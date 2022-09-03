mutable struct TextureArray
    id::UInt32
    width::UInt32
    height::UInt32
    depth::UInt32

    internal_format::UInt32
    data_format::UInt32
    type::UInt32
end

function TextureArray(
    width::Integer, height::Integer, depth::Integer;
    type::UInt32 = GL_UNSIGNED_BYTE, internal_format::UInt32 = GL_RGB8,
    data_format::UInt32 = GL_RGB, kwargs...,
)
    id = @ref glGenTextures(1, Ref{UInt32})
    glBindTexture(GL_TEXTURE_2D_ARRAY, id)
    glTexImage3D(
        GL_TEXTURE_2D_ARRAY, 0, internal_format,
        width, height, depth, 0, data_format, type, C_NULL)

    # TODO allow disabling?
    set_texture_array_parameters(; kwargs...)
    TextureArray(id, width, height, depth, internal_format, data_format, type)
end

function set_texture_array_parameters(;
    min_filter::UInt32 = GL_NEAREST, mag_filter::UInt32 = GL_NEAREST,
    wrap_s::UInt32 = GL_CLAMP_TO_EDGE, wrap_t::UInt32 = GL_CLAMP_TO_EDGE,
)
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER, min_filter)
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, mag_filter)
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S, wrap_s)
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T, wrap_t)
end

function set_data!(t::TextureArray, data)
    bind(t)
    glTexImage3D(
        GL_TEXTURE_2D_ARRAY, 0, t.internal_format,
        t.width, t.height, t.depth, 0, t.data_format, t.type, data)
end

function get_data(t::TextureArray)
    channels = get_n_channels(t)
    data = Array{get_native_type(t)}(
        undef, channels, t.width, t.height, t.depth)
    get_data!(t, data)
end

function get_data!(t::TextureArray, data)
    bind(t)
    glGetTexImage(GL_TEXTURE_2D_ARRAY, 0, t.data_format, t.type, data)
    unbind(t)
    data
end

function bind(t::TextureArray, slot::Integer = 0)
    glActiveTexture(GL_TEXTURE0 + slot)
    glBindTexture(GL_TEXTURE_2D_ARRAY, t.id)
end

unbind(::TextureArray) = glBindTexture(GL_TEXTURE_2D_ARRAY, 0)

delete!(t::TextureArray) = glDeleteTextures(1, Ref(t.id))

function resize!(
    t::TextureArray; width::Integer, height::Integer, depth::Integer,
)
    bind(t)
    glTexImage3D(
        GL_TEXTURE_2D_ARRAY, 0, t.internal_format,
        width, height, depth, 0, t.data_format, t.type, C_NULL)
    t.width = width
    t.height = height
    t.depth = depth
end
