# B v3.16 Syntax Reference

This document outlines the syntax and language features of the B compiler, version 3.16.

## 1. Lexical Structure

### 1.1. Comments

Single-line comments start with `//`. Multi-line comments are not supported.

```b
// This is a single-line comment.
```

### 1.2. Identifiers

Identifiers start with a letter (`a-z`, `A-Z`) followed by zero or more letters or digits (`0-9`).

### 1.3. Keywords

The following are reserved keywords:

`func`, `var`, `const`, `return`, `if`, `else`, `while`, `for`, `switch`, `case`, `default`, `break`, `continue`, `import`, `as`, `from`, `asm`, `true`, `false`, `struct`, `enum`, `impl`, `static`, `sizeof`, `tagged`, `packed`

Type keywords: `u8`, `u16`, `u32`, `u64`, `i64`, `char`

### 1.4. Literals

- **Integer Literals**: Decimal integers (e.g., `123`, `0`, `99`). Negative numbers are parsed with a unary minus.
- **Character Literals**: A single ASCII character enclosed in single quotes (e.g., `'a'`, `'\n'`).
- **String Literals**: A sequence of characters enclosed in double quotes (e.g., `"hello"`, `"line\n"`).
- **Boolean Literals**: `true` and `false`.

### 1.5. Operators and Delimiters

- **Arithmetic**: `+`, `-`, `*`, `/`, `%`
- **Bitwise**: `&`, `|`, `^`, `<<`, `>>`
- **Logical**: `&&`, `||`, `!`
- **Comparison**: `==`, `!=`, `<`, `>`, `<=`, `>=`
- **Assignment**: `=`, `+=`, `-=`, `*=`, `/=`, `%=`
- **Increment/Decrement**: `++`, `--` (prefix and postfix)
- **Member Access**: `.`, `->`
- **Pointer**: `*` (dereference), `&` (address-of)
- **Delimiters**: `( )`, `{ }`, `[ ]`, `;`, `:`, `,`
- **Function Return**: `->`

## 2. Types

### 2.1. Basic Types

- `u8`, `char` (alias for `u8`)
- `u16`
- `u32`
- `u64`
- `i64` (primarily used for signed values, but the type system often treats it as `u64`)

### 2.2. Pointer Types

Pointers are declared using `*`. Multiple `*` can be used for pointers to pointers.

```b
var p: *u64;      // Pointer to u64
var pp: **u8;     // Pointer to a pointer to u8
```

### 2.3. Tagged Pointers

A pointer can be marked as `tagged`, indicating it uses some of its bits to store a tag. An optional layout name can be provided in parentheses.

```b
var tp: *tagged u64;
var tlp: *tagged(MyLayout) u64;
```

**Limitations**:
- `tagged` can only be applied to the outermost pointer.
- `tagged` cannot be used with struct pointers.

### 2.4. Array Types

Arrays have a fixed size known at compile time.

```b
var arr: [10]u64; // Array of 10 u64s
```

**Limitations**:
- Arrays of structs are not supported.
- Multi-dimensional arrays are not directly supported.
- When passed as a function parameter, an array decays to a pointer to its first element.

### 2.5. Slice Types

Slices provide a view into a contiguous block of memory, defined by a pointer and a length.

```b
var s: []u64; // A slice of u64s
```

A slice literal `slice(ptr, len)` can be used to create a slice.

**Limitations**:
- Slices of structs are not supported.

### 2.6. Struct Types

Structs are user-defined aggregate data types.

```b
struct Point {
    x: u64;
    y: u64;
}
```

#### Packed Structs

The `packed` keyword can be used to define a struct where fields are bit-packed.

```b
packed struct Bitfield {
    a: u4;  // 4 bits
    b: u12; // 12 bits
    c: u8;  // 8 bits
}
```

**Limitations**:
- Fields in a packed struct must be unsigned integers (`u1` to `u64`).

## 3. Declarations

### 3.1. `const` Declarations

Constants must be initialized with a compile-time constant integer or character value.

```b
const MY_CONST = 100;
const NEWLINE = '\n';
```

### 3.2. `var` Declarations (Global and Local)

Variables can be declared at the global or function scope. The type can be explicitly specified. If no initializer is present, the variable is initialized to zero.

```b
var g_my_global; // Global, semicolon required

func my_func() {
    var x: u64 = 10;
    var y: *u8;
    var z: [5]u64;
}
```

### 3.3. `enum` Declarations

Enums define a set of named integer constants. The value automatically increments from the previous member.

