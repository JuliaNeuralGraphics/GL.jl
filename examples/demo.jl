using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using GL

function main()
    GL.init()

    window, imgui_ctx, glfw_ctx, gl_ctx, window_resolution =
        GL.init_renderer("DEMO"; fullscreen=false, width=1280, height=960)

    GL.render_loop(window, imgui_ctx, glfw_ctx, gl_ctx) do
        GL.imgui_begin(glfw_ctx, gl_ctx)
        GL.clear()
        GL.set_clear_color(0.2, 0.2, 0.2, 1.0)

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        GL.imgui_end(gl_ctx)
        glfwSwapBuffers(window)
        glfwPollEvents()
    end
end
main()
