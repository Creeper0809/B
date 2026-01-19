// ssa.b - SSA data structures (v3_17)
//
// 제네릭 없이 SSA를 구성하기 위한 전용 자료구조 집합.
// - BlockList: BasicBlock 포인터 배열 (동적 확장)
// - Instruction: 침습적 연결 리스트 노드
// - SSAContext: 전체 SSA 그래프 컨텍스트

// ============================================
// Constants
// ============================================

const SIZEOF_SSA_INST = 48;   // 6 * u64 (op tagged in prev)
const SIZEOF_SSA_BLOCK = 112;  // 14 * u64
const SIZEOF_SSA_FUNC = 72;   // 9 * u64
const SIZEOF_SSA_CTX = 40;    // 5 * u64
const SIZEOF_SSA_PHI_ARG = 24; // 3 * u64

const SSA_OP_NOP = 0;
const SSA_OP_ENTRY = 1;
const SSA_OP_PHI = 2;

// Basic arithmetic
const SSA_OP_CONST = 10;
const SSA_OP_ADD = 11;
const SSA_OP_SUB = 12;
const SSA_OP_MUL = 13;
const SSA_OP_DIV = 14;

// Comparison ops
const SSA_OP_EQ = 15;
const SSA_OP_NE = 16;
const SSA_OP_LT = 17;
const SSA_OP_GT = 18;
const SSA_OP_LE = 19;
const SSA_OP_GE = 20;

// Bitwise/shift/mod ops
const SSA_OP_MOD = 33;
const SSA_OP_AND = 34;
const SSA_OP_OR = 35;
const SSA_OP_XOR = 36;
const SSA_OP_SHL = 37;
const SSA_OP_SHR = 38;

// Memory ops (mem2reg 이전 단계)
const SSA_OP_LOAD = 25;
const SSA_OP_STORE = 26;
const SSA_OP_PARAM = 27;

// Control flow
const SSA_OP_JMP = 30;
const SSA_OP_BR = 31;
const SSA_OP_RET = 32;

// SSA destruction helper
const SSA_OP_COPY = 40;

// Address helpers
const SSA_OP_LEA_STR = 50;
const SSA_OP_LEA_LOCAL = 51;
const SSA_OP_LEA_GLOBAL = 52;

// Memory ops (explicit address)
const SSA_OP_LOAD8 = 60;
const SSA_OP_LOAD16 = 61;
const SSA_OP_LOAD32 = 62;
const SSA_OP_LOAD64 = 63;
const SSA_OP_STORE8 = 64;
const SSA_OP_STORE16 = 65;
const SSA_OP_STORE32 = 66;
const SSA_OP_STORE64 = 67;

const SSA_OPR_VALUE_MASK = 9223372036854775807;

// ============================================
// SSA Core Types
// ============================================

packed struct InstMeta {
    op: u16;
}

struct SSAInstruction {
    prev: *tagged(InstMeta) u8;
    next: *SSAInstruction;
    id: u64;
    dest: u64; // virtual register id
    src1: u64; // tagged operand (const/reg) or phi args head
    src2: u64; // tagged operand (const/reg)
}

struct SSAPhiArg {
    val: u64;        // incoming value (virtual register id)
    block_id: u64;   // predecessor block id
    next: *SSAPhiArg;
}

struct SSABlock {
    id: u64;
    phi_head: *SSAInstruction;
    inst_head: *SSAInstruction;
    inst_tail: *SSAInstruction;
    preds_data: u64;
    preds_len: u64;
    preds_cap: u64;
    succs_data: u64;
    succs_len: u64;
    succs_cap: u64;
    df_data: u64;
    df_len: u64;
    df_cap: u64;
    dom_parent: *SSABlock;
}

struct SSAFunction {
    id: u64;
    name_ptr: u64;
    name_len: u64;
    blocks_data: u64; // *SSABlock (pointer array)
    blocks_len: u64;
    blocks_cap: u64;
    entry: *SSABlock;
    reg_map_data: u64; // *u64 (virtual reg -> phys reg)
    reg_map_len: u64;
}

struct SSAContext {
    funcs_data: u64; // *SSAFunction (pointer array)
    funcs_len: u64;
    funcs_cap: u64;
    next_block_id: u64;
    next_inst_id: u64;
}
