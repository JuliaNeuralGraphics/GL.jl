struct Framebuffer
    id::UInt32
    attachments::Dict{UInt32, AbstractTexture}
end

function Framebuffer(attachments)
    id = @gl_check(@ref(glGenFramebuffers(1, Ref{UInt32})))
    @gl_check(glBindFramebuffer(GL_FRAMEBUFFER, id))
    for (type, attachment) in attachments
        @gl_check(glFramebufferTexture(GL_FRAMEBUFFER, type, attachment.id, 0))
    end
    @gl_check(glBindFramebuffer(GL_FRAMEBUFFER, 0))
    Framebuffer(id, attachments)
end

# Good default for rendering.
function Framebuffer(; width::Integer, height::Integer)
    id = @gl_check(@ref(glGenFramebuffers(1, Ref{UInt32})))
    @gl_check(glBindFramebuffer(GL_FRAMEBUFFER, id))
    attachments = get_default_attachments(width, height)
    for (type, attachment) in attachments
        @gl_check(glFramebufferTexture(GL_FRAMEBUFFER, type, attachment.id, 0))
    end
    @gl_check(glBindFramebuffer(GL_FRAMEBUFFER, 0))
    Framebuffer(id, attachments)
end

Base.getindex(f::Framebuffer, type) = f.attachments[type]

function get_default_attachments(width::Integer, height::Integer)
    color = Texture(width, height; internal_format=GL_RGB8, data_format=GL_RGB)
    depth = Texture(
        width, height; type=GL_FLOAT, internal_format=GL_DEPTH_COMPONENT,
        data_format=GL_DEPTH_COMPONENT)
    Dict(GL_COLOR_ATTACHMENT0 => color, GL_DEPTH_ATTACHMENT => depth)
end

# FB must be binded already.
function is_complete(::Framebuffer)
    @gl_check(glCheckFramebufferStatus(GL_FRAMEBUFFER)) == GL_FRAMEBUFFER_COMPLETE
end

bind(f::Framebuffer) = @gl_check(glBindFramebuffer(GL_FRAMEBUFFER, f.id))

unbind(::Framebuffer) = @gl_check(glBindFramebuffer(GL_FRAMEBUFFER, 0))

function delete!(f::Framebuffer)
    glDeleteFramebuffers(1, Ref{UInt32}(f.id))
    for k in keys(f.attachments)
        delete!(pop!(f.attachments, k))
    end
end
