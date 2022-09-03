struct QuadVertex
    position::SVector{3, Float32}
    color::SVector{4, Float32}
    texture_coordinate::SVector{2, Float32}
    texture_slot::Float32
end

mutable struct RenderSurface
    program::ShaderProgram
    texture::Texture
    va::VertexArray
end

function RenderSurface(; width::Integer, height::Integer)
    texture = Texture(width, height; internal_format=GL_RGB32F, type=GL_FLOAT)
    program = get_program(RenderSurface)
    bind(program)
    upload_uniform(program, "u_Textures[0]", 0)
    unbind(program)

    va = get_quad_va()
    RenderSurface(program, texture, va)
end

function get_program(::Type{RenderSurface})
    vertex_shader_code = """
    #version 330 core

    layout (location = 0) in vec3 a_Position;
    layout (location = 1) in vec4 a_Color;
    layout (location = 2) in vec2 a_TexCoord;
    layout (location = 3) in float a_TexId;

    out vec4 v_Color;
    out vec2 v_TexCoord;
    out float v_TexId;

    void main() {
        v_Color = a_Color;
        v_TexCoord = a_TexCoord;
        v_TexId = a_TexId;
        gl_Position = vec4(a_Position, 1.0);
    }
    """
    fragment_shader_code = """
    #version 330 core

    in vec4 v_Color;
    in vec2 v_TexCoord;
    in float v_TexId;

    uniform sampler2D u_Textures[1];

    layout (location = 0) out vec4 color;

    void main() {
        color = v_Color;
        color *= texture(u_Textures[int(v_TexId)], v_TexCoord);
    }
    """
    ShaderProgram((
        Shader(GL_VERTEX_SHADER, vertex_shader_code),
        Shader(GL_FRAGMENT_SHADER, fragment_shader_code)))
end

function draw(s::RenderSurface)
    bind(s.program)
    bind(s.texture)
    bind(s.va)
    draw(s.va)
end

function resize!(s::RenderSurface; width::Integer, height::Integer)
    width == s.texture.width && height == s.texture.height && return nothing
    resize!(s.texture; width, height)
end

@inline set_data!(s::RenderSurface, data) = set_data!(s.texture, data)

"Return a quad vertex array, used to display the rendered NeRF."
function get_quad_va(tint = ones(SVector{4, Float32}), texture_slot = 0f0)
    uvs = (
        SVector{2, Float32}(0f0, 0f0), SVector{2, Float32}(1f0, 0f0),
        SVector{2, Float32}(1f0, 1f0), SVector{2, Float32}(0f0, 1f0))
    vertices = (
        SVector{3, Float32}(-1f0, -1f0, 0f0),
        SVector{3, Float32}( 1f0, -1f0, 0f0),
        SVector{3, Float32}( 1f0,  1f0, 0f0),
        SVector{3, Float32}(-1f0,  1f0, 0f0))

    data = [QuadVertex(vertices[i], tint, uvs[i], texture_slot) for i in 1:4]

    layout = BufferLayout([
        BufferElement(SVector{3, Float32}, "a_Position"),
        BufferElement(SVector{4, Float32}, "a_Color"),
        BufferElement(SVector{2, Float32}, "a_TextureCoordinate"),
        BufferElement(SVector{1, Float32}, "a_TextureId")])

    ib = IndexBuffer(UInt32[0, 1, 2, 2, 3, 0])
    vb = VertexBuffer(data, layout)
    VertexArray(ib, vb)
end
