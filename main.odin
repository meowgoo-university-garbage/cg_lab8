package main

import "core:fmt"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import myglfw "./glfw"

random_bright :: proc () -> [3]f32 {
    random_bright_single :: proc () -> f32 {
        return (rand.float32() / 2) + 0.5
    }
    return { random_bright_single(), random_bright_single(), random_bright_single() }
}

random_dark :: proc () -> [3]f32 {
    random_dark_single :: proc () -> f32 {
        return rand.float32() / 2
    }
    return { random_dark_single(), random_dark_single(), random_dark_single() }
}


s :: math.SQRT_THREE

VERTEXES : []Vertex : {
    { pos = { -1, -1, 1 },    col = {  }, nor = { -s, -s, s   } },
    { pos = { 1, -1, 1 },     col = {  }, nor = { s, -s, s    } },
    { pos = { 1, 1, 1 },      col = {  }, nor = { s, s, s     } },
    { pos = { -1, 1, 1 },     col = {  }, nor = { -s, s, s    } },
    { pos = { -1, -1, -1 },   col = {  }, nor = { -s, -s, -s  } },
    { pos = { 1, -1, -1 },    col = {  }, nor = { s, -s, -s   } },
    { pos = { 1, 1, -1 },     col = {  }, nor = { s, s, -s    } },
    { pos = { -1, 1, -1 },    col = {  }, nor = { -s, s, -s   } },
}

INDEXES : []u32 : {
    0, 1, 2,
    2, 3, 0,
    0, 4, 5,
    5, 1, 0,
    1, 5, 6,
    6, 2, 1,
    2, 6, 7,
    7, 3, 2,
    3, 7, 4,
    4, 0, 3,
    5, 4, 6,
    6, 7, 4
}




Transform :: struct {
    pos : [3]f32,
    rot : quaternion128,
    scale : [3]f32,
}




MAJOR :: 4
MINOR :: 6

