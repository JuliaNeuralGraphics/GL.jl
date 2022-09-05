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

mutable struct VertexBuffer{T}
    id::UInt32
    usage::UInt32
    layout::BufferLayout
    sizeof::Int64
    length::Int64
end

function VertexBuffer(data, layout::BufferLayout; usage = GL_STATIC_DRAW)
    sof = sizeof(data)
    id = @gl_check(@ref(glGenBuffers(1, Ref{UInt32})))
    @gl_check(glBindBuffer(GL_ARRAY_BUFFER, id))
    @gl_check(glBufferData(GL_ARRAY_BUFFER, sof, data, usage))
    @gl_check(glBindBuffer(GL_ARRAY_BUFFER, 0))
    VertexBuffer{eltype(data)}(id, usage, layout, sof, length(data))
end

Base.length(b::VertexBuffer) = b.length

Base.eltype(::VertexBuffer{T}) where T = T

Base.sizeof(b::VertexBuffer) = b.sizeof

bind(b::VertexBuffer) = @gl_check(glBindBuffer(GL_ARRAY_BUFFER, b.id))

unbind(::VertexBuffer) = @gl_check(glBindBuffer(GL_ARRAY_BUFFER, 0))

delete!(b::VertexBuffer) = @gl_check(glDeleteBuffers(1, Ref{UInt32}(b.id)))

function get_data(b::VertexBuffer{T})::Vector{T} where T
    bind(b)
    data = Vector{T}(undef, length(b))
    @gl_check(glGetBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(b), data))
    glBufferData
    unbind(b)
    data
end

function set_data!(b::VertexBuffer{T}, data) where T
    T == eltype(data) || error("Not the same eltype: $T vs $(eltype(data)).")
    sof = sizeof(data)
    bind(b)
    if length(data) > length(b)
        @gl_check(glBufferData(GL_ARRAY_BUFFER, sof, data, b.usage))
    else
        @gl_check(glBufferSubData(GL_ARRAY_BUFFER, 0, sof, data))
    end
    unbind(b)
    b.length = length(data)
    b.sizeof = sof
end

mutable struct IndexBuffer
    id::UInt32
    primitive_type::UInt32
    usage::UInt32
    sizeof::Int64
    length::Int64
end

function IndexBuffer(
    indices; primitive_type::UInt32 = GL_TRIANGLES,
    usage::UInt32 = GL_STATIC_DRAW,
)
    sof, len = sizeof(indices), length(indices)

    id = @ref glGenBuffers(1, Ref{UInt32})
    @gl_check(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id))
    @gl_check(glBufferData(GL_ELEMENT_ARRAY_BUFFER, sof, indices, usage))
    @gl_check(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0))
    IndexBuffer(id, primitive_type, usage, sof, len)
end

function set_data!(b::IndexBuffer, data::D) where D <: AbstractArray
    sof = sizeof(data)
    bind(b)
    if length(data) > length(b)
        @gl_check(glBufferData(GL_ELEMENT_ARRAY_BUFFER, sof, data, b.usage))
    else
        @gl_check(glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, sof, data))
    end
    unbind(b)
    b.length = length(data)
    b.sizeof = sof
end

function get_data(b::IndexBuffer)
    data = Vector{UInt32}(undef, length(b))
    bind(b)
    @gl_check(glGetBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, sizeof(b), data))
    unbind(b)
    data
end

Base.length(b::IndexBuffer) = b.length

Base.sizeof(b::IndexBuffer) = b.sizeof

bind(b::IndexBuffer) = @gl_check(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, b.id))

unbind(::IndexBuffer) = @gl_check(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0))

delete!(b::IndexBuffer) = @gl_check(glDeleteBuffers(1, Ref{UInt32}(b.id)))

mutable struct VertexArray
    id::UInt32
    index_buffer::IndexBuffer
    vertex_buffer::VertexBuffer
    vb_id::UInt32
end

function VertexArray(ib::IndexBuffer, vb::VertexBuffer)
    id = @gl_check(@ref(glGenVertexArrays(1, Ref{UInt32})))
    va = VertexArray(id, ib, vb, zero(UInt32))
    set_index_buffer(va)
    set_vertex_buffer(va)
    va
end

function bind(va::VertexArray)
    @gl_check(glBindVertexArray(va.id))
    bind(va.index_buffer)
end

unbind(::VertexArray) = @gl_check(glBindVertexArray(0))

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
    @gl_check(glEnableVertexAttribArray(va.vb_id))
    @gl_check(glVertexAttribPointer(
        va.vb_id, length(el), gl_eltype(el), el.normalized ? GL_TRUE : GL_FALSE,
        layout.stride, Ptr{Cvoid}(Int64(el.offset))))
    va.vb_id += 1
end

function draw(va::VertexArray)
    @gl_check(glDrawElements(
        va.index_buffer.primitive_type, length(va.index_buffer),
        GL_UNSIGNED_INT, C_NULL))
end

function delete!(va::VertexArray)
    @gl_check(glDeleteVertexArrays(1, Ref{UInt32}(va.id)))
    delete!(va.index_buffer)
    delete!(va.vertex_buffer)
end
