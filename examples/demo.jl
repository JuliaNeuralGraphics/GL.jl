using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using LinearAlgebra
using StaticArrays
using GL

function main()
    GL.init()

    window, imgui_ctx, glfw_ctx, gl_ctx, window_resolution =
        GL.init_renderer("DEMO"; fullscreen=false, width=1280, height=960)

    bbox = GL.BBox(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
    P = SMatrix{4, 4, Float32}(I)
    V = SMatrix{4, 4, Float32}(I)
    # TODO add tests
    display(GL.get_data(bbox.va.vertex_buffer)); println()

    delta_time = 0.0
    last_time = time()
    elapsed_time = 0.0

    GL.render_loop(window, imgui_ctx, glfw_ctx, gl_ctx) do
        GL.imgui_begin(glfw_ctx, gl_ctx)
        GL.clear()
        GL.set_clear_color(0.2, 0.2, 0.2, 1.0)

        bmin = zeros(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        bmax = ones(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        GL.update_corners!(bbox, bmin, bmax)
        GL.draw(bbox, P, V)

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        GL.imgui_end(gl_ctx)
        glfwSwapBuffers(window)
        glfwPollEvents()

        delta_time = time() - last_time
        last_time = time()
        elapsed_time += delta_time
    end
end
main()
