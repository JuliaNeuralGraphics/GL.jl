using Test
using StaticArrays
using ModernGL
using GL

GL.init(4, 4)

function in_gl_ctx(test_function)
    ctx = GL.Context("Test"; width=64, height=64)
    test_function()
    GL.delete!(ctx)
end

@testset "Resize texture" begin
    in_gl_ctx() do
        t = GL.Texture(2, 2)
        @test t.id > 0
        old_id = t.id

        new_width, new_height = 4, 4
        GL.resize!(t; width=new_width, height=new_height)

        @test t.id == old_id
        @test t.width == new_width
        @test t.height == new_height

        GL.delete!(t)
    end
end

@testset "Read & write texture" begin
    in_gl_ctx() do
        t = GL.Texture(4, 4)
        @test t.id > 0

        data = rand(UInt8, 3, t.width, t.height)
        GL.set_data!(t, data)

        tex_data = GL.get_data(t)
        @test size(data) == size(tex_data)
        @test data == tex_data

        GL.delete!(t)
    end
end

@testset "Read & write texture array" begin
    in_gl_ctx() do
        t = GL.TextureArray(4, 4, 4)
        @test t.id > 0

        data = rand(UInt8, 3, t.width, t.height, t.depth)
        GL.set_data!(t, data)

        tex_data = GL.get_data(t)
        @test size(data) == size(tex_data)
        @test data == tex_data

        GL.delete!(t)
    end
end

@testset "Resize texture array" begin
    in_gl_ctx() do
        t = GL.TextureArray(2, 2, 2)
        @test t.id > 0
        old_id = t.id

        new_width, new_height, new_depth = 4, 4, 4
        GL.resize!(t; width=new_width, height=new_height, depth=new_depth)

        @test t.id == old_id
        @test t.width == new_width
        @test t.height == new_height
        @test t.depth == new_depth

        GL.delete!(t)
    end
end

@testset "Framebuffer creation" begin
    in_gl_ctx() do
        fb = GL.Framebuffer(Dict(
            GL_COLOR_ATTACHMENT0 => GL.Attachment(
                GL_TEXTURE_2D_ARRAY, GL.TextureArray(0, 0, 0)),
            GL_DEPTH_STENCIL_ATTACHMENT => GL.Attachment(
                GL_TEXTURE_2D_ARRAY, GL.TextureArray(0, 0, 0)),
        ))
        @test fb.id > 0
        @test length(fb.attachments) == 2

        GL.delete!(fb)
    end
end

@testset "Line creation" begin
    in_gl_ctx() do
        l = GL.Line(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
        @test l.va.id > 0
        GL.delete!(l; with_program=true)
    end
end
