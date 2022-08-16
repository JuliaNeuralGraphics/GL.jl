module GL

using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using FileIO
using ImageCore
using ImageIO
using LinearAlgebra
using ModernGL
using StaticArrays

"""
Replaces:

```julia
id_ref = Ref{UInt32}()
glGenTextures(1, id_ref)
id = id_ref[]
```

With:

```julia

id = @ref glGenTextures(1, Ref{UInt32})
```

To pass appropriate pointer type, add `:Rep` before the regular type, e.g.
`UInt32` -> `RepUInt32`.

Replaces only first such occurrence.
"""
macro ref(expression::Expr)
    reference_position = 0
    reference_type = Nothing

    for (i, arg) in enumerate(expression.args)
        arg isa Expr || continue
        length(arg.args) < 1 && continue

        if arg.args[1] == :Ref
            reference_position = i
            reference_type = arg
            break
        end
    end
    reference_position == 0 && return esc(expression)

    expression.args[reference_position] = :reference
    esc(quote
        reference = $reference_type()
        $expression
        reference[]
    end)
end

const SVec3f0 = SVector{3, Float32}
const SVec4f0 = SVector{4, Float32}
const SMat3f0 = SMatrix{3, 3, Float32}
const SMat4f0 = SMatrix{4, 4, Float32}

function look_at(position, target, up)
    Z = normalize(position - target)
    X  = normalize(normalize(up) × Z)
    Y = Z × X

    SMatrix{4, 4, Float32}(
        X[1], Y[1], Z[1], 0f0,
        X[2], Y[2], Z[2], 0f0,
        X[3], Y[3], Z[3], 0f0,
        X ⋅ -position, Y ⋅ -position, Z ⋅ -position, 1f0)
end

function _frustum(left, right, bottom, top, znear, zfar)
    (right == left || bottom == top || znear == zfar) &&
        return SMatrix{4, 4, Float32}(I)

    SMatrix{4, 4, Float32}(
        2f0 * znear / (right - left), 0f0, 0f0, 0f0,
        0f0, 2f0 * znear / (top - bottom), 0f0, 0f0,
        (right + left) / (right - left), (top + bottom) / (top - bottom), -(zfar + znear) / (zfar - znear), -1f0,
        0f0, 0f0, (-2f0 * znear * zfar) / (zfar - znear), 0f0)
end

"""
- `fovy`: In degrees.
"""
function perspective(fovy, aspect, znear, zfar)
    (znear == zfar) &&
        error("znear `$znear` must be different from zfar `$zfar`")

    h = tan(0.5f0 * deg2rad(fovy)) * znear
    w = h * aspect
    _frustum(-w, w, -h, h, znear, zfar)
end

include("shader.jl")
include("texture.jl")
include("buffers.jl")
include("quad.jl")
include("bounding_box.jl")
include("line.jl")
include("frustum.jl")

const GLSL_VERSION = 410

function init()
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0)
end

function init_renderer(title; width = -1, height = -1, fullscreen::Bool = false)
    if fullscreen && (width != -1 || height != -1)
        error("You can specify either `fullscreen` or `width` & `height` parameters.")
    end
    if !fullscreen && (width == -1 || height == -1)
        error("You need to specify either `fullscreen` or `width` & `height` parameters.")
    end

    if fullscreen
        glfwWindowHint(GLFW_RESIZABLE, false)
        monitor = glfwGetPrimaryMonitor()
        mode = unsafe_load(glfwGetVideoMode(monitor))
        window = glfwCreateWindow(mode.width, mode.height, title, monitor, C_NULL)
        width, height = mode.width, mode.height
    else
        glfwWindowHint(GLFW_RESIZABLE, true)
        window = glfwCreateWindow(width, height, title, C_NULL, C_NULL)
    end
    glfwMakeContextCurrent(window)
    glfwSwapInterval(1) # enable vsync
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1) # you need this for RGB textures that their width is not a multiple of 4

    imgui_ctx = CImGui.CreateContext()
    CImGui.StyleColorsDark()
    style = CImGui.GetStyle()
    style.FrameRounding = 0f0
    style.WindowRounding = 0f0
    style.ScrollbarRounding = 0f0

    glfw_ctx = CImGui.ImGuiGLFWBackend.create_context(window)
    gl_ctx = CImGui.ImGuiOpenGLBackend.create_context(GLSL_VERSION)

    CImGui.ImGuiGLFWBackend.init(glfw_ctx)
    CImGui.ImGuiOpenGLBackend.init(gl_ctx)

    window, imgui_ctx, glfw_ctx, gl_ctx, (width, height)