Vertex :: struct {
    pos : [3]f32,
    col : [3]f32,
    nor : [3]f32,
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
    glfw.WindowHint_bool(glfw.RESIZABLE, false)

    window := glfw.CreateWindow(800, 600, "lab4 __FLOAT__", nil, nil)
    if window == nil {
        fmt.println("bad")
        return
    }

    myglfw.SetCursorInputMode(window, .Disabled)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    gl.load_up_to(MAJOR, MINOR, proc (p : rawptr, name : cstring) {
        (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
    })

    program_box, _ := gl.load_shaders_file("vertex.glsl", "fragment.glsl")
    defer gl.DeleteProgram(program_box)

    program_lid, _ := gl.load_shaders_file("vertex-lid.glsl", "fragment-lid.glsl")
    defer gl.DeleteProgram(program_lid)

    array_vertex : u32
    gl.GenVertexArrays(1, &array_vertex)
    defer gl.DeleteVertexArrays(1, &array_vertex)
    gl.BindVertexArray(array_vertex)



    vertexes : [dynamic]Vertex
    for v in VERTEXES {
        v := v
        v.col = random_bright()
        append(&vertexes, v)
    }

    indexes : []u32
    indexes = INDEXES

    buffer_vertex : u32
    gl.GenBuffers(1, &buffer_vertex)
    defer gl.DeleteBuffers(1, &buffer_vertex)

    gl.BindBuffer(gl.ARRAY_BUFFER, buffer_vertex)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Vertex) * len(vertexes), raw_data(vertexes), gl.STATIC_DRAW)



    buffer_index : u32
    gl.GenBuffers(1, &buffer_index)
    defer gl.DeleteBuffers(1, &buffer_index)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer_index)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indexes), raw_data(indexes), gl.STATIC_DRAW)


    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, pos))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, col))



    time_start := time.now()
    time_last := time.now()



    WindowData :: struct{
        orthogonal : bool,
    }

    wdata : WindowData = {
        orthogonal = false,
    }
    glfw.SetWindowUserPointer(window, &wdata)


    myglfw.SetKeyCallback(window, proc "c" (window : glfw.WindowHandle, key : myglfw.Key, scancode : myglfw.Scancode, action : myglfw.KeyAction, mods : myglfw.Mods) {
        wdata := cast(^WindowData)glfw.GetWindowUserPointer(window)

        if action != .Press { return }

        #partial switch key {
        case .Space:
            wdata.orthogonal = !wdata.orthogonal
        case: return
        }
    })

    gl.Enable(gl.DEPTH_TEST)


    position : [3]f32 = { 0, 0, 0 }
    rotation : f32
    scale : f32 = 0.3

    cursor_old : [2]f32


    transform_player : Transform

    transform_box : Transform = {
        pos = { 0, 0, 0 },
        rot = linalg.QUATERNIONF32_IDENTITY,
        scale = ({ 1, 1, 1 } * 0.3),
    }

    transform_lid : Transform = {
        pos = { 0, 0, 1 + 0.1 },
        rot = linalg.quaternion_from_euler_angles_f32(1, 0, 0, .XYZ),
        scale = { 1, 1, 0.1 },
    }



    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()


        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)


        time_now := time.now()
        time_passed := cast(f32)time.duration_seconds(time.diff(time_start, time_now))
        time_delta := cast(f32)time.duration_seconds(time.diff(time_last, time_now))
        defer time_last = time_now
        gl.Uniform1f(0, time_passed)





        cursor_pos := myglfw.GetCursorPosf32(window)
        defer cursor_old = cursor_pos
        cursor_delta := cursor_pos - cursor_old

        yaw, pitch, _ := linalg.euler_angles_from_quaternion_f32(transform_player.rot, .ZXY)

        sensitivity :: 0.3
        pitch_safety :: 0.1

        yaw   -= cursor_delta.x * time_delta * sensitivity
        pitch -= cursor_delta.y * time_delta * sensitivity
        if pitch <= -math.PI / 2 + pitch_safety { pitch = -math.PI / 2 + pitch_safety }
        if pitch >= math.PI / 2 - pitch_safety  { pitch = math.PI / 2 - pitch_safety }

        transform_player.rot = linalg.quaternion_from_euler_angles_f32(yaw, pitch, 0, .ZXY)





        playerMovement : [3]f32 =
            {  0,  1,  0 } * myglfw.IsKeyPressed_f32(window, .LetterW) +
            {  0, -1,  0 } * myglfw.IsKeyPressed_f32(window, .LetterS) +
            {  1,  0,  0 } * myglfw.IsKeyPressed_f32(window, .LetterD) +
            { -1,  0,  0 } * myglfw.IsKeyPressed_f32(window, .LetterA) +
            {  0,  0,  1 } * myglfw.IsKeyPressed_f32(window, .Space) +
            {  0,  0, -1 } * myglfw.IsKeyPressed_f32(window, .LeftShift)
        playerMovement = linalg.normalize0(playerMovement)


        movementRotation := linalg.matrix4_rotate_f32(yaw, { 0, 0, 1 })


        playerMovement = (movementRotation * [4]f32{ playerMovement.x, playerMovement.y, playerMovement.z, 0 }).xyz
        playerMovement = linalg.normalize0(playerMovement) * time_delta
        transform_player.pos += playerMovement





        {
            lid, _, _ := linalg.euler_angles_from_quaternion_f32(transform_lid.rot, .XYZ)
            lid +=  1 * myglfw.IsKeyPressed_f32(window, .LetterK) * time_delta
            lid += -1 * myglfw.IsKeyPressed_f32(window, .LetterJ) * time_delta
            transform_lid.rot = linalg.quaternion_from_euler_angles_f32(lid, 0, 0, .XYZ)
        }

        {
            transform_box.rot = linalg.quaternion_angle_axis_f32(-1 * time_delta * myglfw.IsKeyPressed_f32(window, .LetterH), { 1, 1, 1 }) * transform_box.rot
            transform_box.rot = linalg.quaternion_angle_axis_f32( 1 * time_delta * myglfw.IsKeyPressed_f32(window, .LetterL), { 1, 1, 1 }) * transform_box.rot
        }


        viewDirection := (linalg.matrix4_from_quaternion_f32(transform_player.rot) * [4]f32{ 0.0, 1.0, 0.0, 0.0 }).xyz
        matrix_view  := linalg.matrix4_look_at_f32(transform_player.pos, transform_player.pos + viewDirection, { 0.0, 0.0, 1.0 })

        matrix_proj := linalg.matrix4_perspective_f32(0.25 * math.PI, 800.0 / 600.0, 0.1, 100)



        // BOX
        {
            gl.UseProgram(program_box)

            matrix_model := linalg.matrix4_translate_f32(transform_box.pos) * linalg.matrix4_from_quaternion_f32(transform_box.rot) * linalg.matrix4_scale_f32(transform_box.scale)

            gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_model)
            gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_view)
            gl.UniformMatrix4fv(3, 1, gl.FALSE, cast(^f32)&matrix_proj)

            gl.BindVertexArray(array_vertex)
            gl.DrawElements(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil)
        }


        // LID
        {
            gl.UseProgram(program_lid)

            matrix_model_parent := linalg.matrix4_translate_f32(transform_box.pos) * linalg.matrix4_from_quaternion_f32(transform_box.rot) * linalg.matrix4_scale_f32(transform_box.scale)
            matrix_rotation := linalg.matrix4_translate_f32({ 0, -1, 0 }) * linalg.matrix4_from_quaternion_f32(transform_lid.rot) * linalg.matrix4_translate_f32({ 0, 1, 0 })
            matrix_model := linalg.matrix4_translate_f32(transform_lid.pos) * matrix_rotation * linalg.matrix4_scale_f32(transform_lid.scale)
            matrix_model = matrix_model_parent * matrix_model

            gl.UniformMatrix4fv(1, 1, gl.FALSE, cast(^f32)&matrix_model)
            gl.UniformMatrix4fv(2, 1, gl.FALSE, cast(^f32)&matrix_view)
            gl.UniformMatrix4fv(3, 1, gl.FALSE, cast(^f32)&matrix_proj)

            gl.BindVertexArray(array_vertex)
            gl.DrawElements(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil)
        }

        glfw.SwapBuffers(window)
    }
}
