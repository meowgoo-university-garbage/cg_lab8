package main

import "core:fmt"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"

// NOTE: some boilerplate copied from here
// https://github.com/vassvik/odin-gl_examples

MAJOR :: 4
MINOR :: 6

main :: proc() {
    if !glfw.Init() {
        fmt.println("bad")
        return
    }
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window := glfw.CreateWindow(800, 600, "lab1", nil, nil)
    if window == nil {
        fmt.println("bad")
        return
    }

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    gl.load_up_to(MAJOR, MINOR, proc (p : rawptr, name : cstring) {
        (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
    })

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        gl.ClearColor(0.2, 0.3, 0.4, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        glfw.SwapBuffers(window)
    }
}
