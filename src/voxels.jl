mutable struct Voxels
    program::ShaderProgram
    va::VertexArray
    data_buffer::VertexBuffer
    data_vb_id::Int
    n_voxels::Int
end

function Voxels(data::Vector{Float32})
    program = get_program(Voxels)

    @assert length(data) % 5 == 0
    n_voxels = length(data) ÷ 5

    vertices = _box_corners_to_buffer(zeros(SVec3f0), ones(SVec3f0))
    vertex_buffer = VertexBuffer(vertices, BufferLayout([
        BufferElement(SVec3f0, "vertex")]))

    data_buffer = VertexBuffer(data, BufferLayout([
        BufferElement(SVec3f0, "translation"; divisor=1),
        BufferElement(SVec2f0, "density & diagonal"; divisor=1),
    ]))

    """
    - 8 cube vertices, divisor = N
    - N Vec3f0 translations, divisor = 1
    - N Vec2f0(density, diagonal), divisor = 1
    """

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
    va = VertexArray(IndexBuffer(indices), vertex_buffer)
    data_vb_id = va.vb_id
    set_vertex_buffer!(va, data_buffer)
    Voxels(program, va, data_buffer, data_vb_id, n_voxels)
end

function update!(voxels::Voxels, new_data::Vector{Float32})
    @assert length(new_data) % 5 == 0
    n_voxels = length(new_data) ÷ 5
    data_buffer = VertexBuffer(new_data, voxels.data_buffer.layout)

    delete!(voxels.data_buffer)
    voxels.va.vb_id = voxels.data_vb_id

    set_vertex_buffer!(voxels.va, data_buffer)
    voxels.data_buffer = data_buffer
    voxels.n_voxels = n_voxels
end

function get_program(::Type{Voxels})
    vertex_shader_code = """
    #version 330 core

    layout (location = 0) in vec3 vertex;
    layout (location = 1) in vec3 translation;
    layout (location = 2) in vec2 data;

    out float density;

    uniform mat4 proj;
    uniform mat4 view;

    void main(void) {
        float diagonal = data.y;
        vec3 local_pos = vertex * diagonal + translation;
        gl_Position = proj * view * vec4(local_pos, 1.0);
        density = data.x;
    }
    """
    fragment_shader_code = """
    #version 330 core

    in float density;

    layout (location = 0) out vec4 outColor;

    vec3 colorA = vec3(0.912,0.844,0.589);
    vec3 colorB = vec3(0.149,0.141,0.912);

    void main(void) {
        outColor = vec4(mix(colorA, colorB, density), 0.5);
    }
    """
    ShaderProgram((
        Shader(GL_VERTEX_SHADER, vertex_shader_code),
        Shader(GL_FRAGMENT_SHADER, fragment_shader_code)))
end

function draw_instanced(voxels::Voxels, P::SMat4f0, V::SMat4f0)
    voxels.n_voxels == 0 && return

    bind(voxels.program)
    bind(voxels.va)

    upload_uniform(voxels.program, "proj", P)
    upload_uniform(voxels.program, "view", V)
    draw_instanced(voxels.va, voxels.n_voxels)
    nothing
end

function delete!(voxels::Voxels; with_program::Bool = false)
    delete!(voxels.va)
    delete!(voxels.data_buffer)
    with_program && delete!(voxels.program)
end
