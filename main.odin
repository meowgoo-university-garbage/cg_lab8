package main

import "core:fmt"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import myglfw "./glfw"
import obj "./obj"
import "core:os"
import img "core:image"
import img_png "core:image/png"




Transform :: struct {
    pos : [3]f32,
    rot : quaternion128,
    scale : [3]f32,
}

Index :: u32

Mesh :: struct {
    array_index : []u32,
    array_vertex : []Vertex,
}

loadObj :: proc (data : []u8) -> (mesh : Mesh, ok : bool = false) {
    vertexMap := make(map[Vertex]Index)

    vertexes := make([dynamic]Vertex)
    indexes := make([dynamic]Index)

    vpos, vtex, vnor, faces := obj.parse_obj(string(data)) or_return

    // NOTE: check allocator
    defer {
        delete(vpos)
        delete(vtex)
        delete(vnor)
        delete(faces)
    }

    for face in faces {
        for vertex in face {
            pos := vpos[vertex.x - 1]
            tex := vtex[vertex.y - 1]
            nor := vnor[vertex.z - 1]
            tex.y = 1.0 - tex.y

            v := Vertex{
                pos = pos,
                col = { 1.0, 1.0, 1.0 },
                tex = tex,
                nor = nor,
            }

            i := Index(len(vertexes))

            newIndex, exists := vertexMap[v]

            if !exists {
                vertexMap[v] = i
                append(&vertexes, v)
                append(&indexes, i)
            }
            else {
                append(&indexes, newIndex)
            }
        }
    }

    mesh = {
        array_vertex = vertexes[:],
        array_index = indexes[:],
    }

    ok = true
    return
}


MAJOR :: 4
MINOR :: 6

Vertex :: struct {
    pos : [3]f32,
    col : [3]f32,
    nor : [3]f32,
    tex : [2]f32,
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





    model_bytes, _ := os.read_entire_file_from_path("cube.obj", context.allocator)
    model_mesh, ok := loadObj(model_bytes)
    if !ok {
        fmt.println("BAD model")
    }




    vertexes : [dynamic]Vertex
    for v in model_mesh.array_vertex {
        v := v
        // v.col = random_bright()
        append(&vertexes, v)
    }

    indexes : []u32
    indexes = model_mesh.array_index

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
    gl.EnableVertexAttribArray(2)
    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, pos))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, col))
    gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, nor))
    gl.VertexAttribPointer(3, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tex))



    time_start := time.now()
    time_last := time.now()




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



    WindowData :: struct {
        texture_ralsei : u32,
        texture_osaka : u32,

        texture_current : u32,
    }



    myglfw.SetMouseButtonCallback(window, proc "c" (window : glfw.WindowHandle, button : myglfw.MouseButton, action : myglfw.Action, mods : myglfw.Mods) {
        if action != .Press { return }

        wdata := cast(^WindowData)glfw.GetWindowUserPointer(window)
        if wdata.texture_current == wdata.texture_ralsei {
            wdata.texture_current = wdata.texture_osaka
        }
        else {
            wdata.texture_current = wdata.texture_ralsei
        }

        gl.BindTexture(gl.TEXTURE_2D, wdata.texture_current)
    })



    texture_ralsei : u32
    gl.GenTextures(1, &texture_ralsei)
    gl.BindTexture(gl.TEXTURE_2D, texture_ralsei)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    image_ralsei, _ := img.load_from_file("ralsei.png", { .alpha_add_if_missing })
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, cast(i32)image_ralsei.width, cast(i32)image_ralsei.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(image_ralsei.pixels.buf))
    gl.GenerateMipmap(gl.TEXTURE_2D)




    texture_osaka : u32
    gl.GenTextures(1, &texture_osaka)
    gl.BindTexture(gl.TEXTURE_2D, texture_osaka)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    image_osaka, _ := img.load_from_file("osaka.png", { .alpha_add_if_missing })
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, cast(i32)image_osaka.width, cast(i32)image_osaka.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(image_osaka.pixels.buf))
    gl.GenerateMipmap(gl.TEXTURE_2D)



    wdata : WindowData = {
        texture_ralsei = texture_ralsei,
        texture_osaka = texture_osaka,

        texture_current = texture_ralsei,
    }

    glfw.SetWindowUserPointer(window, &wdata)



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
            gl.Uniform3f(4, transform_player.pos.x, transform_player.pos.y, transform_player.pos.z)

            gl.BindVertexArray(array_vertex)
            gl.DrawElements(gl.TRIANGLES, cast(i32)len(indexes), gl.UNSIGNED_INT, nil)
        }

        glfw.SwapBuffers(window)
    }
}
