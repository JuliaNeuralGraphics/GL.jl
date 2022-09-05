struct Line
    from::SVector{3, Float32}
    to::SVector{3, Float32}

    program::ShaderProgram
    va::VertexArray
end

function Line(from::SVec3f0, to::SVec3f0; program = get_program(Line))
    vertices = [from, to]
    indices = UInt32[0, 1]

    layout = BufferLayout([BufferElement(SVec3f0, "position")])
    vb = VertexBuffer(vertices, layout)
    ib = IndexBuffer(indices; primitive_type=GL_LINES)
    Line(from, to, program, VertexArray(ib, vb))
end

function get_program(::Type{Line})
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

    layout (location = 0) out vec4 color;

    void main(void) {
        color = vec4(0.8, 0.5, 0.1, 1.0);
    }
    """
    ShaderProgram((
        Shader(GL_VERTEX_SHADER, vertex_shader_code),
        Shader(GL_FRAGMENT_SHADER, fragment_shader_code)))
end

function draw(l::Line, P, V)
    bind(l.program)
    bind(l.va)

    upload_uniform(l.program, "proj", P)
    upload_uniform(l.program, "view", V)
    draw(l.va)
end

function delete!(l::Line; with_program::Bool = false)
    delete!(l.va)
    with_program && delete!(l.program)
end
