struct Shader
    id::UInt32
end

function Shader(type::UInt32, code::String)
    Shader(compile_shader(type, code))
end

function compile_shader(type::UInt32, code::String)
    id = @gl_check(glCreateShader(type))
    id == 0 && error("Failed to create shader of type: $type")

    raw_code = pointer([convert(Ptr{UInt8}, pointer(code))])
    raw_code = convert(Ptr{UInt8}, raw_code)
    @gl_check(glShaderSource(id, 1, raw_code, C_NULL))

    @gl_check(glCompileShader(id))
    validate_shader(id)

    id
end

delete!(s::Shader) = @gl_check(glDeleteShader(s.id))

function validate_shader(id::UInt32)
    succ = @gl_check(@ref(glGetShaderiv(id, GL_COMPILE_STATUS, Ref{Int32})))
    succ == GL_TRUE && return

    error_log = get_info_log(id)
    error("Failed to compile shader: \n$error_log")
end

function get_info_log(id::UInt32)
    # Return the info log for id, whether it be a shader or a program.
    is_shader = @gl_check(glIsShader(id))
    getiv = is_shader == GL_TRUE ? glGetShaderiv : glGetProgramiv
    getInfo = is_shader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog

    # Get the maximum possible length for the descriptive error message.
    max_message_length = @gl_check(@ref(
        getiv(id, GL_INFO_LOG_LENGTH, Ref{Int32})))

    # Return the text of the message if there is any.
    max_message_length == 0 && return ""

    message_buffer = zeros(UInt8, max_message_length)
    message_length = @gl_check(@ref(getInfo(id, max_message_length, Ref{Int32}, message_buffer)))
    unsafe_string(Base.pointer(message_buffer), message_length)
end

struct ShaderProgram
    id::UInt32

    function ShaderProgram(shaders, delete_shaders::Bool = true)
        id = create_program(shaders)
        if delete_shaders
            for shader in shaders
                delete!(shader)
            end
        end
        new(id)
    end
end

function create_program(shaders)
    id = @gl_check(glCreateProgram())
    id == 0 && error("Failed to create shader program")

    for shader in shaders
        @gl_check(glAttachShader(id, shader.id))
    end
    @gl_check(glLinkProgram(id))

    succ = @gl_check(@ref(glGetProgramiv(id, GL_LINK_STATUS, Ref{Int32})))
    if succ == GL_FALSE
        @gl_check(glDeleteProgram(id))
        error_log = get_info_log(id)
        error("Failed to link shader program: \n$error_log")
    end

    id
end

bind(p::ShaderProgram) = @gl_check(glUseProgram(p.id))

unbind(::ShaderProgram) = @gl_check(glUseProgram(0))

delete!(p::ShaderProgram) = @gl_check(glDeleteProgram(p.id))

# TODO prefetch locations or cache them
function upload_uniform(p::ShaderProgram, name::String, v::SVector{4, Float32})
    loc = @gl_check(glGetUniformLocation(p.id, name))
    @gl_check(glUniform4f(loc, v...))
end

function upload_uniform(p::ShaderProgram, name::String, v::SVector{3, Float32})
    loc = @gl_check(glGetUniformLocation(p.id, name))
    @gl_check(glUniform3f(loc, v...))
end

function upload_uniform(p::ShaderProgram, name::String, v::Real)
    loc = @gl_check(glGetUniformLocation(p.id, name))
    @gl_check(glUniform1f(loc, v))
end

function upload_uniform(p::ShaderProgram, name::String, v::Int)
    loc = @gl_check(glGetUniformLocation(p.id, name))
    @gl_check(glUniform1i(loc, v))
end

function upload_uniform(p::ShaderProgram, name::String, v::SMatrix{4, 4, Float32})
    loc = @gl_check(glGetUniformLocation(p.id, name))
    @gl_check(glUniformMatrix4fv(loc, 1, GL_FALSE, v))
end
