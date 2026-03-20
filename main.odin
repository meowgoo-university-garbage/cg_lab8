package main

import "core:fmt"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

// NOTE: some boilerplate copied from here
// https://github.com/vassvik/odin-gl_examples

// NOTE: dodecahedron vertexes and model
// https://en.wikipedia.org/wiki/Regular_dodecahedron#Relation_to_the_golden_ratio

PHI :: 1.618

DODECAHEDRON : [][3]f32 : {
    // ORANGE
    { 1, 1, 1 },                // 0
    { 1, 1, -1 },               // 1
    { 1, -1, 1 },               // 2
    { 1, -1, -1 },              // 3
    { -1, 1, 1 },               // 4
    { -1, 1, -1 },              // 5
    { -1, -1, 1 },              // 6
    { -1, -1, -1 },             // 7


    // GREEN
    { 0, PHI, 1 / PHI },        // 8
    { 0, PHI, -1 / PHI },       // 9

    { 0, -PHI, 1 / PHI },       // 10
    { 0, -PHI, -1 / PHI },      // 11


    // BLUE
    { 1 / PHI, 0, PHI },        // 12
    { -1 / PHI, 0, PHI },       // 13

    { 1 / PHI, 0, -PHI },       // 14
    { -1 / PHI, 0, -PHI },      // 15


    // PINK
    { PHI, 1 / PHI, 0 },        // 16
    { PHI, -1 / PHI, 0 },       // 17

    { -PHI, 1 / PHI, 0 },       // 18
    { -PHI, -1 / PHI, 0 },      // 19
}

DODECAHEDRON_INDEXES : [][3]int : {
    { 6, 10, 13 },
    { 10, 12, 13 },
    { 10, 2, 12 },

    { 19, 7, 6 },
    { 6, 7, 10 },
    { 10, 7, 11 },

    { 10, 11, 3 },
    { 3, 2, 10 },
    { 3, 17, 2 },
    
    { 12, 2, 17 },
    { 17, 0, 12 },
    { 17, 16, 0 },

    { 17, 3, 14 },
    { 14, 16, 17 },
    { 14, 1, 16 },

    { 11, 7, 15 },
    { 11, 15, 3 },
    { 15, 14, 3 },

    { 4, 6, 13 },
    { 4, 18, 6 },
    { 18, 19, 6 },

    { 7, 19, 18 },
    { 7, 18, 5 },
    { 7, 5, 15 },

    { 4, 5, 18 },
    { 4, 8, 5 },
    { 8, 9, 5 },

    { 13, 12, 4 },
    { 12, 8, 4 },
    { 12, 0, 8 },

    { 5, 14, 15 },
    { 5, 9, 14 },
    { 9, 1, 14 },

    { 0, 9, 8 },
    { 0, 16, 9 },
    { 16, 1, 9 }
}

MAJOR :: 4
MINOR :: 6

Vertex :: struct {
    pos : [3]f32,
    col : [3]f32,
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

    window := glfw.CreateWindow(800, 600, "lab1 __FLOAT__", nil, nil)
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

    vertexes_list : [dynamic]Vertex
    for pos in DODECAHEDRON {
        append(&vertexes_list, Vertex{ pos = pos, col = { rand.float32(), rand.float32(), rand.float32() } })
    }

    vertexes : [dynamic]Vertex
    for index in DODECAHEDRON_INDEXES {
        append(&vertexes, vertexes_list[index.x])
        append(&vertexes, vertexes_list[index.y])
        append(&vertexes, vertexes_list[index.z])
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

        gl.UseProgram(program)

        time_now := time.now()
        time_passed := cast(f32)time.duration_seconds(time.diff(time_start, time_now))
        gl.Uniform1f(0, time_passed)

        matrix_model := linalg.matrix4_translate_f32({ 0.0, 0.0, 1.0 } * math.sin(time_passed)) * linalg.matrix4_rotate_f32(time_passed, { 1.0, 1.0, 1.0 })
        matrix_view  := linalg.matrix4_look_at_f32({ 0.0, -8.0, 0.0 }, { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 1.0 })
        matrix_proj  := linalg.matrix4_perspective_f32(0.25 * math.PI, 800.0 / 600.0, 0.1, 100)

        gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_model)
        gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_view)
        gl.UniformMatrix4fv(3, 1, gl.FALSE, cast(^f32)&matrix_proj)

        gl.BindVertexArray(array_vertex)
        gl.DrawArraysInstanced(gl.TRIANGLES, 0, cast(i32)len(vertexes), 1)

        glfw.SwapBuffers(window)
    }
}
