package obj

import sc "core:strconv"
import str "core:strings"
import "core:fmt"
import "core:log"

VPosition :: [3]f32
VNormal :: [3]f32
VTexture :: [2]f32

FaceVertex :: [3]int
Face :: [3]FaceVertex

parse_f32 :: proc (s : string) -> (value : f32, rest : string, ok : bool) {
    read : int
    value, read, ok = sc.parse_f32_prefix(s)
    rest = s[read:]
    return
}

parse_int :: proc (s : string) -> (value : int, rest : string, ok : bool) {
    valuep : f32

    // NOTE: for some reason Odin doesn't have parse_int_prefix, I'm too lazy to make it myself atm
    valuep, rest, ok = parse_f32(s)
    value = cast(int)valuep

    return
}

is_eof :: proc (s : string) -> bool { return len(s) == 0 }

parse_eol :: proc (s : string) -> (rest : string) {
    for i := 0; i < len(s); i += 1 {
        if s[i] == '\n' do return s[i+1:]
    }
    return s[len(s):]
}

parse_byte :: proc (s : string, byte : u8) -> (value : u8, rest : string, ok : bool = false) {
    if len(s) == 0 do return
    if s[0] != byte do return
    return byte, s[1:], true
}

is_whitespace :: proc (byte : u8) -> bool {
    return byte == ' ' || byte == '\n'
}

parse_whitespace :: proc (s : string, mandatory : bool = false) -> (rest : string, ok : bool = false) {
    if mandatory && len(s) == 0 do return
    if mandatory && !is_whitespace(s[0]) do return
    for i := 0; i < len(s); i += 1 {
        if !is_whitespace(s[i]) do return s[i:], true
    }
    return s[len(s):], true
}

parse_v :: proc (s : string) -> (value : VPosition, rest : string, ok : bool = false) {
    s := s

    _, s = parse_byte(s, 'v') or_return
    s = parse_whitespace(s, true) or_return

    value.x, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    value.y, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    value.z, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    ok = true
    rest = s
    return
}

parse_vt :: proc (s : string) -> (value : VTexture, rest : string, ok : bool = false) {
    s := s

    _, s = parse_byte(s, 'v') or_return
    _, s = parse_byte(s, 't') or_return
    s = parse_whitespace(s, true) or_return

    value.x, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    value.y, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    ok = true
    rest = s
    return
}

parse_vn :: proc (s : string) -> (value : VNormal, rest : string, ok : bool = false) {
    s := s

    _, s = parse_byte(s, 'v') or_return
    _, s = parse_byte(s, 'n') or_return
    s = parse_whitespace(s, true) or_return

    value.x, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    value.y, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    value.z, s = parse_f32(s) or_return
    s = parse_whitespace(s, true) or_return

    ok = true
    rest = s
    return
}

parse_f_v :: proc (s : string) -> (value : FaceVertex, rest : string, ok : bool = false) {
    s := s

    value[0], s = parse_int(s) or_return

    _, s = parse_byte(s, '/') or_return

    value[1], s = parse_int(s) or_return

    _, s = parse_byte(s, '/') or_return

    value[2], s = parse_int(s) or_return

    ok = true
    rest = s
    return
}

parse_f :: proc (s : string) -> (value : Face, rest : string, ok : bool = false) {
    s := s

    _, s = parse_byte(s, 'f') or_return
    s = parse_whitespace(s, true) or_return

    value[0], s = parse_f_v(s) or_return
    s = parse_whitespace(s, true) or_return

    value[1], s = parse_f_v(s) or_return
    s = parse_whitespace(s, true) or_return

    value[2], s = parse_f_v(s) or_return
    s = parse_whitespace(s, true) or_return

    ok = true
    rest = s
    return
}

parse_obj :: proc (s : string, allocator := context.allocator) -> (vposr : []VPosition, vtexr : []VTexture, vnorr : []VNormal, facesr : []Face, ok : bool) {
    vpos := make([dynamic]VPosition, allocator)
    vtex := make([dynamic]VTexture, allocator)
    vnor := make([dynamic]VNormal, allocator)
    faces := make([dynamic]Face, allocator)

    defer if !ok {
        delete(vpos)
        delete(vtex)
        delete(vnor)
        delete(faces)
    }

    s := s
    for !is_eof(s) {
        if false {}
        else if str.has_prefix(s, "vt") {
            vt : VTexture
            vt, s, ok = parse_vt(s)
            if !ok do return
            append(&vtex, vt)
        }
        else if str.has_prefix(s, "vn") {
            vn : VNormal
            vn, s, ok = parse_vn(s)
            if !ok do return
            append(&vnor, vn)
        }
        else if str.has_prefix(s, "v") {
            v : VPosition
            v, s, ok = parse_v(s)
            if !ok do return
            append(&vpos, v)
        }
        else if str.has_prefix(s, "f") {
            f : Face
            f, s, ok = parse_f(s)
            if !ok do return
            append(&faces, f)
        }
        else if str.has_prefix(s, "#") {
            s = parse_eol(s)
        }
        else {
            log.warnf("Couldn't parse line starting with %v", cast(rune)s[0])
            s = parse_eol(s)
        }
    }

    ok = true
    return vpos[:], vtex[:], vnor[:], faces[:], true
}

