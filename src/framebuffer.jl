const AttachmentVariants = Union{Texture, TextureArray}

struct Attachment{T <: AttachmentVariants}
    target::UInt32
    attachment::T
end

get_id(a::Attachment) = a.attachment.id

struct Framebuffer
    id::UInt32
    attachments::Dict{UInt32, Attachment}
end

function Framebuffer(attachments::Dict{UInt32, A}) where A <: Attachment
    id = @ref glGenFramebuffers(1, Ref{UInt32})
    glBindFramebuffer(GL_FRAMEBUFFER, id)

    for (type, attachment) in attachments
        glFramebufferTexture2D(
            GL_FRAMEBUFFER, type, attachment.target, get_id(attachment), 0)
    end

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    Framebuffer(id, attachments)
end

# Good default for rendering.
function Framebuffer(; width::Integer, height::Integer)
    id = @ref glGenFramebuffers(1, Ref{UInt32})
    glBindFramebuffer(GL_FRAMEBUFFER, id)

    attachments = get_default_attachments(width, height)
    for (type, attachment) in attachments
        glFramebufferTexture2D(
            GL_FRAMEBUFFER, type, attachment.target, get_id(attachment), 0)
    end

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    Framebuffer(id, attachments)
end

Base.getindex(f::Framebuffer, type) = f.attachments[type]

function get_default_attachments(width::Integer, height::Integer)
    color = Texture(width, height; internal_format=GL_RGB8, data_format=GL_RGB)
    depth = Texture(
        width, height; type=GL_UNSIGNED_INT_24_8,
        internal_format=GL_DEPTH24_STENCIL8, data_format=GL_DEPTH_STENCIL)
    Dict{UInt32, Attachment}(
        GL_COLOR_ATTACHMENT0 => Attachment(GL_TEXTURE_2D, color),
        GL_DEPTH_STENCIL_ATTACHMENT => Attachment(GL_TEXTURE_2D, depth))
end

# FB must be binded already.
function is_complete(::Framebuffer)
    glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE
end

bind(f::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, f.id)

unbind(::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, 0)

function delete!(f::Framebuffer)
    glDeleteFramebuffers(1, Ref{UInt32}(f.id))
    for k in keys(f.attachments)
        delete!(pop!(f.attachments, k).attachment)
    end
end
