// Test 10: Collections (Vec + HashMap)
// Expect exit code: 0

import std.vec;
import std.hashmap;
import std.str;

func main(argc, argv) {
    var v = vec_new(4);
    var i = 0;
    while (i < 10) {
        vec_push(v, i * 10);
        i = i + 1;
    }
    if (vec_len(v) != 10) { return 1; }
    if (vec_get(v, 0) != 0) { return 2; }
    if (vec_get(v, 5) != 50) { return 3; }
    vec_set(v, 5, 999);
    if (vec_get(v, 5) != 999) { return 4; }

    var map = hashmap_new(8);
    var key1 = "apple";
    var key2 = "banana";
    var key3 = "cherry";
    hashmap_put(map, key1, str_len(key1), 100);
    hashmap_put(map, key2, str_len(key2), 200);
    hashmap_put(map, key3, str_len(key3), 300);

    if (hashmap_get(map, key1, str_len(key1)) != 100) { return 5; }
    if (hashmap_get(map, key2, str_len(key2)) != 200) { return 6; }
    if (hashmap_get(map, key3, str_len(key3)) != 300) { return 7; }
    if (!hashmap_has(map, "apple", 5)) { return 8; }
    if (hashmap_has(map, "orange", 6)) { return 9; }

    return 0;
}
