// Test 10: Switch Statement
import io;
import util;

func day_name(day) {
    if (day == 0) {
        emit("Sunday", 6);
        return;
    }
    if (day == 1) {
        emit("Monday", 6);
        return;
    }
    if (day == 2) {
        emit("Tuesday", 7);
        return;
    }
    if (day == 3) {
        emit("Wednesday", 9);
        return;
    }
    if (day == 4) {
        emit("Thursday", 8);
        return;
    }
    if (day == 5) {
        emit("Friday", 6);
        return;
    }
    if (day == 6) {
        emit("Saturday", 8);
        return;
    }
    emit("Invalid day", 11);
}

func main(argc, argv) {
    var i;
    
    emit("Days of the week:\n", 18);
    i = 0;
    while (i < 8) {
        emit("Day ", 4);
        emit_i64(i);
        emit(": ", 2);
        day_name(i);
        emit_nl();
        i = i + 1;
    }
    
    return 0;
}
