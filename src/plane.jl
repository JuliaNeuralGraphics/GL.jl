struct Screen
    program::ShaderProgram
    va::VertexArray
end

function Screen()
    # 2 vertices, 2 tex coord
    data = Float32[
        -1, -1, 0, 0,
        1, -1, 1, 0,
        1, 1, 1, 1,
        -1, 1, 0, 1,
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    layout = BufferLayout([
        BufferElement(SVec2f0, "a_Position"),
        BufferElement(SVec2f0, "a_TexCoord")])
    vb = VertexBuffer(data, layout)
    ib = IndexBuffer(indices)
    Screen(get_program(Screen), VertexArray(ib, vb))
end

function get_program(::Type{Screen})
    GL.ShaderProgram((
        GL.Shader(GL_VERTEX_SHADER, """
        #version 330 core
        layout (location = 0) in vec2 a_Position;
        layout (location = 1) in vec2 a_TexCoord;

        out vec2 v_TexCoord;

        void main() {
            v_TexCoord = a_TexCoord;
            gl_Position = vec4(a_Position, 0.0, 1.0);
        }
        """),
        GL.Shader(GL_FRAGMENT_SHADER, """
        #version 330 core
        in vec2 v_TexCoord;

        uniform sampler2D u_ScreenTexture;

        layout (location = 0) out vec4 frag_color;

        void main() {
            vec3 color = texture(u_ScreenTexture, v_TexCoord).rgb;
            frag_color = vec4(color, 1.0);
        }
        """),
    ))
end

function draw(s::Screen, screen_texture::Texture)
    bind(s.program)
    bind(s.va)
    bind(screen_texture)

    upload_uniform(s.program, "u_ScreenTexture", 0)
    draw(s.va)
end

function delete!(s::Screen; with_program::Bool = true)
    delete!(s.va)
    with_program && delete!(s.program)
end