end

function imgui_begin(glfw_ctx, gl_ctx)
    CImGui.ImGuiOpenGLBackend.new_frame(gl_ctx)
    CImGui.ImGuiGLFWBackend.new_frame(glfw_ctx)
    CImGui.NewFrame()
end

function imgui_end(gl_ctx)
    CImGui.Render()
    CImGui.ImGuiOpenGLBackend.render(gl_ctx)
end

function imgui_shutdown(imgui_ctx, glfw_ctx, gl_ctx)
    CImGui.ImGuiOpenGLBackend.shutdown(gl_ctx)
    CImGui.ImGuiGLFWBackend.shutdown(glfw_ctx)
    CImGui.DestroyContext(imgui_ctx)
end

function spinner(label, radius, thickness, color)
    window = CImGui.igGetCurrentWindow()
    unsafe_load(window.SkipItems) && return false

    style = CImGui.igGetStyle()
    id = CImGui.GetID(label)

    pos = unsafe_load(window.DC).CursorPos
    y_pad = unsafe_load(style.FramePadding.y)
    size = CImGui.ImVec2(radius * 2, (radius + y_pad) * 2)

    bb = CImGui.ImRect(pos, CImGui.ImVec2(pos.x + size.x, pos.y + size.y))
    CImGui.igItemSizeRect(bb, y_pad)
    CImGui.igItemAdd(bb, id, C_NULL) || return false

    # Render.
    draw_list = unsafe_load(window.DrawList)
    CImGui.ImDrawList_PathClear(draw_list)

    n_segments = 30f0
    start::Float32 = abs(sin(CImGui.GetTime() * 1.8f0) * (n_segments - 5f0))

    a_min = π * 2f0 * start / n_segments
    a_max = π * 2f0 * (n_segments - 3f0) / n_segments
    a_δ = a_max - a_min
    center = CImGui.ImVec2(pos.x + radius, pos.y + radius + y_pad)

    for i in 1:n_segments
        a = a_min + ((i - 1) / n_segments) * a_δ
        ai = a + CImGui.GetTime() * 8
        CImGui.ImDrawList_PathLineTo(draw_list, CImGui.ImVec2(
            center.x + cos(ai) * radius,
            center.y + sin(ai) * radius))
    end
    CImGui.ImDrawList_PathStroke(draw_list, color, false, thickness)
    true
end

clear(bit::UInt32 = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) = glClear(bit)

set_clear_color(r, g, b, a) = glClearColor(r, g, b, a)

set_viewport(width, height) = glViewport(0, 0, width, height)

hide_cursor(w::GLFWwindow) = glfwSetInputMode(w, GLFW_CURSOR, GLFW_CURSOR_DISABLED)

show_cursor(w::GLFWwindow) = glfwSetInputMode(w, GLFW_CURSOR, GLFW_CURSOR_NORMAL)

function render_loop(draw_f, window, imgui_ctx, glfw_ctx, gl_ctx)
    try
        while glfwWindowShouldClose(window) == 0
            draw_f()
        end
    catch exception
        @error "Error in render loop!" exception=exception
        Base.show_backtrace(stderr, catch_backtrace())
    finally
        imgui_shutdown(imgui_ctx, glfw_ctx, gl_ctx)
        glfwDestroyWindow(window)
    end
end

is_key_pressed(key; repeat::Bool = true) = CImGui.IsKeyPressed(key, repeat)

is_key_down(key) = CImGui.IsKeyDown(key)

get_mouse_delta() = unsafe_load(CImGui.GetIO().MouseDelta)

function resize_callback(_, width, height)
    (width == 0 || height == 0) && return nothing # Window minimized.
    set_viewport(width, height)
    nothing
end

end
