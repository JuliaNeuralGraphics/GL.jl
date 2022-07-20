mutable struct BufferElement{T}
    type::T
    name::String
    offset::UInt32
    normalized::Bool
end

function BufferElement(type, name::String, normalized::Bool = false)
    BufferElement(type, name, zero(UInt32), normalized)
end

Base.sizeof(b::BufferElement) = sizeof(b.type)

Base.length(b::BufferElement) = length(b.type)

function gl_eltype(b::BufferElement)
    T = eltype(b.type)
    T <: Integer && return GL_INT
    T <: Real && return GL_FLOAT
    T <: Bool && return GL_BOOL

    error("Failed to get OpenGL type for $T")
end


struct BufferLayout
    elements::Vector{BufferElement}
    stride::UInt32
end

function BufferLayout(elements)
    stride = calculate_offset!(elements)
    BufferLayout(elements, stride)
end

function calculate_offset!(elements)
    offset = 0
    for el in elements
        el.offset += offset
        offset += sizeof(el)
    end
    offset
end

struct VertexBuffer
    id::UInt32
    layout::BufferLayout
end

function VertexBuffer(data, layout::BufferLayout)
    id = @ref glGenBuffers(1, Ref{UInt32})
    type = GL_STATIC_DRAW # TODO change if data changes

    glBindBuffer(GL_ARRAY_BUFFER, id)
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, type)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    VertexBuffer(id, layout)
end

bind(b::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, b.id)

unbind(::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)

struct IndexBuffer
    id::UInt32
    count::UInt32
    primitive_type::UInt32
end

function IndexBuffer(indices, primitive_type::UInt32 = GL_TRIANGLES)
    id = @ref glGenBuffers(1, Ref{UInt32})

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

    IndexBuffer(id, length(indices), primitive_type)
end

bind(b::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, b.id)

unbind(::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

mutable struct VertexArray
    id::UInt32
    index_buffer::IndexBuffer
    vertex_buffer::VertexBuffer
    vb_id::UInt32
end

function VertexArray(ib::IndexBuffer, vb::VertexBuffer)
    id = @ref glGenVertexArrays(1, Ref{UInt32})

    va = VertexArray(id, ib, vb, zero(UInt32))
    set_index_buffer(va)
    set_vertex_buffer(va)

    va
end

function bind(va::VertexArray)
    glBindVertexArray(va.id)
    bind(va.index_buffer)
end

unbind(::VertexArray) = glBindVertexArray(0)

function set_index_buffer(va::VertexArray)
    bind(va)
    bind(va.index_buffer)
    unbind(va)
end

function set_vertex_buffer(va::VertexArray)
    bind(va)
    bind(va.vertex_buffer)
    for el in va.vertex_buffer.layout.elements
        set_pointer!(va, va.vertex_buffer.layout, el)
    end
    unbind(va)
end

function set_pointer!(va::VertexArray, layout::BufferLayout, el::BufferElement)
    glEnableVertexAttribArray(va.vb_id)
    glVertexAttribPointer(
        va.vb_id, length(el), gl_eltype(el), el.normalized ? GL_TRUE : GL_FALSE,
        layout.stride, Ptr{Cvoid}(Int64(el.offset)))
    va.vb_id += 1
end

function draw(va::VertexArray)
    glDrawElements(va.index_buffer.primitive_type, va.index_buffer.count, GL_UNSIGNED_INT, C_NULL)
end
