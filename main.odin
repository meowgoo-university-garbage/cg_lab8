package main

import "core:fmt"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"
import "core:math/linalg"

// NOTE: some boilerplate copied from here
// https://github.com/vassvik/odin-gl_examples

MAJOR :: 4
MINOR :: 6

Vertex :: struct {
    pos : [3]f32,
    // _ : f32,
    col : [3]f32,
    // _ : f32,
}

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

    program, _ := gl.load_shaders_file("vertex.glsl", "fragment.glsl")
    defer gl.DeleteProgram(program)

    array_vertex : u32
    gl.GenVertexArrays(1, &array_vertex)
    defer gl.DeleteVertexArrays(1, &array_vertex)
    gl.BindVertexArray(array_vertex)

    vertexes : []Vertex = {
        { pos = { -0.5,  0.0,  0.0 },   col = { 1.0, 0.0, 0.0 } },
        { pos = {  0.5,  0.0,  0.0 },   col = { 0.0, 1.0, 0.0 } },
        { pos = {  0.5,  0.0,  1.0 },   col = { 0.0, 0.0, 1.0 } },
    }

    buffer_vertex : u32
    gl.GenBuffers(1, &buffer_vertex)
    defer gl.DeleteBuffers(1, &buffer_vertex)

    gl.BindBuffer(gl.ARRAY_BUFFER, buffer_vertex)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Vertex) * len(vertexes), raw_data(vertexes), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, pos))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, col))



    time_start := time.now()




    gl.Enable(gl.DEPTH_TEST)
    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        // gl.ClearColor(0.2, 0.3, 0.4, 1.0)

        gl.UseProgram(program)

        time_now := time.now()
        time_passed := cast(f32)time.duration_seconds(time.diff(time_start, time_now))
        gl.Uniform1f(0, time_passed)

        matrix_model := linalg.MATRIX4F32_IDENTITY
        matrix_view  := linalg.matrix4_look_at_f32({ 0.0, -5.0, 0.0 }, { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 1.0 })
        matrix_proj  := linalg.matrix4_perspective_f32(90, 800.0 / 600.0, 0.1, 100)

        gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_model)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(3, 1, gl.FALSE, cast(^f32)&matrix_proj)


        gl.BindVertexArray(array_vertex)
        gl.DrawArraysInstanced(gl.TRIANGLES, 0, cast(i32)len(vertexes), 1)

        glfw.SwapBuffers(window)
    }
}
