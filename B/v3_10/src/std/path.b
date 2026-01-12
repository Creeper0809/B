// path.b - Path utilities for v3.8

import std.io;
import std.str;

func path_dirname(path, path_len) {
    var last_slash = 0 - 1;
    var i = 0;
    while (i < path_len) {
        if (*(*u8)(path + i) == 47) {
            last_slash = i;
        }
        i = i + 1;
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
