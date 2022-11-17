struct Box
    program::ShaderProgram
    va::VertexArray
end

function Box(bmin::SVec3f0, bmax::SVec3f0)
    program = get_program(Box)
    vertices = _box_corners_to_buffer(bmin, bmax)
    indices = UInt32[
        0, 6, 4,
        0, 2, 6,
        1, 5, 7,
        1, 7, 3,
        0, 3, 2,
        0, 1, 3,
        4, 6, 7,
        4, 7, 5,
        2, 7, 6,
        2, 3, 7,
        0, 4, 5,
        0, 5, 1,
    ]
    layout = BufferLayout([BufferElement(SVec3f0, "position")])
    vb = VertexBuffer(vertices, layout)
    Box(program, VertexArray(IndexBuffer(indices), vb))
end

get_program(::Type{Box}) = get_program(BBox)

function _box_corners_to_buffer(bmin::SVec3f0, bmax::SVec3f0)
    [
        bmin,
        SVec3f0(bmin[1], bmin[2], bmax[3]),
        SVec3f0(bmin[1], bmax[2], bmin[3]),
        SVec3f0(bmin[1], bmax[2], bmax[3]),
        SVec3f0(bmax[1], bmin[2], bmin[3]),
        SVec3f0(bmax[1], bmin[2], bmax[3]),
        SVec3f0(bmax[1], bmax[2], bmin[3]),
        bmax,
    ]
end

function draw(
    box::Box, P::SMat4f0, V::SMat4f0;
    color::SVec4f0 = SVec4f0(1f0, 1f0, 1f0, 1f0),
)
    bind(box.program)
    bind(box.va)

    upload_uniform(box.program, "u_color", color)
    upload_uniform(box.program, "proj", P)
    upload_uniform(box.program, "view", V)
    draw(box.va)
end

function update_corners!(box::Box, bmin::SVec3f0, bmax::SVec3f0)
    new_buffer = _box_corners_to_buffer(bmin, bmax)
    set_data!(box.va.vertex_buffer, new_buffer)
    box
end

function delete!(box::Box; with_program::Bool = false)
    delete!(box.va)
    with_program && delete!(box.program)
end
