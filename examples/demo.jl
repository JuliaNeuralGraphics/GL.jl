using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using LinearAlgebra
using StaticArrays
using GL

function main()
    GL.init()
    context = GL.Context("でも"; width=1280, height=960)
    GL.set_resize_callback!(context, GL.resize_callback)

    bbox = GL.Box(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
    P = SMatrix{4, 4, Float32}(I)
    V = SMatrix{4, 4, Float32}(I)

    delta_time = 0.0
    last_time = time()
    elapsed_time = 0.0

    voxels_data = Float32[
        0f0, 0f0, 0f0, 1f0, 0.1f0,
        0.2f0, 0f0, 0f0, 0.5f0, 0.1f0,
        0.2f0, 0.2f0, 0f0, 0f0, 0.05f0]
    voxels_data_2 = Float32[
        0f0, 0f0, 0f0, 1f0, 0.1f0,
        0.2f0, 0f0, 0f0, 0.5f0, 0.1f0]
    voxels = GL.Voxels(voxels_data)

    GL.enable_blend()

    GL.render_loop(context; destroy_context=false) do
        GL.imgui_begin(context)
        GL.clear()
        GL.set_clear_color(0.2, 0.2, 0.2, 1.0)

        # bmin = zeros(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        # bmax = ones(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        # GL.update_corners!(bbox, bmin, bmax)
        # GL.draw(bbox, P, V)

        GL.draw_instanced(voxels, P, V)

        if 2 < elapsed_time < 4
            GL.update!(voxels, voxels_data_2)
        elseif elapsed_time > 4
            GL.update!(voxels, voxels_data)
        end

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        GL.imgui_end(context)
        glfwSwapBuffers(context.window)
        glfwPollEvents()

        delta_time = time() - last_time
        last_time = time()
        elapsed_time += delta_time
        true
    end

    GL.delete!(bbox)
    GL.delete!(context)
end
main()
