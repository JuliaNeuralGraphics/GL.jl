struct Shader
    id::UInt32
end

function Shader(type::UInt32, code::String)
    Shader(compile_shader(type, code))
end

function compile_shader(type::UInt32, code::String)
    id = glCreateShader(type)
    id == 0 && error("Failed to create shader of type: $type")

    raw_code = pointer([convert(Ptr{UInt8}, pointer(code))])
    raw_code = convert(Ptr{UInt8}, raw_code)
    glShaderSource(id, 1, raw_code, C_NULL)

    glCompileShader(id)
    validate_shader(id)

    id
end

delete!(s::Shader) = glDeleteShader(s.id)

function validate_shader(id::UInt32)
    succ = @ref glGetShaderiv(id, GL_COMPILE_STATUS, Ref{Int32})
    succ == GL_TRUE && return

    error_log = get_info_log(id)
    error("Failed to compile shader: \n$error_log")
end

function get_info_log(id::UInt32)
    # Return the info log for id, whether it be a shader or a program.
    is_shader = glIsShader(id)
    getiv = is_shader == GL_TRUE ? glGetShaderiv : glGetProgramiv
    getInfo = is_shader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog

    # Get the maximum possible length for the descriptive error message.
    max_message_length = @ref getiv(id, GL_INFO_LOG_LENGTH, Ref{Int32})

    # Return the text of the message if there is any.
    max_message_length == 0 && return ""

    message_buffer = zeros(UInt8, max_message_length)
    message_length = @ref getInfo(id, max_message_length, Ref{Int32}, message_buffer)
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
    id = glCreateProgram()
    id == 0 && error("Failed to create shader program")

    for shader in shaders
        glAttachShader(id, shader.id)
    end
    glLinkProgram(id)

    succ = @ref glGetProgramiv(id, GL_LINK_STATUS, Ref{Int32})
    if succ == GL_FALSE
        glDeleteProgram(id)
        error_log = get_info_log(id)
        error("Failed to link shader program: \n$error_log")
    end

    id
end

bind(p::ShaderProgram) = glUseProgram(p.id)

unbind(::ShaderProgram) = glUseProgram(0)

delete!(p::ShaderProgram) = glDeleteProgram(p.id)

# TODO prefetch locations or cache them
function upload_uniform(p::ShaderProgram, name::String, v::SVector{4, Float32})
    glUniform4f(glGetUniformLocation(p.id, name), v...)
end

function upload_uniform(p::ShaderProgram, name::String, v::SVector{3, Float32})
    glUniform3f(glGetUniformLocation(p.id, name), v...)
end

function upload_uniform(p::ShaderProgram, name::String, v::Real)
    glUniform1f(glGetUniformLocation(p.id, name), v)
end

function upload_uniform(p::ShaderProgram, name::String, v::Int)
    glUniform1i(glGetUniformLocation(p.id, name), v)
end

function upload_uniform(p::ShaderProgram, name::String, v::SMatrix{4, 4, Float32})
    glUniformMatrix4fv(glGetUniformLocation(p.id, name), 1, GL_FALSE, v)
end
