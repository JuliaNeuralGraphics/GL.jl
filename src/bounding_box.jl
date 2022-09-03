struct BBox
    program::ShaderProgram
    va::VertexArray
end

function BBox(bmin::SVec3f0, bmax::SVec3f0)
    program = get_program(BBox)

    vertices = _bbox_corners_to_buffer(bmin, bmax)
    indices = UInt32[
        # First side.
        0, 1,
        1, 2,
        2, 3,
        3, 0,
        # Second side.
        4, 5,
        5, 6,
        6, 7,
        7, 4,
        # Connections between sides.
        0, 6,
        1, 7,
        2, 4,
        3, 5]

    layout = BufferLayout([BufferElement(SVec3f0, "position")])
    vb = VertexBuffer(vertices, layout)
    ib = IndexBuffer(indices, GL_LINES)
    BBox(program, VertexArray(ib, vb))
end

function _bbox_corners_to_buffer(bmin::SVec3f0, bmax::SVec3f0)
    [
        bmin,
        SVec3f0(bmin[1], bmin[2], bmax[3]),
        SVec3f0(bmin[1], bmax[2], bmax[3]),
        SVec3f0(bmin[1], bmax[2], bmin[3]),
        bmax,
        SVec3f0(bmax[1], bmax[2], bmin[3]),
        SVec3f0(bmax[1], bmin[2], bmin[3]),
        SVec3f0(bmax[1], bmin[2], bmax[3])]
end

function get_program(::Type{BBox})
    vertex_shader_code = """
    #version 330 core
    layout (location = 0) in vec3 position;

    uniform mat4 proj;
    uniform mat4 view;

    void main(void) {
        gl_Position = proj * view * vec4(position, 1.0);
    }
    """
    fragment_shader_code = """
    #version 330 core

    uniform vec4 u_color;

    layout (location = 0) out vec4 color;

    void main(void) {
        color = u_color;
    }
    """
    ShaderProgram((
        Shader(GL_VERTEX_SHADER, vertex_shader_code),
        Shader(GL_FRAGMENT_SHADER, fragment_shader_code)))
end

function draw(
    bbox::BBox, P::SMat4f0, V::SMat4f0;
    color::SVec4f0 = SVec4f0(1f0, 0f0, 0f0, 1f0),
)
    bind(bbox.program)
    bind(bbox.va)

    upload_uniform(bbox.program, "u_color", color)
    upload_uniform(bbox.program, "proj", P)
    upload_uniform(bbox.program, "view", V)
    draw(bbox.va)
end

function update_corners!(bbox::BBox, bmin::SVec3f0, bmax::SVec3f0)
    new_buffer = _bbox_corners_to_buffer(bmin, bmax)
    buffer_data!(bbox.va.vertex_buffer, new_buffer)
    bbox
end

function delete!(bbox::BBox; with_program::Bool = false)
    delete!(bbox.va)
    with_program && delete!(bbox.program)
end