```b
enum Color {
    RED,    // 0
    GREEN,  // 1
    BLUE,   // 2
}

enum Flags {
    A = 1,
    B = 2,
    C = 4,
}
```
The members are accessed as `EnumName_MemberName` (e.g., `Color_RED`).

### 3.4. `import` Declarations

Imports a module. The path is specified using dot notation. 선택적으로 심볼을 가져오거나 별칭을 부여할 수 있습니다.

```b
import std.io;
import my.module;

// Selective import
import str_eq from std.str;

// Selective import with alias
import str_eq as eq from std.str;
```

## 4. Functions and `impl` Blocks

### 4.1. Function Declarations

Functions are defined with `func`, a name, parameters, an optional return type, and a body.

```b
func add(a: u64, b: u64) -> u64 {
    return a + b;
}

func no_return() {
    // ...
}

**Note (Multi-Pass):**
- The compiler performs a signature collection pass before full codegen.
- Functions can be called before their definitions without explicit forward declarations.
```

### 4.2. `impl` Blocks

Methods can be associated with a struct using an `impl` block. Methods are called using `.` for values and `->` for pointers. `static` methods can be defined which do not take a `this` pointer.

```b
struct Counter {
    value: u64;
}

impl Counter {
    func increment(this: *Counter) {
        this->value = this->value + 1;
    }

    static func new() -> *Counter {
        var c: *Counter = (*Counter)heap_alloc(8);
        c->value = 0;
        return c;
    }
}

// Usage
var c: *Counter = Counter.new();
c->increment();
```
**Behind the Scenes**: `c->increment()` is syntactic sugar for `Counter_increment(c)`.

## 5. Expressions

B supports a standard set of expressions with C-like precedence rules.

- **Primary**: Literals, identifiers, `( ... )`.
- **Postfix**: `expr[idx]`, `expr.member`, `expr->member`, `func(...)`, `expr++`, `expr--`.
- **Prefix**: `&var`, `*ptr`, `!expr`, `-expr`, `++expr`, `--expr`.
- **Binary**: Standard arithmetic, logical, and bitwise operators.
- **Casting**: `(*TypeName)expr` or `(u64)expr`.
- **`sizeof`**: `sizeof(TypeName)` or `sizeof(*TypeName)`.
- **Slice Literal**: `slice(ptr_expr, len_expr)`.
- **Struct Literal**: `Point { 10, 20 }`.

## 6. Statements

Statements are terminated with a semicolon, except for block statements.

### 6.1. Control Flow

- **`if-else`**:
  ```b
  if (x > 0) {
      // ...
  } else if (x < 0) {
      // ...
  } else {
      // ...
  }
  ```
- **`while` loop**:
  ```b
  while (i < 10) {
      i = i + 1;
  }
  ```
- **`for` loop**: C-style `for` loops with init, condition, and update clauses.
  ```b
  for (var i: u64 = 0; i < 10; i = i + 1) {
      // ...
  }
  ```
- **`switch` statement**:
  ```b
  switch (val) {
      case 0:
          // ...
          break;
      case 1:
          // ...
          break;
      default:
          // ...
  }
  ```
- **Jump Statements**: `break;`, `continue;`, `return ...;`.

### 6.2. `asm` Blocks

Inline assembly can be included using `asm { ... }`. The content is passed directly to the assembler.

```b
asm {
    mov rax, 60
    mov rdi, 0
    syscall
}
```

## 7. Limitations and Quirks

- **Type System**: The type system is simple. There is no implicit casting between types. All casts must be explicit.
- **Error Handling**: Compile errors often result in a `panic`, halting compilation immediately. Error messages can be cryptic.
- **No Generics**: There is no support for generic programming.
- **Manual Memory Management**: Memory must be managed manually (e.g., via `heap_alloc` or other imported functions). There is no garbage collector.
- **Array/Slice of Structs**: Storing structs directly in arrays or slices is not supported; you must use pointers to structs instead (`[10]*MyStruct`).
- **Global Variables**: Global variables are declared with `var name;` at the top level but are not initialized. Their initialization state is zero by default.
- **String Handling**: Strings are treated as pointers to character data (`*u8`) and are not null-terminated by default. String literals are stored in the data segment.
- **Single-Pass Compilation**: The compiler is largely single-pass. This means you must declare functions, structs, and constants before you use them.
- **Struct Literals**: The number of values in a struct literal must exactly match the number of fields in the struct definition.
- **Packed Structs**: Bitfield access relies on specific code generation patterns and may have alignment or endianness assumptions that are not explicitly documented.

```
```