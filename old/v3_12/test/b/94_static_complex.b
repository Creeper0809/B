// 94_static_complex.b - Complex static method and variable test
// Expect exit code: 42

struct Database {
    id: i64;
}

impl Database {
    static var connection_count: i64 = 0;
    static var total_queries: i64 = 0;
    
    static func connect() -> Database {
        Database.connection_count = Database.get_connection_count() + 1;
        var db: Database;
        db.id = Database.connection_count;
        return db;
    }
    
    static func disconnect(db: *Database) -> i64 {
        Database.connection_count = Database.connection_count - 1;
        return Database.connection_count;
    }
    
    static func get_connection_count() -> i64 {
        return Database.connection_count;
    }
    
    static func query(db: *Database) -> i64 {
        Database.total_queries = Database.total_queries + 1;
        return db->id;
    }
    
    static func get_total_queries() -> i64 {
        return Database.total_queries;
    }
}

struct Logger {
    level: i64;
}

impl Logger {
    static var log_count: i64 = 0;
    
    static func log(msg_id: i64) -> i64 {
        Logger.log_count = Logger.log_count + 1;
        return Logger.get_count();
    }
    
    static func get_count() -> i64 {
        return Logger.log_count;
    }
    
    static func reset() -> i64 {
        Logger.log_count = 0;
        return 0;
    }
}

struct Calculator {
    dummy: i64;
}

impl Calculator {
    static func add(a: i64, b: i64) -> i64 {
        Logger.log(1);
        return a + b;
    }
    
    static func multiply(a: i64, b: i64) -> i64 {
        Logger_log(2);
        return a * b;
    }
    
    static func compute(x: i64, y: i64) -> i64 {
        var sum = Calculator.add(x, y);
        var product = Calculator_multiply(sum, 2);
        return product;
    }
}

func main() -> i64 {
    // Test Database static methods
    var db1: Database = Database.connect();
    var db2: Database = Database.connect();
    var db3: Database = Database_connect();
    
    var conn_count = Database.get_connection_count();
    if (conn_count != 3) {
        return 1;
    }
    
    // Test Database query
    Database.query(&db1);
    Database_query(&db2);
    Database.query(&db3);
    
    var queries = Database.get_total_queries();
    if (queries != 3) {
        return 2;
    }
    
    // Test disconnect
    Database.disconnect(&db1);
    var remaining = Database_get_connection_count();
    if (remaining != 2) {
        return 3;
    }
    
    // Test Logger with Calculator
    Logger.reset();
    var result = Calculator.compute(5, 10);
    
    // compute calls add (logs 1) and multiply (logs 2)
    var logs = Logger.get_count();
    if (logs != 2) {
        return 4;
    }
    
    // (5 + 10) * 2 = 30
    if (result != 30) {
        return 5;
    }
    
    // Final computation
    var final_result = Calculator.add(20, 22);
    
    // Should be 42
    if (final_result == 42) {
        return 42;
    }
    
    return 6;
}
