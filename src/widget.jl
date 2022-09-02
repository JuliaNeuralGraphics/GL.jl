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

    v = π * 2f0 / n_segments
    a_min, a_max = v * start, v * (n_segments - 3f0)
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
