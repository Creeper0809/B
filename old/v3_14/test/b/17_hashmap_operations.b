// Test 17: HashMap Operations
import io;
import util;
import hashmap;

func main(argc, argv) {
    var map;
    var key1;
    var key2;
    var key3;
    
    emit("Testing HashMap:\n", 17);
    
    // Create hashmap
    map = hashmap_new(8);
    emit("Created hashmap\n", 16);
    
    // Prepare keys
    key1 = "apple";
    key2 = "banana";
    key3 = "cherry";
    
    // Put values
    emit("Putting values...\n", 18);
    hashmap_put(map, key1, str_len(key1), 100);
    hashmap_put(map, key2, str_len(key2), 200);
    hashmap_put(map, key3, str_len(key3), 300);
    
    // Get values
    emit("Getting values:\n", 16);
    
    emit("  ", 2);
    emit(key1, str_len(key1));
    emit(" = ", 3);
    emit_i64(hashmap_get(map, key1, str_len(key1)));
    emit_nl();
    
    emit("  ", 2);
    emit(key2, str_len(key2));
    emit(" = ", 3);
    emit_i64(hashmap_get(map, key2, str_len(key2)));
    emit_nl();
    
    emit("  ", 2);
    emit(key3, str_len(key3));
    emit(" = ", 3);
    emit_i64(hashmap_get(map, key3, str_len(key3)));
    emit_nl();
    
    // Check has
    if (hashmap_has(map, "apple", 5)) {
        emit("Has 'apple': yes\n", 17);
    }
    
    if (!hashmap_has(map, "orange", 6)) {
        emit("Has 'orange': no\n", 17);
    }
    
    return 0;
}
