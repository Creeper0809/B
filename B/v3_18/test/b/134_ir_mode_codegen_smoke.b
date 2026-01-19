// Expect exit code: 0

import std.vec;
import ast;
import types;
import codegen;
import opt;

func main() -> i64 {
    opt_set_ir_mode(IR_SSA);
    opt_set_level(0);

    var stmts: u64 = vec_new(4);
    vec_push(stmts, ast_return(ast_literal(1)));
    var body: u64 = ast_block(stmts);

    var params: u64 = vec_new(2);
    var fn: u64 = ast_func_ex("main", 4, params, TYPE_I64, 0, 0, 0, 0, 0, 0, 0, body);

    var funcs: u64 = vec_new(2);
    vec_push(funcs, fn);

    var consts: u64 = vec_new(2);
    var imports: u64 = vec_new(2);
    var prog: u64 = ast_program(funcs, consts, imports);

    cg_program_with_sigs(prog, funcs);
    return 0;
}
