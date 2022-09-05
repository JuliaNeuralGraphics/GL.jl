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

@testset "Test OP on deleted texture" begin
    in_gl_ctx() do
        t = GL.Texture(2, 2)
        @test t.id > 0
        GL.delete!(t)
        new_width, new_height = 4, 4
        @test_throws ErrorException GL.resize!(
            t; width=new_width, height=new_height)
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
            GL_COLOR_ATTACHMENT0 => GL.TextureArray(0, 0, 0),
            GL_DEPTH_STENCIL_ATTACHMENT => GL.TextureArray(0, 0, 0)))
        @test fb.id > 0
        @test length(fb.attachments) == 2
        @test GL.is_complete(fb)

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

@testset "IndexBuffer creation, update, read" begin
    in_gl_ctx() do
        idx1 = UInt32[0, 1, 2, 3]
        idx2 = UInt32[0, 1, 2, 3, 4, 5, 6, 7]
        idx3 = UInt32[0, 1]

        ib = GL.IndexBuffer(idx1; primitive_type=GL_LINES, usage=GL_DYNAMIC_DRAW)
        @test length(ib) == length(idx1)
        @test sizeof(ib) == sizeof(idx1)
        @test GL.get_data(ib) == idx1

        GL.set_data!(ib, idx2)
        @test length(ib) == length(idx2)
        @test sizeof(ib) == sizeof(idx2)
        @test GL.get_data(ib) == idx2

        GL.set_data!(ib, idx3)
        @test length(ib) == length(idx3)
        @test sizeof(ib) == sizeof(idx3)
        @test GL.get_data(ib) == idx3
    end
end

@testset "VertexBuffer creation, update, read" begin
    in_gl_ctx() do
        v1 = rand(Float32, 3, 1)
        v2 = rand(Float32, 3, 4)
        v3 = rand(Float32, 3, 2)

        layout = GL.BufferLayout([
            GL.BufferElement(SVector{3, Float32}, "position")])
        vb = GL.VertexBuffer(v1, layout; usage=GL_DYNAMIC_DRAW)
        @test length(vb) == length(v1)
        @test sizeof(vb) == sizeof(v1)
        @test GL.get_data(vb) == reshape(v1, :)

        GL.set_data!(vb, v2)
        @test length(vb) == length(v2)
        @test sizeof(vb) == sizeof(v2)
        @test GL.get_data(vb) == reshape(v2, :)

        GL.set_data!(vb, v3)
        @test length(vb) == length(v3)
        @test sizeof(vb) == sizeof(v3)
        @test GL.get_data(vb) == reshape(v3, :)
    end
end
