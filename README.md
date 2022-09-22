# GL.jl

## Install

```bash
git clone https://github.com/JuliaNeuralGraphics/GL.jl.git
cd GL.jl
julia --project=.
]instantiate
```

## Demo

Execute `julia --project=. examples/demo.jl`.

## AMDGPU workaround

Trying to run OpenGL stuff on AMDGPU as is raises following error (see below).

This is caused by Julia's `libstdc++.so`.

To fix this, in the folder with Julia, rename all `/julia/lib/libstdc++.so*` to `/julia/lib/libstdc++.so*.bak`.

This is a known issue: [link](https://github.com/JuliaGL/GLFW.jl/issues/198).


```
3.3.8 X11 GLX EGL OSMesa clock_gettime evdev shared
libGL: Can't open configuration file /etc/drirc: No such file or directory.
libGL: Can't open configuration file /home/pxl-th/.drirc: No such file or directory.
libGL: using driver amdgpu for 22
libGL: Can't open configuration file /etc/drirc: No such file or directory.
libGL: Can't open configuration file /home/pxl-th/.drirc: No such file or directory.
libGL: pci id for fd 22: 1002:73df, driver radeonsi
libGL: MESA-LOADER: failed to open /usr/lib/x86_64-linux-gnu/dri/radeonsi_dri.so: /home/pxl-th/bin/julia-latest/bin/../lib/julia/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by /lib/x86_64-linux-gnu/libLLVM-13.so.1)
libGL: MESA-LOADER: failed to open \$${ORIGIN}/dri/radeonsi_dri.so: \$${ORIGIN}/dri/radeonsi_dri.so: cannot open shared object file: No such file or directory
libGL: MESA-LOADER: failed to open /usr/lib/dri/radeonsi_dri.so: /usr/lib/dri/radeonsi_dri.so: cannot open shared object file: No such file or directory
libGL error: MESA-LOADER: failed to open radeonsi: /usr/lib/dri/radeonsi_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri, suffix _dri)
libGL error: failed to load driver: radeonsi
libGL: MESA-LOADER: failed to open /usr/lib/x86_64-linux-gnu/dri/swrast_dri.so: /home/pxl-th/bin/julia-latest/bin/../lib/julia/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by /lib/x86_64-linux-gnu/libLLVM-13.so.1)
libGL: MESA-LOADER: failed to open \$${ORIGIN}/dri/swrast_dri.so: \$${ORIGIN}/dri/swrast_dri.so: cannot open shared object file: No such file or directory
libGL: MESA-LOADER: failed to open /usr/lib/dri/swrast_dri.so: /usr/lib/dri/swrast_dri.so: cannot open shared object file: No such file or directory
libGL error: MESA-LOADER: failed to open swrast: /usr/lib/dri/swrast_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri, suffix _dri)
libGL error: failed to load driver: swrast
ERROR: LoadError: GLFWError (VERSION_UNAVAILABLE): GLX: Failed to create context: BadValue
```
