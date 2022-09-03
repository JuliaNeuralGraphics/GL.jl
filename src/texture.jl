mutable struct Texture
    id::UInt32
    width::UInt32
    height::UInt32

    internal_format::UInt32
    data_format::UInt32
    type::UInt32
end

function Texture(path::String; kwargs...)
    type = GL_UNSIGNED_BYTE
    data = load_texture_data(path)
    internal_format, data_format = get_data_formats(eltype(data))
    width, height = size(data)

    id = @ref glGenTextures(1, Ref{UInt32})
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, internal_format,
        width, height, 0, data_format, type, data)

    set_texture_parameters(;kwargs...)
    Texture(id, width, height, internal_format, data_format, type)
end

function Texture(
    width, height; type::UInt32 = GL_UNSIGNED_BYTE,
    internal_format::UInt32 = GL_RGB8, data_format::UInt32 = GL_RGB, kwargs...,
)
    id = @ref glGenTextures(1, Ref{UInt32})
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, internal_format,
        width, height, 0, data_format, type, C_NULL)

    set_texture_parameters(; kwargs...)
    Texture(id, width, height, internal_format, data_format, type)
end

function bind(t::Texture, slot::Integer = 0)
    glActiveTexture(GL_TEXTURE0 + slot)
    glBindTexture(GL_TEXTURE_2D, t.id)
end

unbind(::Texture) = glBindTexture(GL_TEXTURE_2D, 0)

delete!(t::Texture) = glDeleteTextures(1, Ref(t.id))

function set_texture_parameters(;
    min_filter::UInt32 = GL_LINEAR, mag_filter::UInt32 = GL_LINEAR,
    wrap_s::UInt32 = GL_REPEAT, wrap_t::UInt32 = GL_REPEAT,
)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, min_filter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag_filter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_s)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_t)
end

function load_texture_data(path::String, vertical_flip::Bool = true)
    !isfile(path) && error("File `$path` does not exist.")
    data = permutedims(load(path), (2, 1)) # HxW -> WxH
    vertical_flip && (data = data[:, end:-1:1];)
    data
end

function get_data_formats(pixel_type)
    internal_format = GL_RGB8
    data_format = GL_RGB

    if pixel_type <: RGB
        internal_format = GL_RGB8
        data_format = GL_RGB
    elseif pixel_type <: RGBA
        internal_format = GL_RGBA8
        data_format = GL_RGBA
    elseif  pixel_type <: Gray
        internal_format = GL_RED
        data_format = GL_RED
    else
        error("Unsupported texture data format `$pixel_type`")
    end

    internal_format, data_format
end

function set_data!(t::Texture, data)
    bind(t)
    glTexImage2D(
        GL_TEXTURE_2D, 0, t.internal_format,
        t.width, t.height, 0, t.data_format, t.type, data)
end

function get_n_channels(t)
    if t.data_format == GL_RGB return 3
    elseif t.data_format == GL_RGBA return 4
    elseif t.data_format == GL_DEPTH_COMPONENT return 1
    elseif t.data_format == GL_RED && return 4 end
end

function get_native_type(t)
    if t.type == GL_UNSIGNED_BYTE return UInt8
    elseif t.type == GL_FLOAT return Float32 end
end

function get_data(t::Texture)
    channels = get_n_channels(t)
    data = Array{get_native_type(t)}(undef, channels, t.width, t.height)
    get_data!(t, data)
end

function get_data!(t::Texture, data)
    bind(t)
    glGetTexImage(GL_TEXTURE_2D, 0, t.data_format, t.type, data)
    unbind(t)
    data
end

function resize!(t::Texture; width::Integer, height::Integer)
    bind(t)
    glTexImage2D(
        GL_TEXTURE_2D, 0, t.internal_format,
        width, height, 0, t.data_format, t.type, C_NULL)
    t.width = width
    t.height = height
end
