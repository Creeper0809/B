// path.b - Path utilities for v3.8

import std.io;
import std.str;

func path_dirname(path, path_len) {
    var last_slash = 0 - 1;
    for(var i = 0; i < path_len; i++){
        if (*(*u8)(path + i) == 47) {
            last_slash = i;
        }
    }

    if (last_slash < 0) {
        var result = heap_alloc(2);
        *(*u8)result = 46;
        *(*u8)(result + 1) = 0;
        return result;
    }

    var result = heap_alloc(last_slash + 2);
    str_copy(result, path, last_slash);
    *(*u8)(result + last_slash) = 0;
    return result;
}

func path_join(dir, dir_len, name, name_len) {
    var slash = heap_alloc(1);
    *(*u8)slash = 47;
    return str_concat3(dir, dir_len, slash, 1, name, name_len);
}

func module_to_path(name, name_len) {
    var ext = heap_alloc(2);
    *(*u8)ext = 46;
    *(*u8)(ext + 1) = 98;
    return str_concat(name, name_len, ext, 2);
}

// path_basename_noext: "a/b/c.txt" -> "c"
func path_basename_noext(path, path_len) {
    var last_slash = 0 - 1;
    for (var i = 0; i < path_len; i++) {
        if (*(*u8)(path + i) == 47) { last_slash = i; }
    }
    var start: u64 = 0;
    if (last_slash >= 0) { start = (u64)(last_slash + 1); }

    var last_dot = 0 - 1;
    for (var j = start; j < path_len; j++) {
        if (*(*u8)(path + j) == 46) { last_dot = (i64)j; }
    }

    var end: u64 = path_len;
    if (last_dot >= 0) { end = (u64)last_dot; }
    if (end < start) { end = start; }

    var out_len: u64 = end - start;
    var out = heap_alloc(out_len + 1);
    if (out_len > 0) {
        str_copy(out, path + start, out_len);
    }
    *(*u8)(out + out_len) = 0;
    return out;
}
