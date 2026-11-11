// RSD (1d7415b), Processor/Src with every `include expanded, and
// patched for tohost and a serial input (PATCHES in the script).
// Written by scripts/flatten.py. Do not edit.
// Copyright 2019- RSD contributors. Apache License 2.0 (LICENSE.RSD).
`define RSD_SYNTHESIS
`define RSD_SYNTHESIS_VIVADO
`define RSD_SYNTHESIS_FPGA
`define RSD_DISABLE_DEBUG_REGISTER
`define RSD_USE_EXTERNAL_MEMORY
`define RSD_MARCH_INT_ISSUE_WIDTH 2
`define REF input
// ---- BasicMacros.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.




// On each clock edge, it evaluates "exp" and if its result is false, it shows "msg".
// You can use a formatted string with parentheses in "msg" as follows:
// `RSD_ASSERT_CLK_FMT(clk, some_expression, ("%d", i))
/*
`define RSD_ASSERT_CLK_FMT(clk, exp, msg) \
    assert property (@(posedge clk) (exp)) \
        else $error msg;
*/

`ifdef RSD_SYNTHESIS
    // These macros are disabled in synthesys
    `define RSD_ASSERT_CLK_FMT(clk, exp, msg) 
    `define RSD_ASSERT_CLK(clk, exp, msg) 
`else
    `define RSD_ASSERT_CLK_FMT(clk, exp, msg) \
        always @(posedge clk) begin \
            if (!(exp)) begin \
                $display msg; \
            end \
        end 
    `define RSD_ASSERT_CLK(clk, exp, msg) `RSD_ASSERT_CLK_FMT(clk, exp, (msg))
`endif

// RSD_STATIC_ASSERT_FMT must be used from outside always_comb/always_ff blocks.
`define RSD_STATIC_ASSERT_FMT(exp, msg) \
    generate \
        if (!(exp)) begin \
            RSD_STATIC_ASSERT_FAILED non_existing_module(); \
        end \
    endgenerate \

//$error msg; \

`define RSD_STATIC_ASSERT(exp, msg) `RSD_STATIC_ASSERT_FMT(exp, (msg))

// ---- BasicTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.



package BasicTypes;



localparam TRUE  = 1'b1;
localparam FALSE = 1'b0;

// SID
localparam OP_SERIAL_WIDTH = 10;
typedef logic [OP_SERIAL_WIDTH-1:0] OpSerial;

// Byte
localparam BYTE_WIDTH = 8; // 1バイトのビット幅
typedef logic [ BYTE_WIDTH-1:0 ] BytePath;

// Instruction width
localparam INSN_WIDTH = 32;
typedef logic [INSN_WIDTH-1:0] InsnPath;

localparam INSN_BYTE_WIDTH = INSN_WIDTH / BYTE_WIDTH;
localparam INSN_ADDR_BIT_WIDTH = $clog2(INSN_BYTE_WIDTH);

// Address
localparam ADDR_WIDTH = 32;
localparam ADDR_WIDTH_BIT_SIZE = $clog2(ADDR_WIDTH);
localparam ADDR_BYTE_WIDTH = ADDR_WIDTH / BYTE_WIDTH;
typedef logic [ADDR_WIDTH-1:0] AddrPath;

// Data width
localparam DATA_WIDTH = 32;
localparam DATA_BYTE_WIDTH = DATA_WIDTH / BYTE_WIDTH;
localparam DATA_BYTE_WIDTH_BIT_SIZE = $clog2(DATA_BYTE_WIDTH);
typedef logic [DATA_WIDTH-1:0] DataPath;
typedef logic signed [DATA_WIDTH-1:0] SignedDataPath;
localparam DATA_MASK = 32'hffffffff;
localparam DATA_ZERO = 32'h00000000;

// Vector Data width
localparam VEC_WIDTH = 128;
localparam VEC_WORD_WIDTH = VEC_WIDTH / DATA_WIDTH;
localparam VEC_BYTE_WIDTH = VEC_WIDTH / BYTE_WIDTH;
localparam VEC_BYTE_WIDTH_BIT_SIZE = $clog2(VEC_BYTE_WIDTH);
localparam VEC_ADDR_MASK = 32'hfffffff0; // 下位VEC_BYTE_WIDTH_BIT_SIZEビットが0
typedef logic [VEC_WIDTH-1:0] VectorPath;

//
// --- Register File
//

// Logical vector register number width
localparam LSCALAR_NUM = 32;
localparam LSCALAR_NUM_BIT_WIDTH = $clog2( LSCALAR_NUM );
typedef logic [LSCALAR_NUM_BIT_WIDTH-1:0] LScalarRegNumPath;

// Physical register number width
localparam PSCALAR_NUM = 64;
localparam PSCALAR_NUM_BIT_WIDTH = $clog2( PSCALAR_NUM );
typedef logic [PSCALAR_NUM_BIT_WIDTH-1:0] PScalarRegNumPath;

// Logical vector register number width ( for SIMD )
localparam LVECTOR_NUM = 16;
localparam LVECTOR_NUM_BIT_WIDTH = $clog2( LVECTOR_NUM );
typedef logic [LVECTOR_NUM_BIT_WIDTH-1:0] LVectorRegNumPath;

// Physical vector register number width ( for SIMD )
localparam PVECTOR_NUM = 32;
localparam PVECTOR_NUM_BIT_WIDTH = $clog2( PVECTOR_NUM );
typedef logic [PVECTOR_NUM_BIT_WIDTH-1:0] PVectorRegNumPath;

// Logical general register ( scalar register + vector register ) number width
localparam LREG_NUM = 32;
localparam LREG_NUM_BIT_WIDTH = $clog2( LREG_NUM );
typedef struct packed { // LRegNumPath
`ifdef RSD_ENABLE_VECTOR_PATH
    logic isVector; // If TRUE, the register is for SIMD.
    logic [ LREG_NUM_BIT_WIDTH-2:0 ] regNum;
`else
    logic [ LREG_NUM_BIT_WIDTH-1:0 ] regNum;
`endif
} LRegNumPath;

// Physical general regiseter ( scalar register + vector register ) number width
`ifdef RSD_ENABLE_VECTOR_PATH
localparam PREG_NUM = 128; //PSCALAR_NUM + PVECTOR_NUM;
localparam PREG_NUM_BIT_WIDTH = $clog2( PREG_NUM );
typedef struct packed { // PRegNumPath
    logic isVector; // If TRUE, the register is for SIMD.
    logic [ PREG_NUM_BIT_WIDTH-1:0 ] regNum;
} PRegNumPath;
`else
localparam PREG_NUM = PSCALAR_NUM;
localparam PREG_NUM_BIT_WIDTH = $clog2( PREG_NUM );
typedef struct packed { // PRegNumPath
    logic [ PREG_NUM_BIT_WIDTH-1:0 ] regNum;
} PRegNumPath;
`endif


//
// --- Pipeline
//

// Fetch width
localparam FETCH_WIDTH = 2;
localparam FETCH_WIDTH_BIT_SIZE = $clog2( FETCH_WIDTH ); // log2(FETCH_WIDTH)
typedef logic [ FETCH_WIDTH_BIT_SIZE-1:0 ] FetchLaneIndexPath;

// Decode width
localparam DECODE_WIDTH = FETCH_WIDTH;
localparam DECODE_WIDTH_BIT_SIZE = FETCH_WIDTH_BIT_SIZE; // log2(DECODE_WIDTH)
typedef logic [ DECODE_WIDTH_BIT_SIZE-1:0 ] DecodeLaneIndexPath;

// Rename width
localparam RENAME_WIDTH = FETCH_WIDTH;
localparam RENAME_WIDTH_BIT_SIZE = FETCH_WIDTH_BIT_SIZE; // log2(RENAME_WIDTH)
typedef logic [ RENAME_WIDTH_BIT_SIZE-1:0 ] RenameLaneIndexPath;
typedef logic unsigned [ $clog2(RENAME_WIDTH):0 ] RenameLaneCountPath;

// Dispatch width
localparam DISPATCH_WIDTH = FETCH_WIDTH;
localparam DISPATCH_WIDTH_BIT_SIZE = FETCH_WIDTH_BIT_SIZE; // log2(DISPATCH_WIDTH)
typedef logic [ DISPATCH_WIDTH_BIT_SIZE-1:0 ] DispatchLaneIndexPath;

// Issue width
`ifdef RSD_MARCH_INT_ISSUE_WIDTH
    localparam INT_ISSUE_WIDTH =`RSD_MARCH_INT_ISSUE_WIDTH;
`else
    localparam INT_ISSUE_WIDTH = 2;
`endif
localparam INT_ISSUE_WIDTH_BIT_SIZE = 1; // log2(INT_ISSUE_WIDTH)
typedef logic [ INT_ISSUE_WIDTH_BIT_SIZE-1:0 ] IntIssueLaneIndexPath;
typedef logic unsigned [ $clog2(INT_ISSUE_WIDTH):0 ] IntIssueLaneCountPath;

localparam MULDIV_ISSUE_WIDTH = 1;
localparam MULDIV_STAGE_DEPTH = 3;

`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
localparam COMPLEX_ISSUE_WIDTH = 0;
localparam COMPLEX_ISSUE_WIDTH_BIT_SIZE = 1; // log2(COMPLEX_ISSUE_WIDTH)
typedef logic [ COMPLEX_ISSUE_WIDTH_BIT_SIZE-1:0 ] ComplexIssueLaneIndexPath;
typedef logic unsigned [ $clog2(COMPLEX_ISSUE_WIDTH):0 ] ComplexIssueLaneCountPath;
`else
localparam COMPLEX_ISSUE_WIDTH = 1;
localparam COMPLEX_ISSUE_WIDTH_BIT_SIZE = 1; // log2(COMPLEX_ISSUE_WIDTH)
typedef logic [ COMPLEX_ISSUE_WIDTH_BIT_SIZE-1:0 ] ComplexIssueLaneIndexPath;
typedef logic unsigned [ $clog2(COMPLEX_ISSUE_WIDTH):0 ] ComplexIssueLaneCountPath;
`endif

`ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
    localparam LOAD_ISSUE_WIDTH = 1;
    localparam STORE_ISSUE_WIDTH = 1;
    localparam MEM_ISSUE_WIDTH = 1;
    localparam STORE_ISSUE_LANE_BEGIN = 0;   // Load and store share the same lanes
`else
    localparam LOAD_ISSUE_WIDTH = 1;
    localparam STORE_ISSUE_WIDTH = 1;
    localparam MEM_ISSUE_WIDTH = 2;
    localparam STORE_ISSUE_LANE_BEGIN = LOAD_ISSUE_WIDTH;    // Store uses dedicated lanes
`endif

localparam MEM_ISSUE_WIDTH_BIT_SIZE = 1; // log2(MEM_ISSUE_WIDTH)
typedef logic [ MEM_ISSUE_WIDTH_BIT_SIZE-1:0 ] MemIssueLaneIndexPath;
typedef logic unsigned [ $clog2(MEM_ISSUE_WIDTH):0 ] MemIssueLaneCountPath;

localparam ISSUE_WIDTH = INT_ISSUE_WIDTH + COMPLEX_ISSUE_WIDTH + MEM_ISSUE_WIDTH;
localparam ISSUE_WIDTH_BIT_SIZE = $clog2(ISSUE_WIDTH); // log2(ISSUE_WIDTH)
typedef logic [ ISSUE_WIDTH_BIT_SIZE-1:0 ] IssueLaneIndexPath;
typedef logic unsigned [ ISSUE_WIDTH_BIT_SIZE:0 ] IssueLaneCountPath;

// Commit width
localparam COMMIT_WIDTH = 2;     //must be more than RENAME_WIDTH for recovery
localparam COMMIT_WIDTH_BIT_SIZE = $clog2(COMMIT_WIDTH); // log2(COMMIT_WIDTH)
typedef logic [ COMMIT_WIDTH_BIT_SIZE-1:0 ] CommitLaneIndexPath;
typedef logic unsigned [ COMMIT_WIDTH_BIT_SIZE:0 ] CommitLaneCountPath;


// Pipeline depth
localparam COMPLEX_EXEC_STAGE_DEPTH = 3;

//
// --- Op
//
typedef struct packed // OpSrc
{
    PRegNumPath phySrcRegNumA;
    PRegNumPath phySrcRegNumB;
} OpSrc;

typedef struct packed // OpDst
{
    logic writeReg;
    PRegNumPath phyDstRegNum;
} OpDst;


//
// --- Physical register data
//
localparam PREG_DATA_WIDTH = DATA_WIDTH + 1; // +1 is for a valid flag.
typedef struct packed 
{
    logic valid;
    DataPath data;
} PRegDataPath;

localparam PVEC_DATA_WIDTH = VEC_WIDTH + 1; // +1 is for a valid flag.
typedef struct packed
{
    logic valid;
    VectorPath data;
} PVecDataPath;

//
// --- Shifter
//
localparam SHIFTER_WIDTH = 12;
localparam RISCV_SHIFTER_WIDTH = 30;
typedef logic [ RISCV_SHIFTER_WIDTH-1:0 ] ShifterPath;

localparam SHIFT_AMOUNT_BIT_SIZE = 5;
typedef logic [SHIFT_AMOUNT_BIT_SIZE-1:0] ShiftAmountPath;



endpackage

// ---- Memory/MemoryMapTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Types related to a memory map
//

package MemoryMapTypes;

import BasicTypes::*;

//
// --- Memory map
//



//
// 命令アドレス
//
localparam INSN_RESET_VECTOR = 32'h00001000;

// すべてのベンチマークは、PC_GOALを最終PCとする
localparam PC_GOAL = 32'h80001004;

//
// PC
//

 // PCを圧縮して19ビットにする．面積削減用．
`define RSD_NARROW_PC
 //    PCの圧縮は，現在の論理アドレス空間のメモリ配置をうまく利用して実現している
 //    現在の論理アドレス空間のメモリ配置は以下の通り．
 //      0x0000_1000 - 0x0000_FFFF: Section 0 (ROM)
 //      0x8000_0000 - 0x8003_FFFF: Section 1 (RAM)
 //      0x4000_0000 - 0x4000_000F: Timer IO
 //      0x4000_2000: Serial IO 
 //    このうち，IO 領域には命令アクセスを行うことはないため，
 //    有効な命令の範囲は ROM および RAM 領域のみである．
 //    この範囲内では，論理アドレスは最上位1ビットと下位18ビットしか使われることがない:
 //        ROM 領域: 最上位ビットは 0, 下位16ビットを使用
 //        RAM 領域: 最上位ビットは 1, 下位18ビットを使用
 //    したがって，使わないビットを捨てて，間を詰めることでPCの圧縮が可能
 //      例1) ROM 領域: 0x0000_2000 -> 0x0_2000
 //      例2) RAM 領域: 0x8000_2000 -> 0x4_2000 (最上位 1 ビットと下位 18 ビットを抽出)
 //    ただし，例外を取り扱う際は，32ビットのアドレスで処理する必要があるので注意

`ifdef RSD_NARROW_PC
localparam PC_WIDTH = 19;
`else
localparam PC_WIDTH = ADDR_WIDTH;
`endif

localparam PC_TAG = ADDR_WIDTH - PC_WIDTH;
typedef logic [PC_WIDTH-1:0] PC_Path;

// 圧縮されたPCを32ビットアドレスに変換する
function automatic AddrPath ToAddrFromPC ( PC_Path pc );
`ifdef RSD_NARROW_PC
    return { pc[PC_WIDTH-1], { PC_TAG{1'b0} }, pc[PC_WIDTH-2:0] };
`else
    return pc;
`endif
endfunction

// 32ビットアドレスを圧縮する
function automatic PC_Path ToPC_FromAddr ( AddrPath addr );
`ifdef RSD_NARROW_PC
    return { addr[ADDR_WIDTH-1], addr [PC_WIDTH-2:0] };
`else
    return addr;
`endif
endfunction


//
// Logical address memory type
//
typedef enum logic[1:0]  {
    MMT_MEMORY  = 2'b00,
    MMT_IO      = 2'b01,
    MMT_ILLEGAL = 2'b10
} MemoryMapType;

//
// Physical Address
// 1 bit の mem/IO 識別と，残りの物理アドレスで表限
localparam PHY_ADDR_WIDTH = 21;  // 21 bits: 1bit flag + 1MB memory/IO space
localparam PHY_ADDR_WIDTH_BIT_SIZE = $clog2(PHY_ADDR_WIDTH);
localparam PHY_ADDR_BYTE_WIDTH = PHY_ADDR_WIDTH / BYTE_WIDTH;

localparam PHY_RAW_ADDR_WIDTH = PHY_ADDR_WIDTH - 1;  // 20
localparam PHY_RAW_ADDR_WIDTH_BIT_SIZE = $clog2(PHY_RAW_ADDR_WIDTH);
localparam PHY_RAW_ADDR_BYTE_WIDTH = PHY_RAW_ADDR_WIDTH / BYTE_WIDTH;

typedef logic [PHY_RAW_ADDR_WIDTH-1:0] PhyRawAddrPath;
typedef struct packed {
    logic isIO; // True if address is 
    PhyRawAddrPath addr;
} PhyAddrPath;


//
// 論理と物理メモリ空間のマッピング
// 


//
// Section 0 (ROM?)
// 0x0000_1000 - 0x0000_ffff -> 0x0_1000 -> 0x0_ffff
//
localparam LOG_ADDR_SECTION_0_BEGIN = 32'h0000_1000;
localparam LOG_ADDR_SECTION_0_END   = 32'h0001_0000;
localparam LOG_ADDR_SECTION_0_ADDR_BIT_WIDTH = 16;

// 下位アドレスを切り出してそのまま加算できるように，0x1000 分は無視
localparam PHY_ADDR_SECTION_0_BASE = 20'h0_0000;


//
// Section 1 (RAM?)
// 0x8000_0000 - 0x8003_ffff -> 0x1_0000 -> 0x4_ffff
//
localparam LOG_ADDR_SECTION_1_BEGIN = 32'h8000_0000;
localparam LOG_ADDR_SECTION_1_END   = 32'h8004_0000;
localparam LOG_ADDR_SECTION_1_ADDR_BIT_WIDTH = 18;

localparam PHY_ADDR_SECTION_1_BASE = 20'h1_0000;


//
// --- Serial IO
//
localparam LOG_ADDR_SERIAL_OUTPUT = 32'h4000_2000;
localparam PHY_ADDR_SERIAL_OUTPUT = 20'h0_2000;
localparam LOG_ADDR_SERIAL_INPUT = 32'h4000_2004;
localparam PHY_ADDR_SERIAL_INPUT = 20'h0_2004;
localparam LOG_ADDR_TOHOST = 32'h8000_1000;
localparam PHY_ADDR_TOHOST = 20'h0_3000;


//
// --- Timer IO
//

// Timer IO の 論理アドレス
// 0x4000_0000 - 0x4000_000F
localparam LOG_ADDR_TIMER_BASE    = 32'h4000_0000;
localparam LOG_ADDR_TIMER_LOW     = LOG_ADDR_TIMER_BASE + 0;
localparam LOG_ADDR_TIMER_HI      = LOG_ADDR_TIMER_BASE + 4;
localparam LOG_ADDR_TIMER_CMP_LOW = LOG_ADDR_TIMER_BASE + 8;
localparam LOG_ADDR_TIMER_CMP_HI  = LOG_ADDR_TIMER_BASE + 12;

localparam LOG_ADDR_TIMER_BEGIN = LOG_ADDR_TIMER_BASE;
localparam LOG_ADDR_TIMER_END   = LOG_ADDR_TIMER_BASE + 16;

// タイマーの IO 物理アドレス
// 0x0_0000 - 0x0_000F
localparam PHY_ADDR_TIMER_BASE    = 20'h0_0000;
localparam PHY_ADDR_TIMER_LOW     = PHY_ADDR_TIMER_BASE + 0;
localparam PHY_ADDR_TIMER_HI      = PHY_ADDR_TIMER_BASE + 4;
localparam PHY_ADDR_TIMER_CMP_LOW = PHY_ADDR_TIMER_BASE + 8;
localparam PHY_ADDR_TIMER_CMP_HI  = PHY_ADDR_TIMER_BASE + 12;

localparam PHY_ADDR_TIMER_ZONE_BIT_WIDTH = 4;


// 論理アドレスからメモリタイプを得る
function automatic MemoryMapType GetMemoryMapType(AddrPath addr);
    // TODO: アドレス変換を真面目に実装する
    if (LOG_ADDR_TOHOST <= addr && addr < LOG_ADDR_TOHOST + 8) begin
        return MMT_IO;
    end
    else if (addr == LOG_ADDR_SERIAL_INPUT) begin
        return MMT_IO;
    end
    else if (addr == LOG_ADDR_SERIAL_OUTPUT) begin
        return MMT_IO;
    end
    else if (LOG_ADDR_TIMER_BEGIN <= addr && addr < LOG_ADDR_TIMER_END) begin
        return MMT_IO;
    end
    else if (LOG_ADDR_SECTION_0_BEGIN <= addr && addr < LOG_ADDR_SECTION_0_END) begin
        return MMT_MEMORY;
    end
    else if (LOG_ADDR_SECTION_1_BEGIN <= addr && addr < LOG_ADDR_SECTION_1_END) begin
        return MMT_MEMORY;
    end
    else begin
        return MMT_ILLEGAL;
    end
endfunction

// 論理アドレスから物理アドレスへの変換
function automatic PhyAddrPath ToPhyAddrFromLogical(AddrPath logAddr);
    PhyAddrPath phyAddr;

    if (LOG_ADDR_TOHOST <= logAddr && logAddr < LOG_ADDR_TOHOST + 8) begin
        phyAddr.isIO = TRUE;
        phyAddr.addr = PHY_ADDR_TOHOST + logAddr[2:0];
    end
    else if (logAddr == LOG_ADDR_SERIAL_INPUT) begin
        phyAddr.isIO = TRUE;
        phyAddr.addr = PHY_ADDR_SERIAL_INPUT;
    end
    else if (logAddr == LOG_ADDR_SERIAL_OUTPUT) begin
        phyAddr.isIO = TRUE;
        phyAddr.addr = PHY_ADDR_SERIAL_OUTPUT;
    end
    else if (LOG_ADDR_TIMER_BEGIN <= logAddr && logAddr < LOG_ADDR_TIMER_END) begin
        phyAddr.isIO = TRUE;
        phyAddr.addr = PHY_ADDR_TIMER_BASE + 
            logAddr[PHY_ADDR_TIMER_ZONE_BIT_WIDTH-1:0];
    end
    else if (LOG_ADDR_SECTION_0_BEGIN <= logAddr && logAddr < LOG_ADDR_SECTION_0_END) begin
        // Section 0 (ROM?)
        phyAddr.isIO = FALSE;
        phyAddr.addr = PHY_ADDR_SECTION_0_BASE + 
            logAddr[LOG_ADDR_SECTION_0_ADDR_BIT_WIDTH:0];
    end
    else if (LOG_ADDR_SECTION_1_BEGIN <= logAddr && logAddr < LOG_ADDR_SECTION_1_END) begin
        // Section 1 (RAM?)
        phyAddr.isIO = FALSE;
        phyAddr.addr = PHY_ADDR_SECTION_1_BASE + 
            logAddr[LOG_ADDR_SECTION_1_ADDR_BIT_WIDTH-1:0];
    end
    else begin
        // Invalid
        phyAddr.isIO = FALSE;
        phyAddr.addr = 32'hCCCC_CCCC;
    end

    return phyAddr;
endfunction

function automatic logic IsPhyAddrIO(PhyAddrPath phyAddr);
    return phyAddr.isIO;
endfunction

endpackage
// ---- Cache/CacheSystemTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.



package CacheSystemTypes;

    import BasicTypes::*;
    import MemoryMapTypes::*;

    //
    // --- DCache
    //

    // Main cache parameters.
    // The remaining cache parameters must be fixed or calculated by the following
    // parameters.
    localparam DCACHE_INDEX_BIT_WIDTH = 9;   // The number of index bits 11:16B*1^11=32KB 9:16*1^9=8KB
    localparam DCACHE_LINE_BYTE_NUM = 8;    // Line size
    localparam MSHR_NUM = 2;                 // The nubmer of MSHR entries.

    // Index bits
    localparam DCACHE_INDEX_NUM = 1 << DCACHE_INDEX_BIT_WIDTH;
    typedef logic [DCACHE_INDEX_BIT_WIDTH-1:0] DCacheIndexPath;

    // They number of the ports of tag/data array.
    localparam DCACHE_ARRAY_PORT_NUM = 2;    // Block ram has 2 ports.
    localparam DCACHE_ARRAY_PORT_NUM_BIT_WIDTH = $clog2(DCACHE_ARRAY_PORT_NUM);
    typedef logic [DCACHE_ARRAY_PORT_NUM_BIT_WIDTH-1 : 0] DCacheArrayPortIndex;

    // Line size
    localparam DCACHE_LINE_BYTE_NUM_BIT_WIDTH = $clog2(DCACHE_LINE_BYTE_NUM);
    localparam DCACHE_LINE_BIT_WIDTH = DCACHE_LINE_BYTE_NUM * 8;
    typedef logic [DCACHE_LINE_BIT_WIDTH-1:0] DCacheLinePath;

    typedef logic [DCACHE_LINE_BYTE_NUM-1:0] DCacheByteEnablePath;

    // Tag bits
    localparam DCACHE_TAG_BIT_WIDTH = 
        PHY_ADDR_WIDTH - DCACHE_INDEX_BIT_WIDTH - DCACHE_LINE_BYTE_NUM_BIT_WIDTH;
    typedef logic [DCACHE_TAG_BIT_WIDTH-1:0] DCacheTagPath;

    // Tag+Index bits
    typedef logic [PHY_ADDR_WIDTH-DCACHE_LINE_BYTE_NUM_BIT_WIDTH-1:0] DCacheLineAddr;

    typedef struct packed {
        logic valid;
        DCacheTagPath tag;
    } DCacheTagValidPath;

    // Subset of index for MSHR identifier in ReplayQueue
    // This value MUST be less than or equal to DCACHE_INDEX_BIT_WIDTH.
    localparam DCACHE_INDEX_SUBSET_BIT_WIDTH = 5;
    typedef logic [DCACHE_INDEX_SUBSET_BIT_WIDTH-1:0] DCacheIndexSubsetPath;

    // Memory Access Serial
    // 同時にoutstanding可能なリードトランザクションの最大数を決める
    // D-Cacheからの要求の最大数はMSHR_NUM，I-Cacheからの要求は1，最大要求数はMSHR_NUM+1となる
    // 今後I-Cacheからの同時発行可能な要求数を増やすのであればここを変更
    localparam MEM_ACCESS_SERIAL_BIT_SIZE = $clog2( MSHR_NUM+1 );
    typedef logic [MEM_ACCESS_SERIAL_BIT_SIZE-1 : 0] MemAccessSerial;

    // 同時にoutstanding可能なライトトランザクションの最大数を決める
    // D-Cacheからの要求の最大数はMSHR_NUMなので，最大要求数もMSHR_NUMとなる
    localparam MEM_WRITE_SERIAL_BIT_SIZE = $clog2( MSHR_NUM );
    typedef logic [MEM_WRITE_SERIAL_BIT_SIZE-1 : 0] MemWriteSerial;

    //
    // MSHR
    //
    localparam MSHR_NUM_BIT_WIDTH = $clog2(MSHR_NUM);
    typedef logic [MSHR_NUM_BIT_WIDTH-1:0] MSHR_IndexPath;
    typedef logic [MSHR_NUM_BIT_WIDTH:0] MSHR_CountPath;

    typedef enum logic [3:0]
    {
        MSHR_PHASE_INVALID = 0,                 // This entry is invalid

        // Victim is read from the cache.
        MSHR_PHASE_VICTIM_REQEUST       = 1,    //
        MSHR_PHASE_VICTIM_RECEIVE_TAG   = 2,    //
        MSHR_PHASE_VICTIM_RECEIVE_DATA  = 3,    // Receive dirty data.
        MSHR_PHASE_VICTIM_WRITE_TO_MEM  = 4,    // Victim is written to a main memory.
        MSHR_PHASE_VICTIM_WRITE_COMPLETE = 5,   // Wait until victim writeback is complete.

        MSHR_PHASE_MISS_MERGE_STORE_DATA = 6,   // Merge the allocator store's data and the fetched line.

        MSHR_PHASE_MISS_READ_MEM_REQUEST = 7,   // Read from a main memory to a cache.
        MSHR_PHASE_MISS_READ_MEM_RECEIVE = 8,   // Read from a main memory to a cache.
        MSHR_PHASE_MISS_WRITE_CACHE_REQUEST = 9, // Write data to a cache.
        MSHR_PHASE_MISS_WRITE_CACHE_FINISH = 10

    } MSHR_Phase;

    typedef struct packed   // MissStatusHandlingRegister;
    {
        logic valid;

        MSHR_Phase phase;

        logic victimDirty;
        logic victimValid;
        logic victimReceived;
        PhyAddrPath victimAddr;

        logic newValid;
        PhyAddrPath newAddr;

        MemAccessSerial memSerial; // Read request serial
        MemWriteSerial memWSerial; // Write request serial

        // Line data is shared by "new" and "victim".
        DCacheLinePath line;

        // A MSHR entry can be invalid when
        // its allocator is load and has bypassed data.
        logic canBeInvalid;

        // A MSHR entry which has been allocated by store must integrate the store's data into a fetched cache line.
        logic isAllocatedByStore;
    } MissStatusHandlingRegister;

    typedef struct packed   // DCachePortMultiplexerIn
    {
        DCacheIndexPath indexIn;

        logic           tagWE;
        DCacheTagPath   tagDataIn;
        logic           tagValidIn;

        logic                   dataWE_OnTagHit;
        logic                   dataWE;
        DCacheLinePath          dataDataIn;
        DCacheByteEnablePath    dataByteWE;
        logic                   dataDirtyIn;

        // To notify MSHR that this request is by allocator load.
        logic           makeMSHRCanBeInvalid;

    } DCachePortMultiplexerIn;

    typedef struct packed   // DCachePortMultiplexerTagOut
    {
        DCacheTagPath   tagDataOut;
        logic           tagValidOut;
        logic           tagHit;
        logic           mshrConflict;
        logic           mshrAddrHit;
        MSHR_IndexPath  mshrAddrHitMSHRID;
        logic           mshrReadHit;
        DCacheLinePath  mshrReadData;
    } DCachePortMultiplexerTagOut;

    typedef struct packed   // DCachePortMultiplexerDataOut
    {
        DCacheLinePath  dataDataOut;
        logic           dataDirtyOut;
    } DCachePortMultiplexerDataOut;

    typedef struct packed   // MemoryPortMultiplexerIn
    {
        PhyAddrPath addr;
        DCacheLinePath data;
        logic we;
    } MemoryPortMultiplexerIn;

    typedef struct packed   // MemoryPortMultiplexerOut
    {
        logic ack;              // Request is accpeted or not.
        MemAccessSerial serial; // Request serial
        MemWriteSerial wserial; // Request serial
    } MemoryPortMultiplexerOut;


    // ports
    // Read: for load[LOAD_ISSUE_WIDTH], for store(commit), read victim[MSHR_NUM]
    // Write: WriteNew[MSHR_NUM];
    localparam DCACHE_LSU_READ_PORT_NUM = LOAD_ISSUE_WIDTH;
    localparam DCACHE_LSU_WRITE_PORT_NUM = 1;       // +1 for store commit.
    localparam DCACHE_LSU_PORT_NUM = DCACHE_LSU_READ_PORT_NUM + DCACHE_LSU_WRITE_PORT_NUM;

    localparam DCACHE_LSU_READ_PORT_BEGIN  = 0;
    localparam DCACHE_LSU_WRITE_PORT_BEGIN = DCACHE_LSU_READ_PORT_NUM;

    localparam DCACHE_MUX_PORT_NUM = DCACHE_LSU_PORT_NUM + MSHR_NUM;

    typedef logic [$clog2(DCACHE_MUX_PORT_NUM)-1:0] DCacheMuxPortIndexPath;


    //
    // --- ICache
    //

    // Main cache parameters.
    // The remaining cache parameters must be fixed or calculated by the following
    // parameters.
    localparam ICACHE_WAY_NUM = 2;           // Way Num
    localparam ICACHE_INDEX_BIT_WIDTH = 9 - $clog2(ICACHE_WAY_NUM);   // The number of index bits
    localparam ICACHE_LINE_BYTE_NUM = 8;    // Line size

    // Index bits
    localparam ICACHE_INDEX_NUM = 1 << ICACHE_INDEX_BIT_WIDTH;
    typedef logic [ICACHE_INDEX_BIT_WIDTH-1:0] ICacheIndexPath;

    // Line size
    localparam ICACHE_LINE_BYTE_NUM_BIT_WIDTH = $clog2(ICACHE_LINE_BYTE_NUM);
    localparam ICACHE_LINE_BIT_WIDTH = ICACHE_LINE_BYTE_NUM * 8;
    typedef logic [ICACHE_LINE_BIT_WIDTH-1:0] ICacheLinePath;

    // Line as insn list
    localparam ICACHE_LINE_INSN_NUM = ICACHE_LINE_BYTE_NUM / INSN_BYTE_WIDTH;
    typedef logic [$clog2(ICACHE_LINE_INSN_NUM)-1:0] ICacheLineInsnIndexPath;
    typedef logic [$clog2(ICACHE_LINE_INSN_NUM)  :0] ICacheLineInsnCountPath;
    typedef InsnPath [ICACHE_LINE_INSN_NUM-1:0] ICacheLineInsnPath;

    // Tag bits
    localparam ICACHE_TAG_BIT_WIDTH = 
        PHY_ADDR_WIDTH - ICACHE_INDEX_BIT_WIDTH - ICACHE_LINE_BYTE_NUM_BIT_WIDTH;
    typedef logic [ICACHE_TAG_BIT_WIDTH-1:0] ICacheTagPath;

    // Tag+Index bits
    typedef logic [PHY_ADDR_WIDTH - ICACHE_LINE_BYTE_NUM_BIT_WIDTH - 1:0] ICacheLineAddr;

    typedef struct packed {
        logic valid;
        ICacheTagPath tag;
    } ICacheTagValidPath;

    // Way bits
    typedef logic [$clog2(ICACHE_WAY_NUM)-1:0] ICacheWayPath;

    // NRU Access state bits
    // (N-way NRU -> N bits)
    // These bits correspond to the cache way:
    //   if bit[way] == 1 then the way is referenced recently
    typedef logic [ICACHE_WAY_NUM-1:0] NRUAccessStatePath;

    //
    // --- Memory Access
    //
    typedef struct packed {
        logic ack;              // Request is accpeted or not.
        MemAccessSerial serial; // Read request serial
        MemWriteSerial wserial; // Write request serial
    } MemAccessReqAck;

    typedef struct packed {
        logic valid;
        logic we;
        PhyAddrPath addr;
        DCacheLinePath data;
    } MemAccessReq;

    typedef struct packed {
        logic valid;
        PhyAddrPath addr;
    } MemReadAccessReq;

    typedef struct packed {
        logic valid;
        MemAccessSerial serial;
        DCacheLinePath data;
    } MemAccessResult;

    typedef struct packed {
        logic valid;
        MemWriteSerial serial;
    } MemAccessResponse;

endpackage
// ---- Memory/MemoryTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


package MemoryTypes;

import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryMapTypes::*;

//
// メインメモリのメモリサイズ
//
`ifdef RSD_SYNTHESIS
    `ifdef RSD_USE_EXTERNAL_MEMORY
        localparam MEMORY_ADDR_BIT_SIZE = 32;
    `else
        localparam MEMORY_ADDR_BIT_SIZE = 18; // 256KB
    `endif
`else
        localparam MEMORY_ADDR_BIT_SIZE = 25; // 512KB
`endif

localparam MEMORY_BYTE_SIZE = 1 << MEMORY_ADDR_BIT_SIZE;

// メモリはダミーデータで初期化するが
// そのダミーデータの行数（1行がメモリの1エントリに対応）を指定する。
// メモリの方が大きければ、ダミーデータを繰り返し読み込んで初期化する。
localparam DUMMY_HEX_ENTRY_NUM = 256;


// Size
localparam MEMORY_ENTRY_BIT_NUM /*verilator public*/ = 64; // メモリ1エントリのビット幅
localparam MEMORY_ENTRY_BYTE_NUM = MEMORY_ENTRY_BIT_NUM / BYTE_WIDTH;
localparam MEMORY_ADDR_MSB = MEMORY_ADDR_BIT_SIZE - 1;
localparam MEMORY_ADDR_LSB = $clog2( MEMORY_ENTRY_BYTE_NUM );
localparam MEMORY_INDEX_BIT_WIDTH = MEMORY_ADDR_MSB - MEMORY_ADDR_LSB + 1;
localparam MEMORY_ENTRY_NUM /*verilator public*/ = (1 << MEMORY_INDEX_BIT_WIDTH);
typedef logic [ MEMORY_ENTRY_BIT_NUM-1:0 ] MemoryEntryDataPath;

// Latency

// - メモリ読み出し時に通るパイプラインの長さ。
localparam MEMORY_READ_PIPELINE_DEPTH = 5;

// - メモリ書込アクセスの処理時間
localparam MEMORY_WRITE_PROCESS_LATENCY = 2;

// - メモリ読出アクセスの処理時間
// 読出アクセスを行ってから、次に読出/書込アクセスできるようになるまでの
// サイクル数を示す。データを取得するまでのサイクル数ではないので注意。
localparam MEMORY_READ_PROCESS_LATENCY = 2;

// - メモリ読出/書込アクセスの処理時間をカウント
typedef logic [1:0] MemoryProcessLatencyCount;


//
// RSDがAXI4を用いてメモリアクセスする場合のAXI4バスのパラメータ
//

// RSDのメモリ空間とPS(ARM)のメモリ空間のオフセット
// PS(ARM)のプロセスはここで指定したアドレス以降の空間をRSDとの明示的データ共有以外の目的で使用してはいけない．
localparam MEMORY_AXI4_BASE_ADDR = 32'h10000000; // 256MB

localparam MEMORY_AXI4_DATA_BIT_NUM = 64; // AXI4バスのデータ幅

// AXI4のバースト数
// RSDのメモリアクセス単位はキャッシュライン幅単位なので，それをAXI4バスのデータ幅で割った数
localparam MEMORY_AXI4_BURST_LEN = MEMORY_ENTRY_BIT_NUM/MEMORY_AXI4_DATA_BIT_NUM;
localparam MEMORY_AXI4_BURST_BIT_NUM = $clog2( MEMORY_AXI4_BURST_LEN );

// 同時にoutstanding可能なトランザクションの最大数を決める
// D-Cacheからの要求の最大数はMSHR_NUM，I-Cacheからの要求は1，最大要求数はMSHR_NUM+1となる
localparam MEMORY_AXI4_READ_ID_WIDTH = CacheSystemTypes::MEM_ACCESS_SERIAL_BIT_SIZE;
localparam MEMORY_AXI4_READ_ID_NUM = (1 << MEMORY_AXI4_READ_ID_WIDTH);

// 書き込みの総数は2のべき乗
// 現状，書き込み完了応答があるまで次の書き込みはできないため，InOに1つずつしか書き込みできない
// しかし，RSDからの書き込み要求を受け取ってバッファすることでアドレス要求(aw handshake)を先行して行えるので，
// MSHRと同数にするのが好ましい
localparam MEMORY_AXI4_WRITE_ID_WIDTH = CacheSystemTypes::MEM_WRITE_SERIAL_BIT_SIZE;
localparam MEMORY_AXI4_WRITE_ID_NUM = (1 << MEMORY_AXI4_WRITE_ID_WIDTH);

localparam MEMORY_AXI4_ADDR_BIT_SIZE = MEMORY_ADDR_BIT_SIZE; // AXI4のアドレス幅

// *USERはすべて未使用のため，専用線は削除
localparam MEMORY_AXI4_AWUSER_WIDTH = 0;
localparam MEMORY_AXI4_ARUSER_WIDTH = 0;
localparam MEMORY_AXI4_WUSER_WIDTH = 0;
localparam MEMORY_AXI4_RUSER_WIDTH = 0;
localparam MEMORY_AXI4_BUSER_WIDTH = 0;

typedef struct packed {
    logic [MEMORY_AXI4_READ_ID_WIDTH-1: 0] id; // AXI4用のリクエストID
    logic [MEMORY_AXI4_ADDR_BIT_SIZE-1: 0] addr;
} MemoryReadReq;

// To add variable latency memory access
localparam MEM_REQ_QUEUE_SIZE = 128;
localparam VARIAVBLE_WIDTH = 10;
localparam RANDOM_LATENCY_SEED = 10;
typedef logic [$clog2(VARIAVBLE_WIDTH):0] LatencyCountPath;
typedef struct packed {
    logic isRead;
    logic isWrite;
    AddrPath memAccessAddr;
    MemoryEntryDataPath memAccessWriteData;
    MemAccessSerial nextMemReadSerial; // RSDの次の読み出し要求に割り当てられるシリアル(id)
    MemWriteSerial nextMemWriteSerial; // RSDの次の書き込み要求に割り当てられるシリアル(id)
    logic wr;
} MemoryRequestData;


// PS-PL Memoryサイズ
localparam PS_PL_MEMORY_DATA_BIT_SIZE = 32;
localparam PS_PL_MEMORY_ADDR_BIT_SIZE = 11;
localparam PS_PL_MEMORY_ADDR_LSB = (PS_PL_MEMORY_DATA_BIT_SIZE/32) + 1; // 32-bit: 2, 64-bit: 3
localparam PS_PL_MEMORY_SIZE = 1 << (PS_PL_MEMORY_ADDR_BIT_SIZE-PS_PL_MEMORY_ADDR_LSB); // 512

// PS-PL ControlRegister
localparam PS_PL_CTRL_REG_DATA_BIT_SIZE = 32;
localparam PS_PL_CTRL_REG_ADDR_BIT_SIZE = 7;
localparam PS_PL_CTRL_REG_ADDR_LSB = (PS_PL_CTRL_REG_DATA_BIT_SIZE/32) + 1; // 32-bit: 2, 64-bit: 3
localparam PS_PL_CTRL_REG_SIZE = 1 << (PS_PL_CTRL_REG_ADDR_BIT_SIZE-PS_PL_CTRL_REG_ADDR_LSB); // 32

// PS-PL ControlQueue
localparam PS_PL_CTRL_QUEUE_DATA_BIT_SIZE = PS_PL_CTRL_REG_DATA_BIT_SIZE;
localparam PS_PL_CTRL_QUEUE_ADDR_BIT_SIZE = 6;
localparam PS_PL_CTRL_QUEUE_SIZE = 1 << PS_PL_CTRL_QUEUE_ADDR_BIT_SIZE; // 64


endpackage
// ---- Decoder/OpFormat.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


package OpFormatTypes;

import BasicTypes::*;

// JAL, JALR uses PC+4 as operands
localparam PC_OPERAND_OFFSET = 4;

//
// --- 条件コードの定義
//
typedef enum logic [2:0]    // enum CondCode
{
    COND_EQ  = 3'b000, // EQ  '='
    COND_NE  = 3'b001, // NE  '!='
    COND_LT  = 3'b100, // LT  符号付き'<'
    COND_GE  = 3'b101, // GE  符号付き'>'
    COND_LTU = 3'b110, // LTU 符号なし'<'
    COND_GEU = 3'b111, // GEU 符号なし'>'
    COND_AL  = 3'b010  // AL 常時（無条件）
} CondCode;

//
// 命令タイプ
//
typedef enum logic [2:0]    // enum OpCode
{
    OC_INT_REG = 3'b000,    // 整数演算（レジスタ）
    OC_INT_IMM = 3'b001,    // 整数演算（即値）
    OC_MEM_IMM = 3'b010,    // ロード/ストア（即値オフセット・アドレッシング）
    OC_MEM_REG = 3'b011,    // ロード/ストア（レジスタオフセット・アドレッシング）
    OC_MEM_MUL = 3'b100,    // 複数ロード/ストア
    OC_BR      = 3'b101        // 分岐
} OpCode;


//
// Op命令とOpImm命令のfunct3
//
typedef enum logic [2:0]    // enum OpFunct3
{
    OP_FUNCT3_ADD_SUB   = 3'b000,
    OP_FUNCT3_SLT       = 3'b010,
    OP_FUNCT3_SLTU      = 3'b011,
    OP_FUNCT3_EOR       = 3'b100,
    OP_FUNCT3_OR        = 3'b110,
    OP_FUNCT3_AND       = 3'b111,
    OP_FUNCT3_SLL       = 3'b001,
    OP_FUNCT3_SRL_SRA   = 3'b101
} OpFunct3;

//
// Op命令のfunct7
//
typedef enum logic [6:0]    // enum OpFunct7
{
    OP_FUNCT7_ADD = 7'b0000000,
    OP_FUNCT7_SUB = 7'b0100000
} OpFunct7;

//
// シフト命令のfunct7
//
typedef enum logic [6:0]    // enum ShiftFunct7
{
    SHIFT_FUNCT7_SRL = 7'b0000000,
    SHIFT_FUNCT7_SRA = 7'b0100000
} ShiftFunct7;

//
// RV32Mのfunct7
//
typedef enum logic [6:0]    // enum RV32MFunct7
{
    RV32M_FUNCT7_ALL = 7'b0000001
} RV32MFunct7;

//
// 分岐命令のfunct3
//
typedef enum logic [2:0]    // enum BrFunct3
{
    BRANCH_FUNCT3_BEQ     = 3'b000,
    BRANCH_FUNCT3_BNE     = 3'b001,
    BRANCH_FUNCT3_BLT     = 3'b100,
    BRANCH_FUNCT3_BGE     = 3'b101,
    BRANCH_FUNCT3_BLTU    = 3'b110,
    BRANCH_FUNCT3_BGEU    = 3'b111
} BrFunct3;

//
// Mem命令のfunct3
//
typedef enum logic [2:0]    // enum MemFunct3
{
    MEM_FUNCT3_SIGNED_BYTE          = 3'b000,
    MEM_FUNCT3_SIGNED_HALF_WORD     = 3'b001,
    MEM_FUNCT3_WORD                 = 3'b010,
    MEM_FUNCT3_UNSIGNED_BYTE        = 3'b100,
    MEM_FUNCT3_UNSIGNED_HALF_WORD   = 3'b101
} MemFunct3;

//
// RV32M(乗算・除算・剰余)命令のfunct3
//
typedef enum logic [2:0]    // enum RV32MFunct3
{
    RV32M_FUNCT3_MUL     = 3'b000,
    RV32M_FUNCT3_MULH    = 3'b001,
    RV32M_FUNCT3_MULHSU  = 3'b010,
    RV32M_FUNCT3_MULHU   = 3'b011,
    RV32M_FUNCT3_DIV     = 3'b100,
    RV32M_FUNCT3_DIVU    = 3'b101,
    RV32M_FUNCT3_REM     = 3'b110,
    RV32M_FUNCT3_REMU    = 3'b111
} RV32MFunct3;

//
// Misc-Mem命令のfunct3
//
typedef enum logic [2:0]    // enum MiscMemFunct3
{
    MISC_MEM_FUNCT3_FENCE   = 3'b000, // FENCE
    MISC_MEM_FUNCT3_FENCE_I = 3'b001  // FENCE.I
} MiscMemFunct3;

//
// System 命令の funct3, funct12
//
typedef enum logic [2:0]    // enum SystemFunct3
{
    SYSTEM_FUNCT3_PRIV  = 3'b000,     // Privileged (ecall/ebreak/mret

    SYSTEM_FUNCT3_CSR_RW    = 3'b001, // CSRRW
    SYSTEM_FUNCT3_CSR_RS    = 3'b010, // CSRRS
    SYSTEM_FUNCT3_CSR_RC    = 3'b011, // CSRRC

    SYSTEM_FUNCT3_UNDEFINED = 3'b100,  // ???

    SYSTEM_FUNCT3_CSR_RW_I  = 3'b101, // CSRRWI
    SYSTEM_FUNCT3_CSR_RS_I  = 3'b110, // CSRRSI
    SYSTEM_FUNCT3_CSR_RC_I  = 3'b111  // CSRRCI

} SystemFunct3;

typedef enum logic [11:0]    // enum SystemFunct12
{
    SYSTEM_FUNCT12_ECALL  = 12'b0000_0000_0000, // ECALL
    SYSTEM_FUNCT12_EBREAK = 12'b0000_0000_0001, // EBREAK
    SYSTEM_FUNCT12_MRET   = 12'b0011_0000_0010, // MRET
    SYSTEM_FUNCT12_WFI    = 12'b0001_0000_0101  // WFI
} SystemFunct12;


//
// --- shifter_operand の定義
//


// Shift operand type
typedef enum logic    // enum ShiftOperandType
{
    SOT_IMM_SHIFT = 1'b0,   // Immediate shift
    SOT_REG_SHIFT = 1'b1    // Register shift
} ShiftOperandType;

typedef enum logic [1:0]    // enum ShiftType
{
    ST_LSL = 2'b00, // Logical shift left
    ST_LSR = 2'b01, // Logical shift right
    ST_ASR = 2'b10, // Arithmetic shift right
    ST_ROR = 2'b11  // Rotate
} ShiftType;

typedef enum logic [1:0]    // Imm
{
    RISCV_IMM_R    = 2'b00,
    RISCV_IMM_I    = 2'b01,
    RISCV_IMM_S    = 2'b10,
    RISCV_IMM_U    = 2'b11
} RISCV_ImmType;


//即値 : 5+2+1+20+2 = 30 bit → SHIFTER_WIDTH
typedef struct packed    // struct RISCV_IntOperandImmShift
{
    logic [4:0] shift;
    ShiftType   shiftType;
    logic       isRegShift;
    logic [19:0] imm;
    RISCV_ImmType immType;
} RISCV_IntOperandImmShift;


//
// --- アドレッシング
//

// 即値
localparam ADDR_OPERAND_IMM_WIDTH = 12;
localparam ADDR_SIGN_EXTENTION_WIDTH = ADDR_WIDTH - ADDR_OPERAND_IMM_WIDTH;

typedef struct packed    // struct AddrOperandImm
{
    logic [11:0] imm;    // [11:0] offset
} AddrOperandImm;


// Memory Access Mode (signed / access size)
typedef enum logic [1:0]
{
    MEM_ACCESS_SIZE_BYTE = 2'b00,
    MEM_ACCESS_SIZE_HALF_WORD = 2'b01,
    MEM_ACCESS_SIZE_WORD = 2'b10,
    MEM_ACCESS_SIZE_VEC  = 2'b11
} MemAccessSizeType;

function automatic logic IsMisalignedAddress(input AddrPath addr, input MemAccessSizeType size);
    if (size == MEM_ACCESS_SIZE_BYTE || size == MEM_ACCESS_SIZE_VEC) begin
        return FALSE;
    end
    else if (size == MEM_ACCESS_SIZE_HALF_WORD) begin
        return addr[0:0] != 0 ? TRUE : FALSE;
    end
    else if (size == MEM_ACCESS_SIZE_WORD) begin
        return addr[1:0] != 0 ? TRUE : FALSE;
    end
    else 
        return FALSE;
endfunction

typedef struct packed
{
    logic isSigned;
    MemAccessSizeType size;
} MemAccessMode;

// ディスプレースメント幅: 各分岐命令のディスプレースメントはそれぞれ
// Branch: 12ビット，JAL: 20ビット， JALR: 12ビット
// のビット幅でエンコードされる．
localparam BR_DISP_WIDTH = 20;
typedef logic [BR_DISP_WIDTH-1:0] BranchDisplacement;
// 符号拡張用
localparam BR_DISP_SIGN_EXTENTION_WIDTH = ADDR_WIDTH - BR_DISP_WIDTH;


// ALU code
typedef enum logic [3:0]    // enum ALU_Code
{
    AC_ADD  = 4'b0000,    // ADD    加算
    AC_SLT  = 4'b0010,    // SLT    比較 Rd = if Rs1 < Rs2 then 1 else 0
    AC_SLTU = 4'b0011,    // SLTU   符号なし比較
    AC_EOR  = 4'b0100,    // EOR    排他的論理和
    AC_ORR  = 4'b0110,    // ORR    （包含的）論理和
    AC_AND  = 4'b0111,    // AND    論理積
    AC_SUB  = 4'b0001    // SUB    減算
} IntALU_Code;


// IntMUL code
typedef enum logic [1:0]    // enum IntMUL_Code
{
    AC_MUL    = 2'b00,    // MUL    
    AC_MULH   = 2'b01,    // MULH
    AC_MULHSU = 2'b10,    // MULHSU 
    AC_MULHU  = 2'b11     // MULHU  
} IntMUL_Code;


// IntDIV code
typedef enum logic [1:0]    // enum IntDIV_Code
{
    AC_DIV    = 2'b00,    // DIV    
    AC_DIVU   = 2'b01,    // DIVU
    AC_REM    = 2'b10,    // REM 
    AC_REMU   = 2'b11     // REMU  
} IntDIV_Code;

// CSR operation code
typedef enum logic [1:0]    // enum CSR_Code
{
    CSR_UNKNOWN = 2'b00,    // ???
    CSR_WRITE   = 2'b01,    // WRITE
    CSR_SET     = 2'b10,    // SET
    CSR_CLEAR   = 2'b11     // CLEAR
} CSR_Code;

localparam CSR_NUMBER_WIDTH = 12;
typedef logic [CSR_NUMBER_WIDTH-1:0] CSR_NumberPath;

localparam CSR_IMM_WIDTH = 5;
typedef logic [CSR_IMM_WIDTH-1:0] CSR_ImmPath;

typedef struct packed // 5+1+2=8
{
    CSR_ImmPath imm;
    logic isImm;
    CSR_Code code;
} CSR_CtrlPath;

// Environment operation code
typedef enum logic [2:0]      // enum ENV_Code
{
    ENV_CALL            = 3'b000,    // ECALL
    ENV_BREAK           = 3'b001,    // EBREAK
    ENV_MRET            = 3'b010,    // MRET
    ENV_INSN_ILLEGAL    = 3'b011,    // Executes illegal insturction
    ENV_INSN_VIOLATION  = 3'b100,    // Insturction access violation

    ENV_UNKNOWN         = 3'b101     //
} ENV_Code;




//RISCV Instruction Format

//
// RISCV 命令タイプ
//
typedef enum logic [6:0]    // enum OpCode
{
    RISCV_OP_IMM    = 7'b0010011,
    RISCV_OP        = 7'b0110011,
    RISCV_LUI       = 7'b0110111,
    RISCV_AUIPC     = 7'b0010111,
    RISCV_JAL       = 7'b1101111,
    RISCV_JALR      = 7'b1100111,
    RISCV_BR        = 7'b1100011,
    RISCV_LD        = 7'b0000011,
    RISCV_ST        = 7'b0100011,
    RISCV_MISC_MEM  = 7'b0001111,
    RISCV_SYSTEM    = 7'b1110011
} RISCV_OpCode;


// R-Type
typedef struct packed
{
    logic [6:0]     funct7;     // [31:25] funct7
    logic [4:0]     rs2;        // [24:20] Rs2
    logic [4:0]     rs1;        // [19:15] Rs1
    logic [2:0]     funct3;     // [14:12] funct3
    logic [4:0]     rd;         // [11: 7] Rd
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ
} RISCV_ISF_Common;

// R-Type
typedef struct packed
{
    logic [6:0]     funct7;     // [31:25] funct7
    logic [4:0]     rs2;        // [24:20] Rs2
    logic [4:0]     rs1;        // [19:15] Rs1
    logic [2:0]     funct3;     // [14:12] funct3
    logic [4:0]     rd;         // [11: 7] Rd
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ
} RISCV_ISF_R;

// I-Type
typedef struct packed
{
    logic [11:0]    imm;        // [31:20] Imm
    logic [4:0]     rs1;        // [19:15] Rs1
    logic [2:0]     funct3;     // [14:12] funct3
    logic [4:0]     rd;         // [11: 7] Rd
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ
} RISCV_ISF_I;

// S-Type
typedef struct packed
{
    logic [6:0]     imm2;       // [31:25] imm[11:5]
    logic [4:0]     rs2;        // [24:20] Rs2
    logic [4:0]     rs1;        // [19:15] Rs1
    logic [2:0]     funct3;     // [14:12] funct3
    logic [4:0]     imm1;       // [11: 7] imm[4:0]
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ
} RISCV_ISF_S;

// U-Type
typedef struct packed
{
    logic [19:0]    imm;        // [31:12] imm
    logic [4:0]     rd;         // [11: 7] Rd
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ
} RISCV_ISF_U;

// B-Type 
typedef struct packed 
{ 
    logic           imm12;      // [31:31] imm[12] 
    logic [5:0]     imm10_5;    // [30:25] imm[10:5] 
    logic [4:0]     rs2;        // [24:20] Rs2 
    logic [4:0]     rs1;        // [19:15] Rs1 
    logic [2:0]     funct3;     // [14:12] funct3 
    logic [3:0]     imm4_1;     // [11:8]  imm[4:1] 
    logic           imm11;      // [7:7]   imm[11] 
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ 
} RISCV_ISF_B;

// J-Type 
typedef struct packed 
{ 
    logic           imm20;      // [31:31] imm[20] 
    logic [9:0]     imm10_1;    // [30:21] imm[10:1] 
    logic           imm11;      // [20:20] imm[11] 
    logic [7:0]     imm19_12;   // [19:12] imm[19:12] 
    logic [4:0]     rd;         // [11: 7] Rd 
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ 
} RISCV_ISF_J;

// MISC-MEM 
typedef struct packed 
{ 
    logic [3:0] reserved;       // [31:28] reserved
    logic pi;                   // [27:27] pi
    logic po;                   // [26:26] po
    logic pr;                   // [25:25] pr
    logic pw;                   // [24:24] pw
    logic si;                   // [23:23] si
    logic so;                   // [22:22] so
    logic sr;                   // [21:21] sr
    logic sw;                   // [20:20] sw
    logic [4:0]     rs1;        // [19:15] Rs1
    logic [2:0]     funct3;     // [14:12] funct3
    logic [4:0]     rd;         // [11: 7] Rd 
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ 
} RISCV_ISF_MISC_MEM;

// SYSTEM
typedef struct packed 
{ 
    logic [11:0]    funct12;    // [31:20] csr
    logic [4:0]     rs1;        // [19:15] Rs1
    logic [2:0]     funct3;     // [14:12] funct3
    logic [4:0]     rd;         // [11: 7] Rd 
    RISCV_OpCode    opCode;     // [ 6: 0] 命令タイプ 
} RISCV_ISF_SYSTEM;


//
// ---RISCV→ALUCODE の変換
//
function automatic void RISCV_DecodeOpImmFunct3(
    output IntALU_Code aluCode,
    input OpFunct3 funct3
);
    case(funct3)
        OP_FUNCT3_ADD_SUB : begin  //ADDI
            aluCode = AC_ADD;
        end
        OP_FUNCT3_SLT : begin  //SLTI
            aluCode = AC_SLT;
        end
        OP_FUNCT3_SLTU : begin  //SLTUI
            aluCode = AC_SLTU;
        end
        OP_FUNCT3_EOR : begin  //EORI
            aluCode = AC_EOR;
        end
        OP_FUNCT3_OR : begin  //ORI
            aluCode = AC_ORR;
        end
        OP_FUNCT3_AND : begin  //ANDI
            aluCode = AC_AND;
        end
        OP_FUNCT3_SLL : begin //SLLI
            aluCode = AC_AND;
        end
        OP_FUNCT3_SRL_SRA : begin //SRLI, SRAI
            aluCode = AC_AND;
        end
        default : begin
            aluCode = AC_AND; 
        end
    endcase // funct3
endfunction

function automatic void RISCV_DecodeOpFunct3(
    output IntALU_Code aluCode,
    input OpFunct3 funct3,
    input OpFunct7 funct7
);
    case(funct3)
        OP_FUNCT3_ADD_SUB : begin  //ADD or SUB
            if(funct7==OP_FUNCT7_ADD) begin
                aluCode = AC_ADD;
            end else begin
                aluCode = AC_SUB;
            end
        end
        OP_FUNCT3_SLT : begin  //SLT
            aluCode = AC_SLT;
        end
        OP_FUNCT3_SLTU : begin  //SLTU
            aluCode = AC_SLTU;
        end
        OP_FUNCT3_EOR : begin  //EOR
            aluCode = AC_EOR;
        end
        OP_FUNCT3_OR : begin  //OR
            aluCode = AC_ORR;
        end
        OP_FUNCT3_AND : begin  //AND
            aluCode = AC_AND;
        end
        OP_FUNCT3_SLL : begin //SLL
            aluCode = AC_AND;
        end
        OP_FUNCT3_SRL_SRA : begin //SRL, SRA
            aluCode = AC_AND;
        end
        default : begin
            aluCode = AC_AND;
        end
    endcase // funct3
endfunction


//
// ---RISCV→ConditionCode の変換
//      ConditionCodeはARMのものを変更して使う
function automatic void RISCV_DecodeBrFunct3(
    output CondCode condCode,
    input BrFunct3 funct3
);
    case(funct3)
        BRANCH_FUNCT3_BEQ : begin  //BEQ
            condCode = COND_EQ;
        end
        BRANCH_FUNCT3_BNE : begin  //BNE
            condCode = COND_NE;
        end
        BRANCH_FUNCT3_BLT : begin  //BLT
            condCode = COND_LT;
        end
        BRANCH_FUNCT3_BGE : begin  //BGE
            condCode = COND_GE;
        end
        BRANCH_FUNCT3_BLTU : begin  //BLTU
            condCode = COND_LTU;
        end
        BRANCH_FUNCT3_BGEU : begin  //BGEU
            condCode = COND_GEU;
        end
        default : begin
            condCode = COND_AL;
        end
    endcase // funct3
endfunction

//
// ---LD/ST のサイズの変換
//
function automatic void RISCV_DecodeMemAccessMode(
    output MemAccessMode memAccessMode,
    input MemFunct3 funct3
);
    case(funct3)
        MEM_FUNCT3_SIGNED_BYTE : begin  //LB, SB
            memAccessMode.isSigned = TRUE;
            memAccessMode.size = MEM_ACCESS_SIZE_BYTE;
        end
        MEM_FUNCT3_SIGNED_HALF_WORD : begin  //LH, SH
            memAccessMode.isSigned = TRUE;
            memAccessMode.size = MEM_ACCESS_SIZE_HALF_WORD;
        end
        MEM_FUNCT3_WORD : begin  //LW, SW
            memAccessMode.isSigned = TRUE;
            memAccessMode.size = MEM_ACCESS_SIZE_WORD;
        end
        MEM_FUNCT3_UNSIGNED_BYTE : begin  //LBU
            memAccessMode.isSigned = FALSE;
            memAccessMode.size = MEM_ACCESS_SIZE_BYTE;
        end
        MEM_FUNCT3_UNSIGNED_HALF_WORD : begin  //LHU
            memAccessMode.isSigned = FALSE;
            memAccessMode.size = MEM_ACCESS_SIZE_HALF_WORD;
        end
        default : begin  //WORD
            memAccessMode.isSigned = TRUE;
            memAccessMode.size = MEM_ACCESS_SIZE_BYTE;
        end
    endcase
endfunction

function automatic void RISCV_DecodeComplexOpFunct3(
    output IntMUL_Code mulCode,
    output IntDIV_Code divCode,
    input RV32MFunct3 funct3
);
    case(funct3)
        RV32M_FUNCT3_MUL : begin  //ADD or SUB
            mulCode = AC_MUL;
            divCode = AC_DIV;
        end
        RV32M_FUNCT3_MULH : begin  //SLT
            mulCode = AC_MULH;
            divCode = AC_DIV;
        end
        RV32M_FUNCT3_MULHSU : begin  //SLTU
            mulCode = AC_MULHSU;
            divCode = AC_DIV;
        end
        RV32M_FUNCT3_MULHU : begin  //EOR
            mulCode = AC_MULHU;
            divCode = AC_DIV;
        end
        RV32M_FUNCT3_DIV : begin  //OR
            mulCode = AC_MUL;
            divCode = AC_DIV;
        end
        RV32M_FUNCT3_DIVU : begin  //AND
            mulCode = AC_MUL;
            divCode = AC_DIVU;
        end
        RV32M_FUNCT3_REM : begin //SLL
            mulCode = AC_MUL;
            divCode = AC_REM;
        end
        RV32M_FUNCT3_REMU : begin //SRL, SRA
            mulCode = AC_MUL;
            divCode = AC_REMU;
        end
        default : begin
            mulCode = AC_MUL;
            divCode = AC_DIV;
        end
    endcase // funct3
endfunction

//
// brDispのデコード
//
function automatic BranchDisplacement GetBranchDisplacement(
    input RISCV_ISF_B isfBr
);
    return
    {
        {9{isfBr.imm12}},   // 9 bits sign extention
        isfBr.imm11,    // 1 bits
        isfBr.imm10_5,  // 6 bits
        isfBr.imm4_1    // 4 bits
    };
endfunction

function automatic BranchDisplacement GetJAL_Target(
    input RISCV_ISF_J isfJAL
);
    return
    {
        isfJAL.imm20,    //  1 bits
        isfJAL.imm19_12, //  8 bits
        isfJAL.imm11,    //  1 bits
        isfJAL.imm10_1   // 10 bits
    };
endfunction

function automatic BranchDisplacement GetJALR_Target(
    input RISCV_ISF_I isfJALR
);
    return
    {
        {8{isfJALR.imm[11]}},   // 8 bits sign extention
        isfJALR.imm             // 12 bits
    };
endfunction

//
// signed extention
//
function automatic logic [19:0] ShamtExtention(
    input RISCV_ISF_R isfR
);
    return { 15'h0, isfR.rs2 };
endfunction

function automatic logic [19:0] I_TypeImmExtention(
    input RISCV_ISF_I isfI
);
    return { {8{isfI.imm[11]}}, isfI.imm };
endfunction

function automatic AddrPath ExtendBranchDisplacement(
    input BranchDisplacement brDisp
);
    return
    {
        { (ADDR_WIDTH-BR_DISP_WIDTH-1){brDisp[BR_DISP_WIDTH-1]} },
        brDisp,
        1'b0
    };
endfunction

function automatic AddrPath ExtendJALR_Target(
    input BranchDisplacement brDisp
);
    return
    {
        { (ADDR_WIDTH-BR_DISP_WIDTH){brDisp[BR_DISP_WIDTH-1]} },
        brDisp
    };
endfunction


function automatic AddrPath AddJALR_TargetOffset(    
    input AddrPath data, input BranchDisplacement disp
);
    AddrPath target;
    target = data + ExtendJALR_Target(disp);
    target[0] = 1'b0;   // Mask the LSB
    return target;
endfunction


endpackage

// ---- Decoder/MicroOp.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Definitions related to micro ops.
//


package MicroOpTypes;

import BasicTypes::*;
import OpFormatTypes::*;


localparam LINK_REGISTER = 5'h 1;
localparam MICRO_OP_TMP_REGISTER = 4'h f;
localparam ZERO_REGISTER = 5'h 0;

localparam MICRO_OP_MAX_NUM = 3;     // An instruction is decoded to up to 3 micro ops.
localparam MICRO_OP_INDEX_BITS = 2;  
typedef logic [MICRO_OP_INDEX_BITS-1:0] MicroOpIndex;   // マイクロOp のインデックス
typedef logic [MICRO_OP_INDEX_BITS  :0] MicroOpCount;


localparam ALL_DECODED_MICRO_OP_WIDTH = MICRO_OP_MAX_NUM * DECODE_WIDTH;
localparam ALL_DECODED_MICRO_OP_WIDTH_BIT_SIZE = MICRO_OP_INDEX_BITS + DECODE_WIDTH_BIT_SIZE;

typedef logic [ALL_DECODED_MICRO_OP_WIDTH-1:0] AllDecodedMicroOpPath;
typedef logic [ALL_DECODED_MICRO_OP_WIDTH-DECODE_WIDTH-1:0] RemainingDecodedMicroOpPath;
typedef logic [ALL_DECODED_MICRO_OP_WIDTH_BIT_SIZE-1:0] AllDecodedMicroOpIndex;


localparam MICRO_OP_SOURCE_REG_NUM = 2;

typedef enum logic [1:0]
{
    MOP_TYPE_INT     = 2'b00,
    MOP_TYPE_COMPLEX = 2'b01,
    MOP_TYPE_MEM     = 2'b10
} MicroOpType;

// 各サブタイプは，パイプライン中で処理を見分けるために使用される
typedef enum logic [2:0]
{
    INT_MOP_TYPE_ALU       = 3'b000,
    INT_MOP_TYPE_SHIFT     = 3'b001,

    INT_MOP_TYPE_BR        = 3'b010,
    INT_MOP_TYPE_RIJ       = 3'b011
} IntMicroOpSubType;

typedef enum logic [2:0]
{
    COMPLEX_MOP_TYPE_MUL       = 3'b000,
    COMPLEX_MOP_TYPE_DIV       = 3'b001   // DIV演算器を使うもの(DIVとREM)
`ifdef RSD_ENABLE_VECTOR_PATH
    COMPLEX_MOP_TYPE_VEC_ADD   = 3'b011,
    COMPLEX_MOP_TYPE_VEC_MUL   = 3'b100
`endif
} ComplexMicroOpSubType;

typedef enum logic [2:0]
{
    MEM_MOP_TYPE_LOAD      = 3'b000,
    MEM_MOP_TYPE_STORE     = 3'b001,

    // Mem パイプで乗除算をやる場合のコード
    MEM_MOP_TYPE_MUL       = 3'b010,
    MEM_MOP_TYPE_DIV       = 3'b011,

    MEM_MOP_TYPE_CSR       = 3'b100, // CSR access
    MEM_MOP_TYPE_FENCE     = 3'b101, // fence
    MEM_MOP_TYPE_ENV       = 3'b110  // env

} MemMicroOpSubType;

typedef union packed    // OpSubType
{
    IntMicroOpSubType     intType;
    ComplexMicroOpSubType complexType;
    MemMicroOpSubType     memType;
} MicroOpSubType;

typedef struct packed // OpId
{
    OpSerial sid;
    MicroOpIndex mid;
} OpId;

// The type of operand.
typedef enum logic [1:0]    // enum OperandType
{
    OOT_REG = 2'b00,   // Register
    OOT_IMM = 2'b01,   // Immediate
    OOT_PC  = 2'b10    // PC
} OpOperandType;


//
// The eperands of micro-ops
// The order of fields is important. The order must be fixed for simplifying a decoder.
//

// Int: 6+6+6+ 4+ 1+ 30=53 bits
typedef struct packed // IntMicroOpOperand
{
    // 論理レジスタ番号
    LRegNumPath dstRegNum;
    LRegNumPath srcRegNumA;    // レジスタN 相当
    LRegNumPath srcRegNumB;    // 第2オペランド

    // ALU
    IntALU_Code aluCode;

    // Shift
    ShiftOperandType shiftType;

    // Shifter operand and imm
    ShifterPath shiftIn;
} IntMicroOpOperand;

// Mem: 6+6+6 +1+1+3 +8 +15 +12 = 18+5+8+10+12 = 53 bits
typedef struct packed // MemMicroOpOperand
{
    // 論理レジスタ番号
    LRegNumPath dstRegNum;
    LRegNumPath srcRegNumA;    // レジスタN 相当
    LRegNumPath srcRegNumB;    // 第2オペランド

    logic isAddAddr;    // オフセット加算
    logic isRegAddr;    // レジスタアドレッシング
    MemAccessMode memAccessMode; // signed/unsigned and access size

    CSR_CtrlPath csrCtrl;
    logic [9:0] padding; //　padding

    // Address offset or CSR number
    AddrOperandImm addrIn;
} MemMicroOpOperand;

// Branch:6+6+6 +15 +20=53 bits
typedef struct packed // BrMicroOpOperand
{
    // 論理レジスタ番号
    LRegNumPath dstRegNum;
    LRegNumPath srcRegNumA;    // レジスタN 相当
    LRegNumPath srcRegNumB;    // 第2オペランド
    logic [14:0] padding;       // padding
    BranchDisplacement brDisp;  // Branch offset.
} BrMicroOpOperand;

// Complex Integer: 6+6+6 +1 +16 +18 = 35+18= 53 bits
typedef struct packed // ComplexMicroOpOperand
{
    // 論理レジスタ番号
    LRegNumPath dstRegNum;
    LRegNumPath srcRegNumA;    // レジスタN 相当
    LRegNumPath srcRegNumB;    // 第2オペランド

    logic mulGetUpper;  // 乗算結果の33-64bit目を使用
    IntMUL_Code mulCode;
    IntDIV_Code divCode;

    logic [15:0] padding;        // Padding field.
    logic [13:0] riscv_padding; // RISCV用のpadding
} ComplexMicroOpOperand;

// MiscMem: 6+6+6 +1 +16 +18 = 35+18= 53 bits
typedef struct packed // MiscMemMicroOpOperand
{
    // 論理レジスタ番号
    LRegNumPath dstRegNum;
    LRegNumPath srcRegNumA;    // レジスタN 相当
    LRegNumPath srcRegNumB;    // 第2オペランド

    logic fence;

    logic [15:0] padding;        // Padding field.
    logic [17:0] riscv_padding; // RISCV用のpadding
} MiscMemMicroOpOperand;

// MiscMem: 6+6+6 +3+1 +19 +12 = 18+4+19+12= 53 bits
typedef struct packed // SystemMicroOpOperand
{
    // 論理レジスタ番号
    LRegNumPath dstRegNum;
    LRegNumPath srcRegNumA;    // レジスタN 相当
    LRegNumPath srcRegNumB;    // 第2オペランド

    ENV_Code envCode;
    logic isEnv;

    logic [18:0] padding;        // Padding field.

    logic [11:0] imm;
} SystemMicroOpOperand;

typedef union packed    // MicroOpOperand
{
    IntMicroOpOperand     intOp;
    MemMicroOpOperand     memOp;
    BrMicroOpOperand      brOp;
    ComplexMicroOpOperand complexOp;
    MiscMemMicroOpOperand miscMemOp;
    SystemMicroOpOperand  systemOp;
} MicroOpOperand;


typedef struct packed // OpInfo
{
    // 条件コード
    CondCode cond;

    // 命令の種類
    MicroOpType mopType;
    MicroOpSubType mopSubType;
    
    // The operands of this micro op.
    MicroOpOperand operand;

    OpOperandType opTypeA;
    OpOperandType opTypeB;

    logic writeReg;     // レジスタ書き込みを行うかどうか
    
    // 無効な命令
    logic undefined;    // Undefined op.
    logic unsupported;  // Defined, but unsuported.
    
    // マイクロOp に分割されているかどうか
    logic split;
    
    // Whether this micro op is valid or not.
    logic valid;

    // Whether this micro op is the last micro op in an original instruction.
    logic last;
    
    // マイクロOp のインデックス
    MicroOpIndex mid;

    // This instruction needs serialization.
    // That is, 
    // * this instruction is not fed to the succeeding stages until all the 
    // preceding instructions are retired. 
    // * The succeeding instructions are never fetched until this instruction 
    // is retired. 
    // * Already fetched succeeding instructions are flushed when this 
    // instruction is decoded.
    logic serialized;    
} OpInfo;

typedef struct packed { // InsnInfo
    logic writePC;  // This instruction writes the PC.

    // call/return
    logic isCall;
    logic isReturn;
    
    // PC relative (JAL, branch)
    logic isRelBranch;

    // See comments of "serialized" in OpInfo
    logic isSerialized;    
} InsnInfo;


endpackage

// ---- RegisterFile/BypassTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Types related to bypass network.
//

package BypassTypes;

import BasicTypes::*;

typedef enum logic unsigned [1:0]   // enum BypassSelect
{
    BYPASS_STAGE_INT_EX = 0,
    BYPASS_STAGE_INT_WB = 1,
    BYPASS_STAGE_MEM_MA = 2,
    BYPASS_STAGE_MEM_WB = 3
} BypassSelectStage;


typedef struct packed {
    // TODO: unionで実装
    IntIssueLaneIndexPath intLane;
    ComplexIssueLaneIndexPath complexLane;
    MemIssueLaneIndexPath memLane;
} BypassLane;

typedef struct packed {
    logic valid; // バイパスするか否か
    BypassSelectStage stg;
    BypassLane lane;
} BypassSelect;

typedef struct packed {
    BypassSelect rA;
    BypassSelect rB;
} BypassControll;

endpackage
// ---- FetchUnit/FetchUnitTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Fetch unit types
//

package FetchUnitTypes;

import BasicTypes::*;
import MemoryMapTypes::*;

//
// BTB
//

localparam BTB_ENTRY_NUM = 1024;

// Entry: 1(valid)+4(BTB_TAG_WIDTH)+13(BTB_TAG_WIDTH) = 18 bits
// The width of a block ram is 18bits, thus the sum of these parameters is set to 18 bits.

// Tag width, only lower bits are checked and the results of the BTB may incorrect.
localparam BTB_TAG_WIDTH = 4;                

// BTB have bits with BTB_CONTENTS_ADDR_WIDTH. The remaining address bits are made from the PC.
localparam BTB_CONTENTS_ADDR_WIDTH = 13;     


localparam BTB_ENTRY_NUM_BIT_WIDTH = $clog2(BTB_ENTRY_NUM);
typedef logic [BTB_ENTRY_NUM_BIT_WIDTH-1:0] BTB_IndexPath;
typedef logic [BTB_CONTENTS_ADDR_WIDTH-1:0] BTB_AddrPath;
typedef logic [BTB_TAG_WIDTH-1:0] BTB_TagPath;


localparam BTB_QUEUE_SIZE = 32;
localparam BTB_QUEUE_SIZE_BIT_WIDTH = $clog2(BTB_QUEUE_SIZE);
typedef logic [BTB_QUEUE_SIZE_BIT_WIDTH-1:0] BTBQueuePointerPath;

typedef struct packed // struct BTB_Entry
{
    logic valid;
    logic [BTB_TAG_WIDTH-1:0] tag;
    BTB_AddrPath data;
    logic isCondBr;
} BTB_Entry;

typedef struct packed // struct PhtQueueEntry
{
    AddrPath btbWA;            // Write Address
    BTB_Entry btbWV;                        // result of bpred
} BTBQueueEntry;

function automatic BTB_IndexPath ToBTB_Index(PC_Path addr);
    return addr[
        BTB_ENTRY_NUM_BIT_WIDTH + INSN_ADDR_BIT_WIDTH - 1: 
        INSN_ADDR_BIT_WIDTH
    ];
endfunction

function automatic BTB_TagPath ToBTB_Tag(PC_Path addr);
    return addr[
        BTB_ENTRY_NUM_BIT_WIDTH + INSN_ADDR_BIT_WIDTH + BTB_TAG_WIDTH - 1:
        BTB_ENTRY_NUM_BIT_WIDTH + INSN_ADDR_BIT_WIDTH
    ];
endfunction

function automatic BTB_AddrPath ToBTB_Addr(PC_Path addr);
    return addr[
        INSN_ADDR_BIT_WIDTH + BTB_CONTENTS_ADDR_WIDTH - 1:
        INSN_ADDR_BIT_WIDTH
    ];
endfunction

function automatic PC_Path ToRawAddrFromBTB_Addr(BTB_AddrPath addr, PC_Path pc);
    return 
    {
        pc[PC_WIDTH-1 : BTB_CONTENTS_ADDR_WIDTH + 2],
        addr[BTB_CONTENTS_ADDR_WIDTH-1 : 0],
        2'b0
    };
endfunction


//
// GShare
//

localparam BRANCH_GLOBAL_HISTORY_BIT_WIDTH = 10;
typedef logic [BRANCH_GLOBAL_HISTORY_BIT_WIDTH-1 : 0] BranchGlobalHistoryPath;


//
// PHT
//

localparam PHT_ENTRY_NUM = 2048;
localparam PHT_ENTRY_NUM_BIT_WIDTH = $clog2(PHT_ENTRY_NUM);
typedef logic [PHT_ENTRY_NUM_BIT_WIDTH-1:0] PHT_IndexPath;

localparam PHT_ENTRY_WIDTH = 2;
localparam PHT_ENTRY_MAX = (1 << PHT_ENTRY_WIDTH) - 1;
typedef logic [PHT_ENTRY_WIDTH-1:0] PHT_EntryPath;


localparam PHT_QUEUE_SIZE = 32;
localparam PHT_QUEUE_SIZE_BIT_WIDTH = $clog2(PHT_QUEUE_SIZE);
typedef logic [PHT_QUEUE_SIZE_BIT_WIDTH-1:0] PhtQueuePointerPath;

typedef struct packed // struct PhtQueueEntry
{
    AddrPath phtWA;            // Write Address
    PHT_EntryPath phtWV;                        // result of bpred
} PhtQueueEntry;


//
// Result/prediction
//

typedef struct packed // struct BranchResult
{
    PC_Path brAddr;     // The address of a executed branch.
    PC_Path nextAddr;   // The next address of a executed branch.
    logic execTaken;    // The execution result of a branch's direction.
    logic predTaken;    // The prediction result of a branch's direction.
    logic isCondBr;     // Whether this branch is conditional one or not.
    logic mispred;      // Whether the prediction result of this branch is incorrect.
    logic valid;        // Whether this result is valid or not.

    BranchGlobalHistoryPath globalHistory;  // The global history of branches.
    PHT_EntryPath phtPrevValue;             // PHT's counter value
} BranchResult;

typedef struct packed // struct BranchPred
{
    PC_Path predAddr;            // Predicted address
    logic predTaken;                        // result of bpred
    
    BranchGlobalHistoryPath globalHistory;  // The global history of branches.
    PHT_EntryPath phtPrevValue;             // PHT's counter value
} BranchPred;

endpackage : FetchUnitTypes
// ---- LoadStoreUnit/LoadStoreUnitTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Types related to a load-store queue.
//

package LoadStoreUnitTypes;

import BasicTypes::*;
import MemoryMapTypes::*;
import CacheSystemTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import MemoryMapTypes::*;

// Load/store queues compare addresses as a word unit.

// LSQ 内部の処理は，現在は物理アドレス幅に揃える
localparam LSQ_ADDR_MSB = PHY_ADDR_WIDTH; 
localparam LSQ_ADDR_UPPER_PADDING_BIT_SIZE = PHY_ADDR_WIDTH - LSQ_ADDR_MSB;

// LSQ 内部のデータ幅
//localparam LSQ_BLOCK_WIDTH = DATA_WIDTH;  // ロードストアの最大データ幅に等しい
localparam LSQ_BLOCK_WIDTH = 32;  // ロードストアの最大データ幅に等しい
localparam LSQ_BLOCK_WORD_WIDTH = LSQ_BLOCK_WIDTH / DATA_WIDTH;
localparam LSQ_BLOCK_BYTE_WIDTH = LSQ_BLOCK_WIDTH / BYTE_WIDTH;
localparam LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE = $clog2(LSQ_BLOCK_BYTE_WIDTH);
typedef logic [LSQ_BLOCK_WIDTH-1:0] LSQ_BlockDataPath;


// LSQ 内部データ幅単位のアドレス
typedef logic [LSQ_ADDR_MSB-1-LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE:0] LSQ_BlockAddrPath;

function automatic LSQ_BlockAddrPath LSQ_ToBlockAddr(PhyAddrPath addr);
    return addr[LSQ_ADDR_MSB-1 : LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE];
endfunction

function automatic PhyAddrPath LSQ_ToFullAddrFromBlockAddr(LSQ_BlockAddrPath blockAddr);
    return { { LSQ_ADDR_UPPER_PADDING_BIT_SIZE{1'b0} }, blockAddr, {LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE{1'b0}} };
endfunction

// Load queue
localparam LOAD_QUEUE_ENTRY_NUM = 16;
localparam LOAD_QUEUE_ENTRY_NUM_BIT_WIDTH = $clog2(LOAD_QUEUE_ENTRY_NUM);

typedef logic [ LOAD_QUEUE_ENTRY_NUM_BIT_WIDTH-1:0 ] LoadQueueIndexPath;
typedef logic [ LOAD_QUEUE_ENTRY_NUM_BIT_WIDTH:0 ] LoadQueueCountPath;
typedef logic [ (1<<LOAD_QUEUE_ENTRY_NUM_BIT_WIDTH)-1:0 ] LoadQueueOneHotPath;

// Store queue
localparam STORE_QUEUE_ENTRY_NUM = 16;
localparam STORE_QUEUE_ENTRY_NUM_BIT_WIDTH = $clog2(STORE_QUEUE_ENTRY_NUM);

typedef logic [ STORE_QUEUE_ENTRY_NUM_BIT_WIDTH-1:0 ] StoreQueueIndexPath;
typedef logic [ STORE_QUEUE_ENTRY_NUM_BIT_WIDTH:0 ] StoreQueueCountPath;
typedef logic [ (1<<STORE_QUEUE_ENTRY_NUM_BIT_WIDTH)-1:0 ] StoreQueueOneHotPath;

// Read enable signals per word.
typedef logic [ LSQ_BLOCK_WORD_WIDTH-1:0 ] LSQ_BlockWordEnablePath;
typedef logic [ LSQ_BLOCK_BYTE_WIDTH-1:0 ] LSQ_BlockByteEnablePath;
typedef logic [ DATA_BYTE_WIDTH-1:0 ] LSQ_WordByteEnablePath;

// width が 0 の場合は 0 を返す
function automatic int LSQ_SelectBits(int data, int offset, int width);
    int ret;
    ret = 0;
    for (int i = 0; i < width; i++) begin
        ret[i] = data[i + offset];
    end
    return ret;
endfunction

// Generate read / write enable signals for each word
// from a memory address and an access size.
function automatic LSQ_BlockWordEnablePath LSQ_ToBlockWordEnable(
    PhyAddrPath addr,
    MemAccessMode mode
);
    LSQ_BlockWordEnablePath wordEnable;
    case(mode.size)
        MEM_ACCESS_SIZE_VEC: begin
            wordEnable = '1;    // All 1
        end
        default: begin
            wordEnable = 1;     // Lowest word
        end
    endcase

    return
        wordEnable << 
        LSQ_SelectBits(
            addr, DATA_BYTE_WIDTH_BIT_SIZE, LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE - DATA_BYTE_WIDTH_BIT_SIZE
        );
    //return wordEnable << addr[ LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE-1:DATA_BYTE_WIDTH_BIT_SIZE ];
endfunction

// Generate read / write enable signals for each byte
// from a memory address and an access size.
function automatic LSQ_WordByteEnablePath LSQ_ToWordByteEnable(
    PhyAddrPath addr,
    MemAccessMode mode
);
    LSQ_WordByteEnablePath byteEnable;
    
    case(mode.size)
        MEM_ACCESS_SIZE_BYTE: begin
            byteEnable = 'b0001;
        end
        MEM_ACCESS_SIZE_HALF_WORD: begin
            byteEnable = 'b0011;
        end
        default: begin
            byteEnable = '1;
        end
    endcase
    
    return byteEnable << addr[ DATA_BYTE_WIDTH_BIT_SIZE-1:0 ];
endfunction


function automatic PhyAddrPath LSQ_ToFullPhyAddrFromBlockAddrAndWordWE(
    LSQ_BlockAddrPath blockAddr, LSQ_BlockWordEnablePath wordWE
);
    PhyAddrPath ret;
    ret = {blockAddr, {LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE{1'b0}}};
    for (int i = 0; i < LSQ_BLOCK_WORD_WIDTH; i++) begin
        if (wordWE[i]) begin
            return ret + i*DATA_BYTE_WIDTH;
        end
    end
    return ret;
endfunction

function automatic DataPath LSQ_ToScalarWordDataFromBlockData(
    LSQ_BlockDataPath data, LSQ_BlockWordEnablePath wordWE
);
    DataPath ret;
    ret = data[DATA_WIDTH-1:0];
    for (int i = 0; i < LSQ_BLOCK_WORD_WIDTH; i++) begin
        if (wordWE[i]) begin
            return (data >> (i*DATA_WIDTH));
        end
    end
    return ret;
endfunction

//
// Entries of LSQ
//

typedef struct packed // LoadQueueEntry
{
    // Whether the load was executed using the correct source operand
    logic regValid;
    // This flag indicate whether a load is finished or not.
    logic finished;
    
    // The address of a load.
    LSQ_BlockAddrPath address;
    
    // Read enable signals.
    LSQ_BlockWordEnablePath wordRE;

    // Addr for memory dependent predictor.
    PC_Path pc;
} LoadQueueEntry;

typedef struct packed // StoreQueueAddrEntry
{
    // Whether the store was executed using the correct source operand
    logic regValid;
    // This flag indicate whether a load is finished or not.
    logic finished;
    
    // The address of a store.
    LSQ_BlockAddrPath address;
    
    // Write enable signals.
    LSQ_BlockWordEnablePath wordWE;
    LSQ_WordByteEnablePath byteWE;
} StoreQueueAddrEntry;

typedef struct packed // StoreQueueDataEntry
{
    logic condEnabled;
    LSQ_BlockDataPath data;

    // Write enable signals.
    LSQ_BlockWordEnablePath wordWE;
    LSQ_WordByteEnablePath byteWE;
} StoreQueueDataEntry;


endpackage


// ---- RenameLogic/RenameLogicTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Types related to a rename logic.
//

package RenameLogicTypes;

import MicroOpTypes::*;
import BasicTypes::*;
import LoadStoreUnitTypes::*;

//
// --- RMT
//

// RMTはscalar/vectorで共通
localparam RMT_ENTRY_NUM = LREG_NUM;
localparam RMT_INDEX_BIT_SIZE = LREG_NUM_BIT_WIDTH;

`ifdef RSD_ENABLE_VECTOR_PATH
    // PRegNumPathの最上位ビットはscalar/vectorを表すが、
    // そのビットはRMTに保存しない
    localparam RMT_ENTRY_BIT_SIZE = PREG_NUM_BIT_WIDTH - 1;
`else
    localparam RMT_ENTRY_BIT_SIZE = PREG_NUM_BIT_WIDTH;
`endif

//
// --- Free list
//
// 全ての物理レジスタは
// - 論理レジスタに割り当てられている
// - フリーリストに繋がれている
// のどちらかの状態にあるため、
//
// 物理レジスタ数＝論理レジスタ数＋フリーリストの長さ
//
// であり、これを移項することでフリーリストの長さを求める公式が得られる
//

// Free list for general (scalar) registers
localparam SCALAR_FREE_LIST_ENTRY_NUM = PSCALAR_NUM - LSCALAR_NUM;
localparam SCALAR_FREE_LIST_ENTRY_NUM_BIT_WIDTH =
    $clog2( SCALAR_FREE_LIST_ENTRY_NUM );
typedef logic [SCALAR_FREE_LIST_ENTRY_NUM_BIT_WIDTH-1:0] ScalarFreeListIndexPath;
typedef logic [SCALAR_FREE_LIST_ENTRY_NUM_BIT_WIDTH:0] ScalarFreeListCountPath;

// Free list for general (vector) registers
localparam VECTOR_FREE_LIST_ENTRY_NUM = PVECTOR_NUM - LVECTOR_NUM;
localparam VECTOR_FREE_LIST_ENTRY_NUM_BIT_WIDTH =
    $clog2( VECTOR_FREE_LIST_ENTRY_NUM );
typedef logic [VECTOR_FREE_LIST_ENTRY_NUM_BIT_WIDTH-1:0] VectorFreeListIndexPath;
typedef logic [VECTOR_FREE_LIST_ENTRY_NUM_BIT_WIDTH:0] VectorFreeListCountPath;



//
// -- Recovery Mode
//
localparam RECOVERY_FROM_RRMT = FALSE;
localparam RECOVERY_FROM_ACTIVE_LIST = TRUE;

endpackage
// ---- Scheduler/SchedulerTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Types related to an issue queue.
//

package SchedulerTypes;

import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryMapTypes::*;
import MicroOpTypes::*;
import OpFormatTypes::*;
import BypassTypes::*;
import RenameLogicTypes::*;
import LoadStoreUnitTypes::*;
import FetchUnitTypes::*;

// Issue queue
localparam ISSUE_QUEUE_ENTRY_NUM = 16;
localparam ISSUE_QUEUE_ENTRY_NUM_BIT_WIDTH = $clog2(ISSUE_QUEUE_ENTRY_NUM);

typedef logic [ISSUE_QUEUE_ENTRY_NUM_BIT_WIDTH-1:0] IssueQueueIndexPath;
typedef logic [ISSUE_QUEUE_ENTRY_NUM_BIT_WIDTH:0] IssueQueueCountPath;

typedef logic [ISSUE_QUEUE_ENTRY_NUM-1:0] IssueQueueOneHotPath;

localparam ISSUE_QUEUE_SRC_REG_NUM = MICRO_OP_SOURCE_REG_NUM;

localparam ISSUE_QUEUE_INT_LATENCY     = 1;
//localparam ISSUE_QUEUE_COMPLEX_LATENCY = COMPLEX_EXEC_STAGE_DEPTH;
localparam ISSUE_QUEUE_COMPLEX_LATENCY = COMPLEX_EXEC_STAGE_DEPTH + 2;
localparam ISSUE_QUEUE_MEM_LATENCY     = 3;

localparam WAKEUP_WIDTH = INT_ISSUE_WIDTH + COMPLEX_ISSUE_WIDTH + LOAD_ISSUE_WIDTH;    // Stores do not wakeup consumers.

// --- Issue queue flush count
// - 例外発生時に、発行キューは例外命令より後方の命令が選択的にフラッシュされる。
//   その際、フリーリストへのインデックスの返却は専用のポートを介して複数サイクルで行われる。
//   ISSUE_QUEUE_RESET_CYCLE はそのサイクル数を表す。
localparam ISSUE_QUEUE_RETURN_INDEX_WIDTH = 2;
localparam ISSUE_QUEUE_RETURN_INDEX_CYCLE
    = (ISSUE_QUEUE_ENTRY_NUM-1) / ISSUE_QUEUE_RETURN_INDEX_WIDTH + 1; // 割り算して切り上げ
localparam ISSUE_QUEUE_RETURN_INDEX_CYCLE_BIT_SIZE
    = $clog2( ISSUE_QUEUE_RETURN_INDEX_CYCLE );

// --- Issue queue reset count
localparam ISSUE_QUEUE_RESET_CYCLE
    = (ISSUE_QUEUE_ENTRY_NUM-1) / (ISSUE_WIDTH+ISSUE_QUEUE_RETURN_INDEX_WIDTH) + 1; // 割り算して切り上げ
localparam ISSUE_QUEUE_RESET_CYCLE_BIT_SIZE
    = $clog2( ISSUE_QUEUE_RESET_CYCLE );


//
// --- Active list 
//
localparam ACTIVE_LIST_ENTRY_NUM = 64;
localparam ACTIVE_LIST_ENTRY_NUM_BIT_WIDTH = $clog2( ACTIVE_LIST_ENTRY_NUM );
typedef logic [ACTIVE_LIST_ENTRY_NUM_BIT_WIDTH-1:0] ActiveListIndexPath;
typedef logic [ACTIVE_LIST_ENTRY_NUM_BIT_WIDTH:0] ActiveListCountPath;

// Information about the execution of an op.
typedef enum logic [3:0] // ExecutionState
{
    EXEC_STATE_NOT_FINISHED     = 4'b0000,
    EXEC_STATE_SUCCESS          = 4'b0001, // Execution is successfully finished.
    
    EXEC_STATE_REFETCH_THIS     = 4'b0010, // Execution is failed.
                                           // It must be refetch from this op. 
    EXEC_STATE_REFETCH_NEXT     = 4'b0011, // Execution is successfully finished,
                                           // but it must be refetch from next op.
    EXEC_STATE_TRAP_ECALL       = 4'b0100, // Execution causes a trap (ECALL)
    EXEC_STATE_TRAP_EBREAK      = 4'b0101, // Execution causes a trap (EBREAK)
    EXEC_STATE_TRAP_MRET        = 4'b0110,  // Execution causes a MRET

    EXEC_STATE_FAULT_LOAD_MISALIGNED  = 4'b1000,  // Misaligned load is executed
    EXEC_STATE_FAULT_LOAD_VIOLATION   = 4'b1001,  // Load access violation
    EXEC_STATE_FAULT_STORE_MISALIGNED = 4'b1010,  // Misaligned store is executed
    EXEC_STATE_FAULT_STORE_VIOLATION  = 4'b1011,  // Store access violation

    EXEC_STATE_FAULT_INSN_ILLEGAL     = 4'b1100,  // Illegal instruction
    EXEC_STATE_FAULT_INSN_VIOLATION   = 4'b1101,  // Illegal instruction
    EXEC_STATE_FAULT_INSN_MISALIGNED  = 4'b1110   // Mialigned instruciton address
} ExecutionState;
localparam EXEC_STATE_BIT_WIDTH = $bits(ExecutionState);

typedef struct packed // ActiveListEntry
{
    `ifndef RSD_DISABLE_DEBUG_REGISTER // Debug info
        OpId      opId;
    `endif

    PC_Path pc;
    
    LRegNumPath logDstRegNum;
    logic writeReg;
    
    logic isLoad;
    logic isStore;
    logic isBranch; // TRUE if the op is BR or RIJ
    logic isEnv;    // TRUE if the op is ECALL/EBREAK
    
    logic last; // そのARM命令における最後のマイクロ命令ならTRUEに
    logic undefined;
    
    // For releasing a register to a free list on recovery.
    PRegNumPath  phyDstRegNum;

    // For releasing a register to a free list on commitment.
    // and recovering a RMT.
    PRegNumPath  phyPrevDstRegNum;

    IssueQueueIndexPath prevDependIssueQueuePtr;
    
} ActiveListEntry;


typedef struct packed // ActiveListWriteData
{
    ActiveListIndexPath ptr;
    LoadQueueIndexPath loadQueuePtr;
    StoreQueueIndexPath storeQueuePtr;
    ExecutionState      state;
    PC_Path             pc;
    AddrPath            dataAddr;
    logic               isBranch;
    logic               isStore;
} ActiveListWriteData;


// Convert a pointer of an active list to an "age."
// An "age" can be directly compared with a comparetor.
function automatic ActiveListCountPath ActiveListPtrToAge(ActiveListIndexPath ptr, ActiveListIndexPath head);
    ActiveListCountPath age;
    age = ptr;
    if (ptr < head)
        return age + ACTIVE_LIST_ENTRY_NUM; // Wrap around.
    else
        return age;
endfunction


//
// --- OpInfo of Integer Pipeline
//

// IntOpSubInfo と BrOpSubInfo のビット幅を合わせるための　padding の計算をする
localparam INT_SUB_INFO_BIT_WIDTH = 
    $bits(OpOperandType) * 2 + $bits(IntALU_Code) + $bits(ShiftOperandType) + $bits(ShifterPath);
localparam BR_SUB_INFO_BIT_WIDTH =
    $bits(OpOperandType) * 2 + $bits(BranchPred) + $bits(BranchDisplacement);
    
localparam INT_SUB_INFO_PADDING_BIT_WIDTH = 
    BR_SUB_INFO_BIT_WIDTH - INT_SUB_INFO_BIT_WIDTH;

//
typedef struct packed // IntOpInfo
{

    // 論理レジスタを読むかどうか
    OpOperandType operandTypeA;
    OpOperandType operandTypeB;

    IntALU_Code aluCode;

    // 即値
    ShiftOperandType shiftType;
    ShifterPath      shiftIn;

    // BrOpSubInfo とビット幅を合わせるための padding
    logic [INT_SUB_INFO_PADDING_BIT_WIDTH-1:0] padding;
} IntOpSubInfo;

//
typedef struct packed // BrOpInfo
{
    // 論理レジスタを読むかどうか
    OpOperandType operandTypeA;
    OpOperandType operandTypeB;

    BranchPred bPred;
    BranchDisplacement brDisp;        // 分岐ターゲット
} BrOpSubInfo;

typedef union packed    // IntOpInfo
{
    IntOpSubInfo intSubInfo;
    BrOpSubInfo  brSubInfo;
} IntOpInfo;

typedef struct packed // IntIssueQueueEntry
{
`ifndef RSD_DISABLE_DEBUG_REGISTER // Debug info
    OpId      opId;
`endif

    IntOpInfo intOpInfo;

    IntMicroOpSubType opType;
    CondCode cond;
    ActiveListIndexPath activeListPtr;
    LoadQueueIndexPath loadQueueRecoveryPtr;    //for recovery
    StoreQueueIndexPath storeQueueRecoveryPtr;    //for recovery
    OpSrc opSrc;
    OpDst opDst;
    PC_Path pc;
} IntIssueQueueEntry;


//
// --- OpInfo of Complex Integer Pipeline
//

// 1+2=3
typedef struct packed // MulOpInfo
{
    logic mulGetUpper; // 乗算で33-64bit目を結果とするか否か
    IntMUL_Code mulCode;
} MulOpSubInfo;

// 1+2=3
typedef struct packed // DivOpInfo
{
    logic padding;
    IntDIV_Code divCode;
} DivOpSubInfo;

typedef union packed    // ComplexOpInfo
{
    MulOpSubInfo  mulSubInfo;
    DivOpSubInfo  divSubInfo;
} ComplexOpInfo;

typedef struct packed // ComplexIssueQueueEntry
{
`ifndef RSD_DISABLE_DEBUG_REGISTER // Debug info
    OpId      opId;
`endif

    ComplexOpInfo complexOpInfo;
    ComplexMicroOpSubType opType;

    ActiveListIndexPath activeListPtr;
    LoadQueueIndexPath loadQueueRecoveryPtr;    //for recovery
    StoreQueueIndexPath storeQueueRecoveryPtr;    //for recovery
    OpSrc opSrc;
    OpDst opDst;
    PC_Path pc;
} ComplexIssueQueueEntry;

typedef struct packed // MemOpInfo
{
    MemMicroOpSubType opType;

    // 条件コード
    CondCode cond;

    // 論理レジスタを読むかどうか
    OpOperandType operandTypeA;
    OpOperandType operandTypeB;

    // アドレッシング
    AddrOperandImm addrIn;
    logic isAddAddr;    // オフセット加算
    logic isRegAddr;    // レジスタアドレッシング
    MemAccessMode memAccessMode; // signed/unsigned and access size

    // CSR
    CSR_CtrlPath csrCtrl;
    ENV_Code envCode;

    // Complex
`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    MulOpSubInfo mulSubInfo;
    DivOpSubInfo divSubInfo;
`endif

    // Pointer of LSQ
    LoadQueueIndexPath loadQueuePtr;
    StoreQueueIndexPath storeQueuePtr;

    // MSHRをAllocateした命令かどうか
    logic hasAllocatedMSHR;
    MSHR_IndexPath mshrID;

} MemOpInfo;

typedef struct packed // MemIssueQueueEntry
{
`ifndef RSD_DISABLE_DEBUG_REGISTER // Debug info
    OpId      opId;
`endif

    MemOpInfo memOpInfo;
    ActiveListIndexPath activeListPtr;
    LoadQueueIndexPath loadQueueRecoveryPtr;    //for recovery
    StoreQueueIndexPath storeQueueRecoveryPtr;    //for recovery
    OpSrc opSrc;
    OpDst opDst;
    PC_Path pc;
} MemIssueQueueEntry;

//
// Entry of Scheduler
//

typedef struct packed // SchedulerEntry
{
    MicroOpType opType;
    MicroOpSubType opSubType;

    logic srcRegValidA;
    logic srcRegValidB;
    OpSrc opSrc;
    OpDst opDst;

    // Pointer to producers in an issue queue.
    IssueQueueIndexPath srcPtrRegA;
    IssueQueueIndexPath srcPtrRegB;
} SchedulerEntry;


//
// A tag for a source CAM and a ready bit table.
// These tags are used for a ready bit table, thus they are neccesary in
// matrix based implementation.
//

// For a phyical register.
typedef struct packed // SchedulerRegTag
{
    PRegNumPath num;
    logic valid;
} SchedulerRegTag;

//
// A pointer for a producer matrix.
//

// For a phyical register.
typedef struct packed // SchedulerRegPtr
{
    IssueQueueIndexPath ptr;
    logic valid;
} SchedulerRegPtr;

//
// For the destination operand of an op.
//
typedef struct packed // SchedulerDstTag
{
    SchedulerRegTag  regTag;
} SchedulerDstTag;

// For the source operands of an op.
typedef struct packed // SchedulerSrcTag
{
    SchedulerRegTag  [ISSUE_QUEUE_SRC_REG_NUM-1:0] regTag;
    SchedulerRegPtr  [ISSUE_QUEUE_SRC_REG_NUM-1:0] regPtr;
} SchedulerSrcTag;

// Memory Dependent Predictor
localparam MDT_ENTRY_NUM = 1024;
localparam MDT_ENTRY_NUM_BIT_WIDTH = $clog2(MDT_ENTRY_NUM);
typedef logic [MDT_ENTRY_NUM_BIT_WIDTH-1:0] MDT_IndexPath;

typedef struct packed // struct MDT_Entry
{
    logic counter;
    //logic [MDT_ENTRY_WIDTH-1:0] counter; // for expand counter width
} MDT_Entry;

function automatic MDT_IndexPath ToMDT_Index(PC_Path addr);
    return
        addr[
            MDT_ENTRY_NUM_BIT_WIDTH + INSN_ADDR_BIT_WIDTH - 1: 
            INSN_ADDR_BIT_WIDTH
        ];
endfunction

endpackage : SchedulerTypes
// ---- Pipeline/PipelineTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// ---Pipeline Registers
//

package PipelineTypes;

import MicroOpTypes::*;
import BasicTypes::*;
import OpFormatTypes::*;
import BypassTypes::*;
import RenameLogicTypes::*;
import LoadStoreUnitTypes::*;
import SchedulerTypes::*;
import FetchUnitTypes::*;
import MemoryMapTypes::*;

// Controll of a pipeline
// See comments in Controller
typedef struct packed// struct PipelineControll
{
    logic stall;
    logic clear;
} PipelineControll;


// For Recovery
// Phase of a pipeline
// See code of RecoveryManager.sv
typedef enum logic[1:0]
{
    PHASE_COMMIT = 0,
    PHASE_RECOVER_0 = 1,    // The first cycle of a recovery phase.
    PHASE_RECOVER_1 = 2
} PipelinePhase;

// Exception Type
typedef enum logic [2:0] { // RefetchType
    REFETCH_TYPE_THIS_PC                = 3'b000,
    REFETCH_TYPE_NEXT_PC                = 3'b001,
    REFETCH_TYPE_STORE_NEXT_PC          = 3'b010,
    REFETCH_TYPE_BRANCH_TARGET          = 3'b011,
    REFETCH_TYPE_NEXT_PC_TO_CSR_TARGET  = 3'b100,
    REFETCH_TYPE_THIS_PC_TO_CSR_TARGET  = 3'b101
} RefetchType;

//
// Pipeline registers.
// These registers put at the head of each stage.
// For example, DecodeStageRegPath is put at the head of a decode stage, and
// they are written by a fetch stage.
//

typedef struct packed { // FetchStageRegPath
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpSerial sid;
`endif
    logic valid;
    PC_Path pc;
} FetchStageRegPath;

typedef struct packed // PreDecodeStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpSerial sid;
`endif

    logic    valid;     // Valid flag. If this is 0, this op is treated as NOP.
    InsnPath insn;      // Instruction code
    PC_Path pc;
    BranchPred brPred;
} PreDecodeStageRegPath;

typedef struct packed // DecodeStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpSerial sid;
`endif

    logic    valid;     // Valid flag. If this is 0, this op is treated as NOP.
    InsnPath insn;      // Instruction code
    PC_Path pc;
    BranchPred brPred;

    OpInfo [MICRO_OP_MAX_NUM-1:0] microOps;  // Decoded micro ops
    InsnInfo insnInfo;   // Whether a decoded instruction is branch or not.
} DecodeStageRegPath;


typedef struct packed // RenameStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic    valid;     // Valid flag. If this is 0, this op is treated as NOP.
    OpInfo   opInfo;    // Decoded micro op.
    PC_Path pc;
    BranchPred bPred;
} RenameStageRegPath;

typedef struct packed // DispatchStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic    valid;     // Valid flag. If this is 0, this op is treated as NOP.
    OpInfo   opInfo;    // Decoded micro op.

    PC_Path pc;        // Program counter
    BranchPred brPred;  // Branch prediction result.

    // Renamed physical register numbers.
    PRegNumPath phySrcRegNumA;
    PRegNumPath phySrcRegNumB;
    PRegNumPath phyDstRegNum;
    PRegNumPath phyPrevDstRegNum;  // For releasing a register.

    // Source pointer for a matrix scheduler.
    IssueQueueIndexPath srcIssueQueuePtrRegA;
    IssueQueueIndexPath srcIssueQueuePtrRegB;

    IssueQueueIndexPath issueQueuePtr;
    ActiveListIndexPath activeListPtr;
    LoadQueueIndexPath loadQueuePtr;
    StoreQueueIndexPath storeQueuePtr;
    LoadQueueIndexPath loadQueueRecoveryPtr;
    StoreQueueIndexPath storeQueueRecoveryPtr;
} DispatchStageRegPath;

typedef struct packed // IssueStageRegPath
{
    logic    valid;     // Valid flag. If this is 0, this op is treated as NOP.
    IssueQueueIndexPath issueQueuePtr;
} IssueStageRegPath;

//
// Integer back end
//
typedef struct packed // IntegerRegisterReadStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;     // Valid flag. If this is 0, its op is treated as NOP.
    IntIssueQueueEntry intQueueData;
} IntegerRegisterReadStageRegPath;


typedef struct packed // IntegerExecutionStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;      // Valid flag. If this is 0, its op is treated as NOP.
    IntIssueQueueEntry intQueueData;

    // register read out
    PRegDataPath operandA;
    PRegDataPath operandB;

    // Bypass control
    BypassControll bCtrl;
} IntegerExecutionStageRegPath;


typedef struct packed // IntegerRegisterWriteStageRegPath
{

`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;  // Valid flag. If this is 0, its op is treated as NOP.
    IntIssueQueueEntry intQueueData;

    PRegDataPath dataOut;   // Result of ALU/shifter/Load

    logic brMissPred;
    BranchResult brResult;  // Result of branch
} IntegerRegisterWriteStageRegPath;

//
// ComplexInteger back end
//
typedef struct packed // ComplexIntegerRegisterReadStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;     // Valid flag. If this is 0, its op is treated as NOP.
    logic replay;
    ComplexIssueQueueEntry complexQueueData;
} ComplexIntegerRegisterReadStageRegPath;


typedef struct packed // ComplexIntegerExecutionStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;      // Valid flag. If this is 0, its op is treated as NOP.
    logic replay;
    logic isFlushed;
    ComplexIssueQueueEntry complexQueueData;

    // register read out
    PRegDataPath operandA;
    PRegDataPath operandB;
`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath vecOperandA;
    PVecDataPath vecOperandB;
`endif

    // Bypass control
    BypassControll bCtrl;
} ComplexIntegerExecutionStageRegPath;


typedef struct packed // ComplexIntegerRegisterWriteStageRegPath
{

`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;  // Valid flag. If this is 0, its op is treated as NOP.
    ComplexIssueQueueEntry complexQueueData;

    PRegDataPath dataOut;   // Result of Execution
`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath vecDataOut;
`endif
} ComplexIntegerRegisterWriteStageRegPath;


//
// Memory back end
//
typedef struct packed // MemoryRegisterReadStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;     // Valid flag. If this is 0, its op is treated as NOP.
    MemIssueQueueEntry memQueueData;

    // For release of the entries of an issue queue. See comments in MemoryExecutionStage.
    IssueQueueIndexPath issueQueuePtr;
    logic replay;
} MemoryRegisterReadStageRegPath;


typedef struct packed // MemoryExecutionStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;      // Valid flag. If this is 0, its op is treated as NOP.
    MemIssueQueueEntry memQueueData;

    // register read out
    PRegDataPath operandA;
    PRegDataPath operandB;
`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath vecOperandB;
`endif

    // Bypass control
    BypassControll bCtrl;

    // For release of the entries of an issue queue. See comments in MemoryExecutionStage.
    IssueQueueIndexPath issueQueuePtr;
    logic replay;

} MemoryExecutionStageRegPath;


typedef struct packed // MemoryTagAccessStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic valid;      // Valid flag. If this is 0, its op is treated as NOP.
    MemIssueQueueEntry memQueueData;

    logic condEnabled;      // 条件コードは有効か
    logic regValid;         // Whether source operands are valid or not.

    DataPath addrOut;       // The result of address calculation.
    DataPath dataIn;        // The input data for store or CSR data out
`ifdef RSD_ENABLE_VECTOR_PATH
    VectorPath vecDataIn;   // The input data for store
`endif
    MemoryMapType memMapType;  // Memory map type: mem/io
    PhyAddrPath phyAddrOut;

} MemoryTagAccessStageRegPath;


typedef struct packed // MemoryAccessStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic    valid;      // Valid flag. If this is 0, its op is treated as NOP.

    logic isStore;
    logic isLoad;
    logic isCSR;
    logic isDiv;
    logic isMul;
    OpDst opDst;

    ActiveListIndexPath activeListPtr;  // Use to write recovery reg
    LoadQueueIndexPath loadQueueRecoveryPtr;
    StoreQueueIndexPath storeQueueRecoveryPtr;
    AddrPath pc;

    logic regValid;             // Whether source operands are valid or not.
    ExecutionState execState;   // Execution status. See RenameLogicTypes.sv
    
    AddrPath addrOut;    // The result of address calculation.
    MemoryMapType memMapType;  // Memory map type: mem/io
    PhyAddrPath phyAddrOut;    // The result of address calculation.
    
    // CSR data out. csrDataOut is from dataIn in MemoryTagAccessStageRegPath
    // TODO: addrOut and csrDataOut is exclusively used, these can be unified.
    DataPath csrDataOut; 

} MemoryAccessStageRegPath;


typedef struct packed // MemoryRegisterWriteStageRegPath
{
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpId      opId;
`endif

    logic    valid;     // Valid flag. If this is 0, its op is treated as NOP.
    ActiveListIndexPath activeListPtr;
    LoadQueueIndexPath loadQueueRecoveryPtr;
    StoreQueueIndexPath storeQueueRecoveryPtr;
    AddrPath pc;
    AddrPath addrOut;

    OpDst    opDst;
    ExecutionState execState; // Execution status. See RenameLogicTypes.sv
    logic isStore;

    PRegDataPath dataOut;    // Result of Load
`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath vecDataOut; // Result of Vector Load
`endif

} MemoryRegisterWriteStageRegPath;

function automatic logic SelectiveFlushDetector(
    input logic detectRange,
    input ActiveListIndexPath headPtr,
    input ActiveListIndexPath tailPtr,
    input ActiveListIndexPath opPtr
);
    if(!detectRange) begin
        return FALSE;
    end
    else if(detectRange && tailPtr >= headPtr) begin
        //  |---h***i***t-------|
        if(opPtr >= headPtr && opPtr < tailPtr) begin
            return TRUE;
        end
        else begin
            return FALSE;
        end
    end
    else if(detectRange && tailPtr < headPtr) begin
        //  |*****t----h***i****|
        if(opPtr >= headPtr && opPtr > tailPtr) begin
            return TRUE;
        end
        //  |**i***t----h*******|
        else if(opPtr < headPtr && opPtr < tailPtr) begin
            return TRUE;
        end
        else begin
            return FALSE;
        end
    end
    else begin
        return FALSE;
    end
endfunction

endpackage


// ---- IO/IO_UnitTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Types related to IO_Unit
//

package IO_UnitTypes;

import BasicTypes::*;

// Timer related definitions
localparam TIMER_REGISTER_WIDTH = 64;
typedef logic [TIMER_REGISTER_WIDTH-1:0] TimerRegisterRawPath;

typedef struct packed{    // struct TimerRegisterSplitPath
    DataPath hi;
    DataPath low;
} TimerRegisterSplitPath;

typedef union packed {
    TimerRegisterRawPath raw;
    TimerRegisterSplitPath split;
} TimerRegisterPath;

typedef struct packed {
    TimerRegisterPath mtime;
    TimerRegisterPath mtimecmp;
} TimerRegsters;


//
// --- LED IO
//
`ifndef RSD_SYNTHESIS
localparam LED_WIDTH = 16;
`elsif RSD_SYNTHESIS_ZEDBOARD
localparam LED_WIDTH = 8;
`else
localparam LED_WIDTH = 16;
`endif
typedef logic [ LED_WIDTH-1:0 ] LED_Path;

// Serial IO
`ifdef RSD_SYNTHESIS_FPGA
    localparam SERIAL_OUTPUT_WIDTH = 8;
`else
    localparam SERIAL_OUTPUT_WIDTH = 32;
`endif
typedef logic [ SERIAL_OUTPUT_WIDTH-1:0 ] SerialDataPath;



endpackage


// ---- Privileged/CSR_UnitTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


// 
// --- Types related to CSR
//

package CSR_UnitTypes;

import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;

// If you add additonal status bits, check CSR_Unit.sv because 
// only valid fileds are updated.
typedef struct packed {
    logic [23:0] padding_2;  // 31:8
    logic MPIE;               // 7
    logic [2:0] padding_1;   // 6:4
    logic MIE;              // 3
    logic [2:0] padding_0;   // 2:0
} CSR_MSTATUS_Path;

// Interrupt pending?
typedef struct packed {
    logic [19:0] padding_3; // 31:12
    logic MEIP;             // 11:11    external interrupt
    logic [2:0] padding_2;  // 10:8
    logic MTIP;             // 7:7      timer interrupt
    logic [2:0] padding_1;  // 6:4
    logic MSIP;             // 3:3      software interrupt
    logic [2:0] padding_0;  // 2:0
} CSR_MIP_Path;

// Interrupt enable?
typedef struct packed {
    logic [19:0] padding_3; // 31:12
    logic MEIE;             // 11:11    external interrupt
    logic [2:0] padding_2;  // 10:8
    logic MTIE;             // 7:7      timer interrupt
    logic [2:0] padding_1;  // 6:4
    logic MSIE;             // 3:3      software interrupt
    logic [2:0] padding_0;  // 2:0
} CSR_MIE_Path;

typedef enum logic [3:0] {
    CSR_CAUSE_TRAP_CODE_INSN_MISALIGNED = 0,
    CSR_CAUSE_TRAP_CODE_INSN_VIOLATION = 1,
    CSR_CAUSE_TRAP_CODE_INSN_ILLEGAL = 2,
    CSR_CAUSE_TRAP_CODE_BREAK = 3,
    CSR_CAUSE_TRAP_CODE_LOAD_MISALIGNED = 4,
    CSR_CAUSE_TRAP_CODE_LOAD_VIOLATION = 5,
    CSR_CAUSE_TRAP_CODE_STORE_MISALIGNED = 6,
    CSR_CAUSE_TRAP_CODE_STORE_VIOLATION = 7,
    CSR_CAUSE_TRAP_CODE_MCALL = 11,

    CSR_CAUSE_TRAP_CODE_UNKNOWN = 14
} CSR_CAUSE_TrapCodePath;

function automatic CSR_CAUSE_TrapCodePath ToTrapCodeFromExecState(ExecutionState state);
    case(state)
    EXEC_STATE_TRAP_ECALL:  return CSR_CAUSE_TRAP_CODE_MCALL;
    EXEC_STATE_TRAP_EBREAK: return CSR_CAUSE_TRAP_CODE_BREAK;

    EXEC_STATE_FAULT_LOAD_MISALIGNED:  return CSR_CAUSE_TRAP_CODE_LOAD_MISALIGNED;
    EXEC_STATE_FAULT_LOAD_VIOLATION:   return CSR_CAUSE_TRAP_CODE_LOAD_VIOLATION;
    EXEC_STATE_FAULT_STORE_MISALIGNED: return CSR_CAUSE_TRAP_CODE_STORE_MISALIGNED;
    EXEC_STATE_FAULT_STORE_VIOLATION:  return CSR_CAUSE_TRAP_CODE_STORE_VIOLATION;
    
    EXEC_STATE_FAULT_INSN_ILLEGAL:     return CSR_CAUSE_TRAP_CODE_INSN_ILLEGAL;
    EXEC_STATE_FAULT_INSN_VIOLATION:   return CSR_CAUSE_TRAP_CODE_INSN_VIOLATION;
    EXEC_STATE_FAULT_INSN_MISALIGNED:  return CSR_CAUSE_TRAP_CODE_INSN_MISALIGNED;

    default: return CSR_CAUSE_TRAP_CODE_UNKNOWN;
    endcase
endfunction


typedef enum logic [3:0] {
    CSR_CAUSE_INTERRUPT_CODE_TIMER = 7
} CSR_CAUSE_InterruptCodePath;

typedef union packed    // IntOpInfo
{
    CSR_CAUSE_TrapCodePath trapCode;
    CSR_CAUSE_InterruptCodePath  interruptCode;
} CSR_CAUSE_CodePath;

typedef struct packed {
    logic isInterrupt;          // 31
    logic [26:0] padding;       // 30:4
    CSR_CAUSE_CodePath code;    //  3:0
} CSR_CAUSE_Path;


typedef enum logic [1:0] {
    CSR_MTVEC_MODE_BASE = 0,
    CSR_MTVEC_MODE_VECTORED = 1
} CSR_MTVEC_ModePath;

typedef struct packed {
    logic [29:0]        base;    // 31:2
    CSR_MTVEC_ModePath  mode;    //  1:0
} CSR_MTVEC_Path;

localparam logic [1:0] CSR_MTVEC_BASE_PADDING = 2'b0;

// All members have 32bit width
typedef union packed {
    CSR_MSTATUS_Path mstatus;
    CSR_MIP_Path mip;
    CSR_MIE_Path mie;
    CSR_CAUSE_Path mcause;
    CSR_MTVEC_Path mtvec;
    DataPath mtval;
    DataPath mepc;
    DataPath mscratch;

    DataPath mcycle;
    DataPath minstret;
} CSR_ValuePath;

typedef struct packed {
    // Inturrupt related registers
    CSR_MSTATUS_Path mstatus;
    CSR_MIP_Path mip;
    CSR_MIE_Path mie;
    CSR_CAUSE_Path mcause;
    CSR_MTVEC_Path mtvec;
    DataPath mtval;
    DataPath mepc;
    DataPath mscratch;

    DataPath mcycle;
    DataPath minstret;
} CSR_BodyPath;

//
// Machine Information Registers
//
localparam CSR_NUM_MVENDORID = 12'hF11; // Vendor ID.
localparam CSR_NUM_MARCHID   = 12'hF12; // Architecture ID.
localparam CSR_NUM_MIMPID    = 12'hF13; // Implementation ID.
localparam CSR_NUM_MHARTID   = 12'hF14; // Hardware thread ID.

//
// Machine Trap Setup
//
localparam CSR_NUM_MSTATUS   = 12'h300; // Machine status register.
localparam CSR_NUM_MISA      = 12'h301; // ISA and extensions
localparam CSR_NUM_MEDELEG   = 12'h302; // Machine exception delegation register.
localparam CSR_NUM_MIDELEG   = 12'h303; // Machine interrupt delegation register.
localparam CSR_NUM_MIE       = 12'h304; // Machine interrupt-enable register.
localparam CSR_NUM_MTVEC     = 12'h305; // Machine trap-handler base address.
localparam CSR_NUM_MCOUNTEREN = 12'h306; // Machine counter enable.

//
// Machine Trap Handling
//
localparam CSR_NUM_MSCRATCH  = 12'h340; // Scratch register for machine trap handlers.
localparam CSR_NUM_MEPC      = 12'h341; // Machine exception program counter.
localparam CSR_NUM_MCAUSE    = 12'h342; // Machine trap cause.
localparam CSR_NUM_MTVAL     = 12'h343; // Machine bad address or instruction.
localparam CSR_NUM_MIP       = 12'h344; // Machine interrupt pending.

//
// Machine Protection and Translation
//
localparam CSR_NUM_PMPCFG0   = 12'h3A0; // Physical memory protection configuration.
localparam CSR_NUM_PMPCFG1   = 12'h3A1; // Physical memory protection configuration, RV32 only.
localparam CSR_NUM_PMPCFG2   = 12'h3A2; // Physical memory protection configuration.
localparam CSR_NUM_PMPCFG3   = 12'h3A3; // Physical memory protection configuration, RV32 only.

localparam CSR_NUM_PMPADDR0  = 12'h3B0; // Physical memory protection address register.
localparam CSR_NUM_PMPADDR1  = 12'h3B1; 
localparam CSR_NUM_PMPADDR2  = 12'h3B2;
localparam CSR_NUM_PMPADDR3  = 12'h3B3;
localparam CSR_NUM_PMPADDR4  = 12'h3B4;
localparam CSR_NUM_PMPADDR5  = 12'h3B5;
localparam CSR_NUM_PMPADDR6  = 12'h3B6;
localparam CSR_NUM_PMPADDR7  = 12'h3B7;
localparam CSR_NUM_PMPADDR8  = 12'h3B8;
localparam CSR_NUM_PMPADDR9  = 12'h3B9;
localparam CSR_NUM_PMPADDR10 = 12'h3BA;
localparam CSR_NUM_PMPADDR11 = 12'h3BB;
localparam CSR_NUM_PMPADDR12 = 12'h3BC;
localparam CSR_NUM_PMPADDR13 = 12'h3BD;
localparam CSR_NUM_PMPADDR14 = 12'h3BE;
localparam CSR_NUM_PMPADDR15 = 12'h3BF;

localparam CSR_NUM_MCYCLE        = 12'hB00; // Machine cycle counter.
localparam CSR_NUM_MINSTRET      = 12'hB02; // Machine instructions-retired counter.

localparam CSR_NUM_MHPMCOUNTER3  = 12'hB03; // Machine performance-monitoring counter.
localparam CSR_NUM_MHPMCOUNTER4  = 12'hB04; // Machine performance-monitoring counter.
// ... TODO: Define these counters
localparam CSR_NUM_MHPMCOUNTER31 = 12'hB1F; // Machine performance-monitoring counter.

localparam CSR_NUM_MCYCLEH       = 12'hB80; // Upper 32 bits of mcycle, RV32I only.
localparam CSR_NUM_MINSTRETH     = 12'hB82; // Upper 32 bits of minstret, RV32I only.
localparam CSR_NUM_MHPMCOUNTER3H = 12'hB83; // Upper 32 bits of mhpmcounter3, RV32I only.
localparam CSR_NUM_MHPMCOUNTER4H = 12'hB84; // Upper 32 bits of mhpmcounter4, RV32I only.
// ... TODO: Define these counters
localparam CSR_NUM_MHPMCOUNTER31H = 12'hB9F; // Upper 32 bits of mhpmcounter31, RV32I only.

//
// Machine Counter Setup
//
localparam CSR_NUM_MHPMEVENT3    = 12'h323; // Machine performance-monitoring event selector.
localparam CSR_NUM_MHPMEVENT4    = 12'h324; // Machine performance-monitoring event selector.
// ... TODO: Define these counters
localparam CSR_NUM_MHPMEVENT31   = 12'h33F; // Machine performance-monitoring event selector.

//
// Debug/Trace Registers (shared with Debug Mode)
//
localparam CSR_NUM_TSELECT   = 12'h7A0; // Debug/Trace trigger register select.
localparam CSR_NUM_TDATA1    = 12'h7A1; // First Debug/Trace trigger data register.
localparam CSR_NUM_TDATA2    = 12'h7A2; // Second Debug/Trace trigger data register.
localparam CSR_NUM_TDATA3    = 12'h7A3; // Third Debug/Trace trigger data register.


// Debug Mode Registers
localparam CSR_NUM_DCSR      = 12'h7B0; // Debug control and status register.
localparam CSR_NUM_DPC       = 12'h7B1; // Debug PC.
localparam CSR_NUM_DSCRATCH  = 12'h7B2; // Debug scratch register.


endpackage


// ---- Debug/DebugTypes.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Types related to debug.
//


package DebugTypes;

import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import LoadStoreUnitTypes::*;
import PipelineTypes::*;

//
// --- Hardware Counter
//

// ハードウェアカウンタ用のアドレス範囲
// アドレスの上位 HARDWARE_COUNTER_TAG_BIT_SIZE ビットが
// HARDWARE_COUNTER_TAG と一致したら、ハードウェアカウンタ用アドレス
localparam HARDWARE_COUNTER_TAG = 5'b11111; // addr: f8000000-ffffffff
localparam HARDWARE_COUNTER_TAG_BIT_SIZE = 5;
localparam HARDWARE_COUNTER_TAG_MSB = DATA_WIDTH - 1;
localparam HARDWARE_COUNTER_TAG_LSB =
    HARDWARE_COUNTER_TAG_MSB - HARDWARE_COUNTER_TAG_BIT_SIZE + 1;

// ハードウェアカウンタの種類を指定するビットの指定
localparam HARDWARE_COUNTER_TYPE_BIT_SIZE = 3;
localparam HARDWARE_COUNTER_TYPE_LSB = DATA_BYTE_WIDTH_BIT_SIZE;
localparam HARDWARE_COUNTER_TYPE_MSB =
    HARDWARE_COUNTER_TYPE_LSB + HARDWARE_COUNTER_TYPE_BIT_SIZE - 1;

// 各種ハードウェアカウンタ
typedef enum logic [ HARDWARE_COUNTER_TYPE_BIT_SIZE-1:0 ] {
    HW_CNT_TYPE_CYCLE = 0,
    HW_CNT_TYPE_COMMIT = 1,
    HW_CNT_TYPE_REFETCH_THIS_PC = 2,
    HW_CNT_TYPE_REFETCH_NEXT_PC = 3,
    HW_CNT_TYPE_REFETCH_BR_TARGET = 4,
    HW_CNT_TYPE_LOAD_MISS = 5
} HardwareCounterType;

//
// --- Debug Register
//

typedef struct packed { // NextPCStageDebugRegister
    logic valid;
    OpSerial sid;
} NextPCStageDebugRegister;

typedef struct packed { // FetchStageDebugRegister
    logic valid;
    OpSerial sid;
    logic flush;
} FetchStageDebugRegister;

typedef struct packed { // PreDecodeStageDebugRegister
    logic valid;
    OpSerial sid;
`ifdef RSD_FUNCTIONAL_SIMULATION
    // 演算のソースと結果の値は、機能シミュレーション時のみデバッグ出力する
    // 合成時は、IOポートが足りなくて不可能であるため
    IntALU_Code aluCode;
    IntMicroOpSubType opType;
`endif
} PreDecodeStageDebugRegister;

typedef struct packed { // DecodeStageDebugRegister
    logic valid;
    logic flush;    // Branch misprediction is detected on instruction decode and flush this instruction.
    OpId opId;
    AddrPath pc;
    InsnPath insn;
    logic undefined;
    logic unsupported;
} DecodeStageDebugRegister;

typedef struct packed { // RenameStageDebugRegister
    logic valid;
    OpId opId;

    // Physical register numbers are outputed in the next stage, becuase
    // The pop flags of the free list is negated and correct physical
    // register numbers cannot be outputed in this stage when the pipeline
    // is stalled.
} RenameStageDebugRegister;

typedef struct packed { // DispatchStageDebugRegister
    logic valid;
    OpId opId;


`ifdef RSD_FUNCTIONAL_SIMULATION
    // レジスタ番号は、機能シミュレーション時のみデバッグ出力する
    // 合成時は、IOポートが足りなくて不可能であるため
    logic readRegA;
    LRegNumPath logSrcRegA;
    PRegNumPath phySrcRegA;

    logic readRegB;
    LRegNumPath logSrcRegB;
    PRegNumPath phySrcRegB;

    logic writeReg;
    LRegNumPath logDstReg;
    PRegNumPath phyDstReg;
    PRegNumPath phyPrevDstReg;

    IssueQueueIndexPath issueQueuePtr;
`endif
} DispatchStageDebugRegister;

typedef struct packed { // IntegerIssueStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} IntegerIssueStageDebugRegister;

typedef struct packed { // IntegerRegisterReadStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} IntegerRegisterReadStageDebugRegister;

typedef struct packed { // IntegerExecutionStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;

`ifdef RSD_FUNCTIONAL_SIMULATION
    // 演算のソースと結果の値は、機能シミュレーション時のみデバッグ出力する
    // 合成時は、IOポートが足りなくて不可能であるため
    DataPath dataOut;
    DataPath fuOpA;
    DataPath fuOpB;
    IntALU_Code aluCode;
    IntMicroOpSubType opType;
`endif

} IntegerExecutionStageDebugRegister;

typedef struct packed { // IntegerRegisterWriteStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} IntegerRegisterWriteStageDebugRegister;

typedef struct packed { // ComplexIntegerIssueStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} ComplexIntegerIssueStageDebugRegister;

typedef struct packed { // ComplexIntegerRegisterReadStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} ComplexIntegerRegisterReadStageDebugRegister;

typedef struct packed { // ComplexIntegerExecutionStageDebugRegister
    logic [ COMPLEX_EXEC_STAGE_DEPTH-1:0 ] valid;
    logic [ COMPLEX_EXEC_STAGE_DEPTH-1:0 ] flush;
    OpId [ COMPLEX_EXEC_STAGE_DEPTH-1:0 ] opId;

`ifdef RSD_FUNCTIONAL_SIMULATION
    // 演算のソースと結果の値は、機能シミュレーション時のみデバッグ出力する
    // 合成時は、IOポートが足りなくて不可能であるため
    DataPath dataOut;
    DataPath fuOpA;
    DataPath fuOpB;

    VectorPath vecDataOut;
    VectorPath fuVecOpA;
    VectorPath fuVecOpB;
`endif

} ComplexIntegerExecutionStageDebugRegister;

typedef struct packed { // ComplexIntegerRegisterWriteStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} ComplexIntegerRegisterWriteStageDebugRegister;

typedef struct packed { // MemoryIssueStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} MemoryIssueStageDebugRegister;

typedef struct packed { // MemoryRegisterReadStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} MemoryRegisterReadStageDebugRegister;

typedef struct packed { // MemoryExecutionStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;

`ifdef RSD_FUNCTIONAL_SIMULATION
    // 演算のソースと結果の値は、機能シミュレーション時のみデバッグ出力する
    // 合成時は、IOポートが足りなくて不可能であるため
    AddrPath addrOut;
    DataPath fuOpA;
    DataPath fuOpB;
    VectorPath fuVecOpB;
    MemMicroOpSubType opType;
    MemAccessSizeType size;
    logic isSigned;
`endif

} MemoryExecutionStageDebugRegister;

typedef struct packed { // MemoryTagAccessStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
`ifdef RSD_FUNCTIONAL_SIMULATION
    logic executeLoad;
    AddrPath executedLoadAddr;
    logic executeStore;
    AddrPath executedStoreAddr;
    DataPath executedStoreData;
    VectorPath executedStoreVectorData;
`endif
} MemoryTagAccessStageDebugRegister;

typedef struct packed { // MemoryAccessStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
`ifdef RSD_FUNCTIONAL_SIMULATION
    logic executeLoad;
    DataPath executedLoadData;
    VectorPath executedLoadVectorData;
`endif
} MemoryAccessStageDebugRegister;

typedef struct packed { // MemoryRegisterWriteStageDebugRegister
    logic valid;
    logic flush;
    OpId opId;
} MemoryRegisterWriteStageDebugRegister;

typedef struct packed { // CommitStageDebugRegister
    logic commit;
    logic flush;
    OpId opId;

`ifdef RSD_FUNCTIONAL_SIMULATION
    logic releaseReg;
    PRegNumPath phyReleasedReg;
`endif
} CommitStageDebugRegister;

typedef struct packed { // ActiveListDebugRegister
    logic finished;
    OpId opId;
} ActiveListDebugRegister;

typedef struct packed { // SchedulerDebugRegister
    logic valid;
} SchedulerDebugRegister;

typedef struct packed { // IssueQueueDebugRegister
    logic flush;
    OpId opId;
} IssueQueueDebugRegister;


`ifndef RSD_DISABLE_DEBUG_REGISTER
typedef struct packed { // DebugRegister

    // DebugRegister of each stage
    NextPCStageDebugRegister [ FETCH_WIDTH-1:0 ] npReg;
    FetchStageDebugRegister   [ FETCH_WIDTH-1:0 ] ifReg;
    PreDecodeStageDebugRegister[ DECODE_WIDTH-1:0 ]   pdReg;
    DecodeStageDebugRegister   [ DECODE_WIDTH-1:0 ]   idReg;
    RenameStageDebugRegister   [ RENAME_WIDTH-1:0 ]   rnReg;
    DispatchStageDebugRegister [ DISPATCH_WIDTH-1:0 ] dsReg;

    IntegerIssueStageDebugRegister         [ INT_ISSUE_WIDTH-1:0 ] intIsReg;
    IntegerRegisterReadStageDebugRegister  [ INT_ISSUE_WIDTH-1:0 ] intRrReg;
    IntegerExecutionStageDebugRegister     [ INT_ISSUE_WIDTH-1:0 ] intExReg;
    IntegerRegisterWriteStageDebugRegister [ INT_ISSUE_WIDTH-1:0 ] intRwReg;

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    ComplexIntegerIssueStageDebugRegister         [ COMPLEX_ISSUE_WIDTH-1:0 ] complexIsReg;
    ComplexIntegerRegisterReadStageDebugRegister  [ COMPLEX_ISSUE_WIDTH-1:0 ] complexRrReg;
    ComplexIntegerExecutionStageDebugRegister     [ COMPLEX_ISSUE_WIDTH-1:0 ] complexExReg;
    ComplexIntegerRegisterWriteStageDebugRegister [ COMPLEX_ISSUE_WIDTH-1:0 ] complexRwReg;
`endif

    MemoryIssueStageDebugRegister          [ MEM_ISSUE_WIDTH-1:0 ] memIsReg;
    MemoryRegisterReadStageDebugRegister   [ MEM_ISSUE_WIDTH-1:0 ] memRrReg;
    MemoryExecutionStageDebugRegister      [ MEM_ISSUE_WIDTH-1:0 ] memExReg;
    MemoryTagAccessStageDebugRegister      [ MEM_ISSUE_WIDTH-1:0 ] mtReg;
    MemoryAccessStageDebugRegister         [ MEM_ISSUE_WIDTH-1:0 ] maReg;
    MemoryRegisterWriteStageDebugRegister  [ MEM_ISSUE_WIDTH-1:0 ] memRwReg;

    CommitStageDebugRegister [ COMMIT_WIDTH-1:0 ] cmReg;

    SchedulerDebugRegister  [ ISSUE_QUEUE_ENTRY_NUM-1:0 ] scheduler;
    IssueQueueDebugRegister [ ISSUE_QUEUE_ENTRY_NUM-1:0 ] issueQueue;

    // Signals related to commit
    logic toRecoveryPhase;
    ActiveListIndexPath activeListHeadPtr;
    ActiveListCountPath activeListCount;

    // Pipeline control signal
    PipelineControll npStagePipeCtrl;
    PipelineControll ifStagePipeCtrl;
    PipelineControll pdStagePipeCtrl;
    PipelineControll idStagePipeCtrl;
    PipelineControll rnStagePipeCtrl;
    PipelineControll dsStagePipeCtrl;
    PipelineControll backEndPipeCtrl;
    PipelineControll cmStagePipeCtrl;
    logic stallByDecodeStage;

    // Others
    logic loadStoreUnitAllocatable;
    logic storeCommitterPhase;
    StoreQueueCountPath storeQueueCount;
    logic busyInRecovery;
    logic storeQueueEmpty;
} DebugRegister;
`else
    // Dummy definition
    typedef logic DebugRegister;
`endif

endpackage
// ---- Core.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Core module
//
// プロセッサ・コアに含まれる全てのモジュールをインスタンシエートし、
// インターフェースで接続する

import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryTypes::*;
import MemoryMapTypes::*;
import IO_UnitTypes::*;
import DebugTypes::*;

module Core (
input
    logic clk,
    logic rst, rstStart,
    MemAccessSerial nextMemReadSerial, // RSDの次の読み出し要求に割り当てられるシリアル(id)
    MemWriteSerial nextMemWriteSerial, // RSDの次の書き込み要求に割り当てられるシリアル(id)
    MemoryEntryDataPath memReadData,
    logic memReadDataReady,
    MemAccessSerial memReadSerial, // メモリの読み出しデータのシリアル
    MemAccessResponse memAccessResponse, // メモリ書き込み完了通知
    logic memAccessReadBusy,
    logic memAccessWriteBusy,
    logic [15:0] serialIn,
output
    DebugRegister debugRegister,
    PC_Path lastCommittedPC,
    PhyAddrPath memAccessAddr,
    MemoryEntryDataPath memAccessWriteData,
    logic memAccessRE,
    logic memAccessWE,
    logic serialWE,
    SerialDataPath serialWriteData,
    DataPath tohost,
    logic [7:0] serialInAck
);
    //
    // --- For Debug
    //
    DebugIF debugIF( clk, rst );
    HardwareCounterIF hwCounterIF( clk, rst );

    assign debugRegister = debugIF.debugRegister;

`ifndef RSD_DISABLE_DEBUG_REGISTER
    Debug debug ( debugIF, lastCommittedPC );
`else
    always_ff @(posedge clk) begin
        lastCommittedPC <= debugIF.lastCommittedPC;
    end
`endif

`ifndef RSD_DISABLE_HARDWARE_COUNTER
    //HardwareCounter hwCounter( hwCounterIF );
    SimpleHardwareCounter hwCounter( hwCounterIF ); // 実行サイクル数のみカウント
`endif

    //
    // --- Interfaces
    //

    // Pipeline control logic
    ControllerIF ctrlIF( clk, rst );

    // Pipeline stages
    NextPCStageIF npStageIF( clk, rst, rstStart );
    FetchStageIF ifStageIF( clk, rst, rstStart );
    PreDecodeStageIF pdStageIF( clk, rst );
    DecodeStageIF idStageIF( clk, rst );
    RenameStageIF rnStageIF( clk, rst, rstStart );
    //DispatchStageIF dsStageIF( clk, rst );
    ScheduleStageIF scStageIF( clk, rst );

    IntegerIssueStageIF intIsStageIF( clk, rst );
    IntegerRegisterReadStageIF intRrStageIF( clk, rst );
    IntegerExecutionStageIF intExStageIF( clk, rst );
    //IntegerRegisterWriteStageIF intRwStageIF( clk, rst );

    ComplexIntegerIssueStageIF complexIsStageIF( clk, rst );
    ComplexIntegerRegisterReadStageIF complexRrStageIF( clk, rst );
    ComplexIntegerExecutionStageIF complexExStageIF( clk, rst );

    MemoryIssueStageIF memIsStageIF( clk, rst );
    MemoryRegisterReadStageIF memRrStageIF( clk, rst );
    MemoryExecutionStageIF memExStageIF( clk, rst );
    MemoryTagAccessStageIF mtStageIF( clk, rst );
    MemoryAccessStageIF maStageIF( clk, rst );
    //MemoryRegisterWriteStageIF memRwStageIF( clk, rst );

    CommitStageIF cmStageIF( clk, rst );

    // Other interfaces.
    CacheSystemIF cacheSystemIF( clk, rst );
    RenameLogicIF renameLogicIF( clk, rst, rstStart );
    ActiveListIF activeListIF( clk, rst );
    SchedulerIF schedulerIF( clk, rst, rstStart );
    WakeupSelectIF wakeupSelectIF( clk, rst, rstStart );
    RegisterFileIF registerFileIF( clk, rst, rstStart );
    BypassNetworkIF bypassNetworkIF( clk, rst, rstStart );
    LoadStoreUnitIF loadStoreUnitIF( clk, rst, rstStart );
    RecoveryManagerIF recoveryManagerIF( clk, rst );
    CSR_UnitIF csrUnitIF(clk, rst, rstStart);
    IO_UnitIF ioUnitIF(clk, rst, rstStart, serialWE, serialWriteData);
    assign tohost = ioUnitIF.tohost;
    assign ioUnitIF.serialIn = serialIn;
    assign serialInAck = ioUnitIF.serialInAck;
    MulDivUnitIF mulDivUnitIF(clk, rst);

    //
    // --- Modules
    //
    Controller controller( ctrlIF, debugIF );
    MemoryAccessController memoryAccessController(
        .port( cacheSystemIF.MemoryAccessController ),
        .memAccessAddr( memAccessAddr ),
        .memAccessWriteData( memAccessWriteData ),
        .memAccessRE( memAccessRE ),
        .memAccessWE( memAccessWE ),
        .memAccessReadBusy( memAccessReadBusy ),
        .memAccessWriteBusy( memAccessWriteBusy ),
        .nextMemReadSerial( nextMemReadSerial ),
        .nextMemWriteSerial( nextMemWriteSerial ),
        .memReadDataReady( memReadDataReady ),
        .memReadData( memReadData ),
        .memReadSerial( memReadSerial ),
        .memAccessResponse( memAccessResponse )
    );


    NextPCStage npStage( npStageIF, ifStageIF, recoveryManagerIF, ctrlIF, debugIF );
        PC pc( npStageIF );
        BTB btb( npStageIF, ifStageIF );
        BranchPredictor brPred( npStageIF, ifStageIF, ctrlIF );
    FetchStage ifStage( ifStageIF, npStageIF, ctrlIF, debugIF );
        ICache iCache( npStageIF, ifStageIF, cacheSystemIF );
    
    PreDecodeStage pdStage( pdStageIF, ifStageIF, ctrlIF, debugIF );
    DecodeStage idStage( idStageIF, pdStageIF, ctrlIF, debugIF );

    RenameStage rnStage( rnStageIF, idStageIF, renameLogicIF, activeListIF, schedulerIF, loadStoreUnitIF, recoveryManagerIF, ctrlIF, debugIF );
        RenameLogic renameLogic( renameLogicIF, activeListIF, recoveryManagerIF );
        RenameLogicCommitter renameLogicCommitter( renameLogicIF, activeListIF, recoveryManagerIF );
        ActiveList activeList( activeListIF, recoveryManagerIF, ctrlIF, debugIF );
        RMT rmt_wat( renameLogicIF );
        RetirementRMT retirementRMT( renameLogicIF );
        MemoryDependencyPredictor memoryDependencyPredictor( rnStageIF, loadStoreUnitIF );
    
    DispatchStage dsStage( /*dsStageIF,*/ rnStageIF, schedulerIF, ctrlIF, debugIF );

    ScheduleStage scStage( scStageIF, schedulerIF, recoveryManagerIF, ctrlIF );
        IssueQueue issueQueue( schedulerIF, wakeupSelectIF, recoveryManagerIF, debugIF );
        ReplayQueue replayQueue( schedulerIF, loadStoreUnitIF, mulDivUnitIF ,recoveryManagerIF, ctrlIF );
        Scheduler scheduler( schedulerIF, wakeupSelectIF, recoveryManagerIF, mulDivUnitIF, debugIF );
        WakeupPipelineRegister wakeupPipelineRegister( wakeupSelectIF, recoveryManagerIF );
        DestinationRAM destinationRAM( wakeupSelectIF );
        WakeupLogic wakeupLogic( wakeupSelectIF );
        SelectLogic selectLogic( wakeupSelectIF, recoveryManagerIF );

    IntegerIssueStage intIsStage( intIsStageIF, scStageIF, schedulerIF, recoveryManagerIF, ctrlIF, debugIF );
    IntegerRegisterReadStage intRrStage( intRrStageIF, intIsStageIF, registerFileIF, bypassNetworkIF, recoveryManagerIF, ctrlIF, debugIF );
    IntegerExecutionStage intExStage( intExStageIF, intRrStageIF, bypassNetworkIF, recoveryManagerIF, ctrlIF, debugIF );
    IntegerRegisterWriteStage intRwStage( /*intRwStageIF,*/ intExStageIF, schedulerIF, npStageIF, registerFileIF, activeListIF, recoveryManagerIF, ctrlIF, debugIF );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    ComplexIntegerIssueStage complexIsStage( complexIsStageIF, scStageIF, schedulerIF, recoveryManagerIF, mulDivUnitIF, ctrlIF, debugIF );
    ComplexIntegerRegisterReadStage complexRrStage( complexRrStageIF, complexIsStageIF, registerFileIF, bypassNetworkIF, recoveryManagerIF, ctrlIF, debugIF );
    ComplexIntegerExecutionStage complexExStage( complexExStageIF, complexRrStageIF, mulDivUnitIF, schedulerIF, bypassNetworkIF, recoveryManagerIF, ctrlIF, debugIF );
    ComplexIntegerRegisterWriteStage complexRwStage( complexExStageIF, registerFileIF, activeListIF, recoveryManagerIF, ctrlIF, debugIF );
`endif
        MulDivUnit mulDivUnit(mulDivUnitIF);

    MemoryIssueStage memIsStage( memIsStageIF, scStageIF, schedulerIF, recoveryManagerIF, mulDivUnitIF, ctrlIF, debugIF );
    MemoryRegisterReadStage memRrStage( memRrStageIF, memIsStageIF,loadStoreUnitIF, mulDivUnitIF, registerFileIF, bypassNetworkIF, recoveryManagerIF, ctrlIF, debugIF );
    MemoryExecutionStage memExStage( memExStageIF, memRrStageIF, loadStoreUnitIF, mulDivUnitIF, bypassNetworkIF, recoveryManagerIF, ctrlIF, csrUnitIF, debugIF );
    MemoryTagAccessStage mtStage( mtStageIF, memExStageIF, schedulerIF, loadStoreUnitIF, mulDivUnitIF, recoveryManagerIF, ctrlIF, debugIF, hwCounterIF );
    MemoryAccessStage maStage( maStageIF, mtStageIF, loadStoreUnitIF, mulDivUnitIF, bypassNetworkIF, ioUnitIF, recoveryManagerIF, ctrlIF, debugIF );
        LoadStoreUnit loadStoreUnit( loadStoreUnitIF, ctrlIF, hwCounterIF );
        LoadQueue loadQueue( loadStoreUnitIF, recoveryManagerIF );
        StoreQueue storeQueue( loadStoreUnitIF, recoveryManagerIF );
        StoreCommitter storeCommitter(loadStoreUnitIF, recoveryManagerIF, ioUnitIF, debugIF);
        DCache dCache( loadStoreUnitIF, cacheSystemIF, ctrlIF );
    MemoryRegisterWriteStage memRwStage( /*memRwStageIF,*/ maStageIF, registerFileIF, activeListIF, recoveryManagerIF, ctrlIF, debugIF );

    RegisterFile registerFile( registerFileIF );
        BypassController bypassController( bypassNetworkIF, ctrlIF );
        BypassNetwork  bypassNetwork( bypassNetworkIF, ctrlIF );
`ifdef RSD_ENABLE_VECTOR_PATH
        VectorBypassNetwork  vectorBypassNetwork( bypassNetworkIF, ctrlIF );
`endif
    // A commitment stage generates a flush signal and this is send to scheduler.
    CommitStage cmStage( cmStageIF, renameLogicIF, activeListIF, loadStoreUnitIF, recoveryManagerIF, csrUnitIF, debugIF, hwCounterIF );
        RecoveryManager recoveryManager( recoveryManagerIF, activeListIF, csrUnitIF, ctrlIF );

    CSR_Unit csrUnit(csrUnitIF);
    InterruptController interruptCtrl(csrUnitIF, ctrlIF, npStageIF, recoveryManagerIF);
    IO_Unit ioUnit(ioUnitIF, csrUnitIF);

endmodule : Core
// ---- Pipeline/FetchStage/NextPCStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for updating PC
//

import BasicTypes::*;
import PipelineTypes::*;
import MemoryMapTypes::*;
import CacheSystemTypes::*;
import FetchUnitTypes::*;

//`define RSD_STOP_FETCH_ON_PRED_MISS

// Detect the cache line boundary in sequential access
function automatic logic StepOverCacheLine (PC_Path pc1, PC_Path pc2);
    return pc1[ICACHE_LINE_BYTE_NUM_BIT_WIDTH] != pc2[ICACHE_LINE_BYTE_NUM_BIT_WIDTH];
endfunction

module NextPCStage(
    NextPCStageIF.ThisStage port,
    FetchStageIF.NextPCStage next,
    RecoveryManagerIF.NextPCStage recovery,
    ControllerIF.NextPCStage ctrl,
    DebugIF.NextPCStage debug
);

`ifdef RSD_STOP_FETCH_ON_PRED_MISS
    typedef enum logic {
        PHASE_FETCH,
        PHASE_WAIT
    } Phase;

    parameter PHASE_DELAY = 2;
    Phase phase[PHASE_DELAY];
    Phase nextPhase;
    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < PHASE_DELAY; i++) begin
                phase[i] <= PHASE_FETCH;
            end
        end
        else if (recovery.toRecoveryPhase || recovery.toCommitPhase) begin
            for (int i = 0; i < PHASE_DELAY; i++) begin
                phase[i] <= PHASE_FETCH;
            end
        end
        else begin
            for (int i = 0; i < PHASE_DELAY - 1; i++) begin
                phase[i+1] <= phase[i];
            end
            phase[0] <= nextPhase;
        end
    end

    always_comb begin
        if (recovery.toRecoveryPhase) begin
            nextPhase = PHASE_FETCH;
        end
        else begin

            nextPhase = phase[0];
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                if (port.brResult[i].valid && port.brResult[i].mispred) begin
                    nextPhase = PHASE_WAIT;
                end
            end
        end
    end
`endif

    // デバッグ用SID
    // 内部事情により，1 からはじめる
`ifndef RSD_DISABLE_DEBUG_REGISTER
    OpSerial curSID, nextSID;
    FlipFlop#( .FF_WIDTH(OP_SERIAL_WIDTH), .RESET_VALUE(1) )
        sidFF(
            .out( curSID ),
            .in ( nextSID ),
            .clk( port.clk ),
            .rst( port.rst )
        );
`endif

    PC_Path predNextPC;
    FetchStageRegPath nextStage[ FETCH_WIDTH ];

    // Pipeline Controll
    logic stall, clear;
    logic regStall, beginStall;
    logic writePC_FromOuter;
    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            regStall <= FALSE;
        end
        else begin
            regStall <= stall;
        end
    end

    always_comb begin
        // Control
        stall = ctrl.npStage.stall;
        clear = ctrl.npStage.clear;
`ifdef RSD_STOP_FETCH_ON_PRED_MISS
        ctrl.npStageSendBubbleLower =
            (!recovery.toRecoveryPhase && phase[PHASE_DELAY - 1] == PHASE_WAIT);
`else
        ctrl.npStageSendBubbleLower = FALSE;
`endif

        beginStall = !regStall && stall;

        // Whether PC is written from outside
        if (recovery.toRecoveryPhase || recovery.recoverFromRename
                                     || port.interruptAddrWE) begin
            writePC_FromOuter = TRUE;
        end
        else begin
            writePC_FromOuter = FALSE;
        end
        
        // Update PC if not stalled.
        // NOTE: Update even during stall in the next cases:
        //   1) if PC is written from outside
        //   2) if it is beginning of stall
        //   (see the comment of regBrPred in FetchStage.sv)
        port.pcWE = 
            (writePC_FromOuter || !stall || beginStall) && !port.rst;
    end


    //
    // Branch Prediction
    //
    always_comb begin

        // Decide the address to input to the branch predictor
        if (recovery.toRecoveryPhase) begin
            // Branch misprediction or an exception etc. is detected
            // Refetch instruction specified by Rw, Cm stage
            predNextPC = recovery.recoveredPC_FromRwCommit;
        end
        else if (recovery.recoverFromRename) begin
            // Detect branch misprediction in decode stage
            predNextPC = recovery.recoveredPC_FromRename;
        end
        else begin
            // Use current PC
            predNextPC = port.pcOut;

            for (int i = 0; i < FETCH_WIDTH; i++) begin
                // Process of branch prediction:
                // If BTB is hit, the instruction is predicted to be a branch. 
                // In addition, if the branch is predicted as Taken, 
                // the address read from BTB is used as next PC.
                if (!regStall && next.fetchStageIsValid[i] && 
                        next.btbHit[i] && next.brPredTaken[i]) begin
                    // Use PC from BTB
                    predNextPC = next.btbOut[i];
                    break;
                end
            end
        end
        // To Branch predictor
        port.predNextPC = predNextPC;
    end


    //
    //  Updating PC
    //
    always_comb begin

        // --- PC
        if (port.interruptAddrWE) begin
            // When an interrupt occurs, use interrupt address.
            // NOTE: This input can be a critical path.
            // Hence, interrupt address is input to PC first rather than 
            // input to the branch predictor directly.
            port.pcIn = port.interruptAddrIn;
        end
        else if (beginStall) begin
            // Update PC based on the branch prediction result accessed
            // immediately before the stall if it is beginning of stall.
            // (see the comment of regBrPred in FetchStage.sv)
            port.pcIn = predNextPC;
        end
        else begin
            // Increment PC
            port.pcIn = predNextPC + FETCH_WIDTH*INSN_BYTE_WIDTH;
            for (int i = 1; i < FETCH_WIDTH; i++) begin
                if (StepOverCacheLine(predNextPC, 
                                     predNextPC+i*INSN_BYTE_WIDTH)) begin
                    // When PC stepped over the border of cache line, stop there
                    port.pcIn = predNextPC+i*INSN_BYTE_WIDTH;
                    break;
                end
            end
        end

        for (int i = 0; i < FETCH_WIDTH; i++) begin
`ifndef RSD_DISABLE_DEBUG_REGISTER
            // Generate serial id for dumping
            nextStage[i].sid = curSID + i;
`endif
            nextStage[i].pc = predNextPC + i * INSN_BYTE_WIDTH;
            if (port.interruptAddrWE || clear ||
                StepOverCacheLine(predNextPC, nextStage[i].pc)) begin
                nextStage[i].valid = FALSE;
            end
            else begin
                nextStage[i].valid = TRUE;
            end
        end

        port.nextStage = nextStage;
    end


    //
    // I-cache Access
    //
    AddrPath fetchAddr;
    always_comb begin
        // Decide input address of I-cache
        if (next.fetchStageIsValid[0] && stall) begin
            // Use the PC of the IF stage
            fetchAddr = ToAddrFromPC(next.fetchStagePC[0]);
        end
        else begin
            // Use the PC of this stage
            fetchAddr = ToAddrFromPC(predNextPC);
        end
        
        // To I-cache
        port.icNextReadAddrIn = ToPhyAddrFromLogical(fetchAddr);
    end


`ifndef RSD_DISABLE_DEBUG_REGISTER
    logic [FETCH_WIDTH : 0] numValidInsns;
    always_comb begin
        numValidInsns = 0; // Count valid instructions in this stage
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            if (!nextStage[i].valid) begin
                break;
            end
            else begin
                numValidInsns++;
            end
        end

        // Update serial ID.
        nextSID = ( stall || clear) ? 
            curSID : (curSID + numValidInsns);

        // --- Debug Register
        for ( int i = 0; i < FETCH_WIDTH; i++ ) begin
            debug.npReg[i].valid = stall ? FALSE : nextStage[i].valid;
            debug.npReg[i].sid = nextStage[i].sid;
        end
    end
`endif

endmodule : NextPCStage
// ---- Pipeline/FetchStage/NextPCStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- NextPCStageIF
//

import BasicTypes::*;
import PipelineTypes::*;
import FetchUnitTypes::*;
import MemoryMapTypes::*;

interface NextPCStageIF( input logic clk, rst, rstStart );
    
    // PC
    logic    pcWE;
    PC_Path  pcOut;
    PC_Path  pcIn;

    PC_Path  predNextPC;

    // Executed branch results for updating a branch predictor.
    // This signal is written back from a write back stage.
    BranchResult brResult[ INT_ISSUE_WIDTH ];

    // Interrupt
    PC_Path interruptAddrIn;
    logic interruptAddrWE;

    // I-cache
    PhyAddrPath   icNextReadAddrIn; // Value of icReadAddrIn in next cycle.

    // Pipeline register
    FetchStageRegPath nextStage[ FETCH_WIDTH ];

    modport PC(
    input
        clk, rst, pcWE, pcIn,
    output
        pcOut
    );

    modport ThisStage(
    input
        clk,
        rst,
        pcOut,
        brResult,
        interruptAddrIn,
        interruptAddrWE,
    output
        pcWE,
        pcIn,
        predNextPC,
        icNextReadAddrIn,
        nextStage
    );

    modport NextStage(
    input
        predNextPC,
        nextStage
    );

    modport IntegerRegisterWriteStage(
    output
        brResult
    );

    modport BTB(
    input
        clk,
        rst,
        rstStart,
        predNextPC,
        brResult
    );

    modport BranchPredictor(
    input
        clk,
        rst,
        rstStart,
        predNextPC,
        brResult
    );

    modport ICache(
    input
        clk,
        rst,
        rstStart,
        icNextReadAddrIn
    );

    modport InterruptController(
    input
        pcOut,
    output
        interruptAddrIn,
        interruptAddrWE
    );


endinterface : NextPCStageIF
// ---- Pipeline/FetchStage/FetchStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for fetching instructions.
//

import BasicTypes::*;
import PipelineTypes::*;
import FetchUnitTypes::*;
import MemoryMapTypes::*;

module FetchStage(
    FetchStageIF.ThisStage port,
    NextPCStageIF.NextStage prev,
    ControllerIF.FetchStage ctrl,
    DebugIF.FetchStage debug
);

    // Pipeline Controll
    logic stall, clear;
    logic empty;
    logic regStall, beginStall;
    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            regStall <= FALSE;
        end
        else begin
            regStall <= stall;
        end
    end

    
    // --- Pipeline registers
    FetchStageRegPath pipeReg[FETCH_WIDTH];
    PreDecodeStageRegPath nextStage[ FETCH_WIDTH ];

    always_comb begin
        // Control
        stall = ctrl.ifStage.stall;
        clear = ctrl.ifStage.clear;

        // Stall upper stages if cannot fetch valid instruction 
        ctrl.ifStageSendBubbleLower = 
            pipeReg[0].valid && !port.icReadHit[0];

        // Check whether instructions exist in this stage
        empty = TRUE;
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            if (pipeReg[i].valid)
                empty = FALSE;
        end
        ctrl.ifStageEmpty = empty;

        // Detect beginning of stall
        beginStall = !regStall && stall;
    end

    // Whether instruction is invalidated by branch prediction
    logic isFlushed[FETCH_WIDTH];

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < FETCH_WIDTH; i++) begin
                pipeReg[i] <= '0;
            end
        end
        else if (!stall) begin
            pipeReg <= prev.nextStage;
        end
        else begin
            for (int i = 0; i < FETCH_WIDTH; i++) begin
                if (isFlushed[i]) begin                    
                    // When a branch is predicted as Taken during stall,
                    // clear the valid bits of the subsequent lanes
                    pipeReg[i].valid <= FALSE;
                end
            end
        end
    end


    BranchPred brPred[FETCH_WIDTH];

    // Record the result of branch prediction.
    //
    // When this stage is stalled, the next instruction's PC is input to 
    // the branch predictor and the output of the branch predictor will change 
    // in the next cycle.
    // Hence, when stalled, the process of branch prediction must be performed at the beginning cycle of stall.
    // And more, it is necessary to keep the branch prediction result of the stalled instruction.
    BranchPred regBrPred[FETCH_WIDTH];
    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < FETCH_WIDTH; i++) begin
                regBrPred[i] <= '0;
            end
        end
        else if (beginStall) begin
            regBrPred <= brPred;
        end
    end


    //
    // Branch Prediction
    //
    always_comb begin

        // The result of branch prediction
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            brPred[i].predAddr = port.brPredTaken[i] ? 
                port.btbOut[i] : pipeReg[i].pc + INSN_BYTE_WIDTH;
            brPred[i].predTaken = port.brPredTaken[i];
            brPred[i].globalHistory = port.brGlobalHistory[i];
            brPred[i].phtPrevValue = port.phtPrevValue[i];
        end

        // Check whether instructions are flushed by branch prediction
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            isFlushed[i] = FALSE;
            if (!regStall && pipeReg[i].valid && brPred[i].predTaken) begin
                for (int j = i + 1; j < FETCH_WIDTH; j++) begin
                    isFlushed[j] = pipeReg[j].valid;
                end

                break;
            end
        end

        // Update the branch history
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            port.updateBrHistory[i] = !regStall && pipeReg[i].valid;
        end
    end


    //
    // I-cache Access
    //
    AddrPath fetchAddrOut;
    always_comb begin
        // --- I-cache read
        port.icRE = pipeReg[0].valid; // read enable: whether check hit/miss
        fetchAddrOut = ToAddrFromPC(pipeReg[0].pc);
        // Address for comparing tag
        port.icReadAddrIn = ToPhyAddrFromLogical(fetchAddrOut);


        // Send information about this stage to the previous stage for
        // deciding the next fetch address
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            port.fetchStageIsValid[i] = pipeReg[i].valid;
            port.fetchStagePC[i] = pipeReg[i].pc;
        end
    end


    //
    // --- Pipeline registers
    //
    always_comb begin
        for ( int i = 0; i < FETCH_WIDTH; i++ ) begin
            if (stall || clear || port.rst || isFlushed[i]) begin
                nextStage[i].valid = FALSE;
            end
            else begin
                nextStage[i].valid = pipeReg[i].valid;
            end

`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].sid = pipeReg[i].sid;
`endif
            nextStage[i].pc = pipeReg[i].pc;
            nextStage[i].brPred = regStall ? regBrPred[i] : brPred[i];
            nextStage[i].insn = pipeReg[i].valid ? 
                port.icReadDataOut[i] : '0;
        end

        port.nextStage = nextStage;

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // --- Debug Register
        for ( int i = 0; i < FETCH_WIDTH; i++ ) begin
            debug.ifReg[i].valid = pipeReg[i].valid;
            debug.ifReg[i].sid = pipeReg[i].sid;
            debug.ifReg[i].flush = isFlushed[i];
        end
`endif
    end

endmodule : FetchStage
// ---- Pipeline/FetchStage/FetchStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- FetchStageIF
//

import BasicTypes::*;
import PipelineTypes::*;
import FetchUnitTypes::*;
import MemoryMapTypes::*;

interface FetchStageIF( input logic clk, rst, rstStart );

    // This Stage
    logic  fetchStageIsValid[FETCH_WIDTH];
    PC_Path fetchStagePC[FETCH_WIDTH];

    // BTB
    PC_Path btbOut[FETCH_WIDTH];
    logic btbHit[FETCH_WIDTH];
    logic readIsCondBr[FETCH_WIDTH];
    
    // BranchPredictor
    logic updateBrHistory[FETCH_WIDTH];
    logic brPredTaken[FETCH_WIDTH];
    BranchGlobalHistoryPath brGlobalHistory[FETCH_WIDTH];
    PHT_EntryPath phtPrevValue[FETCH_WIDTH];

    // I-Cache
    logic     icReadHit [ FETCH_WIDTH ];
    logic     icRE;
    InsnPath  icReadDataOut[ FETCH_WIDTH ];
    PhyAddrPath   icReadAddrIn; // Head addr to fetch

    // Pipeline register
    PreDecodeStageRegPath nextStage[ FETCH_WIDTH ];

    modport ThisStage(
    input
        clk,
        rst,
        icReadHit,
        icReadDataOut,
        btbOut,
        brPredTaken,
        brGlobalHistory,
        phtPrevValue,
    output
        fetchStageIsValid,
        fetchStagePC,
        updateBrHistory,
        nextStage,
        icRE,
        icReadAddrIn
    );

    modport NextPCStage(
    input
        fetchStageIsValid,
        fetchStagePC,
        btbOut,
        btbHit,
        brPredTaken
    );

    modport NextStage(
    input
        nextStage
    );

    modport ICache(
    input
        icRE, // Read Enable
        icReadAddrIn,
    output
        icReadHit,
        icReadDataOut
    );

    modport BTB(
    output
        btbOut,
        btbHit,
        readIsCondBr
    );

    modport BranchPredictor(
    input
        updateBrHistory,
        btbOut,
        btbHit,
        readIsCondBr,
    output
        brPredTaken,
        brGlobalHistory,
        phtPrevValue
    );

endinterface : FetchStageIF
// ---- Pipeline/FetchStage/PC.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// PC
// PC has INSN_RESET_VECTOR and cannot use AddrReg.
//

import BasicTypes::*;
import MemoryMapTypes::*;

module PC( NextPCStageIF.PC port );
    
    FlipFlopWE#( PC_WIDTH, INSN_RESET_VECTOR ) 
        body( 
            .out( port.pcOut ), 
            .in ( port.pcIn ),
            .we ( port.pcWE ), 
            .clk( port.clk ),
            .rst( port.rst )
        );
        
endmodule : PC

// ---- Pipeline/PreDecodeStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// DecodeStage
//

import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import DebugTypes::*;
import FetchUnitTypes::*;
import MemoryMapTypes::*;


module PreDecodeStage(
    PreDecodeStageIF.ThisStage port, 
    FetchStageIF.NextStage prev,
    ControllerIF.PreDecodeStage ctrl,
    DebugIF.PreDecodeStage debug
);
    // --- Pipeline registers
    PreDecodeStageRegPath pipeReg[DECODE_WIDTH];
    
`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    always_ff@ (posedge port.clk)
    begin
        if (port.rst) begin
            for (int i = 0; i < DECODE_WIDTH; i++) begin
                pipeReg[i].valid <= FALSE;
            end
        end
        else if (!ctrl.pdStage.stall) begin             // write data
            pipeReg <= prev.nextStage;
        end
    end

    AddrPath pc[DECODE_WIDTH];
    logic illegalPC[DECODE_WIDTH];
    always_comb begin
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            pc[i] = ToAddrFromPC(pipeReg[i].pc);
            illegalPC[i] =
                GetMemoryMapType(pc[i]) == MMT_ILLEGAL ? TRUE : FALSE;
        end
    end

    // Micro op decoder
    OpInfo [DECODE_WIDTH-1:0][MICRO_OP_MAX_NUM-1:0] microOps;  // Decoded micro ops
    InsnInfo [DECODE_WIDTH-1:0] insnInfo;   // Whether a decoded instruction is branch or not.
    for (genvar i = 0; i < DECODE_WIDTH; i++) begin
        Decoder decoder(
            .insn(pipeReg[i].insn),
            .insnInfo(insnInfo[i]),
            .microOps(microOps[i]),
            .illegalPC(illegalPC[i])
        );
    end

    // Pipeline controll
    logic stall, clear;
    logic empty;
    DecodeStageRegPath nextStage[DECODE_WIDTH];
    
    
    always_comb begin
        stall = ctrl.pdStage.stall;
        clear = ctrl.pdStage.clear;

        empty = TRUE;
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            nextStage[i].valid = 
                (stall || clear || port.rst) ? FALSE : pipeReg[i].valid;
            
            // Decoded micr-op and context.
            nextStage[i].insn = pipeReg[i].insn;
            nextStage[i].pc = pipeReg[i].pc;
            nextStage[i].brPred = pipeReg[i].brPred;

            nextStage[i].insnInfo = insnInfo[i];
            nextStage[i].microOps = microOps[i];

            if (pipeReg[i].valid)
                empty = FALSE;

`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].sid = pipeReg[i].sid;
`endif
        end
        
        port.nextStage = nextStage;
        ctrl.pdStageEmpty = empty;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            // 先頭が次に送られたら，デコード元は消える．
            debug.pdReg[i].valid = pipeReg[i].valid;
            debug.pdReg[i].sid = pipeReg[i].sid;
`ifdef RSD_FUNCTIONAL_SIMULATION
            debug.pdReg[i].aluCode = microOps[i][1].operand.intOp.aluCode;
            debug.pdReg[i].opType = microOps[i][1].mopSubType.intType;
`endif
        end
`endif

    end
endmodule : PreDecodeStage


// ---- Pipeline/PreDecodeStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- PreDecodeStageIF
//

import BasicTypes::*;
import PipelineTypes::*;
import MicroOpTypes::*;

interface PreDecodeStageIF(input logic clk, rst);

    // Pipeline registers 
    DecodeStageRegPath nextStage[DECODE_WIDTH];
    
    modport ThisStage(
    input 
        clk, 
        rst,
    output 
        nextStage
    );
    
    modport NextStage(
    input
        nextStage
    );
    
endinterface : PreDecodeStageIF



// ---- Pipeline/DecodeStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// DecodeStage
//

import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import DebugTypes::*;
import FetchUnitTypes::*;

//
// Pick micro ops for feeding to a next stage from all decoded micro ops.
//
module MicroOpPicker(
input
    AllDecodedMicroOpPath req,
    AllDecodedMicroOpPath serialize,
output
    logic picked[DECODE_WIDTH],
    AllDecodedMicroOpIndex pickedIndex[DECODE_WIDTH],
    AllDecodedMicroOpPath next
);
    logic clear;
    logic sent;
    AllDecodedMicroOpPath cur;

    always_comb begin
        clear = FALSE;
        sent = FALSE;
        cur = req;

        for (int i = 0; i < DECODE_WIDTH; i++) begin
            picked[i] = FALSE;
            pickedIndex[i] = 0;
            for (int mn = 0; mn < ALL_DECODED_MICRO_OP_WIDTH; mn++) begin
                if (cur[mn] && !clear) begin
                    // シリアライズが有効な場合，1 mop のみ次のステージに送る
                    // If this op is serialized one, only a single op is picked.
                    if (serialize[mn]) begin
                        clear = TRUE;
                    end
                    // 既に通常命令を送っている場合，このシリアライズ命令はピックしない
                    if (clear && sent) begin
                        break;
                    end

                    sent = TRUE;
                    picked[i] = TRUE;
                    pickedIndex[i] = mn;
                    cur[mn] = FALSE;
                    break;
                end
            end
            
        end
        
        next = cur;
    end
endmodule



module DecodeStage(
    DecodeStageIF.ThisStage port, 
    PreDecodeStageIF.NextStage prev,
    ControllerIF.DecodeStage ctrl,
    DebugIF.DecodeStage debug
);
    // --- Pipeline registers
    DecodeStageRegPath pipeReg[DECODE_WIDTH];
    
`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    always_ff@ (posedge port.clk)
    begin
        if (port.rst) begin
            for (int i = 0; i < DECODE_WIDTH; i++) begin
                pipeReg[i].valid <= FALSE;
            end
        end
        else if (!ctrl.idStage.stall) begin             // write data
            pipeReg <= prev.nextStage;
        end
    end

    // Pipeline controll
    logic stall, clear;
    logic empty;
    RenameStageRegPath nextStage[DECODE_WIDTH];
    
    // Micro op decoder
    OpInfo [ALL_DECODED_MICRO_OP_WIDTH-1:0] microOps;  // Decoded micro ops
    InsnInfo [DECODE_WIDTH-1:0] insnInfo;   // Whether a decoded instruction is branch or not.
    
    always_comb begin
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            for (int j = 0; j < MICRO_OP_MAX_NUM; j++) begin
                microOps[i*MICRO_OP_MAX_NUM + j] = pipeReg[i].microOps[j];
            end
            insnInfo[i] = pipeReg[i].insnInfo;
        end

        empty = TRUE;
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            if (pipeReg[i].valid)
                empty = FALSE;
        end
        ctrl.idStageEmpty = empty;
    end
    
    
    // Control
    logic initiate;
    logic complete;
    
    // Early branch misprediction detection.
    RISCV_ISF_Common [DECODE_WIDTH-1:0] isfIn;
    logic flush;
    logic insnValidIn[DECODE_WIDTH];
    logic insnValidOut[DECODE_WIDTH];
    logic insnFlush[DECODE_WIDTH];
    BranchPred brPredOut[DECODE_WIDTH];
    BranchPred [DECODE_WIDTH-1:0] brPredIn;
    PC_Path pcIn[DECODE_WIDTH];
    PC_Path recoveredPC;

    DecodedBranchResolver decodeStageBranchResolver(
        .clk(port.clk),
        .rst(port.rst),
        .stall(ctrl.idStage.stall && !ctrl.stallByDecodeStage),
        .decodeComplete(complete),
        .insnValidIn(insnValidIn),
        .isf(isfIn),
        .brPredIn(brPredIn),
        .pc(pcIn),
        .insnInfo(insnInfo),
        .insnValidOut(insnValidOut),
        .insnFlushed(insnFlush),
        .flush(flush),
        .brPredOut(brPredOut),
        .recoveredPC(recoveredPC)
    );
    
    always_comb begin
        
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            insnValidIn[i] = pipeReg[i].valid;
            isfIn[i] = pipeReg[i].insn;
            pcIn[i] = pipeReg[i].pc;
            brPredIn[i] = pipeReg[i].brPred;
        end
        
        port.nextFlush = complete && flush && !clear;
        port.nextRecoveredPC = recoveredPC;
    end
    
    AllDecodedMicroOpPath remainingValidMOps;
    AllDecodedMicroOpPath nextValidMOps;

    AllDecodedMicroOpPath curValidMOps;
    AllDecodedMicroOpPath pickedValidMOps;
    AllDecodedMicroOpPath serializedMOps;
    
    AllDecodedMicroOpIndex mopPickedIndex[DECODE_WIDTH];
    logic mopPicked[DECODE_WIDTH];
    DecodeLaneIndexPath orgPickedInsnLane;


    always_ff@( posedge port.clk ) begin
        if (port.rst || ctrl.idStage.clear) begin
            remainingValidMOps <= 0;
            initiate <= TRUE;
        end
        else begin
            if (!(ctrl.idStage.stall && !ctrl.stallByDecodeStage)) begin
                initiate <= complete;
                remainingValidMOps <= nextValidMOps;
            end
        end
    end
    
    // From the index of decoded micro ops lanes to that of instructions.
    function automatic DecodeLaneIndexPath ToInsnLane(AllDecodedMicroOpIndex mopLane);
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            for (int j = 0; j < MICRO_OP_MAX_NUM; j++) begin
                if(mopLane == i*MICRO_OP_MAX_NUM + j)
                    return i;
            end
        end
        return 0;
    endfunction
    

    always_comb begin
        
        stall = ctrl.idStage.stall;
        clear = ctrl.idStage.clear;

        //
        // Setup current valid bits(=undecoded bits).
        //
        if (initiate) begin
            for (int i = 0; i < ALL_DECODED_MICRO_OP_WIDTH; i++) begin
                curValidMOps[i] = microOps[i].valid;
            end
        end
        else begin
            curValidMOps = remainingValidMOps;
        end

        // Set a "serialized" flag for each micro op.
        for (int i = 0; i < ALL_DECODED_MICRO_OP_WIDTH; i++) begin
            serializedMOps[i] = microOps[i].serialized;
        end
    end

    MicroOpPicker picker(curValidMOps, serializedMOps, mopPicked, mopPickedIndex, pickedValidMOps);

    always_comb begin
        // --- Picker picks micro ops

        // Set picked results.
        nextValidMOps = pickedValidMOps;
        
        complete = TRUE;
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            for (int j = 0; j < MICRO_OP_MAX_NUM; j++) begin
                if(nextValidMOps[i*MICRO_OP_MAX_NUM+j] && insnValidIn[i]) begin
                    complete = FALSE;
                end
            end
            // "complete" does not care "insnValidOut" because "insnValidOut" is in
            // a critical path.
            if(!insnValidOut[i]) begin
                for (int j = 0; j < MICRO_OP_MAX_NUM; j++) begin
                    nextValidMOps[i*MICRO_OP_MAX_NUM + j] = FALSE;
                end
            end
        end

        // Stall decision
        ctrl.idStageStallUpper = !complete;
        
        
        // Pick decoded micro ops.
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            orgPickedInsnLane = ToInsnLane(mopPickedIndex[i]);
        
            nextStage[i].opInfo = microOps[ mopPickedIndex[i] ];

            nextStage[i].valid = insnValidOut[orgPickedInsnLane] && mopPicked[i] && !clear;
            nextStage[i].pc = pipeReg[orgPickedInsnLane].pc;
            nextStage[i].bPred = brPredOut[orgPickedInsnLane];  

`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId.sid = pipeReg[orgPickedInsnLane].sid;
            nextStage[i].opId.mid = nextStage[i].opInfo.mid;
`endif
        end
        
        
        port.nextStage = nextStage;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            // 先頭が次に送られたら，デコード元は消える．
            debug.idReg[i].valid = pipeReg[i].valid;
            debug.idReg[i].flush = insnFlush[i];
            for (int j = 0; j < MICRO_OP_MAX_NUM; j++) begin
                if(microOps[i*MICRO_OP_MAX_NUM + j].valid && microOps[i*MICRO_OP_MAX_NUM + j].mid == 0) begin
                    if(!curValidMOps[i*MICRO_OP_MAX_NUM + j]) begin
                        debug.idReg[i].valid = FALSE;
                    end
                    break;
                end
            end
            
            
            debug.idReg[i].opId.sid = pipeReg[i].sid;
            debug.idReg[i].opId.mid = 0;
            debug.idReg[i].pc = ToAddrFromPC(pipeReg[i].pc);
            debug.idReg[i].insn = pipeReg[i].insn;
            
            debug.idReg[i].undefined = FALSE;
            debug.idReg[i].unsupported = FALSE;
            for (int j = 0; j < MICRO_OP_MAX_NUM; j++) begin
                debug.idReg[i].undefined = debug.idReg[i].undefined | microOps[i*MICRO_OP_MAX_NUM + j].undefined;
                debug.idReg[i].unsupported = debug.idReg[i].unsupported | microOps[i*MICRO_OP_MAX_NUM + j].unsupported;
            end
        end
`endif

    end
endmodule : DecodeStage


// ---- Pipeline/DecodeStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- FetchPipe
//

import BasicTypes::*;
import PipelineTypes::*;
import MicroOpTypes::*;

interface DecodeStageIF( input logic clk, rst );

    // Pipeline registers 
    RenameStageRegPath nextStage[ DECODE_WIDTH ];
    logic nextFlush;
    AddrPath nextRecoveredPC;
    
    modport ThisStage(
    input 
        clk, 
        rst,
    output 
        nextStage,
        nextFlush,
        nextRecoveredPC
    );
    
    modport NextStage(
    input
        nextStage,
        nextFlush,
        nextRecoveredPC
    );
    
endinterface : DecodeStageIF



// ---- Pipeline/RenameStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for register read.
//


import BasicTypes::*;
import MemoryMapTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import LoadStoreUnitTypes::*;
import DebugTypes::*;

// シリアライズ命令が送られて来た場合，パイプラインを適切にストールさせる
// シリアライズ命令の前の命令がコミットして ROB が空になるまで待って，
// さらにシリアライズ命令自身がコミットされるまで上流をストールさせ続ける
//
// DecodeStage がシリアライズ命令のみを必ず単独で送ってくるようにしているため，
// 先頭しかみていない
module RenameStageSerializer(
input 
    logic clk, rst, stall, clear, activeListEmpty,
    OpInfo [RENAME_WIDTH-1:0] opInfo, // Unpacked array of structure corrupts in Modelsim.
    logic [RENAME_WIDTH-1:0] valid,
output 
    logic serialize
);
    generate
        for (genvar i = 1; i < RENAME_WIDTH; i++) begin : assertionBlock
            `RSD_ASSERT_CLK_FMT(
                clk, 
                !(opInfo[i].serialized && valid[i]), 
                ("Multiple serialized ops were sent to RenameStage. (%x, %x)", opInfo[i].serialized, valid[i])
            ); 
        end
    endgenerate

    // Serialize phase
    typedef enum logic[1:0]
    {
        PHASE_NORMAL = 0,               // フェッチ継続
        PHASE_WAIT_OWN = 2              // 自分自身のコミット待ち
    } Phase;
    Phase regPhase, nextPhase;

    always_ff@(posedge clk)   // synchronous rst
    begin
        if (rst) begin
            regPhase <= PHASE_NORMAL;
        end
        else if(!stall) begin             // write data
            regPhase <= nextPhase;
        end
    end

    always_comb begin
        // multiple serialized ops must not be sent to this stage.
        serialize = FALSE;
        nextPhase = PHASE_NORMAL;
        if (clear) begin
            nextPhase = PHASE_NORMAL; // force reset 
        end
        if (regPhase == PHASE_NORMAL) begin
            if (opInfo[0].serialized && valid[0]) begin
                // Wait for all previous ops to be committed
                if (!activeListEmpty) begin
                    serialize = TRUE;   
                    nextPhase = PHASE_NORMAL;
                end
                else begin
                    // deassert serialize" for dispatch  
                    nextPhase = PHASE_WAIT_OWN;
                end
            end
        end
        else begin
            // Wait for a serialized op to be committed
            if (!activeListEmpty) begin
                serialize = TRUE;
                nextPhase = PHASE_WAIT_OWN;
            end
            else begin
                nextPhase = PHASE_NORMAL;
            end
        end
    end

endmodule

module RenameStage(
    RenameStageIF.ThisStage port,
    DecodeStageIF.NextStage prev,
    RenameLogicIF.RenameStage renameLogic,
    ActiveListIF.RenameStage activeList,
    SchedulerIF.RenameStage scheduler,
    LoadStoreUnitIF.RenameStage loadStoreUnit,
    RecoveryManagerIF.RenameStage recovery,
    ControllerIF.RenameStage ctrl,
    DebugIF.RenameStage debug
);

    // --- Pipeline registers
    RenameStageRegPath pipeReg[RENAME_WIDTH];
    logic regFlush;
    PC_Path regRecoveredPC;


`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < RENAME_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
        regRecoveredPC = '0;
    end
`endif

    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < RENAME_WIDTH; i++) begin
                pipeReg[i].valid <= FALSE;
            end
            regFlush <= '0;
            regRecoveredPC <= '0;
        end
        else if(!ctrl.rnStage.stall) begin             // write data
            pipeReg <= prev.nextStage;
            regFlush <= prev.nextFlush;
            regRecoveredPC <= prev.nextRecoveredPC;
        end
    end

    always_comb begin
        recovery.recoverFromRename = regFlush;
        recovery.recoveredPC_FromRename = regRecoveredPC;
        ctrl.rnStageFlushUpper = regFlush;
    end


    // Pipeline controll
    logic stall, clear;
    logic empty;
    logic serialize;

    logic [ RENAME_WIDTH-1:0 ] valid;
    logic update [ RENAME_WIDTH ];
    OpInfo [RENAME_WIDTH-1:0] opInfo;
    ActiveListEntry alEntry [ RENAME_WIDTH ];
    DispatchStageRegPath nextStage [ RENAME_WIDTH ];

    logic isLoad[RENAME_WIDTH];
    logic isStore[RENAME_WIDTH];
    logic isBranch[RENAME_WIDTH];

    logic activeListEmpty;

    always_comb begin
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            valid[i] = pipeReg[i].valid;
            opInfo[i] = pipeReg[i].opInfo;
        end

        // The rename stage stalls when resources cannot be allocated.
        // Inputs of stall/flush requests to the controller must not dependend
        // on stall/clear signals for avoiding a race condition.
        ctrl.rnStageSendBubbleLower =
            (
                ( |valid ) &&
                (
                    !renameLogic.allocatable ||
                    !scheduler.allocatable ||
                    !activeList.allocatable ||
                    !loadStoreUnit.allocatable
                )
            ) || serialize;

        stall = ctrl.rnStage.stall;
        clear = ctrl.rnStage.clear;
        activeListEmpty = activeList.validEntryNum == 0;
    end

    RenameStageSerializer serializer(
        port.clk, port.rst, stall, clear, activeListEmpty,
        opInfo, 
        valid,
        serialize
    );

    logic isEnv[RENAME_WIDTH];
    always_comb begin
        //
        // --- Data to Rename logic
        //
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            // The rename stage stalls when resources cannot be allocated.
            update[i] =
                valid[i] && !stall && !clear;
        end

        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            isLoad[i] = 
                (opInfo[i].mopType == MOP_TYPE_MEM) && 
                (opInfo[i].mopSubType.memType == MEM_MOP_TYPE_LOAD);
            isStore[i] = 
                (opInfo[i].mopType == MOP_TYPE_MEM) && 
                (opInfo[i].mopSubType.memType == MEM_MOP_TYPE_STORE);
            isEnv[i] = 
                (opInfo[i].mopType == MOP_TYPE_MEM) && 
                (opInfo[i].mopSubType.memType == MEM_MOP_TYPE_ENV);
            isBranch[i] =
                (opInfo[i].mopType == MOP_TYPE_INT) &&
                (opInfo[i].mopSubType.intType inside {INT_MOP_TYPE_BR, INT_MOP_TYPE_RIJ});
        end

        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            renameLogic.updateRMT[i] = update[i];

            // Logical register numbers
            renameLogic.logSrcRegA[i] = isBranch[i] ? opInfo[i].operand.brOp.srcRegNumA : opInfo[i].operand.intOp.srcRegNumA;
            renameLogic.logSrcRegB[i] = isBranch[i] ? opInfo[i].operand.brOp.srcRegNumB : opInfo[i].operand.intOp.srcRegNumB;
            renameLogic.logDstReg[i] = isBranch[i] ? opInfo[i].operand.brOp.dstRegNum : opInfo[i].operand.intOp.dstRegNum;

            // Read/Write control
            renameLogic.readRegA[i] = opInfo[i].opTypeA == OOT_REG;
            renameLogic.readRegB[i] = opInfo[i].opTypeB == OOT_REG;

            renameLogic.writeReg[i] = opInfo[i].writeReg;

            // to WAT
            renameLogic.watWriteRegFromPipeReg[i] = opInfo[i].writeReg && update[i];
            renameLogic.watWriteIssueQueuePtrFromPipeReg[i] = scheduler.allocatedPtr[i];
        end


        //
        // --- Renamed operands
        //
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            // Renamed physical register numbers.
            nextStage[i].phySrcRegNumA = renameLogic.phySrcRegA[i];
            nextStage[i].phySrcRegNumB = renameLogic.phySrcRegB[i];
            nextStage[i].phyDstRegNum = renameLogic.phyDstReg[i];
            nextStage[i].phyPrevDstRegNum = renameLogic.phyPrevDstReg[i];

        end

        // Source pointer for a matrix scheduler.
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            // Renamed physical register numbers.
            nextStage[i].srcIssueQueuePtrRegA = renameLogic.srcIssueQueuePtrRegA[i];
            nextStage[i].srcIssueQueuePtrRegB = renameLogic.srcIssueQueuePtrRegB[i];
        end


        //
        // Active list allocation
        //
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            activeList.pushTail[i] = update[i];

            `ifndef RSD_DISABLE_DEBUG_REGISTER
                alEntry[i].opId = pipeReg[i].opId;
            `endif

            alEntry[i].pc = pipeReg[i].pc;

            alEntry[i].phyPrevDstRegNum = nextStage[i].phyPrevDstRegNum;
            alEntry[i].phyDstRegNum = nextStage[i].phyDstRegNum;
            alEntry[i].logDstRegNum = opInfo[i].operand.intOp.dstRegNum;
            alEntry[i].writeReg = opInfo[i].writeReg;
            alEntry[i].isLoad = isLoad[i];
            alEntry[i].isStore = isStore[i];
            alEntry[i].isBranch = isBranch[i];
            alEntry[i].isEnv = opInfo[i].operand.systemOp.isEnv;
            alEntry[i].undefined = opInfo[i].undefined || opInfo[i].unsupported;
            alEntry[i].last = opInfo[i].last;
            alEntry[i].prevDependIssueQueuePtr = renameLogic.prevDependIssueQueuePtr[i];

            nextStage[i].activeListPtr = activeList.pushedTailPtr[i];
        end
        activeList.pushedTailData = alEntry;

        //
        // Issue queue allocation
        //
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            scheduler.allocate[i] = update[i];
            nextStage[i].issueQueuePtr = scheduler.allocatedPtr[i];
        end


        //
        // Load/store unit allocation
        //
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            loadStoreUnit.allocateLoadQueue[i] = update[i] && isLoad[i];
            loadStoreUnit.allocateStoreQueue[i] = update[i] && isStore[i];

            nextStage[i].loadQueuePtr = loadStoreUnit.allocatedLoadQueuePtr[i];
            nextStage[i].storeQueuePtr = loadStoreUnit.allocatedStoreQueuePtr[i];
        end

        // Make read request to Memory Dependent Prediction
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            port.pc[i] = pipeReg[i].pc;
        end
        
        //
        // --- Pipeline control
        //

        // 'valid' is invalidate, if 'stall' or 'clear' or 'rst' is enabled.
        // That is, a op is treated as a NOP.
        // Otherwise 'valid' is set to a previous stage's 'valid.'
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = pipeReg[i].opId;
`endif

            nextStage[i].valid =
                ( stall || clear || port.rst ) ? FALSE : valid[i];

            // Decoded micr-op and context.
            nextStage[i].pc = pipeReg[i].pc;
            nextStage[i].brPred = pipeReg[i].bPred;
            nextStage[i].opInfo = opInfo[i];

            // 以下のLSQのポインタはLSQのリカバリに用いる
            nextStage[i].loadQueueRecoveryPtr = loadStoreUnit.allocatedLoadQueuePtr[i];
            nextStage[i].storeQueueRecoveryPtr = loadStoreUnit.allocatedStoreQueuePtr[i];

        end
        port.nextStage = nextStage;

        empty = TRUE;
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            if (pipeReg[i].valid)
                empty = FALSE;
        end
        ctrl.rnStageEmpty = empty;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            debug.rnReg[i].valid = valid[i];
            debug.rnReg[i].opId = pipeReg[i].opId;
        end
`endif
    end



endmodule : RenameStage
// ---- Pipeline/RenameStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- RenameStageIF
// The interface of a rename stage.
//

import BasicTypes::*;
import MemoryMapTypes::*;
import PipelineTypes::*;


interface RenameStageIF( input logic clk, rst, rstStart );
    
    // Paths to the pipeline registers of a next stage.
    DispatchStageRegPath nextStage [ RENAME_WIDTH ];

    PC_Path pc [ RENAME_WIDTH ];
    logic memDependencyPred [ RENAME_WIDTH ];

    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage,
        pc
    );

    modport NextStage(
    input
        nextStage,
        memDependencyPred
    );

    modport MemoryDependencyPredictor(
    input
        clk,
        rst,
        rstStart,
        pc,
    output
        memDependencyPred
    );


endinterface : RenameStageIF




// ---- Pipeline/DispatchStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for dispatch.
//


import BasicTypes::*;
import MemoryMapTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;

module DispatchStage(
    //DispatchStageIF.ThisStage port,
    RenameStageIF.NextStage prev,
    SchedulerIF.DispatchStage scheduler,
    ControllerIF.DispatchStage ctrl,
    DebugIF.DispatchStage debug
);

    // パディングは IntOpSubInfo のみ行う．対応できない場合は ASSERT に引っかかる
    `RSD_STATIC_ASSERT(
        INT_SUB_INFO_BIT_WIDTH <= BR_SUB_INFO_BIT_WIDTH, 
        "Invalid padding at IntOpSubInfo"
    );

    // --- Pipeline registers
    DispatchStageRegPath pipeReg [ DISPATCH_WIDTH ];
    always_ff @(posedge ctrl.clk) begin
        if (ctrl.rst) begin
            for (int i = 0; i < DISPATCH_WIDTH; i++) begin
                pipeReg[i] <= '0;
            end
        end
        else if (!ctrl.dsStage.stall) begin
            pipeReg <= prev.nextStage;
        end
        else begin
            pipeReg <= pipeReg;
        end
    end

    // Pipeline controll
    logic stall, clear;
    logic update  [ DISPATCH_WIDTH ];
    OpInfo opInfo [ DISPATCH_WIDTH ];
    IntIssueQueueEntry     intEntry     [ DISPATCH_WIDTH ];
    ComplexIssueQueueEntry complexEntry [ DISPATCH_WIDTH ];
    MemIssueQueueEntry     memEntry     [ DISPATCH_WIDTH ];
    SchedulerEntry schedulerEntry [ DISPATCH_WIDTH ];
    OpSrc opSrc[ DISPATCH_WIDTH ];
    OpDst opDst[ DISPATCH_WIDTH ];

    IntOpSubInfo intSubInfo[ DISPATCH_WIDTH ];
    BrOpSubInfo  brSubInfo [ DISPATCH_WIDTH ];
    MulOpSubInfo mulSubInfo[ DISPATCH_WIDTH ];
    DivOpSubInfo divSubInfo[ DISPATCH_WIDTH ];
    always_comb begin
        stall = ctrl.dsStage.stall;
        clear = ctrl.dsStage.clear;

        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            update[i] = !stall && !clear && pipeReg[i].valid;
            opInfo[i] = pipeReg[i].opInfo;
        end

        //
        // Dispatch an op to the shceduler.
        //
        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            //
            // Issue queue payload RAM entry.
            //
`ifndef RSD_DISABLE_DEBUG_REGISTER
            intEntry[i].opId     = pipeReg[i].opId;
            complexEntry[i].opId = pipeReg[i].opId;
            memEntry[i].opId     = pipeReg[i].opId;
`endif
            // OpSrc
            opSrc[i].phySrcRegNumA = pipeReg[i].phySrcRegNumA;
            opSrc[i].phySrcRegNumB = pipeReg[i].phySrcRegNumB;

            // OpDst
            opDst[i].writeReg = pipeReg[i].opInfo.writeReg;
            opDst[i].phyDstRegNum = pipeReg[i].phyDstRegNum;

            //
            // --- To an integer queue.
            //
            intEntry[i].opType = opInfo[i].mopSubType.intType;
            intEntry[i].cond = opInfo[i].cond;

            // OpSrc/OpDst
            intEntry[i].opSrc = opSrc[i];
            intEntry[i].opDst = opDst[i];

            // ActiveListIndexPath
            intEntry[i].activeListPtr = pipeReg[i].activeListPtr;

            //LSQ Tail Pointer for one cycle recovery
            intEntry[i].loadQueueRecoveryPtr = pipeReg[i].loadQueueRecoveryPtr;
            intEntry[i].storeQueueRecoveryPtr = pipeReg[i].storeQueueRecoveryPtr;

            // PC
            intEntry[i].pc = pipeReg[i].pc;

            intSubInfo[i].operandTypeA  = opInfo[i].opTypeA;
            intSubInfo[i].operandTypeB  = opInfo[i].opTypeB;
            intSubInfo[i].shiftIn       = opInfo[i].operand.intOp.shiftIn;
            intSubInfo[i].shiftType     = opInfo[i].operand.intOp.shiftType;
            intSubInfo[i].aluCode       = opInfo[i].operand.intOp.aluCode;
            intSubInfo[i].padding = '0;

            brSubInfo[i].brDisp = opInfo[i].operand.brOp.brDisp;
            brSubInfo[i].bPred = pipeReg[i].brPred;
            brSubInfo[i].operandTypeA = opInfo[i].opTypeA;
            brSubInfo[i].operandTypeB = opInfo[i].opTypeB;

            if ((intEntry[i].opType == INT_MOP_TYPE_BR) || (intEntry[i].opType == INT_MOP_TYPE_RIJ) ) begin
                intEntry[i].intOpInfo.brSubInfo = brSubInfo[i];
            end
            else begin
                intEntry[i].intOpInfo.intSubInfo = intSubInfo[i];
            end

            //
            // --- To a complex integer queue.
            //
            complexEntry[i].opType = opInfo[i].mopSubType.complexType;

            // OpSrc/OpDst
            complexEntry[i].opSrc = opSrc[i];
            complexEntry[i].opDst = opDst[i];

            // ActiveListIndexPath
            complexEntry[i].activeListPtr = pipeReg[i].activeListPtr;

            // PC
            complexEntry[i].pc = pipeReg[i].pc;

            complexEntry[i].loadQueueRecoveryPtr = pipeReg[i].loadQueueRecoveryPtr;
            complexEntry[i].storeQueueRecoveryPtr = pipeReg[i].storeQueueRecoveryPtr;

            mulSubInfo[i].mulGetUpper = opInfo[i].operand.complexOp.mulGetUpper;
            mulSubInfo[i].mulCode = opInfo[i].operand.complexOp.mulCode;

            divSubInfo[i].padding = '0;
            divSubInfo[i].divCode = opInfo[i].operand.complexOp.divCode;
            
            if (complexEntry[i].opType == COMPLEX_MOP_TYPE_MUL) begin
                complexEntry[i].complexOpInfo.mulSubInfo = mulSubInfo[i];
            end
            else begin // 将来ComplexパイプラインにMulとDiv以外の演算器を追加する場合はここをelse if (complexEntry[i].opType == COMPLEX_MOP_TYPE_DIV)に
                complexEntry[i].complexOpInfo.divSubInfo = divSubInfo[i];
            end
            
            //
            // --- To a memory queue.
            //

            // MemOpInfo
            memEntry[i].memOpInfo.opType = opInfo[i].mopSubType.memType;

            memEntry[i].memOpInfo.cond          = opInfo[i].cond;
            memEntry[i].memOpInfo.operandTypeA  = opInfo[i].opTypeA;
            memEntry[i].memOpInfo.operandTypeB  = opInfo[i].opTypeB;
            memEntry[i].memOpInfo.addrIn        = opInfo[i].operand.memOp.addrIn;
            memEntry[i].memOpInfo.isAddAddr     = opInfo[i].operand.memOp.isAddAddr;
            memEntry[i].memOpInfo.isRegAddr     = opInfo[i].operand.memOp.isRegAddr;
            memEntry[i].memOpInfo.memAccessMode = opInfo[i].operand.memOp.memAccessMode;

            memEntry[i].memOpInfo.csrCtrl     = opInfo[i].operand.memOp.csrCtrl;
            memEntry[i].memOpInfo.envCode     = opInfo[i].operand.systemOp.envCode;

`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            // これらは complex のフォーマットから取得する
            memEntry[i].memOpInfo.mulSubInfo = mulSubInfo[i];
            memEntry[i].memOpInfo.divSubInfo = divSubInfo[i];
`endif

            memEntry[i].memOpInfo.loadQueuePtr  = pipeReg[i].loadQueuePtr;
            memEntry[i].memOpInfo.storeQueuePtr = pipeReg[i].storeQueuePtr;

            memEntry[i].memOpInfo.hasAllocatedMSHR = 0;
            memEntry[i].memOpInfo.mshrID = '0;

            // OpSrc
            memEntry[i].opSrc = opSrc[i];
            memEntry[i].opDst = opDst[i];

            // ActiveListIndexPath
            memEntry[i].activeListPtr = pipeReg[i].activeListPtr;

            //LSQ Tail Pointer for one cycle recovery
            memEntry[i].loadQueueRecoveryPtr = pipeReg[i].loadQueueRecoveryPtr;
            memEntry[i].storeQueueRecoveryPtr = pipeReg[i].storeQueueRecoveryPtr;

            // PC
            memEntry[i].pc = pipeReg[i].pc;

            //
            // Scheduler Entry
            //
            schedulerEntry[i].opType = opInfo[i].mopType;
            schedulerEntry[i].opSubType = opInfo[i].mopSubType;

            schedulerEntry[i].srcRegValidA = ( opInfo[i].opTypeA == OOT_REG );
            schedulerEntry[i].srcRegValidB = ( opInfo[i].opTypeB == OOT_REG );
            schedulerEntry[i].opSrc = opSrc[i];
            schedulerEntry[i].opDst = opDst[i];

            schedulerEntry[i].srcPtrRegA = pipeReg[i].srcIssueQueuePtrRegA;
            schedulerEntry[i].srcPtrRegB = pipeReg[i].srcIssueQueuePtrRegB;

            //
            // Output to scheduler
            //
            scheduler.write[i] = update[i];
            scheduler.writePtr[i] = pipeReg[i].issueQueuePtr;
            scheduler.writeAL_Ptr[i] = pipeReg[i].activeListPtr;
            scheduler.intWriteData[i] = intEntry[i];
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            scheduler.complexWriteData[i] = complexEntry[i];
`endif
            scheduler.memWriteData[i] = memEntry[i];
            scheduler.writeSchedulerData[i] = schedulerEntry[i];
            scheduler.allocated[i] = pipeReg[i].valid;
            scheduler.memDependencyPred[i] = prev.memDependencyPred[i];
        end

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // Debug Register
        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            debug.dsReg[i].valid = pipeReg[i].valid;
            debug.dsReg[i].opId = pipeReg[i].opId;

`ifdef RSD_FUNCTIONAL_SIMULATION
            debug.dsReg[i].readRegA = opInfo[i].opTypeA == OOT_REG;
            debug.dsReg[i].logSrcRegA = opInfo[i].operand.intOp.srcRegNumA;
            debug.dsReg[i].phySrcRegA = pipeReg[i].phySrcRegNumA;

            debug.dsReg[i].readRegB = opInfo[i].opTypeB == OOT_REG;
            debug.dsReg[i].logSrcRegB = opInfo[i].operand.intOp.srcRegNumB;
            debug.dsReg[i].phySrcRegB = pipeReg[i].phySrcRegNumB;

            debug.dsReg[i].writeReg = opInfo[i].writeReg;
            debug.dsReg[i].logDstReg = opInfo[i].operand.intOp.dstRegNum;
            debug.dsReg[i].phyDstReg = pipeReg[i].phyDstRegNum;
            debug.dsReg[i].phyPrevDstReg = pipeReg[i].phyPrevDstRegNum;

            debug.dsReg[i].issueQueuePtr = pipeReg[i].issueQueuePtr;
`endif
        end
`endif
    end

endmodule : DispatchStage
// ---- Pipeline/DispatchStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- DispatchStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface DispatchStageIF( input logic clk, rst );
    
    modport ThisStage(
    input
        clk,
        rst
    );

endinterface : DispatchStageIF




// ---- Pipeline/ScheduleStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for scheduling.
//


import BasicTypes::*;
import MemoryMapTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;

module ScheduleStage(
    ScheduleStageIF.ThisStage port,
    SchedulerIF.ScheduleStage scheduler,
    RecoveryManagerIF.ScheduleStage recovery,
    ControllerIF.ScheduleStage ctrl
);
    // Pipeline controll
    logic stall, clear;
    logic flush [ ISSUE_WIDTH ];
    logic valid [ ISSUE_WIDTH ];
    logic update [ ISSUE_WIDTH ];
    IssueStageRegPath nextStage [ ISSUE_WIDTH ];
    IssueQueueIndexPath issueQueuePtr [ ISSUE_WIDTH ];
    IssueQueueOneHotPath flushIQ_Entry;

    always_comb begin

        stall = ctrl.scStage.stall;
        clear = ctrl.scStage.clear;

        // Scheduling
        scheduler.stall = stall;

        flushIQ_Entry = recovery.flushIQ_Entry;

        for (int i = 0; i < ISSUE_WIDTH; i++) begin
            valid[i] = scheduler.selected[i];
            issueQueuePtr[i] = scheduler.selectedPtr[i];
            flush[i] = flushIQ_Entry[issueQueuePtr[i]];
            update[i] = !stall && !clear && valid[i] && !flush[i];

            // --- Pipeline ラッチ書き込み
            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : valid[i];

            nextStage[i].issueQueuePtr = scheduler.selectedPtr[i];

            if ( i < INT_ISSUE_WIDTH )
                port.intNextStage[i] = nextStage[i];
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            else if ( i < INT_ISSUE_WIDTH + COMPLEX_ISSUE_WIDTH )
                port.complexNextStage[ i-INT_ISSUE_WIDTH ] = nextStage[i];
`endif
            else
                port.memNextStage[ i-INT_ISSUE_WIDTH-COMPLEX_ISSUE_WIDTH ] = nextStage[i];
        end
    end


endmodule : ScheduleStage
// ---- Pipeline/ScheduleStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- DispatchStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface ScheduleStageIF( input logic clk, rst );
    
    // Pipeline register
    IssueStageRegPath intNextStage     [ INT_ISSUE_WIDTH ];
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    IssueStageRegPath complexNextStage [ COMPLEX_ISSUE_WIDTH ];
`endif
    IssueStageRegPath memNextStage     [ MEM_ISSUE_WIDTH ];
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        intNextStage,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexNextStage,
`endif
        memNextStage
    );
    
    modport IntNextStage(
    input
        intNextStage
    );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    modport ComplexNextStage(
    input
        complexNextStage
    );
`endif

    modport MemNextStage(
    input
        memNextStage
    );

endinterface : ScheduleStageIF




// ---- Pipeline/IntegerBackEnd/IntegerIssueStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for issuing ops.
//


import BasicTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;

module IntegerIssueStage(
    IntegerIssueStageIF.ThisStage port,
    ScheduleStageIF.IntNextStage prev,
    SchedulerIF.IntegerIssueStage scheduler,
    RecoveryManagerIF.IntegerIssueStage recovery,
    ControllerIF.IntegerIssueStage ctrl,
    DebugIF.IntegerIssueStage debug
);

    // --- Pipeline registers
    IssueStageRegPath pipeReg [ INT_ISSUE_WIDTH ];
    IssueStageRegPath nextPipeReg [ INT_ISSUE_WIDTH ];
    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if ( port.rst ) begin
            for ( int i = 0; i < INT_ISSUE_WIDTH; i++ )
                pipeReg[i] <= '0;
        end
        else if( !ctrl.isStage.stall )              // write data
            pipeReg <= prev.intNextStage;
        else
            pipeReg <= nextPipeReg;
    end

    always_comb begin
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            if (recovery.toRecoveryPhase) begin
                nextPipeReg[i].valid = pipeReg[i].valid &&
                                    !SelectiveFlushDetector(
                                        recovery.toRecoveryPhase,
                                        recovery.flushRangeHeadPtr,
                                        recovery.flushRangeTailPtr,
                                        scheduler.intIssuedData[i].activeListPtr
                                        );
            end
            else begin
                nextPipeReg[i].valid = pipeReg[i].valid;
            end
            nextPipeReg[i].issueQueuePtr = pipeReg[i].issueQueuePtr;
        end
    end

    // Pipeline controll
    logic stall, clear;
    logic flush[ INT_ISSUE_WIDTH ];
    logic valid [ INT_ISSUE_WIDTH ];
    IntegerRegisterReadStageRegPath nextStage [ INT_ISSUE_WIDTH ];
    IntIssueQueueEntry issuedData [ INT_ISSUE_WIDTH ];
    IssueQueueIndexPath issueQueuePtr [ INT_ISSUE_WIDTH ];

    always_comb begin

        stall = ctrl.isStage.stall;
        clear = ctrl.isStage.clear;

        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin

            if (scheduler.replay) begin
                // In this cycle, the pipeline replays ops.
                issuedData[i] = scheduler.intReplayData[i];
                valid[i] = scheduler.intReplayEntry[i];
            end
            else begin
                // In this cycle, the pipeline issues ops.
                issuedData[i] = scheduler.intIssuedData[i];
                valid[i] = !stall && pipeReg[i].valid;
            end

            issueQueuePtr[i] = pipeReg[i].issueQueuePtr;

            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        issuedData[i].activeListPtr
                        );

            // Issue.
            scheduler.intIssue[i] = !clear && valid[i] && !flush[i];
            scheduler.intIssuePtr[i] = issueQueuePtr[i];

            // --- Pipeline ラッチ書き込み
            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (clear || port.rst || flush[i]) ? FALSE : valid[i];
            nextStage[i].intQueueData = issuedData[i];

`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = issuedData[i].opId;
`endif
        end

        port.nextStage = nextStage;

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // Debug Register
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            debug.intIsReg[i].valid = valid[i];
            debug.intIsReg[i].flush = flush[i];
            debug.intIsReg[i].opId = issuedData[i].opId;
        end
`endif
    end


endmodule : IntegerIssueStage
// ---- Pipeline/IntegerBackEnd/IntegerIssueStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- IntegerIssueStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface IntegerIssueStageIF( input logic clk, rst );
    
    // Pipeline register
    IntegerRegisterReadStageRegPath nextStage [ INT_ISSUE_WIDTH ];
    
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );

endinterface : IntegerIssueStageIF




// ---- Pipeline/IntegerBackEnd/IntegerRegisterReadStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for register read.
//


import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import DebugTypes::*;

//
// --- Immediate
//
function automatic DataPath RISCV_OpImm(
    RISCV_IntOperandImmShift intOperandImm
);

    // Todo: optimize
    DataPath result;
    case( intOperandImm.immType )
        //RISCV_IMM_I : begin
        default : begin
            result   = { {12{intOperandImm.imm[19]}}, intOperandImm.imm };
        end
        RISCV_IMM_U : begin
            result   = { intOperandImm.imm, 12'h0 };
        end
    endcase // immType
    return result;
endfunction : RISCV_OpImm


//
// --- オペランドの選択
//

function automatic DataPath SelectOperandIntReg(
input
    OpOperandType opType, DataPath regV, DataPath immV, DataPath pcV
);
    case( opType )
    default:    // OOT_REG
        return regV;
    OOT_IMM:
        return immV;
    OOT_PC:
        return pcV;
    endcase
endfunction

//
// --- Integer Register Read Stage
//
module IntegerRegisterReadStage(
    IntegerRegisterReadStageIF.ThisStage port,
    IntegerIssueStageIF.NextStage prev,
    RegisterFileIF.IntegerRegisterReadStage registerFile,
    BypassNetworkIF.IntegerRegisterReadStage bypass,
    RecoveryManagerIF.IntegerRegisterReadStage recovery,
    ControllerIF.IntegerRegisterReadStage ctrl,
    DebugIF.IntegerRegisterReadStage debug
);

    // --- Pipeline registers
    IntegerRegisterReadStageRegPath pipeReg [INT_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    always_ff@(posedge port.clk)   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= FALSE;
            end
        end
        else if(!ctrl.backEnd.stall) begin              // write data
            pipeReg <= prev.nextStage;
        end
    end

    // Operand
    DataPath immOut [ INT_ISSUE_WIDTH ];
    AddrPath pc [ INT_ISSUE_WIDTH ];
    PRegDataPath operandA [ INT_ISSUE_WIDTH ];
    PRegDataPath operandB [ INT_ISSUE_WIDTH ];

    // Pipeline controll
    logic stall, clear;
    logic flush[ INT_ISSUE_WIDTH ];
    IntIssueQueueEntry iqData[INT_ISSUE_WIDTH];
    IntOpSubInfo intSubInfo[INT_ISSUE_WIDTH];
    BrOpSubInfo brSubInfo[INT_ISSUE_WIDTH];
    OpSrc opSrc[INT_ISSUE_WIDTH];
    OpDst opDst[INT_ISSUE_WIDTH];
    IntegerExecutionStageRegPath nextStage[INT_ISSUE_WIDTH];

    always_comb begin
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            iqData[i] = pipeReg[i].intQueueData;
            intSubInfo[i] = iqData[i].intOpInfo.intSubInfo;
            brSubInfo[i] = iqData[i].intOpInfo.brSubInfo;
            opSrc[i] = iqData[i].opSrc;
            opDst[i] = iqData[i].opDst;
            pc[i] = ToAddrFromPC(iqData[i].pc);

            //
            // To the register file.
            //
            registerFile.intSrcRegNumA[i] = opSrc[i].phySrcRegNumA;
            registerFile.intSrcRegNumB[i] = opSrc[i].phySrcRegNumB;

            //
            // To the bypass network.
            // ストールやフラッシュの制御は，Bypass モジュールの内部で
            // コントローラの信号を参照して行われている
            //
            bypass.intPhySrcRegNumA[i] = opSrc[i].phySrcRegNumA;
            bypass.intPhySrcRegNumB[i] = opSrc[i].phySrcRegNumB;

            bypass.intWriteReg[i]  = opDst[i].writeReg & pipeReg[i].valid;
            bypass.intPhyDstRegNum[i] = opDst[i].phyDstRegNum;
            bypass.intReadRegA[i] = ( intSubInfo[i].operandTypeA == OOT_REG ) || ( brSubInfo[i].operandTypeA == OOT_REG );
            bypass.intReadRegB[i] = ( intSubInfo[i].operandTypeB == OOT_REG ) || ( brSubInfo[i].operandTypeA == OOT_REG );

            //
            // --- オペランド選択
            //
            immOut[i] = RISCV_OpImm(
                .intOperandImm( intSubInfo[i].shiftIn )
            );
            operandA[i].data = SelectOperandIntReg(
                intSubInfo[i].operandTypeA,
                registerFile.intSrcRegDataA[i].data,
                immOut[i],
                pc[i]
            );
            operandB[i].data = SelectOperandIntReg(
                intSubInfo[i].operandTypeB,
                registerFile.intSrcRegDataB[i].data,
                immOut[i],
                pc[i]
            );
            operandA[i].valid = (intSubInfo[i].operandTypeA != OOT_REG || registerFile.intSrcRegDataA[i].valid);
            operandB[i].valid = (intSubInfo[i].operandTypeB != OOT_REG || registerFile.intSrcRegDataB[i].valid);

            //
            // --- Pipeline ラッチ書き込み
            //
            `ifndef RSD_DISABLE_DEBUG_REGISTER
                nextStage[i].opId = pipeReg[i].opId;
            `endif

            // リセットorフラッシュ時はNOP
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        iqData[i].activeListPtr
                        );
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : pipeReg[i].valid;

            // レジスタ値&フラグ
            nextStage[i].operandA = operandA[i];
            nextStage[i].operandB = operandB[i];

            // Issue queue data
            nextStage[i].intQueueData = pipeReg[i].intQueueData;

            // バイパス制御
            nextStage[i].bCtrl = bypass.intCtrlOut[i];

        end
        port.nextStage = nextStage;

        // Debug Register
        `ifndef RSD_DISABLE_DEBUG_REGISTER
            for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
                debug.intRrReg[i].valid = pipeReg[i].valid;
                debug.intRrReg[i].flush = flush[i];
                debug.intRrReg[i].opId = pipeReg[i].opId;
            end
        `endif
    end
endmodule : IntegerRegisterReadStage
// ---- Pipeline/IntegerBackEnd/IntegerRegisterReadStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;
import BypassTypes::*;
import PipelineTypes::*;


interface IntegerRegisterReadStageIF( input logic clk, rst );
    
    // Pipeline register
    IntegerExecutionStageRegPath nextStage [ INT_ISSUE_WIDTH ];

    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );


endinterface : IntegerRegisterReadStageIF




// ---- Pipeline/IntegerBackEnd/IntegerExecutionStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- IntegerExecutionStageIF
//

import BasicTypes::*;
import BypassTypes::*;
import OpFormatTypes::*;
import PipelineTypes::*;


interface IntegerExecutionStageIF( input logic clk, rst );

    // Pipeline register
    IntegerRegisterWriteStageRegPath nextStage [ INT_ISSUE_WIDTH ];
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );
endinterface : IntegerExecutionStageIF




// ---- Pipeline/IntegerBackEnd/IntegerExecutionStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Execution stage
//

import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import DebugTypes::*;
import FetchUnitTypes::*;
import RenameLogicTypes::*;


function automatic logic IsConditionEnabledInt( CondCode cond, DataPath opA, DataPath opB );
    logic ce;
    SignedDataPath signedOpA;
    SignedDataPath signedOpB;

    signedOpA = opA;
    signedOpB = opB;

    case( cond )
        COND_EQ:  ce = ( opA == opB );
        COND_NE:  ce = ( opA != opB );
        COND_LT:  ce = ( signedOpA < signedOpB );
        COND_LTU: ce = ( opA < opB );
        COND_GE:  ce = ( signedOpA >= signedOpB );
        COND_GEU: ce = ( opA >= opB );

        // AL 常時（無条件） -
        COND_AL: ce = 1;

        default:
            ce = 1;
    endcase

    return ce;

endfunction

//
// 実行ステージ
//

module IntegerExecutionStage(
    IntegerExecutionStageIF.ThisStage port,
    IntegerRegisterReadStageIF.NextStage prev,
    BypassNetworkIF.IntegerExecutionStage bypass,
    RecoveryManagerIF.IntegerExecutionStage recovery,
    ControllerIF.IntegerExecutionStage ctrl,
    DebugIF.IntegerExecutionStage debug
);

    IntegerExecutionStageRegPath pipeReg [INT_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    // --- Pipeline registers
    always_ff@(posedge port.clk)   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= FALSE;
            end
        end
        else if(!ctrl.backEnd.stall) begin  // write data
            pipeReg <= prev.nextStage;
        end
    end

    // Pipeline controll
    logic stall, clear;
    logic flush[ INT_ISSUE_WIDTH ];

    IntIssueQueueEntry iqData[INT_ISSUE_WIDTH];
    IntOpInfo  intOpInfo [ INT_ISSUE_WIDTH ];
    BranchPred bPred [ INT_ISSUE_WIDTH ];
    AddrPath pc [ INT_ISSUE_WIDTH ];

    PRegDataPath fuOpA [ INT_ISSUE_WIDTH ];
    PRegDataPath fuOpB [ INT_ISSUE_WIDTH ];
    PRegDataPath dataOut [ INT_ISSUE_WIDTH ];

    // Condition
    logic isCondEnabled [ INT_ISSUE_WIDTH ];

    // ALU
    DataPath aluDataOut [ INT_ISSUE_WIDTH ];
    IntALU_Code aluCode [ INT_ISSUE_WIDTH ];

    for ( genvar i = 0; i < INT_ISSUE_WIDTH; i++ ) begin : BlockALU
        IntALU intALU(
            .aluCode ( aluCode[i] ),
            .fuOpA_In ( fuOpA[i].data ),
            .fuOpB_In ( fuOpB[i].data ),
            .aluDataOut ( aluDataOut[i] )
        );
    end

    // Shifter
    ShiftOperandType shiftOperandType [ INT_ISSUE_WIDTH ];
    RISCV_IntOperandImmShift shiftImmIn [ INT_ISSUE_WIDTH ];
    DataPath shiftDataOut [ INT_ISSUE_WIDTH ];
    logic shiftCarryOut [ INT_ISSUE_WIDTH ];

    for ( genvar i = 0; i < INT_ISSUE_WIDTH; i++ ) begin : BlockShifter
        Shifter shifter(
            .shiftOperandType( shiftOperandType[i] ),
            .shiftType( shiftImmIn[i].shiftType ),
            .immShiftAmount( shiftImmIn[i].shift ),
            .regShiftAmount( fuOpB[i][SHIFT_AMOUNT_BIT_SIZE-1:0] ),
            .dataIn( fuOpA[i].data ),
            .carryIn( 1'b0 ),
            .dataOut( shiftDataOut[i] ),
            .carryOut( shiftCarryOut[i] )
        );
    end

    // Branch
    logic isBranch [ INT_ISSUE_WIDTH ];
    logic isJump [ INT_ISSUE_WIDTH ];
    logic brTaken  [ INT_ISSUE_WIDTH ];
    BranchResult brResult [ INT_ISSUE_WIDTH ];
    logic predMiss [ INT_ISSUE_WIDTH ];
    logic regValid [ INT_ISSUE_WIDTH ];

    IntOpSubInfo intSubInfo[ INT_ISSUE_WIDTH ];
    BrOpSubInfo  brSubInfo[ INT_ISSUE_WIDTH ];

    always_comb begin
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            iqData[i] = pipeReg[i].intQueueData;
            intOpInfo[i] = iqData[i].intOpInfo;
            intSubInfo[i] = intOpInfo[i].intSubInfo;
            brSubInfo[i] = intOpInfo[i].brSubInfo;
            pc[i] = ToAddrFromPC(iqData[i].pc);
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        iqData[i].activeListPtr
                        );

            // オペランド
            fuOpA[i] = ( pipeReg[i].bCtrl.rA.valid ? bypass.intSrcRegDataOutA[i] : pipeReg[i].operandA );
            fuOpB[i] = ( pipeReg[i].bCtrl.rB.valid ? bypass.intSrcRegDataOutB[i] : pipeReg[i].operandB );

            // Condition
            isCondEnabled[i] = IsConditionEnabledInt( iqData[i].cond, fuOpA[i].data, fuOpB[i].data );

            // Shifter
            shiftOperandType[i] = intSubInfo[i].shiftType;
            shiftImmIn[i] = intSubInfo[i].shiftIn;

            // ALU
            aluCode[i] = intSubInfo[i].aluCode;

            //
            // データアウト
            //
            unique case ( iqData[i].opType )
            INT_MOP_TYPE_ALU:       dataOut[i].data = aluDataOut[i];
            INT_MOP_TYPE_SHIFT:     dataOut[i].data = shiftDataOut[i];
            //INT_MOP_TYPE_BR, INT_MOP_TYPE_RIJ :        dataOut[i].data = ToPC_FromAddr(pc[i] + PC_OPERAND_OFFSET);
            INT_MOP_TYPE_BR, INT_MOP_TYPE_RIJ :        dataOut[i].data = pc[i] + PC_OPERAND_OFFSET;
            default: /* select */  dataOut[i].data = ( isCondEnabled[i] ? fuOpA[i].data : fuOpB[i].data );
            endcase

            // If invalid regisers are read, regValid is negated and this op must be replayed.
            regValid[i] =
                (intSubInfo[i].operandTypeA != OOT_REG || fuOpA[i].valid ) &&
                (intSubInfo[i].operandTypeB != OOT_REG || fuOpB[i].valid );
            dataOut[i].valid = regValid[i];


            //
            // --- Bypass
            //
            bypass.intCtrlIn[i] = pipeReg[i].bCtrl;
            bypass.intDstRegDataOut[i] = dataOut[i];

            //
            // --- 分岐
            //
            bPred[i] = brSubInfo[i].bPred;
            isBranch[i] = ( iqData[i].opType inside { INT_MOP_TYPE_BR, INT_MOP_TYPE_RIJ } );
            isJump[i] = 
                (iqData[i].opType == INT_MOP_TYPE_BR && iqData[i].cond == COND_AL)
                    || iqData[i].opType == INT_MOP_TYPE_RIJ;

            // 分岐orレジスタ間接分岐で，条件が有効ならTaken
            brTaken[i] = pipeReg[i].valid && isBranch[i] && isCondEnabled[i];

            // Whether this branch is conditional one or not.
            brResult[i].isCondBr = !isJump[i];
            
            // The address of a branch.
            brResult[i].brAddr = ToPC_FromAddr(pc[i]);

            // ターゲットアドレスの計算
            if( brTaken[i] ) begin
                brResult[i].nextAddr =
                    ToPC_FromAddr(
                        (iqData[i].opType == INT_MOP_TYPE_BR) ?  
                            (pc[i] + ExtendBranchDisplacement(brSubInfo[i].brDisp) ) : // 方向分岐 
                            (AddJALR_TargetOffset(fuOpA[i].data, brSubInfo[i].brDisp) // レジスタ間接分岐 
                        ) 
                    );
            end
            else begin
                brResult[i].nextAddr = ToPC_FromAddr(pc[i] + INSN_BYTE_WIDTH);
            end
            brResult[i].execTaken = brTaken[i];
            brResult[i].predTaken = bPred[i].predTaken;
            brResult[i].valid = isBranch[i] && pipeReg[i].valid && regValid[i];
            brResult[i].globalHistory = bPred[i].globalHistory;
            brResult[i].phtPrevValue = bPred[i].phtPrevValue;
                    
            // 予測ミス判定
            predMiss[i] =
                pipeReg[i].valid && isBranch[i] &&
                (
                     (bPred[i].predTaken != brTaken[i]) ||
                     (brTaken[i] == TRUE &&
                      bPred[i].predAddr != brResult[i].nextAddr)
                );

            brResult[i].mispred = predMiss[i];
        end
    end

    //
    // --- Pipeline レジスタ書き込み
    //
    IntegerRegisterWriteStageRegPath nextStage [ INT_ISSUE_WIDTH ];

    always_comb begin
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            `ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = pipeReg[i].opId;
            `endif

            nextStage[i].intQueueData = pipeReg[i].intQueueData;

            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : pipeReg[i].valid;

            nextStage[i].dataOut = dataOut[i];

            nextStage[i].brResult    = brResult[i];
            nextStage[i].brMissPred  = predMiss[i];
        end

        // Output
        port.nextStage = nextStage;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            debug.intExReg[i].valid = pipeReg[i].valid;
            debug.intExReg[i].flush = flush[i];
            debug.intExReg[i].opId = pipeReg[i].opId;
`ifdef RSD_FUNCTIONAL_SIMULATION
            debug.intExReg[i].dataOut = dataOut[i];
            debug.intExReg[i].fuOpA   = fuOpA[i].data;
            debug.intExReg[i].fuOpB   = fuOpB[i].data;
            debug.intExReg[i].aluCode  = aluCode[i];
            debug.intExReg[i].opType  = iqData[i].opType;
`endif
        end
    `endif
end

endmodule : IntegerExecutionStage
// ---- Pipeline/IntegerBackEnd/IntegerRegisterWriteStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- IntegerRegisterWritePipeIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface IntegerRegisterWriteStageIF( input logic clk, rst );
    
    modport ThisStage(
    input
        clk,
        rst
    );

endinterface : IntegerRegisterWriteStageIF




// ---- Pipeline/IntegerBackEnd/IntegerRegisterWriteStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Integer Write back stage
//

import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import FetchUnitTypes::*;
import DebugTypes::*;




module IntegerRegisterWriteStage(
    //IntegerRegisterWriteStageIF.ThisStage port,
    IntegerExecutionStageIF.NextStage prev,
    SchedulerIF.IntegerRegisterWriteStage scheduler,
    NextPCStageIF.IntegerRegisterWriteStage ifStage,
    RegisterFileIF.IntegerRegisterWriteStage registerFile,
    ActiveListIF.IntegerRegisterWriteStage activeList,
    RecoveryManagerIF.IntegerRegisterWriteStage recovery,
    ControllerIF.IntegerRegisterWriteStage ctrl,
    DebugIF.IntegerRegisterWriteStage debug
);
    IntegerRegisterWriteStageRegPath pipeReg [INT_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    // --- Pipeline registers
    always_ff@( posedge /*port.clk*/ ctrl.clk )   // synchronous rst
    begin
        if (ctrl.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= FALSE;
            end
        end
        else if(!ctrl.backEnd.stall) begin   // write data
            pipeReg <= prev.nextStage;
        end
    end

    ActiveListWriteData alWriteData[INT_ISSUE_WIDTH];
    IntIssueQueueEntry iqData[INT_ISSUE_WIDTH];
    BranchResult brResult[INT_ISSUE_WIDTH];
    logic stall, clear;
    logic flush[ INT_ISSUE_WIDTH ];
    logic update [ INT_ISSUE_WIDTH ];
    logic valid [ INT_ISSUE_WIDTH ];
    logic regValid [ INT_ISSUE_WIDTH ];

    always_comb begin

        // Pipeline controll
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            iqData[i] = pipeReg[i].intQueueData;
            regValid[i] = pipeReg[i].dataOut.valid;

            valid[i] = pipeReg[i].valid;
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        iqData[i].activeListPtr
                        );
            update[i] = !stall && !clear && valid[i] && !flush[i];

            //
            // Register file
            //
            registerFile.intDstRegWE[i] =
                update[i] && iqData[i].opDst.writeReg;

            registerFile.intDstRegNum[i] = iqData[i].opDst.phyDstRegNum;
            registerFile.intDstRegData[i] = pipeReg[i].dataOut;

            //
            // Active list
            //
            alWriteData[i].ptr = iqData[i].activeListPtr;
            alWriteData[i].loadQueuePtr = iqData[i].loadQueueRecoveryPtr;
            alWriteData[i].storeQueuePtr = iqData[i].storeQueueRecoveryPtr;
            alWriteData[i].pc = pipeReg[i].brResult.nextAddr;
            alWriteData[i].dataAddr = '0;
            alWriteData[i].isBranch = (iqData[i].opType inside { INT_MOP_TYPE_BR, INT_MOP_TYPE_RIJ });
            alWriteData[i].isStore = FALSE;

            // Branch results.
            brResult[i] = pipeReg[i].brResult;
            brResult[i].valid = pipeReg[i].brResult.valid && update[i] && regValid[i];
            ifStage.brResult = brResult;

            // ExecState
            if ( update[i] ) begin
                if (regValid[i]) begin
                    alWriteData[i].state =
                        pipeReg[i].brMissPred ? EXEC_STATE_REFETCH_NEXT : EXEC_STATE_SUCCESS;
                end
                else begin
                    alWriteData[i].state = EXEC_STATE_NOT_FINISHED;
                end
            end
            else begin
                alWriteData[i].state = EXEC_STATE_NOT_FINISHED;
            end


            // 実行が正しく終了してる場合，フォールト判定を行う
            if (alWriteData[i].state inside {EXEC_STATE_REFETCH_NEXT, EXEC_STATE_SUCCESS}) begin
                if (brResult[i].nextAddr[INSN_ADDR_BIT_WIDTH-1:0] != 0 && brResult[i].valid) begin
                    alWriteData[i].state = EXEC_STATE_FAULT_INSN_MISALIGNED;
                    alWriteData[i].dataAddr = brResult[i].nextAddr;
                end
            end

            activeList.intWrite[i] = update[i];
            activeList.intWriteData[i] = alWriteData[i];

            // Replay
            scheduler.intRecordEntry[i] = update[i] && !regValid[i];
            scheduler.intRecordData[i] = pipeReg[i].intQueueData;
        end

        // Debug Register
        `ifndef RSD_DISABLE_DEBUG_REGISTER
            for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
                debug.intRwReg[i].valid = valid[i];
                debug.intRwReg[i].flush = flush[i];
                debug.intRwReg[i].opId = pipeReg[i].opId;
            end
        `endif
    end
endmodule : IntegerRegisterWriteStage
// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerIssueStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for issuing ops.
//


import BasicTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE

module ComplexIntegerIssueStage(
    ComplexIntegerIssueStageIF.ThisStage port,
    ScheduleStageIF.ComplexNextStage prev,
    SchedulerIF.ComplexIntegerIssueStage scheduler,
    RecoveryManagerIF.ComplexIntegerIssueStage recovery,
    MulDivUnitIF.ComplexIntegerIssueStage mulDivUnit,
    ControllerIF.ComplexIntegerIssueStage ctrl,
    DebugIF.ComplexIntegerIssueStage debug
);

    // --- Pipeline registers
    IssueStageRegPath pipeReg [ COMPLEX_ISSUE_WIDTH ];
    IssueStageRegPath nextPipeReg [ COMPLEX_ISSUE_WIDTH ];
    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if ( port.rst ) begin
            for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ )
                pipeReg[i] <= '0;
        end
        else if( !ctrl.isStage.stall )              // write data
            pipeReg <= prev.complexNextStage;
        else
            pipeReg <= nextPipeReg;
    end

    always_comb begin
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            if (recovery.toRecoveryPhase) begin
                nextPipeReg[i].valid = pipeReg[i].valid &&
                                    !SelectiveFlushDetector(
                                        recovery.toRecoveryPhase,
                                        recovery.flushRangeHeadPtr,
                                        recovery.flushRangeTailPtr,
                                        scheduler.complexIssuedData[i].activeListPtr
                                        );
            end
            else begin
                nextPipeReg[i].valid = pipeReg[i].valid;
            end
            nextPipeReg[i].issueQueuePtr = pipeReg[i].issueQueuePtr;
        end
    end


    // Pipeline controll
    logic stall, clear;
    logic flush[ COMPLEX_ISSUE_WIDTH ];
    logic valid [ COMPLEX_ISSUE_WIDTH ];
    ComplexIntegerRegisterReadStageRegPath nextStage [ COMPLEX_ISSUE_WIDTH ];
    ComplexIssueQueueEntry issuedData [ COMPLEX_ISSUE_WIDTH ];
    IssueQueueIndexPath issueQueuePtr [ COMPLEX_ISSUE_WIDTH ];

    always_comb begin

        stall = ctrl.isStage.stall;
        clear = ctrl.isStage.clear;

        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin

            if (scheduler.replay) begin
                // In this cycle, the pipeline replays ops.
                issuedData[i] = scheduler.complexReplayData[i];
                valid[i] = scheduler.complexReplayEntry[i];
            end
            else begin
                // In this cycle, the pipeline issues ops.
                issuedData[i] = scheduler.complexIssuedData[i];
                valid[i] = !stall && pipeReg[i].valid;
            end

            issueQueuePtr[i] = pipeReg[i].issueQueuePtr;

            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        issuedData[i].activeListPtr
                        );

            // Issue.
            scheduler.complexIssue[i] = !clear && valid[i] && !flush[i];
            scheduler.complexIssuePtr[i] = issueQueuePtr[i];

            `ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                // Lock div units
                mulDivUnit.divAcquire[i] = 
                    !clear && valid[i] &&
                    !flush[i] && issuedData[i].opType == COMPLEX_MOP_TYPE_DIV;
                mulDivUnit.divResetFromCI_Stage[i] = 
                    valid[i] && (flush[i] || clear) &&
                    issuedData[i].opType == COMPLEX_MOP_TYPE_DIV;
            `endif        

            // --- Pipeline ラッチ書き込み
            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (clear || port.rst || flush[i]) ? FALSE : valid[i];
            nextStage[i].complexQueueData = issuedData[i];
            nextStage[i].replay = scheduler.replay;
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = issuedData[i].opId;
`endif
        end

        port.nextStage = nextStage;

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // Debug Register
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            debug.complexIsReg[i].valid = valid[i];
            debug.complexIsReg[i].flush = flush[i];
            debug.complexIsReg[i].opId = issuedData[i].opId;
        end
`endif
    end


endmodule : ComplexIntegerIssueStage

`endif
// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerIssueStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- ComplexIntegerIssueStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface ComplexIntegerIssueStageIF( input logic clk, rst );
    
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    // Pipeline register
    ComplexIntegerRegisterReadStageRegPath nextStage [ COMPLEX_ISSUE_WIDTH ];
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );
`endif    


endinterface : ComplexIntegerIssueStageIF




// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerRegisterReadStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for register read.
//


import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import DebugTypes::*;

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE

module ComplexIntegerRegisterReadStage(
    ComplexIntegerRegisterReadStageIF.ThisStage port,
    ComplexIntegerIssueStageIF.NextStage prev,
    RegisterFileIF.ComplexIntegerRegisterReadStage registerFile,
    BypassNetworkIF.ComplexIntegerRegisterReadStage bypass,
    RecoveryManagerIF.ComplexIntegerRegisterReadStage recovery,
    ControllerIF.ComplexIntegerRegisterReadStage ctrl,
    DebugIF.ComplexIntegerRegisterReadStage debug
);

    // --- Pipeline registers
    ComplexIntegerRegisterReadStageRegPath pipeReg[COMPLEX_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin              // write data
            pipeReg <= prev.nextStage;
        end
    end



    // Pipeline controll
    logic stall, clear;
    logic flush[ COMPLEX_ISSUE_WIDTH ];
    ComplexIssueQueueEntry iqData[COMPLEX_ISSUE_WIDTH];
    MulOpSubInfo mulOpInfo[COMPLEX_ISSUE_WIDTH];
    OpSrc opSrc[COMPLEX_ISSUE_WIDTH];
    OpDst opDst[COMPLEX_ISSUE_WIDTH];
    ComplexIntegerExecutionStageRegPath nextStage[COMPLEX_ISSUE_WIDTH];

    always_comb begin
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            iqData[i] = pipeReg[i].complexQueueData;
            mulOpInfo[i] = iqData[i].complexOpInfo.mulSubInfo;
            opSrc[i] = iqData[i].opSrc;
            opDst[i] = iqData[i].opDst;

            //
            // To the register file.
            //

            registerFile.complexSrcRegNumA[i] = opSrc[i].phySrcRegNumA;
            registerFile.complexSrcRegNumB[i] = opSrc[i].phySrcRegNumB;

            //
            // To the bypass network.
            // ストールやフラッシュの制御は，Bypass モジュールの内部で
            // コントローラの信号を参照して行われている
            //
            bypass.complexPhySrcRegNumA[i] = opSrc[i].phySrcRegNumA;
            bypass.complexPhySrcRegNumB[i] = opSrc[i].phySrcRegNumB;

            bypass.complexWriteReg[i]  = opDst[i].writeReg & pipeReg[i].valid;
            bypass.complexPhyDstRegNum[i] = opDst[i].phyDstRegNum;

            // Complex Integer では、operandTypeはOOT_REGしか未サポート
            bypass.complexReadRegA[i] = TRUE;
            bypass.complexReadRegB[i] = TRUE;
            //bypass.complexReadRegA[i] = ( iqData[i].complexOpInfo.operandTypeA == OOT_REG );
            //bypass.complexReadRegB[i] = ( iqData[i].complexOpInfo.operandTypeB == OOT_REG );

            //
            // --- Pipeline ラッチ書き込み
            //
            `ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = pipeReg[i].opId;
            `endif

            // リセットorフラッシュ時はNOP
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        iqData[i].activeListPtr
                        );
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : pipeReg[i].valid;

            nextStage[i].replay = pipeReg[i].replay;

            // divがこのステージ内でフラッシュされた場合：
            // Dividerへの要求予約を取り消し，
            // IQからdivを発行できるようにする 
            if (iqData[i].opType == COMPLEX_MOP_TYPE_DIV) begin
                nextStage[i].isFlushed = pipeReg[i].valid && flush[i];
            end
            else begin
                nextStage[i].isFlushed = FALSE;
            end
            
            // レジスタ値&フラグ
            nextStage[i].operandA = registerFile.complexSrcRegDataA[i];
            nextStage[i].operandB = registerFile.complexSrcRegDataB[i];
`ifdef RSD_ENABLE_VECTOR_PATH
            nextStage[i].vecOperandA = registerFile.complexSrcVecDataA[i];
            nextStage[i].vecOperandB = registerFile.complexSrcVecDataB[i];
`endif
            // Issue queue data
            nextStage[i].complexQueueData = pipeReg[i].complexQueueData;

            // バイパス制御
            nextStage[i].bCtrl = bypass.complexCtrlOut[i];

        end
        port.nextStage = nextStage;

        // Debug Register
        `ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            debug.complexRrReg[i].valid = pipeReg[i].valid;
            debug.complexRrReg[i].flush = flush[i];
            debug.complexRrReg[i].opId = pipeReg[i].opId;
        end
        `endif
    end
endmodule : ComplexIntegerRegisterReadStage

`endif
// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerRegisterReadStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;
import PipelineTypes::*;


interface ComplexIntegerRegisterReadStageIF( input logic clk, rst );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    // Pipeline register
    ComplexIntegerExecutionStageRegPath nextStage [ COMPLEX_ISSUE_WIDTH ];

    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );
`endif

endinterface : ComplexIntegerRegisterReadStageIF




// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerExecutionStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- ComplexIntegerExecutionStageIF
//

import BasicTypes::*;
import PipelineTypes::*;

interface ComplexIntegerExecutionStageIF( input logic clk, rst );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE

    // Pipeline register
    ComplexIntegerRegisterWriteStageRegPath nextStage [ COMPLEX_ISSUE_WIDTH ];
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );
`endif

endinterface : ComplexIntegerExecutionStageIF




// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerExecutionStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Complex Integer Execution stage
//
// 乗算/SIMD 命令の演算を行う
// COMPLEX_EXEC_STAGE_DEPTH 段にパイプライン化されている
//

import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import DebugTypes::*;

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE

module ComplexIntegerExecutionStage(
    ComplexIntegerExecutionStageIF.ThisStage port,
    ComplexIntegerRegisterReadStageIF.NextStage prev,
    MulDivUnitIF.ComplexIntegerExecutionStage mulDivUnit,
    SchedulerIF.ComplexIntegerExecutionStage scheduler,
    BypassNetworkIF.ComplexIntegerExecutionStage bypass,
    RecoveryManagerIF.ComplexIntegerExecutionStage recovery,
    ControllerIF.ComplexIntegerExecutionStage ctrl,
    DebugIF.ComplexIntegerExecutionStage debug
);
    // Pipeline controll
    logic stall, clear;
    logic flush[ COMPLEX_ISSUE_WIDTH ][ COMPLEX_EXEC_STAGE_DEPTH ];

    `RSD_STATIC_ASSERT(COMPLEX_ISSUE_WIDTH == MULDIV_ISSUE_WIDTH, "These muse be same");
    `RSD_STATIC_ASSERT(COMPLEX_EXEC_STAGE_DEPTH == MULDIV_STAGE_DEPTH, "These muse be same");

    //
    // --- Local Pipeline Register
    //

    // 複数サイクルにわたる ComplexIntegerExecutionStage 内で
    // 使用するパイプラインレジスタ
    typedef struct packed // LocalPipeReg
    {

`ifndef RSD_DISABLE_DEBUG_REGISTER
        OpId      opId;
`endif

        logic valid;  // Valid flag. If this is 0, its op is treated as NOP.
        logic regValid; // Valid flag of a destination register.
        ComplexIssueQueueEntry complexQueueData;
    } LocalPipeReg;

    LocalPipeReg localPipeReg [ COMPLEX_ISSUE_WIDTH ][ COMPLEX_EXEC_STAGE_DEPTH-1 ];
    LocalPipeReg nextLocalPipeReg [ COMPLEX_ISSUE_WIDTH ][ COMPLEX_EXEC_STAGE_DEPTH-1 ];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            for (int j = 0; j < COMPLEX_EXEC_STAGE_DEPTH-1; j++) begin
                localPipeReg[i][j] <= '0;
            end
        end
    end
`endif

    always_ff@( posedge port.clk ) begin
        if (port.rst || clear) begin
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                for ( int j = 0; j < COMPLEX_EXEC_STAGE_DEPTH-1; j++ ) begin
                    localPipeReg[i][j].valid <= '0;
                    localPipeReg[i][j].regValid <= '0;
                end
            end
        end
        else if(!ctrl.backEnd.stall) begin   // write data
            localPipeReg <= nextLocalPipeReg;
        end
    end


    //
    // --- Pipeline Register
    //

    // ComplexIntegerRegisterReadStage との境界にあるパイプラインレジスタ
    ComplexIntegerExecutionStageRegPath pipeReg[COMPLEX_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif
    always_ff@(posedge port.clk)   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin   // write data
            pipeReg <= prev.nextStage;
        end
    end

    //
    // Signals
    //
    ComplexIssueQueueEntry iqData        [ COMPLEX_ISSUE_WIDTH ] [COMPLEX_EXEC_STAGE_DEPTH];
    ComplexOpInfo          complexOpInfo [ COMPLEX_ISSUE_WIDTH ];
    MulOpSubInfo           mulSubInfo    [ COMPLEX_ISSUE_WIDTH ];
    DivOpSubInfo           divSubInfo    [ COMPLEX_ISSUE_WIDTH ];

    PRegDataPath  fuOpA    [ COMPLEX_ISSUE_WIDTH ];
    PRegDataPath  fuOpB    [ COMPLEX_ISSUE_WIDTH ];
    logic         regValid [ COMPLEX_ISSUE_WIDTH ];
    PRegDataPath  dataOut  [ COMPLEX_ISSUE_WIDTH ];



    //
    // DividerUnit
    //
    logic isDiv         [ COMPLEX_ISSUE_WIDTH ]; 
    logic finished      [ COMPLEX_ISSUE_WIDTH ];

    // For selective flush
    ActiveListIndexPath regActiveListIndex  [ COMPLEX_ISSUE_WIDTH ];
    ActiveListIndexPath nextActiveListIndex [ COMPLEX_ISSUE_WIDTH ];
    logic divReset[ COMPLEX_ISSUE_WIDTH ];

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                regActiveListIndex[i] <= '0;
            end
        end
        else begin
            regActiveListIndex <= nextActiveListIndex;
        end
    end

    for ( genvar i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
        //`RSD_ASSERT_CLK(port.clk, !(!mulDivUnit.divFree[i] && scheduler.divIsIssued[i]), "");
    end

    always_comb begin

        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            mulDivUnit.dataInA[i] = fuOpA[i].data;
            mulDivUnit.dataInB[i] = fuOpB[i].data;

            // DIV
            mulDivUnit.divCode[i] = divSubInfo[i].divCode;

            isDiv[i] =  
                pipeReg[i].complexQueueData.opType == COMPLEX_MOP_TYPE_DIV;

            // MUL
            mulDivUnit.mulGetUpper[i] = mulSubInfo[i].mulGetUpper;
            mulDivUnit.mulCode[i] = mulSubInfo[i].mulCode;

            // DIV
            mulDivUnit.divCode[i] = divSubInfo[i].divCode;

            mulDivUnit.dataInA[i] = fuOpA[i].data;
            mulDivUnit.dataInB[i] = fuOpB[i].data;

            // Reset 条件
            divReset[i] = FALSE;
            // Dividerで処理中のdivがフラッシュされたら，Dividerの状態をFREEに変更して
            // IQからdivを発行できるようにする
            if (recovery.toRecoveryPhase) begin
                divReset[i] = SelectiveFlushDetector( 
                    recovery.toRecoveryPhase, 
                    recovery.flushRangeHeadPtr, 
                    recovery.flushRangeTailPtr, 
                    regActiveListIndex[i]
                );
            end
            if (clear) begin
                divReset[i] = TRUE;
            end
            if (isDiv[i] && (pipeReg[i].isFlushed || (pipeReg[i].valid && flush[i][0]))) begin
                // Div is flushed at register read stage, so release the divider
                divReset[i] = TRUE;
            end
            mulDivUnit.divReset[i] = divReset[i];

            // Request to the divider
            // NOT make a request when below situation
            // 1) When any operands of inst. are invalid
            // 2) When the divider is waiting for the instruction
            //    to receive the result of the divider
            mulDivUnit.divReq[i] = 
                mulDivUnit.divReserved[i] && 
                pipeReg[i].valid && isDiv[i] && 
                fuOpA[i].valid && fuOpB[i].valid;

            if (mulDivUnit.divFinished[i] &&
                localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].valid &&
                localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].complexQueueData.opType == COMPLEX_MOP_TYPE_DIV && 
                localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].regValid
            ) begin 
                // Divが除算器から結果を取得できたので，
                // IQからのdivの発行を許可する 
                mulDivUnit.divRelease[i] = TRUE;
            end
            else begin
                mulDivUnit.divRelease[i] = FALSE;
            end
`endif

            if (pipeReg[i].valid && isDiv[i] && mulDivUnit.divReserved[i]) begin
                nextActiveListIndex[i] = 
                    pipeReg[i].complexQueueData.activeListPtr;
            end
            else begin
                nextActiveListIndex[i] = regActiveListIndex[i];
            end
        end
    end

    always_comb begin
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            iqData[i][0] = pipeReg[i].complexQueueData;
            complexOpInfo[i]  = pipeReg[i].complexQueueData.complexOpInfo;
            mulSubInfo[i]  = complexOpInfo[i].mulSubInfo;
            divSubInfo[i]  = complexOpInfo[i].divSubInfo;
            

            flush[i][0] = SelectiveFlushDetector(
                recovery.toRecoveryPhase,
                recovery.flushRangeHeadPtr,
                recovery.flushRangeTailPtr,
                pipeReg[i].complexQueueData.activeListPtr
            );

            // From local pipeline 
            for (int j = 1; j < COMPLEX_EXEC_STAGE_DEPTH; j++) begin 
                iqData[i][j] = localPipeReg[i][j-1].complexQueueData; 
                flush[i][j] = SelectiveFlushDetector( 
                    recovery.toRecoveryPhase, 
                    recovery.flushRangeHeadPtr, 
                    recovery.flushRangeTailPtr, 
                    localPipeReg[i][j-1].complexQueueData.activeListPtr 
                );
            end

            // オペランド
            fuOpA[i] = ( pipeReg[i].bCtrl.rA.valid ? bypass.complexSrcRegDataOutA[i] : pipeReg[i].operandA );
            fuOpB[i] = ( pipeReg[i].bCtrl.rB.valid ? bypass.complexSrcRegDataOutB[i] : pipeReg[i].operandB );
           

            
            //
            // --- regValid
            //

            // If invalid regisers are read, regValid is negated and this op must be replayed.
            // ベクタ以外の演算
            regValid[i] =
                fuOpA[i].valid &&
                fuOpB[i].valid;

            //
            // --- データアウト(実行ステージの最終段の処理)
            //
            dataOut[i].valid
                = localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].regValid;

            unique case ( localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].complexQueueData.opType )
            COMPLEX_MOP_TYPE_DIV: dataOut[i].data = mulDivUnit.divDataOut[i];
            default: /* mul */    dataOut[i].data = mulDivUnit.mulDataOut[i];
            endcase

            //
            // --- Bypass
            //

            // 最初のステージで出力
            bypass.complexCtrlIn[i] = pipeReg[i].bCtrl;

            // 最後のステージで出力
            bypass.complexDstRegDataOut[i] = dataOut[i];

            //
            // --- Replay
            //

            // ISから3ステージ後=EX1ステージでReplayを出力
            // このとき、localPipeReg[lane][0]のデータを使う
            scheduler.complexRecordEntry[i] =
                !stall &&
                !clear &&
                !flush[i][1] &&
                localPipeReg[i][0].valid &&
                !localPipeReg[i][0].regValid;
            scheduler.complexRecordData[i] =
                localPipeReg[i][0].complexQueueData;
        end
    end


`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath  fuVecOpA    [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  fuVecOpB    [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  vecDataOut  [ COMPLEX_ISSUE_WIDTH ];

    //
    // VectorAdder
    //
    VectorPath vecAddDataOut [ COMPLEX_ISSUE_WIDTH ];
    for ( genvar i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin : BlockVecAdd
        PipelinedVectorAdder #(
            .PIPELINE_DEPTH( COMPLEX_EXEC_STAGE_DEPTH )
        ) vecAdder (
            .clk( port.clk ),
            .stall( stall ),
            .fuOpA_In( fuVecOpA[i].data ),
            .fuOpB_In( fuVecOpB[i].data ),
            .dataOut( vecAddDataOut[i] )
        );
    end

    //
    // VectorMultiplier
    //
    VectorPath vecMulDataOut [ COMPLEX_ISSUE_WIDTH ];
    for ( genvar i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin : BlockVecMul
        PipelinedVectorMultiplier #(
            .PIPELINE_DEPTH( COMPLEX_EXEC_STAGE_DEPTH )
        ) vecMul (
            .clk( port.clk ),
            .stall( stall ),
            .getUpper( FALSE ),
            .mulCode( AC_MUL ),
            .fuOpA_In( fuVecOpA[i].data ),
            .fuOpB_In( fuVecOpB[i].data ),
            .dataOut( vecMulDataOut[i] )
        );
    end

    always_comb begin
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            fuVecOpA[i] = ( pipeReg[i].bCtrl.rA.valid ? bypass.complexSrcVecDataOutA[i] : pipeReg[i].vecOperandA );
            fuVecOpB[i] = ( pipeReg[i].bCtrl.rB.valid ? bypass.complexSrcVecDataOutB[i] : pipeReg[i].vecOperandB );

            if ( iqData[i][0].opDst.phyDstRegNum.isVector ) begin
                // ベクタ演算
                regValid[i] =
                    fuVecOpA[i].valid &&
                    fuVecOpB[i].valid;
            end
            else begin
                // ベクタ以外の演算
                regValid[i] =
                    fuOpA[i].valid &&
                    fuOpB[i].valid;
            end
            vecDataOut[i].valid
                = localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].regValid;

            unique case ( localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].complexQueueData.opType )
            COMPLEX_MOP_TYPE_VEC_ADD: vecDataOut[i].data = vecAddDataOut[i];
            default: /* vec mul */    vecDataOut[i].data = vecMulDataOut[i];
            endcase
            bypass.complexDstVecDataOut[i] = vecDataOut[i];
        end
    end
`endif


    //
    // --- Pipeline レジスタ書き込み
    //
    ComplexIntegerRegisterWriteStageRegPath nextStage [ COMPLEX_ISSUE_WIDTH ];

    always_comb begin
        // Local Pipeline Register
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextLocalPipeReg[i][0].opId = pipeReg[i].opId;
`endif

            nextLocalPipeReg[i][0].valid = flush[i][0] ? FALSE : pipeReg[i].valid;
            nextLocalPipeReg[i][0].complexQueueData = pipeReg[i].complexQueueData;

            // Regvalid of local pipeline 
            if (isDiv[i]) begin
                nextLocalPipeReg[i][0].regValid = 
                    pipeReg[i].replay && (mulDivUnit.divFinished[i]);
            end
            else begin
                nextLocalPipeReg[i][0].regValid = regValid[i];
            end
            

            for (int j = 1; j < COMPLEX_EXEC_STAGE_DEPTH-1; j++) begin
`ifndef RSD_DISABLE_DEBUG_REGISTER
                nextLocalPipeReg[i][j].opId = localPipeReg[i][j-1].opId;
`endif 
                nextLocalPipeReg[i][j].valid = flush[i][j] ? FALSE : localPipeReg[i][j-1].valid;
                nextLocalPipeReg[i][j].regValid = localPipeReg[i][j-1].regValid; 
                nextLocalPipeReg[i][j].complexQueueData = localPipeReg[i][j-1].complexQueueData;
            end 
        end

        // To ComplexIntegerRegisterWriteStage
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId
                = localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].opId;
`endif

            nextStage[i].complexQueueData
                = localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].complexQueueData;

            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i][COMPLEX_EXEC_STAGE_DEPTH-1]) ? FALSE : localPipeReg[i][COMPLEX_EXEC_STAGE_DEPTH-2].valid;

            nextStage[i].dataOut = dataOut[i];
`ifdef RSD_ENABLE_VECTOR_PATH
            nextStage[i].vecDataOut = vecDataOut[i];
`endif
        end

        port.nextStage = nextStage;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            debug.complexExReg[i].valid[0] = pipeReg[i].valid;
            debug.complexExReg[i].flush[0] = flush[i][0];
            debug.complexExReg[i].opId[0] = pipeReg[i].opId;
            for ( int j = 1; j < COMPLEX_EXEC_STAGE_DEPTH; j++ ) begin
                debug.complexExReg[i].valid[j] = localPipeReg[i][j-1].valid;
                debug.complexExReg[i].opId[j] = localPipeReg[i][j-1].opId;
                debug.complexExReg[i].flush[j] = flush[i][j];
            end
`ifdef RSD_FUNCTIONAL_SIMULATION
            debug.complexExReg[i].dataOut = dataOut[i];
            debug.complexExReg[i].fuOpA   = fuOpA[i];
            debug.complexExReg[i].fuOpB   = fuOpB[i];

`ifdef RSD_ENABLE_VECTOR_PATH
            debug.complexExReg[i].vecDataOut = vecDataOut[i];
            debug.complexExReg[i].fuVecOpA = fuVecOpA[i];
            debug.complexExReg[i].fuVecOpB = fuVecOpB[i];
`endif

`endif  // `ifdef RSD_FUNCTIONAL_SIMULATION
        end //for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
`endif
end

endmodule : ComplexIntegerExecutionStage

`endif
// ---- Pipeline/ComplexIntegerBackEnd/ComplexIntegerRegisterWriteStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Complex Integer Write back stage
//

import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE

module ComplexIntegerRegisterWriteStage(
    ComplexIntegerExecutionStageIF.NextStage prev,
    RegisterFileIF.ComplexIntegerRegisterWriteStage registerFile,
    ActiveListIF.ComplexIntegerRegisterWriteStage activeList,
    RecoveryManagerIF.ComplexIntegerRegisterWriteStage recovery,
    ControllerIF.ComplexIntegerRegisterWriteStage ctrl,
    DebugIF.ComplexIntegerRegisterWriteStage debug
);
    ComplexIntegerRegisterWriteStageRegPath pipeReg[COMPLEX_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif
    // --- Pipeline registers
    always_ff@(posedge ctrl.clk)   // synchronous rst
    begin
        if (ctrl.rst) begin
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin    // write data
            pipeReg <= prev.nextStage;
        end
    end

    ActiveListWriteData alWriteData[COMPLEX_ISSUE_WIDTH];
    IntIssueQueueEntry iqData[COMPLEX_ISSUE_WIDTH];
    logic stall, clear;
    logic flush[ COMPLEX_ISSUE_WIDTH ];
    logic update [ COMPLEX_ISSUE_WIDTH ];
    logic valid [ COMPLEX_ISSUE_WIDTH ];
    logic regValid [ COMPLEX_ISSUE_WIDTH ];

    always_comb begin

        // Pipeline controll
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            iqData[i] = pipeReg[i].complexQueueData;
            regValid[i] = pipeReg[i].dataOut.valid;

            valid[i] = pipeReg[i].valid;
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        iqData[i].activeListPtr
                        );
            update[i] = !stall && !clear && valid[i] && !flush[i];


            //
            // Register file
            //

            registerFile.complexDstRegWE[i] =
                update[i] && iqData[i].opDst.writeReg;

            registerFile.complexDstRegNum[i] = iqData[i].opDst.phyDstRegNum;
            registerFile.complexDstRegData[i] = pipeReg[i].dataOut;
`ifdef RSD_ENABLE_VECTOR_PATH
            registerFile.complexDstVecData[i] = pipeReg[i].vecDataOut;
`endif
            //
            // Active list
            //
            alWriteData[i].ptr = iqData[i].activeListPtr;
            alWriteData[i].loadQueuePtr = iqData[i].loadQueueRecoveryPtr;
            alWriteData[i].storeQueuePtr = iqData[i].storeQueueRecoveryPtr;
            alWriteData[i].ptr = iqData[i].activeListPtr;
            alWriteData[i].pc = iqData[i].pc;
            alWriteData[i].dataAddr = '0;
            alWriteData[i].isBranch = FALSE;
            alWriteData[i].isStore = FALSE;

            // ExecState
            if ( update[i] && regValid[i] ) begin
                alWriteData[i].state = EXEC_STATE_SUCCESS;
            end
            else begin
                alWriteData[i].state = EXEC_STATE_NOT_FINISHED;
            end

            activeList.complexWrite[i] = update[i];
            activeList.complexWriteData[i] = alWriteData[i];
        end

        // Debug Register
        `ifndef RSD_DISABLE_DEBUG_REGISTER
            for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
                debug.complexRwReg[i].valid = valid[i];
                debug.complexRwReg[i].flush = flush[i];
                debug.complexRwReg[i].opId = pipeReg[i].opId;
            end
        `endif
    end
endmodule : ComplexIntegerRegisterWriteStage

`endif
// ---- Pipeline/MemoryBackEnd/MemoryIssueStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for issuing ops.
//


import BasicTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;

module MemoryIssueStage(
    MemoryIssueStageIF.ThisStage port,
    ScheduleStageIF.MemNextStage prev,
    SchedulerIF.MemoryIssueStage scheduler,
    RecoveryManagerIF.MemoryIssueStage recovery,
    MulDivUnitIF.MemoryIssueStage mulDivUnit,
    ControllerIF.MemoryIssueStage ctrl,
    DebugIF.MemoryIssueStage debug
);

    // --- Pipeline registers
    IssueStageRegPath pipeReg [ MEM_ISSUE_WIDTH ];
    IssueStageRegPath nextPipeReg [ MEM_ISSUE_WIDTH ];
    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if ( port.rst ) begin
            for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ )
                pipeReg[i] <= '0;
        end
        else if( !ctrl.isStage.stall )              // write data
            pipeReg <= prev.memNextStage;
        else
            pipeReg <= nextPipeReg;
    end

    always_comb begin
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            if (recovery.toRecoveryPhase) begin
                nextPipeReg[i].valid = 
                    pipeReg[i].valid &&
                    !SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        scheduler.memIssuedData[i].activeListPtr
                    );
            end
            else begin
                nextPipeReg[i].valid = pipeReg[i].valid;
            end
            
            nextPipeReg[i].issueQueuePtr = pipeReg[i].issueQueuePtr;
        end
    end



    // Pipeline controll
    logic stall, clear;
    logic flush[ MEM_ISSUE_WIDTH ];
    logic valid [ MEM_ISSUE_WIDTH ];
    MemoryRegisterReadStageRegPath nextStage [ MEM_ISSUE_WIDTH ];
    MemIssueQueueEntry issuedData [ MEM_ISSUE_WIDTH ];
    IssueQueueIndexPath issueQueuePtr [ MEM_ISSUE_WIDTH ];

    always_comb begin

        stall = ctrl.isStage.stall;
        clear = ctrl.isStage.clear;

        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin

            if (scheduler.replay) begin
                issuedData[i] = scheduler.memReplayData[i];
                valid[i] = scheduler.memReplayEntry[i];
            end
            else begin
                issuedData[i] = scheduler.memIssuedData[i];
                valid[i] = !stall && pipeReg[i].valid;
            end

            issueQueuePtr[i] = pipeReg[i].issueQueuePtr;

            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        issuedData[i].activeListPtr
                        );

            // Issue
            scheduler.memIssue[i] = !clear && valid[i] && !flush[i];
            scheduler.memIssuePtr[i] = issueQueuePtr[i];

            // Release the entries of the issue queue.
            nextStage[i].replay = scheduler.replay;
            nextStage[i].issueQueuePtr = issueQueuePtr[i];

            // --- Pipeline ラッチ書き込み
            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (clear || port.rst || flush[i]) ? FALSE : valid[i];
            nextStage[i].memQueueData = issuedData[i];
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = issuedData[i].opId;
`endif
        end

`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin
            // Lock div units
            mulDivUnit.divAcquire[i] = 
                !clear && valid[i] && !flush[i] && 
                issuedData[i].memOpInfo.opType == MEM_MOP_TYPE_DIV;
            mulDivUnit.divResetFromMI_Stage[i] = 
                valid[i] && (flush[i] || clear) &&
                issuedData[i].memOpInfo.opType == MEM_MOP_TYPE_DIV;
        end
`endif
        port.nextStage = nextStage;

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // Debug Register
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            debug.memIsReg[i].valid = valid[i];
            debug.memIsReg[i].flush = flush[i];
            debug.memIsReg[i].opId = issuedData[i].opId;
        end
`endif
    end


endmodule : MemoryIssueStage
// ---- Pipeline/MemoryBackEnd/MemoryIssueStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- MemoryIssueStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface MemoryIssueStageIF( input logic clk, rst );
    
    // Pipeline register
    MemoryRegisterReadStageRegPath nextStage [ MEM_ISSUE_WIDTH ];
    
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );

endinterface : MemoryIssueStageIF




// ---- Pipeline/MemoryBackEnd/MemoryRegisterReadStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A pipeline stage for register read.
//


import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import CacheSystemTypes::*;
import PipelineTypes::*;
import DebugTypes::*;

//
// --- オペランドの選択
//
function automatic DataPath SelectOperand(
input
    OpOperandType opType, DataPath regV, DataPath immV, DataPath pcV
);
    case( opType )
    default:    // OOT_REG
        return regV;
    OOT_IMM:
        return immV;
    OOT_PC:
        return pcV;
    endcase
endfunction

//
// --- Memory Register Read Stage
//
module MemoryRegisterReadStage(
    MemoryRegisterReadStageIF.ThisStage port,
    MemoryIssueStageIF.NextStage prev,
    LoadStoreUnitIF.MemoryRegisterReadStage loadStoreUnit,
    MulDivUnitIF.MemoryRegisterReadStage mulDivUnit,
    RegisterFileIF.MemoryRegisterReadStage registerFile,
    BypassNetworkIF.MemoryRegisterReadStage bypass,
    RecoveryManagerIF.MemoryRegisterReadStage recovery,
    ControllerIF.MemoryRegisterReadStage ctrl,
    DebugIF.MemoryRegisterReadStage debug
);

    // --- Pipeline registers
    MemoryRegisterReadStageRegPath pipeReg [MEM_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if (!ctrl.backEnd.stall) begin             // write data
            pipeReg <= prev.nextStage;
        end
    end


    // Operand
    DataPath immOut [ MEM_ISSUE_WIDTH ];
    AddrPath pc [ MEM_ISSUE_WIDTH ];
    PRegDataPath operandA [ MEM_ISSUE_WIDTH ];
    PRegDataPath operandB [ MEM_ISSUE_WIDTH ];

    // Pipeline controll
    logic stall, clear;
    logic flush[ MEM_ISSUE_WIDTH ];
    MemIssueQueueEntry iqData[MEM_ISSUE_WIDTH];
    MemOpInfo memOpInfo[MEM_ISSUE_WIDTH];
    OpSrc opSrc[MEM_ISSUE_WIDTH];
    OpDst opDst[MEM_ISSUE_WIDTH];
    MemoryExecutionStageRegPath nextStage [MEM_ISSUE_WIDTH];
    MSHR_IndexPath mshrID;

    logic makeMSHRCanBeInvalid[LOAD_ISSUE_WIDTH];
    logic isLoad[LOAD_ISSUE_WIDTH];

    always_comb begin
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            iqData[i] = pipeReg[i].memQueueData;
            memOpInfo[i] = iqData[i].memOpInfo;
            opSrc[i] = iqData[i].opSrc;
            opDst[i] = iqData[i].opDst;
            pc[i] = iqData[i].pc;

            //
            // Register file
            //

            registerFile.memSrcRegNumA[i] = opSrc[i].phySrcRegNumA;
            registerFile.memSrcRegNumB[i] = opSrc[i].phySrcRegNumB;


            //
            // To a bypass network.
            // ストールやフラッシュの制御は，Bypass モジュールの内部で
            // コントローラの信号を参照して行われている
            //
            bypass.memPhySrcRegNumA[i] = opSrc[i].phySrcRegNumA;
            bypass.memPhySrcRegNumB[i] = opSrc[i].phySrcRegNumB;

            bypass.memWriteReg[i]  = opDst[i].writeReg & pipeReg[i].valid;
            bypass.memPhyDstRegNum[i] = opDst[i].phyDstRegNum;
            bypass.memReadRegA[i] = ( memOpInfo[i].operandTypeA == OOT_REG );
            bypass.memReadRegB[i] = ( memOpInfo[i].operandTypeB == OOT_REG );

            //
            // --- オペランド選択
            //
            immOut[i] = '0; //RISCVにおいて即値をオペランドにとるようなロード/ストアはない(アドレス計算はExecutionStage)
            operandA[i].data = SelectOperand(
                memOpInfo[i].operandTypeA,
                registerFile.memSrcRegDataA[i].data,
                immOut[i],
                pc[i]
            );
            operandB[i].data = SelectOperand(
                memOpInfo[i].operandTypeB,
                registerFile.memSrcRegDataB[i].data,
                immOut[i],
                pc[i]
            );
            operandA[i].valid = (memOpInfo[i].operandTypeA != OOT_REG || registerFile.memSrcRegDataA[i].valid);
            operandB[i].valid = (memOpInfo[i].operandTypeB != OOT_REG || registerFile.memSrcRegDataB[i].valid);

            //
            // --- Pipeline ラッチ書き込み
            //
            `ifndef RSD_DISABLE_DEBUG_REGISTER
                nextStage[i].opId = pipeReg[i].opId;
            `endif


            // リセットorフラッシュ時はNOP
            flush[i] = SelectiveFlushDetector(
                recovery.toRecoveryPhase,
                recovery.flushRangeHeadPtr,
                recovery.flushRangeTailPtr,
                iqData[i].activeListPtr
            );
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : pipeReg[i].valid;

            nextStage[i].memQueueData = pipeReg[i].memQueueData;

            // レジスタ値&フラグ
            nextStage[i].operandA = operandA[i];
            nextStage[i].operandB = operandB[i];

            // バイパス制御
            nextStage[i].bCtrl = bypass.memCtrlOut[i];

            // Release the entries of the issue queue.
            nextStage[i].replay = pipeReg[i].replay && pipeReg[i].valid;
            nextStage[i].issueQueuePtr = pipeReg[i].issueQueuePtr;
        end

        `ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            // divがこのステージ内でフラッシュされた場合，演算器を解放する
            for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin
                mulDivUnit.divResetFromMR_Stage[i] = 
                    (memOpInfo[i].opType == MEM_MOP_TYPE_DIV) &&
                    pipeReg[i].valid && flush[i];
            end
        `endif

        // Vector Operand
`ifdef RSD_ENABLE_VECTOR_PATH
        `RSD_STATIC_ASSERT(FALSE, "TODO: ls/st unified pipeline");
        for ( int i = 0; i < STORE_ISSUE_LANE_BEGIN; i++ ) begin
            nextStage[i].vecOperandB = '0;
        end
        for ( int i = 0; i < STORE_ISSUE_WIDTH; i++ ) begin
            nextStage[i+STORE_ISSUE_LANE_BEGIN].vecOperandB = registerFile.memSrcVecDataB[i];
        end
`endif
        port.nextStage = nextStage;

        //フラッシュによってMSHRをアロケートしたロード命令がフラッシュされる場合のMSHRの解放処理
        for (int i = 0; i < MSHR_NUM; i++) begin
            loadStoreUnit.makeMSHRCanBeInvalidByMemoryRegisterReadStage[i] = FALSE;
        end


        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            isLoad[i] = pipeReg[i].memQueueData.memOpInfo.opType == MEM_MOP_TYPE_LOAD;
            if (pipeReg[i].valid && isLoad[i] && flush[i]) begin
                makeMSHRCanBeInvalid[i] = pipeReg[i].memQueueData.memOpInfo.hasAllocatedMSHR;
            end
            else begin
                makeMSHRCanBeInvalid[i] = FALSE;
            end

            mshrID = pipeReg[i].memQueueData.memOpInfo.mshrID;
            if (makeMSHRCanBeInvalid[i]) begin
                loadStoreUnit.makeMSHRCanBeInvalidByMemoryRegisterReadStage[mshrID] = TRUE;
            end
        end

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            debug.memRrReg[i].valid = pipeReg[i].valid;
            debug.memRrReg[i].flush = flush[i];
            debug.memRrReg[i].opId = pipeReg[i].opId;
        end
`endif
    end
endmodule : MemoryRegisterReadStage
// ---- Pipeline/MemoryBackEnd/MemoryRegisterReadStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- FetchPipeIF
//

import BasicTypes::*;
import BypassTypes::*;
import PipelineTypes::*;


interface MemoryRegisterReadStageIF( input logic clk, rst );
    
    // Pipeline register
    MemoryExecutionStageRegPath nextStage [ MEM_ISSUE_WIDTH ];
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );

endinterface : MemoryRegisterReadStageIF




// ---- Pipeline/MemoryBackEnd/MemoryExecutionStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- MemoryExecutionStageIF
//

import BasicTypes::*;
import BypassTypes::*;
import OpFormatTypes::*;
import PipelineTypes::*;


interface MemoryExecutionStageIF( input logic clk, rst );

    // Pipeline register
    MemoryTagAccessStageRegPath nextStage[MEM_ISSUE_WIDTH];
    
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );

    modport NextStage(
    input
        nextStage
    );
endinterface : MemoryExecutionStageIF




// ---- Pipeline/MemoryBackEnd/MemoryExecutionStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Execution stage
//


import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import DebugTypes::*;
import MemoryMapTypes::*;


//
// 実行ステージ
//

module MemoryExecutionStage(
    MemoryExecutionStageIF.ThisStage port,
    MemoryRegisterReadStageIF.NextStage prev,
    LoadStoreUnitIF.MemoryExecutionStage loadStoreUnit,
    MulDivUnitIF.MemoryExecutionStage mulDivUnit,
    BypassNetworkIF.MemoryExecutionStage bypass,
    RecoveryManagerIF.MemoryExecutionStage recovery,
    ControllerIF.MemoryExecutionStage ctrl,
    CSR_UnitIF.MemoryExecutionStage csrUnit,
    DebugIF.MemoryExecutionStage debug
);

    MemoryExecutionStageRegPath pipeReg[MEM_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    // --- Pipeline registers
    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin              // write data
            pipeReg <= prev.nextStage;
        end
    end


    // Pipeline controll
    logic stall, clear;
    logic flush[ MEM_ISSUE_WIDTH ];

    MemIssueQueueEntry iqData[MEM_ISSUE_WIDTH];
    MemOpInfo memOpInfo  [ MEM_ISSUE_WIDTH ];

    PRegDataPath  fuOpA  [ MEM_ISSUE_WIDTH ];
    PRegDataPath  fuOpB  [ MEM_ISSUE_WIDTH ];

    // Valid bits of registers
    logic regValid[MEM_ISSUE_WIDTH];

`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath  fuVecOpB [ MEM_ISSUE_WIDTH ];
    logic vecRegValid[MEM_ISSUE_WIDTH];
`endif

    AddrPath addrOut[ MEM_ISSUE_WIDTH ];
    MemoryMapType memMapType[MEM_ISSUE_WIDTH];
    PhyAddrPath phyAddrOut[MEM_ISSUE_WIDTH];

    // MSHRをAllocateした命令からのメモリリクエストかどうか
    // そのリクエストがアクセスに成功した場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalid[LOAD_ISSUE_WIDTH];

    always_comb begin
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            makeMSHRCanBeInvalid[i] = 
                pipeReg[i].memQueueData.memOpInfo.hasAllocatedMSHR;
        end

        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            iqData[i] = pipeReg[i].memQueueData;
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase,
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        iqData[i].activeListPtr
                        );
            memOpInfo[i]  = iqData[i].memOpInfo;

      
            // オペランド
            fuOpA[i] = ( pipeReg[i].bCtrl.rA.valid ? bypass.memSrcRegDataOutA[i] : pipeReg[i].operandA );
            fuOpB[i] = ( pipeReg[i].bCtrl.rB.valid ? bypass.memSrcRegDataOutB[i] : pipeReg[i].operandB );

            // Address unit
            addrOut[i] = fuOpA[i].data + { {ADDR_SIGN_EXTENTION_WIDTH{memOpInfo[i].addrIn[ADDR_OPERAND_IMM_WIDTH-1]}}, memOpInfo[i].addrIn };
            phyAddrOut[i] = ToPhyAddrFromLogical(addrOut[i]);
            memMapType[i] = GetMemoryMapType(addrOut[i]);


            // --- Bypass
            // 制御
            bypass.memCtrlIn[i] = pipeReg[i].bCtrl;


            // Register valid bits.
            // If invalid regisers are read, regValid is negated and this op must be replayed.
            `ifdef RSD_ENABLE_VECTOR_PATH
                if ( memOpInfo[i].memAccessMode.size == MEM_ACCESS_SIZE_VEC ) begin
                    regValid[i] = vecRegValid[i];
                end
                else begin
                    regValid[i] =
                        (memOpInfo[i].operandTypeA != OOT_REG || fuOpA[i].valid ) &&
                        (memOpInfo[i].operandTypeB != OOT_REG || fuOpB[i].valid );
                end
            `else
                regValid[i] =
                    (memOpInfo[i].operandTypeA != OOT_REG || fuOpA[i].valid ) &&
                    (memOpInfo[i].operandTypeB != OOT_REG || fuOpB[i].valid );
            `endif

        end // for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            // --- DCache access
            // TODO: メモリマップが MMT_MEMORY じゃなかったとしても，一度 MSHR を確保して
            // しまった場合にはデータを受け取らないと行けないので，とりあえずどんな
            // 領域にアクセスをするとしても DC からデータを拾うようにしておく
            loadStoreUnit.dcReadReq[i] =
                !stall && !clear && pipeReg[i].valid && regValid[i] && !flush[i] &&
                (memOpInfo[i].opType inside { MEM_MOP_TYPE_LOAD });

            //loadStoreUnit.dcReadAddr[i] = addrOut[i];
            loadStoreUnit.dcReadAddr[i] = phyAddrOut[i];

            // To notify MSHR that the requester is its allocator load.
            loadStoreUnit.makeMSHRCanBeInvalid[i] = makeMSHRCanBeInvalid[i];
        end
    end

    //
    // --- Vector Operand
    //
`ifdef RSD_ENABLE_VECTOR_PATH
    always_comb begin
        for ( int i = 0; i < STORE_ISSUE_LANE_BEGIN; i++ ) begin
            fuVecOpB[i] = '0;
            vecRegValid[i] =
                (memOpInfo[i].operandTypeA != OOT_REG || fuOpA[i].valid );
        end
        for ( int i = 0; i < STORE_ISSUE_WIDTH; i++ ) begin
            fuVecOpB[i+STORE_ISSUE_LANE_BEGIN] = ( pipeReg[i+STORE_ISSUE_LANE_BEGIN].bCtrl.rB.valid ? bypass.memSrcVecDataOutB[i] : pipeReg[i+STORE_ISSUE_LANE_BEGIN].vecOperandB );
            vecRegValid[i+STORE_ISSUE_LANE_BEGIN] =
                (memOpInfo[i+STORE_ISSUE_LANE_BEGIN].operandTypeA != OOT_REG || fuOpA[i+STORE_ISSUE_LANE_BEGIN].valid ) &&
                fuVecOpB[i+STORE_ISSUE_LANE_BEGIN].valid;
        end
    end
`endif

    // CSR access
    generate
        // Since a CSR op is serialized, so multiple CSR ops are not issued.
        for (genvar i = 1; i < MEM_ISSUE_WIDTH; i++) begin : assertionBlock
            `RSD_ASSERT_CLK(
                port.clk, 
                !(memOpInfo[i].opType inside {
                    MEM_MOP_TYPE_CSR, MEM_MOP_TYPE_FENCE, MEM_MOP_TYPE_ENV
                } && pipeReg[i].valid),
                "A CSR/FENCE/ENV op was issued to a lane other than 0."
            );
        end
    endgenerate

    logic isCSR;
    always_comb begin   // CSR must be issued to the lane 0;
        isCSR = memOpInfo[0].opType == MEM_MOP_TYPE_CSR;

        // CSR request
        csrUnit.csrWE = pipeReg[0].valid && isCSR;
        csrUnit.csrNumber = memOpInfo[0].addrIn;
        csrUnit.csrWriteIn = 
            memOpInfo[0].csrCtrl.isImm ? memOpInfo[0].csrCtrl.imm : pipeReg[0].operandA;
        csrUnit.csrCode = memOpInfo[0].csrCtrl.code;
    end

    //
    // MulDiv
    //
`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    logic isDiv         [ MULDIV_ISSUE_WIDTH ]; 
    logic finished      [ MULDIV_ISSUE_WIDTH ];

    // For selective flush
    ActiveListIndexPath regActiveListIndex  [ MULDIV_ISSUE_WIDTH ];
    ActiveListIndexPath nextActiveListIndex [ MULDIV_ISSUE_WIDTH ];
    logic divReset[ MULDIV_ISSUE_WIDTH ];

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin
                regActiveListIndex[i] <= '0;
            end
        end
        else begin
            regActiveListIndex <= nextActiveListIndex;
        end
    end

    MulOpSubInfo mulSubInfo[MULDIV_ISSUE_WIDTH];
    DivOpSubInfo divSubInfo[MULDIV_ISSUE_WIDTH];
    always_comb begin

        for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin
            mulDivUnit.dataInA[i] = fuOpA[i].data;
            mulDivUnit.dataInB[i] = fuOpB[i].data;

            // MUL
            mulSubInfo[i]  = memOpInfo[i].mulSubInfo;
            divSubInfo[i]  = memOpInfo[i].divSubInfo;
            mulDivUnit.mulGetUpper[i] = mulSubInfo[i].mulGetUpper;
            mulDivUnit.mulCode[i] = mulSubInfo[i].mulCode;

            // DIV
            mulDivUnit.divCode[i] = divSubInfo[i].divCode;

            isDiv[i] =  
                memOpInfo[i].opType inside {MEM_MOP_TYPE_DIV};

            // Dividerで処理中のdivがフラッシュされたら，Dividerの状態をFREEに変更して
            // IQからdivを発行できるようにする
            divReset[i] = FALSE;
            if (recovery.toRecoveryPhase) begin
                divReset[i] = SelectiveFlushDetector( 
                    recovery.toRecoveryPhase, 
                    recovery.flushRangeHeadPtr, 
                    recovery.flushRangeTailPtr, 
                    regActiveListIndex[i]
                );
            end
            if (clear) begin
                divReset[i] = TRUE;
            end
            if (isDiv[i] && flush[i]) begin
                // Div is flushed at register read stage, so release the divider
                divReset[i] = TRUE;
            end
            mulDivUnit.divReset[i] = divReset[i];

            // Request to the divider
            // NOT make a request when below situation
            // 1) When any operands of inst. are invalid
            // 2) When the divider is waiting for the instruction
            //    to receive the result of the divider
            mulDivUnit.divReq[i] = 
                mulDivUnit.divReserved[i] && 
                pipeReg[i].valid && isDiv[i] && 
                fuOpA[i].valid && fuOpB[i].valid;


            if (pipeReg[i].valid && isDiv[i] && mulDivUnit.divReserved[i]) begin
                nextActiveListIndex[i] = 
                    iqData[i].activeListPtr;
            end
            else begin
                nextActiveListIndex[i] = regActiveListIndex[i];
            end

        end

    end


`endif



    //
    // --- Pipeline レジスタ書き込み
    //
    MemoryTagAccessStageRegPath nextStage [ MEM_ISSUE_WIDTH ];

    always_comb begin
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            nextStage[i].memQueueData = pipeReg[i].memQueueData;

            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : pipeReg[i].valid;
            nextStage[i].condEnabled = TRUE;
            nextStage[i].dataIn = (i == 0 && isCSR) ? csrUnit.csrReadOut : fuOpB[i].data;   // CSR must be issued to the lane 0
            `ifdef RSD_ENABLE_VECTOR_PATH
                nextStage[i].vecDataIn = fuVecOpB[i].data;
            `endif
            nextStage[i].addrOut = addrOut[i];
            nextStage[i].regValid = regValid[i];
            nextStage[i].memMapType = memMapType[i];
            nextStage[i].phyAddrOut = phyAddrOut[i];
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = pipeReg[i].opId;
`endif
        end

        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            if (makeMSHRCanBeInvalid[i]) begin
                nextStage[i].memQueueData.memOpInfo.hasAllocatedMSHR = FALSE;
            end
        end
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            nextStage[i+STORE_ISSUE_LANE_BEGIN].memQueueData.memOpInfo.hasAllocatedMSHR = FALSE;
        end


        // Output
        port.nextStage = nextStage;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            debug.memExReg[i].valid = pipeReg[i].valid;
            debug.memExReg[i].flush = flush[i];
            debug.memExReg[i].opId = pipeReg[i].opId;
`ifdef RSD_FUNCTIONAL_SIMULATION
            if (isCSR && i == 0) begin  // Special case for CSR
                debug.memExReg[i].addrOut = csrUnit.csrReadOut;
                debug.memExReg[i].fuOpA   = memOpInfo[0].addrIn;
                debug.memExReg[i].fuOpB   = memOpInfo[0].csrCtrl.isImm ? memOpInfo[0].csrCtrl.imm : pipeReg[0].operandA;
            end
            else begin
                debug.memExReg[i].addrOut = addrOut[i];
                debug.memExReg[i].fuOpA   = fuOpA[i].data;
                debug.memExReg[i].fuOpB   = fuOpB[i].data;
            end
            `ifdef RSD_ENABLE_VECTOR_PATH
                debug.memExReg[i].fuVecOpB = fuVecOpB[i].data;
            `endif
            debug.memExReg[i].opType = memOpInfo[i].opType;
            debug.memExReg[i].size = memOpInfo[i].memAccessMode.size;
            debug.memExReg[i].isSigned = memOpInfo[i].memAccessMode.isSigned;
`endif
        end
`endif
    end

endmodule : MemoryExecutionStage
// ---- Pipeline/MemoryBackEnd/MemoryAccessStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- RegisterWritePipeIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface MemoryAccessStageIF( input logic clk, rst );

    // Pipeline register
    MemoryRegisterWriteStageRegPath nextStage[MEM_ISSUE_WIDTH];
    
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );
    
    modport NextStage(
    input
        nextStage
    );

endinterface : MemoryAccessStageIF




// ---- Pipeline/MemoryBackEnd/MemoryAccessStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Memory access stage
//


import BasicTypes::*;
import OpFormatTypes::*;
import RenameLogicTypes::*;
import PipelineTypes::*;
import DebugTypes::*;
import MicroOpTypes::*;
import MemoryMapTypes::*;

module MemoryAccessStage(
    MemoryAccessStageIF.ThisStage port,
    MemoryTagAccessStageIF.NextStage prev,
    LoadStoreUnitIF.MemoryAccessStage loadStoreUnit,
    MulDivUnitIF.MemoryAccessStage mulDivUnit,
    BypassNetworkIF.MemoryAccessStage bypass,
    IO_UnitIF.MemoryAccessStage ioUnit,
    RecoveryManagerIF.MemoryAccessStage recovery,
    ControllerIF.MemoryAccessStage ctrl,
    DebugIF.MemoryAccessStage debug
);

    MemoryAccessStageRegPath pipeReg[MEM_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    // --- Pipeline registers
    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin              // write data
            pipeReg <= prev.nextStage;
        end
    end



    logic isStore  [ MEM_ISSUE_WIDTH ];
    logic isLoad  [ MEM_ISSUE_WIDTH ];
    logic isCSR   [ MEM_ISSUE_WIDTH ];
    logic isDiv   [ MEM_ISSUE_WIDTH ];
    logic isMul   [ MEM_ISSUE_WIDTH ];


    logic valid   [ MEM_ISSUE_WIDTH ];
    logic update  [ MEM_ISSUE_WIDTH ];

    logic regValid[ MEM_ISSUE_WIDTH ];

    // Pipeline controll
    logic stall, clear;
    logic flush[ MEM_ISSUE_WIDTH ];
    MemoryRegisterWriteStageRegPath nextStage [ MEM_ISSUE_WIDTH ];

    PRegDataPath  dataOut[MEM_ISSUE_WIDTH];
    PRegDataPath  ldDataOut[LOAD_ISSUE_WIDTH];
    PRegDataPath  stDataOut[STORE_ISSUE_WIDTH];
    PVecDataPath  vecDataOut[MEM_ISSUE_WIDTH];

    always_comb begin
        
        // Pipeline controll
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            valid[i]   = pipeReg[i].valid;
            flush[i] = SelectiveFlushDetector(
                            recovery.toRecoveryPhase,
                            recovery.flushRangeHeadPtr,
                            recovery.flushRangeTailPtr,
                            pipeReg[i].activeListPtr
                        );
            isStore[i] = pipeReg[i].isStore;
            isLoad[i]  = pipeReg[i].isLoad;
            isCSR[i]   = pipeReg[i].isCSR;
            isDiv[i]   = pipeReg[i].isDiv;
            isMul[i]   = pipeReg[i].isMul;
            update[i]  = pipeReg[i].valid && !stall && !clear && !flush[i];
            regValid[i] = pipeReg[i].regValid;
        end

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            if (i == 0) begin
                ioUnit.ioReadAddrIn = pipeReg[i].phyAddrOut;
            end

            if (isLoad[i]) begin
                if (i == 0 && pipeReg[i].memMapType == MMT_IO) begin
                    ldDataOut[i].data = ioUnit.ioReadDataOut;
                end
                else begin
                    ldDataOut[i].data = loadStoreUnit.executedLoadData[i];
                end
            end
            else if (isCSR[i])
                ldDataOut[i].data = pipeReg[i].csrDataOut;
            else
                ldDataOut[i].data = pipeReg[i].addrOut;

            `ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                if (isDiv[i])
                    ldDataOut[i].data = mulDivUnit.divDataOut[i];
                else if (isMul[i])
                    ldDataOut[i].data = mulDivUnit.mulDataOut[i];

                if (mulDivUnit.divFinished[i] &&
                    update[i] &&
                    isDiv[i] && 
                    regValid[i]
                ) begin 
                    // Divが除算器から結果を取得できたので，
                    // IQからのdivの発行を許可する 
                    mulDivUnit.divRelease[i] = TRUE;
                end
                else begin
                    mulDivUnit.divRelease[i] = FALSE;
                end

            `endif


            ldDataOut[i].valid = regValid[i];
        end
        
        for ( int i = 0; i < STORE_ISSUE_WIDTH; i++ ) begin
            stDataOut[i].data = '0;
            stDataOut[i].valid = FALSE;
        end


        `ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
            for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
                dataOut[i] = isStore[i] ? stDataOut[i] : ldDataOut[i];
            end
        `else
            for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
                dataOut[i] = ldDataOut[i];
            end
            for ( int i = 0; i < STORE_ISSUE_WIDTH; i++ ) begin
                dataOut[i+STORE_ISSUE_LANE_BEGIN] = stDataOut[i];
            end
        `endif

        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin

`ifdef RSD_ENABLE_VECTOR_PATH
            vecDataOut[i].data = loadStoreUnit.executedLoadVectorData[i];
            vecDataOut[i].valid = regValid[i];
            nextStage[i].vecDataOut = vecDataOut[i];
`endif

            nextStage[i].dataOut = dataOut[i];
            bypass.memDstRegDataOut[i] = dataOut[i];    // Bypass

            // Pipeline レジスタ書き込み
`ifndef RSD_DISABLE_DEBUG_REGISTER
            nextStage[i].opId = pipeReg[i].opId;
`endif

            nextStage[i].opDst = pipeReg[i].opDst;

            nextStage[i].activeListPtr = pipeReg[i].activeListPtr;
            nextStage[i].loadQueueRecoveryPtr = pipeReg[i].loadQueueRecoveryPtr;
            nextStage[i].storeQueueRecoveryPtr = pipeReg[i].storeQueueRecoveryPtr;
            nextStage[i].execState = pipeReg[i].execState;
            nextStage[i].pc = pipeReg[i].pc;
            nextStage[i].addrOut = pipeReg[i].addrOut;
            nextStage[i].isStore = pipeReg[i].isStore;

            // リセットorフラッシュ時はNOP
            nextStage[i].valid =
                (stall || clear || port.rst || flush[i]) ? FALSE : pipeReg[i].valid;
        end


        // Vector Bypass
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            bypass.memDstVecDataOut[i] = vecDataOut[i];
`endif
        end


        port.nextStage = nextStage;

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            debug.maReg[i].valid = pipeReg[i].valid;
            debug.maReg[i].flush = flush[i];
            debug.maReg[i].opId = pipeReg[i].opId;
        end
`ifdef RSD_FUNCTIONAL_SIMULATION
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            debug.maReg[i].executeLoad       = update[i] && isLoad[i];
            debug.maReg[i].executedLoadData  = dataOut[i].data;
            debug.maReg[i].executedLoadVectorData = loadStoreUnit.executedLoadVectorData[i];
        end
`endif
`endif
    end

    generate 
        for (genvar i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            `RSD_ASSERT_CLK(
                port.clk, 
                !(isLoad[i] && valid[i] && !flush[i] && i != 0 && pipeReg[i].memMapType == MMT_IO),
                "IO access cane be accessed in the mem lane 0."
            );
        end
    endgenerate


endmodule : MemoryAccessStage
// ---- Pipeline/MemoryBackEnd/MemoryTagAccessStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- MemoryTagAccessStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface MemoryTagAccessStageIF(input logic clk, rst);

    // Pipeline register
    MemoryAccessStageRegPath nextStage[MEM_ISSUE_WIDTH];
    
    modport ThisStage(
    input
        clk,
        rst,
    output
        nextStage
    );
    
    modport NextStage(
    input
        nextStage
    );

endinterface : MemoryTagAccessStageIF




// ---- Pipeline/MemoryBackEnd/MemoryTagAccessStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Tag access stage
//


import BasicTypes::*;
import OpFormatTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import DebugTypes::*;
import MicroOpTypes::*;
import CacheSystemTypes::*;
import MemoryMapTypes::*;

// When this switch is enabled, instructions are re-issued from the issue queue.
// Otherwise, instructions are refetched.
`define RSD_ENABLE_REISSUE_ON_CACHE_MISS

// To a part of a line index from a full address.
function automatic DCacheIndexSubsetPath ToIndexSubsetPartFromFullAddrInMTStage(input AddrPath addr);
    return addr[DCACHE_LINE_BYTE_NUM_BIT_WIDTH+DCACHE_INDEX_SUBSET_BIT_WIDTH-1 : DCACHE_LINE_BYTE_NUM_BIT_WIDTH];
endfunction

module MemoryTagAccessStage(
    MemoryTagAccessStageIF.ThisStage port,
    MemoryExecutionStageIF.NextStage prev,
    SchedulerIF.MemoryTagAccessStage scheduler,
    LoadStoreUnitIF.MemoryTagAccessStage loadStoreUnit,
    MulDivUnitIF.MemoryTagAccessStage mulDivUnit,    
    RecoveryManagerIF.MemoryTagAccessStage recovery,
    ControllerIF.MemoryTagAccessStage ctrl,
    DebugIF.MemoryTagAccessStage debug,
    HardwareCounterIF.MemoryTagAccessStage hwCounter
);

    MemoryTagAccessStageRegPath pipeReg[MEM_ISSUE_WIDTH];
    MemoryTagAccessStageRegPath ldPipeReg[LOAD_ISSUE_WIDTH];
    MemoryTagAccessStageRegPath stPipeReg[STORE_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    // --- Pipeline registers
    always_ff@( posedge port.clk )   // synchronous rst
    begin
        if (port.rst) begin
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin              // write data
            pipeReg <= prev.nextStage;
        end
    end

    // Pipeline controll
    logic stall, clear;

    logic lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[MSHR_NUM];
    MSHR_IndexPath mshrID;

    MemIssueQueueEntry ldIqData[LOAD_ISSUE_WIDTH];
    MemIssueQueueEntry stIqData[STORE_ISSUE_WIDTH];

    always_comb begin
        // Pipeline controll
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;


        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            ldPipeReg[i] = pipeReg[i];
            ldIqData[i] = pipeReg[i].memQueueData;
        end
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            stPipeReg[i] = pipeReg[i + STORE_ISSUE_LANE_BEGIN];
            stIqData[i] = pipeReg[i + STORE_ISSUE_LANE_BEGIN].memQueueData;
        end

    end

    // Load pipe
    logic isLoad    [LOAD_ISSUE_WIDTH];
    logic isCSR     [LOAD_ISSUE_WIDTH];
    logic isENV     [LOAD_ISSUE_WIDTH];
    logic ldUpdate  [LOAD_ISSUE_WIDTH];
    logic ldRegValid[LOAD_ISSUE_WIDTH];
    logic ldFlush   [LOAD_ISSUE_WIDTH];
    logic isDiv     [LOAD_ISSUE_WIDTH];
    logic isMul     [LOAD_ISSUE_WIDTH];
    MemoryAccessStageRegPath ldNextStage[LOAD_ISSUE_WIDTH];
    MemIssueQueueEntry ldRecordData[LOAD_ISSUE_WIDTH];  // for ReplayQueue

    always_comb begin
        for ( int i = 0; i < MSHR_NUM; i++ ) begin
            lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[i] = FALSE;
        end

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin

            ldFlush[i] = SelectiveFlushDetector(
                            recovery.toRecoveryPhase,
                            recovery.flushRangeHeadPtr,
                            recovery.flushRangeTailPtr,
                            ldIqData[i].activeListPtr
                        );
            ldUpdate[i]  = ldPipeReg[i].valid && !stall && !clear && !ldFlush[i];
            isLoad[i] = ( ldIqData[i].memOpInfo.opType == MEM_MOP_TYPE_LOAD );
            isCSR[i] = ( ldIqData[i].memOpInfo.opType == MEM_MOP_TYPE_CSR );
            isENV[i] = ( ldIqData[i].memOpInfo.opType == MEM_MOP_TYPE_ENV );
            isDiv[i] = ( ldIqData[i].memOpInfo.opType == MEM_MOP_TYPE_DIV );
            isMul[i] = ( ldIqData[i].memOpInfo.opType == MEM_MOP_TYPE_MUL );

            // Load store unit
            loadStoreUnit.executeLoad[i] = ldUpdate[i] && isLoad[i];
            loadStoreUnit.executedLoadAddr[i] = ldPipeReg[i].phyAddrOut;
            loadStoreUnit.executedLoadPC[i] = ldIqData[i].pc;
            loadStoreUnit.executedLoadMemAccessMode[i] = ldIqData[i].memOpInfo.memAccessMode;
            loadStoreUnit.executedStoreQueuePtrByLoad[i] = ldIqData[i].memOpInfo.storeQueuePtr;
            loadStoreUnit.executedLoadQueuePtrByLoad[i] = ldIqData[i].memOpInfo.loadQueuePtr;

            // Set hasAllocatedMSHR and mshrID info to notice ReplayQueue
            // whether missed loads have allocated MSHRs or not.
`ifndef RSD_DISABLE_DEBUG_REGISTER // Debug info
            ldRecordData[i].opId = ldPipeReg[i].memQueueData.opId;
`endif
            ldRecordData[i].activeListPtr = ldPipeReg[i].memQueueData.activeListPtr;
            ldRecordData[i].opSrc         = ldPipeReg[i].memQueueData.opSrc;
            ldRecordData[i].opDst         = ldPipeReg[i].memQueueData.opDst;
            ldRecordData[i].pc            = ldPipeReg[i].memQueueData.pc;
            ldRecordData[i].memOpInfo     = ldPipeReg[i].memQueueData.memOpInfo;
            ldRecordData[i].storeQueueRecoveryPtr = ldIqData[i].storeQueueRecoveryPtr;
            ldRecordData[i].loadQueueRecoveryPtr  = ldIqData[i].loadQueueRecoveryPtr;

            // Set MSHR id if the load instruction allocated a MSHR entry.
            if (ldPipeReg[i].memQueueData.memOpInfo.hasAllocatedMSHR) begin
                ldRecordData[i].memOpInfo.hasAllocatedMSHR = ldPipeReg[i].memQueueData.memOpInfo.hasAllocatedMSHR;
                ldRecordData[i].memOpInfo.mshrID = ldPipeReg[i].memQueueData.memOpInfo.mshrID;
            end
            else begin
                if (i < LOAD_ISSUE_WIDTH) begin
                    ldRecordData[i].memOpInfo.hasAllocatedMSHR = loadStoreUnit.loadHasAllocatedMSHR[i];

                    // There are two sources of MSHR ID to memorize,
                    // 1. when a load hits a MSHR entry, the hit MSHR ID,
                    // 2. when a load allocates a MSHR entry, the allocated MSHR ID.
                    // 3. when otherwise (no hit and no allocate), don't ldUpdate.
                    if (loadStoreUnit.loadHasAllocatedMSHR[i]) begin
                        ldRecordData[i].memOpInfo.mshrID = loadStoreUnit.loadMSHRID[i];
                    end
                    else if (loadStoreUnit.mshrAddrHit[i]) begin
                        ldRecordData[i].memOpInfo.mshrID = loadStoreUnit.mshrAddrHitMSHRID[i];
                    end
                    else begin
                        ldRecordData[i].memOpInfo.mshrID = ldPipeReg[i].memQueueData.memOpInfo.mshrID;
                    end
                end
                else begin
                    ldRecordData[i].memOpInfo.hasAllocatedMSHR = FALSE;
                    ldRecordData[i].memOpInfo.mshrID = '0;
                end
            end

            loadStoreUnit.dcReadCancelFromMT_Stage[i] = FALSE;
            
`ifdef RSD_ENABLE_REISSUE_ON_CACHE_MISS
            if (isLoad[i]) begin
                if (loadStoreUnit.storeLoadForwarded[i]) begin
                    loadStoreUnit.dcReadCancelFromMT_Stage[i] = TRUE;   // キャンセルしてMSHR の確保を行わせない
                    ldRegValid[i] = loadStoreUnit.forwardMiss[i] ? FALSE : ldPipeReg[i].regValid;
                end
                else if (ldRecordData[i].memOpInfo.hasAllocatedMSHR) begin
                    // When the load has allocated an MSHR entry,
                    // The data will come from MSHR.
                    ldRegValid[i] = loadStoreUnit.mshrReadHit[i] ? ldPipeReg[i].regValid : FALSE;
                end
                else if (loadStoreUnit.mshrReadHit[i]) begin
                    ldRegValid[i] = ldPipeReg[i].regValid;
                end
                else begin
                    // The consumers of a missed load is invalidate.
                    ldRegValid[i] = loadStoreUnit.dcReadHit[i] ? ldPipeReg[i].regValid : FALSE;
                end
            end
            else if (ldRecordData[i].memOpInfo.hasAllocatedMSHR) begin
                // When the prefetch load has allocated an MSHR entry,
                // The data will come from MSHR.
                ldRegValid[i] = loadStoreUnit.mshrReadHit[i] ? ldPipeReg[i].regValid : FALSE;
            end
            else begin
                ldRegValid[i] = ldPipeReg[i].regValid;
            end
`else
            ldRegValid[i] = TRUE;
`endif

            // Sends to the load queue whether the load executed in this cycle is valid.
            loadStoreUnit.executedLoadRegValid[i] = ldRegValid[i];
            
            `ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                if (isDiv[i] && ldRegValid[i]) begin
                    /*ldPipeReg[i].replay && */
                    ldRegValid[i] = mulDivUnit.divFinished[i];
                end
                mulDivUnit.divResetFromMT_Stage[i] = 
                    ldRegValid[i] && (ldFlush[i] || clear) && isDiv[i];
            `endif

            // Pipeline レジスタ書き込み
            ldNextStage[i].regValid = ldRegValid[i];
            ldNextStage[i].addrOut = ldPipeReg[i].addrOut;
            ldNextStage[i].memMapType = ldPipeReg[i].memMapType;
            ldNextStage[i].phyAddrOut = ldPipeReg[i].phyAddrOut;
            ldNextStage[i].csrDataOut = ldPipeReg[i].dataIn;

            ldNextStage[i].isLoad  = isLoad[i];
            ldNextStage[i].isStore = FALSE;
            ldNextStage[i].isCSR   = isCSR[i];
            ldNextStage[i].isDiv   = isDiv[i];
            ldNextStage[i].isMul   = isMul[i];

            ldNextStage[i].opDst = ldIqData[i].opDst;
            ldNextStage[i].activeListPtr = ldIqData[i].activeListPtr;
            ldNextStage[i].loadQueueRecoveryPtr  = ldIqData[i].loadQueueRecoveryPtr;
            ldNextStage[i].storeQueueRecoveryPtr = ldIqData[i].storeQueueRecoveryPtr;
            ldNextStage[i].pc = ldIqData[i].pc;


            // ExecState
            // 命令の実行結果によって、再フェッチが必要かどうかなどを判定する
            if (!ldUpdate[i] || (ldUpdate[i] && !ldRegValid[i])) begin
                ldNextStage[i].execState = EXEC_STATE_NOT_FINISHED;
            end
            else if ( isLoad[i] ) begin
                // ロードの実行に失敗した場合は、
                // 正しい実行結果が得られていないので、
                // そのロード命令からやり直す
                if ( loadStoreUnit.storeLoadForwarded[i] ) begin
                    // フォワードされた場合
                    ldNextStage[i].execState =
                        loadStoreUnit.forwardMiss[i] ? EXEC_STATE_REFETCH_THIS : EXEC_STATE_SUCCESS;
                    if (ldRecordData[i].memOpInfo.hasAllocatedMSHR) begin
                        lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[ldRecordData[i].memOpInfo.mshrID] = TRUE;
                    end
                end
                else if (ldRecordData[i].memOpInfo.hasAllocatedMSHR) begin
                    ldNextStage[i].execState =
                            loadStoreUnit.mshrReadHit[i] ? EXEC_STATE_SUCCESS : EXEC_STATE_REFETCH_THIS;
                end
                else if (loadStoreUnit.mshrReadHit[i]) begin
                    ldNextStage[i].execState = EXEC_STATE_SUCCESS;
                end
                else begin
                    // DCache
                    ldNextStage[i].execState =
                        loadStoreUnit.dcReadHit[i] ? EXEC_STATE_SUCCESS : EXEC_STATE_REFETCH_THIS;
                end
            end
            else if (ldRecordData[i].memOpInfo.hasAllocatedMSHR) begin
                ldNextStage[i].execState =
                        loadStoreUnit.mshrReadHit[i] ? EXEC_STATE_SUCCESS : EXEC_STATE_REFETCH_THIS;
            end
            else if (isENV[i]) begin
                // EBREAK/ECALL/MRET はトラップ扱い
                unique case (ldIqData[i].memOpInfo.envCode)
                ENV_BREAK:          ldNextStage[i].execState = EXEC_STATE_TRAP_EBREAK;
                ENV_CALL:           ldNextStage[i].execState = EXEC_STATE_TRAP_ECALL;
                ENV_MRET:           ldNextStage[i].execState = EXEC_STATE_TRAP_MRET;
                ENV_INSN_ILLEGAL:   ldNextStage[i].execState = EXEC_STATE_FAULT_INSN_ILLEGAL;
                ENV_INSN_VIOLATION: ldNextStage[i].execState = EXEC_STATE_FAULT_INSN_VIOLATION;
                default:
                    ldNextStage[i].execState = EXEC_STATE_TRAP_EBREAK;
                endcase
            end
`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            else if (isDiv[i]) begin
                ldNextStage[i].execState = mulDivUnit.divFinished[i] ? EXEC_STATE_SUCCESS : EXEC_STATE_NOT_FINISHED;
            end
`endif 
            else begin
                ldNextStage[i].execState = EXEC_STATE_SUCCESS;
            end

            // 実行が正しく終了してる場合，フォールト判定を行う
            // ストアの依存予測ではこちらの方が優先される
            if (ldNextStage[i].execState inside {EXEC_STATE_SUCCESS, EXEC_STATE_REFETCH_NEXT}) begin
                if (isLoad[i]) begin
                    if (ldPipeReg[i].memMapType == MMT_ILLEGAL)
                        ldNextStage[i].execState = EXEC_STATE_FAULT_LOAD_VIOLATION;
                    else if (IsMisalignedAddress(ldPipeReg[i].addrOut, ldIqData[i].memOpInfo.memAccessMode.size))
                        ldNextStage[i].execState = EXEC_STATE_FAULT_LOAD_MISALIGNED;
                end
            end


            // リセットorフラッシュ時はNOP
            ldNextStage[i].valid =
                (stall || clear || port.rst || ldFlush[i]) ? FALSE : ldPipeReg[i].valid;

`ifndef RSD_DISABLE_DEBUG_REGISTER
            ldNextStage[i].opId = ldPipeReg[i].opId;
`endif
        end // for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin

        //フラッシュによってMSHRをアロケートしたロード命令がフラッシュされる場合のMSHRの解放処理
        for ( int i = 0; i < MSHR_NUM; i++ ) begin
            loadStoreUnit.makeMSHRCanBeInvalidByMemoryTagAccessStage[i] = FALSE;
        end
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            if (ldPipeReg[i].valid && isLoad[i]) begin
                if (ldFlush[i]) begin
                    lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[i] = ldRecordData[i].memOpInfo.hasAllocatedMSHR;
                end
            end
            else begin
                lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[i] = FALSE;
            end

            mshrID = ldRecordData[i].memOpInfo.mshrID;
            if (lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[i] && isLoad[i]) begin
                loadStoreUnit.makeMSHRCanBeInvalidByMemoryTagAccessStage[mshrID] = TRUE;
            end
        end

    end // always_comb


    logic isStore   [STORE_ISSUE_WIDTH];
    logic stUpdate  [STORE_ISSUE_WIDTH];
    logic stRegValid[STORE_ISSUE_WIDTH];
    logic stFlush   [STORE_ISSUE_WIDTH];
    MemoryAccessStageRegPath stNextStage[STORE_ISSUE_WIDTH];
    MemIssueQueueEntry stRecordData[STORE_ISSUE_WIDTH];  // for ReplayQueue

    // For memory dependency prediction (only for STORE)
    logic memAccessOrderViolation[STORE_ISSUE_WIDTH];

    always_comb begin

        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            memAccessOrderViolation[i] = FALSE;
            stFlush[i] = SelectiveFlushDetector(
                            recovery.toRecoveryPhase,
                            recovery.flushRangeHeadPtr,
                            recovery.flushRangeTailPtr,
                            stIqData[i].activeListPtr
                        );
            stUpdate[i]  = stPipeReg[i].valid && !stall && !clear && !stFlush[i];
            isStore[i] = (stIqData[i].memOpInfo.opType == MEM_MOP_TYPE_STORE);

            // Load store unit
            loadStoreUnit.executeStore[i] = stUpdate[i] && isStore[i];
            loadStoreUnit.executedStoreData[i] = stPipeReg[i].dataIn;
`ifdef RSD_ENABLE_VECTOR_PATH
            loadStoreUnit.executedStoreVectorData[i] = stPipeReg[i].vecDataIn;
`else
            loadStoreUnit.executedStoreVectorData[i] = '0;
`endif
            loadStoreUnit.executedStoreAddr[i] = stPipeReg[i].phyAddrOut;
            loadStoreUnit.executedStoreCondEnabled[i]   = stPipeReg[i].condEnabled;
            loadStoreUnit.executedStoreRegValid[i] = stPipeReg[i].regValid;
            loadStoreUnit.executedStoreMemAccessMode[i] = stIqData[i].memOpInfo.memAccessMode;
            loadStoreUnit.executedLoadQueuePtrByStore[i] = stIqData[i].memOpInfo.loadQueuePtr;
            loadStoreUnit.executedStoreQueuePtrByStore[i] = stIqData[i].memOpInfo.storeQueuePtr;

            // Set hasAllocatedMSHR and mshrID info to notice ReplayQueue
            // whether missed loads have allocated MSHRs or not.
`ifndef RSD_DISABLE_DEBUG_REGISTER // Debug info
            stRecordData[i].opId = stPipeReg[i].memQueueData.opId;
`endif
            stRecordData[i].activeListPtr = stPipeReg[i].memQueueData.activeListPtr;
            stRecordData[i].opSrc         = stPipeReg[i].memQueueData.opSrc;
            stRecordData[i].opDst         = stPipeReg[i].memQueueData.opDst;
            stRecordData[i].pc = stPipeReg[i].memQueueData.pc;
            stRecordData[i].storeQueueRecoveryPtr = stIqData[i].storeQueueRecoveryPtr;
            stRecordData[i].loadQueueRecoveryPtr  = stIqData[i].loadQueueRecoveryPtr;
            stRecordData[i].memOpInfo = stPipeReg[i].memQueueData.memOpInfo;
            stRecordData[i].memOpInfo.hasAllocatedMSHR = FALSE;
            stRecordData[i].memOpInfo.mshrID = '0;

`ifdef RSD_ENABLE_REISSUE_ON_CACHE_MISS
            stRegValid[i] = stPipeReg[i].regValid;
`else
            stRegValid[i] = TRUE;
`endif


            // Pipeline レジスタ書き込み
            stNextStage[i].regValid   = stRegValid[i];
            stNextStage[i].addrOut    = stPipeReg[i].addrOut;
            stNextStage[i].memMapType = stPipeReg[i].memMapType;
            stNextStage[i].phyAddrOut = stPipeReg[i].phyAddrOut;
            stNextStage[i].csrDataOut = stPipeReg[i].dataIn;

            stNextStage[i].isLoad = FALSE;
            stNextStage[i].isStore = isStore[i];
            stNextStage[i].isCSR = FALSE;
            stNextStage[i].isDiv = FALSE;
            stNextStage[i].isMul = FALSE;

            stNextStage[i].opDst = stIqData[i].opDst;
            stNextStage[i].activeListPtr  = stIqData[i].activeListPtr;
            stNextStage[i].loadQueueRecoveryPtr = stIqData[i].loadQueueRecoveryPtr;
            stNextStage[i].storeQueueRecoveryPtr = stIqData[i].storeQueueRecoveryPtr;
            stNextStage[i].pc  = stIqData[i].pc;

            // ExecState
            // 命令の実行結果によって、再フェッチが必要かどうかなどを判定する
            if (!stUpdate[i] || (stUpdate[i] && !stRegValid[i])) begin
                stNextStage[i].execState = EXEC_STATE_NOT_FINISHED;
            end
            else if ( isStore[i] && loadStoreUnit.conflict[i] ) begin
                // memAccessOrderViolation
                // ストア命令自身は正しく実行できているため、
                // 次の命令からやり直す
                stNextStage[i].execState = EXEC_STATE_REFETCH_NEXT;
                // Make request for studying violation instruction to Memory dependent predictor.
                memAccessOrderViolation[i] = TRUE;
            end
            else begin
                stNextStage[i].execState = EXEC_STATE_SUCCESS;
            end

            // 実行が正しく終了してる場合，フォールト判定を行う
            // ストアの依存予測ではこちらの方が優先される
            if (stNextStage[i].execState inside {EXEC_STATE_SUCCESS, EXEC_STATE_REFETCH_NEXT}) begin
                if (isStore[i]) begin
                    if (stPipeReg[i].memMapType == MMT_ILLEGAL)
                        stNextStage[i].execState = EXEC_STATE_FAULT_STORE_VIOLATION;
                    else if (IsMisalignedAddress(stPipeReg[i].addrOut, stIqData[i].memOpInfo.memAccessMode.size))
                        stNextStage[i].execState = EXEC_STATE_FAULT_STORE_MISALIGNED;
                end
            end


            // リセットorフラッシュ時はNOP
            stNextStage[i].valid =
                (stall || clear || port.rst || stFlush[i]) ? FALSE : stPipeReg[i].valid;

`ifndef RSD_DISABLE_DEBUG_REGISTER
            stNextStage[i].opId = stPipeReg[i].opId;
`endif
        end // for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
    end // always_comb begin


    logic flush   [ MEM_ISSUE_WIDTH ];
    MemoryAccessStageRegPath nextStage[MEM_ISSUE_WIDTH];

    always_comb begin
        loadStoreUnit.memAccessOrderViolation = memAccessOrderViolation;

        `ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                // Record instructions to the replay queue.
                if (isStore[i]) begin
                    scheduler.memRecordEntry[i] = stUpdate[i] && !stRegValid[i];
                    scheduler.memRecordData[i] = stRecordData[i];
                    scheduler.memRecordAddrHit[i] = FALSE;
                    scheduler.memRecordAddrSubset[i] = ToIndexSubsetPartFromFullAddrInMTStage(stPipeReg[i].addrOut);
                    nextStage[i] = stNextStage[i];
                    flush[i] = stFlush[i];
                end
                else begin
                    scheduler.memRecordEntry[i] = ldUpdate[i] && !ldRegValid[i];
                    scheduler.memRecordData[i] = ldRecordData[i];
                    scheduler.memRecordAddrHit[i] = loadStoreUnit.mshrAddrHit[i];
                    scheduler.memRecordAddrSubset[i] = ToIndexSubsetPartFromFullAddrInMTStage(ldPipeReg[i].addrOut);
                    nextStage[i] = ldNextStage[i];
                    flush[i] = ldFlush[i];
                end
            end
        `else
            for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
                // Record instructions to the replay queue.
                scheduler.memRecordEntry[i] = ldUpdate[i] && !ldRegValid[i];
                scheduler.memRecordData[i] = ldRecordData[i];
                scheduler.memRecordAddrHit[i] = loadStoreUnit.mshrAddrHit[i];
                scheduler.memRecordAddrSubset[i] = ToIndexSubsetPartFromFullAddrInMTStage(ldPipeReg[i].addrOut);
                nextStage[i] = ldNextStage[i];
                flush[i] = ldFlush[i];
            end
            for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
                // Record instructions to the replay queue.
                scheduler.memRecordEntry[i+STORE_ISSUE_LANE_BEGIN] = stUpdate[i] && !stRegValid[i];
                scheduler.memRecordData[i+STORE_ISSUE_LANE_BEGIN] = stRecordData[i];
                scheduler.memRecordAddrHit[i+STORE_ISSUE_LANE_BEGIN] = FALSE;
                scheduler.memRecordAddrSubset[i+STORE_ISSUE_LANE_BEGIN] = ToIndexSubsetPartFromFullAddrInMTStage(stPipeReg[i].addrOut);
                nextStage[i+STORE_ISSUE_LANE_BEGIN] = stNextStage[i];
                flush[i+STORE_ISSUE_LANE_BEGIN] = stFlush[i];
            end
        `endif

        port.nextStage = nextStage;

    end

    always_comb begin

        // Debug Register
`ifndef RSD_DISABLE_HARDWARE_COUNTER
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            hwCounter.loadMiss[i] =
                ldUpdate[i] && isLoad[i] && ldPipeReg[i].regValid && !loadStoreUnit.dcReadHit[i];
        end
`endif

        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            debug.mtReg[i].valid = pipeReg[i].valid;
            debug.mtReg[i].flush = flush[i];
            debug.mtReg[i].opId = pipeReg[i].opId;
        end
`ifdef RSD_FUNCTIONAL_SIMULATION

        `ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                debug.mtReg[i].executeLoad = isLoad[i] ? loadStoreUnit.executeLoad[i] : FALSE;
                debug.mtReg[i].executedLoadAddr  = loadStoreUnit.executedLoadAddr[i];

                debug.mtReg[i].executeStore      = isStore[i] ? loadStoreUnit.executeStore[i] : FALSE;
                debug.mtReg[i].executedStoreAddr = loadStoreUnit.executedStoreAddr[i];
                debug.mtReg[i].executedStoreData = loadStoreUnit.executedStoreData[i];
                debug.mtReg[i].executedStoreVectorData = loadStoreUnit.executedStoreVectorData[i];
            end

        `else
            for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
                debug.mtReg[i].executeLoad       = loadStoreUnit.executeLoad[i];
                debug.mtReg[i].executedLoadAddr  = loadStoreUnit.executedLoadAddr[i];
            end
            for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
                debug.mtReg[i+STORE_ISSUE_LANE_BEGIN].executeStore      = loadStoreUnit.executeStore[i];
                debug.mtReg[i+STORE_ISSUE_LANE_BEGIN].executedStoreAddr = loadStoreUnit.executedStoreAddr[i];
                debug.mtReg[i+STORE_ISSUE_LANE_BEGIN].executedStoreData = loadStoreUnit.executedStoreData[i];
                debug.mtReg[i+STORE_ISSUE_LANE_BEGIN].executedStoreVectorData = loadStoreUnit.executedStoreVectorData[i];
            end
        `endif // `ifdef RSD_FUNCTIONAL_SIMULATION
`endif // `ifdef RSD_FUNCTIONAL_SIMULATION

`endif  // `ifndef RSD_DISABLE_DEBUG_REGISTER
    end


endmodule : MemoryTagAccessStage
// ---- Pipeline/MemoryBackEnd/MemoryRegisterWriteStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- MemoryRegisterWriteStageIF
//

import BasicTypes::*;
import PipelineTypes::*;


interface MemoryRegisterWriteStageIF( input logic clk, rst );

    modport ThisStage(
    input
        clk,
        rst
    );

endinterface : MemoryRegisterWriteStageIF




// ---- Pipeline/MemoryBackEnd/MemoryRegisterWriteStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Memory Write back stage
//

import BasicTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import DebugTypes::*;



module MemoryRegisterWriteStage(
    //MemoryRegisterWriteStageIF.ThisStage port,
    MemoryAccessStageIF.NextStage prev,
    RegisterFileIF.MemoryRegisterWriteStage registerFile,
    ActiveListIF.MemoryRegisterWriteStage activeList,
    RecoveryManagerIF.MemoryRegisterWriteStage recovery,
    ControllerIF.MemoryRegisterWriteStage ctrl,
    DebugIF.MemoryRegisterWriteStage debug
);
    MemoryRegisterWriteStageRegPath pipeReg[MEM_ISSUE_WIDTH];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            pipeReg[i] = '0;
        end
    end
`endif

    // --- Pipeline registers
    always_ff@( posedge /*port.clk*/ ctrl.clk )   // synchronous rst
    begin
        if (ctrl.rst) begin
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                pipeReg[i].valid <= '0;
            end
        end
        else if(!ctrl.backEnd.stall) begin    // write data
            pipeReg <= prev.nextStage;
        end
    end


    logic stall, clear;
    logic flush[ MEM_ISSUE_WIDTH ];
    logic update [ MEM_ISSUE_WIDTH ];
    logic valid [ MEM_ISSUE_WIDTH ];
    ActiveListWriteData alWriteData[MEM_ISSUE_WIDTH];

    ExecutionState execState[MEM_ISSUE_WIDTH];

    always_comb begin

        // Pipeline controll
        stall = ctrl.backEnd.stall;
        clear = ctrl.backEnd.clear;

        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            valid[i] = pipeReg[i].valid;
            flush[i] = SelectiveFlushDetector(
                recovery.toRecoveryPhase,
                recovery.flushRangeHeadPtr,
                recovery.flushRangeTailPtr,
                pipeReg[i].activeListPtr
            );
            update[i] = !stall && !clear && valid[i] && !flush[i];

            //
            // Active list
            //
            alWriteData[i].ptr = pipeReg[i].activeListPtr;
            alWriteData[i].loadQueuePtr = pipeReg[i].loadQueueRecoveryPtr;
            alWriteData[i].storeQueuePtr = pipeReg[i].storeQueueRecoveryPtr;

            alWriteData[i].isBranch = FALSE;
            alWriteData[i].isStore = pipeReg[i].isStore;

            // ExecState
            if ( update[i] ) begin
                alWriteData[i].state = pipeReg[i].execState;
            end
            else begin
                alWriteData[i].state = EXEC_STATE_NOT_FINISHED;
            end
            execState[i] = alWriteData[i].state;

            alWriteData[i].pc = pipeReg[i].pc;
            alWriteData[i].dataAddr = pipeReg[i].addrOut;

            activeList.memWrite[i] = update[i];
            activeList.memWriteData[i] = alWriteData[i];
        end


        //
        // Register file
        //
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin

            registerFile.memDstRegWE[i] =
                update[i] && pipeReg[i].opDst.writeReg;

            registerFile.memDstRegNum[i] = pipeReg[i].opDst.phyDstRegNum;
            registerFile.memDstRegData[i] = pipeReg[i].dataOut;
`ifdef RSD_ENABLE_VECTOR_PATH
            registerFile.memDstVecData[i] = pipeReg[i].vecDataOut;
`endif
        end


        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            debug.memRwReg[i].valid = valid[i];
            debug.memRwReg[i].flush = flush[i];
            debug.memRwReg[i].opId = pipeReg[i].opId;
        end
`endif
    end
endmodule : MemoryRegisterWriteStage
// ---- Pipeline/CommitStageIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- CommitStageIF
//

interface CommitStageIF( input logic clk, rst );
    
    modport ThisStage(
    input 
        clk, 
        rst
    );

endinterface : CommitStageIF
// ---- Pipeline/CommitStage.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Commit stage
//


import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import DebugTypes::*;
import FetchUnitTypes::*;


// 実行が終わってInsnの範囲を調べ、
// それがアクティブリストの先頭からop何個分に相当するかを返す
function automatic void GetFinishedInsnRange(
    output CommitLaneCountPath finishedInsnRange,
    input  CommitLaneCountPath finishedOpNum,    // the number of ops in an active list.
    input  ExecutionState      execState[COMMIT_WIDTH], // the execution state of the head ops on an active list.
    input  logic               last[COMMIT_WIDTH]
);
    finishedInsnRange = 0;
    for (int i = COMMIT_WIDTH - 1; i >= 0; i--) begin
        if (i < finishedOpNum && last[i]) begin
            finishedInsnRange = i + 1;
            break;
        end
    end
endfunction

// 実行が終わったopの数を出力。最大でCOMMIT_WIDTH
function automatic void GetFinishedOpNum(
    output CommitLaneCountPath finishedOpNum,
    input  ActiveListCountPath activeListCount,
    input  ExecutionState      execState[COMMIT_WIDTH] // the execution state of the head ops on an active list.
);
    finishedOpNum = 0;
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
        if (i < activeListCount && execState[i] != EXEC_STATE_NOT_FINISHED)
            finishedOpNum = i + 1;
        else
            break;
    end
endfunction

// そのInsnと次のInsnの最初のマイクロ命令を指すポインタを得る
function automatic void GetInsnPtr(
    output CommitLaneIndexPath headOfThisInsn[COMMIT_WIDTH],
    output CommitLaneIndexPath tailOfThisInsn[COMMIT_WIDTH],
    input  logic        last [COMMIT_WIDTH]
);
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
        headOfThisInsn[i] = 0;
        for (int j = i - 1; 0 <= j; j--) begin
            if (last[j]) begin
                headOfThisInsn[i] = j + 1;
                break;
            end
        end

        tailOfThisInsn[i] = COMMIT_WIDTH-1;
        for (int j = i; j < COMMIT_WIDTH; j++) begin
            if (last[j]) begin
                tailOfThisInsn[i] = j;
                break;
            end
        end
    end
endfunction

// Decide which ops are committed.
function automatic void DecideCommit(
    output logic commit[COMMIT_WIDTH],         // Whether to commit or not
    output logic toRecoveryPhase,              // Misprediction is detected and recover the system.
    output CommitLaneIndexPath recoveredIndex, // The index of mis-predicted op.
    output RefetchType refetchType,            // Where to refetch from.
    output ExecutionState recoveryCause,       // Why recovery is caused
    input logic startCommit,                      // In commit phase or not.
    input ActiveListCountPath activeListCount,    // the number of ops in an active list.
    input ExecutionState execState[COMMIT_WIDTH], // the execution state of the head ops on an active list.
    input logic isBranch [COMMIT_WIDTH],          // Whether the op is BR or RIJ
    input logic isStore [COMMIT_WIDTH],          // Whether the op is store
    input logic last[COMMIT_WIDTH],      // Whether the op is last of the insn or not
    input logic unableToStartRecovery    // Whether to start recovery
);



    CommitLaneIndexPath headOfThisInsn[COMMIT_WIDTH];
    CommitLaneIndexPath tailOfThisInsn[COMMIT_WIDTH];

    logic recovery[COMMIT_WIDTH];
    CommitLaneIndexPath recoveryPoint[COMMIT_WIDTH];
    logic recoveryTrigger;
    CommitLaneCountPath recoveryStart;

    // 実行終了し、コミット可能なマイクロ命令の数
    CommitLaneCountPath finishedOpNum;

    // すべてのマイクロ命令が終了したInstructionに属するマイクロ命令の数の合計。
    // 実行終了したマイクロ命令は、Instruction単位でコミットされるため、
    // これを計算しておくことが必要となる。
    CommitLaneCountPath finishedInsnRange;

    RefetchType opRefetchType[COMMIT_WIDTH]; // RefetchType of each lane.

    GetInsnPtr(headOfThisInsn, tailOfThisInsn, last);

    GetFinishedOpNum(finishedOpNum, activeListCount, execState);

    GetFinishedInsnRange(finishedInsnRange, finishedOpNum, execState, last);

    for (int i = 0; i < COMMIT_WIDTH; i++) begin
        if (execState[i] == EXEC_STATE_REFETCH_NEXT) begin
            recovery[i] = TRUE;
            recoveryPoint[i] = tailOfThisInsn[i];
            opRefetchType[i] = (
                isBranch[i] ?   REFETCH_TYPE_BRANCH_TARGET : 
                isStore[i]  ?   REFETCH_TYPE_STORE_NEXT_PC :
                                REFETCH_TYPE_NEXT_PC
            );
        end
        else if (execState[i] == EXEC_STATE_REFETCH_THIS) begin
            recovery[i] = TRUE;
            recoveryPoint[i] = headOfThisInsn[i];
            opRefetchType[i] = REFETCH_TYPE_THIS_PC;
        end
        else if (execState[i] inside{
            EXEC_STATE_TRAP_ECALL, 
            EXEC_STATE_TRAP_EBREAK, 
            EXEC_STATE_TRAP_MRET,
            EXEC_STATE_FAULT_INSN_MISALIGNED
        }) begin
            recovery[i] = TRUE;
            recoveryPoint[i] = tailOfThisInsn[i];
            opRefetchType[i] = REFETCH_TYPE_NEXT_PC_TO_CSR_TARGET;
        end
        else if (execState[i] inside{
            EXEC_STATE_FAULT_LOAD_MISALIGNED,
            EXEC_STATE_FAULT_LOAD_VIOLATION,
            EXEC_STATE_FAULT_STORE_MISALIGNED,
            EXEC_STATE_FAULT_STORE_VIOLATION,
            EXEC_STATE_FAULT_INSN_ILLEGAL,
            EXEC_STATE_FAULT_INSN_VIOLATION
        }) begin
            recovery[i] = TRUE;
            recoveryPoint[i] = headOfThisInsn[i];
            opRefetchType[i] = REFETCH_TYPE_THIS_PC_TO_CSR_TARGET;
        end
        else begin
            // Set dummy values
            recovery[i] = FALSE;
            recoveryPoint[i] = 0;
            opRefetchType[i] = REFETCH_TYPE_THIS_PC;
        end
    end

    recoveryTrigger = FALSE;
    recoveredIndex = 0;
    recoveryStart = COMMIT_WIDTH; // max value
    refetchType = REFETCH_TYPE_THIS_PC; // dummy value
    recoveryCause = EXEC_STATE_SUCCESS;
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
        if (i < finishedInsnRange) begin
            if (recovery[i] && recoveryPoint[i] < recoveryStart) begin
                recoveryTrigger = TRUE;
                recoveredIndex = i;
                recoveryStart = recoveryPoint[i];
                refetchType = opRefetchType[i];
                recoveryCause = execState[i];
            end
        end
    end

    toRecoveryPhase = (startCommit && recoveryTrigger && !unableToStartRecovery ? TRUE : FALSE);

    for (int i = 0; i < COMMIT_WIDTH; i++) begin
        if (startCommit) begin
            if (recoveryTrigger) begin
                if (i < recoveryStart) begin
                    commit[i] = TRUE;
                end
                else if (i == recoveryStart) begin
                    commit[i] =
                        ( ((execState[i] inside {
                            EXEC_STATE_REFETCH_THIS,
                            EXEC_STATE_FAULT_LOAD_MISALIGNED,
                            EXEC_STATE_FAULT_LOAD_VIOLATION,
                            EXEC_STATE_FAULT_STORE_MISALIGNED,
                            EXEC_STATE_FAULT_STORE_VIOLATION,
                            EXEC_STATE_FAULT_INSN_ILLEGAL,
                            EXEC_STATE_FAULT_INSN_VIOLATION
                        }) || unableToStartRecovery) ? FALSE : TRUE);
                end
                else begin
                    commit[i] = FALSE;
                end
            end
            else begin
                commit[i] = (i < finishedInsnRange ? TRUE : FALSE);
            end
        end
        else begin
            commit[i] = FALSE;
        end
    end
endfunction



module CommitStage(
    CommitStageIF.ThisStage port,
    RenameLogicIF.CommitStage renameLogic,
    ActiveListIF.CommitStage activeList,
    LoadStoreUnitIF.CommitStage loadStoreUnit,
    RecoveryManagerIF.CommitStage recovery,
    CSR_UnitIF.CommitStage csrUnit,
    DebugIF.CommitStage debug,
    HardwareCounterIF.CommitStage hwCounter
);

    logic toRecoveryPhase;

    logic commit [ COMMIT_WIDTH ] /*verilator public*/;
    logic last [ COMMIT_WIDTH ];
    logic isBranch [ COMMIT_WIDTH ];
    logic isStore [ COMMIT_WIDTH ];

    ActiveListEntry alReadData [ COMMIT_WIDTH ] /*verilator public*/;
    ExecutionState execState [ COMMIT_WIDTH ];

    CommitLaneIndexPath recoveryOpIndex;
    RefetchType refetchType;
    ExecutionState recoveryCause;

    CommitLaneCountPath commitNum;
    CommitLaneCountPath commitLoadNum;
    CommitLaneCountPath commitStoreNum;

    PipelinePhase phase;

    PC_Path lastCommittedPC, prevLastCommittedPC;

    always_ff@(posedge port.clk) begin
        prevLastCommittedPC <= lastCommittedPC;
    end

    always_comb begin

        // The head entries of an active list.
        alReadData = activeList.readData;
        execState = activeList.headExecState;

        // Phase of a pipeline
        phase = recovery.phase;

        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            last[i] = alReadData[i].last;
            isBranch[i] = alReadData[i].isBranch;
            isStore[i] = alReadData[i].isStore;
        end

        // Decide which instructions are committed.
        DecideCommit(
            .commit(commit),
            .toRecoveryPhase(toRecoveryPhase),
            .recoveredIndex(recoveryOpIndex),
            .refetchType(refetchType),
            .recoveryCause(recoveryCause),
            .startCommit(phase == PHASE_COMMIT),
            .activeListCount(activeList.validEntryNum),
            .execState(execState),
            .last(last),
            .isBranch(isBranch),
            .isStore(isStore),
            .unableToStartRecovery(recovery.unableToStartRecovery)
       );

        // Count num of commit instructions.
        commitNum = 0;
        commitLoadNum = 0;
        commitStoreNum = 0;
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            if (commit[i]) begin
                commitNum++;
                if (alReadData[i].isLoad)
                    commitLoadNum++;
                if (alReadData[i].isStore)
                    commitStoreNum++;
            end
        end

        // To the rename logic.
        renameLogic.commit = commit[0];
        renameLogic.commitNum = commitNum;

        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            if (commit[i]) begin
                renameLogic.retRMT_WriteReg[i] = alReadData[i].writeReg;
                renameLogic.retRMT_WriteReg_PhyRegNum[i] = alReadData[i].phyDstRegNum;
                renameLogic.retRMT_WriteReg_LogRegNum[i] = alReadData[i].logDstRegNum;
            end
            else begin
                renameLogic.retRMT_WriteReg[i] = FALSE;
                renameLogic.retRMT_WriteReg_PhyRegNum[i] = 0;
                renameLogic.retRMT_WriteReg_LogRegNum[i] = 0;
            end
        end

        // Update load/store unit.
        loadStoreUnit.releaseLoadQueue = commit[0];
        loadStoreUnit.releaseLoadQueueEntryNum = commitLoadNum;
        loadStoreUnit.commitStore = commit[0];
        loadStoreUnit.commitStoreNum = commitStoreNum;

        // To RecoveryManager
        recovery.exceptionDetectedInCommitStage = toRecoveryPhase;
        recovery.refetchTypeFromCommitStage = refetchType;
        recovery.recoveryOpIndex = recoveryOpIndex;
        recovery.recoveryCauseFromCommitStage = recoveryCause;

        // lastCommittedPC
        lastCommittedPC = prevLastCommittedPC;
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            if (commit[i])
                lastCommittedPC = alReadData[i].pc;
        end

        // CSR Update
        csrUnit.commitNum = commitNum;

        // Debug Register
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
`ifndef RSD_DISABLE_DEBUG_REGISTER
            debug.toRecoveryPhase = toRecoveryPhase;
            debug.cmReg[i].commit = commit[i];
            debug.cmReg[i].flush =
                (i < renameLogic.flushNum) && recovery.renameLogicRecoveryRMT;

            debug.cmReg[i].opId = alReadData[i].opId;
`ifdef RSD_FUNCTIONAL_SIMULATION
            debug.cmReg[i].releaseReg = renameLogic.releaseReg[i];
            debug.cmReg[i].phyReleasedReg = renameLogic.phyReleasedReg[i];
`endif
`endif
            debug.lastCommittedPC = lastCommittedPC;
        end

        // Hardware Counter
`ifndef RSD_DISABLE_HARDWARE_COUNTER
        hwCounter.commitNum = commitNum;
        hwCounter.refetchThisPC =
            toRecoveryPhase && (refetchType == REFETCH_TYPE_THIS_PC);
        hwCounter.refetchNextPC =
            toRecoveryPhase && (refetchType inside {REFETCH_TYPE_NEXT_PC, REFETCH_TYPE_STORE_NEXT_PC});
        hwCounter.refetchBrTarget =
            toRecoveryPhase && (refetchType == REFETCH_TYPE_BRANCH_TARGET);
`endif
    end

    generate
        for (genvar i = 0; i < COMMIT_WIDTH; i++) begin
            `RSD_ASSERT_CLK(
                port.clk,
                !(commit[i] && phase == PHASE_COMMIT && alReadData[i].undefined),
                "An undefined or unsupported op is retired."
            );
        end
    endgenerate

endmodule : CommitStage

// ---- RegisterFile/RegisterFile.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Register file
//

import BasicTypes::*;

module RegisterFile(
    RegisterFileIF.RegisterFile port
);
    //
    // Register
    //
    parameter REG_READ_NUM = ISSUE_WIDTH * 2;
    parameter REG_WRITE_NUM = INT_ISSUE_WIDTH + COMPLEX_ISSUE_WIDTH + LOAD_ISSUE_WIDTH;

    logic       regWE      [ REG_WRITE_NUM ];
    PScalarRegNumPath dstRegNum  [ REG_WRITE_NUM ];
    PRegDataPath dstRegData [ REG_WRITE_NUM ];
    PScalarRegNumPath srcRegNum  [ REG_READ_NUM ];
    PRegDataPath srcRegData [ REG_READ_NUM ];

    DistributedMultiPortRAM #(
        .ENTRY_NUM( PSCALAR_NUM ),
        .ENTRY_BIT_SIZE( $bits(PRegDataPath) ),
        .READ_NUM( REG_READ_NUM ),
        .WRITE_NUM( REG_WRITE_NUM )
    ) phyReg (
        .clk( port.clk ),
        .we( regWE ),
        .wa( dstRegNum ),
        .wv( dstRegData ),
        .ra( srcRegNum ),
        .rv( srcRegData )
    );

    // - Initialization logic
    PRegNumPath regRstIndex;
    always_ff @( posedge port.clk ) begin
        if (port.rstStart)
            regRstIndex <= 0;
        else
            regRstIndex <= regRstIndex + REG_WRITE_NUM;
    end

    always_comb begin
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            regWE     [i] = port.intDstRegWE[i] && !port.intDstRegNum[i].isVector;
`else
            regWE     [i] = port.intDstRegWE[i];
`endif
            dstRegNum [i] = port.intDstRegNum[i];
            dstRegData[i] = port.intDstRegData[i];

            srcRegNum[i*2  ] = port.intSrcRegNumA[i];
            srcRegNum[i*2+1] = port.intSrcRegNumB[i];
            port.intSrcRegDataA[i] = srcRegData[i*2  ];
            port.intSrcRegDataB[i] = srcRegData[i*2+1];
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            regWE     [i+INT_ISSUE_WIDTH] = port.complexDstRegWE[i] && !port.complexDstRegNum[i].isVector;
`else
            regWE     [i+INT_ISSUE_WIDTH] = port.complexDstRegWE[i];
`endif
            dstRegNum [i+INT_ISSUE_WIDTH] = port.complexDstRegNum[i];
            dstRegData[i+INT_ISSUE_WIDTH] = port.complexDstRegData[i];

            srcRegNum[(i+INT_ISSUE_WIDTH)*2  ] = port.complexSrcRegNumA[i];
            srcRegNum[(i+INT_ISSUE_WIDTH)*2+1] = port.complexSrcRegNumB[i];
            port.complexSrcRegDataA[i] = srcRegData[(i+INT_ISSUE_WIDTH)*2  ];
            port.complexSrcRegDataB[i] = srcRegData[(i+INT_ISSUE_WIDTH)*2+1];
        end
`endif
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            srcRegNum[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)*2  ] = port.memSrcRegNumA[i];
            srcRegNum[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)*2+1] = port.memSrcRegNumB[i];
            port.memSrcRegDataA[i] = srcRegData[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)*2  ];
            port.memSrcRegDataB[i] = srcRegData[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)*2+1];
        end

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            regWE     [(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.memDstRegWE[i] && !port.memDstRegNum[i].isVector;
`else
            regWE     [(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.memDstRegWE[i];
`endif

            dstRegNum [(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.memDstRegNum[i];
            dstRegData[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.memDstRegData[i];
        end
        // 以下のリセット後の初期化処理で全てのレジスタに0x0を代入する.
        // ゼロレジスタは, 書き込み時にはDecoderでwriteフラグを落とし,
        // 読み込み時は,RMTの初期化によって割り当てられる,
        // 0x0で初期化された物理レジスタの0番エントリを実際に参照することで実現している.
        // よって, 以下の初期化処理を論理合成時も省略してはならない
        if (port.rst) begin
            for (int i = 0; i < REG_WRITE_NUM; i++) begin
                regWE     [i] = TRUE;
                dstRegNum [i] = regRstIndex + i;
                dstRegData[i].data = 'h00000000;
                dstRegData[i].valid = TRUE;
            end
        end
    end


    //
    // Vector
    //
`ifdef RSD_ENABLE_VECTOR_PATH
    parameter VEC_READ_NUM = COMPLEX_ISSUE_WIDTH * 2 + STORE_ISSUE_WIDTH;
    parameter VEC_WRITE_NUM = COMPLEX_ISSUE_WIDTH + LOAD_ISSUE_WIDTH;

    logic             vecWE      [ VEC_WRITE_NUM ];
    PVectorRegNumPath dstVecNum  [ VEC_WRITE_NUM ];
    PVecDataPath      dstVecData [ VEC_WRITE_NUM ];
    PVectorRegNumPath srcVecNum  [ VEC_READ_NUM ];
    PVecDataPath      srcVecData [ VEC_READ_NUM ];
    DistributedMultiPortRAM #(
        .ENTRY_NUM( PVECTOR_NUM ),
        .ENTRY_BIT_SIZE( $bits(PVecDataPath) ),
        .READ_NUM( VEC_READ_NUM ),
        .WRITE_NUM( VEC_WRITE_NUM )
    ) phyVec (
        .clk( port.clk ),
        .we( vecWE ),
        .wa( dstVecNum ),
        .wv( dstVecData ),
        .ra( srcVecNum ),
        .rv( srcVecData )
    );

    // - Initialization logic
    PVectorRegNumPath vecRstIndex;
    always_ff @( posedge port.clk ) begin
        if (port.rstStart)
            vecRstIndex <= 0;
        else
            vecRstIndex <= vecRstIndex + VEC_WRITE_NUM;
    end

    always_comb begin
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            vecWE     [i] = port.complexDstRegWE[i] && port.complexDstRegNum[i].isVector;
            dstVecNum [i] = port.complexDstRegNum[i].regNum;
            dstVecData[i] = port.complexDstVecData[i];

            srcVecNum[i*2  ] = port.complexSrcRegNumA[i].regNum;
            srcVecNum[i*2+1] = port.complexSrcRegNumB[i].regNum;
            port.complexSrcVecDataA[i] = srcVecData[i*2  ];
            port.complexSrcVecDataB[i] = srcVecData[i*2+1];
        end

        for ( int i = 0; i < STORE_ISSUE_WIDTH; i++ ) begin
            srcVecNum[(i+COMPLEX_ISSUE_WIDTH)*2] = port.memSrcRegNumB[i+STORE_ISSUE_LANE_BEGIN].regNum;
            port.memSrcVecDataB[i] = srcVecData[(i+COMPLEX_ISSUE_WIDTH)*2];
        end

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            vecWE     [(i+COMPLEX_ISSUE_WIDTH)] = port.memDstRegWE[i] && port.memDstRegNum[i].isVector;
            dstVecNum [(i+COMPLEX_ISSUE_WIDTH)] = port.memDstRegNum[i].regNum;
            dstVecData[(i+COMPLEX_ISSUE_WIDTH)] = port.memDstVecData[i];
        end
        if (port.rst) begin
            for (int i = 0; i < VEC_WRITE_NUM; i++) begin
                vecWE     [i] = TRUE;
                dstVecNum [i] = vecRstIndex + i;
                dstVecData[i].data = 128'hcdcdcdcd_cdcdcdcd_cdcdcdcd_cdcdcdcd;
                dstVecData[i].valid = TRUE;
            end
        end
    end
`endif


endmodule : RegisterFile
// ---- RegisterFile/RegisterFileIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- RegisterFileIF
//

import BasicTypes::*;


interface RegisterFileIF( input logic clk, rst, rstStart );
    
    /* Integer Register Read */
    PRegNumPath intSrcRegNumA [ INT_ISSUE_WIDTH ];
    PRegNumPath intSrcRegNumB [ INT_ISSUE_WIDTH ];
    
    PRegDataPath intSrcRegDataA [ INT_ISSUE_WIDTH ];
    PRegDataPath intSrcRegDataB [ INT_ISSUE_WIDTH ];
    
    /* Integer Register Write */
    logic intDstRegWE  [ INT_ISSUE_WIDTH ];
    PRegNumPath intDstRegNum  [ INT_ISSUE_WIDTH ];    
    PRegDataPath intDstRegData  [ INT_ISSUE_WIDTH ];
    
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    /* Complex Integer Register Read */
    PRegNumPath  complexSrcRegNumA [ COMPLEX_ISSUE_WIDTH ];
    PRegNumPath  complexSrcRegNumB [ COMPLEX_ISSUE_WIDTH ];
    
    PRegDataPath  complexSrcRegDataA [ COMPLEX_ISSUE_WIDTH ];
    PRegDataPath  complexSrcRegDataB [ COMPLEX_ISSUE_WIDTH ];


    /* Complex Integer Register Write */
    logic complexDstRegWE  [ COMPLEX_ISSUE_WIDTH ];

    PRegNumPath  complexDstRegNum  [ COMPLEX_ISSUE_WIDTH ];
    
    PRegDataPath  complexDstRegData  [ COMPLEX_ISSUE_WIDTH ];
`endif

    /* Memory Register Read */
    PRegNumPath memSrcRegNumA [ MEM_ISSUE_WIDTH ];
    PRegNumPath memSrcRegNumB [ MEM_ISSUE_WIDTH ];
    
    PRegDataPath  memSrcRegDataA [ MEM_ISSUE_WIDTH ];
    PRegDataPath  memSrcRegDataB [ MEM_ISSUE_WIDTH ];
    
    /* Memory Register Write */
    logic memDstRegWE  [ LOAD_ISSUE_WIDTH ];

    PRegNumPath memDstRegNum [ LOAD_ISSUE_WIDTH ];
    
    PRegDataPath memDstRegData  [ LOAD_ISSUE_WIDTH ];

`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath  complexSrcVecDataA [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  complexSrcVecDataB [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  complexDstVecData  [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  memSrcVecDataB [ STORE_ISSUE_WIDTH ];
    PVecDataPath memDstVecData [ LOAD_ISSUE_WIDTH ];
`endif    

    modport RegisterFile(
    input 
        clk,
        rst,
        rstStart,
        intSrcRegNumA,
        intSrcRegNumB,
        memSrcRegNumA,
        memSrcRegNumB,
        intDstRegWE,
        intDstRegNum,
        intDstRegData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexSrcRegNumA,
        complexSrcRegNumB,
        complexDstRegWE,
        complexDstRegNum,
        complexDstRegData,
`endif
        memDstRegWE,
        memDstRegNum,
        memDstRegData,
`ifdef RSD_ENABLE_VECTOR_PATH
        complexDstVecData,
        memDstVecData,
`endif
    output
`ifdef RSD_ENABLE_VECTOR_PATH
        complexSrcVecDataA,
        complexSrcVecDataB,
        memSrcVecDataB,
`endif
        intSrcRegDataA,
        intSrcRegDataB,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexSrcRegDataA,
        complexSrcRegDataB,
`endif
        memSrcRegDataA,
        memSrcRegDataB
    );
    
    modport IntegerRegisterReadStage(
    input
        intSrcRegDataA,
        intSrcRegDataB,
    output
        intSrcRegNumA,
        intSrcRegNumB
    );
    
    modport IntegerRegisterWriteStage(
    output
        intDstRegWE,
        intDstRegNum,
        intDstRegData
    );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE    
    modport ComplexIntegerRegisterReadStage(
    input
        complexSrcRegDataA,
        complexSrcRegDataB,
`ifdef RSD_ENABLE_VECTOR_PATH
        complexSrcVecDataA,
        complexSrcVecDataB,
`endif
    output
        complexSrcRegNumA,
        complexSrcRegNumB
    );
    
    modport ComplexIntegerRegisterWriteStage(
    output
 `ifdef RSD_ENABLE_VECTOR_PATH
        complexDstVecData,
 `endif
        complexDstRegWE,
        complexDstRegNum,
        complexDstRegData
    );
`endif

    modport MemoryRegisterReadStage(
    input
        memSrcRegDataA,
        memSrcRegDataB,
`ifdef RSD_ENABLE_VECTOR_PATH
         memSrcVecDataB,
`endif
    output
        memSrcRegNumA,
        memSrcRegNumB
    );
    
    modport MemoryRegisterWriteStage(
    output
`ifdef RSD_ENABLE_VECTOR_PATH
        memDstVecData,
`endif
        memDstRegWE,
        memDstRegNum,
        memDstRegData
    );
    
endinterface : RegisterFileIF




// ---- RegisterFile/BypassController.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import BypassTypes::*;

//
// --- Bypass controller
//
// BypassController outputs control information that controlls BypassNetwork.
// BypassController is connected to a register read stage.
//

typedef struct packed // struct BypassCtrlOperand
{
    PRegNumPath dstRegNum;
    logic writeReg;
} BypassCtrlOperand;


module BypassCtrlStage(
    input  logic clk, rst, 
    input  PipelineControll ctrl,
    input  BypassCtrlOperand in, 
    output BypassCtrlOperand out 
);
    BypassCtrlOperand body;
    
    always_ff@( posedge clk )               // synchronous rst 
    begin
        if( rst || ctrl.clear ) begin              // rst 
            body.dstRegNum <= 0;
            body.writeReg  <= FALSE;
        end
        else if( ctrl.stall ) begin         // write data
            body <= body;
        end
        else begin
            body <= in;
        end
    end
    
    assign out = body;
endmodule

module BypassController( 
    BypassNetworkIF.BypassController port,
    ControllerIF.BypassController ctrl
);

    function automatic BypassSelect SelectReg( 
    input
        PRegNumPath regNum,
        logic read,
        BypassCtrlOperand intEX [ INT_ISSUE_WIDTH ],
        BypassCtrlOperand intWB [ INT_ISSUE_WIDTH ],
        BypassCtrlOperand memMA [ LOAD_ISSUE_WIDTH ],
        BypassCtrlOperand memWB [ LOAD_ISSUE_WIDTH ]
    );
        BypassSelect ret;
        ret.valid = FALSE;
        //ret.stg = BYPASS_STAGE_DEFAULT;
        ret.stg = BYPASS_STAGE_INT_EX;
        ret.lane.intLane = 0;
        ret.lane.memLane = 0;
        // Not implemented 
        ret.lane.complexLane = 0; 

        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            if ( read && intEX[i].writeReg && regNum == intEX[i].dstRegNum ) begin
                ret.valid = TRUE;
                ret.stg = BYPASS_STAGE_INT_EX;
                ret.lane.intLane = i;
                break;
            end
            if ( read && intWB[i].writeReg && regNum == intWB[i].dstRegNum ) begin
                ret.valid = TRUE;
                ret.stg = BYPASS_STAGE_INT_WB;
                ret.lane.intLane = i;
                break;
            end
        end
        
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            if ( read && memMA[i].writeReg && regNum == memMA[i].dstRegNum ) begin
                ret.valid = TRUE;
                ret.stg = BYPASS_STAGE_MEM_MA;
                ret.lane.memLane = i;
                break;
            end
            if ( read && memWB[i].writeReg && regNum == memWB[i].dstRegNum ) begin
                ret.valid = TRUE;
                ret.stg = BYPASS_STAGE_MEM_WB;
                ret.lane.memLane = i;
                break;
            end
        end
        
        return ret;
    endfunction

    logic clk, rst;
    
    assign clk = port.clk;
    assign rst = port.rst;
    
    //
    // Back-end Pipeline Structure
    //
    // Int:     IS RR EX WB
    // Complex: IS RR EX WB
    // Mem:     IS RR EX MT MA WB
    BypassCtrlOperand intRR [ INT_ISSUE_WIDTH ];
    BypassCtrlOperand intEX [ INT_ISSUE_WIDTH ];
    BypassCtrlOperand intWB [ INT_ISSUE_WIDTH ];
    BypassCtrlOperand memRR [ LOAD_ISSUE_WIDTH ];
    BypassCtrlOperand memEX [ LOAD_ISSUE_WIDTH ];
    BypassCtrlOperand memMT [ LOAD_ISSUE_WIDTH ];
    BypassCtrlOperand memMA [ LOAD_ISSUE_WIDTH ];
    BypassCtrlOperand memWB [ LOAD_ISSUE_WIDTH ];

    for ( genvar i = 0; i < INT_ISSUE_WIDTH; i++ ) begin : stgInt
        BypassCtrlStage stgIntRR( clk, rst, ctrl.backEnd, intRR[i], intEX[i] );
        BypassCtrlStage stgIntEX( clk, rst, ctrl.backEnd, intEX[i], intWB[i] );
    end

    for ( genvar i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin : stgMem
        BypassCtrlStage stgMemRR( clk, rst, ctrl.backEnd, memRR[i], memEX[i] );
        BypassCtrlStage stgMemEX( clk, rst, ctrl.backEnd, memEX[i], memMT[i] );
        BypassCtrlStage stgMemMT( clk, rst, ctrl.backEnd, memMT[i], memMA[i] );
        BypassCtrlStage stgMemMA( clk, rst, ctrl.backEnd, memMA[i], memWB[i] );
    end
    
    BypassControll intBypassCtrl [ INT_ISSUE_WIDTH ];
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    BypassControll complexBypassCtrl [ COMPLEX_ISSUE_WIDTH ];
`endif
    BypassControll memBypassCtrl [ MEM_ISSUE_WIDTH ];

    always_comb begin
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            intRR[i].dstRegNum = port.intPhyDstRegNum[i];
            intRR[i].writeReg  = port.intWriteReg[i];

            intBypassCtrl[i].rA   = SelectReg ( port.intPhySrcRegNumA[i], port.intReadRegA[i], intEX, intWB, memMA, memWB );
            intBypassCtrl[i].rB   = SelectReg ( port.intPhySrcRegNumB[i], port.intReadRegB[i], intEX, intWB, memMA, memWB );
        end
        port.intCtrlOut = intBypassCtrl;

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            complexBypassCtrl[i].rA   = SelectReg ( port.complexPhySrcRegNumA[i], port.complexReadRegA[i], intEX, intWB, memMA, memWB );
            complexBypassCtrl[i].rB   = SelectReg ( port.complexPhySrcRegNumB[i], port.complexReadRegB[i], intEX, intWB, memMA, memWB );
        end
        port.complexCtrlOut = complexBypassCtrl;
`endif

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            memRR[i].dstRegNum = port.memPhyDstRegNum[i];
            memRR[i].writeReg  = port.memWriteReg[i];
        end

        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            memBypassCtrl[i].rA   = SelectReg ( port.memPhySrcRegNumA[i], port.memReadRegA[i], intEX, intWB, memMA, memWB );
            memBypassCtrl[i].rB   = SelectReg ( port.memPhySrcRegNumB[i], port.memReadRegB[i], intEX, intWB, memMA, memWB );
        end
        port.memCtrlOut = memBypassCtrl;
    end

endmodule : BypassController

// ---- RegisterFile/BypassNetwork.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Bypass network
//

import BasicTypes::*;
import PipelineTypes::*;
import BypassTypes::*;

typedef struct packed // struct BypassOperand
{
    PRegDataPath value;
} BypassOperand;


module BypassStage(
    input  logic clk, rst, 
    input  PipelineControll ctrl,
    input  BypassOperand in, 
    output BypassOperand out 
);
    BypassOperand body;
    
    always_ff@( posedge clk )               // synchronous rst 
    begin
        if( rst || ctrl.clear ) begin              // rst 
            body.value.data <= 0;
            body.value.valid <= 0;
        end
        else if( ctrl.stall ) begin         // write data
            body <= body;
        end
        else begin
            body <= in;
        end
    end
    
    assign out = body;
endmodule


module BypassNetwork( 
    BypassNetworkIF.BypassNetwork port,
    ControllerIF.BypassNetwork ctrl
);
    function automatic PRegDataPath SelectData( 
    input
        BypassSelect sel,
        BypassOperand intEX [ INT_ISSUE_WIDTH ],
        BypassOperand intWB [ INT_ISSUE_WIDTH ],
        BypassOperand memMA [ LOAD_ISSUE_WIDTH ],
        BypassOperand memWB [ LOAD_ISSUE_WIDTH ]
    );
        if( sel.stg == BYPASS_STAGE_INT_EX )
            return intEX[sel.lane.intLane].value;
        else   if( sel.stg == BYPASS_STAGE_INT_WB )
            return intWB[sel.lane.intLane].value;
        else   if( sel.stg == BYPASS_STAGE_MEM_MA )
            return memMA[sel.lane.memLane].value;
        else   if( sel.stg == BYPASS_STAGE_MEM_WB )
            return memWB[sel.lane.memLane].value;
        else
            return '0;
        
    endfunction 


    BypassOperand intDst [ INT_ISSUE_WIDTH ];
    BypassOperand intEX  [ INT_ISSUE_WIDTH ];
    BypassOperand intWB  [ INT_ISSUE_WIDTH ];
    BypassOperand memDst [ LOAD_ISSUE_WIDTH ];
    BypassOperand memMA  [ LOAD_ISSUE_WIDTH ];
    BypassOperand memWB  [ LOAD_ISSUE_WIDTH ];

    generate 
        for ( genvar i = 0; i < INT_ISSUE_WIDTH; i++ ) begin : stgInt
            BypassStage stgIntEX( port.clk, port.rst, ctrl.backEnd, intDst[i], intEX[i] );
            BypassStage stgIntWB( port.clk, port.rst, ctrl.backEnd, intEX[i],  intWB[i] );
        end
        
        for ( genvar i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin : stgMem
            BypassStage stgMemMA( port.clk, port.rst, ctrl.backEnd, memDst[i], memMA[i] );
            BypassStage stgMemWB( port.clk, port.rst, ctrl.backEnd, memMA[i],  memWB[i] );
        end
    endgenerate
    
    always_comb begin

        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            intDst[i].value = port.intDstRegDataOut[i];
            
            port.intSrcRegDataOutA[i] = SelectData( port.intCtrlIn[i].rA,   intEX, intWB, memMA, memWB );
            port.intSrcRegDataOutB[i] = SelectData( port.intCtrlIn[i].rB,   intEX, intWB, memMA, memWB );
        end
        
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            port.complexSrcRegDataOutA[i] = SelectData( port.complexCtrlIn[i].rA,   intEX, intWB, memMA, memWB );
            port.complexSrcRegDataOutB[i] = SelectData( port.complexCtrlIn[i].rB,   intEX, intWB, memMA, memWB );
        end
`endif
        
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            memDst[i].value = port.memDstRegDataOut[i];
        end
            
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            port.memSrcRegDataOutA[i] = SelectData( port.memCtrlIn[i].rA,   intEX, intWB, memMA, memWB );
            port.memSrcRegDataOutB[i] = SelectData( port.memCtrlIn[i].rB,   intEX, intWB, memMA, memWB );
        end
    end

endmodule : BypassNetwork

// ---- RegisterFile/BypassNetworkIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- BypassNetworkIF
//

import BasicTypes::*;
import BypassTypes::*;


interface BypassNetworkIF(input logic clk, rst, rstStart);
    
    //
    // --- Integer Pipeline
    //
    
    // Register read stage
    PRegNumPath intPhySrcRegNumA [ INT_ISSUE_WIDTH ];
    PRegNumPath intPhySrcRegNumB [ INT_ISSUE_WIDTH ];
    PRegNumPath intPhyDstRegNum  [ INT_ISSUE_WIDTH ];

    
    logic intReadRegA [ INT_ISSUE_WIDTH ];
    logic intReadRegB [ INT_ISSUE_WIDTH ];

    logic intWriteReg  [ INT_ISSUE_WIDTH ];
    
    BypassControll intCtrlOut [ INT_ISSUE_WIDTH ];
    
    // Execution stage
    BypassControll intCtrlIn [ INT_ISSUE_WIDTH ];
    
    PRegDataPath intSrcRegDataOutA  [ INT_ISSUE_WIDTH ];
    PRegDataPath intSrcRegDataOutB  [ INT_ISSUE_WIDTH ];

    PRegDataPath intDstRegDataOut  [ INT_ISSUE_WIDTH ];

    //
    // --- Complex Integer Pipeline
    //
    
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    // Register read stage
    PRegNumPath complexPhySrcRegNumA [ COMPLEX_ISSUE_WIDTH ];
    PRegNumPath complexPhySrcRegNumB [ COMPLEX_ISSUE_WIDTH ];
    PRegNumPath complexPhyDstRegNum  [ COMPLEX_ISSUE_WIDTH ];

    logic complexReadRegA [ COMPLEX_ISSUE_WIDTH ];
    logic complexReadRegB [ COMPLEX_ISSUE_WIDTH ];

    logic complexWriteReg  [ COMPLEX_ISSUE_WIDTH ];

    PRegDataPath complexSrcRegDataA [ COMPLEX_ISSUE_WIDTH ];
    PRegDataPath complexSrcRegDataB [ COMPLEX_ISSUE_WIDTH ];

    BypassControll complexCtrlOut [ COMPLEX_ISSUE_WIDTH ];
    
    // Execution stage
    BypassControll complexCtrlIn [ COMPLEX_ISSUE_WIDTH ];
    
    PRegDataPath  complexSrcRegDataOutA [ COMPLEX_ISSUE_WIDTH ];
    PRegDataPath  complexSrcRegDataOutB [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  complexSrcVecDataOutA [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  complexSrcVecDataOutB [ COMPLEX_ISSUE_WIDTH ];

    PRegDataPath  complexDstRegDataOut  [ COMPLEX_ISSUE_WIDTH ];
    PVecDataPath  complexDstVecDataOut  [ COMPLEX_ISSUE_WIDTH ];
`endif

    //
    // --- Memory Pipeline
    //
    
    // Register read stage
    PRegNumPath memPhySrcRegNumA [ MEM_ISSUE_WIDTH ];
    PRegNumPath memPhySrcRegNumB [ MEM_ISSUE_WIDTH ];
    PRegNumPath memPhyDstRegNum  [ MEM_ISSUE_WIDTH ];
    
    logic memReadRegA [ MEM_ISSUE_WIDTH ];
    logic memReadRegB [ MEM_ISSUE_WIDTH ];

    logic memWriteReg  [ MEM_ISSUE_WIDTH ];
    
    BypassControll memCtrlOut [ MEM_ISSUE_WIDTH ];
    
    // Execution stage
    BypassControll memCtrlIn [ MEM_ISSUE_WIDTH ];
    
    PRegDataPath memSrcRegDataOutA  [ MEM_ISSUE_WIDTH ];
    PRegDataPath memSrcRegDataOutB  [ MEM_ISSUE_WIDTH ];
    PRegDataPath  memDstRegDataOut  [ MEM_ISSUE_WIDTH ];

`ifdef RSD_ENABLE_VECTOR_PATH
    PVecDataPath  memSrcVecDataOutB [ STORE_ISSUE_WIDTH ];
    PVecDataPath  memDstVecDataOut  [ LOAD_ISSUE_WIDTH ];
`endif
    

    modport BypassController(
    input
        clk,
        rst,
        intPhySrcRegNumA,
        intPhySrcRegNumB,
        intPhyDstRegNum,
        intReadRegA,
        intReadRegB,
        intWriteReg,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexPhySrcRegNumA,
        complexPhySrcRegNumB,
        complexPhyDstRegNum,
        complexReadRegA,
        complexReadRegB,
        complexWriteReg,
`endif
        memPhySrcRegNumA,
        memPhySrcRegNumB,
        memPhyDstRegNum,
        memReadRegA,
        memReadRegB,
        memWriteReg,
    output
        intCtrlOut,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexCtrlOut,
`endif
        memCtrlOut
    );

    modport BypassNetwork(
    input
        clk,
        rst,
        intCtrlIn,
        intDstRegDataOut,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexCtrlIn,
        complexDstRegDataOut,
`endif
        memCtrlIn,
        memDstRegDataOut,
    output
        intSrcRegDataOutA,
        intSrcRegDataOutB,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexSrcRegDataOutA,
        complexSrcRegDataOutB,
`endif
        memSrcRegDataOutA,
        memSrcRegDataOutB
    );

`ifdef RSD_ENABLE_VECTOR_PATH
    modport VectorBypassNetwork(
    input
        clk,
        rst,
        complexCtrlIn,
        complexDstVecDataOut,
        memCtrlIn,
        memDstVecDataOut,
    output
        complexSrcVecDataOutA,
        complexSrcVecDataOutB,
        memSrcVecDataOutB
    );
`endif
    modport IntegerRegisterReadStage(
    input
        clk,
        rst,
        intCtrlOut,
    output
        intPhySrcRegNumA,
        intPhySrcRegNumB,
        intPhyDstRegNum,
        intReadRegA,
        intReadRegB,
        intWriteReg
    );
    
    modport IntegerExecutionStage(
    input
        intSrcRegDataOutA,
        intSrcRegDataOutB,
    output 
        intCtrlIn,
        intDstRegDataOut
    );
    
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    modport ComplexIntegerRegisterReadStage(
    input
        clk,
        rst,
        complexCtrlOut,
    output
        complexPhySrcRegNumA,
        complexPhySrcRegNumB,
        complexPhyDstRegNum,
        complexReadRegA,
        complexReadRegB,
        complexWriteReg
    );
    
    modport ComplexIntegerExecutionStage(
    input
        complexSrcRegDataOutA,
        complexSrcRegDataOutB,
        complexSrcVecDataOutA,
        complexSrcVecDataOutB,
    output 
        complexCtrlIn,
        complexDstRegDataOut,
        complexDstVecDataOut
    );
`endif
    
    modport MemoryRegisterReadStage(
    input
        clk,
        rst,
        memCtrlOut,
    output
        memPhySrcRegNumA,
        memPhySrcRegNumB,
        memPhyDstRegNum,
        memReadRegA,
        memReadRegB,
        memWriteReg
    );

    modport MemoryExecutionStage(
    input
        memSrcRegDataOutA,
        memSrcRegDataOutB,
`ifdef RSD_ENABLE_VECTOR_PATH
        memSrcVecDataOutB,
`endif
    output 
        memCtrlIn
    );

    modport MemoryAccessStage(
    output 
`ifdef RSD_ENABLE_VECTOR_PATH
        memDstVecDataOut,
`endif
        memDstRegDataOut
    );

endinterface : BypassNetworkIF




// ---- RegisterFile/VectorBypassNetwork.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Vector Bypass network
//

import BasicTypes::*;
import PipelineTypes::*;
import BypassTypes::*;

typedef struct packed // struct VectorBypassOperand
{
    PVecDataPath value;
} VectorBypassOperand;


module VectorBypassStage(
    input  logic clk, rst,
    input  PipelineControll ctrl,
    input  VectorBypassOperand in,
    output VectorBypassOperand out
);
    VectorBypassOperand body;

    always_ff@( posedge clk )               // synchronous rst
    begin
        if( rst || ctrl.clear ) begin              // rst
            body.value.data <= 0;
            body.value.valid <= 0;
        end
        else if( ctrl.stall ) begin         // write data
            body <= body;
        end
        else begin
            body <= in;
        end
    end

    assign out = body;
endmodule

`ifdef RSD_ENABLE_VECTOR_PATH

module VectorBypassNetwork(
    BypassNetworkIF.VectorBypassNetwork port,
    ControllerIF.VectorBypassNetwork ctrl
);
    function automatic PVecDataPath SelectData(
    input
        BypassSelect sel,
        VectorBypassOperand memMA [ LOAD_ISSUE_WIDTH ],
        VectorBypassOperand memWB [ LOAD_ISSUE_WIDTH ]
    );
        if( sel.stg == BYPASS_STAGE_MEM_MA )
            return memMA[sel.lane.memLane].value;
        else   if( sel.stg == BYPASS_STAGE_MEM_WB )
            return memWB[sel.lane.memLane].value;
        else
            return '0;

    endfunction


    VectorBypassOperand memDst [ LOAD_ISSUE_WIDTH ];
    VectorBypassOperand memMA  [ LOAD_ISSUE_WIDTH ];
    VectorBypassOperand memWB  [ LOAD_ISSUE_WIDTH ];

    generate
        for ( genvar i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin : stgMem
            VectorBypassStage stgMemMA( port.clk, port.rst, ctrl.backEnd, memDst[i], memMA[i] );
            VectorBypassStage stgMemWB( port.clk, port.rst, ctrl.backEnd, memMA[i],  memWB[i] );
        end
    endgenerate

    always_comb begin

        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            port.complexSrcVecDataOutA[i] = SelectData( port.complexCtrlIn[i].rA, memMA, memWB );
            port.complexSrcVecDataOutB[i] = SelectData( port.complexCtrlIn[i].rB, memMA, memWB );
        end

        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            memDst[i].value = port.memDstVecDataOut[i];
        end

        for ( int i = 0; i < STORE_ISSUE_WIDTH; i++ ) begin
            port.memSrcVecDataOutB[i] = SelectData( port.memCtrlIn[(i+STORE_ISSUE_LANE_BEGIN)].rB, memMA, memWB );
        end
    end
endmodule : VectorBypassNetwork

`endif
// ---- ExecUnit/BitCounter.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Bit counter unit (Process CLZ instruction)
//

import BasicTypes::*;
import OpFormatTypes::*;

// ビット・カウンタ
// データの上位から0が連続しているビットの数を出力
module BitCounter(
input
    DataPath fuOpA_In,
output
    DataPath dataOut
);
    DataPath count;
    
    always_comb begin
        for ( count = 0; count < DATA_WIDTH; count++ ) begin
            if ( fuOpA_In[ DATA_WIDTH - count - 1 ] == TRUE )
                break;
        end
        dataOut = count;
    end

endmodule : BitCounter

// パイプライン化されたビット・カウンタ
// PIPELINE_DEPTHは2以上でなければならない
module PipelinedBitCounter#( 
    parameter PIPELINE_DEPTH = 3
)(
input
    clk, rst, stall,
    DataPath fuOpA_In,
output
    DataPath dataOut
);
    DataPath pipeReg[ PIPELINE_DEPTH-1 ]; // synthesis syn_pipeline = 1
    DataPath count;
    
    always_comb begin
        for ( count = 0; count < DATA_WIDTH; count++ ) begin
            if ( fuOpA_In[ DATA_WIDTH - count - 1 ] == TRUE )
                break;
        end
        dataOut = pipeReg[ PIPELINE_DEPTH-2 ];
    end

    always_ff @(posedge clk) begin
        if ( rst ) begin
            for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= '0;
        end
        else if ( stall ) begin
            for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= pipeReg[i];
        end
        else begin
            pipeReg[0] <= count;
            for ( int i = 1; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= pipeReg[i-1];
        end
    end

endmodule : PipelinedBitCounter
// ---- ExecUnit/IntALU.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// 32bit ARM ALU
//


import BasicTypes::*;
import MicroOpTypes::*;
import OpFormatTypes::*;
import PipelineTypes::*;


typedef struct packed 
{
    logic    carry;
    DataPath data;
} IntAdderResult;


// 加算機
// inv がアサートされたオペランドはビット反転を行う
module IntAdder(
output 
    IntAdderResult dst,
    logic overflowOut,
input
    DataPath srcA, logic invA,
    DataPath srcB, logic invB,
    logic carryIn
);
    function automatic DataPath Inv(
        input DataPath src, logic inv
    );
        return inv ? ~src : src;
    endfunction

    DataPath tmpA, tmpB;
    always_comb begin
        tmpA = Inv( srcA, invA );
        tmpB = Inv( srcB, invB );
        dst  = tmpA + tmpB + carryIn;
        overflowOut =
            ( dst.data[DATA_WIDTH-1] ^ tmpA[DATA_WIDTH-1] ) &&
            ( dst.data[DATA_WIDTH-1] ^ tmpB[DATA_WIDTH-1] );
    end
endmodule


module IntALU(
    output
        DataPath aluDataOut,
    input 
        IntALU_Code aluCode,
        DataPath fuOpA_In,
        DataPath fuOpB_In
);
    
    IntAdderResult opDst;
    
    
    DataPath opA;
    DataPath opB;
    SignedDataPath signedOpA;
    SignedDataPath signedOpB;
    
    IntAdderResult adderDst;
    DataPath adderInA; logic adderInvInA;
    DataPath adderInB; logic adderInvInB;
    logic    adderInCarry;
    logic    adderOutOverflow;
    
    IntAdder adder(
        .dst(adderDst),
        .srcA(adderInA),
        .invA(adderInvInA),
        .srcB(adderInB),
        .invB(adderInvInB),
        .carryIn(adderInCarry),
        .overflowOut(adderOutOverflow)
    );

    `define Add( a, ia, b, ib, c ) begin \
        adderInA     = a;  \
        adderInvInA  = ia; \
        adderInB     = b;  \
        adderInvInB  = ib; \
        adderInCarry = c;  \
        opDst        = adderDst; \
    end \
    
    `define Logic( a ) begin \
        adderInA     = '0;  \
        adderInvInA  = FALSE; \
        adderInB     = '0;  \
        adderInvInB  = FALSE; \
        adderInCarry = 0;  \
        opDst        = { 1'b0, (a) }; \
    end \


    // Operation
    always_comb begin
        
        opA     = fuOpA_In;
        opB     = fuOpB_In;
        
        case( aluCode )
            // AND  論理積
            default: `Logic( opA & opB )
            
            // EOR  排他的論理和
            AC_EOR: `Logic( opA ^ opB )
            
            // SUB  減算
            // a - b = a + ~b + 1
            AC_SUB: `Add( opA, FALSE, opB, TRUE, 1  )   
            
            // ADD  加算
            AC_ADD: `Add( opA, FALSE, opB, FALSE, 0 )       
            
            // SLT  比較   Rd = if Rs1 < Rs2 then 1 else 0
            AC_SLT : begin
                signedOpA = opA;
                signedOpB = opB;
                `Logic( { 31'h0, ( signedOpA < signedOpB) } )
            end
            // SLTU  符号なし比較
            AC_SLTU: `Logic( { 31'h0, ( opA < opB ) } )
            
            // ORR  （包含的）論理和    Rd := Rn OR shifter_operand
            AC_ORR: `Logic( opA | opB )

        endcase

        aluDataOut   = opDst.data;
    end
    


endmodule : IntALU
// ---- ExecUnit/Shifter.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// ARM shifter unit (32bit)
//
// Todo: Rotation operation in a register mode when its shift amount is zero is 
// not implemented correctly and must be fixed.
// 

import BasicTypes::*;
import OpFormatTypes::*;


//
// An straightforward implementation of a shifter unit.
// Do not remove this implementation because this implementation is used for
// verification.
//
module OrgShifter(
input
    ShiftOperandType shiftOperandType,
    ShiftType shiftType,
    ShiftAmountPath immShiftAmount,
    ShiftAmountPath regShiftAmount,
    DataPath dataIn,
    logic carryIn,
output
    DataPath dataOut,
    logic carryOut
);

    typedef struct {
        DataPath dataOut; 
        logic    carryOut;
    } ShiftResult;
    
    //
    // --- Immediate shift
    //
    function automatic ShiftResult OpImmShift(
        ShiftType shiftType, 
        ShiftAmountPath shiftAmount,
        DataPath dataIn,
        logic    carryIn 
    );
        logic [DATA_WIDTH:0] shiftTmp;  // not DataPath
        ShiftResult result;
        DataPath dataOut;
        logic    carryOut;
        
        case( shiftType ) 

        // Logical shift left
        default: begin
        //ST_LSL: begin
            if( shiftAmount == 0 ) begin
                dataOut  = dataIn;
                carryOut = carryIn;
            end
            else begin
                shiftTmp = dataIn << shiftAmount;
                dataOut  = shiftTmp[DATA_WIDTH-1:0];
                carryOut = shiftTmp[DATA_WIDTH];
            end
        end
        
        // Logical shift right
        ST_LSR: begin
            if( shiftAmount == 0 ) begin
                dataOut  = 0;
                carryOut = dataIn[DATA_WIDTH-1];
            end
            else begin
                shiftTmp = {dataIn, 1'b0} >> shiftAmount;
                dataOut  = shiftTmp[DATA_WIDTH:1];
                carryOut = shiftTmp[0];
            end
        end
                    
        // Arithmetic shift right
        ST_ASR: begin
            if( shiftAmount == 0 ) begin
                if( dataIn[DATA_WIDTH-1] == 0 ) begin
                    dataOut  = 0;
                    carryOut = dataIn[DATA_WIDTH-1];
                end
                else begin
                    dataOut  = 32'hffffffff;
                    carryOut = dataIn[DATA_WIDTH-1];
                end
            end 
            else begin
                shiftTmp = {{DATA_WIDTH{dataIn[DATA_WIDTH-1]}}, dataIn, 1'b0} >> shiftAmount;
                dataOut  = shiftTmp[DATA_WIDTH:1];
                carryOut = shiftTmp[0];
            end
        end

        // RRX/Rotate
        ST_ROR: begin
            if( shiftAmount == 0 ) begin
                dataOut  = {carryIn, dataIn[DATA_WIDTH-1:1]};
                carryOut = dataIn[0];
            end
            else begin
                shiftTmp = {dataIn, dataIn, 1'b0} >> shiftAmount;
                dataOut  = shiftTmp[DATA_WIDTH:1];
                carryOut = shiftTmp[0];
            end
        end
        endcase
        
        result.dataOut = dataOut;
        result.carryOut = carryOut;
        return result;
    endfunction : OpImmShift
    
    
    
    //
    // --- Register shift
    // 
    //  Todo:シフト量が32を超えた場合の挙動がおかしい
    //
    function automatic ShiftResult OpRegShift(
    input
        ShiftType shiftType, 
        ShiftAmountPath shiftAmount,
        DataPath           dataIn,
        logic [4:0]        shiftIn,
        logic              carryIn 
    );

        logic [DATA_WIDTH:0] shiftTmp;  // not DataPath
        DataPath    dataOut;
        logic       carryOut;
        ShiftResult result;
        
        case( shiftType ) 

        // Logical shift left
        //ST_LSL: begin
        default: begin
            if( shiftIn == 0 ) begin
                dataOut  = dataIn;
                carryOut = carryIn;
            end
            else begin
                shiftTmp = dataIn << shiftIn;
                dataOut  = shiftTmp[DATA_WIDTH-1:0];
                carryOut = shiftTmp[DATA_WIDTH];
            end
        end
        
        // Logical shift right
        ST_LSR: begin
            if( shiftIn == 0 ) begin
                dataOut  = 0;
                carryOut = dataIn[DATA_WIDTH-1];
            end
            else begin
                shiftTmp = {dataIn, 1'b0} >> shiftIn;
                dataOut  = shiftTmp[DATA_WIDTH:1];
                carryOut = shiftTmp[0];
            end
        end
                    
        // Arithmetic shift right
        ST_ASR: begin
            if( shiftIn == 0 ) begin
                if( dataIn[DATA_WIDTH-1] == 0 ) begin
                    dataOut  = 0;
                    carryOut = dataIn[DATA_WIDTH-1];
                end
                else begin
                    dataOut  = 32'hffffffff;
                    carryOut = dataIn[DATA_WIDTH-1];
                end
            end 
            else begin
                shiftTmp = {{DATA_WIDTH{dataIn[DATA_WIDTH-1]}}, dataIn, 1'b0} >> shiftAmount;
                dataOut  = shiftTmp[DATA_WIDTH:1];
                carryOut = shiftTmp[0];
            end
        end

        // Rotate
        ST_ROR: begin
            if( shiftIn == 0 ) begin
                dataOut  = {carryIn, dataIn[DATA_WIDTH-1:1]};
                carryOut = dataIn[0];
            end
            else begin
                shiftTmp = {dataIn, dataIn, 1'b0} >> shiftIn;
                dataOut  = shiftTmp[DATA_WIDTH:1];
                carryOut = shiftTmp[0];
            end
        end
        endcase

        result.dataOut = dataOut;
        result.carryOut = carryOut;
        return result;
    endfunction : OpRegShift

    
    ShiftResult shiftResult;
    always_comb begin
        case( shiftType )

        // Immediate
        //SOT_IMM: begin

        // Immediate shift
        default: begin
        //SOT_IMM_SHIFT: begin
            shiftResult = OpImmShift( shiftType, immShiftAmount, dataIn, carryIn );
        end
        
        // Register shift
        SOT_REG_SHIFT: begin
            shiftResult = OpRegShift( shiftType, immShiftAmount, dataIn, regShiftAmount, carryIn );
        end

        endcase
        
        dataOut = shiftResult.dataOut;
        carryOut = shiftResult.carryOut;
    end
    

endmodule : OrgShifter



//
// --- An optimized implementation of a shifter unit.
//
module Shifter(
input
    ShiftOperandType shiftOperandType,
    ShiftType shiftType,
    ShiftAmountPath immShiftAmount,
    ShiftAmountPath regShiftAmount,
    DataPath dataIn,
    logic carryIn,
output
    DataPath dataOut,
    logic carryOut
);

    ShiftAmountPath shiftAmount;

    // This shifter unit is implemented with an unified 65-to-33 right shifter.
    logic [DATA_WIDTH*2+1:0] unifiedShiftTmp;
    DataPath unifiedShiftHighIn;
    DataPath unifiedShiftLowIn;
    logic [DATA_WIDTH+1:0] unifiedShiftOut;
    logic [SHIFT_AMOUNT_BIT_SIZE:0] unifiedShiftAmount;
    logic isShiftZero;

    always_comb begin
        
        //
        // --- Select a shift amount.
        //
        case( shiftOperandType )

            // Immediate shift
            default: begin        //SOT_IMM_SHIFT: begin
                shiftAmount = immShiftAmount;
            end
            
            // Register shift
            SOT_REG_SHIFT: begin
                shiftAmount = regShiftAmount;
            end

        endcase
        

        isShiftZero = (shiftAmount == 0) ? TRUE : FALSE;
        

        case( shiftType ) 

        // Logical shift left
        ST_LSL: begin
            //if( shiftAmount == 0 ) begin
            //    dataOut  = dataIn;
            //    carryOut = carryIn;
            //end
            //else begin
            //    shiftTmp = dataIn << shiftAmount;
            //    dataOut  = shiftTmp[DATA_WIDTH-1:0];
            //    carryOut = shiftTmp[DATA_WIDTH];
            //end        
            unifiedShiftAmount = DATA_WIDTH - shiftAmount;
            unifiedShiftHighIn = dataIn;
            unifiedShiftLowIn = 0;
        end
        
        // Logical shift right
        ST_LSR: begin
        
            //if( shiftAmount == 0 ) begin
            //    dataOut  = 0;
            //    carryOut = dataIn[DATA_WIDTH-1];
            //end
            //else begin
            //    shiftTmp = {dataIn, 1'b0} >> shiftAmount;
            //    dataOut  = shiftTmp[DATA_WIDTH:1];
            //    carryOut = shiftTmp[0];
            //end        
        
            //unifiedShiftAmount = isShiftZero ? DATA_WIDTH : shiftAmount;
            unifiedShiftAmount = shiftAmount;
            unifiedShiftHighIn = 0;
            unifiedShiftLowIn = dataIn;
        end
                    
        // Arithmetic shift right
        ST_ASR: begin
            //if( shiftAmount == 0 ) begin
            //    if( dataIn[DATA_WIDTH-1] == 0 ) begin
            //        dataOut  = 0;
            //        carryOut = dataIn[DATA_WIDTH-1];
            //    end
            //    else begin
            //        dataOut  = 32'hffffffff;
            //        carryOut = dataIn[DATA_WIDTH-1];
            //    end
            //end 
            //else begin
            //    shiftTmp = {dataIn, 1'b0} >>> shiftAmount;
            //    dataOut  = shiftTmp[DATA_WIDTH:1];
            //    carryOut = shiftTmp[0];
            //end
            //unifiedShiftAmount = isShiftZero ? DATA_WIDTH : shiftAmount;
            unifiedShiftAmount = shiftAmount;
            unifiedShiftHighIn = {DATA_WIDTH{dataIn[DATA_WIDTH-1]}};
            unifiedShiftLowIn = dataIn;
        end

        // RRX/Rotate
        ST_ROR: begin
            //if( shiftAmount == 0 ) begin
            //    dataOut  = {carryIn, dataIn[DATA_WIDTH-1:1]};
            //    carryOut = dataIn[0];
            //end
            //else begin
            //    shiftTmp = {dataIn, dataIn, 1'b0} >> shiftAmount;
            //    dataOut  = shiftTmp[DATA_WIDTH:1];
            //    carryOut = shiftTmp[0];
            //end
            //unifiedShiftAmount = isShiftZero ? 1 : shiftAmount;
            unifiedShiftAmount = shiftAmount;
            unifiedShiftHighIn = {dataIn[DATA_WIDTH-1:1], (isShiftZero ? carryIn : dataIn[0])};
            unifiedShiftLowIn = dataIn;
        end
        endcase


        // Source of a 65-to-33 right shifter.
        unifiedShiftTmp = {carryIn, unifiedShiftHighIn, unifiedShiftLowIn, 1'b0};
        

        // Optimized implementation of 65-to-33 right shifter.
        // Original implementation:
        //   unifiedShiftOut = unifiedShiftTmp >> unifiedShiftAmount;
        /*
        unifiedShiftTmp = unifiedShiftAmount[5] ? unifiedShiftTmp[65:32] : unifiedShiftTmp[64:0];
        unifiedShiftTmp = unifiedShiftAmount[4] ? unifiedShiftTmp[64:16] : unifiedShiftTmp[48:0];
        unifiedShiftTmp = unifiedShiftAmount[3] ? unifiedShiftTmp[48:8] :  unifiedShiftTmp[40:0];
        unifiedShiftTmp = unifiedShiftAmount[2] ? unifiedShiftTmp[40:4] :  unifiedShiftTmp[36:0];
        unifiedShiftTmp = unifiedShiftAmount[1] ? unifiedShiftTmp[36:2] :  unifiedShiftTmp[34:0];
        unifiedShiftTmp = unifiedShiftAmount[0] ? unifiedShiftTmp[34:1] :  unifiedShiftTmp[33:0];
        */
        
        // Each 4:1 selector will be synthesized to 6:1 LUT.
        case(unifiedShiftAmount[5:4])
            2'h3: unifiedShiftTmp = 49'hx;
            2'h2: unifiedShiftTmp = {15'hx, unifiedShiftTmp[65:32]};
            2'h1: unifiedShiftTmp = unifiedShiftTmp[64:16];
            2'h0: unifiedShiftTmp = unifiedShiftTmp[48:0];
        endcase
        case(unifiedShiftAmount[3:2])
            2'h3: unifiedShiftTmp = unifiedShiftTmp[48:12];
            2'h2: unifiedShiftTmp = unifiedShiftTmp[44:8];
            2'h1: unifiedShiftTmp = unifiedShiftTmp[40:4];
            2'h0: unifiedShiftTmp = unifiedShiftTmp[36:0];
        endcase
        case(unifiedShiftAmount[1:0])
            2'h3: unifiedShiftTmp = unifiedShiftTmp[36:3];
            2'h2: unifiedShiftTmp = unifiedShiftTmp[35:2];
            2'h1: unifiedShiftTmp = unifiedShiftTmp[34:1];
            2'h0: unifiedShiftTmp = unifiedShiftTmp[33:0];
        endcase

        unifiedShiftOut = unifiedShiftTmp;
        
        
        // Output results.
        dataOut = unifiedShiftOut[DATA_WIDTH:1];
        
        case( shiftType ) 
            // Logical shift left
            ST_LSL: carryOut = unifiedShiftOut[DATA_WIDTH+1];
            
            // Logical shift right
            // Arithmetic shift right
            // RRX/Rotate
            default: carryOut = unifiedShiftOut[0];
        endcase
    end
    

endmodule : Shifter

// ---- ExecUnit/MultiplierUnit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Multiplier Unit
// This unit performs 32bit*32bit = 32bit,
// and return upper or lower 32 bit
//

import BasicTypes::*;
import MicroOpTypes::*;
import OpFormatTypes::*;

// Multiplier Unit
module MultiplierUnit (
input
    DataPath fuOpA_In,
    DataPath fuOpB_In,
    logic getUpper, // If TRUE, the multiplication result 33-64 bit is set to mulDataOut
output
    DataPath dataOut
);
    logic [ 2*DATA_WIDTH-1:0 ] mulResult;
    
    Multiplier #( 
        .BIT_WIDTH( $bits(DataPath) )
    ) mul ( 
        .srcA(fuOpA_In),
        .srcB(fuOpB_In),
        .dst(mulResult)
    );
    
    always_comb begin
        if (getUpper)
            dataOut = mulResult[ 2*DATA_WIDTH-1:DATA_WIDTH ];
        else
            dataOut = mulResult[ DATA_WIDTH-1:0 ];
    end
    
endmodule : MultiplierUnit


// Pipelined Multiplier Unit
module PipelinedMultiplierUnit #( 
    parameter BIT_WIDTH = 32,
    parameter PIPELINE_DEPTH = 3
)( 
input
    logic clk, stall,
    DataPath fuOpA_In,
    DataPath fuOpB_In,
    logic getUpper, // If TRUE, the multiplication result 33-64 bit is set to mulDataOut
    IntMUL_Code mulCode,
output
    DataPath dataOut
);
    
    typedef struct packed { // PipeReg
        logic getUpper;
        IntMUL_Code mulCode;
        logic fuOpA_sign;
        logic fuOpB_sign;
    } PipeReg;
    
    PipeReg pipeReg[ PIPELINE_DEPTH-1 ];
    
    logic [ 2*DATA_WIDTH-1:0 ] mulResult;
    //logic signed [ 2*DATA_WIDTH-1:0 ] mulResult_signed;
    //logic signed [ 2*DATA_WIDTH-1:0 ] dataOut_signed;
    logic signed [ DATA_WIDTH-1:0 ] fuOpA_signed;
    logic signed [ DATA_WIDTH-1:0 ] fuOpB_signed;
    logic fuOpA_sign;
    logic fuOpB_sign;
    //logic signed [ DATA_WIDTH-1:0 ] srcA_signed;
    //logic signed [ DATA_WIDTH-1:0 ] srcB_signed;
    logic signA;
    logic signB;
    logic [ DATA_WIDTH-1:0 ] srcA;
    logic [ DATA_WIDTH-1:0 ] srcB;

    PipelinedMultiplier #( 
        .BIT_WIDTH( $bits(DataPath) ),
        .PIPELINE_DEPTH( PIPELINE_DEPTH )
    ) mul (
        .clk( clk ),
        .stall( stall ),
        .srcA(srcA),
        .srcB(srcB),
        .signA(signA),
        .signB(signB),
        .dst(mulResult)
    );

    // Make src operands unsigned(plus) value.
    always_comb begin
        // fuOpA_signed = fuOpA_In;
        // fuOpB_signed = fuOpB_In;
        // fuOpA_sign = (fuOpA_signed < 0);
        // fuOpB_sign = (fuOpB_signed < 0);

        if ( mulCode == AC_MULHU ) begin
            // // MULHU takes srcA as unsigned.
            // srcA_signed = fuOpA_signed;
            signA = '0;
        end
        else begin
            // // Make fuOpA_In plus value when it is minus value. 
            // if (fuOpA_sign) begin
            //     srcA_signed = -fuOpA_signed;
            // end
            // else begin
            //     srcA_signed = fuOpA_signed;
            // end
            signA = '1;
        end

        if ( (mulCode == AC_MULHU) || (mulCode == AC_MULHSU) ) begin
            // // MULHU and MULHSU take srcB as unsigned.
            // srcB_signed = fuOpB_signed;
            signB = '0;
        end
        else begin
            // // Make fuOpB_In plus value when it is minus value. 
            // if (fuOpB_sign) begin
            //     srcB_signed = -fuOpB_signed;
            // end
            // else begin
            //     srcB_signed = fuOpB_signed;
            // end
            signB = '1;
        end

        // srcA = srcA_signed;
        // srcB = srcB_signed;
        srcA = fuOpA_In;
        srcB = fuOpB_In;
    end

    always_comb begin
        // mulResult_signed = mulResult;

        // case (pipeReg[ PIPELINE_DEPTH-2 ].mulCode)
        //     AC_MUL, AC_MULH: begin
        //         if (pipeReg[ PIPELINE_DEPTH-2 ].fuOpA_sign ^ pipeReg[ PIPELINE_DEPTH-2 ].fuOpA_sign) begin
        //             dataOut_signed = -mulResult_signed;
        //         end
        //         else begin
        //             dataOut_signed = mulResult_signed;
        //         end
        //     end
        //     AC_MULHSU: begin
        //         if (pipeReg[ PIPELINE_DEPTH-2 ].fuOpA_sign) begin
        //             dataOut_signed = -mulResult_signed;
        //         end
        //         else begin
        //             dataOut_signed = mulResult_signed;
        //         end
        //     end
        //     AC_MULHU: begin
        //         dataOut_signed = mulResult_signed;
        //     end
        //     default: begin
        //         dataOut_signed = mulResult_signed;
        //     end
        // endcase

        // if ( pipeReg[ PIPELINE_DEPTH-2 ].getUpper ) begin
        //     dataOut = dataOut_signed[ 2*DATA_WIDTH-1:DATA_WIDTH ];
        // end
        // else begin
        //     dataOut = dataOut_signed[ DATA_WIDTH-1:0 ];
        // end

        if ( pipeReg[ PIPELINE_DEPTH-2 ].getUpper ) begin
            dataOut = mulResult[ 2*DATA_WIDTH-1:DATA_WIDTH ];
        end
        else begin
            dataOut = mulResult[ DATA_WIDTH-1:0 ];
        end
    end
    
    always_ff @(posedge clk) begin
        if ( stall ) begin
            for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= pipeReg[i];
        end
        else begin
            pipeReg[0].getUpper <= getUpper;
            pipeReg[0].mulCode  <= mulCode;
            pipeReg[0].fuOpA_sign <= fuOpA_sign;
            pipeReg[0].fuOpB_sign <= fuOpB_sign;
            for ( int i = 1; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= pipeReg[i-1];
        end
    end
    
`ifndef RSD_SYNTHESIS
    initial begin
        for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
            pipeReg[i] <= '0;
    end
`endif

endmodule : PipelinedMultiplierUnit
// ---- ExecUnit/VectorUnit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Vector Unit
//
// - SIMD命令のために、ベクトル演算を行うユニット
//
import BasicTypes::*;
import MicroOpTypes::*;
import OpFormatTypes::*;

// パイプライン化されたベクトル加算ユニット
// PIPELINE_DEPTHは2以上でなければならない
module PipelinedVectorAdder #(
    parameter PIPELINE_DEPTH = 3
)(
input
    logic clk, stall,
    VectorPath fuOpA_In,
    VectorPath fuOpB_In,
output
    VectorPath dataOut
);
    VectorPath pipeReg[ PIPELINE_DEPTH-1 ]; // synthesis syn_pipeline = 1
    DataPath [ VEC_WORD_WIDTH-1:0 ] srcA, srcB, dst;

    always_comb begin
        // `RSD_ASSERT_CLK(clk, PIPELINE_DEPTH > 1, "A pipeline depth of a PipelinedVectorAdder module must be more than 1.");

        srcA = fuOpA_In;
        srcB = fuOpB_In;

        for( int i = 0; i < VEC_WORD_WIDTH; i++ ) begin
            dst[i] = srcA[i] + srcB[i];
        end

        dataOut = pipeReg[ PIPELINE_DEPTH-2 ];
    end

    always_ff @(posedge clk) begin
        if ( stall ) begin
            for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= pipeReg[i];
        end
        else begin
        pipeReg[0] <= dst;
            for ( int i = 1; i < PIPELINE_DEPTH-1; i++)
                pipeReg[i] <= pipeReg[i-1];
        end
    end

    `ifndef RSD_SYNTHESIS
    initial begin
        for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
            pipeReg[i] <= '0;
    end
    `endif
endmodule


// パイプライン化されたベクトル乗算ユニット
module PipelinedVectorMultiplier #(
    parameter PIPELINE_DEPTH = 3
)(
input
    logic clk, stall,
    VectorPath fuOpA_In,
    VectorPath fuOpB_In,
    logic getUpper, // TRUEなら、乗算結果の33-64bit目をmulDataOutにセット
    IntMUL_Code mulCode,
output
    VectorPath dataOut
);
    DataPath [ VEC_WORD_WIDTH-1:0 ] srcA, srcB, dst;

    for ( genvar i = 0; i < VEC_WORD_WIDTH; i++ ) begin : mulUnit
        PipelinedMultiplierUnit #(
            .BIT_WIDTH( DATA_WIDTH ),
            .PIPELINE_DEPTH( PIPELINE_DEPTH )
        ) mulUnit (
            .clk( clk ),
            .stall( stall ),
            .fuOpA_In( srcA[i] ),
            .fuOpB_In( srcB[i] ),
            .getUpper( getUpper ),
            .mulCode( mulCode ),
            .dataOut( dst[i] )
        );
    end

    always_comb begin
        srcA = fuOpA_In;
        srcB = fuOpB_In;
        dataOut = dst;
    end
endmodule
// ---- ExecUnit/PipelinedRefDivider.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Pipelined Reference Divider Unit
// This unit performs signed/unsigned divisiton with arbitrary cycles
//

import BasicTypes::*;
 
module PipelinedRefDivider # (
    parameter BIT_WIDTH = 32,
    parameter PIPELINE_DEPTH = 3
)(
input
    logic clk,         // clock, reset
    //logic req,              // request a new operation
    logic stall,
    DataPath dividend,
    DataPath divisor,
    logic isSigned,          // operation is performed in a singed mode
output
    //logic finished,
    DataPath quotient,
    DataPath remainder
);

    parameter DATA_MINUS_ONE = (1 << DATA_WIDTH) - 1;
    parameter DATA_MINIMUM = (1 << (DATA_WIDTH - 1));

    typedef enum logic[1:0]
    {
        PHASE_FINISHED = 0,     // Division is finished. It outputs results to quotient, remainder 
        PHASE_PROCESSING = 1,   // In processing
        PHASE_COMPENSATING = 2,  // In processing for compensating results
        PHASE_NOTHING_TO_DO = 3
    } Phase;
    Phase regPhase, nextPhase;


    typedef struct packed { // PipeReg
        DataPath dividend;
        DataPath divisor;
        logic isSigned;          // operation is performed in a singed mode
        DataPath quotient;
        DataPath remainder;
        Phase phase;
    } PipeReg;

    PipeReg pipeReg[ PIPELINE_DEPTH-1 ], nextReg;

    always_ff @(posedge clk) begin
        if (!stall) begin 
            pipeReg[0] <= nextReg;
            for ( int i = 1; i < PIPELINE_DEPTH-1; i++) begin
                pipeReg[i] <= pipeReg[i-1];
            end
        end
    end


    always_comb begin
        //finished = (pipeReg[PIPELINE_DEPTH-2].phase == PHASE_FINISHED) ? TRUE : FALSE;
        quotient = pipeReg[PIPELINE_DEPTH-2].quotient;
        remainder = pipeReg[PIPELINE_DEPTH-2].remainder;

        //if (req) begin
            // A request is accepted regardless of the current phase
            nextReg.dividend = dividend;
            nextReg.divisor = divisor;
            nextReg.isSigned = isSigned;

            if (divisor == 0) begin
                // Division by zero
                nextReg.quotient = -1;
                nextReg.remainder = dividend;
            end
            else begin
                if (!isSigned) begin
                    if (dividend == DATA_MINIMUM && divisor == DATA_MINUS_ONE) begin
                        // Sigined division can cause overflow
                        // ex. 8 bits signed division "-0x80 / -1 = 0x80"
                        // causes overflow because the resulst 0x80 > 0x7f
                        nextReg.quotient = dividend;
                        nextReg.remainder = '0;
                    end
                    else begin
                        nextReg.quotient = $signed(dividend) / $signed(divisor);
                        nextReg.remainder = $signed(dividend) % $signed(divisor);
                    end
                end
                else begin
                    nextReg.quotient = dividend / divisor;
                    nextReg.remainder = dividend % divisor;
                end
            end
            nextReg.phase = PHASE_FINISHED;
        /*end
        else begin 
            nextReg.dividend = '0;
            nextReg.divisor = '0;
            nextReg.isSigned = '0;
            nextReg.quotient = '0;
            nextReg.remainder = '0;
            nextReg.phase = PHASE_NOTHING_TO_DO;
        end*/
    end


`ifndef RSD_SYNTHESIS
    initial begin
        for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
            pipeReg[i] <= '0;
    end
`endif

endmodule : PipelinedRefDivider
// ---- ExecUnit/DividerUnit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Divider Unit
//
// - 32bit/32bit=32bitを行うモジュール
//

import BasicTypes::*;
import MicroOpTypes::*;
import OpFormatTypes::*;

// 除算ユニット
module DividerUnit (
input
    logic clk, rst,
    logic req,
    DataPath fuOpA_In,
    DataPath fuOpB_In,
    IntDIV_Code divCode,
output
    logic finished,
    DataPath dataOut
);

    logic regIsSigned, nextIsSigned;
    DataPath regDividend, nextDividend;
    DataPath regDivisor, nextDivisor;
    IntDIV_Code regDivCode, nextDivCode;
    DataPath quotient, remainder;
    
    QuickDivider div ( 
        .clk( clk ),
        .rst( rst ),
        .req ( req ),
        .dividend ( nextDividend ),
        .divisor ( nextDivisor ),
        .isSigned ( nextIsSigned ),
        .finished ( finished ),
        .quotient ( quotient ),
        .remainder ( remainder )
    );
    
// IntDIV code
/*
typedef enum logic [1:0]    // enum IntDIV_Code
{
    AC_DIV    = 2'b00,    // DIV    
    AC_DIVU   = 2'b01,    // DIVU
    AC_REM    = 2'b10,    // REM 
    AC_REMU   = 2'b11     // REMU  
} IntDIV_Code;
*/

    always_ff @(posedge clk) begin
        if (rst) begin
            regIsSigned <= FALSE;
            regDividend <= '0;
            regDivisor <= '0;
            regDivCode <= AC_DIV;
        end
        else begin
            regIsSigned <= nextIsSigned;
            regDividend <= nextDividend;
            regDivisor <= nextDivisor;
            regDivCode <= nextDivCode;
        end
    end

    // Make src operands unsigned(plus) value.
    always_comb begin
        if (req) begin
            if (divCode == AC_DIVU || divCode == AC_REMU) begin
                // DIVU and REMU take srcs as unsigned.
                nextIsSigned = FALSE;
            end
            else begin
                // DIV and REM take srcs as signed.
                nextIsSigned = TRUE;
            end
            nextDividend = fuOpA_In;
            nextDivisor = fuOpB_In;
            nextDivCode = divCode;
        end
        else begin
            // Keep the value 
            nextIsSigned = regIsSigned;
            nextDividend = regDividend;
            nextDivisor = regDivisor;
            nextDivCode = regDivCode;
        end

        // Choose output from div or rem.
        if (regDivCode == AC_DIV || regDivCode == AC_DIVU) begin
            dataOut = quotient;
        end
        else begin
            dataOut = remainder;
        end
    end

endmodule : DividerUnit


// パイプライン化された除算ユニット
module PipelinedDividerUnit #( 
    parameter BIT_WIDTH = 32,
    parameter PIPELINE_DEPTH = 3
)( 
input
    logic clk, 
    logic stall,
    logic req,
    DataPath fuOpA_In,
    DataPath fuOpB_In,
    IntDIV_Code divCode,
output
    logic finished,
    DataPath dataOut
);
    
    typedef struct packed { // PipeReg
        logic valid;
        logic isSigned;
        IntDIV_Code divCode;
    } PipeReg;
    
    PipeReg pipeReg[ PIPELINE_DEPTH-1 ], nextReg;
    
    DataPath quotient, remainder;
    logic isSigned;
    DataPath dividend;
    DataPath divisor;

    PipelinedRefDivider #( 
        .BIT_WIDTH( $bits(DataPath) ),
        .PIPELINE_DEPTH( PIPELINE_DEPTH )
    ) div (
        .clk( clk ),
        .stall( stall ),
        .dividend(dividend),
        .divisor(divisor),
        .isSigned(isSigned),
        .quotient(quotient),
        .remainder(remainder)
    );

    always_ff @(posedge clk) begin
        if (!stall) begin
            pipeReg[0] <= nextReg;
            for (int i = 1; i < PIPELINE_DEPTH-1; i++) begin
                pipeReg[i] <= pipeReg[i-1];
            end
        end
    end

    // Make src operands unsigned(plus) value.
    always_comb begin
        if (divCode == AC_DIVU || divCode == AC_REMU) begin
            // // MULHU takes srcA as unsigned.
            // srcA_signed = fuOpA_signed;
            isSigned = TRUE;
        end
        else begin
            isSigned = FALSE;
        end


        dividend = fuOpA_In;
        divisor = fuOpB_In;

        nextReg.isSigned = isSigned;
        nextReg.divCode = divCode;
        nextReg.valid = req;

        if (pipeReg[PIPELINE_DEPTH-2].valid) begin
            if (pipeReg[PIPELINE_DEPTH-2].divCode == AC_DIV || pipeReg[PIPELINE_DEPTH-2].divCode == AC_DIVU) begin
                dataOut = quotient;
            end
            else begin
                dataOut = remainder;
            end

            finished = TRUE;
        end
        else begin
            dataOut = '0;
            finished = FALSE;
        end
    end

    
`ifndef RSD_SYNTHESIS
    initial begin
        for (int i = 0; i < PIPELINE_DEPTH-1; i++) begin
            pipeReg[i] <= '0;
        end
    end
`endif

endmodule : PipelinedDividerUnit
// ---- MulDivUnit/MulDivUnitIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Complex Integer Execution stage
//
// 乗算/SIMD 命令の演算を行う
// COMPLEX_EXEC_STAGE_DEPTH 段にパイプライン化されている
//

import BasicTypes::*;
import OpFormatTypes::*;


interface MulDivUnitIF(input logic clk, rst);

    logic stall;

    DataPath dataInA[MULDIV_ISSUE_WIDTH];
    DataPath dataInB[MULDIV_ISSUE_WIDTH];

    DataPath    mulDataOut  [MULDIV_ISSUE_WIDTH];
    logic       mulGetUpper [MULDIV_ISSUE_WIDTH];
    IntMUL_Code mulCode     [MULDIV_ISSUE_WIDTH];

    DataPath    divDataOut  [MULDIV_ISSUE_WIDTH];
    IntDIV_Code divCode     [MULDIV_ISSUE_WIDTH];
    logic       divReset    [MULDIV_ISSUE_WIDTH];
    logic       divReq      [MULDIV_ISSUE_WIDTH];
    logic       divReserved [MULDIV_ISSUE_WIDTH];
    logic       divFinished [MULDIV_ISSUE_WIDTH];
    logic       divBusy     [MULDIV_ISSUE_WIDTH];
    logic       divFree     [MULDIV_ISSUE_WIDTH];

    logic divAcquire[MULDIV_ISSUE_WIDTH];
    logic divRelease[MULDIV_ISSUE_WIDTH];

    logic divResetFromMI_Stage[MULDIV_ISSUE_WIDTH];
    logic divResetFromMR_Stage[MULDIV_ISSUE_WIDTH];
    logic divResetFromMT_Stage[MULDIV_ISSUE_WIDTH];
    
    logic divResetFromCI_Stage[MULDIV_ISSUE_WIDTH];

    modport MulDivUnit(
    input
        clk,
        rst,
        stall,
        dataInA,
        dataInB,
        mulGetUpper,
        mulCode,
        divCode,
        divReset,
        divResetFromCI_Stage,
        divResetFromMI_Stage,
        divResetFromMR_Stage,
        divResetFromMT_Stage,
        divReq,
        divAcquire,
        divRelease,
    output
        mulDataOut,
        divDataOut,
        divFinished,
        divBusy,
        divReserved,
        divFree
    );

    modport ComplexIntegerIssueStage(
    output
        divAcquire,
        divResetFromCI_Stage
    );

    modport ComplexIntegerExecutionStage(
    input
        mulDataOut,
        divDataOut,
        divFinished,
        divBusy,
        divReserved,
        divFree,
    output
        stall,
        dataInA,
        dataInB,
        mulGetUpper,
        mulCode,
        divCode,
        divReset,
        divReq,
        divRelease
    );

    modport MemoryIssueStage(
    output
        divAcquire,
        divResetFromMI_Stage
    );

    modport MemoryRegisterReadStage(
    output
        divResetFromMR_Stage
    );

    modport MemoryExecutionStage(
    input
        divBusy,
        divReserved,
        divFree,
    output
        stall,
        dataInA,
        dataInB,
        mulGetUpper,
        mulCode,
        divCode,
        divReset,
        divReq
    );

    modport MemoryTagAccessStage(
    input
        divFinished,
    output 
        divResetFromMT_Stage
    );

    modport MemoryAccessStage(
    input
        mulDataOut,
        divDataOut,
        divFinished,
    output 
        divRelease
    );


    modport Scheduler(
    input
        divFree
    );

    modport ReplayQueue(
    input
        divBusy
    );

endinterface
// ---- MulDivUnit/MulDivUnit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Complex Integer Execution stage
//
// 乗算/SIMD 命令の演算を行う
// COMPLEX_EXEC_STAGE_DEPTH 段にパイプライン化されている
//

import BasicTypes::*;
import OpFormatTypes::*;

module MulDivUnit(MulDivUnitIF.MulDivUnit port);

    for (genvar i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin : BlockMulUnit
        // MultiplierUnit
        PipelinedMultiplierUnit #(
            .BIT_WIDTH(DATA_WIDTH),
            .PIPELINE_DEPTH(MULDIV_STAGE_DEPTH)
        ) mulUnit (
            .clk(port.clk),
            .stall(port.stall),
            .fuOpA_In(port.dataInA[i]),
            .fuOpB_In(port.dataInB[i]),
            .getUpper(port.mulGetUpper[i]),
            .mulCode(port.mulCode[i]),
            .dataOut(port.mulDataOut[i])
        );
    end


    //
    // DividerUnit
    //

    typedef enum logic[1:0]
    {
        DIVIDER_PHASE_FREE       = 0,  // Divider is free
        DIVIDER_PHASE_RESERVED   = 1,  // Divider is not processing but reserved
        DIVIDER_PHASE_PROCESSING = 2,  // In processing
        DIVIDER_PHASE_WAITING    = 3   // Wait for issuing div from replayqueue
    } DividerPhase;
    DividerPhase regPhase  [MULDIV_ISSUE_WIDTH];
    DividerPhase nextPhase [MULDIV_ISSUE_WIDTH];
    logic finished[MULDIV_ISSUE_WIDTH];

    for (genvar i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin : BlockDivUnit
        DividerUnit divUnit(
            .clk(port.clk),
            .rst(port.rst),
            .req(port.divReq[i]),
            .fuOpA_In(port.dataInA[i]),
            .fuOpB_In(port.dataInB[i]),
            .divCode(port.divCode[i]),
            .finished(finished[i]),
            .dataOut(port.divDataOut[i])
        );
    end

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin
                regPhase[i] <= DIVIDER_PHASE_FREE;
            end
        end
        else begin
            regPhase <= nextPhase;
        end
    end

    always_comb begin
        nextPhase = regPhase;


        for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin

            case (regPhase[i])
            default: begin
                nextPhase[i] = DIVIDER_PHASE_FREE;
            end

            DIVIDER_PHASE_FREE: begin
                // Reserve divider and do not issue divs after that.
                if (port.divAcquire[i]) begin
                    nextPhase[i] = DIVIDER_PHASE_RESERVED;
                end
            end

            DIVIDER_PHASE_RESERVED: begin
                // Request to the divider
                // NOT make a request when below situation
                // 1) When any operands of inst. are invalid
                // 2) When the divider is waiting for the instruction
                //    to receive the result of the divider
                if (port.divReq[i]) begin
                    // Receive the request of div, 
                    // so move to processing phase
                    nextPhase[i] = DIVIDER_PHASE_PROCESSING;
                end
            end

            DIVIDER_PHASE_PROCESSING: begin
                // Div operation has finished, so we can get result from divider
                if (finished[i]) begin
                    nextPhase[i] = DIVIDER_PHASE_WAITING;
                end
            end

            DIVIDER_PHASE_WAITING: begin
                if (port.divRelease[i]) begin 
                    // Divが除算器から結果を取得できたので，
                    // IQからのdivの発行を許可する 
                    nextPhase[i] = DIVIDER_PHASE_FREE;
                end
            end
            endcase // regPhase[i]


            // 除算器に要求をしたdivがフラッシュされたので，除算器を解放する
            if (port.divReset[i]) begin
                nextPhase[i] = DIVIDER_PHASE_FREE;
            end

            `ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                if (port.divResetFromMI_Stage[i] || 
                    port.divResetFromMR_Stage[i] || 
                    port.divResetFromMT_Stage[i]
                ) begin
                    nextPhase[i] = DIVIDER_PHASE_FREE;
                end
            `else
                if (port.divResetFromCI_Stage[i]) begin
                    nextPhase[i] = DIVIDER_PHASE_FREE;
                end
            `endif

            // 現状 acquire が issue ステージからくるので，次のサイクルの状態でフリーか
            // どうかを判定する必要がある
            port.divFree[i]     = nextPhase[i] == DIVIDER_PHASE_FREE ? TRUE : FALSE;   
            port.divFinished[i] = regPhase[i] == DIVIDER_PHASE_WAITING ? TRUE : FALSE;
            port.divBusy[i]     = regPhase[i] == DIVIDER_PHASE_PROCESSING ? TRUE : FALSE;
            port.divReserved[i] = regPhase[i] == DIVIDER_PHASE_RESERVED ? TRUE : FALSE;

        end // for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin

    end // always_comb begin


endmodule
// ---- LoadStoreUnit/LoadStoreUnit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Load/store unit.
//


import BasicTypes::*;
import OpFormatTypes::*;
import LoadStoreUnitTypes::*;
import MemoryMapTypes::*;
import DebugTypes::*;
import CacheSystemTypes::*;

module LoadStoreUnit(
    LoadStoreUnitIF.LoadStoreUnit port,
    ControllerIF.LoadStoreUnit ctrl,
    HardwareCounterIF.LoadStoreUnit hwCounter
);
    // DCache/MSHR のラインとして読んだロードデータを、
    // アドレスのオフセットに合わせてシフト
    function automatic DataPath ShiftCacheLineData(DCacheLinePath srcLine, PhyAddrPath addr);
        DataPath data;
        data = srcLine >> (addr[DCACHE_LINE_BYTE_NUM_BIT_WIDTH-1:0] * 8);
        return data;
    endfunction
    function automatic DataPath ShiftForwardedData(LSQ_BlockDataPath srcLine, PhyAddrPath addr);
        DataPath data;
        data = srcLine >> (addr[LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE-1:0] * 8);
        return data;
    endfunction

    // ゼロ拡張or符号拡張
    function automatic DataPath ExtendLoadData(DataPath loadData,MemAccessMode mode);
        case (mode.size)
        MEM_ACCESS_SIZE_BYTE:
            return mode.isSigned ?
                { { 24{ loadData[7] } }, loadData[7:0] }:
                { { 24{ 1'b0 } }, loadData[7:0] };
        MEM_ACCESS_SIZE_HALF_WORD:
            return mode.isSigned ?
                { { 16{ loadData[15] } }, loadData[15:0] } :
                { { 16{ 1'b0 } }, loadData[15:0] };
        default: //MEM_ACCESS_SIZE_WORD,MEM_ACCESS_SIZE_VEC:
            return loadData;
        endcase
    endfunction


    // Pipeline:
    // ----------------------------->
    // ADDR  | D$TAG | D$DATA | WB
    //       |  LSQ  |        |
    //
    // LSQ is acessed in the D$TAG stage (MemoryTagAccessStage) and D$DATA is accessed
    // after this stage, thus forwarded resutls must be latched.

    logic storeLoadForwardedReg[LOAD_ISSUE_WIDTH];
    LSQ_BlockDataPath forwardedLoadDataReg[LOAD_ISSUE_WIDTH];
    // MSHRからのLoad
    logic mshrReadHitReg[LOAD_ISSUE_WIDTH];
    DCacheLinePath mshrReadDataReg[LOAD_ISSUE_WIDTH];

    AddrPath loadAddrReg[LOAD_ISSUE_WIDTH];
    MemAccessMode loadMemAccessSizeReg[LOAD_ISSUE_WIDTH];

    always_ff@(posedge port.clk)
    begin
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            if (port.rst) begin
                storeLoadForwardedReg[i] <= FALSE;
                forwardedLoadDataReg[i] <= '0;
                mshrReadHitReg[i] <= FALSE;
                mshrReadDataReg[i] <= '0;
                loadAddrReg[i] <= '0;
                loadMemAccessSizeReg[i] <= MEM_ACCESS_SIZE_BYTE;
            end
            else if (!ctrl.backEnd.stall) begin
                storeLoadForwardedReg[i] <= port.storeLoadForwarded[i];
                forwardedLoadDataReg[i] <= port.forwardedLoadData[i];
                mshrReadHitReg[i] <= port.mshrReadHit[i];
                mshrReadDataReg[i] <= port.mshrReadData[i];
                loadAddrReg[i] <=  port.executedLoadAddr[i];
                loadMemAccessSizeReg[i] <= port.executedLoadMemAccessMode[i];
            end
        end
    end


    LSQ_BlockDataPath loadLSQ_BlockData[LOAD_ISSUE_WIDTH];
    DataPath shiftedLoadData[LOAD_ISSUE_WIDTH];
    DataPath extendedLoadData[LOAD_ISSUE_WIDTH];
    DataPath executedLoadData [ LOAD_ISSUE_WIDTH ];
    always_comb begin
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            executedLoadData[i] = '0;
            port.executedLoadVectorData[i] = 0;
        end
        
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            loadLSQ_BlockData[i] = 
                storeLoadForwardedReg[i] ? forwardedLoadDataReg[i] :
                mshrReadHitReg[i] ? mshrReadDataReg[i] :
                                    port.dcReadData[i];
            port.executedLoadVectorData[i] = loadLSQ_BlockData[i];

            shiftedLoadData[i] = 
                storeLoadForwardedReg[i] ? ShiftForwardedData(forwardedLoadDataReg[i], loadAddrReg[i]) :
                mshrReadHitReg[i] ? ShiftCacheLineData(mshrReadDataReg[i], loadAddrReg[i]) :
                                    ShiftCacheLineData(port.dcReadData[i], loadAddrReg[i]);
            extendedLoadData[i] = ExtendLoadData(shiftedLoadData[i], loadMemAccessSizeReg[i]);


            // executedLoadData
`ifdef RSD_DISABLE_HARDWARE_COUNTER
            executedLoadData[i] = extendedLoadData[i];
`else
            hwCounter.hardwareCounterType[i] =
                HardwareCounterType'( loadAddrReg[i][ HARDWARE_COUNTER_TYPE_MSB:HARDWARE_COUNTER_TYPE_LSB ] ); // cast
            if ( loadAddrReg[i][ HARDWARE_COUNTER_TAG_MSB:HARDWARE_COUNTER_TAG_LSB ] == HARDWARE_COUNTER_TAG ) begin
                // メモリではなくハードウェアカウンタの値を使用
                executedLoadData[i] = hwCounter.hardwareCounterData[i];
            end
            else begin
                executedLoadData[i] = extendedLoadData[i];
            end
`endif
        end

        port.executedLoadData = executedLoadData;
    end


    // From the rename stage.
    always_comb begin
        port.allocatable = port.loadQueueAllocatable &&    
            port.storeQueueAllocatable && !port.busyInRecovery;
    end

endmodule : LoadStoreUnit

// ---- LoadStoreUnit/LoadStoreUnitIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// The interface of a load/store unit.
//


import BasicTypes::*;
import MemoryMapTypes::*;
import CacheSystemTypes::*;
import OpFormatTypes::*;
import LoadStoreUnitTypes::*;
import MemoryMapTypes::*;

interface LoadStoreUnitIF( input logic clk, rst, rstStart );

    // Allocation
    logic allocatable;
    logic loadQueueAllocatable;
    logic storeQueueAllocatable;
    logic allocateLoadQueue [ RENAME_WIDTH ];
    logic allocateStoreQueue [ RENAME_WIDTH ];
    LoadQueueIndexPath allocatedLoadQueuePtr [ RENAME_WIDTH ];
    StoreQueueIndexPath allocatedStoreQueuePtr [ RENAME_WIDTH ];

    // Execution
    logic executeLoad [ LOAD_ISSUE_WIDTH ];
    logic executedLoadRegValid [LOAD_ISSUE_WIDTH];
    PhyAddrPath executedLoadAddr [ LOAD_ISSUE_WIDTH ];
    DataPath executedLoadData [ LOAD_ISSUE_WIDTH ];
    PC_Path executedLoadPC  [LOAD_ISSUE_WIDTH ];
    VectorPath executedLoadVectorData [ LOAD_ISSUE_WIDTH ];
    MemAccessMode executedLoadMemAccessMode [ LOAD_ISSUE_WIDTH ];
    StoreQueueIndexPath executedStoreQueuePtrByLoad [ LOAD_ISSUE_WIDTH ];
    LoadQueueIndexPath executedLoadQueuePtrByLoad[ LOAD_ISSUE_WIDTH ];

    logic executeStore [ STORE_ISSUE_WIDTH ];
    logic executedStoreCondEnabled [ STORE_ISSUE_WIDTH ];
    logic executedStoreRegValid [ STORE_ISSUE_WIDTH ];
    PhyAddrPath executedStoreAddr [ STORE_ISSUE_WIDTH ];
    DataPath executedStoreData [ STORE_ISSUE_WIDTH ];
    VectorPath executedStoreVectorData [ STORE_ISSUE_WIDTH ];
    MemAccessMode executedStoreMemAccessMode [ STORE_ISSUE_WIDTH ];
    LoadQueueIndexPath executedLoadQueuePtrByStore [ STORE_ISSUE_WIDTH ];
    StoreQueueIndexPath executedStoreQueuePtrByStore [ STORE_ISSUE_WIDTH ];

    // Commit
    logic commitStore;
    CommitLaneCountPath commitStoreNum;

    // Retire
    logic releaseLoadQueue;
    CommitLaneCountPath releaseLoadQueueEntryNum;


    // Whether to release the head entry(s) of the SQ.
    logic releaseStoreQueueHead;    // For commit

    // The number of released entries.
    CommitLaneCountPath releaseStoreQueueHeadEntryNum;  // For commit


    // ストア結果をキャッシュに書き込む際に SQ から読み出すデータ
    StoreQueueIndexPath retiredStoreQueuePtr;
    LSQ_BlockDataPath retiredStoreData;
    logic retiredStoreCondEnabled;
    LSQ_BlockWordEnablePath retiredStoreWordWE;
    LSQ_WordByteEnablePath retiredStoreByteWE;
    LSQ_BlockAddrPath retiredStoreLSQ_BlockAddr;

    // SQ status.
    logic storeQueueEmpty;
    StoreQueueIndexPath storeQueueHeadPtr;
    StoreQueueCountPath storeQueueCount;

    // Recover
    logic busyInRecovery;


    // Store-Load Forwarding
    logic storeLoadForwarded [ LOAD_ISSUE_WIDTH ];
    LSQ_BlockDataPath forwardedLoadData [ LOAD_ISSUE_WIDTH ];
    logic forwardMiss[ LOAD_ISSUE_WIDTH ];


    // DCache
    logic dcReadReq[LOAD_ISSUE_WIDTH];    // Read request from the LSU.
    logic dcReadBusy[LOAD_ISSUE_WIDTH];   // Read ports are busy and cannot accept requests.
    logic dcReadHit[LOAD_ISSUE_WIDTH];

    PhyAddrPath dcReadAddr[LOAD_ISSUE_WIDTH];
    DCacheLinePath dcReadData[LOAD_ISSUE_WIDTH];

    // Forward されたのでメインメモリアクセスや MSHR 確保をキャンセルする 
    // MSHR を確保してしまうと，フォワードしたロードの方はヒット扱いでリタイアするので
    // 永久に MSHR のエントリが解放されない
    logic dcReadCancelFromMT_Stage[LOAD_ISSUE_WIDTH];    

    // MSHRをAllocateした命令かどうか
    logic loadHasAllocatedMSHR[DCACHE_LSU_READ_PORT_NUM];
    MSHR_IndexPath loadMSHRID[DCACHE_LSU_READ_PORT_NUM];
    logic storeHasAllocatedMSHR[DCACHE_LSU_WRITE_PORT_NUM];
    MSHR_IndexPath storeMSHRID[DCACHE_LSU_WRITE_PORT_NUM];

    logic dcWriteReq;     // Same as the read signals.
    logic dcWriteReqAck;
    logic dcWriteBusy;
    logic dcWriteHit;
    PhyAddrPath dcWriteAddr;
    DCacheLinePath dcWriteData;
    DCacheByteEnablePath dcWriteByteWE;

    // MSHRからのLoad
    logic mshrAddrHit[LOAD_ISSUE_WIDTH];
    MSHR_IndexPath mshrAddrHitMSHRID[LOAD_ISSUE_WIDTH];
    logic mshrReadHit[LOAD_ISSUE_WIDTH];
    DCacheLinePath mshrReadData[LOAD_ISSUE_WIDTH];

    // MSHRをAllocateした命令からのメモリリクエストかどうか
    // MSHRをAllocateしたLoad命令がMemoryRegisterReadStageでflushされた場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalidByMemoryRegisterReadStage[MSHR_NUM];

    // そのリクエストがアクセスに成功した場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalid[LOAD_ISSUE_WIDTH];

    // MSHRをAllocateしたLoad命令がStoreForwardingによって完了した場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalidByMemoryTagAccessStage[MSHR_NUM];

    // MSHRをAllocateしたLoad命令がReplayQueueの先頭でflushされた場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalidByReplayQueue[MSHR_NUM];

    // MSHR
    logic mshrValid[MSHR_NUM];
    MSHR_Phase mshrPhase[MSHR_NUM]; // MSHR phase.
    DCacheIndexSubsetPath mshrAddrSubset[MSHR_NUM];

    // Memory dependent prediction
    logic conflict [ STORE_ISSUE_WIDTH ];
    logic memAccessOrderViolation [ STORE_ISSUE_WIDTH ];
    PC_Path conflictLoadPC [ STORE_ISSUE_WIDTH ];
    
    
    modport DCache(
    input
        clk,
        rst,
        rstStart,
        dcReadReq,
        dcWriteReq,
        dcWriteData,
        dcWriteAddr,
        dcWriteByteWE,
        dcReadAddr,
        dcReadCancelFromMT_Stage,
        makeMSHRCanBeInvalidByMemoryRegisterReadStage,
        makeMSHRCanBeInvalid,
        makeMSHRCanBeInvalidByMemoryTagAccessStage,
        makeMSHRCanBeInvalidByReplayQueue,
    output
        dcReadHit,
        dcReadBusy,
        dcReadData,
        dcWriteHit,
        dcWriteBusy,
        dcWriteReqAck,
        mshrAddrHit,
        mshrAddrHitMSHRID,
        mshrAddrSubset,
        mshrReadHit,
        mshrReadData,
        mshrValid,
        mshrPhase,
        loadHasAllocatedMSHR,
        loadMSHRID,
        storeHasAllocatedMSHR,
        storeMSHRID
    );



    modport LoadQueue(
    input
        clk,
        rst,
        allocateLoadQueue,
        executeLoad,
        executedLoadQueuePtrByLoad,
        executedLoadQueuePtrByStore,
        executedLoadAddr,
        executedLoadPC,
        executedLoadRegValid,
        executedStoreAddr,
        executeStore,
        executedLoadMemAccessMode,
        releaseLoadQueue,
        releaseLoadQueueEntryNum,
        executedStoreMemAccessMode,
    output
        allocatedLoadQueuePtr,
        loadQueueAllocatable,
        conflict,
        conflictLoadPC
    );

    modport StoreQueue(
    input
        clk,
        rst,
        allocateStoreQueue,
        executeLoad,
        executedLoadAddr,
        executeStore,
        executedStoreQueuePtrByLoad,
        executedStoreQueuePtrByStore,
        executedStoreAddr,
        executedStoreData,
        executedStoreVectorData,
        executedStoreCondEnabled,
        executedStoreRegValid,
        executedStoreMemAccessMode,
        releaseStoreQueueHead,
        releaseStoreQueueHeadEntryNum,
        retiredStoreQueuePtr,
        executedLoadMemAccessMode,
    output
        allocatedStoreQueuePtr,
        storeQueueAllocatable,
        storeLoadForwarded,
        forwardedLoadData,
        forwardMiss,
        retiredStoreData,
        retiredStoreCondEnabled,
        retiredStoreWordWE,
        retiredStoreByteWE,
        retiredStoreLSQ_BlockAddr,
        storeQueueEmpty,
        storeQueueCount,
        storeQueueHeadPtr
    );

    modport StoreCommitter(
    input
        clk,
        rst,
        commitStore,
        commitStoreNum,
        retiredStoreCondEnabled,
        dcWriteBusy,
        dcWriteHit,
        dcWriteReqAck,
        retiredStoreLSQ_BlockAddr,
        retiredStoreData,
        retiredStoreWordWE,
        retiredStoreByteWE,
        storeQueueEmpty,
        storeQueueCount,
        storeQueueHeadPtr,
        allocatable,
        storeHasAllocatedMSHR,
        storeMSHRID,
        mshrPhase,
    output
        dcWriteReq,
        dcWriteData,
        dcWriteAddr,
        dcWriteByteWE,
        retiredStoreQueuePtr,
        releaseStoreQueueHead,
        busyInRecovery,
        releaseStoreQueueHeadEntryNum
    );

    modport LoadStoreUnit(
    input
        clk,
        rst,
        loadQueueAllocatable,
        storeQueueAllocatable,
        executeLoad,
        executedLoadAddr,
        executedLoadMemAccessMode,
        storeLoadForwarded,
        forwardedLoadData,
        dcReadData,
        busyInRecovery,
        mshrReadHit,
        mshrReadData,
    output
        executedLoadData,
        executedLoadVectorData,
        allocatable
    );

    modport RenameStage(
    input
        allocatable,
        allocatedLoadQueuePtr,
        allocatedStoreQueuePtr,
    output
        allocateLoadQueue,
        allocateStoreQueue
    );

    modport MemoryRegisterReadStage(
    output
        makeMSHRCanBeInvalidByMemoryRegisterReadStage
    );

    modport MemoryExecutionStage(
    input
        clk,
    output
        dcReadReq,
        dcReadAddr,
        makeMSHRCanBeInvalid
    );

    modport MemoryTagAccessStage(
    input
        forwardMiss,
        storeLoadForwarded,
        conflict,
        dcReadHit,
        mshrAddrHit,
        mshrAddrHitMSHRID,
        mshrReadHit,
        loadHasAllocatedMSHR,
        loadMSHRID,
    output
        dcReadCancelFromMT_Stage,
        executeLoad,
        executedLoadQueuePtrByLoad,
        executedLoadQueuePtrByStore,
        executedLoadAddr,
        executedLoadPC,
        executedLoadRegValid,
        executeStore,
        executedStoreQueuePtrByLoad,
        executedStoreQueuePtrByStore,
        executedStoreData,
        executedStoreVectorData,
        executedStoreAddr,
        executedStoreCondEnabled,
        executedStoreRegValid,
        executedLoadMemAccessMode,
        executedStoreMemAccessMode,
        makeMSHRCanBeInvalidByMemoryTagAccessStage,
        memAccessOrderViolation
    );

    modport MemoryAccessStage(
    input
        executedLoadData,
        executedLoadVectorData
    );

    modport ReplayQueue(
    input
        mshrValid,
        mshrPhase,
        mshrAddrSubset,
    output
        makeMSHRCanBeInvalidByReplayQueue
    );

    modport CommitStage(
    input
        busyInRecovery,
    output
        releaseLoadQueue,
        releaseLoadQueueEntryNum,
        commitStore,
        commitStoreNum
    );

    modport MemoryDependencyPredictor(
    input
        memAccessOrderViolation,
        conflictLoadPC
    );

endinterface : LoadStoreUnitIF


// ---- LoadStoreUnit/LoadQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Load queue
//


import BasicTypes::*;
import MemoryMapTypes::*;
import LoadStoreUnitTypes::*;

// Convert a pointer of an active list to an "age."
// An "age" is directly compared with a comparetor.
function automatic LoadQueueCountPath LoadQueuePtrToAge(LoadQueueIndexPath ptr, LoadQueueIndexPath head);
    LoadQueueCountPath age;
    age = ptr;
    if (ptr < head)
        return age + LOAD_QUEUE_ENTRY_NUM; // Wrap around.
    else
        return age;
endfunction

module LoadQueue(
    LoadStoreUnitIF.LoadQueue port,
    RecoveryManagerIF.LoadQueue recovery
);

    logic reset;

    // Head and tail pointers.
    // This head pointer refers the next entry of the last valid entry.
    LoadQueueIndexPath headPtr;
    LoadQueueIndexPath tailPtr;

    // FIFO controller.
    logic push; // push request.
    RenameLaneCountPath pushCount;  // pushed count.
    LoadQueueCountPath curCount;    // current size.
    SetTailMultiWidthQueuePointer #(LOAD_QUEUE_ENTRY_NUM, 0, 0, 0, RENAME_WIDTH, COMMIT_WIDTH)
        loadQueuePointer(
            .clk(port.clk),
            .rst(reset),
            .pop(port.releaseLoadQueue),
            .popCount(port.releaseLoadQueueEntryNum),
            .push(push),
            .pushCount(pushCount),
            .setTail(recovery.toRecoveryPhase),
            .setTailPtr(recovery.loadQueueRecoveryTailPtr),
            .count(curCount),
            .headPtr(headPtr),
            .tailPtr(tailPtr)
        );

    always_comb begin
        // Generate push singnals.
        pushCount = 0;
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            if (tailPtr + pushCount < LOAD_QUEUE_ENTRY_NUM) begin
                port.allocatedLoadQueuePtr[i] = tailPtr + pushCount;
            end
            else begin
                // Out of range of load queue
                port.allocatedLoadQueuePtr[i] = 
                    tailPtr + pushCount - LOAD_QUEUE_ENTRY_NUM;
            end
            pushCount += port.allocateLoadQueue[i];
        end
        push = pushCount > 0;

        // All entries are not used for avoiding head==tail problem.
        port.loadQueueAllocatable =
            (curCount <= LOAD_QUEUE_ENTRY_NUM - RENAME_WIDTH - 1) ? TRUE : FALSE;

        recovery.loadQueueHeadPtr = headPtr;
    end



    // Address and finish flag storage.
    LoadQueueEntry      loadQueue[LOAD_QUEUE_ENTRY_NUM];
    LoadQueueIndexPath  executedLoadQueuePtrByLoad[LOAD_ISSUE_WIDTH];
    LSQ_BlockAddrPath   executedLoadAddr[LOAD_ISSUE_WIDTH];
    LSQ_BlockWordEnablePath executedLoadWordRE[LOAD_ISSUE_WIDTH];
    logic executedLoadRegValid[LOAD_ISSUE_WIDTH];
    always_ff @(posedge port.clk) begin
        if (reset) begin
            for (int i = 0; i < LOAD_QUEUE_ENTRY_NUM; i++) begin
                loadQueue[i].finished <= FALSE;
            end
        end
        else begin
            for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
                if (port.executeLoad[i]) begin
                    loadQueue[ executedLoadQueuePtrByLoad[i] ].regValid <= executedLoadRegValid[i];
                    loadQueue[ executedLoadQueuePtrByLoad[i] ].finished <= TRUE;
                    loadQueue[ executedLoadQueuePtrByLoad[i] ].address <= executedLoadAddr[i];
                    loadQueue[ executedLoadQueuePtrByLoad[i] ].wordRE <= executedLoadWordRE[i];
                    loadQueue[ executedLoadQueuePtrByLoad[i] ].pc <= port.executedLoadPC[i];
                end
            end

            for (int i = 0; i < RENAME_WIDTH; i++) begin
                if (port.allocateLoadQueue[i]) begin
                    loadQueue[ port.allocatedLoadQueuePtr[i] ].finished <= FALSE;
                end
            end
        end
    end

    always_comb begin
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            executedLoadRegValid[i] = port.executedLoadRegValid[i];
            executedLoadQueuePtrByLoad[i] = port.executedLoadQueuePtrByLoad[i];
            executedLoadAddr[i] = LSQ_ToBlockAddr(port.executedLoadAddr[i]);
            executedLoadWordRE[i] =
                LSQ_ToBlockWordEnable(
                    port.executedLoadAddr[i],
                    port.executedLoadMemAccessMode[i]
                );
        end
    end



    // Store-load access order violation detector.

    // A picker of violated entries.
    LoadQueueIndexPath executedLoadQueuePtrByStore[STORE_ISSUE_WIDTH];
    LoadQueueOneHotPath addrMatch[STORE_ISSUE_WIDTH];    // The outputs of address comparators.
    LoadQueueIndexPath pickedPtr[STORE_ISSUE_WIDTH];
    logic picked[STORE_ISSUE_WIDTH];  // This flag is true if violation is detected.
    generate
        for(genvar i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            CircularRangePicker #(
                .ENTRY_NUM(LOAD_QUEUE_ENTRY_NUM)
            ) picker(
                .headPtr(executedLoadQueuePtrByStore[i]),
                .tailPtr(tailPtr),
                .request(addrMatch[i]),
                .grantPtr(pickedPtr[i]),
                .picked(picked[i])
            );
        end
    endgenerate

    // This flags are TRUE if violation is detected.
    logic violation[STORE_ISSUE_WIDTH];

    // The addresses of executed stores/loads.
    LSQ_BlockAddrPath executedStoreAddr[STORE_ISSUE_WIDTH];
    LSQ_BlockWordEnablePath executedStoreWordWE[STORE_ISSUE_WIDTH];

    // This is assigned with PC of load that caused a violation with store.
    PC_Path conflictLoadPC[STORE_ISSUE_WIDTH];
    
    always_comb begin

        // Generate a reset signal.
        reset = port.rst;


        // Detect access order violation between already executed loads and
        // a currently executed store.
        for (int si = 0; si < STORE_ISSUE_WIDTH; si++) begin
            violation[si] = FALSE;
            conflictLoadPC[si] = '0;
            executedStoreAddr[si] = LSQ_ToBlockAddr(port.executedStoreAddr[si]);
            executedStoreWordWE[si] = LSQ_ToBlockWordEnable(
                port.executedStoreAddr[si],
                port.executedStoreMemAccessMode[si]
            );
            executedLoadQueuePtrByStore[si] = port.executedLoadQueuePtrByStore[si];
        end

        // Compares a stored address and already executed load addresses.
        for (int si = 0; si < STORE_ISSUE_WIDTH; si++) begin
            for (int lqe = 0; lqe < LOAD_QUEUE_ENTRY_NUM; lqe++) begin
                addrMatch[si][lqe] =
                    loadQueue[lqe].finished &&
                    loadQueue[lqe].regValid &&
                    loadQueue[lqe].address == executedStoreAddr[si] &&
                    (loadQueue[lqe].wordRE & executedStoreWordWE[si]) != '0;
            end
        end

        // Set address match results.
        for (int si = 0; si < STORE_ISSUE_WIDTH; si++) begin
            if (port.executeStore[si]) begin
                violation[si] = picked[si];

                // Violation is occured with instruction inside load queue.
                if (picked[si] && pickedPtr[si] < LOAD_QUEUE_ENTRY_NUM) begin
                    // Assign write address for Memory dependent predictor
                    // with inst which caused viotion inside load queue.
                    conflictLoadPC[si] = loadQueue[pickedPtr[si]].pc;
                end
            end
            else begin
                violation[si] = FALSE;
            end
        end

        // Detect violation between executed loads and stores in this cycle.
        for (int si = 0; si < STORE_ISSUE_WIDTH; si++) begin
            for (int li = 0; li < LOAD_ISSUE_WIDTH; li++) begin

                // Continue if this slot is not a load.
                if (!port.executeLoad[li]) begin
                    continue;
                end

                // Check an address.
                // If the addresses of a load and a store are different, violation
                // does not occur.
                if (executedLoadAddr[li] != executedStoreAddr[si]) begin
                    // 現在は、LoadStoreのレーンがsplitであることが前提。
                    // unifiedに戻した場合は、同じレーンのアドレスを比較しないよう注意。
                    continue;
                end

                if ((executedLoadWordRE[li] & executedStoreWordWE[si]) == '0) begin
                    // 上の比較器ではベクタ単位でアドレスを比較するが、
                    // ワード単位でアクセス範囲が被って無ければ、
                    // バイオレーションとしない。
                    continue;
                end

                // Check orders.
                if (LoadQueuePtrToAge(port.executedLoadQueuePtrByLoad[li], headPtr) >=
                    LoadQueuePtrToAge(executedLoadQueuePtrByStore[si], headPtr)
                ) begin
                    // Violation is occured with load & store executed in this cycle.
                    violation[si] = TRUE;
                    conflictLoadPC[si] = port.executedLoadPC[li];
                end
            end
        end

        // Send write address of Memory dependent predictor with IF.
        port.conflictLoadPC = conflictLoadPC;
        
        // Output violation information.
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            port.conflict[i] = violation[i];
        end
        /*
        for (int i = STORE_ISSUE_LANE_BEGIN; i < MEM_ISSUE_WIDTH; i++) begin
            port.conflict[i] = violation[i - STORE_ISSUE_LANE_BEGIN];
        end
        */
    end

    generate
        for (genvar i = 0; i < STORE_ISSUE_WIDTH; i++) begin : assertionBlock
            //  |----S---h***L**t----|
            `RSD_ASSERT_CLK(
                port.clk, 
                !(port.executeStore[i] && headPtr < tailPtr && executedLoadQueuePtrByStore[i] < headPtr),
                "1: A store's executedLoadQueuePtr is illegal."
            );

            //  |----h***L**t--S----|
            `RSD_ASSERT_CLK(
                port.clk, 
                 !(port.executeStore[i] && headPtr < tailPtr && tailPtr < executedLoadQueuePtrByStore[i]),
                "2: A store's executedLoadQueuePtr is illegal."
            );

            //  |******t--S--h***L***|
            `RSD_ASSERT_CLK(
                port.clk, 
                !(port.executeStore[i] && tailPtr <= headPtr &&
                tailPtr < executedLoadQueuePtrByStore[i] && executedLoadQueuePtrByStore[i] < headPtr),
                "3: A store's executedLoadQueuePtr is illegal."
            );
        end
    endgenerate

endmodule : LoadQueue

// ---- LoadStoreUnit/StoreQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Store queue
//


import BasicTypes::*;
import CacheSystemTypes::*;
import OpFormatTypes::*;
import LoadStoreUnitTypes::*;
import MemoryMapTypes::*;



module StoreQueue(
    LoadStoreUnitIF.StoreQueue port,
    RecoveryManagerIF.StoreQueue recovery
);

    // ストアデータをアドレスのオフセットに合わせてシフト
    // ベクトルデータの場合は、そのまま
    function automatic void GenerateStoreData(
        output LSQ_BlockDataPath dataOut,
        input DataPath dataIn,
        input LSQ_BlockDataPath blockDataIn,
        input PhyAddrPath addr,
        input MemAccessMode mode
    );
`ifdef RSD_ENABLE_VECTOR_PATH
        // Disable vector data path
        if (mode.size == MEM_ACCESS_SIZE_VEC) begin
            dataOut = blockDataIn;  // Vector
        end
        else begin
            dataOut = dataIn;
            dataOut = dataOut << ( addr[ LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE-1:0 ] * BYTE_WIDTH );
        end
`else
        dataOut = dataIn;
        dataOut = dataOut << ( addr[ LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE-1:0 ] * BYTE_WIDTH );
`endif
    endfunction

    //
    // Signals
    //

    // The content of the head of a SQ.
    StoreQueueAddrEntry headAddrEntry;
    StoreQueueDataEntry headDataEntry;

    // The pointer of released entry.
    StoreQueueIndexPath releasedStoreQueuePtr;

    // The head/tail pointers of a store queue.
    StoreQueueIndexPath headPtr;
    StoreQueueIndexPath tailPtr;

    // FIFO controller.
    RenameLaneCountPath pushCount;
    StoreQueueCountPath curCount;
    logic push;

    // Parameter: Size, Initial head pos., Initial tail pos., Initial count
    SetTailMultiWidthQueuePointer #( STORE_QUEUE_ENTRY_NUM, 0, 0, 0, RENAME_WIDTH, COMMIT_WIDTH )
        storeQueuePointer(
            .clk(port.clk),
            .rst(port.rst), // On flush, pointers are recovered by the store committer.
            .pop(port.releaseStoreQueueHead),
            .popCount(port.releaseStoreQueueHeadEntryNum),
            .push(push),
            .pushCount(pushCount),
            .setTail(recovery.toRecoveryPhase),
            .setTailPtr(recovery.storeQueueRecoveryTailPtr),
            .count(curCount),
            .headPtr(headPtr),
            .tailPtr(tailPtr)
        );

    always_comb begin

        pushCount = 0;
        for (int i = 0; i < RENAME_WIDTH; i++) begin
            if (tailPtr + pushCount < STORE_QUEUE_ENTRY_NUM) begin
                port.allocatedStoreQueuePtr[i] = tailPtr + pushCount;
            end
            else begin
                // Out of range of store queue
                port.allocatedStoreQueuePtr[i] = 
                    tailPtr + pushCount - STORE_QUEUE_ENTRY_NUM;
            end
            pushCount += port.allocateStoreQueue[i];
        end
        push = pushCount > 0;

        port.storeQueueCount = curCount;
        port.storeQueueAllocatable =
            (curCount <= STORE_QUEUE_ENTRY_NUM - RENAME_WIDTH - 1) ? TRUE : FALSE;
        port.storeQueueEmpty = curCount == 0;

        recovery.storeQueueHeadPtr = headPtr;
    end


    //
    // SQ's address and data storage.
    //

    // The address part of a SQ.
    StoreQueueAddrEntry storeQueue[STORE_QUEUE_ENTRY_NUM-1:0];

    logic  executeStore[STORE_ISSUE_WIDTH];
    LSQ_BlockAddrPath executedStoreAddr[STORE_ISSUE_WIDTH];
    LSQ_BlockWordEnablePath executedStoreWordWE[STORE_ISSUE_WIDTH];
    LSQ_WordByteEnablePath executedStoreByteWE[STORE_ISSUE_WIDTH];
    logic executedStoreCondEnabled[STORE_ISSUE_WIDTH];
    logic executedStoreRegValid[STORE_ISSUE_WIDTH];
    StoreQueueIndexPath executedStoreQueuePtrByStore[STORE_ISSUE_WIDTH];

    always_ff @(posedge port.clk) begin
        if(port.rst) begin
            for( int i = 0; i < STORE_QUEUE_ENTRY_NUM; i++) begin
                storeQueue[i].finished <= FALSE;
                storeQueue[i].address <= '0;
                storeQueue[i].wordWE <= '0;
                storeQueue[i].byteWE <= '0;
            end
        end
        else begin
            for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
                if( executeStore[i] ) begin
                    storeQueue[ executedStoreQueuePtrByStore[i] ].regValid <= executedStoreRegValid[i];
                    storeQueue[ executedStoreQueuePtrByStore[i] ].finished <= executedStoreCondEnabled[i];
                    storeQueue[ executedStoreQueuePtrByStore[i] ].address <= executedStoreAddr[i];
                    storeQueue[ executedStoreQueuePtrByStore[i] ].wordWE <= executedStoreWordWE[i];
                    storeQueue[ executedStoreQueuePtrByStore[i] ].byteWE <= executedStoreByteWE[i];
                end
            end

            for (int i = 0; i < RENAME_WIDTH; i++) begin
                if (port.allocateStoreQueue[i]) begin
                    storeQueue[ port.allocatedStoreQueuePtr[i] ].finished <= FALSE;
                end
            end
        end
    end

    always_comb begin
        // Pick store execution results.
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            executeStore[i] = port.executeStore[i];
            executedStoreAddr[i] =
                LSQ_ToBlockAddr(port.executedStoreAddr[i]);
            executedStoreCondEnabled[i] = port.executedStoreCondEnabled[i];
            executedStoreRegValid[i] = port.executedStoreRegValid[i];
            executedStoreQueuePtrByStore[i] = port.executedStoreQueuePtrByStore[i];

            executedStoreWordWE[i] =
                LSQ_ToBlockWordEnable(
                    port.executedStoreAddr[i],
                    port.executedStoreMemAccessMode[i]
                );
            executedStoreByteWE[i] =
                LSQ_ToWordByteEnable(
                    port.executedStoreAddr[i],
                    port.executedStoreMemAccessMode[i]
                );
        end
    end



    // Forwarding from a store queue.
    StoreQueueDataEntry forwardedDataEntry[LOAD_ISSUE_WIDTH];
    LSQ_BlockWordEnablePath executedLoadWordRE[LOAD_ISSUE_WIDTH];
    LSQ_WordByteEnablePath executedLoadByteRE[LOAD_ISSUE_WIDTH];

    // A picker of forwarded entries.
    StoreQueueOneHotPath addrMatch[LOAD_ISSUE_WIDTH];
    StoreQueueIndexPath pickedPtr[LOAD_ISSUE_WIDTH];
    logic picked[LOAD_ISSUE_WIDTH];
    StoreQueueIndexPath executedStoreQueuePtrByLoad[LOAD_ISSUE_WIDTH];

    generate
        for(genvar i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            CircularRangePicker #(
                .ENTRY_NUM( STORE_QUEUE_ENTRY_NUM )
            ) picker(
                .headPtr(headPtr),
                .tailPtr(executedStoreQueuePtrByLoad[i]),
                .request(addrMatch[i]),
                .grantPtr(pickedPtr[i]),
                .picked(picked[i])
            );
        end
    endgenerate

    always_comb begin
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            executedStoreQueuePtrByLoad[i] = port.executedStoreQueuePtrByLoad[i];
        end
    end


    // The data part of the SQ.
    StoreQueueIndexPath sqReadPtr[LOAD_ISSUE_WIDTH + 1];  // +1 for commit.
    StoreQueueDataEntry sqReadData[LOAD_ISSUE_WIDTH + 1];
    logic sqWE[STORE_ISSUE_WIDTH];
    StoreQueueDataEntry sqWriteData[STORE_ISSUE_WIDTH];

    LSQ_BlockDataPath sqWriteStoreData[STORE_ISSUE_WIDTH];

    DistributedMultiPortRAM #(
        .ENTRY_NUM( STORE_QUEUE_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( $bits(StoreQueueDataEntry) ),
        .READ_NUM(LOAD_ISSUE_WIDTH + 1),    // +1 for commit.
        .WRITE_NUM(STORE_ISSUE_WIDTH)
    ) storeQueueData (
        .clk(port.clk),
        .we(sqWE),
        .wa(executedStoreQueuePtrByStore),
        .wv(sqWriteData),
        .ra(sqReadPtr),
        .rv(sqReadData)
    );

    // Write
    always_comb begin
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            GenerateStoreData(
                sqWriteStoreData[i],
                port.executedStoreData[i],
                port.executedStoreVectorData[i],
                port.executedStoreAddr[i],
                port.executedStoreMemAccessMode[i]
            );

            sqWE[i] = executeStore[i];
            sqWriteData[i].data = sqWriteStoreData[i];
            sqWriteData[i].condEnabled = executedStoreCondEnabled[i];
            sqWriteData[i].wordWE = executedStoreWordWE[i];
            sqWriteData[i].byteWE = executedStoreByteWE[i];
        end
    end

    // Store-Load Forwarding
    logic storeLoadForwarded [ LOAD_ISSUE_WIDTH ];
    LSQ_BlockDataPath forwardedLoadData [ LOAD_ISSUE_WIDTH ];
    logic forwardMiss[ LOAD_ISSUE_WIDTH ];

    always_comb begin

        // --- Commit
        // A read pointer is specified by a store commit unit.
        releasedStoreQueuePtr = port.retiredStoreQueuePtr;

        // The last read port is used for commitment.
        sqReadPtr[LOAD_ISSUE_WIDTH] = releasedStoreQueuePtr;
        headDataEntry = sqReadData[LOAD_ISSUE_WIDTH];
        headAddrEntry = storeQueue[releasedStoreQueuePtr];

        port.retiredStoreLSQ_BlockAddr = headAddrEntry.address;

        port.retiredStoreData = headDataEntry.data;
        port.retiredStoreCondEnabled = headDataEntry.condEnabled;
        port.retiredStoreWordWE = headDataEntry.wordWE;
        port.retiredStoreByteWE = headDataEntry.byteWE;

        port.storeQueueHeadPtr = headPtr;


        // --- Forwarding
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            sqReadPtr[i] = pickedPtr[i] >= STORE_QUEUE_ENTRY_NUM ?
                pickedPtr[i] - STORE_QUEUE_ENTRY_NUM : pickedPtr[i];
            forwardedDataEntry[i] = sqReadData[i];

            executedLoadWordRE[i] =
                LSQ_ToBlockWordEnable(
                    port.executedLoadAddr[i],
                    port.executedLoadMemAccessMode[i]
                );
            executedLoadByteRE[i] =
                LSQ_ToWordByteEnable(
                    port.executedLoadAddr[i],
                    port.executedLoadMemAccessMode[i]
                );
        end

        // Detect store-load forwarding between already executed stores and
        // a currently executed load.
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            for (int j = 0; j < STORE_QUEUE_ENTRY_NUM; j++) begin
                addrMatch[i][j] =
                    storeQueue[j].finished &&
                    storeQueue[j].address == LSQ_ToBlockAddr(port.executedLoadAddr[i]) &&
                    ((storeQueue[j].wordWE & executedLoadWordRE[i]) != '0) &&
                    ((storeQueue[j].byteWE & executedLoadByteRE[i]) != '0);
            end
        end

        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            // ロードのフォワーディングの依存元となるストアは1つに限られる。
            // ストアがwriteしてないバイトを、ロードがreadしようとした場合、
            // フォワーディングは失敗となる。
            if (pickedPtr[i] < STORE_QUEUE_ENTRY_NUM) begin
                forwardMiss[i] = !storeQueue[pickedPtr[i]].regValid ||
                    ((~forwardedDataEntry[i].wordWE & executedLoadWordRE[i]) != '0) ||
                    ((~forwardedDataEntry[i].byteWE & executedLoadByteRE[i]) != '0);
                forwardedLoadData[i] = forwardedDataEntry[i].data;
            end
            else begin
                // Out of range of store queue
                forwardMiss[i] = FALSE;
                forwardedLoadData[i] = '0;
            end
            storeLoadForwarded[i] = port.executeLoad[i] && picked[i];
        end

        port.forwardedLoadData = forwardedLoadData;
        port.forwardMiss = forwardMiss;
        port.storeLoadForwarded = storeLoadForwarded;
    end

    //
    // Assertions
    //
    generate
        for (genvar i = 0; i < LOAD_ISSUE_WIDTH; i++) begin : assertionBlock
            //  |-L--h***S***t-------|
            `RSD_ASSERT_CLK(
                port.clk,
                !(port.executeLoad[i] && headPtr < tailPtr && port.executedStoreQueuePtrByLoad[i] < headPtr),
                "1:A load's executedStoreQueuePtr is illegal."
            );

            //  |----h******t--L----|
            `RSD_ASSERT_CLK(
                port.clk,
                !(port.executeLoad[i] && headPtr < tailPtr && tailPtr < port.executedStoreQueuePtrByLoad[i]),
                "2:A load's executedStoreQueuePtr is illegal."
            );

            //  |******t--L--h*******|
            `RSD_ASSERT_CLK(
                port.clk,
                !(port.executeLoad[i] && tailPtr <= headPtr &&
                tailPtr < port.executedStoreQueuePtrByLoad[i] && port.executedStoreQueuePtrByLoad[i] < headPtr),
                "3:A load's executedStoreQueuePtr is illegal."
            );
        end
    endgenerate

    `RSD_ASSERT_CLK(
        port.clk,
        port.rst || !((port.releaseStoreQueueHead ) && curCount == 0),
        "Pop from a empty store queue."
    );


endmodule : StoreQueue

// ---- LoadStoreUnit/StoreCommitter.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Store queue
//


import BasicTypes::*;
import CacheSystemTypes::*;
import OpFormatTypes::*;
import LoadStoreUnitTypes::*;
import MemoryMapTypes::*;
import DebugTypes::*;

module StoreCommitter(
    LoadStoreUnitIF.StoreCommitter port,
    RecoveryManagerIF.StoreCommitter recovery,
    IO_UnitIF.StoreCommitter ioUnit,
    DebugIF.StoreCommitter debug
);

    // State machine
    typedef enum logic
    {
        PHASE_COMMIT = 0,
        PHASE_RECOVER = 1
    } Phase;
    Phase phase;
    Phase nextPhase;

    StoreQueueCountPath unfinishedStoreNum;
    StoreQueueCountPath nextUnfinishedStoreNum;

    always_ff @( posedge port.clk ) begin
        if (port.rst) begin
            phase <= PHASE_COMMIT;
            unfinishedStoreNum <= '0;
        end
        else begin
            phase <= nextPhase;
            unfinishedStoreNum <= nextUnfinishedStoreNum;
        end
    end

    always_comb begin
        // Decide a next phase.
        if(port.rst) begin
            nextPhase = PHASE_COMMIT;
        end
        else if (recovery.toRecoveryPhase) begin
            nextPhase = PHASE_RECOVER;
        end
        else if (phase == PHASE_RECOVER ) begin
            // All entries are released.
            // Store Queue is recovered in one cycle.
            nextPhase = PHASE_COMMIT;
        end
        else begin
            nextPhase = phase;
        end
    end

    MSHR_Phase portMSHRPhase[MSHR_NUM];
    logic portStoreHasAllocatedMSHR;
    MSHR_IndexPath portStoreMSHRID;
    always_comb begin
        for (int i = 0; i < MSHR_NUM; i++) begin
            portMSHRPhase[i] = port.mshrPhase[i];
        end
        portStoreHasAllocatedMSHR = port.storeHasAllocatedMSHR[0];
        portStoreMSHRID = port.storeMSHRID[0];
    end


    // The pipeline register of store commit pipeline.
    logic stallStoreTagStage;
    typedef struct packed {
        logic valid;
        logic condEnabled;
        LSQ_BlockDataPath data;
        LSQ_BlockAddrPath blockAddr;
        LSQ_BlockWordEnablePath wordWE;
        LSQ_WordByteEnablePath byteWE;
        logic isIO;
    } StgReg;

    StgReg tagStagePipeReg;
    StgReg nextTagStagePipeReg;
    StgReg dataStagePipeReg;
    StgReg nextDataStagePipeReg;
    logic headStoreHasAllocatedMSHRPipeReg;
    MSHR_IndexPath storeMSHRID;

    always_ff @( posedge port.clk ) begin
        if (port.rst) begin
            tagStagePipeReg <= '0;
            dataStagePipeReg <= '0;
            headStoreHasAllocatedMSHRPipeReg <= FALSE;
            storeMSHRID <= '0;
        end
        else begin
            if (!stallStoreTagStage) begin
                tagStagePipeReg <= nextTagStagePipeReg;
            end
            dataStagePipeReg <= nextDataStagePipeReg;

            // Memorize whether a head store has allocated a MSHR entry or not.
            if (!stallStoreTagStage) begin
                headStoreHasAllocatedMSHRPipeReg <= FALSE;
            end
            else if (!headStoreHasAllocatedMSHRPipeReg) begin
                headStoreHasAllocatedMSHRPipeReg <= portStoreHasAllocatedMSHR;
            end

            // Memorize the allocated mshr id when the head store allocates a mshr entry.
            if (portStoreHasAllocatedMSHR) begin
                storeMSHRID <= portStoreMSHRID;
            end
        end
    end

    // Generate DCache write enable signals.
    function automatic DCacheByteEnablePath GenerateDCacheWriteEnable(
        LSQ_BlockWordEnablePath wordWE,
        LSQ_WordByteEnablePath byteWE, 
        LSQ_BlockAddrPath blockAddr
    );
        DCacheByteEnablePath ret;
        LSQ_WordByteEnablePath [LSQ_BLOCK_WORD_WIDTH-1:0] we;

        for (int i = 0; i < LSQ_BLOCK_WORD_WIDTH; i++) begin
            if (wordWE[i])
                we[i] = byteWE;
            else
                we[i] = '0;
        end

        // LSQ block to DCache
        ret = we;
        ret = ret << (
            LSQ_BLOCK_BYTE_WIDTH * 
            LSQ_SelectBits(blockAddr, 0, DCACHE_LINE_BYTE_NUM_BIT_WIDTH-LSQ_BLOCK_BYTE_WIDTH_BIT_SIZE)
        );
        return ret;
    endfunction

    function automatic DCacheLinePath GenerateDCacheLine(
        LSQ_BlockDataPath data
    );
        // WE で不要な部分は落とされるので，単純にデュプリケートする
        DCacheLinePath line;
        line = '0;
        for (int i = 0; i < DCACHE_LINE_BYTE_NUM/LSQ_BLOCK_BYTE_WIDTH; i++) begin
             line[i*LSQ_BLOCK_WIDTH +: LSQ_BLOCK_WIDTH] = data;
        end
        return line;
    endfunction


    // Pipeline stage strcuture:
    // | Commit | SQ | Tag | Data
    //
    // Commit: The processor commit stage.
    //
    // SQ:      Read a store queue entry.
    // Tag:     Access tag array & hit/miss detection.
    // Data:    Write data array.


    logic dcWriteReq;
    PhyAddrPath dcWriteAddr;
    DCacheLinePath dcWriteData;
    logic isIO;
    logic [DCACHE_LINE_BYTE_NUM-1:0] dcWriteByteWE;
    StoreQueueIndexPath retiredStoreQueuePtr;
    // --- SQ stage.
    always_comb begin
        retiredStoreQueuePtr =
            port.storeQueueHeadPtr +
            (tagStagePipeReg.valid ? 1 : 0) +
            (dataStagePipeReg.valid ? 1 : 0);
        if (retiredStoreQueuePtr >= STORE_QUEUE_ENTRY_NUM) begin
            // Compensate the index to point in the store queue
            retiredStoreQueuePtr -= STORE_QUEUE_ENTRY_NUM;
        end

        port.retiredStoreQueuePtr = retiredStoreQueuePtr;

        nextUnfinishedStoreNum = unfinishedStoreNum;
        if (port.commitStore) begin
            nextUnfinishedStoreNum += port.commitStoreNum;
        end

        isIO = 
            IsPhyAddrIO(
                LSQ_ToFullPhyAddrFromBlockAddrAndWordWE(
                    port.retiredStoreLSQ_BlockAddr, port.retiredStoreWordWE
                )
            );

        port.busyInRecovery = phase == PHASE_RECOVER;

        if (unfinishedStoreNum == 0) begin
            // There is no entry for pushing to the store commit pipeline.
            nextTagStagePipeReg = '0;
            nextTagStagePipeReg.valid = FALSE;
            dcWriteReq = FALSE;
        end
        else begin
            nextTagStagePipeReg.isIO = isIO;

            // Push an store access to the store commit pipeline.
            if (!port.retiredStoreCondEnabled || isIO) begin
                dcWriteReq = FALSE;
                nextTagStagePipeReg.valid = TRUE;   // Push for releasing an entry..
            end
            else begin
                dcWriteReq = !stallStoreTagStage;
                nextTagStagePipeReg.valid = port.dcWriteReqAck;
            end

            nextTagStagePipeReg.condEnabled = port.retiredStoreCondEnabled;
            nextTagStagePipeReg.blockAddr = port.retiredStoreLSQ_BlockAddr;
            nextTagStagePipeReg.data = port.retiredStoreData;
            nextTagStagePipeReg.wordWE = port.retiredStoreWordWE;
            nextTagStagePipeReg.byteWE = port.retiredStoreByteWE;

            if (!stallStoreTagStage && nextTagStagePipeReg.valid) begin
                nextUnfinishedStoreNum--;
            end

        end

        if (stallStoreTagStage) begin
            // When a head store has allocated a mshr entry, it skips writebacking its data.
            if (headStoreHasAllocatedMSHRPipeReg) begin
                dcWriteReq = FALSE;
            end
            else begin
                dcWriteReq = tagStagePipeReg.condEnabled;
            end

            dcWriteAddr =
                LSQ_ToFullAddrFromBlockAddr(tagStagePipeReg.blockAddr);
            dcWriteData =
                GenerateDCacheLine(tagStagePipeReg.data);
            dcWriteByteWE =
                GenerateDCacheWriteEnable(tagStagePipeReg.wordWE, tagStagePipeReg.byteWE, tagStagePipeReg.blockAddr);
        end
        else begin
            dcWriteAddr =
                LSQ_ToFullAddrFromBlockAddr(port.retiredStoreLSQ_BlockAddr);
            dcWriteData = 
                GenerateDCacheLine(port.retiredStoreData);
            dcWriteByteWE =
                GenerateDCacheWriteEnable(port.retiredStoreWordWE, port.retiredStoreByteWE, port.retiredStoreLSQ_BlockAddr);
        end

        port.dcWriteReq = dcWriteReq;
        port.dcWriteData = dcWriteData;
        port.dcWriteByteWE = dcWriteByteWE;
        port.dcWriteAddr = dcWriteAddr;
    end

    // --- Tag stage
    always_comb begin
        if (tagStagePipeReg.valid) begin
            if(!tagStagePipeReg.condEnabled || tagStagePipeReg.isIO) begin
                stallStoreTagStage = FALSE;
            end
            else if (headStoreHasAllocatedMSHRPipeReg) begin
                // When a head store has allocated a mshr entry, stall until its data is written to cache by MSHR.
                if (portMSHRPhase[storeMSHRID] > MSHR_PHASE_MISS_WRITE_CACHE_REQUEST) begin
                    stallStoreTagStage = FALSE;
                end
                else begin
                    stallStoreTagStage = TRUE;
                end
            end
            else begin
                stallStoreTagStage = !port.dcWriteHit;   // Stall if miss!
            end
        end
        else begin
            stallStoreTagStage = FALSE;
        end

        nextDataStagePipeReg = tagStagePipeReg;
        if (stallStoreTagStage) begin
            nextDataStagePipeReg.valid = FALSE;
        end
    end

    // Whether to release the head entry(s) of the SQ.
    logic releaseStoreQueueHead;
    // The number of released entries.
    CommitLaneCountPath releaseStoreQueueHeadEntryNum;
    // --- Data stage
    always_comb begin
        ioUnit.ioWE = FALSE;
        ioUnit.ioWriteDataIn = 
            LSQ_ToScalarWordDataFromBlockData(dataStagePipeReg.data, dataStagePipeReg.wordWE);
        ioUnit.ioWriteAddrIn = 
            LSQ_ToFullPhyAddrFromBlockAddrAndWordWE(dataStagePipeReg.blockAddr, dataStagePipeReg.wordWE);
        if (dataStagePipeReg.valid) begin
            releaseStoreQueueHeadEntryNum = 1;
            releaseStoreQueueHead = TRUE;  // Ops whose conditions are not invalid must be released.
            if (dataStagePipeReg.condEnabled && dataStagePipeReg.isIO) begin
                ioUnit.ioWE = TRUE;
            end
        end
        else begin
            releaseStoreQueueHeadEntryNum = 0;
            releaseStoreQueueHead = FALSE;
        end

        port.releaseStoreQueueHeadEntryNum = releaseStoreQueueHeadEntryNum;
        port.releaseStoreQueueHead = releaseStoreQueueHead;
    end

`ifndef RSD_DISABLE_DEBUG_REGISTER
    always_comb begin
        debug.loadStoreUnitAllocatable = port.allocatable;
        debug.storeCommitterPhase = phase;
        debug.storeQueueCount = port.storeQueueCount;
        debug.busyInRecovery = port.busyInRecovery;
        debug.storeQueueEmpty = port.storeQueueEmpty;
    end
`endif

    `RSD_ASSERT_CLK(
        port.clk,
        port.rst || (unfinishedStoreNum <= STORE_QUEUE_ENTRY_NUM),
        "Committed store num is larger than store queue entry num." 
    );


    `RSD_ASSERT_CLK(
        port.clk,
        port.rst || !(phase == PHASE_RECOVER && port.commitStore && port.commitStoreNum > 0),
        "Stores are committed in recovery phase." 
    );

endmodule : StoreCommitter

// ---- RenameLogic/RenameLogic.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// RenameLogic
//

import BasicTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;


module RenameLogic (
    RenameLogicIF.RenameLogic port,
    ActiveListIF.RenameLogic activeList,
    RecoveryManagerIF.RenameLogic recovery
);

    logic allocatePhyReg [ RENAME_WIDTH ];
    PRegNumPath allocatedPhyRegNum [ RENAME_WIDTH ];

    logic allocatePhyScalarReg [ RENAME_WIDTH ];
    PScalarRegNumPath allocatedPhyScalarRegNum [ RENAME_WIDTH ];
    logic releasePhyScalarReg [ COMMIT_WIDTH ];
    PScalarRegNumPath releasedPhyScalarRegNum [ COMMIT_WIDTH ];
    ScalarFreeListCountPath scalarFreeListCount;

`ifdef RSD_ENABLE_VECTOR_PATH
    logic allocatePhyVectorReg [ RENAME_WIDTH ];
    PVectorRegNumPath allocatedPhyVectorRegNum [ RENAME_WIDTH ];
    logic releasePhyVectorReg [ COMMIT_WIDTH ];
    PVectorRegNumPath releasedPhyVectorRegNum [ COMMIT_WIDTH ];
    VectorFreeListCountPath vectorFreeListCount;
`endif

    ActiveListEntry alReadData [ COMMIT_WIDTH ];

    //
    // --- Free lists for registers.
    //
    MultiWidthFreeList #(
        .SIZE( SCALAR_FREE_LIST_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( PSCALAR_NUM_BIT_WIDTH ),
        .PUSH_WIDTH( COMMIT_WIDTH ),
        .POP_WIDTH( RENAME_WIDTH ),
        .INITIAL_LENGTH( SCALAR_FREE_LIST_ENTRY_NUM )
    ) scalarFreeList (
        .clk( port.clk ),
        .rst( port.rst ),
        .rstStart( port.rstStart ),
        .count( scalarFreeListCount ),

        .pop( allocatePhyScalarReg ),
        .poppedData( allocatedPhyScalarRegNum ),

        .push( releasePhyScalarReg ),
        .pushedData( releasedPhyScalarRegNum )
    );

`ifdef RSD_ENABLE_VECTOR_PATH
    MultiWidthFreeList #(
        .SIZE( VECTOR_FREE_LIST_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( PVECTOR_NUM_BIT_WIDTH ),
        .PUSH_WIDTH( COMMIT_WIDTH ),
        .POP_WIDTH( RENAME_WIDTH ),
        .INITIAL_LENGTH( VECTOR_FREE_LIST_ENTRY_NUM )
    ) vectorFreeList (
        .clk( port.clk ),
        .rst( port.rst ),
        .rstStart( port.rstStart ),
        .count( vectorFreeListCount ),

        .pop( allocatePhyVectorReg ),
        .poppedData( allocatedPhyVectorRegNum ),

        .push( releasePhyVectorReg ),
        .pushedData( releasedPhyVectorRegNum )
    );
`endif

    // Index address for recoverying the RMT by copying from the retirement RMT.
    LRegNumPath rmtRecoveryIndex;
    logic [LREG_NUM_BIT_WIDTH:0] rmtRecoveryCount;
    logic inRecoveryRMT;
    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            rmtRecoveryCount <= 0;
            rmtRecoveryIndex <= 0;
        end
        else if (recovery.toRecoveryPhase) begin
            rmtRecoveryCount <= LREG_NUM;
            rmtRecoveryIndex <= 0;
        end
        else begin
            if(rmtRecoveryCount > COMMIT_WIDTH) begin
                rmtRecoveryCount <= rmtRecoveryCount - COMMIT_WIDTH;
            end
            else begin
                rmtRecoveryCount <= 0;
            end

            if (!RECOVERY_FROM_RRMT) begin
                rmtRecoveryIndex <= rmtRecoveryIndex + COMMIT_WIDTH;
            end
            else begin
                rmtRecoveryIndex <= rmtRecoveryIndex + RENAME_WIDTH;
            end
        end
    end

    // RMT control signals, which are generated in RenameLogic.
    logic [ COMMIT_WIDTH-1:0 ] rmtWriteReg;
    PRegNumPath  rmtWriteReg_PhyRegNum[ COMMIT_WIDTH ];
    LRegNumPath  rmtWriteReg_LogRegNum[ COMMIT_WIDTH ];

    // Write port for WAT
    logic watWriteReg[ COMMIT_WIDTH ];
    LRegNumPath watWriteLogRegNum[ COMMIT_WIDTH ];
    IssueQueueIndexPath  watWriteIssueQueuePtr[ COMMIT_WIDTH ];

    LRegNumPath retRMT_ReadReg_LogRegNum[RENAME_WIDTH];

    always_comb begin
        for (int i = 0; i < RENAME_WIDTH; i++) begin
            retRMT_ReadReg_LogRegNum[i] = '0;
        end

        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            // Don't care
            rmtWriteReg[i] = FALSE;
            rmtWriteReg_PhyRegNum[i] = '0;
            rmtWriteReg_LogRegNum[i] = '0;
        end

        // Destinations.
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            allocatedPhyRegNum[i].isVector = port.logDstReg[i].isVector;
            allocatedPhyRegNum[i].regNum =
                (port.logDstReg[i].isVector ? allocatedPhyVectorRegNum[i] : allocatedPhyScalarRegNum[i]);
`else
            allocatedPhyRegNum[i].regNum = allocatedPhyScalarRegNum[i];
`endif
        end

        port.phyDstReg = allocatedPhyRegNum;

        // Whether rmt is in a recovery phase or not.
        inRecoveryRMT = RECOVERY_FROM_RRMT ? ( rmtRecoveryCount != 0 ) : recovery.inRecoveryAL;
        recovery.renameLogicRecoveryRMT = inRecoveryRMT;
        alReadData = activeList.readData;   //for RECOVERY_FROM_ACTIVE_LIST mode

        // Empty flag.
`ifdef RSD_ENABLE_VECTOR_PATH
        port.allocatable =
            !inRecoveryRMT &&   // In a recovery mode, the front-end is stalled.
            (scalarFreeListCount >= RENAME_WIDTH) &&
            (vectorFreeListCount >= RENAME_WIDTH);
`else
        port.allocatable =
            !inRecoveryRMT &&   // In a recovery mode, the front-end is stalled.
            (scalarFreeListCount >= RENAME_WIDTH);
`endif

        // Allocation from the free lists.
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            allocatePhyReg[i] = port.updateRMT[i] && port.writeReg[i];

`ifdef RSD_ENABLE_VECTOR_PATH
            allocatePhyScalarReg[i] = allocatePhyReg[i] && !port.logDstReg[i].isVector;
            allocatePhyVectorReg[i] = allocatePhyReg[i] && port.logDstReg[i].isVector;
`else
            allocatePhyScalarReg[i] = allocatePhyReg[i];
`endif
        end

        // Release to the free lists.
        for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            releasePhyScalarReg[i] =
                port.releaseReg[i] && !port.phyReleasedReg[i].isVector;
            releasePhyVectorReg[i] =
                port.releaseReg[i] && port.phyReleasedReg[i].isVector;
            releasedPhyVectorRegNum[i] = port.phyReleasedReg[i].regNum;
`else
            releasePhyScalarReg[i] = port.releaseReg[i];
`endif
            releasedPhyScalarRegNum[i] = port.phyReleasedReg[i].regNum;
        end

        // Write control of RMTs.
        if( |port.updateRMT ) begin
            // Update the RMT.
            for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
                rmtWriteReg[i] = port.updateRMT[i] && port.writeReg[i];
                rmtWriteReg_PhyRegNum[i] = allocatedPhyRegNum[i];
                rmtWriteReg_LogRegNum[i] = port.logDstReg[i];
            end

            //Recovery-only write port
            for ( int i = RENAME_WIDTH; i < COMMIT_WIDTH; i++ ) begin
                rmtWriteReg[i] = FALSE;

            end
        end
        else if (inRecoveryRMT) begin
            if ( RECOVERY_FROM_RRMT ) begin
                // Copy from the retirement RMT in a recovery mode.
                for (int i = 0; i < RENAME_WIDTH; i++) begin
                    rmtWriteReg[i] = TRUE;
                    rmtWriteReg_PhyRegNum[i] = port.retRMT_ReadReg_PhyRegNum[i];
                    rmtWriteReg_LogRegNum[i] = rmtRecoveryIndex + i;
                    retRMT_ReadReg_LogRegNum[i] = rmtRecoveryIndex + i;
                end

                // RMTの書き込みポート数はコミット幅であるが，RRMTの読み出しポート数はリネーム幅のため，
                // RMTの巻き戻しは１サイクルにつきリネーム幅しか行えない．
                // したがって，RMTの空いた書き込みポートを落としておく．
                for (int i = RENAME_WIDTH; i < COMMIT_WIDTH; i++) begin
                    rmtWriteReg[i] = FALSE;
                    rmtWriteReg_PhyRegNum[i] = '0;
                    rmtWriteReg_LogRegNum[i] = '0;
                end
            end
            else begin //recovery from active list
                for (int i = 0; i < COMMIT_WIDTH; i++) begin
                    rmtWriteReg[i] = ( i < activeList.popTailNum ) ? TRUE : FALSE;
                    rmtWriteReg_PhyRegNum[i] = alReadData[i].phyPrevDstRegNum;
                    rmtWriteReg_LogRegNum[i] = alReadData[i].logDstRegNum;
                end
            end
        end

        // WAT
        // Not support for recovering from RRMT
        if (!inRecoveryRMT) begin
            // Get dependent instruction's issue queue pointer
            for (int i = 0; i < RENAME_WIDTH; i++) begin
                watWriteReg[i] = port.watWriteRegFromPipeReg[i];
                watWriteLogRegNum[i] = port.logDstReg[i];
                watWriteIssueQueuePtr[i] = port.watWriteIssueQueuePtrFromPipeReg[i];
            end

            // This is recovery dedicated port so fixed at NEGATIVE
            for (int i = RENAME_WIDTH; i < COMMIT_WIDTH; i++) begin
                watWriteReg[i] = '0;
                watWriteLogRegNum[i] = '0;
                watWriteIssueQueuePtr[i] = '0;
            end
        end
        else begin
            // Recovery WAT from activelist
            for (int i = 0; i < COMMIT_WIDTH; i++) begin
                // Whether recovery WAT (whether this instruction would write register)
                watWriteReg[i] =  ( i < activeList.popTailNum ) ? alReadData[i].writeReg : FALSE;
                // Information for recovering WAT
                watWriteLogRegNum[i] = alReadData[i].logDstRegNum;
                watWriteIssueQueuePtr[i] = alReadData[i].prevDependIssueQueuePtr;
            end
        end

        // Output
        port.rmtWriteReg = rmtWriteReg;
        port.rmtWriteReg_PhyRegNum = rmtWriteReg_PhyRegNum;
        port.rmtWriteReg_LogRegNum = rmtWriteReg_LogRegNum;

        port.watWriteReg = watWriteReg;
        port.watWriteLogRegNum = watWriteLogRegNum;
        port.watWriteIssueQueuePtr = watWriteIssueQueuePtr;
        port.retRMT_ReadReg_LogRegNum = retRMT_ReadReg_LogRegNum;
    end

endmodule : RenameLogic
// ---- RenameLogic/RenameLogicIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// RenameLogic
//

import BasicTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;


interface RenameLogicIF( input logic clk, rst, rstStart );

    // Logical register numbers.
    LRegNumPath logSrcRegA [ RENAME_WIDTH ];
    LRegNumPath logSrcRegB [ RENAME_WIDTH ];
    LRegNumPath logDstReg [ RENAME_WIDTH ];

    // Renamed physical register numbers.
    PRegNumPath phySrcRegA [ RENAME_WIDTH ];
    PRegNumPath phySrcRegB [ RENAME_WIDTH ];
    PRegNumPath phyDstReg [ RENAME_WIDTH ];
    PRegNumPath phyPrevDstReg [ RENAME_WIDTH ];  // For releasing a register.

    // Read/Write control
    logic [ RENAME_WIDTH-1:0 ] updateRMT;
    logic readRegA [ RENAME_WIDTH ];
    logic readRegB [ RENAME_WIDTH ];
    logic writeReg [ RENAME_WIDTH ];

    // Release registers on retirement and recovery.
    logic releaseReg [ COMMIT_WIDTH ];
    PRegNumPath phyReleasedReg [ COMMIT_WIDTH ];

    // There are enough resources to rename.
    logic allocatable;

    // RMT control signals, which are generated in RenameLogic.
    logic [ COMMIT_WIDTH-1:0 ] rmtWriteReg;
    PRegNumPath  rmtWriteReg_PhyRegNum[ COMMIT_WIDTH ];
    LRegNumPath  rmtWriteReg_LogRegNum[ COMMIT_WIDTH ];

    // Retirement RMT control signals, which are generated in CommitStage.
    logic [COMMIT_WIDTH-1:0] retRMT_WriteReg;
    PRegNumPath retRMT_WriteReg_PhyRegNum[COMMIT_WIDTH];
    LRegNumPath retRMT_WriteReg_LogRegNum[COMMIT_WIDTH];

    PRegNumPath retRMT_ReadReg_PhyRegNum[RENAME_WIDTH];
    LRegNumPath retRMT_ReadReg_LogRegNum[RENAME_WIDTH];

    // WAT control signals, which are generated in RenameLogic.
    logic [RENAME_WIDTH-1 : 0] watWriteRegFromPipeReg;
    IssueQueueIndexPath  watWriteIssueQueuePtrFromPipeReg[ RENAME_WIDTH ];
    IssueQueueIndexPath srcIssueQueuePtrRegA[ RENAME_WIDTH ];
    IssueQueueIndexPath srcIssueQueuePtrRegB[ RENAME_WIDTH ];

    // For Recover WAT from Activelist
    IssueQueueIndexPath prevDependIssueQueuePtr[ RENAME_WIDTH ];

    // Write port for WAT
    logic watWriteReg[ COMMIT_WIDTH ];
    LRegNumPath watWriteLogRegNum[ COMMIT_WIDTH ];
    IssueQueueIndexPath  watWriteIssueQueuePtr[ COMMIT_WIDTH ];

    // Commitment/recovery
    logic commit;
    CommitLaneCountPath commitNum;
    CommitLaneCountPath flushNum;

    // To a rename logic
    modport RenameLogic(
    input
        clk,
        rst,
        rstStart,
        updateRMT,
        writeReg,
        releaseReg,
        phyReleasedReg,
        retRMT_ReadReg_PhyRegNum,
        logDstReg,
        watWriteRegFromPipeReg,
        watWriteIssueQueuePtrFromPipeReg,
    output
        allocatable,
        phyDstReg,
        retRMT_ReadReg_LogRegNum,
        rmtWriteReg,
        rmtWriteReg_PhyRegNum,
        rmtWriteReg_LogRegNum,
        watWriteReg,
        watWriteLogRegNum,
        watWriteIssueQueuePtr
    );

    modport RenameStage(
    input
        phySrcRegA,
        phySrcRegB,
        phyDstReg,
        phyPrevDstReg,
        srcIssueQueuePtrRegA,
        srcIssueQueuePtrRegB,
        allocatable,
        prevDependIssueQueuePtr,
    output
        logSrcRegA,
        logSrcRegB,
        logDstReg,
        updateRMT,
        readRegA,
        readRegB,
        writeReg,
        watWriteRegFromPipeReg,
        watWriteIssueQueuePtrFromPipeReg
    );

    modport CommitStage(
    input
        releaseReg,
        phyReleasedReg,
        flushNum,
    output
        commit,
        commitNum,
        retRMT_WriteReg,
        retRMT_WriteReg_PhyRegNum,
        retRMT_WriteReg_LogRegNum
    );

    modport RenameLogicCommitter(
    input
        clk,
        rst,
        commit,
        commitNum,
    output
        releaseReg,
        phyReleasedReg,
        flushNum
    );

    modport RetirementRMT(
    input
        clk,
        rst,
        rstStart,
        retRMT_WriteReg,
        retRMT_WriteReg_PhyRegNum,
        retRMT_WriteReg_LogRegNum,
        retRMT_ReadReg_LogRegNum,
    output
        retRMT_ReadReg_PhyRegNum
    );

    modport RMT(
    input
        clk,
        rst,
        rstStart,
        rmtWriteReg,
        rmtWriteReg_PhyRegNum,
        rmtWriteReg_LogRegNum,
        watWriteReg,
        watWriteLogRegNum,
        watWriteIssueQueuePtr,
        logSrcRegA,
        logSrcRegB,
        logDstReg,
    output
        phySrcRegA,
        phySrcRegB,
        phyPrevDstReg,
        srcIssueQueuePtrRegA,
        srcIssueQueuePtrRegB,
        prevDependIssueQueuePtr
    );

endinterface : RenameLogicIF


// ---- RenameLogic/ActiveListIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// ActiveListIF
//

import BasicTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;
import LoadStoreUnitTypes::*;

interface ActiveListIF( input logic clk, rst );

    // Push 'pushedValue' on dispatch if this is true.
    logic pushTail [RENAME_WIDTH];

    // This value is pushed to an active list on dispatch.
    ActiveListEntry pushedTailData [RENAME_WIDTH];

    // This pointer is send to an issue queue on dispatch.
    // Execution state is written to an entry corresponding to an pointer.
    ActiveListIndexPath pushedTailPtr [RENAME_WIDTH];

    // Pop the head entry in an active list on commitment.
    CommitLaneCountPath popHeadNum;

    // Pop the Tail entry in an active list on retire.
    CommitLaneCountPath popTailNum;

    // In RRMT recovery mode, readData become the front entries data in an active list.
    // Otherwise, readData become the tail entries data in an active list.
    ActiveListEntry readData[COMMIT_WIDTH];

    // The front entries data in an active list.
    // This is used for commitment desicion.
    ExecutionState headExecState[COMMIT_WIDTH];
    ActiveListCountPath validEntryNum;

    // The count of entries from exception op to tail
    ActiveListCountPath recoveryEntryNum;

    // 'execState' is updated on execution.
    logic               intWrite[INT_ISSUE_WIDTH];
    ActiveListWriteData intWriteData[INT_ISSUE_WIDTH];

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    logic               complexWrite[COMPLEX_ISSUE_WIDTH];
    ActiveListWriteData complexWriteData[COMPLEX_ISSUE_WIDTH];
`endif

    logic               memWrite[MEM_ISSUE_WIDTH];
    ActiveListWriteData memWriteData[MEM_ISSUE_WIDTH];

    // Status of an active list.
    logic allocatable;


    // ActiveList/LSQ TailPtr for recovery
    LoadQueueIndexPath loadQueueRecoveryTailPtr;
    StoreQueueIndexPath storeQueueRecoveryTailPtr;

    // Flush range at exception-detected cycle
    ActiveListIndexPath detectedFlushRangeTailPtr;
    ActiveListIndexPath exceptionOpPtr; // Exception op's ActiveListPtr


    // To active list
    modport ActiveList(
    input
        clk,
        rst,
        pushTail,
        pushedTailData,
        popHeadNum,
        popTailNum,
        intWrite,
        intWriteData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexWrite,
        complexWriteData,
`endif
        memWrite,
        memWriteData,
    output
        pushedTailPtr,
        readData,
        headExecState,
        loadQueueRecoveryTailPtr,
        storeQueueRecoveryTailPtr,
        detectedFlushRangeTailPtr,
        exceptionOpPtr,
        allocatable,
        validEntryNum,
        recoveryEntryNum
    );

    // 'pushedTailPtr' is set to an entry in issue queue.
    // 'pushTail' is push request to an active list.
    // 'pushedTailData' is pushed data.
    modport RenameStage(
    input
        allocatable,
        pushedTailPtr,
        validEntryNum,
    output
        pushTail,
        pushedTailData
    );

    modport IntegerRegisterWriteStage(
    output
        intWrite,
        intWriteData
    );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    modport ComplexIntegerRegisterWriteStage(
    output
        complexWrite,
        complexWriteData
    );
`endif

    modport MemoryRegisterWriteStage(
    output
        memWrite,
        memWriteData
    );

    modport CommitStage(
    input
        readData,
        headExecState,
        validEntryNum
    );

    modport RenameLogic(
    input
        readData,
        popTailNum
    );

    modport RenameLogicCommitter(
    input
        readData,
        recoveryEntryNum,
    output
        popHeadNum,
        popTailNum
    );

    modport RecoveryManager(
    input
        loadQueueRecoveryTailPtr,
        storeQueueRecoveryTailPtr,
        detectedFlushRangeTailPtr,
        exceptionOpPtr
    );

endinterface : ActiveListIF
// ---- RenameLogic/ActiveList.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Active list
//


import BasicTypes::*;
import MemoryMapTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import LoadStoreUnitTypes::*;
import PipelineTypes::*;
import DebugTypes::*;


//
// Current implementation is a FIFO with:
//   - 1 input to tail for dispatch.
//   - 1 output from head for commit/recovery.
//   - 1 input to random entries for execution.
//
module ActiveList(
    ActiveListIF.ActiveList port,
    RecoveryManagerIF.ActiveList recovery,
    ControllerIF.ActiveList ctrl,
    DebugIF.ActiveList debug
);

    //
    // --- Pointers
    //
    ActiveListIndexPath headPtr/*verilator public*/;   // Set it public from a test bench for verilator.
    ActiveListIndexPath headPtrList[COMMIT_WIDTH];
    ActiveListIndexPath tailPtr; // 次に割り当てを行うエントリを指す
    ActiveListIndexPath tailPtrList[COMMIT_WIDTH];
    ActiveListIndexPath readPtrList[COMMIT_WIDTH];
    ActiveListIndexPath pushedTailPtr [RENAME_WIDTH];
    ActiveListCountPath count;
    RenameLaneCountPath pushNum;

    // Parameter: Size, Initial head pos., Initial tail pos., Initial count
    BiTailMultiWidthQueuePointer #(ACTIVE_LIST_ENTRY_NUM, 0, 0, 0, RENAME_WIDTH, COMMIT_WIDTH)
        activeListPointer(
            .clk(port.clk),
            .rst(port.rst), // On flush, pointers are recovered by the store committer.
            .popHead(port.popHeadNum > 0),
            .popHeadCount(port.popHeadNum),
            .pushTail(pushNum > 0),
            .pushTailCount(pushNum),
            .popTail( port.popTailNum > 0 ),
            .popTailCount( port.popTailNum ),
            .count(count),
            .headPtr(headPtr),
            .tailPtr(tailPtr)
        );

    always_comb begin
        // In the active list, recovery and allocation can be simultaneously carried out,
        // thus allocation is decided by its current count without its phase.
        port.allocatable = (count <= ACTIVE_LIST_ENTRY_NUM - RENAME_WIDTH) ? TRUE : FALSE;
        port.validEntryNum = count;

        pushNum = 0;
        for (int i = 0; i < RENAME_WIDTH; i++) begin
            if ((tailPtr + pushNum) >= ACTIVE_LIST_ENTRY_NUM) begin
                pushedTailPtr[i] = tailPtr + pushNum - ACTIVE_LIST_ENTRY_NUM;
            end
            else begin
                pushedTailPtr[i] = tailPtr + pushNum;
            end
            pushNum += (port.pushTail[i] ? 1 : 0);
        end
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            if ((headPtr + i) < ACTIVE_LIST_ENTRY_NUM) begin
                headPtrList[i] = headPtr + i;
            end
            else begin
                headPtrList[i] = headPtr + i - ACTIVE_LIST_ENTRY_NUM;
            end
        end
        for (int i = 0; i < COMMIT_WIDTH; i++) begin    //Actually limited to RENAME_WIDTH
            if (( tailPtr - 1 - i) >= ACTIVE_LIST_ENTRY_NUM) begin
                tailPtrList[i] = tailPtr - 1 - i + ACTIVE_LIST_ENTRY_NUM;
            end
            else begin
                tailPtrList[i] = tailPtr - 1 - i;
            end
        end

        if( RECOVERY_FROM_ACTIVE_LIST && ( port.popTailNum > 0 ) ) begin
            readPtrList = tailPtrList;
        end else begin
            readPtrList = headPtrList;
        end

        port.detectedFlushRangeTailPtr = tailPtr + pushNum;
        port.pushedTailPtr = pushedTailPtr;
        //port.detectedFlushRangeHeadPtr = headPtr + port.popHeadNum;

        ctrl.activeListEmpty = count == 0;

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // Debug Register
        debug.activeListHeadPtr = headPtr;
        debug.activeListCount = count;
`endif
    end


    //
    // --- Active List
    //
    logic pushTail [RENAME_WIDTH];
    ActiveListEntry pushedTailData [RENAME_WIDTH];
    ActiveListEntry readData[COMMIT_WIDTH];

    //DistributedMultiPortRAM #(
    DistributedMultiBankRAM #(
        .ENTRY_NUM( ACTIVE_LIST_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( $bits( ActiveListEntry ) ),
        .READ_NUM( COMMIT_WIDTH  ),
        .WRITE_NUM( RENAME_WIDTH )
    ) activeList (
        .clk( port.clk ),
        .we( pushTail ),
        .wa( pushedTailPtr ),
        .wv( pushedTailData ),
        .ra( readPtrList ),
        .rv( readData )
    );

    always_comb begin
        pushTail = port.pushTail;
        pushedTailData = port.pushedTailData;
        port.readData = readData;
    end


    //
    // --- Execution result write
    //
    logic we[ISSUE_WIDTH];
    ActiveListWriteData writeData[ISSUE_WIDTH];
    always_comb begin
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            we[i] = port.intWrite[i];
            writeData[i] = port.intWriteData[i];
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            we[(i+INT_ISSUE_WIDTH)] = port.complexWrite[i];
            writeData[(i+INT_ISSUE_WIDTH)] = port.complexWriteData[i];
        end
`endif
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            we[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.memWrite[i];
            writeData[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.memWriteData[i];
        end
    end


    // Recovery register.
    // Record the oldest recovery point of an op that occurs misprediction.
    typedef struct packed
    {
        PC_Path pc;
        AddrPath faultingDataAddr;
        ActiveListIndexPath ptr;
        LoadQueueIndexPath loadQueuePtr;
        StoreQueueIndexPath storeQueuePtr;
        logic valid;
        ExecutionState state;
    } RecoveryRegPath;

    ActiveListCountPath oldestAge;
    ActiveListCountPath writeAge[ISSUE_WIDTH];
    logic exceptionDetected;
    RefetchType refetchType;
    IssueLaneIndexPath exceptionIndex;

    RecoveryRegPath recoveryReg;
    RecoveryRegPath nextRecoveryReg;
    ActiveListCountPath recoveryEntryNum, nextRecoveryEntryNum;
    ActiveListIndexPath flushRangeHeadPtr, flushRangeTailPtr;
    always_ff@(posedge port.clk) begin
        if (port.rst || recovery.toRecoveryPhase && !exceptionDetected ) begin
            recoveryReg <= '0;
        end
        else begin
            recoveryReg <= nextRecoveryReg;
        end
    end

    // One cycle delay for RenameLogicCommitter's phase flow.
    always_ff@(posedge port.clk) begin
        if(port.rst)
            recoveryEntryNum <= '0;
        else if(recovery.toRecoveryPhase) begin
            recoveryEntryNum <= nextRecoveryEntryNum;
        end
    end

    always_comb begin
        nextRecoveryReg = recoveryReg;
        oldestAge = ActiveListPtrToAge(recoveryReg.ptr, headPtr);
        
        exceptionIndex = '0;
        exceptionDetected = FALSE;
        refetchType = REFETCH_TYPE_THIS_PC;

        for (int i = 0; i < ISSUE_WIDTH; i++) begin
            writeAge[i] = ActiveListPtrToAge(writeData[i].ptr, headPtr);

            if (we[i] && 
                !(writeData[i].state inside {EXEC_STATE_NOT_FINISHED, EXEC_STATE_SUCCESS})
            ) begin
                // Record the oldest recovery point.
                if (!nextRecoveryReg.valid || writeAge[i] < oldestAge) begin
                    oldestAge = writeAge[i];
                    nextRecoveryReg.valid = TRUE;
                    nextRecoveryReg.ptr = writeData[i].ptr;
                    nextRecoveryReg.loadQueuePtr = writeData[i].loadQueuePtr;
                    nextRecoveryReg.storeQueuePtr = writeData[i].storeQueuePtr;
                    nextRecoveryReg.pc = writeData[i].pc;
                    nextRecoveryReg.faultingDataAddr = writeData[i].dataAddr;
                    nextRecoveryReg.state = writeData[i].state;

                    // Rwステージで例外が検出された時点でリカバリを開始する(詳細はRecoveryManager)
                    // EXEC_STATE_TRAP や例外は必ずコミット時に処理する（CSR の操作が伴うため）
                    exceptionDetected = writeData[i].state inside {
                        EXEC_STATE_REFETCH_NEXT, EXEC_STATE_REFETCH_THIS
                    };
                    exceptionIndex = i;
                    // refetchTypeはflushOpのheadPtrを決めるためとrecoveredPCを確定するために使う
                    // Int命令の例外は分岐命令なので分岐ターゲットに飛ぶ
                    // Mem命令のREFETCH_NEXTは順序違反検出なので次のPCに飛ぶ
                    if(writeData[i].state == EXEC_STATE_REFETCH_NEXT) begin
                        refetchType = ( 
                            writeData[i].isBranch ? REFETCH_TYPE_BRANCH_TARGET : 
                            writeData[i].isStore ?  REFETCH_TYPE_STORE_NEXT_PC : 
                                                    REFETCH_TYPE_NEXT_PC 
                        );
                    end
                    else begin
                        refetchType = REFETCH_TYPE_THIS_PC;
                    end
                end
            end

            if (exceptionDetected && !recovery.unableToStartRecovery) begin
                nextRecoveryReg.state = EXEC_STATE_SUCCESS;
            end
        end

        //PCのリカバリに用いる
        //これらのPCはRecoveryManagerのRecoveryRegisterを経由してFetchStageに送られる
        recovery.recoveredPC_FromCommitStage = ToAddrFromPC(recoveryReg.pc);
        recovery.recoveredPC_FromRwStage = ToAddrFromPC(nextRecoveryReg.pc);

        // Fault handling
        recovery.faultingDataAddr = recoveryReg.faultingDataAddr;

        //LSQのリカバリに用いる
        port.loadQueueRecoveryTailPtr = recoveryReg.loadQueuePtr;
        port.storeQueueRecoveryTailPtr = recoveryReg.storeQueuePtr;

        //リカバリをしなければならない命令はアクティブリストのtailからリカバリを起こした命令(またはその命令の後ろ)までのエントリにあたる
        flushRangeHeadPtr = recovery.flushRangeHeadPtr;
        flushRangeTailPtr = recovery.flushRangeTailPtr;
        nextRecoveryEntryNum = (flushRangeTailPtr >= flushRangeHeadPtr) ?
                                flushRangeTailPtr - flushRangeHeadPtr : ACTIVE_LIST_ENTRY_NUM + flushRangeTailPtr - flushRangeHeadPtr;
        // RenameLogicCommitterにtoRecoveryPhase信号が
        // 届いた次のサイクルに信号を送る必要があるので,1サイクルの遅延を入れている
        port.recoveryEntryNum = recoveryEntryNum;

        // RecoveryManagerに例外が検出されたことを知らせる信号
        // 先行してRwステージリカバリを行っていた場合は, コミット時まで待つ
        recovery.exceptionDetectedInRwStage = exceptionDetected && !recovery.unableToStartRecovery;
        recovery.refetchTypeFromRwStage = refetchType;

        // flushRangeHeadPtrを保存するために用いる
        port.exceptionOpPtr = nextRecoveryReg.ptr;
    end

    //
    // --- ExecutionState
    //

    parameter EXEC_STATE_WRITE_NUM = RENAME_WIDTH + ISSUE_WIDTH;
    logic               esWE[EXEC_STATE_WRITE_NUM];
    ActiveListIndexPath esWA[EXEC_STATE_WRITE_NUM];
    ActiveListIndexPath esRA[COMMIT_WIDTH];
    logic esWV[EXEC_STATE_WRITE_NUM];
    logic esRV[COMMIT_WIDTH];
    
    ExecutionState headExecState[COMMIT_WIDTH];

    DistributedMultiPortRAM #(
        .ENTRY_NUM(ACTIVE_LIST_ENTRY_NUM),
        .ENTRY_BIT_SIZE($bits(logic)),
        .READ_NUM(COMMIT_WIDTH),
        .WRITE_NUM(EXEC_STATE_WRITE_NUM)
    )  execState (
        .clk(port.clk),
        .we(esWE),
        .wa(esWA),
        .wv(esWV),
        .ra(esRA),
        .rv(esRV)
    );

    always_comb begin
        if (port.rst) begin
            // Head entries are initialized.
            for (int i = 0; i < EXEC_STATE_WRITE_NUM; i++) begin
                esWE[i] = FALSE;
                esWA[i] = i;
                esWV[i] = FALSE;
            end
        end
        else begin
            for (int i = 0; i < RENAME_WIDTH; i++) begin
                esWE[i] = port.pushTail[i];
                esWA[i] = pushedTailPtr[i];
                esWV[i] = FALSE;
            end

            for (int i = 0; i < ISSUE_WIDTH; i++ ) begin
                esWE[(i+RENAME_WIDTH)] = we[i];
                esWA[(i+RENAME_WIDTH)] = writeData[i].ptr;
                //Rwステージで検出された例外はコミットステージで再度検出されないようにExecStateをEXEC_STATE_SUCCESSにしておく必要がある
                //exceptionIndexは例外を起こした命令の場所を示す
                //esWV[(i+RENAME_WIDTH)] = ( exceptionDetected && !recovery.unableToStartRecovery && (exceptionIndex == i) ) ? TRUE : writeData[i].state;
                esWV[(i+RENAME_WIDTH)] = (writeData[i].state != EXEC_STATE_NOT_FINISHED);
            end
        end

        esRA = headPtrList;
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            if (recoveryReg.valid && (esRA[i] == recoveryReg.ptr)) begin
                headExecState[i] = recoveryReg.state;
            end
            else begin
                if (esRV[i]) begin
                    headExecState[i] = EXEC_STATE_SUCCESS;
                end
                else begin
                    headExecState[i] = EXEC_STATE_NOT_FINISHED;
                end
            end
        end
        port.headExecState = headExecState;
    end
    
// Verify whether the ExecState is correct
`ifndef RSD_SYNTHESIS
    logic               esRefWE[EXEC_STATE_WRITE_NUM];
    ActiveListIndexPath esRefWA[EXEC_STATE_WRITE_NUM];
    ActiveListIndexPath esRefRA[COMMIT_WIDTH];
    logic [EXEC_STATE_BIT_WIDTH-1:0] esRefWV[EXEC_STATE_WRITE_NUM];
    logic [EXEC_STATE_BIT_WIDTH-1:0] esRefRV[COMMIT_WIDTH];
    logic execStateIsDifferentFromRef;
    
    // Whether in recovery
    logic regInRecovery, nextInRecovery;
    always_ff@(posedge port.clk) begin
        if (port.rst) begin
            regInRecovery <= FALSE;
        end
        else begin
            regInRecovery <= nextInRecovery;
        end
    end


    // Record ExecState of all instructions in ActiveList
    DistributedMultiPortRAM #(
        .ENTRY_NUM(ACTIVE_LIST_ENTRY_NUM),
        .ENTRY_BIT_SIZE($bits(ExecutionState)),
        .READ_NUM(COMMIT_WIDTH),
        .WRITE_NUM(EXEC_STATE_WRITE_NUM)
    ) execStateRef (
        .clk(port.clk),
        .we(esRefWE),
        .wa(esRefWA),
        .wv(esRefWV),
        .ra(esRefRA),
        .rv(esRefRV)
    );

    ExecutionState headExecStateRef[COMMIT_WIDTH];

    always_comb begin
        esRefRA = headPtrList;
        
        if (port.rst) begin
            // Head entries are initialized.
            for (int i = 0; i < EXEC_STATE_WRITE_NUM; i++) begin
                esRefWE[i] = FALSE;
                esRefWA[i] = i;
                esRefWV[i] = EXEC_STATE_NOT_FINISHED;
            end
        end
        else begin
            for (int i = 0; i < RENAME_WIDTH; i++) begin
                esRefWE[i] = port.pushTail[i];
                esRefWA[i] = pushedTailPtr[i];
                esRefWV[i] = EXEC_STATE_NOT_FINISHED;
            end

            for (int i = 0; i < ISSUE_WIDTH; i++ ) begin
                esRefWE[(i+RENAME_WIDTH)] = we[i];
                esRefWA[(i+RENAME_WIDTH)] = writeData[i].ptr;
                //Rwステージで検出された例外はコミットステージで再度検出されないようにExecStateをEXEC_STATE_SUCCESSにしておく必要がある
                //exceptionIndexは例外を起こした命令の場所を示す
                esRefWV[(i+RENAME_WIDTH)] = ( exceptionDetected && !recovery.unableToStartRecovery && (exceptionIndex == i) ) ? EXEC_STATE_SUCCESS : writeData[i].state;
            end
        end

        nextInRecovery = regInRecovery;
        if (recovery.toRecoveryPhase) begin
            nextInRecovery = TRUE;
        end
        if (recovery.toCommitPhase) begin
            nextInRecovery = FALSE;
        end
        
        execStateIsDifferentFromRef = FALSE;
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            headExecStateRef[i] = ExecutionState'(esRefRV[i]);
            
            // Compare ExecState to reference value
            if (esRV[i] && (i < count) && !nextInRecovery) begin
                execStateIsDifferentFromRef |= 
                    (headExecState[i] != headExecStateRef[i]);
            end

            // Do not check instructions after the exception
            if (esRA[i] == recoveryReg.ptr) begin
                break;
            end
        end
    end

    `RSD_ASSERT_CLK(
        port.clk,
        !execStateIsDifferentFromRef,
        "Execution State value is different from the reference's value."
    );

`endif

endmodule : ActiveList
// ---- RenameLogic/RMT.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Register Map Table and Wakeup Allocation Table
//

import BasicTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;


module RMT( RenameLogicIF.RMT port );

    // RMT read value
    PRegNumPath phySrcRegA [ RENAME_WIDTH ];
    PRegNumPath phySrcRegB [ RENAME_WIDTH ];
    PRegNumPath phyPrevDstReg [ RENAME_WIDTH ];  // For releasing a register.
    
    // WAT read value
    IssueQueueIndexPath srcIssueQueuePtrRegA[ RENAME_WIDTH ];
    IssueQueueIndexPath srcIssueQueuePtrRegB[ RENAME_WIDTH ];

    //
    // -- Integrated RMT & WAT 
    //
    typedef struct packed // struct BTB_Entry
    {
        logic [ RMT_ENTRY_BIT_SIZE-1:0 ] phyRegNum;
        IssueQueueIndexPath regIssueQueuePtr;
    } RMT_Entry;
    
    logic rmtWE [ COMMIT_WIDTH ];
    LRegNumPath rmtWA[ COMMIT_WIDTH ];
    RMT_Entry rmtWV[ COMMIT_WIDTH ];
    LRegNumPath rmtRA[ 3 * RENAME_WIDTH ];
    RMT_Entry rmtRV[ 3 * RENAME_WIDTH ];

    DistributedMultiPortRAM #(
        .ENTRY_NUM( LREG_NUM ),
        .ENTRY_BIT_SIZE( $bits(RMT_Entry) ),
        .READ_NUM( 3 * RENAME_WIDTH ),
        .WRITE_NUM( COMMIT_WIDTH )
    ) regRMT (
        .clk( port.clk ),
        .we( rmtWE ),
        .wa( rmtWA ),
        .wv( rmtWV ),
        .ra( rmtRA ),
        .rv( rmtRV )
    );

    // For initialize
    LRegNumPath rstWriteLogRegNum [ COMMIT_WIDTH ];
    logic [ RMT_ENTRY_BIT_SIZE-1:0 ] rstWritePhyRegNum [ COMMIT_WIDTH ];

    always_comb begin
        // Write data
        for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
            if ( !port.rst ) begin
                rmtWE[i] = port.rmtWriteReg[i];
                rmtWA[i] = port.rmtWriteReg_LogRegNum[i];
                rmtWV[i].phyRegNum = port.rmtWriteReg_PhyRegNum[i].regNum;
                
                // Write to Write Bypass
                for ( int j = 0; j < i; j++ ) begin
                    if ( rmtWE[i] && rmtWA[i] == rmtWA[j] ) begin
                        rmtWE[j] = FALSE;
                    end
                end

                // Write data
                rmtWV[i].regIssueQueuePtr = port.watWriteIssueQueuePtr[i];
            end
            else begin
                // Reset RMT
                rmtWE[i] = ( i == 0 ? TRUE : FALSE );
                rmtWA[i] = rstWriteLogRegNum[i];
                rmtWV[i].phyRegNum = rstWritePhyRegNum[i];
                rmtWV[i].regIssueQueuePtr = '0;
            end
        end

        // Read data
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            // Read RMT with using logical register number
            rmtRA[ 3*i   ] = port.logSrcRegA[i];
            rmtRA[ 3*i+1 ] = port.logSrcRegB[i];
            rmtRA[ 3*i+2 ] = port.logDstReg[i];
            
`ifdef RSD_ENABLE_VECTOR_PATH
            phySrcRegA[i].isVector    = port.logSrcRegA[i].isVector;
            phySrcRegB[i].isVector    = port.logSrcRegB[i].isVector;
            phyPrevDstReg[i].isVector = port.logDstReg[i].isVector;
`endif
            
            // Physical register number is read from RMT
            phySrcRegA[i].regNum    = rmtRV[ 3*i   ].phyRegNum;
            phySrcRegB[i].regNum    = rmtRV[ 3*i+1 ].phyRegNum;
            phyPrevDstReg[i].regNum = rmtRV[ 3*i+2 ].phyRegNum;

            // Dependent instructions' issue queue pointer is read from WAT
            srcIssueQueuePtrRegA[i] = rmtRV[3*i].regIssueQueuePtr;
            srcIssueQueuePtrRegB[i] = rmtRV[3*i + 1].regIssueQueuePtr;
            port.prevDependIssueQueuePtr[i] = rmtRV[3*i + 2].regIssueQueuePtr;
            
            // Write to Read Bypass
            for ( int j = 0; j < i; j++ ) begin
                if ( port.rmtWriteReg[j] ) begin
                    if ( port.logSrcRegA[i] == port.logDstReg[j] ) begin
                        phySrcRegA[i].regNum = port.rmtWriteReg_PhyRegNum[j].regNum;
                        srcIssueQueuePtrRegA[i] = port.watWriteIssueQueuePtr[j];
                    end
                    if ( port.logSrcRegB[i] == port.logDstReg[j] ) begin
                        phySrcRegB[i].regNum = port.rmtWriteReg_PhyRegNum[j].regNum;
                        srcIssueQueuePtrRegB[i] = port.watWriteIssueQueuePtr[j];
                    end
                    if ( port.logDstReg[i] == port.logDstReg[j] )
                        phyPrevDstReg[i].regNum = port.rmtWriteReg_PhyRegNum[j].regNum;
                end
            end
        end

        // To interface
        port.phySrcRegA = phySrcRegA;
        port.phySrcRegB = phySrcRegB;
        port.phyPrevDstReg = phyPrevDstReg;

        port.srcIssueQueuePtrRegA = srcIssueQueuePtrRegA;
        port.srcIssueQueuePtrRegB = srcIssueQueuePtrRegB;
    end
    
    // - Initialization logic
    always_ff @( posedge port.clk ) begin
        for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
            if ( port.rstStart ) begin
                rstWriteLogRegNum[i] <= 0;
            end
            else begin
                rstWriteLogRegNum[i] <= rstWriteLogRegNum[i] + 1;
            end
        end
    end
    
    // フリーリストには0からFREE_LIST_ENTRY_NUM-1が入っているので、
    // RMTの初期値はFREE_LIST_ENTRY_NUM以上の値を使う
    always_comb begin
        for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            if ( !rstWriteLogRegNum[i].isVector ) begin
                rstWritePhyRegNum[i] =
                    rstWriteLogRegNum[i].regNum + SCALAR_FREE_LIST_ENTRY_NUM;
            end
            else begin
                rstWritePhyRegNum[i] =
                    rstWriteLogRegNum[i].regNum + VECTOR_FREE_LIST_ENTRY_NUM;
            end
`else
            rstWritePhyRegNum[i] =
                rstWriteLogRegNum[i].regNum + SCALAR_FREE_LIST_ENTRY_NUM;
`endif
        end
    end

endmodule
// ---- RenameLogic/RetirementRMT.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Register Map Table
//

import BasicTypes::*;
import RenameLogicTypes::*;


module RetirementRMT(RenameLogicIF.RetirementRMT port);

    //
    // --- RMT for general registers
    //
    logic we [ COMMIT_WIDTH ];
    LRegNumPath writeLogRegNum[ COMMIT_WIDTH ];
    logic [ RMT_ENTRY_BIT_SIZE-1:0 ] writePhyRegNum[ COMMIT_WIDTH ];

    LRegNumPath rstWriteLogRegNum[ COMMIT_WIDTH ];
    logic [ RMT_ENTRY_BIT_SIZE-1:0 ] rstWritePhyRegNum[ COMMIT_WIDTH ];
    
    LRegNumPath readLogRegNum[ RENAME_WIDTH ];
    logic [ RMT_ENTRY_BIT_SIZE-1:0 ] readPhyRegNum[ RENAME_WIDTH ];
    
    DistributedMultiPortRAM #( 
        .ENTRY_NUM( RMT_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( RMT_ENTRY_BIT_SIZE ),
        .READ_NUM( RENAME_WIDTH ),
        .WRITE_NUM( COMMIT_WIDTH )
    ) regRMT ( 
        .clk( port.clk ),
        .we( we ),
        .wa( writeLogRegNum ),
        .wv( writePhyRegNum ),
        .ra( readLogRegNum ),
        .rv( readPhyRegNum )
    );
    
    always_comb begin
        for (int i = 0; i < COMMIT_WIDTH; i++) begin

            // Write data
            if ( !port.rst ) begin
                writeLogRegNum[i] = port.retRMT_WriteReg_LogRegNum[i];
                writePhyRegNum[i] = port.retRMT_WriteReg_PhyRegNum[i].regNum;
                we[i] = port.retRMT_WriteReg[i];
                
                // Write to Write Bypass
                for (int j = 0; j < i; j++) begin
                    if (we[i] && writeLogRegNum[i] == writeLogRegNum[j])
                        we[j] = FALSE;
                end
            end
            else begin
                // Reset RMT
                writeLogRegNum[i] = rstWriteLogRegNum[i];
                writePhyRegNum[i] = rstWritePhyRegNum[i];
                we[i] = (i == 0 ? TRUE : FALSE);
            end
        end
            
        // Read data
        for (int i = 0; i < RENAME_WIDTH; i++) begin
            readLogRegNum[i] = port.retRMT_ReadReg_LogRegNum[i];
            port.retRMT_ReadReg_PhyRegNum[i].regNum = readPhyRegNum[i];
`ifdef RSD_ENABLE_VECTOR_PATH
            port.retRMT_ReadReg_PhyRegNum[i].isVector
                = port.retRMT_ReadReg_LogRegNum[i].isVector;
`endif
            // Retirement RMT is used for recovery, thus it does not require a
            // bypass logic.
        end
    end
    
    // - Initialization logic
    always_ff @( posedge port.clk ) begin
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            if (port.rstStart)
                rstWriteLogRegNum[i] <= 0;
            else
                rstWriteLogRegNum[i] <= rstWriteLogRegNum[i] + 1;
        end
    end
    
    // フリーリストには0からREG_FREE_LIST_ENTRY_NUM-1が入っているので、
    // RMTの初期値はREG_FREE_LIST_ENTRY_NUM以上の値を使う
    always_comb begin
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
`ifdef RSD_ENABLE_VECTOR_PATH
            if ( !rstWriteLogRegNum[i].isVector )
                rstWritePhyRegNum[i] =
                    rstWriteLogRegNum[i].regNum + SCALAR_FREE_LIST_ENTRY_NUM;
            else
                rstWritePhyRegNum[i] =
                    rstWriteLogRegNum[i].regNum + VECTOR_FREE_LIST_ENTRY_NUM;
`else
            rstWritePhyRegNum[i] =
                rstWriteLogRegNum[i].regNum + SCALAR_FREE_LIST_ENTRY_NUM;
`endif
        end
    end   
    
endmodule : RetirementRMT


// ---- RenameLogic/RenameLogicCommitter.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Commit/recovery logic related to a rename logic.
//


import BasicTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;


module RenameLogicCommitter(
    RenameLogicIF.RenameLogicCommitter port,
    ActiveListIF.RenameLogicCommitter activeList,
    RecoveryManagerIF.RenameLogicCommitter recovery
);
    // State machine
    typedef enum logic[1:0]
    {
        PHASE_COMMIT = 0,
        PHASE_RECOVER_0 = 1,
        PHASE_RECOVER_1 = 2
    } Phase;
    Phase phase;
    Phase nextPhase;

    ActiveListCountPath recoveryCount;
    ActiveListCountPath nextRecoveryCount;

    always_ff@( posedge port.clk ) begin
        phase <= nextPhase;
        recoveryCount <= nextRecoveryCount;
    end

    `RSD_ASSERT_CLK(port.clk, !(recovery.toRecoveryPhase && phase != PHASE_COMMIT), "");

    // State machine
    always_comb begin

        if(port.rst) begin
            nextPhase = PHASE_COMMIT;
            nextRecoveryCount = 0;
        end
        else if (recovery.toRecoveryPhase) begin
            // Trigger a recovery mode.
            nextPhase = PHASE_RECOVER_0;
            nextRecoveryCount = 0;
        end
        else if(phase == PHASE_RECOVER_0) begin
            // In the first step of recovery, count the number of ops in the active list.
            nextPhase = PHASE_RECOVER_1;
            nextRecoveryCount = activeList.recoveryEntryNum;
        end
        else if(phase == PHASE_RECOVER_1) begin
            // Release all entries in a mispredicted path, move to a normal phase.
            nextPhase = (recoveryCount == 0) ? PHASE_COMMIT : PHASE_RECOVER_1;
            nextRecoveryCount = (recoveryCount > COMMIT_WIDTH) ? recoveryCount - COMMIT_WIDTH : 0;
        end
        else begin
            nextPhase = phase;
            nextRecoveryCount = recoveryCount;
        end
    end

    //
    // Pipeline registers for released physical registers.
    //
    typedef struct packed
    {
        logic releaseReg;
        PRegNumPath phyReleasedReg;
    } ReleasedRegister;
    ReleasedRegister regReleasedReg[COMMIT_WIDTH];
    ReleasedRegister nextReleasedReg[COMMIT_WIDTH];

    always_ff@(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < COMMIT_WIDTH; i++) begin
                regReleasedReg[i] <= '0;
            end
        end
        else begin
            regReleasedReg <= nextReleasedReg;
        end
    end

    always_comb begin
        for (int i = 0; i < COMMIT_WIDTH; i++) begin
            port.releaseReg[i] = regReleasedReg[i].releaseReg;
            port.phyReleasedReg[i] = regReleasedReg[i].phyReleasedReg;
        end
    end

    //
    // Commitment/recovery
    //
    ActiveListEntry alReadData [ COMMIT_WIDTH ];
    CommitLaneCountPath releaseNum;
    CommitLaneCountPath flushNum;
    always_comb begin

        // The head and tail entres of an active list.
        alReadData = activeList.readData;

        // Update cotrol signals for the active list and the free lists in
        //  a rename logic.
        if(phase == PHASE_COMMIT) begin
            // Commit mode.
            activeList.popTailNum = 0;

            // Pop the head entries of the active list and release registers
            // to the free lists in the rename logic.
            if ( port.commit ) begin
                activeList.popHeadNum = port.commitNum;
            end
            else begin
                activeList.popHeadNum = 0;
            end

            for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
                if( port.commit && i < port.commitNum) begin
                    // A head op can commit.
                    // Release registers to the free lists.
                    nextReleasedReg[i].releaseReg = alReadData[i].writeReg;
                end
                else begin
                    // A head op cannot commit.
                    // The active list and the free lists are not updated.
                    nextReleasedReg[i].releaseReg = FALSE;
                end

                // Released registers are set from the head entry of the active list.
                nextReleasedReg[i].phyReleasedReg = alReadData[i].phyPrevDstRegNum;
            end

            recovery.inRecoveryAL = FALSE;
            flushNum = 0;
        end
        else if(phase == PHASE_RECOVER_0) begin
            activeList.popHeadNum = 0;
            activeList.popTailNum = 0;
            for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
                nextReleasedReg[i].releaseReg = FALSE;
                nextReleasedReg[i].phyReleasedReg = 0;
            end
            recovery.inRecoveryAL = TRUE;
            flushNum = 0;
        end
        else begin

            if( RECOVERY_FROM_RRMT ) begin
                releaseNum = COMMIT_WIDTH;
                if (releaseNum > recoveryCount) begin
                    releaseNum = recoveryCount;
                end
                flushNum = releaseNum;
                activeList.popHeadNum = releaseNum;
                activeList.popTailNum = 0;

                for (int i = 0; i < COMMIT_WIDTH; i++) begin
                    if (i < releaseNum) begin
                        // A head op can commit.
                        // Release registers to the free lists.
                        nextReleasedReg[i].releaseReg = alReadData[i].writeReg;
                    end
                    else begin
                        // A head op cannot commit.
                        // The active list and the free lists are not updated.
                        nextReleasedReg[i].releaseReg = FALSE;
                    end

                    // Released registers are set from the head entry of the active list.
                    nextReleasedReg[i].phyReleasedReg = alReadData[i].phyDstRegNum;
                end

                recovery.inRecoveryAL = TRUE;
            end else begin
                releaseNum = COMMIT_WIDTH;
                if (releaseNum > recoveryCount) begin
                    releaseNum = recoveryCount;
                end
                flushNum = releaseNum;
                activeList.popHeadNum = 0;
                activeList.popTailNum = releaseNum;

                for (int i = 0; i < COMMIT_WIDTH; i++) begin
                    if ( (i < releaseNum)) begin
                        // A head op can commit.
                        // Release registers to the free lists.
                        nextReleasedReg[i].releaseReg = alReadData[i].writeReg;
                    end
                    else begin
                        // A head op cannot commit.
                        // The active list and the free lists are not updated.
                        nextReleasedReg[i].releaseReg = FALSE;
                    end

                    // Released registers are set from the tail entry of the active list.
                    nextReleasedReg[i].phyReleasedReg = alReadData[i].phyDstRegNum;
                end

                recovery.inRecoveryAL = TRUE;
            end
        end

        port.flushNum = flushNum;
    end



endmodule
// ---- Decoder/Decoder.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Micro op decoder
//


import BasicTypes::*;
import MicroOpTypes::*;
import OpFormatTypes::*;


function automatic void EmitInvalidOp(
    output OpInfo op
);
    op = '0;
    op.valid = FALSE;
endfunction


//
// Modify micro op information.
//

function automatic OpInfo ModifyMicroOp(
    input OpInfo src,
    input MicroOpIndex mid,
    input logic split,
    input logic last
);
    OpInfo op;
    op = src;
    op.mid = mid;
    op.split = split;
    op.last = last;
    return op;
endfunction


//
//  RISCV Instruction Decoder
//


//
// --- 即値整数演算, シフト含む
//
function automatic void RISCV_EmitOpImm(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf,
    input LScalarRegNumPath srcRegNumA,
    input LScalarRegNumPath srcRegNumB,
    input LScalarRegNumPath dstRegNum,
    input logic unsupported
);
    RISCV_ISF_I isfI;
    RISCV_ISF_R isfR;
    OpFunct3 opFunct3;
    ShiftFunct7 shiftFunct7;
    RISCV_IntOperandImmShift intOperandImmShift;
    logic isShift;

    IntALU_Code aluCode;

    isfI = isf;
    isfR = isf;
    opFunct3 = OpFunct3'(isfR.funct3);
    shiftFunct7 = ShiftFunct7'(isfR.funct7);
    isShift = ( ( opFunct3 == OP_FUNCT3_SLL ) || ( opFunct3 == OP_FUNCT3_SRL_SRA ) );


    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.intOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.intOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.intOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.intOp.dstRegNum.regNum  = dstRegNum;
    opInfo.operand.intOp.srcRegNumA.regNum = srcRegNumA;
    opInfo.operand.intOp.srcRegNumB.regNum = srcRegNumB;

    // 即値
    opInfo.operand.intOp.shiftType = SOT_IMM_SHIFT ;

    intOperandImmShift.shift        =  isShift ? isfR.rs2 : '0;
    intOperandImmShift.shiftType    =  ( opFunct3 == OP_FUNCT3_SLL ) ? ST_LSL :
                                    ( ( opFunct3 == OP_FUNCT3_SRL_SRA ) && ( shiftFunct7 == SHIFT_FUNCT7_SRL ) ) ? ST_LSR :
                                    ( ( opFunct3 == OP_FUNCT3_SRL_SRA ) && ( shiftFunct7 == SHIFT_FUNCT7_SRA ) ) ? ST_ASR :
                                    ST_ROR;
    intOperandImmShift.isRegShift   = FALSE;
    intOperandImmShift.imm          = isShift ? ShamtExtention( isfR ) : I_TypeImmExtention( isfI );
    intOperandImmShift.immType      = RISCV_IMM_I;

    opInfo.operand.intOp.shiftIn   = intOperandImmShift;


    // ALU
    RISCV_DecodeOpImmFunct3( aluCode, opFunct3 );
    opInfo.operand.intOp.aluCode = aluCode;

    // レジスタ書き込みを行うかどうか
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = ( dstRegNum != ZERO_REGISTER ) ? TRUE : FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_REG;
    opInfo.opTypeB = OOT_IMM;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_INT;
    opInfo.mopSubType.intType = isShift ? INT_MOP_TYPE_SHIFT : INT_MOP_TYPE_ALU;

    // 条件コード
    opInfo.cond = COND_AL;

    // 未定義命令
    opInfo.unsupported = unsupported;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeOpImm(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo intOp;
    OpInfo shiftOp;
    OpInfo rijOp;
    OpInfo selectOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitOpImm(
        .opInfo( intOp ),
        .isf( isf ),
        .srcRegNumA( isf.rs1 ),
        .srcRegNumB( 0 ),
        .dstRegNum( isf.rd ),
        .unsupported( FALSE )
    );

    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(intOp, mid, FALSE, TRUE);
    mid += 1;

    insnInfo.writePC = FALSE;
    insnInfo.isCall = FALSE;
    insnInfo.isReturn = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = FALSE;

endfunction


//
// --- レジスタ整数演算, シフト含む
//
function automatic void RISCV_EmitOp(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf,
    input LScalarRegNumPath srcRegNumA,
    input LScalarRegNumPath srcRegNumB,
    input LScalarRegNumPath dstRegNum,
    input logic unsupported
);
    RISCV_ISF_R isfR;
    OpFunct3 opFunct3;
    OpFunct7 opFunct7;
    ShiftFunct7 shiftFunct7;
    RISCV_IntOperandImmShift intOperandImmShift;
    logic isShift;

    IntALU_Code aluCode;

    isfR = isf;
    opFunct3 = OpFunct3'(isfR.funct3);
    opFunct7 = OpFunct7'(isfR.funct7);
    shiftFunct7 = ShiftFunct7'(isfR.funct7);
    isShift = ( ( opFunct3 == OP_FUNCT3_SLL ) || ( opFunct3 == OP_FUNCT3_SRL_SRA ) );

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.intOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.intOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.intOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.intOp.dstRegNum.regNum  = dstRegNum;
    opInfo.operand.intOp.srcRegNumA.regNum = srcRegNumA;
    opInfo.operand.intOp.srcRegNumB.regNum = srcRegNumB;

    // 即値
    opInfo.operand.intOp.shiftType = SOT_REG_SHIFT ;

    intOperandImmShift.shift        =  isShift ? isfR.rs2 : '0;
    intOperandImmShift.shiftType    =  ( opFunct3 == OP_FUNCT3_SLL ) ? ST_LSL :
                                    ( ( opFunct3 == OP_FUNCT3_SRL_SRA ) && ( shiftFunct7 == SHIFT_FUNCT7_SRL ) ) ? ST_LSR :
                                    ( ( opFunct3 == OP_FUNCT3_SRL_SRA ) && ( shiftFunct7 == SHIFT_FUNCT7_SRA ) ) ? ST_ASR :
                                    ST_ROR;
    intOperandImmShift.isRegShift   = TRUE;
    intOperandImmShift.imm          = '0;
    intOperandImmShift.immType      = RISCV_IMM_R;

    opInfo.operand.intOp.shiftIn   = intOperandImmShift;


    // ALU
    //RISCV_DecodeOpFunct3( isfR.funct3, isfR.funct7, opInfo.operand.intOp.aluCode);
    RISCV_DecodeOpFunct3( aluCode, opFunct3, opFunct7 );
    opInfo.operand.intOp.aluCode = aluCode;

    // レジスタ書き込みを行うかどうか
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = ( dstRegNum != ZERO_REGISTER ) ? TRUE : FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_REG;
    opInfo.opTypeB = OOT_REG;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_INT;
    opInfo.mopSubType.intType = isShift ? INT_MOP_TYPE_SHIFT : INT_MOP_TYPE_ALU;

    // 条件コード
    opInfo.cond = COND_AL;

    // 未定義命令
    opInfo.unsupported = unsupported;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeOp(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo intOp;
    OpInfo shiftOp;
    OpInfo rijOp;
    OpInfo selectOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitOp(
        .opInfo( intOp ),
        .isf( isf ),
        .srcRegNumA( isf.rs1 ),
        .srcRegNumB( isf.rs2 ),
        .dstRegNum( isf.rd ),
        .unsupported( FALSE )
    );

    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(intOp, mid, FALSE, TRUE);
    mid += 1;

    insnInfo.writePC = FALSE;
    insnInfo.isCall = FALSE;
    insnInfo.isReturn = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = FALSE;

endfunction


//
// --- RISCV LUI, AUIPC
//
function automatic void RISCV_EmitUTypeInst(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf,
    input LScalarRegNumPath srcRegNumA,
    input LScalarRegNumPath srcRegNumB,
    input LScalarRegNumPath dstRegNum,
    input logic unsupported
);
    RISCV_ISF_U isfU;
    RISCV_IntOperandImmShift intOperandImmShift;

    isfU = isf;

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.intOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.intOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.intOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.intOp.dstRegNum.regNum  = dstRegNum;
    opInfo.operand.intOp.srcRegNumA.regNum = srcRegNumA;
    opInfo.operand.intOp.srcRegNumB.regNum = srcRegNumB;

    // 即値
    opInfo.operand.intOp.shiftType = SOT_REG_SHIFT ;

    intOperandImmShift.shift        = '0;
    intOperandImmShift.shiftType    = ST_ROR;
    intOperandImmShift.isRegShift   = TRUE;
    intOperandImmShift.imm          = isfU.imm;
    intOperandImmShift.immType      = RISCV_IMM_U;

    opInfo.operand.intOp.shiftIn   = intOperandImmShift;


    // ALU
    opInfo.operand.intOp.aluCode = AC_ADD;

    // レジスタ書き込みを行うかどうか
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = ( dstRegNum != ZERO_REGISTER ) ? TRUE : FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = isf.opCode == RISCV_AUIPC ? OOT_PC : OOT_REG;
    opInfo.opTypeB = OOT_IMM;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_INT;
    opInfo.mopSubType.intType = INT_MOP_TYPE_ALU;

    // 条件コード
    opInfo.cond = COND_AL;

    // 未定義命令
    opInfo.unsupported = unsupported;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeUTypeInst(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo intOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitUTypeInst(
        .opInfo( intOp ),
        .isf( isf ),
        .srcRegNumA( 0 ),
        .srcRegNumB( 0 ),
        .dstRegNum( isf.rd ),
        .unsupported( FALSE )
    );

    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(intOp, mid, FALSE, TRUE);
    mid += 1;

    insnInfo.writePC = FALSE;
    insnInfo.isCall = FALSE;
    insnInfo.isReturn = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = FALSE;

endfunction


//
// --- RISCV JAL
//
function automatic void RISCV_EmitJAL(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf
);
    RISCV_ISF_U isfU;
    isfU = isf;

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.brOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.brOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.brOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.brOp.dstRegNum.regNum  = isfU.rd;
    opInfo.operand.brOp.srcRegNumA.regNum = '0;
    opInfo.operand.brOp.srcRegNumB.regNum = '0;

    // レジスタ書き込みを行うかどうか
    // 比較系の命令はレジスタに書き込みを行わない
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = ( isfU.rd != ZERO_REGISTER ) ? TRUE : FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_PC;
    opInfo.opTypeB = OOT_IMM;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_INT;
    opInfo.mopSubType.intType = INT_MOP_TYPE_BR;

    // 条件コード
    opInfo.cond = COND_AL;

    // 分岐ターゲット
    opInfo.operand.brOp.brDisp = GetJAL_Target( isf );
    opInfo.operand.brOp.padding = 0;

    // 未定義命令
    opInfo.unsupported = FALSE;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeJAL(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo brOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitJAL(
        .opInfo( brOp ),
        .isf( isf )
    );

    // Initizalize
    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(brOp, mid, FALSE, TRUE);

    insnInfo.writePC = TRUE;
    insnInfo.isCall = ( brOp.writeReg && ( brOp.operand.brOp.dstRegNum.regNum == LINK_REGISTER ) ) ? TRUE : FALSE;
    insnInfo.isReturn = FALSE;
    insnInfo.isRelBranch = TRUE;
    insnInfo.isSerialized = FALSE;

endfunction


//
// --- RISCV Decode JALR
//
function automatic void RISCV_EmitJALR(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf
);

    RISCV_ISF_I isfI;
    isfI = isf;

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.brOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.brOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.brOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.brOp.dstRegNum.regNum  = isfI.rd;
    opInfo.operand.brOp.srcRegNumA.regNum = isfI.rs1;
    opInfo.operand.brOp.srcRegNumB.regNum = 0;

    // レジスタ書き込みを行うかどうか
    // 比較系の命令はレジスタに書き込みを行わない
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = ( isfI.rd != ZERO_REGISTER ) ? TRUE : FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_REG;
    opInfo.opTypeB = OOT_IMM;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_INT;
    opInfo.mopSubType.intType = INT_MOP_TYPE_RIJ;

    // 条件コード
    opInfo.cond = COND_AL;

    // 分岐ターゲット
    opInfo.operand.brOp.brDisp = GetJALR_Target( isfI );
    opInfo.operand.brOp.padding = '0;

    // 未定義命令
    opInfo.unsupported = FALSE;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeJALR(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo brOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitJALR(
        .opInfo( brOp ),
        .isf( isf )
    );

    // Initizalize
    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(brOp, mid, FALSE, TRUE);

    insnInfo.writePC = TRUE;
    insnInfo.isCall = ( brOp.writeReg && ( brOp.operand.brOp.dstRegNum.regNum == LINK_REGISTER ) ) ? TRUE : FALSE;
    insnInfo.isReturn = ( ( brOp.operand.brOp.srcRegNumA.regNum == LINK_REGISTER )
                        && ( brOp.operand.brOp.dstRegNum.regNum == ZERO_REGISTER ) ) ? TRUE : FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = FALSE;

endfunction


//
// --- RISCV BRANCH
//
function automatic void RISCV_EmitBranch(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf
);
    RISCV_ISF_R isfR;
    BrFunct3 brFunct3;
    CondCode condCode;

    isfR = isf;
    brFunct3 = BrFunct3'(isfR.funct3);

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.brOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.brOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.brOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.brOp.dstRegNum.regNum  = 0;
    opInfo.operand.brOp.srcRegNumA.regNum = isfR.rs1;
    opInfo.operand.brOp.srcRegNumB.regNum = isfR.rs2;

    // レジスタ書き込みを行うかどうか
    // 比較系の命令はレジスタに書き込みを行わない
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_REG;
    opInfo.opTypeB = OOT_REG;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_INT;
    opInfo.mopSubType.intType = INT_MOP_TYPE_BR;

    // 条件コード
    //RISCV_DecodeBrFunct3(isfR.funct3, opInfo.cond);
    RISCV_DecodeBrFunct3( condCode, brFunct3 );
    opInfo.cond = condCode;

    // 分岐ターゲット
    opInfo.operand.brOp.brDisp = GetBranchDisplacement( isfR );
    opInfo.operand.brOp.padding = '0;

    // 未定義命令
    opInfo.unsupported = FALSE;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeBranch(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo brOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitBranch(
        .opInfo( brOp ),
        .isf( isf )
    );

    // Initizalize
    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(brOp, mid, FALSE, TRUE);

    insnInfo.writePC    = TRUE;
    insnInfo.isCall     = FALSE;
    insnInfo.isReturn   = FALSE;
    insnInfo.isRelBranch = TRUE;
    insnInfo.isSerialized = FALSE;

endfunction

//
// --- EISCV MEMORY OP
//
function automatic void RISCV_EmitMemOp(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf
);
    RISCV_ISF_S isfS;
    RISCV_ISF_I isfI;
    MemFunct3 memFunct3;
    logic isLoad;

    MemAccessMode memAccessMode;

    isfS = isf;
    isfI = isf;
    memFunct3 = MemFunct3'(isfS.funct3);
    isLoad = ( isfI.opCode == RISCV_LD );

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.memOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.memOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.memOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.memOp.dstRegNum.regNum  = isLoad ? isfI.rd : '0;
    opInfo.operand.memOp.srcRegNumA.regNum = isfI.rs1;
    opInfo.operand.memOp.srcRegNumB.regNum = isLoad ? '0 : isfS.rs2;
    opInfo.operand.memOp.csrCtrl = '0; // unused
    opInfo.operand.memOp.padding = '0;

    // レジスタ書き込みを行うかどうか
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = ( isfI.rd != ZERO_REGISTER ) & isLoad;

    // 論理レジスタを読むかどうか
    // ストア時はBを読む
    opInfo.opTypeA = OOT_REG;
    opInfo.opTypeB = isLoad ? OOT_IMM : OOT_REG;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_MEM;
    opInfo.mopSubType.memType = isLoad ? MEM_MOP_TYPE_LOAD : MEM_MOP_TYPE_STORE;

    // 条件コード
    opInfo.cond = COND_AL;

    // アドレッシング
    opInfo.operand.memOp.addrIn    = isLoad ? isfI.imm : {isfS.imm2, isfS.imm1};
    opInfo.operand.memOp.isAddAddr = TRUE;
    opInfo.operand.memOp.isRegAddr = TRUE;
    RISCV_DecodeMemAccessMode( memAccessMode, memFunct3 );
    opInfo.operand.memOp.memAccessMode = memAccessMode;

    opInfo.valid = TRUE;

    opInfo.unsupported = FALSE;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;
endfunction

function automatic void RISCV_DecodeMemOp(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo memOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitMemOp(
        .opInfo( memOp ),
        .isf( isf )
    );

    // Initizalize
    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(memOp, mid, FALSE, TRUE);

    insnInfo.writePC    = FALSE;
    insnInfo.isCall     = FALSE;
    insnInfo.isReturn   = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = FALSE;

endfunction


//
// --- Complex Op (RISC-VではRV32M)
//
function automatic void RISCV_EmitComplexOp(
    output OpInfo  opInfo, 
    input RISCV_ISF_Common isf,
    input LScalarRegNumPath srcRegNumA,
    input LScalarRegNumPath srcRegNumB,
    input LScalarRegNumPath dstRegNum,
    input logic unsupported
);
    RISCV_ISF_R isfR;
    OpFunct3 opFunct3;
    OpFunct7 opFunct7;
    RV32MFunct3 rv32mFunct3;
    RV32MFunct7 rv32mFunct7;
    logic isMul;

    IntMUL_Code mulCode;
    IntDIV_Code divCode;

    isfR = isf;
    opFunct3 = OpFunct3'(isfR.funct3);
    opFunct7 = OpFunct7'(isfR.funct7);
    rv32mFunct3 = RV32MFunct3'(isfR.funct3);
    rv32mFunct7 = RV32MFunct7'(isfR.funct7);
    isMul = ( rv32mFunct3 < RV32M_FUNCT3_DIV );

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    opInfo.operand.complexOp.dstRegNum.isVector  = FALSE;
    opInfo.operand.complexOp.srcRegNumA.isVector = FALSE;
    opInfo.operand.complexOp.srcRegNumB.isVector = FALSE;
`endif
    opInfo.operand.complexOp.dstRegNum.regNum  = dstRegNum;
    opInfo.operand.complexOp.srcRegNumA.regNum = srcRegNumA;
    opInfo.operand.complexOp.srcRegNumB.regNum = srcRegNumB;
    
    // 乗算の有効な結果の位置
    opInfo.operand.complexOp.mulGetUpper = ( rv32mFunct3 > RV32M_FUNCT3_MUL) ;

    // ALU
    RISCV_DecodeComplexOpFunct3( mulCode, divCode, rv32mFunct3 );
    opInfo.operand.complexOp.mulCode = mulCode;
    opInfo.operand.complexOp.divCode = divCode;
    opInfo.operand.complexOp.padding = '0;
    opInfo.operand.complexOp.riscv_padding = '0;

    // レジスタ書き込みを行うかどうか
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする   
    opInfo.writeReg  = ( dstRegNum != ZERO_REGISTER ) ? TRUE : FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_REG;
    opInfo.opTypeB = OOT_REG;

    // 命令の種類
`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    // Mem pipe で処理
    opInfo.mopType = MOP_TYPE_MEM;
    opInfo.mopSubType.memType = isMul ? MEM_MOP_TYPE_MUL : MEM_MOP_TYPE_DIV;
`else
    // 剰余は除算と演算器を共有するためCOMPLEX_MOP_TYPE_DIVとする
    opInfo.mopType = MOP_TYPE_COMPLEX;
    opInfo.mopSubType.complexType = isMul ? COMPLEX_MOP_TYPE_MUL : COMPLEX_MOP_TYPE_DIV;
`endif

    // 条件コード
    opInfo.cond = COND_AL;

    // 未定義命令
    opInfo.unsupported = unsupported;
    opInfo.undefined = FALSE;

    // Serialized
    opInfo.serialized = FALSE;

    // Control
    opInfo.valid = TRUE;    // Valid outputs
endfunction

function automatic void RISCV_DecodeComplexOp( 
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo complexOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitComplexOp(
        .opInfo( complexOp ),
        .isf( isf ),
        .srcRegNumA( isf.rs1 ),
        .srcRegNumB( isf.rs2 ),
        .dstRegNum( isf.rd ),
        .unsupported( FALSE )
    );

    mid = 0;
    for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(complexOp, mid, FALSE, TRUE);
    mid += 1;

    insnInfo.writePC = FALSE;
    insnInfo.isCall = FALSE;
    insnInfo.isReturn = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = FALSE;

endfunction

//
// --- Misc-Mem
//
function automatic void RISCV_EmitMiscMemOp(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf
);
    RISCV_ISF_MISC_MEM isfMiscMem;
    MiscMemFunct3 opFunct3;
    MiscMemMicroOpOperand miscMemOp;

    isfMiscMem = isf;
    opFunct3 = MiscMemFunct3'(isfMiscMem.funct3);

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    miscMemOp.dstRegNum.isVector  = FALSE;
    miscMemOp.srcRegNumA.isVector = FALSE;
    miscMemOp.srcRegNumB.isVector = FALSE;
`endif
    miscMemOp.dstRegNum.regNum  = '0;
    miscMemOp.srcRegNumA.regNum = '0;
    miscMemOp.srcRegNumB.regNum = '0;
    miscMemOp.padding = '0;
    miscMemOp.riscv_padding = '0;

    if (opFunct3 == MISC_MEM_FUNCT3_FENCE || 
        opFunct3 == MISC_MEM_FUNCT3_FENCE_I
    ) begin
        miscMemOp.fence = TRUE;
    end 
    else begin
        miscMemOp.fence = FALSE;
    end

    opInfo.operand.miscMemOp = miscMemOp;

    // レジスタ書き込みを行うかどうか
    // FENCE/FENCE.I Does not write any registers 
    opInfo.writeReg  = FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_IMM;
    opInfo.opTypeB = OOT_IMM;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_MEM;
    opInfo.mopSubType.memType = MEM_MOP_TYPE_FENCE;

    // 条件コード
    opInfo.cond = COND_AL;


    opInfo.valid = TRUE;

    opInfo.unsupported = FALSE;
    if (miscMemOp.fence) begin
        opInfo.undefined = FALSE;
    end
    else begin
        // Unknown misc mem
        opInfo.undefined = TRUE;
    end

    // Serialized
    opInfo.serialized = TRUE;
endfunction

function automatic void RISCV_DecodeMiscMem(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo miscMemOp;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    RISCV_EmitMiscMemOp(
        .opInfo(miscMemOp),
        .isf(isf)
    );

    // Initizalize
    mid = 0;
    for (int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(miscMemOp, mid, FALSE, TRUE);

    insnInfo.writePC    = FALSE;
    insnInfo.isCall     = FALSE;
    insnInfo.isReturn   = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = TRUE;

endfunction


//
// --- System
//
function automatic void RISCV_EmitCSR_Op(
    output OpInfo opInfo,
    input RISCV_ISF_Common isf
);
    RISCV_ISF_SYSTEM isfSystem;
    SystemFunct3 opFunct3;
    MemMicroOpOperand memOp;    // Decoded as a memory op

    isfSystem = isf;
    opFunct3 = SystemFunct3'(isfSystem.funct3);

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    memOp.dstRegNum.isVector  = FALSE;
    memOp.srcRegNumA.isVector = FALSE;
    memOp.srcRegNumB.isVector = FALSE;
`endif
    memOp.dstRegNum.regNum  = isfSystem.rd;
    memOp.srcRegNumA.regNum = isfSystem.rs1;
    memOp.srcRegNumB.regNum = '0;
    memOp.padding = '0;

    // Don't care
    memOp.isAddAddr = FALSE;
    memOp.isRegAddr = FALSE;
    memOp.memAccessMode = '0;

    // コードの設定
    unique case (opFunct3)
        default: begin  // SYSTEM_FUNCT3_PRIV or unknown
            memOp.csrCtrl.code = CSR_WRITE;
        end
        SYSTEM_FUNCT3_CSR_RW, SYSTEM_FUNCT3_CSR_RW_I: begin
            memOp.csrCtrl.code = CSR_WRITE;
        end
        SYSTEM_FUNCT3_CSR_RS, SYSTEM_FUNCT3_CSR_RS_I: begin
            memOp.csrCtrl.code = CSR_SET;
        end
        SYSTEM_FUNCT3_CSR_RC, SYSTEM_FUNCT3_CSR_RC_I: begin
            memOp.csrCtrl.code = CSR_CLEAR;
        end
    endcase

    // CSR number
    memOp.addrIn = isfSystem.funct12;

    // CSR 命令の即値だけは特殊なので REG にしておき，ユニット側で対処する
    memOp.csrCtrl.isImm = 
        (opFunct3 inside {
            SYSTEM_FUNCT3_CSR_RW, 
            SYSTEM_FUNCT3_CSR_RS, 
            SYSTEM_FUNCT3_CSR_RC
        }) ? FALSE : TRUE;
    memOp.csrCtrl.imm = isfSystem.rs1;   // rs1 がちょうど即値になる

    opInfo.operand.memOp = memOp;

    // レジスタ書き込みを行うかどうか
    // CSR 系は基本全て書き込む
    // ゼロレジスタへの書き込みは書き込みフラグをFALSEとする
    opInfo.writeReg  = (isfSystem.rd != ZERO_REGISTER) ? TRUE : FALSE;


    // 論理レジスタを読むかどうか
    // CSR 命令の即値だけは特殊なので REG にしておき，ユニット側で対処する
    opInfo.opTypeA = OOT_REG;  
    opInfo.opTypeB = OOT_IMM;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_MEM;
    opInfo.mopSubType.memType = MEM_MOP_TYPE_CSR;

    // 条件コード
    opInfo.cond = COND_AL;

    opInfo.valid = TRUE;

    opInfo.unsupported = FALSE;
    opInfo.undefined = 
        opFunct3 == SYSTEM_FUNCT3_UNDEFINED ? TRUE : FALSE;

    // Serialized
    opInfo.serialized = TRUE;
endfunction


function automatic void RISCV_EmitSystemOp(
    output OpInfo  opInfo,
    input RISCV_ISF_Common isf
);
    RISCV_ISF_SYSTEM isfSystem;
    SystemFunct3  opFunct3;
    SystemFunct12 opFunct12;
    SystemMicroOpOperand systemOp;
    logic undefined;

    isfSystem = isf;
    opFunct3 = SystemFunct3'(isfSystem.funct3);
    opFunct12 = SystemFunct12'(isfSystem.funct12);

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    systemOp.dstRegNum.isVector  = FALSE;
    systemOp.srcRegNumA.isVector = FALSE;
    systemOp.srcRegNumB.isVector = FALSE;
`endif
    systemOp.dstRegNum.regNum  = '0;
    systemOp.srcRegNumA.regNum = '0;
    systemOp.srcRegNumB.regNum = '0;
    systemOp.isEnv = TRUE;
    systemOp.padding = '0;
    systemOp.imm = '0;

    undefined = FALSE;

    // コードの設定
    if (opFunct12 == SYSTEM_FUNCT12_WFI) begin
        // NOP 扱いにしておく
        opInfo.mopType = MOP_TYPE_INT;
        opInfo.mopSubType.intType = INT_MOP_TYPE_ALU;
    end
    else begin
        unique case(SystemFunct12'(isfSystem.funct12))
            SYSTEM_FUNCT12_ECALL:  systemOp.envCode = ENV_CALL;
            SYSTEM_FUNCT12_EBREAK: systemOp.envCode = ENV_BREAK;
            SYSTEM_FUNCT12_MRET:   systemOp.envCode = ENV_MRET;
            default: begin// Unknown
                systemOp.envCode = ENV_BREAK;            
                undefined = TRUE;
            end
        endcase

        // 命令の種類
        opInfo.mopType = MOP_TYPE_MEM;
        opInfo.mopSubType.memType = MEM_MOP_TYPE_ENV;
    end

    opInfo.operand.systemOp = systemOp;

    // レジスタ書き込みを行うかどうか
    opInfo.writeReg  = FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_IMM;
    opInfo.opTypeB = OOT_IMM;


    // 条件コード
    opInfo.cond = COND_AL;

    opInfo.valid = TRUE;

    opInfo.unsupported = FALSE;
    opInfo.undefined = undefined;

    // Serialized
    opInfo.serialized = TRUE;
endfunction


function automatic void RISCV_DecodeSystem(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf
);
    OpInfo opInfo;
    MicroOpIndex mid;

    //RISCVでは複数micro opへの分割は基本的に必要ないはず

    if (SystemFunct3'(isf.funct3) == SYSTEM_FUNCT3_PRIV) begin
        RISCV_EmitSystemOp(.opInfo(opInfo), .isf(isf));
    end
    else begin 
        RISCV_EmitCSR_Op(.opInfo(opInfo), .isf(isf));
    end

    // Initizalize
    mid = 0;
    for (int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(opInfo, mid, FALSE, TRUE);

    insnInfo.writePC    = FALSE;
    insnInfo.isCall     = FALSE;
    insnInfo.isReturn   = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = TRUE;   // A system instruction must be serialized

endfunction


function automatic void RISCV_EmitIllegalOp(
    output OpInfo opInfo,
    input logic illegalPC
);
    RISCV_ISF_SYSTEM isfSystem;
    SystemFunct3  opFunct3;
    SystemFunct12 opFunct12;
    SystemMicroOpOperand systemOp;
    logic undefined;

    // 論理レジスタ番号
`ifdef RSD_ENABLE_VECTOR_PATH
    systemOp.dstRegNum.isVector  = FALSE;
    systemOp.srcRegNumA.isVector = FALSE;
    systemOp.srcRegNumB.isVector = FALSE;
`endif
    systemOp.dstRegNum.regNum  = '0;
    systemOp.srcRegNumA.regNum = '0;
    systemOp.srcRegNumB.regNum = '0;
    systemOp.isEnv = TRUE;
    systemOp.padding = '0;
    systemOp.imm = '0;

    undefined = FALSE;

    // コードの設定
    systemOp.envCode = illegalPC ? ENV_INSN_VIOLATION : ENV_INSN_ILLEGAL;

    // 命令の種類
    opInfo.mopType = MOP_TYPE_MEM;
    opInfo.mopSubType.memType = MEM_MOP_TYPE_ENV;

    opInfo.operand.systemOp = systemOp;

    // レジスタ書き込みを行うかどうか
    opInfo.writeReg  = FALSE;

    // 論理レジスタを読むかどうか
    opInfo.opTypeA = OOT_IMM;
    opInfo.opTypeB = OOT_IMM;

    // 条件コード
    opInfo.cond = COND_AL;
    opInfo.valid = TRUE;
    opInfo.unsupported = FALSE;
    opInfo.undefined = undefined;

    // Serialized
    opInfo.serialized = TRUE;
endfunction

function automatic void RISCV_DecodeIllegal(
    output OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,
    output InsnInfo insnInfo,
    input RISCV_ISF_Common isf,
    input illegalPC
);
    OpInfo opInfo;
    MicroOpIndex mid;

    RISCV_EmitIllegalOp(opInfo, illegalPC);

    // Initizalize
    mid = 0;
    for (int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
        EmitInvalidOp(microOps[i]);
    end

    // --- 1
    // It begins at 1 for aligning outputs to DecodeIntReg.
    microOps[1] = ModifyMicroOp(opInfo, mid, FALSE, TRUE);

    insnInfo.writePC    = FALSE;
    insnInfo.isCall     = FALSE;
    insnInfo.isReturn   = FALSE;
    insnInfo.isRelBranch = FALSE;
    insnInfo.isSerialized = TRUE;   // A system instruction must be serialized

endfunction
//
// --- DecodeStageでインスタンシエートされるモジュール
//
module Decoder(
input
    InsnPath insn,      // Input instruction
    logic illegalPC,
output
    OpInfo [MICRO_OP_MAX_NUM-1:0] microOps,  // Outputed micro ops
    InsnInfo insnInfo  // Whether this instruction is branch or not.
);
    RISCV_ISF_Common isf;
    RV32MFunct7 rv32mFunct7;
    logic undefined;
    
    always_comb begin
        isf  = insn;
        rv32mFunct7 = RV32MFunct7'(isf.funct7);
        
        insnInfo.writePC = FALSE;
        insnInfo.isCall = FALSE;
        insnInfo.isReturn = FALSE;
        insnInfo.isRelBranch = FALSE;
        insnInfo.isSerialized = FALSE;

        case (isf.opCode)

            // S: LOAD, STORE
            RISCV_LD, RISCV_ST : begin
                RISCV_DecodeMemOp(microOps, insnInfo, insn);
            end

            // B: BRANCH
            RISCV_BR : begin
                RISCV_DecodeBranch(microOps, insnInfo, insn);
            end
            // I: JALR
            RISCV_JALR : begin
                RISCV_DecodeJALR(microOps, insnInfo, insn);
            end
            // J: JAL
            RISCV_JAL : begin
                RISCV_DecodeJAL(microOps, insnInfo, insn);
            end

            // I: OP-IMM
            RISCV_OP_IMM : begin
                RISCV_DecodeOpImm(microOps, insnInfo, insn);
            end

            // R: OP
            RISCV_OP : begin
                if (rv32mFunct7 == RV32M_FUNCT7_ALL) begin
                    RISCV_DecodeComplexOp(microOps, insnInfo, insn);
                end
                else begin
                    RISCV_DecodeOp(microOps, insnInfo, insn);
                end
            end

            // U: AUIPC, LUI
            RISCV_AUIPC, RISCV_LUI : begin
                RISCV_DecodeUTypeInst(microOps, insnInfo, insn);
            end

            // I: MISC-MEM (fence/fence.i)
            RISCV_MISC_MEM : begin
                RISCV_DecodeMiscMem(microOps, insnInfo, insn);
            end

            // I: SYSTEM (ebreak/ecall/csr)
            RISCV_SYSTEM : begin
                RISCV_DecodeSystem(microOps, insnInfo, insn);
            end

            default : begin
                RISCV_DecodeIllegal(microOps, insnInfo, insn, illegalPC);
            end
        endcase

        undefined = FALSE;
        for(int i = 0; i < MICRO_OP_MAX_NUM; i++) begin
            if(microOps[i].undefined || microOps[i].unsupported) begin
                undefined = TRUE;
            end
        end

        if (undefined || illegalPC) begin
            RISCV_DecodeIllegal(microOps, insnInfo, insn, illegalPC);
        end

    end



endmodule : Decoder



// ---- Decoder/DecodedBranchResolver.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Resolve branch misprediction on the decode stage.
// This unit includes a simple return address stack.
//

import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import PipelineTypes::*;
import DebugTypes::*;
import FetchUnitTypes::*;

module DecodedBranchResolver(
input
    logic clk, rst, stall, decodeComplete,
    logic insnValidIn[DECODE_WIDTH],
    RISCV_ISF_Common [DECODE_WIDTH-1 : 0] isf,      // Unpacked array of structure corrupts in Modelsim.
    BranchPred [DECODE_WIDTH-1 : 0] brPredIn,
    PC_Path pc[DECODE_WIDTH],
    InsnInfo [DECODE_WIDTH-1 : 0] insnInfo,
output 
    logic insnValidOut[DECODE_WIDTH],
    logic insnFlushed[DECODE_WIDTH],
    logic flush,
    BranchPred brPredOut[DECODE_WIDTH],
    PC_Path recoveredPC
);
    // Return address stack.
    parameter RAS_ENTRY_NUM = 4;
    typedef logic [$clog2(RAS_ENTRY_NUM)-1 : 0] RAS_IndexPath;
    PC_Path ras[RAS_ENTRY_NUM];
    PC_Path nextRAS;
    logic pushRAS;
    logic popRAS;
    RAS_IndexPath rasPtr;
    RAS_IndexPath nextRAS_Ptr;

    always_ff@(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < RAS_ENTRY_NUM; i++) begin
                ras[i] <= '0;
            end
            rasPtr <= '0;
        end
        else if (!stall && decodeComplete) begin
            // 全 micro op のデコード完了時にだけ RAS を更新するようにしないと，
            // 次のステージに送り込んだ micro op のターゲットと，ここから
            // 出しているターゲットアドレスがずれて（ras の ptr が更新されるから）
            // 正しく動かなくなる
            if (pushRAS) begin
                ras[nextRAS_Ptr] <= nextRAS;
            end
            rasPtr <= nextRAS_Ptr;
        end
        // if (pushRAS) begin
        //     $display("Call(%d) flush @%x old:%p new:%p", nextRAS_Ptr, pc[addrCheckLane], brPredIn[addrCheckLane].predAddr, decodedPC[addrCheckLane]);
        // end 
        // else if (popRAS) begin
        //     $display("Ret(%d)  @%x old:%p new:%p", rasPtr, pc[addrCheckLane], brPredIn[addrCheckLane].predAddr, decodedPC[addrCheckLane]);
        // end
        // if (flush) begin
        //     $display("flush @%x old:%p new:%p", pc[addrCheckLane], brPredIn[addrCheckLane].predAddr, decodedPC[addrCheckLane]);
        // end
    end

    
    PC_Path decodedPC[DECODE_WIDTH];
    PC_Path nextPC[DECODE_WIDTH];
    RISCV_ISF_U isfU[DECODE_WIDTH];

    logic addrCheck;
    logic addrIncorrect;
    DecodeLaneIndexPath addrCheckLane;
    typedef enum logic [1:0] 
    {
        BTT_NEXT = 0,       // nextPC 
        BTT_PC_RELATIVE = 1,         // BRANCH, JAL
        BTT_INDIRECT_JUMP  = 2,       // JALR

        // This insn is serialized, so the succeding insns are flushed
        BTT_SERIALIZED  = 3 
    } BranchTargetType;
    BranchTargetType brTargetType[DECODE_WIDTH];
    logic addrMismatch[DECODE_WIDTH];

    always_comb begin
        
        // Initialize
        flush = FALSE;
        recoveredPC = '0;

        pushRAS = FALSE;
        popRAS = FALSE;
        nextRAS = 0;
        nextRAS_Ptr = rasPtr;
        
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            insnValidOut[i] = insnValidIn[i];
            insnFlushed[i] = FALSE;
            brPredOut[i] = brPredIn[i];
            isfU[i] = isf[i];
        end

        addrCheck = FALSE;
        addrIncorrect = FALSE;
        addrCheckLane = '0;
        
        // Determine the type of branch
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            
            if (insnInfo[i].isRelBranch) begin
                // Normal branch.
                brTargetType[i] = BTT_PC_RELATIVE;
            end
            else if (insnInfo[i].writePC) begin
                // Indirect branch
                brTargetType[i] = BTT_INDIRECT_JUMP;
            end
            else if (insnInfo[i].isSerialized) begin
                brTargetType[i] = BTT_SERIALIZED;
            end
            else begin
                brTargetType[i] = BTT_NEXT;
            end
        end

        // Detects possible  patterns where flash occurs
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            if (!insnValidIn[i]) begin
                break;
            end
            
            if (!insnInfo[i].writePC && brPredIn[i].predTaken) begin
                // Recovery if not branch instructions are predicted as branches.
                addrCheckLane = i;
                addrCheck = TRUE;
                addrIncorrect = TRUE;   // ミスが確定
                break;
            end
            else if ( //JAL || ( Branch && predTaken )
                brTargetType[i] == BTT_PC_RELATIVE && 
                (isfU[i].opCode == RISCV_JAL || brPredIn[i].predTaken)   
            ) begin
                // Update the RAS.
                pushRAS = insnInfo[i].isCall;

                addrCheckLane = i;
                addrCheck = TRUE;
                break;
            end
            else if ( // JALR
                brTargetType[i] == BTT_INDIRECT_JUMP
            ) begin
                // Update theRAS.
                pushRAS = insnInfo[i].isCall;
                popRAS = insnInfo[i].isReturn;

                if (popRAS) begin
                    // Resolve branch pred using the PC read from RAS
                    addrCheckLane = i;
                    addrCheck = TRUE;
                    break;
                end
                else if (pushRAS) begin
                    // Push next PC to RAS．Do not resolve branch pred
                    addrCheckLane = i;
                    break;
                end
            end
            else if (brTargetType[i] == BTT_SERIALIZED) begin
                // The succeeding instuructions are flushed.
                addrCheckLane = i;
                addrCheck = TRUE;
                addrIncorrect = TRUE;   // ミスが確定
                break;
            end
        end
        
        // Calculate target PC
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            nextPC[i] = pc[i] + INSN_BYTE_WIDTH;
            if (brTargetType[i] == BTT_PC_RELATIVE) begin
                // Calculate target PC from displacement
                if (isfU[i].opCode == RISCV_JAL) begin
                    decodedPC[i] = pc[i] + ExtendBranchDisplacement( GetJAL_Target(isfU[i]));
                end
                else begin
                    decodedPC[i] = pc[i] + ExtendBranchDisplacement( GetBranchDisplacement(isfU[i]));
                end
            end
            else if (brTargetType[i] == BTT_INDIRECT_JUMP) begin
                // Read branch target PC from RAS
                decodedPC[i] = ras[rasPtr];
            end
            else begin
                // non-branch instruction
                decodedPC[i] = nextPC[i];
            end
        end
        
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            addrMismatch[i] = brPredIn[i].predAddr != decodedPC[i];
        end
        
        for (int i = 0; i < DECODE_WIDTH; i++) begin
            if (((addrMismatch[i] && addrCheck) || addrIncorrect) && addrCheckLane == i) begin
                flush = TRUE;
                brPredOut[i].predAddr = decodedPC[i];
                brPredOut[i].predTaken = TRUE;
                break;
            end
        end
        recoveredPC = decodedPC[addrCheckLane];

        // Update the RAS.
        nextRAS = nextPC[addrCheckLane];
        if (pushRAS) begin
            // $display("Call(%d) flush @%x old:%p new:%p", nextRAS_Ptr, pc[addrCheckLane], brPredIn[addrCheckLane].predAddr, decodedPC[addrCheckLane]);
            nextRAS_Ptr = rasPtr + 1;
        end 
        else if (popRAS) begin
            // $display("Ret(%d)  @%x old:%p new:%p", rasPtr, pc[addrCheckLane], brPredIn[addrCheckLane].predAddr, decodedPC[addrCheckLane]);
            nextRAS_Ptr = rasPtr - 1;
        end
        else begin
            nextRAS_Ptr = rasPtr;
        end

        if (flush) begin
            for (int i = 0; i < DECODE_WIDTH; i++) begin
                if (i > addrCheckLane) begin
                    insnValidOut[i] = FALSE;
                    insnFlushed[i] = TRUE;
                end
            end
        end
    end // always_comb

endmodule

// ---- FetchUnit/BTB.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Branch target buffer
//

import BasicTypes::*;
import MemoryMapTypes::*;
import FetchUnitTypes::*;

module BTB(
    NextPCStageIF.BTB port,
    FetchStageIF.BTB next
);

    // BTB access
    logic btbWE[INT_ISSUE_WIDTH];
    BTB_IndexPath btbWA[INT_ISSUE_WIDTH];
    BTB_Entry btbWV[INT_ISSUE_WIDTH];
    BTB_IndexPath btbRA[FETCH_WIDTH];
    BTB_Entry btbRV[FETCH_WIDTH];
    
    // Output
    PC_Path btbOut[FETCH_WIDTH];
    logic btbHit[FETCH_WIDTH];
    logic readIsCondBr[FETCH_WIDTH];
    
    PC_Path pcIn;
    
    PC_Path [FETCH_WIDTH-1 : 0] tagReg;
    PC_Path [FETCH_WIDTH-1 : 0] nextTagReg;
    
    logic pushBtbQueue, popBtbQueue;
    logic full, empty;

    BTBQueueEntry btbQueue[BTB_QUEUE_SIZE];
    BTBQueuePointerPath headPtr, tailPtr;

    logic updateBtb;

    generate
        BlockMultiBankRAM #(
            .ENTRY_NUM( BTB_ENTRY_NUM ),
            .ENTRY_BIT_SIZE( $bits( BTB_Entry ) ),
            .READ_NUM( FETCH_WIDTH ),
            .WRITE_NUM( INT_ISSUE_WIDTH )
        ) 
        btbEntryArray( 
            .clk(port.clk),
            .we(btbWE),
            .wa(btbWA),
            .wv(btbWV),
            .ra(btbRA),
            .rv(btbRV)
        );

        QueuePointer #(
            .SIZE( BTB_QUEUE_SIZE )
        )
        btbQueuePointer(
            .clk(port.clk),
            .rst(port.rst),
            .push(pushBtbQueue),
            .pop(popBtbQueue),
            .full(full),
            .empty(empty),
            .headPtr(headPtr),
            .tailPtr(tailPtr)    
        );
    endgenerate
    
    
    // Counter for reset sequence.
    BTB_IndexPath resetIndex;
    always_ff @(posedge port.clk) begin
        if(port.rstStart) begin
            resetIndex <= 0;
        end
        else begin
            resetIndex <= resetIndex + 1;
        end
        
        if (port.rst) begin
            tagReg <= '0;
        end
        else begin
            tagReg <= nextTagReg;
        end
    end

    always_ff @(posedge port.clk) begin
        // Push btb Queue
        if (pushBtbQueue) begin
            btbQueue[headPtr].btbWA <= btbWA[INT_ISSUE_WIDTH-1];
            btbQueue[headPtr].btbWV <= btbWV[INT_ISSUE_WIDTH-1];
        end 
    end


    always_comb begin
        
        pcIn = port.predNextPC;
        
        // Address inputs for read entry.
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            btbRA[i] = ToBTB_Index(pcIn + i*INSN_BYTE_WIDTH);
            nextTagReg[i] = pcIn + i*INSN_BYTE_WIDTH;
        end
            
        // Make logic for using at other module.
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            btbHit[i] = btbRV[i].valid && (btbRV[i].tag == ToBTB_Tag(tagReg[i]));
            btbOut[i] = ToRawAddrFromBTB_Addr(btbRV[i].data, tagReg[i]);
            readIsCondBr[i] = btbRV[i].isCondBr;
        end

        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            btbWE[i] = FALSE;
        end
        updateBtb = FALSE;
        pushBtbQueue = FALSE;

        // Write to BTB.
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            // Make BTB entry when branch is Taken.
            if (updateBtb) begin
                pushBtbQueue = port.brResult[i].valid && port.brResult[i].execTaken;
            end
            else begin
                btbWE[i] = port.brResult[i].valid && port.brResult[i].execTaken;
                updateBtb |= btbWE[i];
            end

            btbWA[i] = ToBTB_Index(port.brResult[i].brAddr);
            btbWV[i].tag = ToBTB_Tag(port.brResult[i].brAddr);
            btbWV[i].data = ToBTB_Addr(port.brResult[i].nextAddr);
            btbWV[i].valid = TRUE;
            btbWV[i].isCondBr = port.brResult[i].isCondBr;
        end

        // Pop btb Queue
        if (!empty && !updateBtb) begin
            popBtbQueue = TRUE;
            btbWE[0] = TRUE;
            btbWA[0] = btbQueue[tailPtr].btbWA;
            btbWV[0] = btbQueue[tailPtr].btbWV;
        end 
        else begin
            popBtbQueue = FALSE;
        end

        
        // In reset sequence, the write port 0 is used for initializing, and 
        // the other write ports are disabled.
        if (port.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                btbWE[i] = (i == 0) ? TRUE : FALSE;
                btbWA[i] = resetIndex;
                btbWV[i].tag = 0;
                btbWV[i].data = 0;
                btbWV[i].valid = FALSE;
            end

            // To avoid writing to the same bank (avoid error message)
            for (int i = 0; i < FETCH_WIDTH; i++) begin
                btbRA[i] = i;
            end
            
            pushBtbQueue = FALSE;
            popBtbQueue = FALSE;
        end

        next.readIsCondBr = readIsCondBr;
        next.btbOut = btbOut;
        next.btbHit = btbHit;
        
    end


endmodule : BTB
// ---- FetchUnit/BranchPredictor.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Branch predictor
//

import BasicTypes::*;
import FetchUnitTypes::*;

`define USE_GSHARE

module BranchPredictor(
    NextPCStageIF.BranchPredictor port,
    FetchStageIF.BranchPredictor next,
    ControllerIF.BranchPredictor ctrl
);

`ifdef USE_GSHARE
    Gshare predictor( port, next, ctrl );
`else
    Bimodal predictor( port, next );
`endif

endmodule : BranchPredictor
// ---- FetchUnit/Gshare.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Gshare Branch Predictor
//

import BasicTypes::*;
import MemoryMapTypes::*;
import FetchUnitTypes::*;

function automatic PHT_IndexPath ToPHT_Index_Global(AddrPath addr, BranchGlobalHistoryPath gh);
    PHT_IndexPath phtIndex;
    phtIndex =
        addr[
            PHT_ENTRY_NUM_BIT_WIDTH + INSN_ADDR_BIT_WIDTH - 1: 
            INSN_ADDR_BIT_WIDTH
        ];
    phtIndex[PHT_ENTRY_NUM_BIT_WIDTH - 1 : PHT_ENTRY_NUM_BIT_WIDTH - BRANCH_GLOBAL_HISTORY_BIT_WIDTH] ^= gh;
    return phtIndex;
endfunction

module Gshare(
    NextPCStageIF.BranchPredictor port,
    FetchStageIF.BranchPredictor next,
    ControllerIF.BranchPredictor ctrl
);

    logic stall, clear;
    PC_Path pcIn;

    // Use combinational logic
    logic brPredTaken[FETCH_WIDTH];
    logic updateHistory[FETCH_WIDTH];

    // Logic for read/write PHT
    logic phtWE[INT_ISSUE_WIDTH];
    PHT_IndexPath phtWA[INT_ISSUE_WIDTH];
    PHT_EntryPath phtWV[INT_ISSUE_WIDTH];
    PHT_EntryPath phtPrevValue[INT_ISSUE_WIDTH];

    // Read port need for branch predict and update counter.
    PHT_IndexPath phtRA[FETCH_WIDTH];
    PHT_EntryPath phtRV[FETCH_WIDTH];

    // Branch history for using predict.
    BranchGlobalHistoryPath nextBrGlobalHistory, regBrGlobalHistory;
    BranchGlobalHistoryPath brGlobalHistory [ FETCH_WIDTH ];

    // assert when misprediction occured.
    logic mispred;

    logic pushPhtQueue, popPhtQueue;
    logic full, empty;

    // Queue for multibank pht
    PhtQueueEntry phtQueue[PHT_QUEUE_SIZE];
    PhtQueuePointerPath headPtr, tailPtr;

    // Check for write number in 1cycle.
    logic updatePht;

    // the body of PHT.
    generate
        BlockMultiBankRAM #(
            .ENTRY_NUM( PHT_ENTRY_NUM ),
            .ENTRY_BIT_SIZE( $bits( PHT_EntryPath ) ),
            .READ_NUM( FETCH_WIDTH ),
            .WRITE_NUM( INT_ISSUE_WIDTH )
        )
        pht( 
            .clk(port.clk),
            .we(phtWE),
            .wa(phtWA),
            .wv(phtWV),
            .ra(phtRA),
            .rv(phtRV)
        );
        
        QueuePointer #(
            .SIZE( PHT_QUEUE_SIZE )
        )
        phtQueuePointer(
            .clk(port.clk),
            .rst(port.rst),
            .push(pushPhtQueue),
            .pop(popPhtQueue),
            .full(full),
            .empty(empty),
            .headPtr(headPtr),
            .tailPtr(tailPtr)    
        );
    endgenerate
    
    
    // Counter for reset sequence.
    PHT_IndexPath resetIndex;
    always_ff @(posedge port.clk) begin
        if (port.rstStart) begin
            resetIndex <= 0;
        end
        else begin
            resetIndex <= resetIndex + 1;
        end
    end

    always_ff @(posedge port.clk) begin
        // update Branch Global History.
        if (port.rst) begin
            regBrGlobalHistory <= '0;
        end
        else begin
            regBrGlobalHistory <= nextBrGlobalHistory;
        end

        // Push Pht Queue
        if (pushPhtQueue) begin
            phtQueue[headPtr].phtWA <= phtWA[INT_ISSUE_WIDTH-1];
            phtQueue[headPtr].phtWV <= phtWV[INT_ISSUE_WIDTH-1];
        end
    end


    always_comb begin

        stall = ctrl.ifStage.stall;
        clear = ctrl.ifStage.clear;
    
        pcIn = port.predNextPC;

        nextBrGlobalHistory = regBrGlobalHistory;

        for (int i = 0; i < FETCH_WIDTH; i++) begin
            brPredTaken[i] = FALSE;
            // Output global history to pipeline for recovery.
            brGlobalHistory[i] = regBrGlobalHistory;
            updateHistory[i] = FALSE;
        end

        for (int i = 0; i < FETCH_WIDTH; i++) begin
            // Predict directions (Check the MSB).
            brPredTaken[i] =
                phtRV[i][PHT_ENTRY_WIDTH - 1] && next.btbHit[i];

            // Assert BTB is hit, ICache line is valid, and conditional branch.
            updateHistory[i] = next.btbHit[i] && next.readIsCondBr[i] && 
                next.updateBrHistory[i];

            // Generate next brGlobalHistory.
            if (updateHistory[i]) begin
                // Shift history 1 bit to the left and reflect prediction direction in LSB.
                nextBrGlobalHistory = 
                    (nextBrGlobalHistory << 1) | brPredTaken[i];
                
                if (brPredTaken[i]) begin
                    // If brPred is taken, next instruction don't be executed.
                    break;
                end
            end
        end
        
        next.phtPrevValue = phtRV;
        next.brPredTaken = brPredTaken;
        next.brGlobalHistory = brGlobalHistory;

        // Discard the result of previous cycle
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            phtWE[i] = FALSE;
            phtWV[i] = '0;
            // Counter's value.
            phtPrevValue[i] = port.brResult[i].phtPrevValue; 
            phtWA[i] = ToPHT_Index_Global(
                port.brResult[i].brAddr,
                port.brResult[i].globalHistory
            );
        end

        updatePht = FALSE;
        pushPhtQueue = FALSE;

        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            // When branch instruction is executed, update PHT.
            if (updatePht) begin
                pushPhtQueue = port.brResult[i].valid;
            end
            else begin
                phtWE[i] = port.brResult[i].valid;
                updatePht |= phtWE[i];
            end

            mispred = port.brResult[i].mispred && port.brResult[i].valid;

            // Update PHT's counter (saturated up/down counter).
            if (port.brResult[i].execTaken) begin
                phtWV[i] = (phtPrevValue[i] == PHT_ENTRY_MAX) ? 
                    PHT_ENTRY_MAX : phtPrevValue[i] + 1;
            end
            else begin
                phtWV[i] = (phtPrevValue[i] == 0) ? 
                    0 : phtPrevValue[i] - 1;
            end

            // When miss prediction is occured, recovory history.
            if (mispred) begin
                if (port.brResult[i].isCondBr) begin
                    nextBrGlobalHistory = 
                        (port.brResult[i].globalHistory << 1) | port.brResult[i].execTaken;
                end
                else begin
                    nextBrGlobalHistory = port.brResult[i].globalHistory;
                end
            end
        end

        for (int i = 0; i < FETCH_WIDTH; i++) begin
            // Read PHT entry for next cycle (use PC ^ brGlobalHistory).
            phtRA[i] = ToPHT_Index_Global(
                pcIn + i*INSN_BYTE_WIDTH,
                nextBrGlobalHistory
            );
        end

        // Pop PHT Queue
        if (!empty && !updatePht) begin
            popPhtQueue = TRUE;
            phtWE[0] = TRUE;
            phtWA[0] = phtQueue[tailPtr].phtWA;
            phtWV[0] = phtQueue[tailPtr].phtWV;
        end 
        else begin
            popPhtQueue = FALSE;
        end

        // In reset sequence, the write port 0 is used for initializing, and 
        // the other write ports are disabled.
        if (port.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                phtWE[i] = (i == 0) ? TRUE : FALSE;
                phtWA[i] = resetIndex;
                phtWV[i] = PHT_ENTRY_MAX / 2 + 1;
            end

            // To avoid writing to the same bank (avoid error message)
            for (int i = 0; i < FETCH_WIDTH; i++) begin
                phtRA[i] = i;
            end

            pushPhtQueue = FALSE;
            popPhtQueue = FALSE;
        end
    end

endmodule : Gshare
// ---- FetchUnit/Bimodal.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Branch predictor -- 2bc.
//

import BasicTypes::*;
import MemoryMapTypes::*;
import FetchUnitTypes::*;

function automatic PHT_IndexPath ToPHT_Index_Local(PC_Path addr);
    return
        addr[
            PHT_ENTRY_NUM_BIT_WIDTH + INSN_ADDR_BIT_WIDTH - 1: 
            INSN_ADDR_BIT_WIDTH
        ];
endfunction

module Bimodal(
    NextPCStageIF.BranchPredictor port,
    FetchStageIF.BranchPredictor next
);

    PC_Path pcIn;

    logic brPredTaken;

    // PHT control logic
    logic phtWE[INT_ISSUE_WIDTH];
    PHT_IndexPath phtWA[INT_ISSUE_WIDTH];
    PHT_EntryPath phtWV[INT_ISSUE_WIDTH];
    PHT_EntryPath phtPrevValue[INT_ISSUE_WIDTH];

    // Read port need for branch predict and update counter.
    PHT_IndexPath phtRA[FETCH_WIDTH];
    PHT_EntryPath phtRV[FETCH_WIDTH];

    // assert when misprediction occured.
    logic mispred;

    logic pushPhtQueue, popPhtQueue;
    logic full, empty;

    PhtQueueEntry phtQueue[PHT_QUEUE_SIZE];
    PhtQueuePointerPath headPtr, tailPtr;

    logic updatePht;


    // the body of PHT.
    generate
        BlockMultiBankRAM #(
            .ENTRY_NUM( PHT_ENTRY_NUM ),
            .ENTRY_BIT_SIZE( $bits( PHT_EntryPath ) ),
            .READ_NUM( FETCH_WIDTH ),
            .WRITE_NUM( INT_ISSUE_WIDTH )
        ) 
        pht( 
            .clk(port.clk),
            .we(phtWE),
            .wa(phtWA),
            .wv(phtWV),
            .ra(phtRA),
            .rv(phtRV)
        );

        QueuePointer #(
            .SIZE( PHT_QUEUE_SIZE )
        )
        phtQueuePointer(
            .clk(port.clk),
            .rst(port.rst),
            .push(pushPhtQueue),
            .pop(popPhtQueue),
            .full(full),
            .empty(empty),
            .headPtr(headPtr),
            .tailPtr(tailPtr)    
        );
    endgenerate
    
    
    // Counter for reset sequence.
    PHT_IndexPath resetIndex;
    always_ff @(posedge port.clk) begin
        if(port.rstStart) begin
            resetIndex <= 0;
        end
        else begin
            resetIndex <= resetIndex + 1;
        end
    end

    always_ff @(posedge port.clk) begin
        // Push Pht Queue
        if (pushPhtQueue) begin
            phtQueue[headPtr].phtWA <= phtWA[INT_ISSUE_WIDTH-1];
            phtQueue[headPtr].phtWV <= phtWV[INT_ISSUE_WIDTH-1];
        end
    end


    always_comb begin
    
        pcIn = port.predNextPC;

        for (int i = 0; i < FETCH_WIDTH; i++) begin
            next.phtPrevValue[i] = phtRV[i];

            // Predict directions (Check the MSB).
            brPredTaken =
                phtRV[i][PHT_ENTRY_WIDTH - 1] && next.btbHit[i];
            next.brPredTaken[i] = brPredTaken;

            if (brPredTaken) begin
                // If brPred is taken, next instruction don't be executed.
                break;
            end
        end

        // Negate first. (to discard the result of previous cycle)
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            phtWE[i] = FALSE;
            updatePht = FALSE;
            pushPhtQueue = FALSE;
        end

        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            // When branch instruction is executed, update PHT.
            if (updatePht) begin
                pushPhtQueue = port.brResult[i].valid;
            end
            else begin
                phtWE[i] = port.brResult[i].valid;
                updatePht |= phtWE[i];
            end

            phtWA[i] = ToPHT_Index_Local(port.brResult[i].brAddr);

            mispred = port.brResult[i].mispred && port.brResult[i].valid;
            
            // Counter's value.
            phtPrevValue[i] = port.brResult[i].phtPrevValue; 
            
            // Update PHT's counter (saturated up/down counter).
            if (port.brResult[i].execTaken) begin
                phtWV[i] = (phtPrevValue[i] == PHT_ENTRY_MAX) ? 
                    PHT_ENTRY_MAX : phtPrevValue[i] + 1;
            end
            else begin
                phtWV[i] = (phtPrevValue[i] == 0) ? 
                    0 : phtPrevValue[i] - 1;
            end

            // When miss prediction is occured, recovory history.
            if (mispred) begin
                break;
            end
        end

        for (int i = 0; i < FETCH_WIDTH; i++) begin
            // Read PHT entry for next cycle (use PC).
            phtRA[i] = ToPHT_Index_Local(pcIn + i*INSN_BYTE_WIDTH);
        end


        // Pop PHT Queue
        if (!empty && !updatePht) begin
            popPhtQueue = TRUE;
            phtWE[0] = TRUE;
            phtWA[0] = phtQueue[tailPtr].phtWA;
            phtWV[0] = phtQueue[tailPtr].phtWV;
        end 
        else begin
            popPhtQueue = FALSE;
        end

        // In reset sequence, the write port 0 is used for initializing, and 
        // the other write ports are disabled.
        if (port.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                phtWE[i] = (i == 0) ? TRUE : FALSE;
                phtWA[i] = resetIndex;
                phtWV[i] = PHT_ENTRY_MAX / 2 + 1;
            end

            // To avoid writing to the same bank (avoid error message)
            for (int i = 0; i < FETCH_WIDTH; i++) begin
                phtRA[i] = i;
            end

            pushPhtQueue = FALSE;
            popPhtQueue = FALSE;
        end
    end


endmodule : Bimodal


// ---- Scheduler/SchedulerIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// SchedulerIF
//

import BasicTypes::*;
import CacheSystemTypes::*;
import MicroOpTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import PipelineTypes::*;

interface SchedulerIF( input logic clk, rst, rstStart );

    // Allocation
    logic               allocate [ RENAME_WIDTH ];
    IssueQueueIndexPath allocatedPtr [ RENAME_WIDTH ];
    logic               allocatable;

    // Dispatch
    logic               write [ DISPATCH_WIDTH ];
    IssueQueueIndexPath writePtr [ DISPATCH_WIDTH ];
    ActiveListIndexPath writeAL_Ptr [ DISPATCH_WIDTH ];
    IntIssueQueueEntry  intWriteData [ DISPATCH_WIDTH ];
    MemIssueQueueEntry  memWriteData [ DISPATCH_WIDTH ];
    SchedulerEntry      writeSchedulerData [ DISPATCH_WIDTH ];

    // Schedule
    logic               selected [ ISSUE_WIDTH ];
    IssueQueueIndexPath selectedPtr [ ISSUE_WIDTH ];

    // Issue
    logic               intIssue [ INT_ISSUE_WIDTH ];
    IssueQueueIndexPath intIssuePtr [ INT_ISSUE_WIDTH ];
    IntIssueQueueEntry  intIssuedData [ INT_ISSUE_WIDTH ];

    logic               memIssue [ MEM_ISSUE_WIDTH ];
    IssueQueueIndexPath memIssuePtr [ MEM_ISSUE_WIDTH ];
    MemIssueQueueEntry  memIssuedData [ MEM_ISSUE_WIDTH ];

    // Release
    // Issued entries are flushed.
    logic               intRecordEntry[INT_ISSUE_WIDTH];
    logic               intReplayEntry[INT_ISSUE_WIDTH];
    IntIssueQueueEntry  intRecordData[INT_ISSUE_WIDTH];
    IntIssueQueueEntry  intReplayData[INT_ISSUE_WIDTH];

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    ComplexIssueQueueEntry  complexWriteData [ DISPATCH_WIDTH ];

    logic               complexIssue [ COMPLEX_ISSUE_WIDTH ];
    IssueQueueIndexPath complexIssuePtr [ COMPLEX_ISSUE_WIDTH ];
    ComplexIssueQueueEntry  complexIssuedData [ COMPLEX_ISSUE_WIDTH ];

    logic               complexRecordEntry[COMPLEX_ISSUE_WIDTH];
    logic               complexReplayEntry[COMPLEX_ISSUE_WIDTH];
    ComplexIssueQueueEntry  complexRecordData[COMPLEX_ISSUE_WIDTH];
    ComplexIssueQueueEntry  complexReplayData[COMPLEX_ISSUE_WIDTH];

    // Reserve to use divider
    logic divIsIssued [ COMPLEX_ISSUE_WIDTH ];
`endif

    logic               memReleaseEntry[MEM_ISSUE_WIDTH];
    logic               memRecordEntry[MEM_ISSUE_WIDTH];
    logic               memReplayEntry[MEM_ISSUE_WIDTH];
    MemIssueQueueEntry  memRecordData[MEM_ISSUE_WIDTH];
    MemIssueQueueEntry  memReplayData[MEM_ISSUE_WIDTH];
    logic               memRecordAddrHit[MEM_ISSUE_WIDTH];
    DCacheIndexSubsetPath   memRecordAddrSubset[MEM_ISSUE_WIDTH];
    logic replay;

    // Stall scheduling
    logic stall;

    // For issue queue flush of dispatch stage ops ( already allocate issue queue entry )
    logic allocated[DISPATCH_WIDTH];

    // Memory dependency prediction
    logic memDependencyPred [ DISPATCH_WIDTH ];

    // To an issue queue payload RAM
    modport IssueQueue(
    input
        clk,
        rst,
        rstStart,
        allocate,
        write,
        writePtr,
        writeAL_Ptr,
        intWriteData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexWriteData,
        complexIssue,
        complexIssuePtr,
`endif
        memWriteData,
        intIssue,
        intIssuePtr,
        memIssue,
        memIssuePtr,
        allocated,
    output
        allocatable,
        allocatedPtr,
        intIssuedData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexIssuedData,
`endif  
        memIssuedData
    );

    // To a scheduler (wakeup/select logic)
    modport Scheduler(
    input
        clk,
        rst,
        stall,
        write,
        writePtr,
        writeSchedulerData,
        memDependencyPred,
    output
        selected,
        selectedPtr
    );

    modport ReplayQueue(
    input
        clk,
        rst,
        rstStart,
        stall,
        intRecordEntry,
        intRecordData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexRecordEntry,
        complexRecordData,
`endif
        memRecordAddrHit,
        memRecordAddrSubset,
        memRecordEntry,
        memRecordData,
    output
        intReplayEntry,
        intReplayData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexReplayEntry,
        complexReplayData,
`endif
        memReplayEntry,
        memReplayData,
        replay
    );



    modport RenameStage(
    input
        allocatedPtr,
        allocatable,
    output
        allocate
    );

    modport DispatchStage(
    output
        write,
        writePtr,
        writeAL_Ptr,
        intWriteData,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexWriteData,
`endif
        memWriteData,
        writeSchedulerData,
        allocated,
        memDependencyPred
    );

    modport ScheduleStage(
    input
        selected,
        selectedPtr,
    output
        stall
    );

    modport IntegerIssueStage(
    input
        intIssuedData,
        intReplayEntry,
        intReplayData,
        replay,
    output
        intIssuePtr,
        intIssue
    );

    modport IntegerRegisterWriteStage(
    output
        intRecordEntry,
        intRecordData
    );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    modport ComplexIntegerIssueStage(
    input
        complexIssuedData,
        complexReplayEntry,
        complexReplayData,
        replay,
    output
        complexIssuePtr,
        complexIssue,
        divIsIssued
    );

    modport ComplexIntegerExecutionStage(
    input
        divIsIssued,
    output
        complexRecordEntry,
        complexRecordData
    );
`endif
    modport MemoryIssueStage(
    input
        memIssuedData,
        memReplayEntry,
        memReplayData,
        replay,
    output
        memIssuePtr,
        memIssue
    );

    modport MemoryTagAccessStage(
    output
        memRecordAddrHit,
        memRecordAddrSubset,
        memRecordEntry,
        memRecordData
    );
    
endinterface : SchedulerIF

// ---- Scheduler/IssueQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// IssueQueue ( Allocator and payloadRAM )
//

import BasicTypes::*;
import PipelineTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import RenameLogicTypes::*;

module IssueQueue (
    SchedulerIF.IssueQueue port,
    WakeupSelectIF.IssueQueue wakeupSelect,
    RecoveryManagerIF.IssueQueue recovery,
    DebugIF.IssueQueue debug
);

    //
    // Issue queue allocator
    //

    // A free list for an issue queue entries.
    // Both its index and values have the same bit width, because
    // the sizes of an issue queue and its free list are same.
    logic releaseEntry [ ISSUE_WIDTH + ISSUE_QUEUE_RETURN_INDEX_WIDTH ];
    IssueQueueIndexPath releasePtr [ ISSUE_WIDTH + ISSUE_QUEUE_RETURN_INDEX_WIDTH ];
    IssueQueueCountPath freeListCount;
    logic freeListReset;
    logic [ ISSUE_QUEUE_RESET_CYCLE_BIT_SIZE-1 : 0 ] freeListResetCycleCount;

    // 選択的フラッシュ検出
    ActiveListIndexPath alPtrReg [ ISSUE_QUEUE_ENTRY_NUM ];  //IssueQueueのActivlistPtrのフィールドを複製したレジスタ
    logic [ ISSUE_QUEUE_ENTRY_NUM-1:0 ] flush;   //フラッシュされるべきエントリの信号(例外命令AL中で後方にあるエントリ)
    logic [ ISSUE_QUEUE_ENTRY_NUM-1:0 ] prevFlushAtRecovery;  //フリーリストにフラッシュされたインデックスを返却するためのレジスタ
    logic issueQueueReturnIndex;    //フリーリストにインデックスを返却中かどうか
    logic [ ISSUE_QUEUE_RETURN_INDEX_CYCLE_BIT_SIZE-1:0 ] issueQueueReturnIndexCycleCount;
    IssueQueueIndexPath returnIndexOffset;//フラッシュの判定をした後にIQのフリーリストへの返却用インデックス

    IssueQueueIndexPath writePtr[ DISPATCH_WIDTH ];
    IssueQueueIndexPath selectedPtr [ ISSUE_WIDTH ];

    MultiWidthFreeList #(
        .SIZE( ISSUE_QUEUE_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( ISSUE_QUEUE_ENTRY_NUM_BIT_WIDTH ),
        .PUSH_WIDTH( ISSUE_WIDTH + ISSUE_QUEUE_RETURN_INDEX_WIDTH ),
        .POP_WIDTH( RENAME_WIDTH ),
        .INITIAL_LENGTH (ISSUE_QUEUE_ENTRY_NUM)
    ) issueQueueFreeList (
            .clk( port.clk ),
            .rst( port.rst || freeListReset ),
            .rstStart( port.rstStart ),
            .count( freeListCount ),

            .pop( port.allocate ),
            .poppedData( port.allocatedPtr ),

            .push( releaseEntry ),
            .pushedData( releasePtr )
        );

    always_comb begin
        // Allocate
        // freeListReset がアサートされているリセット中に，
        // 新しくエントリを確保させるとキューがこわれるのでブロックする
        port.allocatable = (!freeListReset && freeListCount >= RENAME_WIDTH) ? TRUE : FALSE;

        // Release
        for ( int i = 0; i < ISSUE_WIDTH; i++ ) begin
            releasePtr[i] = wakeupSelect.releasePtr[i];
            releaseEntry[i] = wakeupSelect.releaseEntry[i];
        end
        for ( int i = 0; i < ISSUE_QUEUE_RETURN_INDEX_WIDTH; i++ ) begin
            if ( issueQueueReturnIndex && prevFlushAtRecovery[returnIndexOffset+i] ) begin
                releaseEntry[ ISSUE_WIDTH + i ] = TRUE;
                releasePtr[ ISSUE_WIDTH + i ] = returnIndexOffset + i;
            end
            else begin
                releaseEntry[ ISSUE_WIDTH + i ] = FALSE;
                //Don't care
                releasePtr[ ISSUE_WIDTH + i ] = returnIndexOffset + i;
            end
        end
    end

    // Reset(when recovery at commit occurs)
    always_ff @( posedge port.clk ) begin
        if ( port.rst ) begin
            freeListReset <= FALSE;
            freeListResetCycleCount <= 0;
        end
        else if ( recovery.toRecoveryPhase && !recovery.recoveryFromRwStage) begin
            // Start of reset sequence
            freeListReset <= TRUE;
            freeListResetCycleCount <= 0;
        end
        else if ( freeListResetCycleCount == ISSUE_QUEUE_RESET_CYCLE - 1 ) begin
            // End of reset sequence
            freeListReset <= FALSE;
            freeListResetCycleCount <= 0;
        end
        else begin
            freeListReset <= freeListReset;
            freeListResetCycleCount <= freeListResetCycleCount + 1;
        end
    end


    //
    // Issue queue (payload ram).
    //
    IssueQueueIndexPath    intIssuePtr       [ INT_ISSUE_WIDTH ];
    IssueQueueIndexPath    memIssuePtr       [ MEM_ISSUE_WIDTH ];
    IntIssueQueueEntry     intIssuedData     [ INT_ISSUE_WIDTH ];
    MemIssueQueueEntry     memIssuedData     [ MEM_ISSUE_WIDTH ];

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    IssueQueueIndexPath    complexIssuePtr   [ COMPLEX_ISSUE_WIDTH ];
    ComplexIssueQueueEntry complexIssuedData [ COMPLEX_ISSUE_WIDTH ];
`endif


    DistributedMultiPortRAM #(
        .ENTRY_NUM( ISSUE_QUEUE_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( $bits( IntIssueQueueEntry ) ),
        .READ_NUM( INT_ISSUE_WIDTH ),
        .WRITE_NUM( DISPATCH_WIDTH )
    ) intPayloadRAM (
        .clk( port.clk ),
        .we( port.write ),
        .wa( port.writePtr ),
        .wv( port.intWriteData ),
        .ra( intIssuePtr ),
        .rv( intIssuedData )
    );

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    DistributedMultiPortRAM #(
        .ENTRY_NUM( ISSUE_QUEUE_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( $bits( ComplexIssueQueueEntry ) ),
        .READ_NUM( COMPLEX_ISSUE_WIDTH ),
        .WRITE_NUM( DISPATCH_WIDTH )
    ) complexPayloadRAM (
        .clk( port.clk ),
        .we( port.write ),
        .wa( port.writePtr ),
        .wv( port.complexWriteData ),
        .ra( complexIssuePtr ),
        .rv( complexIssuedData )
    );
`endif

    DistributedMultiPortRAM #(
        .ENTRY_NUM( ISSUE_QUEUE_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( $bits( MemIssueQueueEntry ) ),
        .READ_NUM( MEM_ISSUE_WIDTH ),
        .WRITE_NUM( DISPATCH_WIDTH )
    ) memPayloadRAM (
        .clk( port.clk ),
        .we( port.write ),
        .wa( port.writePtr ),
        .wv( port.memWriteData ),
        .ra( memIssuePtr ),
        .rv( memIssuedData )
    );


    always_comb begin
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            intIssuePtr[i] = port.intIssuePtr[i];
            port.intIssuedData[i] = intIssuedData[i];
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            complexIssuePtr[i] = port.complexIssuePtr[i];
            port.complexIssuedData[i] = complexIssuedData[i];
        end
`endif
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            memIssuePtr[i] = port.memIssuePtr[i];
            port.memIssuedData[i] = memIssuedData[i];
        end
    end


    //以下は選択的フラッシュのための機構
`ifndef RSD_SYNTHESIS
    initial begin
        for (int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
            alPtrReg[i]<='0;
        end
    end
`endif

    //alPtrRegにIssueQueueの各エントリのActiveListPtrを複製しておく
    always_ff @( posedge port.clk ) begin
        for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
            if ( port.write[i] ) begin
                alPtrReg[ writePtr[i] ] <= port.writeAL_Ptr[i];
            end
        end
    end

    //WakeupPipelineRegisterにおいてフラッシュされた命令が後続にブロードキャストされないための判定に使う
    always_comb begin
        for ( int i = 0; i < ISSUE_WIDTH; i++ ) begin
            recovery.selectedActiveListPtr[i] = alPtrReg[ selectedPtr[i] ];
        end
    end

    //synopsysの合成においてインターフェースの配列を直接使うのが怪しいので一度変数に落とす
    always_comb begin
        writePtr = port.writePtr;
        selectedPtr = recovery.selectedPtr;
    end

    //例外が発生したとき, IssueQueueの各エントリに対してフラッシュを行うかどうかを判定する
    //また, dispatchステージにある命令はすでにリネームステージでIssueQueueをアロケートしているのでそれもここで判定をする
    always_comb begin
        // Flush IQ Enry
        for ( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            flush[i] = SelectiveFlushDetector(
                        recovery.toRecoveryPhase && recovery.notIssued[i],
                        recovery.flushRangeHeadPtr,
                        recovery.flushRangeTailPtr,
                        alPtrReg[i]
                        );
        end
        // Flush dispatched ops ( already allocate IQ Entry but not activate notIssued )
        for (int i = 0; i < DISPATCH_WIDTH; i++ ) begin
            if(port.allocated[i]) begin
                flush[ writePtr[i] ] = SelectiveFlushDetector(
                            recovery.toRecoveryPhase,
                            recovery.flushRangeHeadPtr,
                            recovery.flushRangeTailPtr,
                            port.writeAL_Ptr[i]
                            );
            end
        end
        recovery.flushIQ_Entry = flush;
        recovery.issueQueueReturnIndex = issueQueueReturnIndex || freeListReset;
    end

    // Return index to FreeList
    always_ff @( posedge port.clk ) begin
        if ( port.rst ) begin
            prevFlushAtRecovery <= 0;
            issueQueueReturnIndex <= FALSE;
            issueQueueReturnIndexCycleCount <= 0;
        end
        else if ( recovery.toRecoveryPhase && recovery.recoveryFromRwStage ) begin
            // Start of reset sequence
            prevFlushAtRecovery <= flush;
            issueQueueReturnIndex <= TRUE;
            issueQueueReturnIndexCycleCount <= 0;
        end
        else if ( issueQueueReturnIndexCycleCount == ISSUE_QUEUE_RETURN_INDEX_CYCLE - 1 ) begin
            // End of reset sequence
            issueQueueReturnIndex <= FALSE;
            issueQueueReturnIndexCycleCount <= 0;
        end
        else begin
            issueQueueReturnIndex <= issueQueueReturnIndex;
            issueQueueReturnIndexCycleCount <= issueQueueReturnIndexCycleCount + 1;
        end
    end

    always_ff @ (posedge port.clk) begin
        if (port.rst || (recovery.toRecoveryPhase && recovery.recoveryFromRwStage)) begin
            returnIndexOffset <= 0;
        end
        else if ( returnIndexOffset >= ISSUE_QUEUE_ENTRY_NUM - ISSUE_QUEUE_RETURN_INDEX_WIDTH ) begin
            returnIndexOffset <= 0;
        end
        else begin
            returnIndexOffset <= returnIndexOffset + ISSUE_QUEUE_RETURN_INDEX_WIDTH;
        end
    end

    //
    // OpId for Debug
    //
    `ifndef RSD_DISABLE_DEBUG_REGISTER
        OpId opId[ ISSUE_QUEUE_ENTRY_NUM ];
        always_ff @( posedge port.clk ) begin
            if( port.rst ) begin
                for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
                    opId[i].sid <= 0;
                    opId[i].mid <= 0;
                end
            end
            else begin
                // Dispatch
                for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
                    if( port.write[i] ) begin
                        opId[ writePtr[i] ] <= port.intWriteData[i].opId;
                    end
                end
            end
        end

        always_comb begin
            for ( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
                debug.issueQueue[i].flush = flush[i];
                debug.issueQueue[i].opId = opId[i];
            end
        end
    `endif

endmodule : IssueQueue



// ---- Scheduler/ReplayQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Replay queue
//

import BasicTypes::*;
import PipelineTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import CacheSystemTypes::*;
import RenameLogicTypes::*;

module ReplayQueue(
    SchedulerIF.ReplayQueue port,
    LoadStoreUnitIF.ReplayQueue mshr,
    MulDivUnitIF.ReplayQueue mulDivUnit,
    RecoveryManagerIF.ReplayQueue recovery,
    ControllerIF.ReplayQueue ctrl
);

    parameter REPLAY_QUEUE_ENTRY_NUM = 20;
    parameter REPLAY_QUEUE_ENTRY_NUM_BIT_WIDTH = $clog2(REPLAY_QUEUE_ENTRY_NUM);
    typedef logic [REPLAY_QUEUE_ENTRY_NUM_BIT_WIDTH-1 : 0] ReplayQueueIndexPath;
    typedef logic [REPLAY_QUEUE_ENTRY_NUM_BIT_WIDTH : 0] ReplayQueueCountPath;

    // A maximux replay interbal between two entries in ReplayQueue is
    // equal to a maximum latency of all instruction.
    // TODO: modify this when adding an instruction whose latency is larger than
    //       memory access instructions.
    parameter REPLAY_QUEUE_MAX_INTERVAL = ISSUE_QUEUE_COMPLEX_LATENCY;
//    parameter REPLAY_QUEUE_MAX_INTERVAL = ISSUE_QUEUE_MEM_LATENCY;
    parameter REPLAY_QUEUE_MAX_INTERVAL_BIT_WIDTH = $clog2(REPLAY_QUEUE_MAX_INTERVAL);
    typedef logic [REPLAY_QUEUE_MAX_INTERVAL_BIT_WIDTH-1 : 0] ReplayQueueIntervalPath;


    // Body of replay queue
    typedef struct packed {
        // Int op data
        logic [INT_ISSUE_WIDTH-1 : 0] intValid;
        IntIssueQueueEntry [INT_ISSUE_WIDTH-1 : 0] intData;
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        // Complex op data
        logic [COMPLEX_ISSUE_WIDTH-1 : 0] complexValid;
        ComplexIssueQueueEntry [COMPLEX_ISSUE_WIDTH-1 : 0] complexData;
`endif
        // Mem op data
        logic [MEM_ISSUE_WIDTH-1 : 0] memValid;
        MemIssueQueueEntry [MEM_ISSUE_WIDTH-1 : 0] memData;
        logic [MEM_ISSUE_WIDTH-1 : 0] memAddrHit;
        DCacheIndexSubsetPath [MEM_ISSUE_WIDTH-1 : 0] memAddrSubset;
        // How many cycles to replay after waiting
        ReplayQueueIntervalPath replayInterval;
    } ReplayQueueEntry;

    ReplayQueueEntry recordData;
    ReplayQueueEntry replayEntryOut;

    ReplayQueueIndexPath headPtr;
    ReplayQueueIndexPath tailPtr;
    logic full;
    logic empty;

    // Input instructions are pushed when
    // some of these are valid.
    logic pushEntry;

    // Head instructions of ReplayQueue are poped unless
    // some loads of these are valid,
    // have allocated MSHR entries and
    // these MSHR entries have not receive data yet.
    logic popEntry;

    // To accept all instructions which must be pushed to ReplayQueue,
    // schedule and issue stage must stall when ReplayQueue is "almost" full.
    // The threshold is REPLAY_QUEUE_ENTRY_NUM - ISSUE_QUEUE_MEM_LATENCY
    // because ISSUE_QUEUE_MEM_LATENCY entries will pushed to ReplayQueue at most
    // after schedule and issue stage stall.
    logic almostFull;
    ReplayQueueCountPath count;

    // size, initial head, initial tail, initial count
    QueuePointerWithEntryCount #( REPLAY_QUEUE_ENTRY_NUM, 0, 0, 0 )
        pointer(
            .clk( port.clk ),
            .rst( port.rst ),
            .push( pushEntry ),
            .pop( popEntry ),
            .full( full ),
            .empty( empty ),
            .headPtr( headPtr ),
            .tailPtr( tailPtr ),
            .count ( count )
    );

    DistributedDualPortRAM #(
        .ENTRY_NUM( 1 << REPLAY_QUEUE_ENTRY_NUM_BIT_WIDTH ),
        .ENTRY_BIT_SIZE( $bits(ReplayQueueEntry) )
    ) replayQueue (
        .clk(port.clk),
        .we(pushEntry),
        .wa(tailPtr),
        .wv(recordData),
        .ra(headPtr),
        .rv(replayEntryOut)
    );

    // Recovery format
    logic recoveryFromCmStage;
    logic recoveryFromRwStage;

    // Valid information in replay queue
    logic replayEntryValidIn;
    logic replayEntryValidOut;

    logic noValidInst;
    ReplayQueueCountPath validInstCount;
    ReplayQueueCountPath validInstCountNext;

    ReplayQueueIntervalPath intervalIn;
    ReplayQueueIntervalPath nextIntervalIn;
    ReplayQueueIntervalPath intervalCount;
    ReplayQueueIntervalPath nextIntervalCount;

    // Flushed Op detection
    ReplayQueueCountPath canBeFlushedEntryCount;    //FlushedOpが存在している可能性があるエントリの個数
    ActiveListIndexPath flushRangeHeadPtr;  //フラッシュされた命令の範囲のhead
    ActiveListIndexPath flushRangeTailPtr;  //フラッシュされた命令の範囲のtail
    logic flushInt[ INT_ISSUE_WIDTH ];
    logic flushMem[ MEM_ISSUE_WIDTH ];
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    logic flushComplex[ COMPLEX_ISSUE_WIDTH ];
`endif

    // Outputs are pipelined for timing optimization.
    // "replay" signal is in a critical path.
    ReplayQueueEntry replayEntryReg;   // Don't care except valid bits.
    ReplayQueueEntry nextReplayEntry;
    logic replayReg;
    logic nextReplay;

    // State of MSHR
    logic [MEM_ISSUE_WIDTH-1 : 0] mshrNotReady;
    logic [MEM_ISSUE_WIDTH-1 : 0] mshrAddrSubsetMatch;
    logic [MEM_ISSUE_WIDTH-1 : 0] targetMSHRValid;
    MSHR_IndexPath mshrID[MEM_ISSUE_WIDTH];

    logic mshrValid[MSHR_NUM];
    MSHR_Phase mshrPhase[MSHR_NUM]; // MSHR phase.
    DCacheIndexSubsetPath mshrAddrSubset[MSHR_NUM];
    logic mshrMakeMSHRCanBeInvalidByReplayQueue[MSHR_NUM];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        replayEntryReg = '0;
    end
`endif

    always_comb begin
        recoveryFromRwStage = recovery.toRecoveryPhase && recovery.recoveryFromRwStage;
        recoveryFromCmStage = recovery.toRecoveryPhase && !recovery.recoveryFromRwStage;
    end

    always_ff @ (posedge port.clk) begin
        if (port.rst) begin
            replayEntryReg.intValid <= '0;
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            replayEntryReg.complexValid <= '0;
`endif
            replayEntryReg.memValid <= '0;
            replayReg <= '0;
            intervalIn <= '0;
            intervalCount <= '0;
        end
        else begin
            replayEntryReg <= nextReplayEntry;
            replayReg <= nextReplay;
            intervalIn <= nextIntervalIn;
            intervalCount <= nextIntervalCount;
        end
    end

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            validInstCount <= 0;
        end
        else begin
            validInstCount <= validInstCountNext;
        end
    end

    always_comb begin
        // Count how many valid instruction in replay queue
        noValidInst = (validInstCount == 0) ? TRUE : FALSE;

        validInstCountNext = validInstCount;
        if (pushEntry && replayEntryValidIn) begin
            validInstCountNext++;
        end

        if (popEntry && replayEntryValidOut) begin
            validInstCountNext--;
        end
    end

    always_comb begin
        // Set MSHR state
        for (int i = 0; i < MSHR_NUM; i++) begin
            mshrValid[i] = mshr.mshrValid[i];
            mshrPhase[i] = mshr.mshrPhase[i];
            mshrAddrSubset[i] = mshr.mshrAddrSubset[i];
        end

        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            mshrID[i] = replayEntryOut.memData[i].memOpInfo.mshrID;
        end
    end

    always_comb begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            if (port.rst) begin
                mshrNotReady[i] = FALSE;
            end
            else begin
                mshrNotReady[i] = 
                    (mshrPhase[mshrID[i]] < MSHR_PHASE_MISS_WRITE_CACHE_REQUEST) ? TRUE : FALSE;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            if (port.rst) begin
                targetMSHRValid[i] = FALSE;
            end
            else begin
                targetMSHRValid[i] = (mshrValid[mshrID[i]]) ? TRUE : FALSE;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            if (port.rst) begin
                mshrAddrSubsetMatch[i] = FALSE;
            end
            else begin
                mshrAddrSubsetMatch[i] = 
                    (mshrAddrSubset[mshrID[i]] == replayEntryOut.memAddrSubset[i]) ? TRUE : FALSE;
            end
        end
    end

    always_comb begin
        nextIntervalIn = intervalIn;
        if (pushEntry) begin
            nextIntervalIn = '0;
        end
        else if (intervalIn < REPLAY_QUEUE_MAX_INTERVAL) begin
            nextIntervalIn++;
        end
    end

    always_comb begin
        nextIntervalCount = intervalCount;
        if (popEntry) begin
            nextIntervalCount = '0;
        end
        else if (intervalCount < REPLAY_QUEUE_MAX_INTERVAL) begin
            nextIntervalCount++;
        end
    end

    always_comb begin

        // To a write port.
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            recordData.intValid[i] = port.intRecordEntry[i];
            recordData.intData[i] = port.intRecordData[i];
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            recordData.complexValid[i] = port.complexRecordEntry[i];
            recordData.complexData[i] = port.complexRecordData[i];
        end
`endif
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            recordData.memValid[i] = port.memRecordEntry[i];
            recordData.memData[i] = port.memRecordData[i];
            recordData.memAddrHit[i] = port.memRecordAddrHit[i];
            recordData.memAddrSubset[i] = port.memRecordAddrSubset[i];
        end
        recordData.replayInterval = intervalIn;


        if (port.rst) begin
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                recordData.intValid[i] = FALSE;
            end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                recordData.complexValid[i] = FALSE;
            end
`endif
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                recordData.memValid[i] = FALSE;
            end
            recordData.replayInterval = '0;
        end


        if (port.rst) begin
            replayEntryValidIn = FALSE;
        end
        else begin
            replayEntryValidIn = FALSE;
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                if (recordData.intValid[i]) begin
                    replayEntryValidIn = TRUE;
                end
            end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                if (recordData.complexValid[i]) begin
                    replayEntryValidIn = TRUE;
                end
            end
`endif
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                if (recordData.memValid[i]) begin
                    replayEntryValidIn = TRUE;
                end
            end
        end

        if (port.rst) begin
            replayEntryValidOut = FALSE;
        end
        else begin
            replayEntryValidOut = FALSE;
            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                if (replayEntryOut.intValid[i]) begin
                    replayEntryValidOut = TRUE;
                end
            end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                if (replayEntryOut.complexValid[i]) begin
                    replayEntryValidOut = TRUE;
                end
            end
`endif
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                if (replayEntryOut.memValid[i]) begin
                    replayEntryValidOut = TRUE;
                end
            end
        end


        // To an input of ReplayQueue.
        if (port.rst) begin
            pushEntry = FALSE;
        end
        else if (full) begin
            pushEntry = FALSE;
        end
        else if (~replayEntryValidIn && noValidInst) begin
            // RQに有効な命令が無く，入力も有効ではないときは何もpushしない
            pushEntry = FALSE;
        end
        else begin
            pushEntry = FALSE;

            for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
                if (recordData.intValid[i]) begin
                    pushEntry = TRUE;
                end
            end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
                if (recordData.complexValid[i]) begin
                    pushEntry = TRUE;
                end
            end
`endif
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                if (recordData.memValid[i]) begin
                    pushEntry = TRUE;
                end
            end
        end

        // To an output of ReplayQueue
        if (port.rst) begin
            popEntry = FALSE;
        end
        else if (empty) begin
            popEntry = FALSE;
        end
        else if (intervalCount < replayEntryOut.replayInterval) begin
            popEntry = FALSE;
        end
        else if (~replayEntryValidOut) begin
            // RQの先頭命令が無効なら必ずpopする　
            popEntry = TRUE;
        end
        else begin
            popEntry = TRUE;
            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                if (replayEntryOut.memValid[i] &&
                    (replayEntryOut.memData[i].memOpInfo.opType
                        inside { MEM_MOP_TYPE_LOAD }) && // the load is valid,
                    replayEntryOut.memData[i].memOpInfo.hasAllocatedMSHR && // has allocated MSHR entries,
                    mshrNotReady[i] // the corresponding MSHR entry has not receive data yet.
                ) begin
                    popEntry = FALSE;
                end
            end

            for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
                if (replayEntryOut.memValid[i] &&
                    (replayEntryOut.memData[i].memOpInfo.opType
                        inside { MEM_MOP_TYPE_LOAD }) && // the load is valid,
                    replayEntryOut.memAddrHit[i] && // has hit a MSHR entry,
                    targetMSHRValid[i] && // the MSHR entry is valid
                    mshrAddrSubsetMatch[i] && // the MSHR entry still has corresponding request,
                    mshrNotReady[i] // the corresponding MSHR entry has not receive data yet.
                ) begin
                    popEntry = FALSE;
                end
`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                else if (
                    replayEntryOut.memValid[i] &&
                    replayEntryOut.memData[i].memOpInfo.opType == MEM_MOP_TYPE_DIV &&
                    mulDivUnit.divBusy[i]
                ) begin
                    popEntry = FALSE;
                end
`endif
            end
            
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin 
                if (replayEntryOut.complexValid[i] && 
                    replayEntryOut.complexData[i].opType == COMPLEX_MOP_TYPE_DIV && 
                    mulDivUnit.divBusy[i]   // Div unit is busy and wait it
                ) begin 
                    // Div interlock (stop issuing div while there is 
                    // any divs in the complex pipeline including replay queue)
                    popEntry = FALSE; 
                end 
            end 
`endif
        end

        // To stall upper stages.
        if (count >= (REPLAY_QUEUE_ENTRY_NUM - ISSUE_QUEUE_MEM_LATENCY)) begin
            almostFull = TRUE;
        end
        else begin
            almostFull = FALSE;
        end


        // To an output register.
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            nextReplayEntry.intValid[i] = popEntry && replayEntryOut.intValid[i];
            nextReplayEntry.intData[i] = replayEntryOut.intData[i];
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            nextReplayEntry.complexValid[i] = popEntry && replayEntryOut.complexValid[i];
            nextReplayEntry.complexData[i] = replayEntryOut.complexData[i];
        end
`endif
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            nextReplayEntry.memValid[i] = popEntry && replayEntryOut.memValid[i];
            nextReplayEntry.memData[i] = replayEntryOut.memData[i];
            nextReplayEntry.memAddrHit[i] = replayEntryOut.memAddrHit[i];
            nextReplayEntry.memAddrSubset[i] = replayEntryOut.memAddrSubset[i];
        end

        nextReplayEntry.replayInterval = replayEntryOut.replayInterval;
        nextReplay = (popEntry && replayEntryValidOut) ? TRUE : FALSE;

        // To an issue queue.
        // Flushed op is detected here.
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            flushInt[i] = SelectiveFlushDetector(
                            canBeFlushedEntryCount != 0,
                            flushRangeHeadPtr,
                            flushRangeTailPtr,
                            replayEntryReg.intData[i].activeListPtr
                            );
            port.intReplayEntry[i] = replayEntryReg.intValid[i] && !flushInt[i];
            port.intReplayData[i] = replayEntryReg.intData[i];
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            flushComplex[i] = SelectiveFlushDetector(
                                canBeFlushedEntryCount != 0,
                                flushRangeHeadPtr,
                                flushRangeTailPtr,
                                replayEntryReg.complexData[i].activeListPtr
                                );
            port.complexReplayEntry[i] = replayEntryReg.complexValid[i] && !flushComplex[i];
            port.complexReplayData[i] = replayEntryReg.complexData[i];
        end
`endif
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            flushMem[i] = SelectiveFlushDetector(
                            canBeFlushedEntryCount != 0,
                            flushRangeHeadPtr,
                            flushRangeTailPtr,
                            replayEntryReg.memData[i].activeListPtr
                            );
            port.memReplayEntry[i] = replayEntryReg.memValid[i] && !flushMem[i];
            port.memReplayData[i] = replayEntryReg.memData[i];
        end

        // MSHR can be invalid when its allocator load is flushed at ReplayQueue.
        for (int i = 0; i < MSHR_NUM; i++) begin
            mshrMakeMSHRCanBeInvalidByReplayQueue[i] = FALSE;
        end

        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            if (replayEntryReg.memValid[i] && replayEntryReg.memData[i].memOpInfo.hasAllocatedMSHR && flushMem[i]) begin
                mshrMakeMSHRCanBeInvalidByReplayQueue[replayEntryReg.memData[i].memOpInfo.mshrID] = TRUE;
            end
        end

        for (int i = 0; i < MSHR_NUM; i++) begin
            mshr.makeMSHRCanBeInvalidByReplayQueue[i] = mshrMakeMSHRCanBeInvalidByReplayQueue[i];
        end


        // Stall issue and schedule stages
        // when ReplayQueue issues or
        // its #entries exceeds the threshold.
        ctrl.isStageStallUpper = replayReg | almostFull;
        port.replay = replayReg;

    end

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            canBeFlushedEntryCount <= 0;
        end
        else if (recoveryFromRwStage || recoveryFromCmStage) begin
            canBeFlushedEntryCount <= count;
            flushRangeHeadPtr <= recovery.flushRangeHeadPtr;
            flushRangeTailPtr <= recovery.flushRangeTailPtr;
        end
        else if (canBeFlushedEntryCount > 0 && port.replay) begin
            canBeFlushedEntryCount <= canBeFlushedEntryCount - 1;
        end
    end

    always_comb begin
        recovery.replayQueueFlushedOpExist = (canBeFlushedEntryCount != 0);
    end

endmodule : ReplayQueue
// ---- Scheduler/WakeupSelectIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Interface for wakeup/select loop
//

import BasicTypes::*;
import SchedulerTypes::*;

interface WakeupSelectIF( input logic clk, rst, rstStart );

    logic stall;

    // write data of dispatch
    logic write [ DISPATCH_WIDTH ];
    IssueQueueIndexPath writePtr [ DISPATCH_WIDTH ];
    SchedulerSrcTag writeSrcTag [ DISPATCH_WIDTH ];
    SchedulerDstTag writeDstTag [ DISPATCH_WIDTH ];

    // WakeupPipelineRegister -> DestinationRAM
    logic wakeup[ WAKEUP_WIDTH ];
    IssueQueueIndexPath wakeupPtr[ WAKEUP_WIDTH + STORE_ISSUE_WIDTH ];
    IssueQueueOneHotPath wakeupVector[ WAKEUP_WIDTH + STORE_ISSUE_WIDTH ];

    // DestinationRAM -> WakeupLogic
    // In matrix based implementation, wakeupDstTag is used only for dispatch and
    // DestinationRAM is out of its critical path.
    SchedulerDstTag wakeupDstTag [ WAKEUP_WIDTH ];

    // WakeupLogic -> SelectLogic
    IssueQueueOneHotPath opReady;

    // SelectLogic -> WakeupPipelineRegister
    logic selected [ ISSUE_WIDTH ];
    IssueQueueIndexPath selectedPtr [ ISSUE_WIDTH ];
    IssueQueueOneHotPath selectedVector [ ISSUE_WIDTH ];


    // Release issue queue entries.
    logic releaseEntry[ ISSUE_WIDTH ];
    IssueQueueIndexPath releasePtr[ISSUE_WIDTH];

    // Memory dependent predict
    logic memDependencyPred [DISPATCH_WIDTH];
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] notIssued; 
    logic dispatchStore[DISPATCH_WIDTH];
    logic dispatchLoad[DISPATCH_WIDTH];

    // Issue requests to select logic.
    // The select logic selects ops by this requests and readiness information.
    logic intIssueReq[ISSUE_QUEUE_ENTRY_NUM];
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    logic complexIssueReq[ISSUE_QUEUE_ENTRY_NUM];
`endif
    logic loadIssueReq[ISSUE_QUEUE_ENTRY_NUM];
    logic storeIssueReq[ISSUE_QUEUE_ENTRY_NUM];


    // A scheduler module is entrance of a wakeup/select logic.
    modport Scheduler(
    input
        selected,
        selectedPtr,
        selectedVector,
    output
        stall,
        write,
        writePtr,
        writeSrcTag,
        writeDstTag,
        intIssueReq,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexIssueReq,
`endif
        loadIssueReq,
        storeIssueReq,
        notIssued,
        dispatchStore,
        dispatchLoad,
        memDependencyPred
    );

    modport DestinationRAM(
    input
        clk,
        rst,
        rstStart,
        write,
        writePtr,
        writeDstTag,
        wakeupPtr,
    output
        wakeupDstTag
    );

    modport WakeupLogic(
    input
        clk,
        rst,
        rstStart,
        stall,
        write,
        writePtr,
        writeSrcTag,
        writeDstTag,
        wakeup,
        wakeupDstTag,
        wakeupVector,
        notIssued,
        dispatchStore,
        dispatchLoad,
        memDependencyPred,
    output
        opReady
    );

    modport SelectLogic(
    input
        opReady,
        intIssueReq,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexIssueReq,
`endif
        loadIssueReq,
        storeIssueReq,
    output
        selected,
        selectedPtr,
        selectedVector
    );

    modport WakeupPipelineRegister(
    input
        clk,
        rst,
        stall,
        selected,
        selectedPtr,
        selectedVector,
    output
        wakeup,
        wakeupPtr,
        wakeupVector,
        releaseEntry,
        releasePtr
    );

    modport IssueQueue(
    input
        releaseEntry,
        releasePtr
    );


endinterface : WakeupSelectIF


// ---- Scheduler/DestinationRAM.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Scheduler::DestinationRAM
// DestinationRAM is a table that has destination register numbers.
// It is looked up with the id of a woke up op in the IQ.
//

import BasicTypes::*;
import SchedulerTypes::*;

module DestinationRAM (WakeupSelectIF.DestinationRAM port);

    //
    // Destination register number
    //

    typedef struct packed // Entry
    {
        SchedulerRegTag  regTag;
    } Entry;

    logic write[DISPATCH_WIDTH];
    IssueQueueIndexPath writePtr[DISPATCH_WIDTH];
    Entry writeData[DISPATCH_WIDTH];
    IssueQueueIndexPath readPtr[WAKEUP_WIDTH];
    Entry readData[WAKEUP_WIDTH];

    DistributedMultiPortRAM #(
        .ENTRY_NUM( ISSUE_QUEUE_ENTRY_NUM ),
        .ENTRY_BIT_SIZE( $bits(Entry) ),
        .READ_NUM( WAKEUP_WIDTH ),
        .WRITE_NUM( DISPATCH_WIDTH )
    ) dstRAM (
        .clk( port.clk ),
        .we( write ),
        .wa( writePtr ),
        .wv( writeData ),
        .ra( readPtr ),
        .rv( readData )
    );

    IssueQueueIndexPath rstIndex;
    always_ff @ (posedge port.clk) begin
        if (port.rstStart || rstIndex >= ISSUE_QUEUE_ENTRY_NUM-1) begin
            rstIndex <= 0;
        end
        else begin
            rstIndex <= rstIndex + 1;
        end
    end

    always_comb begin
        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            write[i] = port.write[i];
            writePtr[i] = port.writePtr[i];
            writeData[i].regTag = port.writeDstTag[i].regTag;
        end

        for (int i = 0; i < WAKEUP_WIDTH; i++) begin
            port.wakeupDstTag[i].regTag = readData[i].regTag;
        end

        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            readPtr[i] = port.wakeupPtr[i];
        end
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            readPtr[(i+INT_ISSUE_WIDTH)] = port.wakeupPtr[(i+INT_ISSUE_WIDTH)];
        end
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            readPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = port.wakeupPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)];
        end
        // Stores do not wake up consumers.


        // Reset sequence.
        if (port.rst) begin
            for (int i = 0; i < DISPATCH_WIDTH; i++) begin
                write[i] = FALSE;
            end
            write[0] = TRUE;
            writePtr[0] = rstIndex;
            writeData[0] = '0;
        end
    end

endmodule : DestinationRAM



// ---- Scheduler/ReadyBitTable.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Ready bit table.
// This table is used for checking already ready source operands on dispatch.
//
`ifndef REF
    `define REF ref
`endif

import BasicTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import MicroOpTypes::*;


module ReadyBitTable #(
    parameter SRC_OP_NUM = 2,
    parameter REG_NUM_BIT_WIDTH = 5,
    parameter ENTRY_NUM = 32
)(
    // input
    input   logic clk, rst, rstStart, stall,
    input   logic wakeup[ WAKEUP_WIDTH ],
    input   logic wakeupDstValid [ WAKEUP_WIDTH ],
    input   logic [REG_NUM_BIT_WIDTH-1:0] wakeupDstRegNum [ WAKEUP_WIDTH ],
    input   logic dispatch[ DISPATCH_WIDTH ],
    input   logic dispatchedDstValid [ DISPATCH_WIDTH ],
    input   logic [REG_NUM_BIT_WIDTH-1:0] dispatchedDstRegNum [ DISPATCH_WIDTH ],
    input   logic dispatchedSrcValid [ DISPATCH_WIDTH ][ SRC_OP_NUM ],
    input   logic [REG_NUM_BIT_WIDTH-1:0] dispatchedSrcRegNum [ DISPATCH_WIDTH ][ SRC_OP_NUM ],
    // output
    output  logic dispatchedSrcReady[ DISPATCH_WIDTH ][ SRC_OP_NUM ]
);

    localparam READY_WRITE_NUM = WAKEUP_WIDTH + DISPATCH_WIDTH;
    localparam READY_READ_NUM = DISPATCH_WIDTH * SRC_OP_NUM;

    typedef logic [REG_NUM_BIT_WIDTH-1:0] RegNumPath;

    logic readyWE[READY_WRITE_NUM];
    logic readyWV[READY_WRITE_NUM];
    RegNumPath readyWA[READY_WRITE_NUM];
    logic readyRV[READY_READ_NUM];
    RegNumPath readyRA[READY_READ_NUM];

    DistributedMultiPortRAM #(
        1 << REG_NUM_BIT_WIDTH, 1, READY_READ_NUM, READY_WRITE_NUM
    )
    radyBitTable(clk, readyWE, readyWA, readyWV, readyRA, readyRV);


    RegNumPath resetIndex;

    always_ff @(posedge clk) begin
        if(rstStart) begin
            resetIndex <= 0;
        end
        else begin
            resetIndex <= resetIndex + 1;
        end
    end

    always_comb begin

        for (int i = 0; i < WAKEUP_WIDTH; i++) begin
            readyWA[i] = wakeupDstRegNum[i];
            readyWV[i] = TRUE;
            readyWE[i] = !stall && (wakeup[i] && wakeupDstValid[i]);
            //if(wakeup[i] && wakeupDstValid[i]) begin
            //    ready[ wakeupDstRegNum[i] ] <= TRUE;
        end

        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            readyWA[i+WAKEUP_WIDTH] = dispatchedDstRegNum[i];
            readyWV[i+WAKEUP_WIDTH] = FALSE;
            readyWE[i+WAKEUP_WIDTH] = (dispatch[i] && dispatchedDstValid[i]);
            //if( dispatch[i] && dispatchedDstValid[i] ) begin
            //    ready[ dispatchedDstRegNum[i] ] <= FALSE;
        end


        // On reset, all entries are set to be ready.
        // On flush, the ready bits are treated in the same way as the reset
        //  case because all allocated entries are ready and non-allocated
        // entries are never referred after flush.
        if (rst) begin

            // In a reset phase, indefinite signals may reach and destroy initialized ready bits.
            for (int i = 0; i < READY_WRITE_NUM; i++) begin
                readyWE[i] = FALSE;
            end

            // A write port 0 is used for reset.
            readyWA[0] = resetIndex;
            readyWV[0] = TRUE;
            readyWE[0] = TRUE;
        end


        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            for (int j = 0; j < SRC_OP_NUM; j++) begin

                readyRA[i*SRC_OP_NUM + j] = dispatchedSrcRegNum[i][j];

                if ( dispatchedSrcValid[i][j] == FALSE ) begin
                    dispatchedSrcReady[i][j] = TRUE;
                end
                else begin
                    //dispatchedSrcReady[i][j] = ready[ dispatchedSrcRegNum[i][j] ];
                    dispatchedSrcReady[i][j] = readyRV[i*SRC_OP_NUM + j];

                    // Bypass wakeup signals.
                    for (int k = 0; k < WAKEUP_WIDTH; k++) begin
                        if (wakeup[k] &&
                            wakeupDstValid[k] &&
                            wakeupDstRegNum[k] == dispatchedSrcRegNum[i][j]
                        ) begin
                            dispatchedSrcReady[i][j] = TRUE;
                        end
                    end

                    // Bypass dispatched instruction's destination registers
                    for (int k = 0; k < i; k++) begin
                        if (dispatch[k] &&
                            dispatchedDstValid[k] &&
                            dispatchedSrcRegNum[i][j] == dispatchedDstRegNum[k]
                        ) begin
                            dispatchedSrcReady[i][j] = FALSE;
                        end
                    end
                end
            end
        end
    end

endmodule : ReadyBitTable

// ---- Scheduler/Scheduler.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Schedule
//

import BasicTypes::*;
import SchedulerTypes::*;
import MicroOpTypes::*;

module Scheduler(
    SchedulerIF.Scheduler port,
    WakeupSelectIF.Scheduler wakeupSelect,
    RecoveryManagerIF.Scheduler recovery,
    MulDivUnitIF.Scheduler mulDivUnit,
    DebugIF.Scheduler debug
);

    // A flag that indicates a not-issued state.
    // This flag contains the validness of each entry.
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] notIssued;

    // The type of an op in each entry.
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] isInt;
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] isComplex;
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] isDiv;
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] isLoad;
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] isStore;

    IssueQueueOneHotPath flushIQ_Entry;

    IssueQueueOneHotPath selectedVector;

    logic dispatchStore[DISPATCH_WIDTH];
    logic dispatchLoad[DISPATCH_WIDTH];
    logic canIssueDiv;

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        isInt = '0;
        isComplex = '0;
        isDiv = '0;
        isLoad = '0;
        isStore = '0;
    end
`endif

    always_ff @(posedge port.clk) begin
        if(port.rst) begin
            // Reset or recovery is necessary only for notIssued flags.
            for(int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
                notIssued[i] <= FALSE;
            end
        end
        else begin

            // Dispatch
            for (int i = 0; i < DISPATCH_WIDTH; i++) begin
                if( port.write[i] ) begin
                    notIssued[ port.writePtr[i] ] <= TRUE;

                    if (port.writeSchedulerData[i].opType == MOP_TYPE_MEM) begin
                        if (port.writeSchedulerData[i].opSubType.memType == MEM_MOP_TYPE_STORE) begin
                            // This port cannot access the data cache.
                            isLoad[ port.writePtr[i] ] <= FALSE;
                            isStore[ port.writePtr[i] ] <= TRUE;
                            isComplex[ port.writePtr[i] ] <= FALSE;
                            isInt[ port.writePtr[i] ] <= FALSE;
                            isDiv[ port.writePtr[i] ] <= FALSE;
                        end
                        else begin
                            `ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                                isComplex[ port.writePtr[i] ] <= 
                                    port.writeSchedulerData[i].opSubType.memType inside {
                                        MEM_MOP_TYPE_MUL, MEM_MOP_TYPE_DIV
                                    };
                                isDiv[ port.writePtr[i] ] <= 
                                    port.writeSchedulerData[i].opSubType.memType inside {
                                        MEM_MOP_TYPE_DIV
                                    };
                                isLoad[ port.writePtr[i] ] <= 
                                    !(port.writeSchedulerData[i].opSubType.memType inside {
                                        MEM_MOP_TYPE_MUL, MEM_MOP_TYPE_DIV
                                    });
                            `else
                                isDiv[ port.writePtr[i] ] <= FALSE;
                                isComplex[ port.writePtr[i] ] <= FALSE;
                                isLoad[ port.writePtr[i] ] <= TRUE;
                            `endif
                            isStore[ port.writePtr[i] ] <= FALSE;
                            isInt[ port.writePtr[i] ] <= FALSE;
                        end
                    end
                    else if (port.writeSchedulerData[i].opType == MOP_TYPE_COMPLEX) begin
                        if (port.writeSchedulerData[i].opSubType.complexType ==
                            COMPLEX_MOP_TYPE_DIV) begin
                            isLoad[ port.writePtr[i] ] <= FALSE;
                            isStore[ port.writePtr[i] ] <= FALSE;
                            isComplex[ port.writePtr[i] ] <= TRUE;
                            isInt[ port.writePtr[i] ] <= FALSE;
                            isDiv[ port.writePtr[i] ] <= TRUE;
                        end
                        else begin
                            isLoad[ port.writePtr[i] ] <= FALSE;
                            isStore[ port.writePtr[i] ] <= FALSE;
                            isComplex[ port.writePtr[i] ] <= TRUE;
                            isInt[ port.writePtr[i] ] <= FALSE;
                            isDiv[ port.writePtr[i] ] <= FALSE;
                        end
                    end
                    else begin
                        isLoad[ port.writePtr[i] ] <= FALSE;
                        isStore[ port.writePtr[i] ] <= FALSE;
                        isComplex[ port.writePtr[i] ] <= FALSE;
                        isInt[ port.writePtr[i] ] <= TRUE;
                        isDiv[ port.writePtr[i] ] <= FALSE;
                    end
                end
            end

            // Select & issue & flush at recovery
            for (int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
                if (selectedVector[i] || flushIQ_Entry[i]) begin
                    notIssued[i] <= FALSE;
                end
            end
        end
    end
    


    always_comb begin

        // Generate ld/st inst dispatch information for making store bit vector at producer.
        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            if ( port.write[i] ) begin
                if (port.writeSchedulerData[i].opType == MOP_TYPE_MEM) begin
                    if (port.writeSchedulerData[i].opSubType.memType == MEM_MOP_TYPE_STORE) begin
                        // Dispatch store
                        dispatchStore[i] = TRUE;
                        dispatchLoad[i] = FALSE;
                    end
                    else begin
                        // Dispatch load
                        dispatchStore[i] = FALSE;
                        dispatchLoad[i] = TRUE;
                    end
                end
                else begin
                    // Not dispatch ld/st inst.
                    dispatchStore[i] = FALSE;
                    dispatchLoad[i] = FALSE;
                end
            end
            else begin
                // Not dispatch inst.
                dispatchStore[i] = FALSE;
                dispatchLoad[i] = FALSE;
            end
        end

        // Connect dispatch/IQ info to IF
        wakeupSelect.dispatchStore = dispatchStore;
        wakeupSelect.dispatchLoad = dispatchLoad;
        wakeupSelect.notIssued = notIssued;

        // Controll logic
        wakeupSelect.stall = port.stall;

        // Dispatch
        wakeupSelect.write = port.write;
        wakeupSelect.writePtr = port.writePtr;

        wakeupSelect.memDependencyPred = port.memDependencyPred;

        flushIQ_Entry = recovery.flushIQ_Entry;
        recovery.notIssued = notIssued;

        for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
            // wakeupSelect.writeSrcTag
            wakeupSelect.writeSrcTag[i].regTag[0].valid = port.writeSchedulerData[i].srcRegValidA;
            wakeupSelect.writeSrcTag[i].regTag[1].valid = port.writeSchedulerData[i].srcRegValidB;
            wakeupSelect.writeSrcTag[i].regTag[0].num = port.writeSchedulerData[i].opSrc.phySrcRegNumA;
            wakeupSelect.writeSrcTag[i].regTag[1].num = port.writeSchedulerData[i].opSrc.phySrcRegNumB;

            // wakeupSelect.writeSrcTag
            wakeupSelect.writeDstTag[i].regTag.valid = port.writeSchedulerData[i].opDst.writeReg;
            wakeupSelect.writeDstTag[i].regTag.num = port.writeSchedulerData[i].opDst.phyDstRegNum;

            // Source pointers to a matrix.
            wakeupSelect.writeSrcTag[i].regPtr[0].valid = port.writeSchedulerData[i].srcRegValidA;
            wakeupSelect.writeSrcTag[i].regPtr[1].valid = port.writeSchedulerData[i].srcRegValidB;

            wakeupSelect.writeSrcTag[i].regPtr[0].ptr = port.writeSchedulerData[i].srcPtrRegA;
            wakeupSelect.writeSrcTag[i].regPtr[1].ptr = port.writeSchedulerData[i].srcPtrRegB;

        end

        // Check whether div can be issued
        // For stop issuing div according to the status of the divider
        canIssueDiv = TRUE;
        for (int i = 0; i < MULDIV_ISSUE_WIDTH; i++) begin
            if (!mulDivUnit.divFree[i]) begin
                canIssueDiv = FALSE;    // Currently, only a single div can be issued 
            end
        end

        // Select
        for(int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
            wakeupSelect.intIssueReq[i] = notIssued[i] && isInt[i];
`ifdef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            wakeupSelect.loadIssueReq[i] = // mul/div is integrated into a load pipeline
                notIssued[i] && (
                    isLoad[i] || 
                    (isComplex[i] && (!isDiv[i] || (isDiv[i] && canIssueDiv)))
                );
`else
            wakeupSelect.loadIssueReq[i] = notIssued[i] && isLoad[i];
            wakeupSelect.complexIssueReq[i] = 
                notIssued[i] && isComplex[i] && (!isDiv[i] || (isDiv[i] && canIssueDiv));
`endif
            wakeupSelect.storeIssueReq[i] = notIssued[i] && isStore[i];
        end

        for ( int i = 0; i < ISSUE_WIDTH; i++ ) begin
            port.selected[i] = wakeupSelect.selected[i] && !port.stall;
            port.selectedPtr[i] = wakeupSelect.selectedPtr[i];
        end

        selectedVector = '0;
        if (!port.stall) begin
            for (int i = 0; i < ISSUE_WIDTH; i++) begin
                selectedVector |= wakeupSelect.selectedVector[i];
            end
        end


        // Debug Register
`ifndef RSD_DISABLE_DEBUG_REGISTER
        for ( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            debug.scheduler[i].valid = notIssued[i] && (isInt[i] || isComplex[i] || isLoad[i] || isStore[i]);
        end
`endif
    end

endmodule : Scheduler



// ---- Scheduler/SelectLogic.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Select logic
//

import BasicTypes::*;
import SchedulerTypes::*;



module SelectLogic(
    WakeupSelectIF.SelectLogic port,
    RecoveryManagerIF.SelectLogic recovery
);

    IssueQueueOneHotPath intRequest;
    IssueQueueOneHotPath intGrant;
    logic intSelected[ INT_ISSUE_WIDTH ];
    IssueQueueIndexPath intSelectedPtr[ INT_ISSUE_WIDTH ];

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    IssueQueueOneHotPath compRequest;
    IssueQueueOneHotPath compGrant;
    logic compSelected[ COMPLEX_ISSUE_WIDTH ];
    IssueQueueIndexPath compSelectedPtr[ COMPLEX_ISSUE_WIDTH ];
`endif

`ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
    IssueQueueOneHotPath memRequest;
    IssueQueueOneHotPath memGrant;
    logic memSelected[ MEM_ISSUE_WIDTH ];
    IssueQueueIndexPath memSelectedPtr[ MEM_ISSUE_WIDTH ];
`else
    IssueQueueOneHotPath loadRequest;
    IssueQueueOneHotPath storeRequest;
    IssueQueueOneHotPath loadGrant;
    IssueQueueOneHotPath storeGrant;
    logic loadSelected[ LOAD_ISSUE_WIDTH ];
    logic storeSelected[ STORE_ISSUE_WIDTH ];
    IssueQueueIndexPath loadSelectedPtr[ LOAD_ISSUE_WIDTH ];
    IssueQueueIndexPath storeSelectedPtr[ STORE_ISSUE_WIDTH ];
`endif


    // SelectLogic -> WakeupPipelineRegister
    logic portSelected [ ISSUE_WIDTH ];
    IssueQueueIndexPath portSelectedPtr [ ISSUE_WIDTH ];
    IssueQueueOneHotPath portSelectedVector [ ISSUE_WIDTH ];

    // For Recovery Maneger IF
    logic recoverySelected [ ISSUE_WIDTH ];
    IssueQueueIndexPath recoverySelectedPtr [ ISSUE_WIDTH ];

    // Requests are interleaved.
    // ex. ENTRY_NUM = 4, GRANT_NUM = 2 case:
    //   granted[0] = pick(req[0], req[2]);
    //   granted[0] = pick(req[1], req[3]);
    //
    // This makes its performance slightly worse, but reduces its complexity.
    InterleavedPicker #(
    //Picker #(
        .ENTRY_NUM(ISSUE_QUEUE_ENTRY_NUM),
        .GRANT_NUM(INT_ISSUE_WIDTH)
    )
    intPicker(
        .req(intRequest),
        .grant(intGrant),
        .grantPtr(intSelectedPtr),
        .granted(intSelected)
    );


`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    Picker #(
        .ENTRY_NUM(ISSUE_QUEUE_ENTRY_NUM),
        .GRANT_NUM(COMPLEX_ISSUE_WIDTH)
    )
    compPicker(
        .req(compRequest),
        .grant(compGrant),
        .grantPtr(compSelectedPtr),
        .granted(compSelected)
    );
`endif

`ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
    Picker #(
        .ENTRY_NUM(ISSUE_QUEUE_ENTRY_NUM),
        .GRANT_NUM(MEM_ISSUE_WIDTH)
    )
    storePicker(
        .req(memRequest),
        .grant(memGrant),
        .grantPtr(memSelectedPtr),
        .granted(memSelected)
    );
`else
    Picker #(
        .ENTRY_NUM(ISSUE_QUEUE_ENTRY_NUM),
        .GRANT_NUM(LOAD_ISSUE_WIDTH)
    )
    loadPicker(
        .req(loadRequest),
        .grant(loadGrant),
        .grantPtr(loadSelectedPtr),
        .granted(loadSelected)
    );
    Picker #(
        .ENTRY_NUM(ISSUE_QUEUE_ENTRY_NUM),
        .GRANT_NUM(STORE_ISSUE_WIDTH)
    )
    storePicker(
        .req(storeRequest),
        .grant(storeGrant),
        .grantPtr(storeSelectedPtr),
        .granted(storeSelected)
    );
`endif

    always_comb begin

        for (int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
            intRequest[i] = port.opReady[i] && port.intIssueReq[i];
            `ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
                memRequest[i] = port.opReady[i] && (port.loadIssueReq[i] || port.storeIssueReq[i]);
            `else
                loadRequest[i] = port.opReady[i] && port.loadIssueReq[i];
                storeRequest[i] = port.opReady[i] && port.storeIssueReq[i];
            `endif
            
            `ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
                compRequest[i] = port.opReady[i] && port.complexIssueReq[i];
            `endif
        end


        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            portSelected[i] = intSelected[i];
            portSelectedPtr[i] = intSelectedPtr[i];
            portSelectedVector[i] = intGrant;
            recoverySelected[i] = intSelected[i];
            recoverySelectedPtr[i] = intSelectedPtr[i];
        end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            portSelected[i+INT_ISSUE_WIDTH] = compSelected[i];
            portSelectedPtr[i+INT_ISSUE_WIDTH] = compSelectedPtr[i];
            portSelectedVector[i+INT_ISSUE_WIDTH] = compGrant;
            recoverySelected[i+INT_ISSUE_WIDTH] = compSelected[i];
            recoverySelectedPtr[i+INT_ISSUE_WIDTH] = compSelectedPtr[i];
        end
`endif

`ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            portSelected[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = memSelected[i];
            portSelectedPtr[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = memSelectedPtr[i];
            portSelectedVector[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = memGrant;
            recoverySelected[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = memSelected[i];
            recoverySelectedPtr[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = memSelectedPtr[i];
        end
`else
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            portSelected[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = loadSelected[i];
            portSelectedPtr[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = loadSelectedPtr[i];
            portSelectedVector[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = loadGrant;
            recoverySelected[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = loadSelected[i];
            recoverySelectedPtr[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH] = loadSelectedPtr[i];
        end
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            portSelected[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH+LOAD_ISSUE_WIDTH] = storeSelected[i];
            portSelectedPtr[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH+LOAD_ISSUE_WIDTH] = storeSelectedPtr[i];
            portSelectedVector[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH+LOAD_ISSUE_WIDTH] = storeGrant;
            recoverySelected[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH+LOAD_ISSUE_WIDTH] = storeSelected[i];
            recoverySelectedPtr[i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH+LOAD_ISSUE_WIDTH] = storeSelectedPtr[i];
        end
`endif

        port.selected = portSelected;
        port.selectedPtr = portSelectedPtr;
        port.selectedVector = portSelectedVector;
        recovery.selected = recoverySelected;
        recovery.selectedPtr = recoverySelectedPtr;
    end

endmodule : SelectLogic

// ---- Scheduler/SourceCAM.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Source Register CAM module for Wakeup Logic
//
`ifndef REF
    `define REF ref
`endif

import BasicTypes::*;
import SchedulerTypes::*;

// - Written:
// dispatch: A write enable signal for cam entries on dispatch.
// dispatchPtr: Write pointer (one-hot).
// dispatchedSrcRegNum: Written CAM entry data, which are physical register numbers of source operands.
// dispatchedSrcReady: True if written source operands are already ready
//                     or dispatch they are invalid in the instruction.
// - Wakeup:
// wakeupDstRegNum: A tag data for wakeup, which are physical register numbers of destination operands.
// opReady: Bit vector corresponding to an issue queue. Each bit indicates
// whether each entry is ready or not.

module SourceCAM #(
    parameter SRC_OP_NUM = 1,
    parameter REG_NUM_BIT_WIDTH = 1
)(
    // input
    input   logic clk, rst, stall,
    input   logic dispatch [ DISPATCH_WIDTH ],
    input   IssueQueueIndexPath dispatchPtr [ DISPATCH_WIDTH ],
    input   logic [REG_NUM_BIT_WIDTH-1:0] dispatchedSrcRegNum [ DISPATCH_WIDTH ][ SRC_OP_NUM ],
    input   logic dispatchedSrcReady [ DISPATCH_WIDTH ][ SRC_OP_NUM ],
    input   logic wakeup [ WAKEUP_WIDTH ],
    input   logic wakeupDstValid [ WAKEUP_WIDTH ],
    input   logic [REG_NUM_BIT_WIDTH-1:0] wakeupDstRegNum [ WAKEUP_WIDTH ],
    // output
    output     IssueQueueOneHotPath opReady

);
    typedef logic [REG_NUM_BIT_WIDTH-1:0] RegNumPath;

    // A bit array of a CAM wake-up logic rdyL / rdyR.
    logic srcReady[ ISSUE_QUEUE_ENTRY_NUM ][ SRC_OP_NUM ];
    logic nextSrcReady[ ISSUE_QUEUE_ENTRY_NUM ][ SRC_OP_NUM ];

    // # of source register : key entries of the CAM.
    RegNumPath srcRegNum[ ISSUE_QUEUE_ENTRY_NUM ][ SRC_OP_NUM ];

    // Match lines of CAM.
    logic match[ ISSUE_QUEUE_ENTRY_NUM ][ SRC_OP_NUM ];


    always_ff @( posedge clk ) begin
        // rdyL / rdyR
        for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            for( int j = 0; j < SRC_OP_NUM; j++ ) begin
                srcReady[i][j] <= ( rst ? FALSE : nextSrcReady[i][j] );
            end
        end

        if (rst) begin
            for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
                for( int j = 0; j < SRC_OP_NUM; j++ ) begin
                    srcRegNum[i][j] <= 0;
                end
            end
        end
        else begin
            // Dispatch
            for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
                if( dispatch[i] ) begin
                    for( int j = 0; j < SRC_OP_NUM; j++ ) begin
                        srcRegNum[ dispatchPtr[i] ][j] <= dispatchedSrcRegNum[i][j];
                    end
                end
            end
        end
    end

    always_comb begin
        // Tag match
        for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            for( int j = 0; j < SRC_OP_NUM; j++ ) begin
                match[i][j] = FALSE;
                // Test all broadcasted tags.
                for( int k = 0; k < WAKEUP_WIDTH; k++ ) begin
                    if ( wakeup[k] && wakeupDstValid[k] )
                        match[i][j] = match[i][j] || ( wakeupDstRegNum[k] == srcRegNum[i][j] );
                end
            end
        end

        // Output ready information of each op.
        for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            opReady[i] = TRUE;
            for( int j = 0; j < SRC_OP_NUM; j++ ) begin
                opReady[i] = opReady[i] && ( match[i][j] || srcReady[i][j] );
            end
        end

        // Set nextSrcReady
        for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            for( int j = 0; j < SRC_OP_NUM; j++ ) begin
                if (stall) begin
                    nextSrcReady[i][j] = srcReady[i][j];
                end
                else begin
                    nextSrcReady[i][j] = srcReady[i][j] || match[i][j];
                end
            end
        end
        for( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
            for ( int j = 0; j < SRC_OP_NUM; j++ ) begin
                if( dispatch[i] )
                    nextSrcReady[ dispatchPtr[i] ][j] = dispatchedSrcReady[i][j];    // Dispatch
            end
        end

    end


endmodule : SourceCAM

// ---- Scheduler/WakeupLogic.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// CAM based wakeup logic
//

import BasicTypes::*;
import SchedulerTypes::*;

// Use a matrix scheduler.
`define RSD_WAKEUP_MATRIX_SCHEDULER 1

module WakeupLogic (
    WakeupSelectIF.WakeupLogic port
);
    // Source status of dispatched instructions.
    logic dispatchedSrcRegValid  [ DISPATCH_WIDTH ][ ISSUE_QUEUE_SRC_REG_NUM ];

    PRegNumPath  dispatchedSrcRegNum  [ DISPATCH_WIDTH ][ ISSUE_QUEUE_SRC_REG_NUM ];

    // Destination status of dispatched instructions.
    logic dispatchedDstRegValid  [ DISPATCH_WIDTH ];

    PRegNumPath  dispatchedDstRegNum  [ DISPATCH_WIDTH ];

    // Destination status of wokeup instructions.
    logic wakeupDstRegValid  [ WAKEUP_WIDTH ];

    PRegNumPath  wakeupDstRegNum  [ WAKEUP_WIDTH ];

    // Connection between srcCAM and readyBitTbl
    logic dispatchedSrcRegReady[ DISPATCH_WIDTH ][ ISSUE_QUEUE_SRC_REG_NUM ];

    // Dependency matrix.
    IssueQueueOneHotPath wakeupDstVector[ WAKEUP_WIDTH + STORE_ISSUE_WIDTH ];
    IssueQueueIndexPath [ DISPATCH_WIDTH-1:0 ][ ISSUE_QUEUE_SRC_REG_NUM-1:0 ] dispatchedSrcRegPtr;
    logic opMatrixReady[ ISSUE_QUEUE_ENTRY_NUM ];

    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] dependStoreBitVector[DISPATCH_WIDTH];
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] storeBitVector;
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] storeBitVectorReg;

    logic dispatchStore[DISPATCH_WIDTH];
    logic dispatchLoad[DISPATCH_WIDTH];
    logic [ISSUE_QUEUE_ENTRY_NUM-1:0] notIssued;

    logic memDependencyPred[DISPATCH_WIDTH];

    //
    // Ready bit tables.
    //
    ReadyBitTable #(
        .SRC_OP_NUM( ISSUE_QUEUE_SRC_REG_NUM ),
        .REG_NUM_BIT_WIDTH( PREG_NUM_BIT_WIDTH ),
        .ENTRY_NUM( PREG_NUM )
    ) regReadyBitTbl (
        .clk( port.clk ),
        .rst( port.rst ),
        .rstStart( port.rstStart ),
        .stall( port.stall ),
        .wakeup( port.wakeup ),
        .wakeupDstValid( wakeupDstRegValid ),
        .wakeupDstRegNum( wakeupDstRegNum ),
        .dispatch( port.write ),
        .dispatchedDstValid( dispatchedDstRegValid ),
        .dispatchedDstRegNum( dispatchedDstRegNum ),
        .dispatchedSrcValid( dispatchedSrcRegValid ),
        .dispatchedSrcRegNum( dispatchedSrcRegNum ),
        .dispatchedSrcReady( dispatchedSrcRegReady  )
    );

    always_comb begin
        // Dispatch
        for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
            dispatchedDstRegValid[i]   = port.writeDstTag[i].regTag.valid;
            dispatchedDstRegNum[i]     = port.writeDstTag[i].regTag.num;

            for ( int j = 0; j < ISSUE_QUEUE_SRC_REG_NUM; j++ ) begin
                dispatchedSrcRegNum[i][j] = port.writeSrcTag[i].regTag[j].num;
                dispatchedSrcRegValid[i][j] = port.writeSrcTag[i].regTag[j].valid;
            end
        end

        // Wake up
        for ( int i = 0; i < WAKEUP_WIDTH; i++ ) begin
            wakeupDstRegValid[i]   = port.wakeupDstTag[i].regTag.valid;
            wakeupDstRegNum[i]     = port.wakeupDstTag[i].regTag.num;
        end
    end


`ifndef RSD_WAKEUP_MATRIX_SCHEDULER

    //
    // Source CAMs.
    //

    // Ready of each instruction
    IssueQueueOneHotPath opRegReady;

    // Wakeup Logic for registers.
    SourceCAM #(
        .SRC_OP_NUM( ISSUE_QUEUE_SRC_REG_NUM ),
        .REG_NUM_BIT_WIDTH( PREG_NUM_BIT_WIDTH )
    ) regSrcCAM (
        .clk( port.clk ),
        .rst( port.rst ),
        .stall( port.stall ),
        .dispatch( port.write ),
        .dispatchPtr( port.writePtr ),
        .dispatchedSrcRegNum( dispatchedSrcRegNum ),
        .dispatchedSrcReady( dispatchedSrcRegReady ),
        .wakeup( port.wakeup ),
        .wakeupDstValid( wakeupDstRegValid ),
        .wakeupDstRegNum( wakeupDstRegNum ),
        .opReady( opRegReady )
    );

    always_comb begin
        // Ready of each instruction
        for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            port.opReady[i] = opRegReady[i];
        end
    end

`else

    //
    // Wakeup Matrix.
    //

    // Wakeup dst valid は，無条件でビットを下ろしておけば良いのでいらない．
    ProducerMatrix producerMatrix(
        .clk( port.clk ),
        .stall( port.stall ),
        .dispatch( port.write ),
        .dispatchedSrcRegReady( dispatchedSrcRegReady ),
        .dispatchedSrcRegPtr( dispatchedSrcRegPtr ),
        .dependStoreBitVector ( dependStoreBitVector ),
        .dispatchPtr( port.writePtr ),
        .wakeupDstVector( wakeupDstVector ),
        .opReady(opMatrixReady)
    );

    always_ff @(posedge port.clk) begin
        // Update store bit vector register.
        if (port.rst) begin
            storeBitVectorReg <= 0;
        end
        else begin
            storeBitVectorReg <= storeBitVector;
        end
    end

    always_comb begin

        // Get logic from IF
        dispatchStore = port.dispatchStore;
        dispatchLoad = port.dispatchLoad;
        notIssued = port.notIssued;

        // Wakeup
        for (int w = 0; w < WAKEUP_WIDTH + STORE_ISSUE_WIDTH; w++) begin
            wakeupDstVector[w] = port.wakeupVector[w];
        end

        // Dispatch
        for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin

            for ( int j = 0; j < ISSUE_QUEUE_SRC_REG_NUM; j++ ) begin
                dispatchedSrcRegPtr[i][j] = port.writeSrcTag[i].regPtr[j].ptr;
            end
        end

        // Update store bit vector according to information about getting out from IQ.
        storeBitVector = storeBitVectorReg & notIssued;
        // Memory dependent prediction
        memDependencyPred = port.memDependencyPred;

        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            if (dispatchStore[i]) begin
                // Update store bit vector (Set the corresponding bit).
                dependStoreBitVector[i] = 0;
                storeBitVector[port.writePtr[i]] = TRUE;
            end
            else if (dispatchLoad[i] && memDependencyPred[i]) begin
                // Issue load inst speculatively according to memory dependent prediction.
                // Add store bit vector to the dependency destination bit.
                // This will be processed in Producer Matrix.
                dependStoreBitVector[i] = storeBitVector;
            end
            else begin
                // Reset store bit vector for which add dependency destination bit.
                dependStoreBitVector[i] = 0;
            end
        end


    end

    always_comb begin
        // Ready of each instruction
        for( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            port.opReady[i] = opMatrixReady[i]; // Matrix
        end
    end
`endif


endmodule : WakeupLogic
// ---- Scheduler/WakeupPipelineRegister.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Scheduler
//

import BasicTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import MicroOpTypes::*;

//
// Track issues ops. Tracked information is used for waking up and releasing entries.
//
module WakeupPipelineRegister(
    WakeupSelectIF.WakeupPipelineRegister port,
    RecoveryManagerIF.WakeupPipelineRegister recovery
);

    // Pipeline registers
    typedef struct packed
    {
        logic valid;              // Valid flag.
        IssueQueueIndexPath ptr;  // A pointer to a selected entry.
        IssueQueueOneHotPath depVector;    // A producer vector for a producer matrix.
        ActiveListIndexPath activeListPtr;     // A pointer of active list for flush
    } WakeupPipeReg;

    WakeupPipeReg intPipeReg[ INT_ISSUE_WIDTH ][ ISSUE_QUEUE_INT_LATENCY ];
    WakeupPipeReg memPipeReg[ MEM_ISSUE_WIDTH ][ ISSUE_QUEUE_MEM_LATENCY ];
    WakeupPipeReg nextIntPipeReg[ INT_ISSUE_WIDTH ];
    WakeupPipeReg nextMemPipeReg[ MEM_ISSUE_WIDTH ];

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    WakeupPipeReg complexPipeReg[ COMPLEX_ISSUE_WIDTH ][ ISSUE_QUEUE_COMPLEX_LATENCY ];
    WakeupPipeReg nextComplexPipeReg[ COMPLEX_ISSUE_WIDTH ];
    logic [$clog2(ISSUE_QUEUE_COMPLEX_LATENCY):0] canBeFlushedRegCountComplex;    //FlushedOpが存在している可能性があるComplexパイプラインレジスタの段数
    logic flushComplex[ COMPLEX_ISSUE_WIDTH ];
    IssueQueueIndexPath complexSelectedPtr[ COMPLEX_ISSUE_WIDTH ];
`endif

    // Flushed Op detection
    logic [$clog2(ISSUE_QUEUE_INT_LATENCY):0] canBeFlushedRegCountInt;    //FlushedOpが存在している可能性があるIntパイプラインレジスタの段数
    logic [$clog2(ISSUE_QUEUE_MEM_LATENCY):0] canBeFlushedRegCountMem;    //FlushedOpが存在している可能性があるMemパイプラインレジスタの段数
    ActiveListIndexPath flushRangeHeadPtr;  //フラッシュされた命令の範囲のhead
    ActiveListIndexPath flushRangeTailPtr;  //フラッシュされた命令の範囲のtail
    logic flushInt[ INT_ISSUE_WIDTH ];
    logic flushMem[ LOAD_ISSUE_WIDTH ];
    IssueQueueIndexPath intSelectedPtr[ INT_ISSUE_WIDTH ];
    IssueQueueIndexPath memSelectedPtr[ MEM_ISSUE_WIDTH ];
    IssueQueueOneHotPath flushIQ_Entry;

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            for( int j = 0; j < ISSUE_QUEUE_INT_LATENCY; j++ ) begin
                intPipeReg[i][j].ptr <= '1;
                intPipeReg[i][j].depVector <= '1;
                intPipeReg[i][j].activeListPtr <= '1;
            end
        end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            for( int j = 0; j < ISSUE_QUEUE_COMPLEX_LATENCY; j++ ) begin
                complexPipeReg[i][j].ptr <= '1;
                complexPipeReg[i][j].depVector <= '1;
                complexPipeReg[i][j].activeListPtr <= '1;
            end
        end
`endif

        for( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            for( int j = 0; j < ISSUE_QUEUE_MEM_LATENCY; j++ ) begin
                memPipeReg[i][j].ptr <= '1;
                memPipeReg[i][j].depVector <= '1;
                memPipeReg[i][j].activeListPtr <= '1;
            end
        end
    end
`endif

    always_ff @( posedge port.clk ) begin
        if( port.rst ||(recovery.toRecoveryPhase && !recovery.recoveryFromRwStage) ) begin
            // パイプラインレジスタの初期化
            // Don't care except valid bits.
            for( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
                for( int j = 0; j < ISSUE_QUEUE_INT_LATENCY; j++ ) begin
                    intPipeReg[i][j].valid <= FALSE;
                end
            end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
                for( int j = 0; j < ISSUE_QUEUE_COMPLEX_LATENCY; j++ ) begin
                    complexPipeReg[i][j].valid <= FALSE;
                end
            end
`endif

            for( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
                for( int j = 0; j < ISSUE_QUEUE_MEM_LATENCY; j++ ) begin
                    memPipeReg[i][j].valid <= FALSE;
                end
            end
        end
        else if ( !port.stall ) begin
            // 通常動作
            for( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
                for( int j = 1; j < ISSUE_QUEUE_INT_LATENCY; j++ ) begin
                    intPipeReg[i][j-1] <= intPipeReg[i][j];
                end
                intPipeReg[i][ ISSUE_QUEUE_INT_LATENCY-1 ] <= nextIntPipeReg[i];
            end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            for( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
                for( int j = 1; j < ISSUE_QUEUE_COMPLEX_LATENCY; j++ ) begin
                    complexPipeReg[i][j-1] <= complexPipeReg[i][j];
                end
                complexPipeReg[i][ ISSUE_QUEUE_COMPLEX_LATENCY-1 ] <= nextComplexPipeReg[i];
            end
`endif

            for( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
                for( int j = 1; j < ISSUE_QUEUE_MEM_LATENCY; j++ ) begin
                    memPipeReg[i][j-1] <= memPipeReg[i][j];
                end
                memPipeReg[i][ ISSUE_QUEUE_MEM_LATENCY-1 ] <= nextMemPipeReg[i];
            end
        end
    end



    always_comb begin
        flushIQ_Entry = recovery.flushIQ_Entry;
        //
        // Register selected ops.
        //
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            // Input of PipeReg (Selected Data)
            intSelectedPtr[i] = port.selectedPtr[i];
            nextIntPipeReg[i].valid = port.selected[i] && !flushIQ_Entry[intSelectedPtr[i]];
            nextIntPipeReg[i].ptr = port.selectedPtr[i];
            nextIntPipeReg[i].depVector = port.selectedVector[i];
            nextIntPipeReg[i].activeListPtr = recovery.selectedActiveListPtr[i];
        end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            complexSelectedPtr[i] = port.selectedPtr[(i+INT_ISSUE_WIDTH)];
            nextComplexPipeReg[i].valid = port.selected[(i+INT_ISSUE_WIDTH)] && !flushIQ_Entry[complexSelectedPtr[i]];
            nextComplexPipeReg[i].ptr = port.selectedPtr[(i+INT_ISSUE_WIDTH)];
            nextComplexPipeReg[i].depVector = port.selectedVector[(i+INT_ISSUE_WIDTH)];
            nextComplexPipeReg[i].activeListPtr = recovery.selectedActiveListPtr[(i+INT_ISSUE_WIDTH)];
        end
`endif

        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            memSelectedPtr[i] = port.selectedPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)];
            nextMemPipeReg[i].valid = port.selected[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] && !flushIQ_Entry[memSelectedPtr[i]];
            nextMemPipeReg[i].ptr = port.selectedPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)];
            nextMemPipeReg[i].depVector = port.selectedVector[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)];
            nextMemPipeReg[i].activeListPtr = recovery.selectedActiveListPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)];
        end

        //
        // Exit from the pipeline registers and now wakeup consumers.
        //
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            // Output of PipeReg (Wakeup Data)
            // Now, WAKEUP_WIDTH == ISSUE_WIDTH
            flushInt[i] = SelectiveFlushDetector(
                            canBeFlushedRegCountInt != 0,
                            flushRangeHeadPtr,
                            flushRangeTailPtr,
                            intPipeReg[i][0].activeListPtr
                            );
            port.wakeup[i] = intPipeReg[i][0].valid && !flushInt[i];
            port.wakeupPtr[i] = intPipeReg[i][0].ptr;
            port.wakeupVector[i] = intPipeReg[i][0].depVector;
        end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for (int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            flushComplex[i] = SelectiveFlushDetector(
                            canBeFlushedRegCountComplex != 0,
                            flushRangeHeadPtr,
                            flushRangeTailPtr,
                            complexPipeReg[i][0].activeListPtr
                            );
            port.wakeup[(i+INT_ISSUE_WIDTH)] = complexPipeReg[i][0].valid && !flushComplex[i];
            port.wakeupPtr[(i+INT_ISSUE_WIDTH)] = complexPipeReg[i][0].ptr;
            port.wakeupVector[(i+INT_ISSUE_WIDTH)] = complexPipeReg[i][0].depVector;
        end
`endif

`ifdef RSD_MARCH_UNIFIED_LDST_MEM_PIPE
        // Store ports do not wake up consumers, thus LOAD_ISSUE_WIDTH is used.
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            flushMem[i] = SelectiveFlushDetector(
                            canBeFlushedRegCountMem != 0,
                            flushRangeHeadPtr,
                            flushRangeTailPtr,
                            memPipeReg[i][0].activeListPtr
                          );
            port.wakeup[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].valid && !flushMem[i];
            port.wakeupPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].ptr;
            port.wakeupVector[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].depVector;
        end

        // Wake up an instruction that depends on the store
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            // Not need to assert flushMem because store dependent is not related on register
            port.wakeupPtr[i+WAKEUP_WIDTH] = memPipeReg[i][0].ptr;
            port.wakeupVector[i+WAKEUP_WIDTH] = memPipeReg[i][0].depVector;
        end
`else
        // Store ports do not wake up consumers, thus LOAD_ISSUE_WIDTH is used.
        for (int i = 0; i < LOAD_ISSUE_WIDTH; i++) begin
            flushMem[i] = SelectiveFlushDetector(
                            canBeFlushedRegCountMem != 0,
                            flushRangeHeadPtr,
                            flushRangeTailPtr,
                            memPipeReg[i][0].activeListPtr
                            );
            port.wakeup[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].valid && !flushMem[i];
            port.wakeupPtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].ptr;
            port.wakeupVector[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].depVector;
        end
        // Wake up an instruction that depends on the store
        for (int i = 0; i < MEM_ISSUE_WIDTH - LOAD_ISSUE_WIDTH; i++) begin
            // Not need to assert flushMem because store dependent is not related on register
            port.wakeupPtr[i+WAKEUP_WIDTH] = memPipeReg[i+LOAD_ISSUE_WIDTH][0].ptr;
            port.wakeupVector[i+WAKEUP_WIDTH] = memPipeReg[i+LOAD_ISSUE_WIDTH][0].depVector;
        end
`endif
    end

    // To an issue queue.
    // Flushed op is detected here.
    always_comb begin
        //
        // Release issue queue entries.
        // Entries can be released after they wake up consumers.
        //
        for (int i = 0; i < INT_ISSUE_WIDTH; i++) begin
            port.releaseEntry[i] = intPipeReg[i][0].valid && !port.stall;
            port.releasePtr[i] = intPipeReg[i][0].ptr;
        end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++) begin
            port.releaseEntry[(i+INT_ISSUE_WIDTH)] = complexPipeReg[i][0].valid && !port.stall;
            port.releasePtr[(i+INT_ISSUE_WIDTH)] = complexPipeReg[i][0].ptr;
        end
`endif
        for (int i = 0; i < MEM_ISSUE_WIDTH; i++) begin
            port.releaseEntry[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].valid && !port.stall;
            port.releasePtr[(i+INT_ISSUE_WIDTH+COMPLEX_ISSUE_WIDTH)] = memPipeReg[i][0].ptr;
        end
    end

    always_ff @( posedge port.clk ) begin
        if(port.rst) begin
            canBeFlushedRegCountInt <= 0;
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            canBeFlushedRegCountComplex <= 0;
`endif
            canBeFlushedRegCountMem <= 0;
            flushRangeHeadPtr <= 0;
            flushRangeTailPtr <= 0;
        end
        else if(recovery.toRecoveryPhase && recovery.recoveryFromRwStage) begin
            canBeFlushedRegCountInt <= ISSUE_QUEUE_INT_LATENCY;
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            canBeFlushedRegCountComplex <= ISSUE_QUEUE_COMPLEX_LATENCY;
`endif
            canBeFlushedRegCountMem <= ISSUE_QUEUE_MEM_LATENCY;
            flushRangeHeadPtr <= recovery.flushRangeHeadPtr;
            flushRangeTailPtr <= recovery.flushRangeTailPtr;
        end
        else begin
            if(canBeFlushedRegCountInt>0 && !port.stall) begin
                canBeFlushedRegCountInt <= canBeFlushedRegCountInt-1;
            end
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            if(canBeFlushedRegCountComplex>0 && !port.stall) begin
                canBeFlushedRegCountComplex <= canBeFlushedRegCountComplex-1;
            end
`endif
            if(canBeFlushedRegCountMem>0 && !port.stall) begin
                canBeFlushedRegCountMem <= canBeFlushedRegCountMem-1;
            end
        end
    end

    always_comb begin
        recovery.wakeupPipelineRegFlushedOpExist = 
            (canBeFlushedRegCountInt != 0) || 
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
            (canBeFlushedRegCountComplex != 0) || 
`endif
            (canBeFlushedRegCountMem != 0);
    end

endmodule : WakeupPipelineRegister



// ---- Scheduler/ProducerMatrix.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Dependency matrix.
//

import BasicTypes::*;
import SchedulerTypes::*;

module ProducerMatrix (
    input logic clk, stall,

    input logic dispatch[ DISPATCH_WIDTH ],
    input logic dispatchedSrcRegReady [ DISPATCH_WIDTH ][ ISSUE_QUEUE_SRC_REG_NUM ],
    input IssueQueueIndexPath [ DISPATCH_WIDTH-1:0 ][ ISSUE_QUEUE_SRC_REG_NUM-1:0 ] dispatchedSrcRegPtr,
    input [ISSUE_QUEUE_ENTRY_NUM-1:0] dependStoreBitVector [DISPATCH_WIDTH], 
    input IssueQueueIndexPath dispatchPtr[ DISPATCH_WIDTH ],

    input IssueQueueOneHotPath wakeupDstVector[ WAKEUP_WIDTH + STORE_ISSUE_WIDTH ],

    output logic opReady[ ISSUE_QUEUE_ENTRY_NUM ]
);
    // ProducerMatrix can be updated without regarding the validness of consumer
    // rows because an outer logic (Scheduler) check their validness.
    IssueQueueOneHotPath [ISSUE_QUEUE_ENTRY_NUM-1:0] nextMatrix;
    IssueQueueOneHotPath [ISSUE_QUEUE_ENTRY_NUM-1:0] matrix;   // Don't care.

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        matrix = '0;
    end
`endif

    always_ff @(posedge clk) begin
        matrix <= nextMatrix;
    end

    IssueQueueOneHotPath [DISPATCH_WIDTH-1:0] dispatchVector;
    IssueQueueOneHotPath wakeupVector;
    always_comb begin

        nextMatrix = matrix;

        // Wakeup
        wakeupVector = '0;
        for (int w = 0; w < WAKEUP_WIDTH + STORE_ISSUE_WIDTH; w++) begin
            // A producer column can be cleared without regarding to validness of wakeup.
            //if (wakeup[w]) begin
            //end
            wakeupVector |= wakeupDstVector[w];
        end

        for (int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
            for (int j = 0; j < ISSUE_QUEUE_ENTRY_NUM; j++) begin
                nextMatrix[i][j] = wakeupVector[j] ? FALSE : nextMatrix[i][j];
            end
        end

        // It is ready when its all source bits are zero.
        for (int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++) begin
            opReady[i] = !(|(nextMatrix[i]));
        end

        if (stall) begin
            // Does not update.
            nextMatrix = matrix;
        end

        // Dispatch
        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            dispatchVector[i] = '0;
            for (int j = 0; j < ISSUE_QUEUE_SRC_REG_NUM; j++) begin
                // dispatchedSrcRegReady are from a ready bit table and it includes validness information.
                if (!dispatchedSrcRegReady[i][j]) begin
                    dispatchVector[i][dispatchedSrcRegPtr[i][j]] = TRUE;
                end
            end

            for (int j = 0; j < ISSUE_QUEUE_ENTRY_NUM; j++) begin 
                if (dependStoreBitVector[i][j]) begin 
                    dispatchVector[i][j] = TRUE; 
                end 
            end 
        end

        for (int i = 0; i < DISPATCH_WIDTH; i++) begin
            if (dispatch[i]) begin
                nextMatrix[dispatchPtr[i]] = dispatchVector[i];
            end
        end

    end

endmodule : ProducerMatrix
// ---- Scheduler/MemoryDependencyPredictor.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.



import BasicTypes::*;
import SchedulerTypes::*;

//`define ALWAYS_SPECULATIVE
//`define ALWAYS_NOT_SPECULATIVE

module MemoryDependencyPredictor(
    RenameStageIF.MemoryDependencyPredictor port,
    LoadStoreUnitIF.MemoryDependencyPredictor loadStoreUnit
);

    logic mdtWE[STORE_ISSUE_WIDTH];
    MDT_IndexPath mdtWA[STORE_ISSUE_WIDTH];
    MDT_Entry mdtWV[STORE_ISSUE_WIDTH];
    MDT_IndexPath mdtRA[RENAME_WIDTH];
    MDT_Entry mdtRV[RENAME_WIDTH];

    logic prediction[RENAME_WIDTH];

    generate
        // NOTE: Need to implement write request queue when increase STORE_ISSUE_WIDTH
        BlockMultiBankRAM #(
            .ENTRY_NUM( MDT_ENTRY_NUM ),
            .ENTRY_BIT_SIZE( $bits( MDT_Entry ) ),
            .READ_NUM( RENAME_WIDTH ),
            .WRITE_NUM( STORE_ISSUE_WIDTH )
        ) 
        mdt( 
            .clk(port.clk),
            .we(mdtWE),
            .wa(mdtWA),
            .wv(mdtWV),
            .ra(mdtRA),
            .rv(mdtRV)
        );
    endgenerate

    // Counter for reset sequence.
    MDT_IndexPath resetIndex;
    always_ff @(posedge port.clk) begin
        if (port.rstStart) begin
            resetIndex <= 0;
        end
        else begin
            resetIndex <= resetIndex + 1;
        end
    end

    always_comb begin

        // Process read request
        for (int i = 0; i < RENAME_WIDTH; i++) begin
            // convert PC_Path to MDT_IndexPath
            mdtRA[i] = ToMDT_Index(port.pc[0] + i*INSN_BYTE_WIDTH);
        end

        // Decide whether issue speculatively
        for (int i = 0; i < RENAME_WIDTH; i++) begin
`ifdef ALWAYS_SPECULATIVE
            prediction[i] = FALSE;
`elsif ALWAYS_NOT_SPECULATIVE
            prediction[i] = TRUE;
`else
            // Predict according to mdt entry
            prediction[i] = mdtRV[i].counter;
`endif
        end

        // Connect to IF.
        port.memDependencyPred = prediction;

        // Process write request
        for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
            // Make write request when store detect conflict with load
            mdtWE[i] = 
                loadStoreUnit.memAccessOrderViolation[i];

            // Learn memory order violation
            mdtWA[i] = ToMDT_Index(loadStoreUnit.conflictLoadPC[i]);
            mdtWV[i].counter = TRUE;
        end

        // In reset sequence, the write port 0 is used for initializing, and 
        // the other write ports are disabled.
        if (port.rst) begin
            for (int i = 0; i < STORE_ISSUE_WIDTH; i++) begin
                mdtWE[i] = (i == 0);
                mdtWA[i] = resetIndex;
                mdtWV[i].counter = FALSE;
            end

            // To avoid writing to the same bank (avoid error message)
            for (int i = 0; i < RENAME_WIDTH; i++) begin
                mdtRA[i] = i;
            end
        end
    end

endmodule : MemoryDependencyPredictor
// ---- Cache/CacheSystemIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- MemoryIF
//

import BasicTypes::*;
import CacheSystemTypes::*;

interface CacheSystemIF( input logic clk, rst );
    
    // ICache
    MemReadAccessReq icMemAccessReq;
    MemAccessReqAck icMemAccessReqAck;
    MemAccessResult icMemAccessResult;
    
    // DCache
    MemAccessReq dcMemAccessReq;
    MemAccessReqAck dcMemAccessReqAck;
    MemAccessResult dcMemAccessResult;
    MemAccessResponse dcMemAccessResponse;
    
    
    modport ICache(
    input
        clk,
        rst,
        icMemAccessResult,
        icMemAccessReqAck,
    output
        icMemAccessReq
    );
    
    modport DCache(
    input
        clk,
        rst,
        dcMemAccessResult,
        dcMemAccessReqAck,
        dcMemAccessResponse,
    output
        dcMemAccessReq
    );

    modport MemoryAccessController(
    input
        clk,
        rst,
        icMemAccessReq,
        dcMemAccessReq,
    output
        icMemAccessResult,
        dcMemAccessResult,
        icMemAccessReqAck,
        dcMemAccessReqAck,
        dcMemAccessResponse
    );
    
endinterface : CacheSystemIF

// ---- Cache/DCache.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// 2-read/write set-associative data cache
//


import BasicTypes::*;
import OpFormatTypes::*;
import CacheSystemTypes::*;
import OpFormatTypes::*;
import MemoryMapTypes::*;
import LoadStoreUnitTypes::*;

// Merge stored data and fetched line.
function automatic void MergeStoreDataToLine(
    output DCacheLinePath dstLine,
    input DCacheLinePath fetchedLine,
    input DCacheLinePath storedLine,
    input logic [DCACHE_LINE_BYTE_NUM-1:0] storedDirty
);
    for (int i = 0; i < DCACHE_LINE_BYTE_NUM; i++) begin
        for (int b = 0; b < 8; b++) begin
            dstLine[i*8 + b] = storedDirty[i] ? storedLine[i*8 + b] : fetchedLine[i*8 + b];
        end
    end
endfunction



// To a line address (index+tag) from a full address.
function automatic PhyAddrPath ToLineAddrFromFullAddr(input PhyAddrPath addr);
    return {
        addr[PHY_ADDR_WIDTH-1 : DCACHE_LINE_BYTE_NUM_BIT_WIDTH],
        { DCACHE_LINE_BYTE_NUM_BIT_WIDTH{1'b0} }
    };
endfunction

// To a line address (index+tag) part from a full address.
function automatic DCacheLineAddr ToLinePartFromFullAddr(input PhyAddrPath addr);
    return addr[PHY_ADDR_WIDTH-1 : DCACHE_LINE_BYTE_NUM_BIT_WIDTH];
endfunction

// To a line index from a full address.
function automatic DCacheIndexPath ToIndexPartFromFullAddr(input PhyAddrPath addr);
    return addr[PHY_ADDR_WIDTH-DCACHE_TAG_BIT_WIDTH-1 : DCACHE_LINE_BYTE_NUM_BIT_WIDTH];
endfunction

// To a line tag from a full address.
function automatic DCacheTagPath ToTagPartFromFullAddr(input PhyAddrPath addr);
    return addr[PHY_ADDR_WIDTH - 1 : PHY_ADDR_WIDTH - DCACHE_TAG_BIT_WIDTH];
endfunction

// Build a full address from index and tag parts.
function automatic PhyAddrPath BuildFullAddr(input DCacheIndexPath index, input DCacheTagPath tag);
    return {
        tag,
        index,
        { DCACHE_LINE_BYTE_NUM_BIT_WIDTH{1'b0} }
    };
endfunction

// To a part of a line index from a full address.
function automatic DCacheIndexSubsetPath ToIndexSubsetPartFromFullAddr(input PhyAddrPath addr);
    return addr[DCACHE_LINE_BYTE_NUM_BIT_WIDTH+DCACHE_INDEX_SUBSET_BIT_WIDTH-1 : DCACHE_LINE_BYTE_NUM_BIT_WIDTH];
endfunction

// 0-cleared MSHR entry.
function automatic MissStatusHandlingRegister ClearedMSHR();
    MissStatusHandlingRegister mshr;
    mshr = '0;
    return mshr;
endfunction

//
// The arbiter of the ports of the main memory.
//
module DCacheMemoryReqPortArbiter(DCacheIF.DCacheMemoryReqPortArbiter port);

    logic req[MSHR_NUM];
    logic grant[MSHR_NUM];
    MSHR_IndexPath memInSel;
    logic memValid;

    always_comb begin
        // Clear
        for (int r = 0; r < MSHR_NUM; r++) begin
            grant[r] = FALSE;
            req[r] = port.mshrMemReq[r];
        end

        // Arbitrate
        memInSel = '0;
        memValid = FALSE;
        for (int r = 0; r < MSHR_NUM; r++) begin
            if (req[r]) begin
                grant[r] = TRUE;
                memInSel = r;
                memValid = TRUE;
                break;
            end
        end

        // Outputs
        port.memInSel = memInSel;
        port.memValid = memValid;
        for (int r = 0; r < MSHR_NUM; r++) begin
            port.mshrMemGrt[r] = grant[r];
        end
    end

endmodule : DCacheMemoryReqPortArbiter

//
// Multiplexer for a memory signals
//

module DCacheMemoryReqPortMultiplexer(DCacheIF.DCacheMemoryReqPortMultiplexer port);

    MSHR_IndexPath portIn;
    always_comb begin

        portIn = port.memInSel;

        port.memAddr = port.mshrMemMuxIn[portIn].addr;
        port.memData = port.mshrMemMuxIn[portIn].data;
        port.memWE = port.mshrMemMuxIn[portIn].we;

        for (int i = 0; i < MSHR_NUM; i++) begin
            port.mshrMemMuxOut[i].ack = port.memReqAck;
            port.mshrMemMuxOut[i].serial = port.memSerial;
            port.mshrMemMuxOut[i].wserial = port.memWSerial;
        end

    end

endmodule : DCacheMemoryReqPortMultiplexer


//
// An arbiter of the ports of the tag/data array.
// 以下から来るアクセス要求に対して，最大 DCache のポート分だけ grant を返す
//   load unit/store unit: port.lsuCacheReq 
//   mshr の全エントリ:     mshrCacheReq    
// 
//   cacheArrayInSel[P]=r: 
//     上記の R個 リクエストのうち，r 番目 が
//     キャッシュの p 番目のポートに割り当てられた
//   cacheArrayOutSel[r]=p, grant[r]: 
//     上記の R個 リクエストのうち，r 番目 が
//     キャッシュの p 番目のポートに割り当てられた
//
// 典型的には，
//   grant[0]: load, grant[1]: store, grant[2],grant[3]...: mshr
//
module DCacheArrayPortArbiter(DCacheIF.DCacheArrayPortArbiter port);

    logic req[DCACHE_MUX_PORT_NUM];
    logic grant[DCACHE_MUX_PORT_NUM];
    DCacheMuxPortIndexPath cacheArrayInSel[DCACHE_ARRAY_PORT_NUM];
    DCacheArrayPortIndex   cacheArrayOutSel[DCACHE_MUX_PORT_NUM];

    always_comb begin
        // Clear
        for (int r = 0; r < DCACHE_MUX_PORT_NUM; r++) begin
            cacheArrayOutSel[r] = '0;
            grant[r] = FALSE;
        end

        // Merge inputs.
        for (int r = 0; r < DCACHE_LSU_PORT_NUM; r++) begin
            req[r] = port.lsuCacheReq[r];
        end
        for (int r = 0; r < MSHR_NUM; r++) begin
            req[r + DCACHE_LSU_PORT_NUM] = port.mshrCacheReq[r];
        end

        // Arbitrate
        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++ ) begin
            cacheArrayInSel[p] = '0;
            for (int r = 0; r < DCACHE_MUX_PORT_NUM; r++) begin
                if (req[r]) begin
                    req[r] = FALSE;
                    grant[r] = TRUE;
                    cacheArrayInSel[p] = r;
                    cacheArrayOutSel[r] = p;
                    break;
                end
            end
        end

        // Outputs
        port.cacheArrayInSel = cacheArrayInSel;
        port.cacheArrayOutSel = cacheArrayOutSel;

        for (int r = 0; r < DCACHE_LSU_PORT_NUM; r++) begin
            port.lsuCacheGrt[r] = grant[r];
        end
        for (int r = 0; r < MSHR_NUM; r++) begin
            port.mshrCacheGrt[r] = grant[r + DCACHE_LSU_PORT_NUM];
        end
    end

endmodule : DCacheArrayPortArbiter



//
// Multiplexer for d-cache signals
//
// DCacheArrayPortArbiter でアービトレーションした結果に基づき，
// DCache の各ポートと load/store/mshr の各ユニットをスイッチする．
// DCache アクセスはパイプライン化されているため，スイッチもパイプラインの各ステージ
// にあわせて行われる．
//
module DCacheArrayPortMultiplexer(DCacheIF.DCacheArrayPortMultiplexer port);

    DCacheMuxPortIndexPath portIn;
    DCacheMuxPortIndexPath portInRegTagStg[DCACHE_ARRAY_PORT_NUM];

    DCacheArrayPortIndex portOutRegTagStg[DCACHE_MUX_PORT_NUM];
    DCacheArrayPortIndex portOutRegDataStg[DCACHE_MUX_PORT_NUM];

    DCachePortMultiplexerIn muxIn[DCACHE_MUX_PORT_NUM];
    DCachePortMultiplexerIn muxInReg[DCACHE_ARRAY_PORT_NUM];    // DCACHE_ARRAY_PORT_NUM!

    DCachePortMultiplexerTagOut muxTagOut[DCACHE_MUX_PORT_NUM];
    DCachePortMultiplexerDataOut muxDataOut[DCACHE_MUX_PORT_NUM];

    logic tagHit[DCACHE_ARRAY_PORT_NUM];
    logic mshrConflict[DCACHE_ARRAY_PORT_NUM];

    logic mshrAddrHit[DCACHE_ARRAY_PORT_NUM];
    MSHR_IndexPath mshrAddrHitMSHRID[DCACHE_ARRAY_PORT_NUM];
    logic mshrReadHit[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath mshrReadData[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath portMSHRData[MSHR_NUM];
    logic portMSHRCanBeInvalid[MSHR_NUM];

    // *** Hack for Synplify...
    // Signals in an interface are set to temproraly signals for avoiding
    // errors outputted by Synplify.
    DCacheTagPath   tagArrayDataOutTmp[DCACHE_ARRAY_PORT_NUM];
    logic           tagArrayValidOutTmp[DCACHE_ARRAY_PORT_NUM];
    logic           dataArrayDirtyOutTmp[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath  dataArrayDataOutTmp[DCACHE_ARRAY_PORT_NUM];


    always_ff @(posedge port.clk) begin


        for (int i = 0; i < DCACHE_ARRAY_PORT_NUM; i++) begin
            if (port.rst) begin
                portInRegTagStg[i] <= '0;
                muxInReg[i] <= '0;
            end
            else begin
                portInRegTagStg[i] <= port.cacheArrayInSel[i];
                muxInReg[i] <= muxIn[ port.cacheArrayInSel[i] ];
            end

        end

        for (int i = 0; i < DCACHE_MUX_PORT_NUM; i++) begin
            if (port.rst) begin
                portOutRegTagStg[i] <= '0;
                portOutRegDataStg[i] <= '0;
            end
            else begin
                portOutRegTagStg[i] <= port.cacheArrayOutSel[i];
                portOutRegDataStg[i] <= portOutRegTagStg[i];
            end
        end

    end


    always_comb begin

        // Merge inputs.
        for (int r = 0; r < DCACHE_LSU_PORT_NUM; r++) begin
            muxIn[r] = port.lsuMuxIn[r];
        end
        for (int r = 0; r < MSHR_NUM; r++) begin
            muxIn[r + DCACHE_LSU_PORT_NUM] = port.mshrCacheMuxIn[r];
        end

        for (int r = 0; r < MSHR_NUM; r++) begin
            portMSHRCanBeInvalid[r] = FALSE;
            portMSHRData[r] = port.mshrData[r];
        end


        //
        // stage:   | ADDR   | D$TAG    | D$DATA   |
        // process: | tag-in | tag-out  |          |
        //          |        | hit/miss |          |
        //          |        | data-in  | data-out |
        //
        // Pipeline regs between ADDR<>D$TAG:   portInRegTagStg, portOutRegTagStg, muxInReg
        // Pipeline regs between D$TAG<>D$DATA: portOutRegDataStg
        //

        // --- Address calculation stage (ADDR, MemoryExecutionStage).
        // Tag array inputs
        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
            portIn = port.cacheArrayInSel[p];
            port.tagArrayWE[p]      = muxIn[ portIn ].tagWE;
            port.tagArrayIndexIn[p] = muxIn[ portIn ].indexIn;
            port.tagArrayDataIn[p]  = muxIn[ portIn ].tagDataIn;
            port.tagArrayValidIn[p] = muxIn[ portIn ].tagValidIn;
        end


        // --- Tag access stage (D$TAG, MemoryTagAccessStage).

        tagArrayDataOutTmp = port.tagArrayDataOut;
        tagArrayValidOutTmp = port.tagArrayValidOut;

        // Hit/miss detection
        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
            mshrConflict[p] = FALSE;
            mshrReadHit[p] = FALSE;
            mshrAddrHit[p] = FALSE;
            mshrAddrHitMSHRID[p] = '0;
            mshrReadData[p] = '0;
            for (int m = 0; m < MSHR_NUM; m++) begin
                if (port.mshrValid[m] &&
                    muxInReg[p].indexIn == ToIndexPartFromFullAddr(port.mshrAddr[m])
                ) begin
                    mshrConflict[p] = TRUE;

                    // When request addr hits mshr,
                    // 1. the mahr allocator load must bypass data from MSHR,
                    // 2. other loads can bypass data from MSHR if possoble.
                    if (muxInReg[p].tagDataIn == ToTagPartFromFullAddr(port.mshrAddr[m])) begin
                        // To bypass data from MSHR.
                        if (port.mshrPhase[m] > (MSHR_PHASE_MISS_WRITE_CACHE_REQUEST-1)) begin
                            if (muxInReg[p].makeMSHRCanBeInvalid) begin
                                portMSHRCanBeInvalid[m] = TRUE;
                            end
                            mshrReadHit[p] = TRUE;
                        end
                        mshrAddrHit[p] = TRUE;
                        mshrAddrHitMSHRID[p] = m;
                        mshrReadData[p] = portMSHRData[m];
                    end
                end
            end

            tagHit[p] =
                (tagArrayDataOutTmp[p] == muxInReg[p].tagDataIn) &&
                tagArrayValidOutTmp[p] &&
                !mshrConflict[p];
        end

        // Tag array outputs
        for (int r = 0; r < DCACHE_MUX_PORT_NUM; r++) begin
            muxTagOut[r].tagDataOut  = tagArrayDataOutTmp[ portOutRegTagStg[r] ];
            muxTagOut[r].tagValidOut = tagArrayValidOutTmp[ portOutRegTagStg[r] ];
            muxTagOut[r].tagHit = tagHit[ portOutRegTagStg[r] ];
            muxTagOut[r].mshrConflict = mshrConflict[ portOutRegTagStg[r] ];
            muxTagOut[r].mshrReadHit = mshrReadHit[ portOutRegTagStg[r] ];
            muxTagOut[r].mshrAddrHit = mshrAddrHit[ portOutRegTagStg[r] ];
            muxTagOut[r].mshrAddrHitMSHRID = mshrAddrHitMSHRID[ portOutRegTagStg[r] ];
            muxTagOut[r].mshrReadData = mshrReadData[ portOutRegTagStg[r] ];
        end


        for (int r = 0; r < MSHR_NUM; r++) begin
            port.mshrCanBeInvalid[r] = portMSHRCanBeInvalid[r];
        end

        // Data array inputs
        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
            port.dataArrayDataIn[p]     = muxInReg[p].dataDataIn;
            port.dataArrayDirtyIn[p]    = muxInReg[p].dataDirtyIn;
            port.dataArrayByteWE_In[p]  = muxInReg[p].dataByteWE;
            port.dataArrayWE[p]         =
                muxInReg[p].dataWE || (muxInReg[p].dataWE_OnTagHit && tagHit[p]);
            port.dataArrayIndexIn[p]    = muxInReg[p].indexIn;
        end


        // ---Data array access stage (D$DATA, MemoryAccessStage).
        // Data array outputs
        dataArrayDataOutTmp = port.dataArrayDataOut;
        dataArrayDirtyOutTmp = port.dataArrayDirtyOut;
        for (int r = 0; r < DCACHE_MUX_PORT_NUM; r++) begin
            muxDataOut[r].dataDataOut = dataArrayDataOutTmp[ portOutRegDataStg[r] ];
            muxDataOut[r].dataDirtyOut = dataArrayDirtyOutTmp[ portOutRegDataStg[r] ];
        end
    end


    // Output to each port.
    always_comb begin
        for (int r = 0; r < DCACHE_LSU_PORT_NUM; r++) begin
            port.lsuMuxTagOut[r] = muxTagOut[r];
            port.lsuMuxDataOut[r] = muxDataOut[r];
        end
        for (int r = 0; r < MSHR_NUM; r++) begin
            port.mshrCacheMuxTagOut[r] = muxTagOut[r + DCACHE_LSU_PORT_NUM];
            port.mshrCacheMuxDataOut[r] = muxDataOut[r + DCACHE_LSU_PORT_NUM];
        end
    end

endmodule : DCacheArrayPortMultiplexer


//
// Tag/data/dirty bits array.
//
module DCacheArray(DCacheIF.DCacheArray port);
    // Data array signals
    logic dataArrayWE[DCACHE_ARRAY_PORT_NUM];
    logic dataArrayByteWE[DCACHE_LINE_BYTE_NUM][DCACHE_ARRAY_PORT_NUM];
    DCacheIndexPath dataArrayIndex[DCACHE_ARRAY_PORT_NUM];
    BytePath        dataArrayIn[DCACHE_LINE_BYTE_NUM][DCACHE_ARRAY_PORT_NUM];
    BytePath        dataArrayOut[DCACHE_LINE_BYTE_NUM][DCACHE_ARRAY_PORT_NUM];
    logic           dataArrayDirtyIn[DCACHE_ARRAY_PORT_NUM];
    logic           dataArrayDirtyOut[DCACHE_ARRAY_PORT_NUM];

    // *** Hack for Synplify...
    DCacheByteEnablePath dataArrayByteWE_Tmp[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath dataArrayInTmp[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath dataArrayOutTmp[DCACHE_ARRAY_PORT_NUM];

    // Tag array signals
    logic tagArrayWE[DCACHE_ARRAY_PORT_NUM];
    DCacheIndexPath tagArrayIndex[DCACHE_ARRAY_PORT_NUM];
    DCacheTagValidPath tagArrayIn[DCACHE_ARRAY_PORT_NUM];
    DCacheTagValidPath tagArrayOut[DCACHE_ARRAY_PORT_NUM];

    // Reset signals
    DCacheIndexPath rstIndex;

    always_ff @(posedge port.clk) begin
        if (port.rstStart)
            rstIndex <= '0;
        else
            rstIndex <= rstIndex + 1;
    end


    generate
        // Data array instance
        for (genvar i = 0; i < DCACHE_LINE_BYTE_NUM; i++) begin
            BlockTrueDualPortRAM #(
                .ENTRY_NUM( DCACHE_INDEX_NUM ),
                .ENTRY_BIT_SIZE( $bits(BytePath) )
                //.PORT_NUM( DCACHE_ARRAY_PORT_NUM )
            ) dataArray (
                .clk( port.clk ),
                .we( dataArrayByteWE[i] ),
                .rwa( dataArrayIndex ),
                .wv( dataArrayIn[i] ),
                .rv( dataArrayOut[i] )
            );
        end

        // Dirty array instance
        // The dirty array is synchronized with the data array.
        BlockTrueDualPortRAM #(
            .ENTRY_NUM( DCACHE_INDEX_NUM ),
            .ENTRY_BIT_SIZE( 1 )
            //.PORT_NUM( DCACHE_ARRAY_PORT_NUM )
        ) dirtyArray (
            .clk( port.clk ),
            .we( dataArrayWE ),
            .rwa( dataArrayIndex ),
            .wv( dataArrayDirtyIn ),
            .rv( dataArrayDirtyOut )
        );

        // Tag array instance
        BlockTrueDualPortRAM #(
            .ENTRY_NUM( DCACHE_INDEX_NUM ),
            .ENTRY_BIT_SIZE( $bits(DCacheTagValidPath) )
            //.PORT_NUM( DCACHE_ARRAY_PORT_NUM )
        ) tagArray (
            .clk( port.clk ),
            .we( tagArrayWE ),
            .rwa( tagArrayIndex ),
            .wv( tagArrayIn ),
            .rv( tagArrayOut )
        );

    endgenerate


    always_comb begin

        // Data array signals
        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
            dataArrayIndex[p] = port.dataArrayIndexIn[p];
            dataArrayDirtyIn[p] = port.dataArrayDirtyIn[p];
            dataArrayWE[p] = port.dataArrayWE[p];
        end

        // *** Hack for Synplify...
        // Signals in an interface are set to temproraly signals for avoiding
        // errors outputted by Synplify.
        dataArrayByteWE_Tmp = port.dataArrayByteWE_In;
        dataArrayInTmp = port.dataArrayDataIn;

        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
            for (int i = 0; i < DCACHE_LINE_BYTE_NUM; i++) begin
                dataArrayByteWE[i][p] = port.dataArrayWE[p] && dataArrayByteWE_Tmp[p][i];
                for (int b = 0; b < 8; b++) begin
                    dataArrayIn[i][p][b] = dataArrayInTmp[p][i*8 + b];
                    dataArrayOutTmp[p][i*8 + b] = dataArrayOut[i][p][b];
                end
            end
        end

        port.dataArrayDataOut = dataArrayOutTmp;
        port.dataArrayDirtyOut = dataArrayDirtyOut;


        // Tag signals
        for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
            tagArrayIndex[p]    = port.tagArrayIndexIn[p];
            tagArrayWE[p]       = port.tagArrayWE[p];
            tagArrayIn[p].tag   = port.tagArrayDataIn[p];
            tagArrayIn[p].valid = port.tagArrayValidIn[p];

            port.tagArrayDataOut[p]  = tagArrayOut[p].tag;
            port.tagArrayValidOut[p] = tagArrayOut[p].valid;
        end


        // Reset
        if (port.rst) begin
            for (int p = 0; p < DCACHE_ARRAY_PORT_NUM; p++) begin
                for (int i = 0; i < DCACHE_LINE_BYTE_NUM; i++) begin
                    dataArrayByteWE[i][p] = FALSE;
                end
                tagArrayWE[p] = FALSE;
            end

            // Port 0 is used for reset.
            for (int i = 0; i < DCACHE_LINE_BYTE_NUM; i++) begin
                dataArrayByteWE[i][0] = TRUE;
                dataArrayIn[i][0] = 8'hcd;
            end
            dataArrayWE[0] = TRUE;
            dataArrayIndex[0] = rstIndex;
            dataArrayDirtyIn[0] = FALSE;

            tagArrayIndex[0] = rstIndex;
            tagArrayWE[0] = TRUE;
            tagArrayIn[0].tag = 0;
            tagArrayIn[0].valid = FALSE;


        end
    end

endmodule : DCacheArray

//
// Data cache main module.
//
module DCache(
    LoadStoreUnitIF.DCache lsu,
    CacheSystemIF.DCache cacheSystem,
    ControllerIF.DCache ctrl
);

    logic hit[DCACHE_LSU_PORT_NUM];
    logic missReq[DCACHE_LSU_PORT_NUM];
    PhyAddrPath missAddr[DCACHE_LSU_PORT_NUM];


    // Tag array
    DCacheIF port(lsu.clk, lsu.rst, lsu.rstStart);

    DCacheArray array(port);
    DCacheArrayPortArbiter arrayArbiter(port);
    DCacheArrayPortMultiplexer arrayMux(port);

    DCacheMemoryReqPortArbiter memArbiter(port);
    DCacheMemoryReqPortMultiplexer memMux(port);

    DCacheMissHandler missHandler(port);


    // Stored data
    DCacheLinePath storedLineData;
    logic [DCACHE_LINE_BYTE_NUM-1:0] storedLineByteWE;

    // Pipeline registers
    //
    // ----------------------------->
    // ADDR  | D$TAG | D$DATA | WB
    //       |  LSQ  |        |
    // Addresses are input to the tag array in the ADDR stage (MemoryExecutionStage).
    //
    PhyAddrPath dcReadAddrRegTagStg[DCACHE_LSU_READ_PORT_NUM];
    PhyAddrPath dcReadAddrRegDataStg[DCACHE_LSU_READ_PORT_NUM];
    logic dcReadReqReg[DCACHE_LSU_READ_PORT_NUM];
    logic lsuCacheGrtReg[DCACHE_LSU_PORT_NUM];

    logic dcWriteReqReg;
    PhyAddrPath dcWriteAddrReg;


    logic lsuLoadHasAllocatedMSHR[DCACHE_LSU_READ_PORT_NUM];
    MSHR_IndexPath lsuLoadMSHRID[DCACHE_LSU_READ_PORT_NUM];
    logic lsuStoreHasAllocatedMSHR[DCACHE_LSU_WRITE_PORT_NUM];
    MSHR_IndexPath lsuStoreMSHRID[DCACHE_LSU_WRITE_PORT_NUM];

    // MSHRからのLoad
    logic lsuMSHRAddrHit[DCACHE_LSU_READ_PORT_NUM];
    MSHR_IndexPath lsuMSHRAddrHitMSHRID[DCACHE_LSU_READ_PORT_NUM];
    logic lsuMSHRReadHit[DCACHE_LSU_READ_PORT_NUM];
    DCacheLinePath lsuMSHRReadData[DCACHE_LSU_READ_PORT_NUM];

    // MSHRをAllocateした命令からのメモリリクエストかどうか
    // MSHRをAllocateしたLoad命令がMemoryRegisterReadStageでflushされた場合，AllocateされたMSHRは解放可能になる
    logic lsuMakeMSHRCanBeInvalidByMemoryRegisterReadStage[MSHR_NUM];

    // そのリクエストがアクセスに成功した場合，AllocateされたMSHRは解放可能になる
    logic lsuMakeMSHRCanBeInvalid[DCACHE_LSU_READ_PORT_NUM];

    // MSHRをAllocateしたLoad命令がStoreForwardingによって完了した場合，AllocateされたMSHRは解放可能になる
    logic lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[MSHR_NUM];

    // MSHRをAllocateしたLoad命令がReplayQueueの先頭でflushされた場合，AllocateされたMSHRは解放可能になる
    logic lsuMakeMSHRCanBeInvalidByReplayQueue[MSHR_NUM];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            dcReadAddrRegTagStg[i] = '0;
            dcReadAddrRegDataStg[i] = '0;
        end
        dcWriteAddrReg = '0;
    end
`endif

    always_ff @(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
                dcReadReqReg[i] <= FALSE;
            end
            for (int i = 0; i < DCACHE_LSU_PORT_NUM; i++) begin
                lsuCacheGrtReg[i] <= FALSE;
            end
            dcWriteReqReg <= '0;
        end
        else begin
            lsuCacheGrtReg <= port.lsuCacheGrt;

            for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
                dcReadReqReg[i] <= lsu.dcReadReq[i];
                dcReadAddrRegTagStg[i] <= lsu.dcReadAddr[i];
            end

            dcReadAddrRegDataStg <= dcReadAddrRegTagStg;

            dcWriteReqReg <= lsu.dcWriteReq;
            dcWriteAddrReg <= lsu.dcWriteAddr;
        end
    end

`ifdef RSD_ENABLE_VECTOR_PATH
    `RSD_STATIC_ASSERT(
        $bits(VectorPath) == $bits(DCacheLinePath), 
        "The width of a DCache line must be same as the width of a vector register."
    );
`endif

    `RSD_STATIC_ASSERT(
        $bits(LSQ_BlockDataPath) <= $bits(DCacheLinePath), 
        "The width of a DCache line must be same or greater than that of an LSQ block."
    );

    always_comb begin

        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            lsuMakeMSHRCanBeInvalid[i] = lsu.makeMSHRCanBeInvalid[i];
        end

        // --- In the address execution stage (MemoryExecutionStage)
        // Load request
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin

            port.lsuCacheReq[(i+DCACHE_LSU_READ_PORT_BEGIN)] = lsu.dcReadReq[i];
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].tagWE = FALSE;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].indexIn = ToIndexPartFromFullAddr(lsu.dcReadAddr[i]);
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].tagDataIn = ToTagPartFromFullAddr(lsu.dcReadAddr[i]);
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].tagValidIn = TRUE;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].dataDataIn = '0;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].dataByteWE = '0;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].dataWE = FALSE;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].dataWE_OnTagHit = FALSE;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].dataDirtyIn = FALSE;
            port.lsuMuxIn[(i+DCACHE_LSU_READ_PORT_BEGIN)].makeMSHRCanBeInvalid = lsuMakeMSHRCanBeInvalid[i];
        end

        // --- In the tag access stage (MemoryTagAccessStage)
        // Hit/miss detection
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            hit[i] = FALSE;
            if (port.lsuMuxTagOut[(i+DCACHE_LSU_READ_PORT_BEGIN)].tagHit && lsuCacheGrtReg[(i+DCACHE_LSU_READ_PORT_BEGIN)]) begin
                hit[i] = TRUE;
            end
        end

        //
        // --- In the data array access stage.
        // Load data from a cache line.
        //
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            // Read data address is aligned to word boundary in ReadDataFromLine.
            lsu.dcReadData[i] = port.lsuMuxDataOut[i].dataDataOut;
            lsu.dcReadHit[i] = hit[i];
        end
/*
        for (int i = DCACHE_LSU_READ_PORT_NUM; i < MEM_ISSUE_WIDTH; i++) begin
            lsu.dcReadData[i] = '0;
            lsu.dcReadHit[i] = FALSE;
            
        end
*/


        // --- In the first stage of the commit stages.
        // Write request


        for (int i = 0; i < DCACHE_LSU_WRITE_PORT_NUM; i++) begin
            assert(DCACHE_LSU_WRITE_PORT_NUM == 1);

            // Write data is not aligned?
            storedLineData = lsu.dcWriteData;
            storedLineByteWE = lsu.dcWriteByteWE;

            port.lsuCacheReq[(i+DCACHE_LSU_WRITE_PORT_BEGIN)] = lsu.dcWriteReq;
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].tagWE = FALSE;    // First, stores read tag.
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].indexIn = ToIndexPartFromFullAddr(lsu.dcWriteAddr);
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].tagDataIn = ToTagPartFromFullAddr(lsu.dcWriteAddr);
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].tagValidIn = TRUE;
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].dataDataIn = storedLineData;
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].dataByteWE = storedLineByteWE;
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].dataWE = FALSE;
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].dataWE_OnTagHit = TRUE;
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].dataDirtyIn = TRUE;
            // ストアはコミット時に初めて MSHR にアクセスするので，キャンセルはしないはず？
            port.lsuMuxIn[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].makeMSHRCanBeInvalid = FALSE;//lsuMakeMSHRCanBeInvalid[(i+DCACHE_LSU_WRITE_PORT_BEGIN)];

            lsu.dcWriteReqAck = port.lsuCacheGrt[(i+DCACHE_LSU_WRITE_PORT_BEGIN)];
        end


        // --- In the first stage of the commit stages.
        // Hit/miss detection

        for (int i = 0; i < DCACHE_LSU_WRITE_PORT_NUM; i++) begin
            assert(DCACHE_LSU_WRITE_PORT_NUM == 1);

            // Store data to the array after miss handling finishes.
            hit[(i+DCACHE_LSU_WRITE_PORT_BEGIN)] = FALSE;
            if (port.lsuMuxTagOut[(i+DCACHE_LSU_WRITE_PORT_BEGIN)].tagHit && lsuCacheGrtReg[(i+DCACHE_LSU_WRITE_PORT_BEGIN)]) begin
                hit[(i+DCACHE_LSU_WRITE_PORT_BEGIN)] = TRUE;
            end

            lsu.dcWriteHit = hit[(i+DCACHE_LSU_WRITE_PORT_BEGIN)];
        end

    end

    always_comb begin
        port.storedLineData = storedLineData;
        port.storedLineByteWE = storedLineByteWE;
    end

    //
    // --- Miss requests.
    // In the tag access stage/second commit stage.
    //
    always_comb begin

        // Read requests from a memory execution stage.
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            missReq[i] = 
                !hit[i] && 
                !port.lsuMuxTagOut[i].mshrConflict && 
                dcReadReqReg[i] && 
                lsuCacheGrtReg[i] && 
                !lsu.dcReadCancelFromMT_Stage[i];
            missAddr[i] = dcReadAddrRegTagStg[i];
        end

        // Write requests from a store queue commitor.
        for (int i = DCACHE_LSU_WRITE_PORT_BEGIN; i < DCACHE_LSU_WRITE_PORT_NUM + DCACHE_LSU_READ_PORT_NUM; i++) begin
            assert(DCACHE_LSU_WRITE_PORT_NUM == 1);
            missReq[i] = !hit[i] && !port.lsuMuxTagOut[i].mshrConflict && dcWriteReqReg && lsuCacheGrtReg[i];
            missAddr[i] = dcWriteAddrReg;
        end

    end


    // 1. MSHR 登録
    //   * 確保できない場合，待たせる
    //   * 以降は MSHR 登録アドレスへの操作は全部ブロック
    logic mshrConflict[DCACHE_LSU_PORT_NUM];

        // Miss handler
    logic portInitMSHR[MSHR_NUM];
    PhyAddrPath portInitMSHR_Addr[MSHR_NUM];
    logic portIsAllocatedByStore[MSHR_NUM];

    always_comb begin

        // MSHR alloc signals for ReplayQueue
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            lsuLoadHasAllocatedMSHR[i] = FALSE;
            lsuLoadMSHRID[i] = '0;
        end

        // MSHR alloc signals for storeCommitter
        for (int i = 0; i < DCACHE_LSU_WRITE_PORT_NUM; i++) begin
            lsuStoreHasAllocatedMSHR[i] = FALSE;
            lsuStoreMSHRID[i] = '0;
        end

        // MSHR addr/data hit and data signals for MemoryAccessBackend
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            lsuMSHRAddrHit[i] = port.lsuMuxTagOut[i].mshrAddrHit;
            lsuMSHRAddrHitMSHRID[i] = port.lsuMuxTagOut[i].mshrAddrHitMSHRID;
            lsuMSHRReadHit[i] = port.lsuMuxTagOut[i].mshrReadHit;
            lsuMSHRReadData[i] = port.lsuMuxTagOut[i].mshrReadData;
        end

        for (int i = 0; i < DCACHE_LSU_PORT_NUM; i++) begin
            mshrConflict[i] = port.lsuMuxTagOut[i].mshrConflict;
        end

        // Check address conflict in missed access in this cycle.
        for (int i = 0; i < DCACHE_LSU_PORT_NUM; i++) begin
            for (int m = 0; m < i; m++) begin
                if (missReq[m] &&
                    ToIndexPartFromFullAddr(missAddr[i]) == ToIndexPartFromFullAddr(missAddr[m])
                ) begin
                    // An access with the same index cannot enter to the MSHR.
                    mshrConflict[i] = TRUE;
                end
            end
        end

        for (int i = 0; i < MSHR_NUM; i++) begin
            portInitMSHR[i] = FALSE;
            portInitMSHR_Addr[i] = '0;
            portIsAllocatedByStore[i] = FALSE;
        end

        for (int i = 0; i < DCACHE_LSU_PORT_NUM; i++) begin
            if (!missReq[i] || mshrConflict[i]) begin
                // This access hits the cache or is invalid.
                // An access with the same index cannot enter to the MSHR.
                continue;
            end

            // Search free MSHR entry and allocate.
            for (int m = 0; m < MSHR_NUM; m++) begin
                if (!port.mshrValid[m] && !portInitMSHR[m]) begin
                    portInitMSHR[m] = TRUE;
                    portInitMSHR_Addr[m] = missAddr[i];
                    if (i < DCACHE_LSU_READ_PORT_NUM) begin
                        lsuLoadHasAllocatedMSHR[i] = TRUE;
                        lsuLoadMSHRID[i] = m;
                    end
                    else begin
                        lsuStoreHasAllocatedMSHR[i-DCACHE_LSU_READ_PORT_NUM] = TRUE;
                        lsuStoreMSHRID[i-DCACHE_LSU_READ_PORT_NUM] = m;
                        portIsAllocatedByStore[m] = TRUE;
                    end
                    break;
                end
            end
        end

        for (int i = 0; i < MSHR_NUM; i++) begin
            port.initMSHR[i] = portInitMSHR[i];
            port.initMSHR_Addr[i] = portInitMSHR_Addr[i];
            port.isAllocatedByStore[i] = portIsAllocatedByStore[i];
        end

        // Output control signals
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            lsu.dcReadBusy[i] = mshrConflict[i];
        end
        lsu.dcWriteBusy = mshrConflict[DCACHE_LSU_WRITE_PORT_BEGIN];

        // MSHR addr/data hit and data signals for MemoryAccessBackend
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            lsu.mshrAddrHit[i] = lsuMSHRAddrHit[i];
            lsu.mshrAddrHitMSHRID[i] = lsuMSHRAddrHitMSHRID[i];
            lsu.mshrReadHit[i] = lsuMSHRReadHit[i];
            lsu.mshrReadData[i] = lsuMSHRReadData[i];
        end

        // MSHR alloc signals for ReplayQueue
        for (int i = 0; i < DCACHE_LSU_READ_PORT_NUM; i++) begin
            lsu.loadHasAllocatedMSHR[i] = lsuLoadHasAllocatedMSHR[i];
            lsu.loadMSHRID[i] = lsuLoadMSHRID[i];
        end

        // MSHR alloc signals for storeCommitter
        for (int i = 0; i < DCACHE_LSU_WRITE_PORT_NUM; i++) begin
            lsu.storeHasAllocatedMSHR[i] = lsuStoreHasAllocatedMSHR[i];
            lsu.storeMSHRID[i] = lsuStoreMSHRID[i];
        end

    end

    always_comb begin
        for (int i = 0; i < MSHR_NUM; i++) begin
            lsuMakeMSHRCanBeInvalidByMemoryRegisterReadStage[i] = lsu.makeMSHRCanBeInvalidByMemoryRegisterReadStage[i];
            lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[i] = lsu.makeMSHRCanBeInvalidByMemoryTagAccessStage[i];
            lsuMakeMSHRCanBeInvalidByReplayQueue[i] = lsu.makeMSHRCanBeInvalidByReplayQueue[i];
        end
    end

    always_comb begin
        for (int i = 0; i < MSHR_NUM; i++) begin
            port.makeMSHRCanBeInvalidByMemoryRegisterReadStage[i] = lsuMakeMSHRCanBeInvalidByMemoryRegisterReadStage[i];
            port.makeMSHRCanBeInvalidByMemoryTagAccessStage[i] = lsuMakeMSHRCanBeInvalidByMemoryTagAccessStage[i];
            port.makeMSHRCanBeInvalidByReplayQueue[i] = lsuMakeMSHRCanBeInvalidByReplayQueue[i];
        end
    end


    //
    // Main memory
    //
    always_comb begin
        cacheSystem.dcMemAccessReq.valid = port.memValid;
        cacheSystem.dcMemAccessReq.we = port.memWE;
        cacheSystem.dcMemAccessReq.addr = port.memAddr;
        cacheSystem.dcMemAccessReq.data = port.memData;
        // To notice mshr phases and addr subset to ReplayQueue.
        for (int i = 0; i < MSHR_NUM; i++) begin
            lsu.mshrPhase[i] = port.mshrPhase[i];
            lsu.mshrAddrSubset[i] = port.mshrAddrSubset[i];
            lsu.mshrValid[i] = port.mshrValid[i];
        end
        port.memReqAck = cacheSystem.dcMemAccessReqAck.ack;
        port.memSerial = cacheSystem.dcMemAccessReqAck.serial;
        port.memAccessResult = cacheSystem.dcMemAccessResult;
        port.memWSerial = cacheSystem.dcMemAccessReqAck.wserial;
        port.memAccessResponse = cacheSystem.dcMemAccessResponse;
    end

endmodule : DCache


module DCacheMissHandler(
    DCacheIF.DCacheMissHandler port
);

    MissStatusHandlingRegister nextMSHR[MSHR_NUM];
    MissStatusHandlingRegister mshr[MSHR_NUM];

    logic portIsAllocatedByStore[MSHR_NUM];
    DCacheLinePath mergedLine[MSHR_NUM];

`ifndef RSD_SYNTHESIS
    // Don't care these values, but avoiding undefined status in Questa.
    initial begin
        for (int i = 0; i < MSHR_NUM; i++) begin
            mshr[i] = '0;
        end
    end
`endif

    // MSHR
    always_ff@(posedge port.clk) begin
        if (port.rst) begin
            for (int i = 0; i < MSHR_NUM; i++) begin
                mshr[i].valid <= FALSE;
                mshr[i].phase <= MSHR_PHASE_INVALID;
                mshr[i].canBeInvalid <= FALSE;
                mshr[i].isAllocatedByStore <= FALSE;
            end
        end
        else begin
            mshr <= nextMSHR;
        end
    end

    always_comb begin
        for (int i = 0; i < MSHR_NUM; i++) begin
            // To notice mshr phases to ReplayQueue.
            port.mshrPhase[i] = mshr[i].phase;

            // To notice mshr newAddr subset to ReplayQueue.
            port.mshrAddrSubset[i] = ToIndexSubsetPartFromFullAddr(mshr[i].newAddr);

            // To bypass mshr data to load insts.
            port.mshrData[i] = mshr[i].line;

            port.mshrValid[i] = mshr[i].valid;
            port.mshrAddr[i] = mshr[i].newAddr;
        end
    end

    DCacheLinePath portStoredLineData;
    logic [DCACHE_LINE_BYTE_NUM-1:0] portStoredLineByteWE;
    always_comb begin
        portStoredLineData = port.storedLineData;
        portStoredLineByteWE = port.storedLineByteWE;
    end


    always_comb begin

        for (int i = 0; i < MSHR_NUM; i++) begin
            portIsAllocatedByStore[i] = port.isAllocatedByStore[i];
        end

        for (int i = 0; i < MSHR_NUM; i++) begin
            nextMSHR[i] = mshr[i];

            // Both MSHR_PHASE_VICTIM_READ_FROM_CACHE & MSHR_PHASE_MISS_WRITE_CACHE_REQUEST phases
            // use newAddr for a cache index.
            // The other phases do not use an index.
            port.mshrCacheMuxIn[i].indexIn = ToIndexPartFromFullAddr(mshr[i].newAddr);

            // Only MSHR_PHASE_MISS_WRITE_CACHE_REQUEST uses tagDataIn, dataByteWE and dataDataIn.
            port.mshrCacheMuxIn[i].tagDataIn = ToTagPartFromFullAddr(mshr[i].newAddr);
            port.mshrCacheMuxIn[i].dataDataIn = mshr[i].line;
            port.mshrCacheMuxIn[i].dataByteWE = {DCACHE_LINE_BYTE_NUM{1'b1}};
            port.mshrCacheMuxIn[i].tagValidIn = TRUE;        // Don't care for the other phases.

            // Other cache request signals.
            port.mshrCacheReq[i] = FALSE;
            port.mshrCacheMuxIn[i].tagWE = FALSE;
            port.mshrCacheMuxIn[i].dataWE = FALSE;
            port.mshrCacheMuxIn[i].dataWE_OnTagHit = FALSE;
            port.mshrCacheMuxIn[i].dataDirtyIn = FALSE;
            port.mshrCacheMuxIn[i].makeMSHRCanBeInvalid = FALSE;

            // Memory request signals
            port.mshrMemReq[i] = FALSE;
            port.mshrMemMuxIn[i].data = mshr[i].line;

            // Don't care
            port.mshrMemMuxIn[i].we = FALSE;
            port.mshrMemMuxIn[i].addr = mshr[i].victimAddr;

            case(mshr[i].phase)
                default: begin

                    // Initialize or read a  MSHR.
                    if (port.initMSHR[i]) begin
                        // 1. MSHR 登録
                        // Initial phase
                        nextMSHR[i].valid = TRUE;
                        nextMSHR[i].phase = MSHR_PHASE_VICTIM_REQEUST;
                        nextMSHR[i].newAddr = port.initMSHR_Addr[i];
                        nextMSHR[i].newValid = FALSE;
                        nextMSHR[i].victimValid = FALSE;

                        nextMSHR[i].victimDirty = FALSE;
                        nextMSHR[i].victimReceived = FALSE;
                        nextMSHR[i].memSerial = '0;
                        nextMSHR[i].memWSerial = '0;

                        nextMSHR[i].canBeInvalid = FALSE;
                        nextMSHR[i].isAllocatedByStore = portIsAllocatedByStore[i];

                        // Dont'care
                        //nextMSHR[i].line = '0;

                    end
                end


                // 2. リプレース対象の読み出し
                //  * フィル対象の決定
                //      if (セット内に invalid なウェイがある) {
                //          フィル対象 = invalid なウェイ
                //      } else {
                //          フィル対象 = LR Uの示すウェイ
                //      }
                //  * ラインの読み出し
                //      if (! 追い出し対象が invalid ){
                //          ラインをキャッシュから読み出す
                //      }
                MSHR_PHASE_VICTIM_REQEUST: begin
                    // Access the cache array.
                    port.mshrCacheReq[i] = TRUE;
                    port.mshrCacheMuxIn[i].tagWE = FALSE;
                    port.mshrCacheMuxIn[i].dataWE = FALSE;
                    port.mshrCacheMuxIn[i].dataWE_OnTagHit = FALSE;
                    port.mshrCacheMuxIn[i].dataDirtyIn = FALSE;

                    nextMSHR[i].phase =
                        port.mshrCacheGrt[i] ?
                        MSHR_PHASE_VICTIM_RECEIVE_TAG : MSHR_PHASE_VICTIM_REQEUST;
                end

                MSHR_PHASE_VICTIM_RECEIVE_TAG: begin
                    // Read a victim line.
                    if (port.mshrCacheMuxTagOut[i].tagValidOut) begin
                        nextMSHR[i].victimAddr =
                            BuildFullAddr(
                                ToIndexPartFromFullAddr(mshr[i].newAddr),
                                port.mshrCacheMuxTagOut[i].tagDataOut
                            );
                        nextMSHR[i].victimValid = TRUE;
                        nextMSHR[i].phase = MSHR_PHASE_VICTIM_RECEIVE_DATA;
                    end
                    else begin
                        nextMSHR[i].victimValid = FALSE;
                        // Skip receiving data and writing back.
                        nextMSHR[i].phase = MSHR_PHASE_MISS_READ_MEM_REQUEST;
                    end

                end


                MSHR_PHASE_VICTIM_RECEIVE_DATA: begin
                    // Receive cache data.
                    nextMSHR[i].victimReceived = TRUE;
                    nextMSHR[i].line = port.mshrCacheMuxDataOut[i].dataDataOut;
                    nextMSHR[i].victimDirty = port.mshrCacheMuxDataOut[i].dataDirtyOut;

                    if (nextMSHR[i].victimDirty) begin
                        nextMSHR[i].phase = MSHR_PHASE_VICTIM_WRITE_TO_MEM;
                    end
                    else begin
                        nextMSHR[i].phase = MSHR_PHASE_MISS_READ_MEM_REQUEST;
                    end
                end

                // 3. リプレース対象の書き出し
                // * if (! 追い出し対象が invalid ){
                //        ラインをメモリに書き出す
                //   }

                MSHR_PHASE_VICTIM_WRITE_TO_MEM: begin
                    port.mshrMemReq[i] = TRUE;
                    port.mshrMemMuxIn[i].we = TRUE;
                    port.mshrMemMuxIn[i].addr = mshr[i].victimAddr;

                    if (port.mshrMemGrt[i] && port.mshrMemMuxOut[i].ack) begin
                        nextMSHR[i].memWSerial = port.mshrMemMuxOut[i].wserial;
                        nextMSHR[i].phase = MSHR_PHASE_VICTIM_WRITE_COMPLETE;
                    end
                    else begin
                        // Waiting until the request is accepted.
                        nextMSHR[i].phase = MSHR_PHASE_VICTIM_WRITE_TO_MEM;
                    end

                end

                // 4. リプレース対象の書き込み完了まで待機
                MSHR_PHASE_VICTIM_WRITE_COMPLETE: begin
                    port.mshrMemReq[i] = FALSE;
                    if (mshr[i].victimValid &&
                        mshr[i].victimDirty &&
                        !(port.memAccessResponse.valid &&
                        mshr[i].memWSerial == port.memAccessResponse.serial)
                    ) begin
                        // Wait MSHR_PHASE_VICTIM_WRITE_TO_MEM.
                        nextMSHR[i].phase = MSHR_PHASE_VICTIM_WRITE_COMPLETE;
                    end
                    else begin
                        nextMSHR[i].phase = MSHR_PHASE_MISS_READ_MEM_REQUEST;
                    end
                end

                // 5. ミスデータのメモリからの読みだし
                MSHR_PHASE_MISS_READ_MEM_REQUEST: begin
                    /* メモリ書込はResultを待たないように仕様変更
                    if (mshr[i].victimValid &&
                        mshr[i].victimDirty &&
                        !(port.memAccessResult.valid &&
                        mshr[i].memSerial == port.memAccessResult.serial)
                    ) begin
                        // Wait MSHR_PHASE_VICTIM_WRITE_TO_MEM.
                        port.mshrMemReq[i] = FALSE;
                    end
                    */
                    //else begin
                    if (TRUE) begin
                        // A victim line has been written to the memory and
                        // data on an MSHR entry is not valid.
                        nextMSHR[i].victimValid = FALSE;

                        // Fetch a missed line.
                        port.mshrMemReq[i] = TRUE;
                        port.mshrMemMuxIn[i].we = FALSE;
                        port.mshrMemMuxIn[i].addr = ToLineAddrFromFullAddr(mshr[i].newAddr);

                        if (port.mshrMemGrt[i] && port.mshrMemMuxOut[i].ack) begin
                            nextMSHR[i].memSerial = port.mshrMemMuxOut[i].serial;
                            nextMSHR[i].phase = MSHR_PHASE_MISS_READ_MEM_RECEIVE;
                        end
                        else begin
                            // Waiting until the request is accepted.
                            nextMSHR[i].phase = MSHR_PHASE_MISS_READ_MEM_REQUEST;
                        end
                    end
                end

                // Receive memory data.
                MSHR_PHASE_MISS_READ_MEM_RECEIVE: begin
                    if (!(port.memAccessResult.valid &&
                        mshr[i].memSerial == port.memAccessResult.serial)
                    ) begin
                        // Waiting until data is received.
                        nextMSHR[i].phase = MSHR_PHASE_MISS_READ_MEM_RECEIVE;
                    end
                    else begin
                        // Set a fetched line to a MSHR entry and go to the next phase.
                        nextMSHR[i].line = port.memAccessResult.data;
                        nextMSHR[i].newValid = TRUE;
                        if (mshr[i].isAllocatedByStore) begin
                            nextMSHR[i].phase = MSHR_PHASE_MISS_MERGE_STORE_DATA;
                        end
                        else begin
                            nextMSHR[i].phase = MSHR_PHASE_MISS_WRITE_CACHE_REQUEST;
                        end
                    end
                end

                // 5.5. MSHRエントリの割り当て者がStore命令の場合，ミスデータとストア命令のデータを結合する
                MSHR_PHASE_MISS_MERGE_STORE_DATA: begin
                    // Merge the allocator store data and the fetched line.
                    MergeStoreDataToLine(mergedLine[i], mshr[i].line,
                        portStoredLineData, portStoredLineByteWE);
                    nextMSHR[i].line = mergedLine[i];
                    nextMSHR[i].phase = MSHR_PHASE_MISS_WRITE_CACHE_REQUEST;
                end


                // 6. ミスデータのキャッシュへの書き込み
                MSHR_PHASE_MISS_WRITE_CACHE_REQUEST: begin
                    // Fille the cache array.
                    port.mshrCacheReq[i] = TRUE;
                    port.mshrCacheMuxIn[i].tagWE = TRUE;
                    port.mshrCacheMuxIn[i].dataWE = TRUE;
                    port.mshrCacheMuxIn[i].dataWE_OnTagHit = FALSE;
                    port.mshrCacheMuxIn[i].dataDirtyIn = mshr[i].isAllocatedByStore;



                    if (port.mshrCacheGrt[i]) begin
                        // If my request is granted, miss handling finishes.
                        nextMSHR[i].phase = MSHR_PHASE_MISS_WRITE_CACHE_FINISH;
                    end
                    else begin
                        nextMSHR[i].phase = MSHR_PHASE_MISS_WRITE_CACHE_REQUEST;
                    end
                end

                // 7.データアレイへの書き込みと解放可能条件を待って MSHR 解放
                // 現在の開放可能条件は
                // ・割り当て者がLoadでそのLoadへのデータの受け渡しが完了した場合
                // ・割り当て者がStoreの場合 (該当Storeのデータはこの時点でキャッシュに書き込まれている)
                MSHR_PHASE_MISS_WRITE_CACHE_FINISH: begin
                    if (mshr[i].canBeInvalid || mshr[i].isAllocatedByStore) begin
                        nextMSHR[i].phase = MSHR_PHASE_INVALID;
                        nextMSHR[i].valid = FALSE;
                    end
                end
            endcase // case(mshr[i].phase)

            if (port.makeMSHRCanBeInvalidByMemoryRegisterReadStage[i]) begin
                // MSHR can be invalid when
                // its allocator load has been flushed at MemoryRegisterReadStage.
                nextMSHR[i].canBeInvalid = TRUE;
            end
            else if (port.makeMSHRCanBeInvalidByMemoryTagAccessStage[i]) begin
                // MSHR can be invalid when
                // its allocator load has completed correctly because of StoreForwarding.
                nextMSHR[i].canBeInvalid = TRUE;
            end
            else if (port.makeMSHRCanBeInvalidByReplayQueue[i]) begin
                // MSHR can be invalid when
                // its allocator load has been flushed at the top of ReplayQueue.
                nextMSHR[i].canBeInvalid = TRUE;
            end
            else if (port.mshrCanBeInvalid[i] && (mshr[i].phase >= MSHR_PHASE_MISS_WRITE_CACHE_REQUEST)) begin
                nextMSHR[i].canBeInvalid = TRUE;
            end
        end // for (int i = 0; i < MSHR_NUM; i++) begin
    end



endmodule : DCacheMissHandler

// ---- Cache/DCacheIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// 2-read/write set-associative data cache
//

import BasicTypes::*;
import OpFormatTypes::*;
import CacheSystemTypes::*;
import OpFormatTypes::*;
import MemoryMapTypes::*;

interface DCacheIF(
input
    logic clk,
    logic rst,
    logic rstStart
);
    // Tag array
    logic           tagArrayWE[DCACHE_ARRAY_PORT_NUM];
    DCacheIndexPath tagArrayIndexIn[DCACHE_ARRAY_PORT_NUM];
    DCacheTagPath   tagArrayDataIn [DCACHE_ARRAY_PORT_NUM];
    logic           tagArrayValidIn[DCACHE_ARRAY_PORT_NUM];
    DCacheTagPath   tagArrayDataOut[DCACHE_ARRAY_PORT_NUM];
    logic           tagArrayValidOut[DCACHE_ARRAY_PORT_NUM];

    // Data array
    logic           dataArrayWE[DCACHE_ARRAY_PORT_NUM];
    DCacheIndexPath dataArrayIndexIn[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath  dataArrayDataIn[DCACHE_ARRAY_PORT_NUM];
    DCacheLinePath  dataArrayDataOut[DCACHE_ARRAY_PORT_NUM];
    DCacheByteEnablePath dataArrayByteWE_In[DCACHE_ARRAY_PORT_NUM];
    logic  dataArrayDirtyIn[DCACHE_ARRAY_PORT_NUM];
    logic  dataArrayDirtyOut[DCACHE_ARRAY_PORT_NUM];


    // Port arbiter input/output
    logic           lsuCacheReq[DCACHE_LSU_PORT_NUM];
    logic           lsuCacheGrt[DCACHE_LSU_PORT_NUM];
    DCachePortMultiplexerIn lsuMuxIn[DCACHE_LSU_PORT_NUM];
    DCachePortMultiplexerTagOut lsuMuxTagOut[DCACHE_LSU_PORT_NUM];
    DCachePortMultiplexerDataOut lsuMuxDataOut[DCACHE_LSU_PORT_NUM];    // Data array outputs are pipelined.

    // MSHR<>Array
    logic           mshrCacheReq[MSHR_NUM];
    logic           mshrCacheGrt[MSHR_NUM];
    DCachePortMultiplexerIn mshrCacheMuxIn[MSHR_NUM];
    DCachePortMultiplexerTagOut mshrCacheMuxTagOut[MSHR_NUM];
    DCachePortMultiplexerDataOut mshrCacheMuxDataOut[MSHR_NUM];    // Data array outputs are pipelined.

    // Multiplexer
    DCacheMuxPortIndexPath  cacheArrayInSel[DCACHE_ARRAY_PORT_NUM];
    DCacheArrayPortIndex    cacheArrayOutSel[DCACHE_MUX_PORT_NUM];

    // MSHR<>Memory
    logic mshrMemReq[MSHR_NUM];
    logic mshrMemGrt[MSHR_NUM];
    MemoryPortMultiplexerIn mshrMemMuxIn[MSHR_NUM];
    MemoryPortMultiplexerOut mshrMemMuxOut[MSHR_NUM];
    MSHR_IndexPath memInSel;

    // Memory
    PhyAddrPath memAddr;
    DCacheLinePath memData;
    logic memValid;
    logic memWE;
    logic memReqAck;           // Request is accpeted or not.
    MemAccessSerial memSerial; // Read request serial
    MemAccessResult memAccessResult;
    MemWriteSerial memWSerial; // Write request serial
    MemAccessResponse memAccessResponse;

    // Miss handler
    logic initMSHR[MSHR_NUM];
    PhyAddrPath initMSHR_Addr[MSHR_NUM];

    logic mshrValid[MSHR_NUM];
    PhyAddrPath mshrAddr[MSHR_NUM];

    MSHR_Phase mshrPhase[MSHR_NUM]; // MSHR phase.
    DCacheLinePath mshrData[MSHR_NUM]; // Data in MSHR.
    DCacheIndexSubsetPath mshrAddrSubset[MSHR_NUM];

    logic mshrCanBeInvalid[MSHR_NUM];
    logic isAllocatedByStore[MSHR_NUM];

    // MSHRをAllocateしたLoad命令がMemoryRegisterReadStageでflushされた場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalidByMemoryRegisterReadStage[MSHR_NUM];

    // MSHRをAllocateしたLoad命令がStoreForwardingによって完了した場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalidByMemoryTagAccessStage[MSHR_NUM];

    // MSHRをAllocateしたLoad命令がReplayQueueの先頭でflushされた場合，AllocateされたMSHRは解放可能になる
    logic makeMSHRCanBeInvalidByReplayQueue[MSHR_NUM];

    VectorPath storedLineData;
    logic [DCACHE_LINE_BYTE_NUM-1:0] storedLineByteWE;

    modport DCacheArrayPortArbiter(
    input
        lsuCacheReq,
        mshrCacheReq,
    output
        lsuCacheGrt,
        mshrCacheGrt,
        cacheArrayInSel,
        cacheArrayOutSel
    );

    modport DCacheArrayPortMultiplexer(
    input
        clk,
        rst,
        mshrCacheMuxIn,
        lsuMuxIn,
        tagArrayDataOut,
        tagArrayValidOut,
        dataArrayDataOut,
        cacheArrayInSel,
        cacheArrayOutSel,
        dataArrayDirtyOut,
        mshrAddr,
        mshrValid,
        mshrPhase,
        mshrData,
    output
        mshrCacheMuxTagOut,
        mshrCacheMuxDataOut,
        lsuMuxTagOut,
        lsuMuxDataOut,
        tagArrayWE,
        tagArrayIndexIn,
        tagArrayDataIn,
        tagArrayValidIn,
        dataArrayWE,
        dataArrayIndexIn,
        dataArrayDataIn,
        dataArrayDirtyIn,
        dataArrayByteWE_In,
        mshrCanBeInvalid
    );


    modport DCacheMemoryReqPortArbiter(
    input
        mshrMemReq,
    output
        mshrMemGrt,
        memInSel,
        memValid
    );

    modport DCacheMemoryReqPortMultiplexer(
    input
        memReqAck,
        memSerial,
        memWSerial,
        mshrMemMuxIn,
        memInSel,
    output
        memAddr,
        memData,
        memWE,
        mshrMemMuxOut
    );

    modport DCacheMissHandler(
    input
        clk,
        rst,
        initMSHR,
        initMSHR_Addr,
        mshrCacheGrt,
        mshrCacheMuxTagOut,
        mshrCacheMuxDataOut,
        mshrMemGrt,
        mshrMemMuxOut,
        memAccessResult,
        memAccessResponse,
        mshrCanBeInvalid,
        isAllocatedByStore,
        makeMSHRCanBeInvalidByMemoryRegisterReadStage,
        makeMSHRCanBeInvalidByMemoryTagAccessStage,
        makeMSHRCanBeInvalidByReplayQueue,
        storedLineData,
        storedLineByteWE,
    output
        mshrCacheReq,
        mshrCacheMuxIn,
        mshrMemReq,
        mshrMemMuxIn,
        mshrValid,
        mshrAddr,
        mshrPhase,
        mshrData,
        mshrAddrSubset
    );

    modport DCacheArray(
    input
        clk,
        rst,
        rstStart,
        tagArrayWE,
        tagArrayIndexIn,
        tagArrayDataIn,
        tagArrayValidIn,
        dataArrayDataIn,
        dataArrayIndexIn,
        dataArrayDirtyIn,
        dataArrayByteWE_In,
        dataArrayWE,
    output
        initMSHR,
        initMSHR_Addr,
        tagArrayDataOut,
        tagArrayValidOut,
        dataArrayDataOut,
        dataArrayDirtyOut,
        memAccessResult
    );



    modport DCache(
    input
        clk,
        rst,
        lsuCacheGrt,
        lsuMuxTagOut,
        lsuMuxDataOut,
        memAddr,
        memData,
        memWE,
        memValid,
        mshrValid,
        mshrAddr,
        mshrPhase,
        mshrAddrSubset,
    output
        lsuCacheReq,
        lsuMuxIn,
        memReqAck,
        memSerial,
        memWSerial,
        memAccessResponse,
        isAllocatedByStore,
        makeMSHRCanBeInvalidByMemoryRegisterReadStage,
        makeMSHRCanBeInvalidByMemoryTagAccessStage,
        makeMSHRCanBeInvalidByReplayQueue,
        storedLineData,
        storedLineByteWE
    );

endinterface
// ---- Cache/ICache.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A set-associative instruction cache (non-blocking)
// Replacement policy: NRU (not-recently used)
//


import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryMapTypes::*;

module ICacheArray(
    input  logic           clk, rst, rstStart,
    input  logic           we,
    input  ICacheIndexPath writeIndex,
    input  ICacheTagPath   writeTag,
    input  ICacheLinePath  writeLineData,
    input  ICacheIndexPath readIndex, // The result comes after 1 cycle from the request
    input  ICacheTagPath   readTag,
    output ICacheLinePath  readLineData,
    output logic           hit, valid
);

    typedef struct packed {
        ICacheLinePath     data;
        ICacheTagValidPath meta;
    } WayData;

    logic weWay;
    ICacheIndexPath rstIndex;
    ICacheIndexPath writeWayIndex;
    WayData readWayData, writeWayData;

    // tag + instruction array
    BlockDualPortRAM #( 
        .ENTRY_NUM( ICACHE_INDEX_NUM ),
        .ENTRY_BIT_SIZE( $bits(WayData)  )
    ) tagValidArray ( 
        .clk( clk ),
        .we( weWay ),
        .wa( writeWayIndex ),
        .wv( writeWayData ),
        .ra( readIndex ),
        .rv( readWayData )
    );

    always_comb begin
        // ICacheTagPath-array write
        if ( rst ) begin
            weWay = TRUE;
            writeWayIndex = rstIndex;
            writeWayData.meta.valid = FALSE;
        end
        else begin
            weWay = we;
            writeWayIndex = writeIndex;
            writeWayData.meta.valid = TRUE;
        end
        writeWayData.meta.tag = writeTag;
        writeWayData.data = writeLineData;
        readLineData = readWayData.data;
        // Result of tag-array read
        valid = readWayData.meta.valid;
        hit = valid && readWayData.meta.tag == readTag;
    end

    
    // Reset Index
    always_ff @ ( posedge clk ) begin
        if ( rstStart ) begin
            rstIndex <= '0;
        end
        else begin
            rstIndex <= rstIndex + 1;
        end
    end

endmodule

//
// NRUStateArray
//
module ICacheNRUStateArray(
    input  logic              clk, rst, rstStart,
    input  ICacheIndexPath    writeIndex,
    input  ICacheWayPath      writeWay,
    input  logic              writeHit,
    input  NRUAccessStatePath writeNRUState,
    input  ICacheIndexPath    readIndex,
    output NRUAccessStatePath readNRUState
);
    ICacheIndexPath rstIndex;
    logic we;
    ICacheIndexPath writeNRUStateIndex;
    NRUAccessStatePath writeNRUStateData;

    // NRUStateArray array
    BlockDualPortRAM #(
        .ENTRY_NUM( ICACHE_INDEX_NUM ),
        .ENTRY_BIT_SIZE( $bits( NRUAccessStatePath ) )
    ) nruStateArray (
        .clk( clk ),
        .we( we ),
        .wa( writeNRUStateIndex ),
        .wv( writeNRUStateData ),
        .ra( readIndex ),
        .rv( readNRUState )
    );

    always_comb begin
        if ( rst ) begin
            we = TRUE;
            writeNRUStateIndex = rstIndex;
            writeNRUStateData = '0;
        end
        else begin
            we = writeHit;
            writeNRUStateIndex = writeIndex;
            writeNRUStateData = writeNRUState;
        end
    end
    // Reset Index
    always_ff @ ( posedge clk ) begin
        if ( rstStart ) begin
            rstIndex <= '0;
        end
        else begin
            rstIndex <= rstIndex + 1;
        end
    end

endmodule

//
// Generate hit signals for each word.
//
module ICacheHitLogic(
input
    logic hitIn,
    ICacheLineInsnIndexPath headWordPtr,
output
    logic hitOut [ FETCH_WIDTH ]
);
    ICacheLineInsnCountPath wordPtr [ FETCH_WIDTH ];
    
    always_comb begin
        for ( int i = 0; i < FETCH_WIDTH; i++ ) begin
            wordPtr[i] = headWordPtr + i;
            if ( wordPtr[i][ $clog2(ICACHE_LINE_INSN_NUM) ] ) begin
                // If this condition is satisfied, word[i] is not on the same line as word[0].
                // It means cache-miss.
                hitOut[i] = FALSE;
            end
            else begin
                hitOut[i] = hitIn;
            end
        end
    end

endmodule

module ICache(
    NextPCStageIF.ICache port,
    FetchStageIF.ICache next,
    CacheSystemIF.ICache cacheSystem
);
    
    //
    // ICacheIndexPath, ICacheTagPath -> Physical Address
    //
    function automatic PhyAddrPath GetFullPhyAddr ( ICacheIndexPath index, ICacheTagPath tag );
        return { tag, index, { ICACHE_LINE_BYTE_NUM_BIT_WIDTH{1'b0} } };
    endfunction
    
    //
    // PC -> ICacheIndexPath, ICacheTagPath etc.
    //
    function automatic ICacheIndexPath GetICacheIndex( PhyAddrPath addr );
        return addr [
            PHY_ADDR_WIDTH - ICACHE_TAG_BIT_WIDTH - 1 : 
            ICACHE_LINE_BYTE_NUM_BIT_WIDTH 
        ];
    endfunction
    
    function automatic ICacheTagPath GetICacheTag( PhyAddrPath addr );
        return addr [ 
            PHY_ADDR_WIDTH - 1 : 
            PHY_ADDR_WIDTH - ICACHE_TAG_BIT_WIDTH 
        ];
    endfunction
    
    function automatic ICacheLineInsnIndexPath GetICacheLineInsnIndex( PhyAddrPath addr );
        return addr [ 
            ICACHE_LINE_BYTE_NUM_BIT_WIDTH-1 : 
            INSN_ADDR_BIT_WIDTH 
        ];
    endfunction
    
    //
    // NRUState, Access -> NRUState
    // NRUState         -> Evicted way (one-hot)
    //
    function automatic NRUAccessStatePath UpdateNRUState( NRUAccessStatePath NRUState, ICacheWayPath way );

        if ( (NRUState | (1 << way)) == (1 << ICACHE_WAY_NUM) - 1 ) begin 
            // if all NRU state bits are high, NRU state needs to clear
            return 1 << way;
        end
        else begin
            // Update indicated NRU state bit 
            return NRUState | (1 << way);
        end
    endfunction

    function automatic NRUAccessStatePath DecideWayToEvictByNRUState( NRUAccessStatePath NRUState );
        // return the position of the rightmost 0-bit
        // e.g. NRUState = 10011 -> return 00100
        return (NRUState | NRUState + 1) ^ NRUState;
    endfunction

    //
    // Phase of ICache
    //
    typedef enum logic [1:0]
    {
        ICACHE_PHASE_READ_CACHE = 0,
        ICACHE_PHASE_MISS_READ_MEM_REQUEST = 1,   // Read from a main memory to a cache.
        ICACHE_PHASE_MISS_READ_MEM_RECEIVE = 2,   // Read from a main memory to a cache.
        ICACHE_PHASE_MISS_WRITE_CACHE = 3         // Write data to a cache.
    } ICachePhase;
    ICachePhase regPhase, nextPhase;

    always_ff @( posedge port.clk ) begin
        if ( port.rst ) begin
            regPhase <= ICACHE_PHASE_READ_CACHE;
        end
        else begin
            regPhase <= nextPhase;
        end
    end
    
    //
    // ICacheArray
    //
    logic valid[ICACHE_WAY_NUM];
    logic hit;
    logic[ICACHE_WAY_NUM-1:0] hitArray;
    ICacheWayPath hitWay;
    logic we[ICACHE_WAY_NUM];
    ICacheIndexPath readIndex, writeIndex, nextReadIndex;
    ICacheTagPath readTag, writeTag;
    ICacheLineInsnPath readLineInsnList[ICACHE_WAY_NUM];

    generate
        for ( genvar i = 0; i < ICACHE_WAY_NUM; i++ ) begin
            ICacheArray array(
                .clk( port.clk ),
                .rst( port.rst ),
                .rstStart( port.rstStart ),
                .we( we[i] ),
                .writeIndex( writeIndex ),
                .writeTag( writeTag ),
                .writeLineData( cacheSystem.icMemAccessResult.data ),
                .readIndex( nextReadIndex ),
                .readTag( readTag ),
                .hit( hitArray[i] ),
                .valid( valid[i] ),
                .readLineData( readLineInsnList[i] )
            );
        end
    endgenerate
    
    always_comb begin
        // Set signal about read address.
        readIndex  = GetICacheIndex( next.icReadAddrIn );
        readTag = GetICacheTag( next.icReadAddrIn );
        
        nextReadIndex = GetICacheIndex( port.icNextReadAddrIn );

        // Check cache hit 
        hit = |hitArray;
        hitWay = '0;
        for (int i = 0; i < ICACHE_WAY_NUM; i++) begin
            if (hitArray[i]) begin
                // Detect which way is hit
                hitWay = i;
                break;
            end
        end
    end

    //
    // ICacheNRUStateArray
    //
    NRUAccessStatePath updatedNRUState, readNRUState;
    NRUAccessStatePath wayToEvictOneHot;
    ICacheWayPath wayToEvict;
    logic nruStateWE;
    ICacheNRUStateArray nruStateArray(
        .clk( port.clk ),
        .rst( port.rst ),
        .rstStart( port.rstStart ),
        .writeIndex( readIndex ),
        .writeWay( hitWay ),
        .writeHit( nruStateWE ),
        .writeNRUState( updatedNRUState ),
        .readIndex( nextReadIndex ),
        .readNRUState( readNRUState )
    );

    always_comb begin
        updatedNRUState = UpdateNRUState(readNRUState, hitWay);
        wayToEvictOneHot = DecideWayToEvictByNRUState(readNRUState);
        wayToEvict = '0;

        for ( int i = 0; i < ICACHE_WAY_NUM; i++ ) begin
            if ( wayToEvictOneHot[i] ) begin
                wayToEvict = i;
                break;
            end
        end
    end

    //
    // HitLogic
    // Check whether each read request is satisfied
    //
    ICacheLineInsnIndexPath wordPtr[ FETCH_WIDTH ];
    ICacheHitLogic iCacheHitLogic (
        .hitIn( hit && regPhase == ICACHE_PHASE_READ_CACHE && next.icRE ),
        .headWordPtr( wordPtr[0] ),
        .hitOut( next.icReadHit )
    );
    
    //
    // ICache Read
    //
    
    always_comb begin
        wordPtr[0] = GetICacheLineInsnIndex( next.icReadAddrIn );
        for ( int i = 1; i < FETCH_WIDTH; i++ ) begin
            wordPtr[i] = wordPtr[0] + i;
        end
        
        // Send i-cache read data to FetchStage
        for ( int i = 0; i < FETCH_WIDTH; i++ ) begin
            next.icReadDataOut[i] = readLineInsnList[hitWay][ wordPtr[i] ];
        end
    end
    
    
    //
    // ICache Miss Handling
    //
    logic regMissValid, nextMissValid;
    ICacheIndexPath regMissIndex, nextMissIndex;
    ICacheTagPath regMissTag, nextMissTag;
    MemAccessSerial regSerial, nextSerial;
    
    always_comb begin
        for ( int i = 0; i < ICACHE_WAY_NUM; i++ ) begin
            we[i] = FALSE;
        end
        nruStateWE = FALSE;

        nextPhase = regPhase;
        
        nextMissValid = regMissValid;
        nextMissIndex = regMissIndex;
        nextMissTag = regMissTag;
        nextSerial = regSerial;
        
        // Non-blocking i-cache state machine
        case (regPhase)
        default: begin
            nextPhase = ICACHE_PHASE_READ_CACHE;
        end
        ICACHE_PHASE_READ_CACHE: begin
            // Not processing cache miss now
            if ( next.icRE && !hit ) begin
                // Read request -> i-cache miss:
                // Change state to process a cache miss
                nextPhase = ICACHE_PHASE_MISS_READ_MEM_REQUEST;
                nextMissValid = TRUE;
                nextMissIndex = readIndex;
                nextMissTag = readTag;
            end
            else if ( next.icRE )begin
                // Read request -> i-cache hit:
                // Update nru state
                nruStateWE = TRUE;
            end
        end
        ICACHE_PHASE_MISS_READ_MEM_REQUEST: begin
            // Send read request to lower level memory
            if ( cacheSystem.icMemAccessReqAck.ack ) begin
                nextPhase = ICACHE_PHASE_MISS_READ_MEM_RECEIVE;
                nextMissValid = FALSE;
                nextSerial = cacheSystem.icMemAccessReqAck.serial;
            end
        end
        ICACHE_PHASE_MISS_READ_MEM_RECEIVE: begin
            // Read response has come
            if (
                cacheSystem.icMemAccessResult.valid &&
                cacheSystem.icMemAccessResult.serial == regSerial
            ) begin
                // Receive memory read data and write it to i-cache
                nextPhase = ICACHE_PHASE_MISS_WRITE_CACHE;
                we[wayToEvict] = TRUE;
            end
        end
        ICACHE_PHASE_MISS_WRITE_CACHE: begin
            // Cannot read the write data in the same cycle,
            // therefore wait 1-cycle
            nextPhase = ICACHE_PHASE_READ_CACHE;
        end
        endcase // regPhase

        writeIndex = regMissIndex;
        writeTag = regMissTag;

        cacheSystem.icMemAccessReq.valid = regMissValid;
        cacheSystem.icMemAccessReq.addr = 
            GetFullPhyAddr( regMissIndex, regMissTag );
    end
    
    always_ff @( posedge port.clk ) begin
        if ( port.rst ) begin
            regMissValid <= FALSE;
            regMissIndex <= '0;
            regMissTag <= '0;
            regSerial <= '0;
        end
        else begin
            regMissValid <= nextMissValid;
            regMissIndex <= nextMissIndex;
            regMissTag <= nextMissTag;
            regSerial <= nextSerial;
        end
        
    end
    
`ifndef RSD_SYNTHESIS
    initial begin
        regMissIndex <= '0;
        regMissTag <= '0;
        regSerial <= '0;
    end
    `RSD_ASSERT_CLK(port.clk, $onehot0(we), "Signal we is not one-hot or 0."); 
    `RSD_ASSERT_CLK(port.clk, $onehot0(hit), "Signal hit is not one-hot or 0.");
`endif
    

endmodule
// ---- Cache/CachePrimitives.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;

//
// Select a way for cache-replacement.
//
module VictimWaySelecter #( parameter WAY_NUM = 2 ) 
(
input
    logic [ WAY_NUM-1:0 ] valid,
    logic unsigned [ $clog2(WAY_NUM)-1:0 ] victimCandidateWayPtr,
output
    logic unsigned [ $clog2(WAY_NUM)-1:0 ] victimWayPtr
);
    logic existInvalidWay;
    logic [ $clog2(WAY_NUM)-1:0 ] invalidWayPtr;
    
    always_comb begin
        existInvalidWay = FALSE;
        invalidWayPtr = 0;
        
        for ( int i = 0; i < WAY_NUM; i++ ) begin
            if ( !valid[i] ) begin
                existInvalidWay = TRUE;
                invalidWayPtr = i;
                break;
            end
        end
        
        victimWayPtr = existInvalidWay ? invalidWayPtr : victimCandidateWayPtr;
    end
endmodule

// ---- Cache/MemoryAccessController.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Memory Access Controller
// キャッシュとメモリの間に存在し、
// メモリアクセス要求の形式を変換する。
// ICacheとDCacheからのアクセスの調停も行う。
//


import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryTypes::*;
import MemoryMapTypes::*;

module MemoryAccessController (
    CacheSystemIF.MemoryAccessController port,
input
    MemAccessSerial nextMemReadSerial, // RSDの次の読み出し要求に割り当てられるシリアル(id)
    MemWriteSerial nextMemWriteSerial, // RSDの次の書き込み要求に割り当てられるシリアル(id)
    MemoryEntryDataPath memReadData,
    logic memReadDataReady,
    MemAccessSerial memReadSerial, // メモリの読み出しデータのシリアル
    MemAccessResponse memAccessResponse, // メモリ書き込み完了通知
    logic memAccessReadBusy,
    logic memAccessWriteBusy,
output
    PhyAddrPath memAccessAddr,
    MemoryEntryDataPath memAccessWriteData,
    logic memAccessRE,
    logic memAccessWE
);
    // ICache/DCacheからの要求を受理するか否か
    logic icAck;
    logic dcAck;

    // メモリアクセスのシリアル番号を保持するカウンタ
    // 現在の実装では、読出し
    MemAccessSerial reqSerial, nextReqSerial;
    MemAccessSerial resultSerial, nextResultSerial;

    always_ff @( posedge port.clk ) begin
        if ( port.rst ) begin
            reqSerial <= '0;
            resultSerial <= '0;
        end
        else begin
            reqSerial <= nextReqSerial;
            resultSerial <= nextResultSerial;
        end
    end

    // メモリへのアクセス要求
    always_comb begin
        // ICache/DCacheの要求を受けるor何もしない を決定
        icAck = FALSE;
        dcAck = FALSE;
        if ( !memAccessReadBusy && port.icMemAccessReq.valid )
            icAck = TRUE;
        else if ( !memAccessReadBusy && port.dcMemAccessReq.valid && ( port.dcMemAccessReq.we == FALSE ) )
            dcAck = TRUE;
        else if ( !memAccessWriteBusy && port.dcMemAccessReq.valid  && ( port.dcMemAccessReq.we == TRUE ) )
            dcAck = TRUE;

        // ICache/DCacheの要求を受ける場合、
        // それに従ってメモリへリクエストを送る
        if ( icAck ) begin
            memAccessAddr = port.icMemAccessReq.addr;
            memAccessWriteData = '0;
            memAccessRE = TRUE;
            memAccessWE = FALSE;
        end
        else if ( dcAck ) begin
            memAccessAddr = port.dcMemAccessReq.addr;
            memAccessWriteData = port.dcMemAccessReq.data;
            memAccessRE = ( port.dcMemAccessReq.we ? FALSE : TRUE );
            memAccessWE = ( port.dcMemAccessReq.we ? TRUE : FALSE );
        end
        else begin
            memAccessAddr = '0;
            memAccessWriteData = '0;
            memAccessRE = FALSE;
            memAccessWE = FALSE;
        end

        // Ack for Request
        port.icMemAccessReqAck.ack = icAck;
        port.icMemAccessReqAck.serial = nextMemReadSerial; // I-Cacheは読み出し要求しかしない
        port.dcMemAccessReqAck.ack = dcAck;
        // D-Cacheの要求は書き込みと読み出しの2種類あり，シリアルは独立に管理されている
        port.dcMemAccessReqAck.serial = nextMemReadSerial;
        port.dcMemAccessReqAck.wserial = nextMemWriteSerial;
    end

    // メモリの読出し結果
    always_comb begin
        port.icMemAccessResult.valid = memReadDataReady;
        port.icMemAccessResult.serial = memReadSerial;
        port.icMemAccessResult.data = memReadData;
        port.dcMemAccessResult.valid = memReadDataReady;
        port.dcMemAccessResult.serial = memReadSerial;
        port.dcMemAccessResult.data = memReadData;
        port.dcMemAccessResponse = memAccessResponse;
    end

    // MemAccessSerial
    always_comb begin
        nextReqSerial = reqSerial;
        nextResultSerial = resultSerial;

        // 読出要求が来たら、reqSerialをインクリメント
        if ( icAck || ( dcAck && port.dcMemAccessReq.we == FALSE ) ) begin
            nextReqSerial = reqSerial + 1;
        end

        // 読出結果が来たら、resultSerialをインクリメント
        if ( memReadDataReady ) begin
            nextResultSerial = resultSerial + 1;
        end
    end

    // 現在の実装では、キャッシュラインのデータ幅とメモリの入出力データ幅は
    // 同じである必要がある。
    `RSD_STATIC_ASSERT(
        $bits(ICacheLinePath) == $bits(MemoryEntryDataPath), 
        ("The data width of a cache line(%x) and a memory entry(%x) are not matched.", $bits(ICacheLinePath), $bits(MemoryEntryDataPath))
    );
    `RSD_STATIC_ASSERT(
        $bits(DCacheLinePath) == $bits(MemoryEntryDataPath),
        ("The data width of a cache line(%x) and a memory entry(%x) are not matched.", $bits(DCacheLinePath), $bits(MemoryEntryDataPath))
    );
endmodule

// ---- Recovery/RecoveryManager.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Recovery Manager
//   リカバリに遷移する信号を各モジュールにブロードキャストするモジュール
//   モジュールのリカバリ自体はそれぞれのモジュール中で記述される
//
// 例外が起きてリカバリが行われる様子は以下のようになっている
// 1. RwStageもしくはCmStageからexceptionDetected信号が, RecoveryManagerに発信される
// 2. exceptionDetected信号があさーとされた次のサイクルに, 各モジュールにtoRecoveryPhase信号が発信される(PHASE_RECOVER_0)
// 3. すべてのモジュールのリカバリが終わったことを確認したら, 各モジュールにtoCommitPhase信号を送り, リカバリ終了


import BasicTypes::*;
import MemoryMapTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;

module RecoveryManager(
    RecoveryManagerIF.RecoveryManager port,
    ActiveListIF.RecoveryManager activeList,
    CSR_UnitIF.RecoveryManager csrUnit,
    ControllerIF.RecoveryManager ctrl
);
    typedef struct packed
    {
        // リカバリのフェーズ
        // 実行ステージからリカバリがかかる場合もあるので，
        // コミットステージのフェーズと同期しているわけではない
        PipelinePhase phase;

        // リカバリ要求
        // これらはステージの終わりのあたりで来ることが多いので，一旦レジスタに積んで
        // パイプライン化する
        logic exceptionDetectedInCommitStage;
        AddrPath recoveredPC_FromRwStage;
        AddrPath recoveredPC_FromCommitStage;

        // Related to CSR 
        // これらもパイプライン化のため
        ExecutionState excptCause;      // Trap vector or MRET return target
        AddrPath excptCauseDataAddr;    // fault 発生時のデータアドレス

        // ActiveList中のどのエントリがどのエントリまでをフラッシュするかを示すポインタ
        ActiveListIndexPath flushRangeHeadPtr;
        ActiveListIndexPath flushRangeTailPtr;
     
        logic recoveryFromRwStage;  // 例外がどこのステージで検出されたか
        RefetchType refetchType;    // リフェッチのタイプ

    } RecoveryManagerStatePath;
    RecoveryManagerStatePath regState;
    RecoveryManagerStatePath nextState;

    // 各モジュールに送られる信号
    // リカバリ時の動作自体は各モジュールで記述される
    logic toRecoveryPhase, toCommitPhase;

    // CSR からリフェッチするかどうか
    logic refetchFromCSR;

    //リカバリによって回復されるPC
    PC_Path recoveredPC;

    // 例外を起こした命令のActiveListのポインタ
    ActiveListIndexPath exceptionOpPtr;

    // 例外が検出された後リカバリ状態に移行する
    logic exceptionDetected;

    always_ff@(posedge port.clk) begin  // synchronous rst
        if (!port.rst) begin
            regState <= nextState;
        end
        else begin
            regState.phase <= PHASE_COMMIT;
            regState.flushRangeHeadPtr <= '0;
            regState.flushRangeTailPtr <= '0;
            regState.recoveryFromRwStage <= FALSE;
            regState.refetchType <= REFETCH_TYPE_THIS_PC;

            regState.exceptionDetectedInCommitStage <= '0;
            regState.recoveredPC_FromRwStage <= '0;
            regState.recoveredPC_FromCommitStage <= '0;

            regState.excptCause <= EXEC_STATE_NOT_FINISHED;
            regState.excptCauseDataAddr <= '0;
        end
    end


    always_comb begin
        // To Recovery 0
        toRecoveryPhase = 
            port.exceptionDetectedInCommitStage || 
            port.exceptionDetectedInRwStage;
        if (toRecoveryPhase) begin
            nextState.recoveryFromRwStage = port.exceptionDetectedInRwStage;
        end
        else begin
            nextState.recoveryFromRwStage = FALSE;
        end

        // Return to COOMIT_PHASE
        toCommitPhase =
            (regState.phase == PHASE_RECOVER_1) &&  // must be PHASE_RECOVER_1 because PHASE_RECOVER_0 procedures has been finished
            !(port.renameLogicRecoveryRMT || port.issueQueueReturnIndex); // LSQ は1サイクルでリカバリが行われるので待つべきは RMT と IQ
        nextState.refetchType = 
            port.exceptionDetectedInCommitStage ? 
                port.refetchTypeFromCommitStage : 
                port.refetchTypeFromRwStage;

        // Trap/fault origin
        // これらの要求は一旦レジスタに積む
        nextState.excptCause = port.recoveryCauseFromCommitStage;
        nextState.excptCauseDataAddr = port.faultingDataAddr;
        nextState.exceptionDetectedInCommitStage = port.exceptionDetectedInCommitStage;
        nextState.recoveredPC_FromRwStage = port.recoveredPC_FromRwStage;
        nextState.recoveredPC_FromCommitStage = port.recoveredPC_FromCommitStage;

        // CSR への要求はすべて PHASE_RECOVER_0 に行う
        refetchFromCSR = regState.refetchType inside {
            REFETCH_TYPE_NEXT_PC_TO_CSR_TARGET, REFETCH_TYPE_THIS_PC_TO_CSR_TARGET
        };
        csrUnit.triggerExcpt = (regState.phase == PHASE_RECOVER_0) && refetchFromCSR;
        csrUnit.excptCauseAddr = ToPC_FromAddr(regState.recoveredPC_FromCommitStage);
        csrUnit.excptCause = regState.excptCause;
        csrUnit.excptCauseDataAddr = regState.excptCauseDataAddr;

        // Recovered PC
        if(regState.phase == PHASE_RECOVER_0) begin
            if (refetchFromCSR) begin
                recoveredPC = ToPC_FromAddr(csrUnit.excptTargetAddr);
            end
            else begin
                if (regState.refetchType == REFETCH_TYPE_THIS_PC) begin
                    recoveredPC = regState.exceptionDetectedInCommitStage ?
                        ToPC_FromAddr(regState.recoveredPC_FromCommitStage) : 
                        ToPC_FromAddr(regState.recoveredPC_FromRwStage);
                end
                else if (regState.refetchType inside{REFETCH_TYPE_NEXT_PC, REFETCH_TYPE_STORE_NEXT_PC}) begin
                    recoveredPC = regState.exceptionDetectedInCommitStage ?
                        ToPC_FromAddr(regState.recoveredPC_FromCommitStage) + INSN_BYTE_WIDTH : 
                        ToPC_FromAddr(regState.recoveredPC_FromRwStage) + INSN_BYTE_WIDTH;
                end
                else begin // REFETCH_TYPE_BRANCH_TARGET
                    recoveredPC = regState.exceptionDetectedInCommitStage ?
                        ToPC_FromAddr(regState.recoveredPC_FromCommitStage) : 
                        ToPC_FromAddr(regState.recoveredPC_FromRwStage);
                end
            end
        end
        else begin
            recoveredPC = '0;
        end

        // Commit/Recovery state manage
        assert(!(toCommitPhase && toRecoveryPhase));

        if(port.rst) begin
            nextState.phase = PHASE_COMMIT;
        end
        else if(regState.phase == PHASE_COMMIT) begin
            nextState.phase = toRecoveryPhase ? PHASE_RECOVER_0 : PHASE_COMMIT;
        end
        else if(regState.phase == PHASE_RECOVER_0) begin
            nextState.phase = PHASE_RECOVER_1;
        end
        else begin
            nextState.phase = toCommitPhase ? PHASE_COMMIT : regState.phase;
        end

        port.phase = regState.phase;

        // Update a PC in a fetcher if branch misprediction occurs.
        port.recoveredPC_FromRwCommit = recoveredPC;
        port.toCommitPhase = toCommitPhase;

        // To each logic to be recovered.
        port.toRecoveryPhase = regState.phase == PHASE_RECOVER_0;
        port.recoveryFromRwStage = regState.recoveryFromRwStage;

        // 選択的フラッシュにおいても，フロントエンドは全てフラッシュされる
        ctrl.cmStageFlushUpper = regState.phase == PHASE_RECOVER_0;

        // フラッシュする命令の範囲の管理
        exceptionDetected = port.exceptionDetectedInCommitStage || port.exceptionDetectedInRwStage;
        exceptionOpPtr = activeList.exceptionOpPtr;

        nextState.flushRangeHeadPtr = 
            (nextState.refetchType inside {REFETCH_TYPE_THIS_PC, REFETCH_TYPE_THIS_PC_TO_CSR_TARGET}) ?
                exceptionOpPtr : exceptionOpPtr + 1;
        nextState.flushRangeTailPtr = activeList.detectedFlushRangeTailPtr;
        port.loadQueueRecoveryTailPtr = activeList.loadQueueRecoveryTailPtr;
        port.storeQueueRecoveryTailPtr = 
            regState.refetchType == REFETCH_TYPE_STORE_NEXT_PC ? 
                (activeList.storeQueueRecoveryTailPtr + 1): activeList.storeQueueRecoveryTailPtr;

        port.flushRangeHeadPtr = regState.flushRangeHeadPtr;
        port.flushRangeTailPtr = regState.flushRangeTailPtr;

        // 
        port.unableToStartRecovery = 
            (regState.phase != PHASE_COMMIT) || 
            port.renameLogicRecoveryRMT || 
            port.issueQueueReturnIndex || 
            port.replayQueueFlushedOpExist || 
            port.wakeupPipelineRegFlushedOpExist;

    end

    `RSD_ASSERT_CLK(
        port.clk,
        !(port.exceptionDetectedInRwStage && nextState.refetchType inside {REFETCH_TYPE_NEXT_PC_TO_CSR_TARGET, REFETCH_TYPE_THIS_PC_TO_CSR_TARGET} ),
        "RW stage recovery is not allowed in REFETCH_TYPE_CSR_UNIT_TARGET"
    );

endmodule : RecoveryManager
// ---- Recovery/RecoveryManagerIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- RecoveryManagerIF
//

import BasicTypes::*;
import PipelineTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import LoadStoreUnitTypes::*;

interface RecoveryManagerIF( input logic clk, rst );

    // Phase of a pipeline
    PipelinePhase phase;

    // A type of exception from CommitStage
    RefetchType refetchTypeFromCommitStage;

    // A type of exception from CommitStage
    RefetchType refetchTypeFromRwStage;

    // Index of detected exception op in CommitStage
    CommitLaneIndexPath recoveryOpIndex;

    // Exception detected in CommitStage
    logic exceptionDetectedInCommitStage;

    // Exception detected in RwStage
    logic exceptionDetectedInRwStage;

    // PC control
    logic    toCommitPhase;
    AddrPath recoveredPC_FromCommitStage;
    AddrPath recoveredPC_FromRwStage;
    AddrPath recoveredPC_FromRwCommit;      // Correct PC

    // For fault handling
    AddrPath faultingDataAddr;

    //　Miss prediction detected in RenameStage
    logic    recoverFromRename;
    AddrPath recoveredPC_FromRename;

    // Trigger recovery of each module
    logic toRecoveryPhase;

    // Flush range to broadcast
    ActiveListIndexPath flushRangeHeadPtr;
    ActiveListIndexPath flushRangeTailPtr;

    // ActiveList/LSQ TailPtr for recovery
    LoadQueueIndexPath loadQueueRecoveryTailPtr;
    LoadQueueIndexPath loadQueueHeadPtr;
    StoreQueueIndexPath storeQueueRecoveryTailPtr;
    StoreQueueIndexPath storeQueueHeadPtr;

    // IssueQueueEntryPtr to be flushed at recovery
    IssueQueueOneHotPath flushIQ_Entry;

    // In IQ returning index to freelist
    logic issueQueueReturnIndex;

    // In AL recovery
    logic inRecoveryAL;

    // In RMT recovery
    logic renameLogicRecoveryRMT;

    // In ReplayQueue flushing
    logic replayQueueFlushedOpExist;

    // In wakeupPipelineReg flushing
    logic wakeupPipelineRegFlushedOpExist;

    // Unable to detect exception and start recovery
    logic unableToStartRecovery;

    // IssueQueueのflushが必要なエントリかどうかの判定に使う
    IssueQueueOneHotPath notIssued;

    // wakeupPipelineRegister内の命令のフラッシュに使う
    logic selected [ ISSUE_WIDTH ];
    IssueQueueIndexPath selectedPtr [ ISSUE_WIDTH ];
    ActiveListIndexPath selectedActiveListPtr [ ISSUE_WIDTH ];

    // RwStageからのリカバリかどうか
    //toRecoveryPhaseと同時に立ちTrueでないときCommitStageからのリカバリ
    logic recoveryFromRwStage;

    // Why recovery is caused
    ExecutionState recoveryCauseFromCommitStage;

    modport RecoveryManager(
    input
        clk,
        rst,
        exceptionDetectedInCommitStage,
        refetchTypeFromCommitStage,
        exceptionDetectedInRwStage,
        refetchTypeFromRwStage,
        renameLogicRecoveryRMT,
        issueQueueReturnIndex,
        replayQueueFlushedOpExist,
        wakeupPipelineRegFlushedOpExist,
        recoveredPC_FromCommitStage,
        recoveredPC_FromRwStage,
        faultingDataAddr,
        notIssued,
        flushIQ_Entry,
        recoveryCauseFromCommitStage,
    output
        phase,
        toRecoveryPhase,
        recoveredPC_FromRwCommit,
        toCommitPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr,
        unableToStartRecovery,
        recoveryFromRwStage,
        loadQueueRecoveryTailPtr,
        storeQueueRecoveryTailPtr
    );

    modport RenameStage(
    output
        recoverFromRename,
        recoveredPC_FromRename
    );

    modport CommitStage(
    input
        phase,
        unableToStartRecovery,
        renameLogicRecoveryRMT,
    output
        exceptionDetectedInCommitStage,
        recoveryOpIndex,
        refetchTypeFromCommitStage,
        recoveryCauseFromCommitStage
    );

    modport NextPCStage(
    input
        toCommitPhase,
        toRecoveryPhase,
        recoveredPC_FromRwCommit,
        recoverFromRename,
        recoveredPC_FromRename
    );

    modport RenameLogic(
    input
        toRecoveryPhase,
        inRecoveryAL,
    output
        renameLogicRecoveryRMT
    );

    modport RenameLogicCommitter(
    input
        toRecoveryPhase,
        toCommitPhase,
    output
        inRecoveryAL
    );

    modport IssueQueue(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr,
        notIssued,
        selected,
        selectedPtr,
        recoveryFromRwStage,
    output
        flushIQ_Entry,
        issueQueueReturnIndex,
        selectedActiveListPtr
    );

    modport Scheduler(
    input
        toRecoveryPhase,
        flushIQ_Entry,
    output
        notIssued
    );

    modport ScheduleStage(
    input
        toRecoveryPhase,
        flushIQ_Entry
    );

    modport SelectLogic(
    output
        selected,
        selectedPtr
    );

    modport ReplayQueue(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr,
        recoveryFromRwStage,
    output
        replayQueueFlushedOpExist
    );

    modport WakeupPipelineRegister(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr,
        selectedActiveListPtr,
        flushIQ_Entry,
        recoveryFromRwStage,
    output
        wakeupPipelineRegFlushedOpExist
    );

    modport LoadQueue(
    input
        toRecoveryPhase,
        loadQueueRecoveryTailPtr,
    output
        loadQueueHeadPtr
    );

    modport StoreQueue(
    input
        toRecoveryPhase,
        storeQueueRecoveryTailPtr,
    output
        storeQueueHeadPtr
    );

    modport StoreCommitter(
    input
        toRecoveryPhase
    );


    modport IntegerIssueStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport IntegerRegisterReadStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport IntegerExecutionStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport IntegerRegisterWriteStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport ComplexIntegerIssueStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport ComplexIntegerRegisterReadStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport ComplexIntegerExecutionStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport ComplexIntegerRegisterWriteStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport MemoryIssueStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport MemoryRegisterReadStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport MemoryExecutionStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport MemoryTagAccessStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport MemoryAccessStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport MemoryRegisterWriteStage(
    input
        toRecoveryPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr
    );

    modport ActiveList(
    input
        toRecoveryPhase,
        toCommitPhase,
        flushRangeHeadPtr,
        flushRangeTailPtr,
        unableToStartRecovery,
    output
        exceptionDetectedInRwStage,
        refetchTypeFromRwStage,
        recoveredPC_FromCommitStage,
        recoveredPC_FromRwStage,
        faultingDataAddr
    );

    modport InterruptController(
    input
        unableToStartRecovery
    );

endinterface : RecoveryManagerIF

// ---- ControllerIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Controller
//

import BasicTypes::*;
import PipelineTypes::*;


interface ControllerIF(
input
    logic clk,
    logic rst
);


    //
    // Pipeline
    //
    // PipelineControll::stall は，そのステージの頭にあるパイプラインレジスタの
    // 書き込み制御を行う．たとえば ifStage であれば PC の，idStage であれば，
    // if/id ステージ間のパイプラインレジスタの WE に接続される．
    //
    // PipelineControll::clear は，有効な場合，そのステージの次のステージに送り
    // 込む命令の valid を強制的に落とす（次のステージにNOPを送る）．
    // これは，そのサイクルにそのステージにいる命令を無効化し，
    // 次のステージにNOP を送り込むことを意味する．
    //
    PipelineControll npStage;
    PipelineControll ifStage;
    PipelineControll pdStage;
    PipelineControll idStage;
    PipelineControll rnStage;
    PipelineControll dsStage;

    PipelineControll scStage;
    PipelineControll isStage;
    PipelineControll backEnd;
    PipelineControll cmStage;

    // 生きた命令がいるかどうか
    logic ifStageEmpty;
    logic pdStageEmpty;
    logic idStageEmpty;
    logic rnStageEmpty;
    logic activeListEmpty;
    logic wholePipelineEmpty;

    //
    // --- Requests from pipeline stages.
    //
    logic npStageSendBubbleLower;
    logic npStageSendBubbleLowerForInterrupt;
    logic ifStageSendBubbleLower;
    logic idStageStallUpper;
    logic rnStageFlushUpper;
    logic rnStageSendBubbleLower;
    logic cmStageFlushUpper;
    logic isStageStallUpper;

    //
    // --- Special signals
    //
    logic stallByDecodeStage;

    modport Controller(
    input
        clk,
        rst,
        cmStageFlushUpper,
        rnStageSendBubbleLower,
        idStageStallUpper,
        rnStageFlushUpper,
        npStageSendBubbleLower,
        ifStageSendBubbleLower,
        npStageSendBubbleLowerForInterrupt,
        isStageStallUpper,
        ifStageEmpty,
        pdStageEmpty,
        idStageEmpty,
        rnStageEmpty,
        activeListEmpty,
    output
        npStage,
        ifStage,
        pdStage,
        idStage,
        rnStage,
        dsStage,
        isStage,
        scStage,
        backEnd,
        cmStage,
        stallByDecodeStage,
        wholePipelineEmpty
    );

    modport NextPCStage(
    input
        npStage,
    output
        npStageSendBubbleLower
    );

    modport FetchStage(
    input
        ifStage,
    output
        ifStageSendBubbleLower,
        ifStageEmpty
    );

    modport DecodeStage(
    input
        idStage,
        stallByDecodeStage,
    output
        idStageStallUpper,
        idStageEmpty
    );

    modport PreDecodeStage(
    input
        pdStage,
    output
        pdStageEmpty
    );

    modport RenameStage(
    input
        rnStage,
    output
        rnStageFlushUpper,
        rnStageSendBubbleLower,
        rnStageEmpty
    );

    modport DispatchStage(
    input
        clk,
        rst,
        dsStage
    );

    modport ScheduleStage(
    input
        scStage
    );

    modport IntegerIssueStage(
    input
        isStage,
        isStageStallUpper
    );

    modport IntegerRegisterReadStage(
    input
        backEnd
    );

    modport IntegerExecutionStage(
    input
        backEnd
    );

    modport IntegerRegisterWriteStage(
    input
        clk,
        rst,
        backEnd
    );

    modport ComplexIntegerIssueStage(
    input
        isStage
    );

    modport ComplexIntegerRegisterReadStage(
    input
        backEnd
    );

    modport ComplexIntegerExecutionStage(
    input
        backEnd
    );

    modport ComplexIntegerRegisterWriteStage(
    input
        clk,
        rst,
        backEnd
    );

    modport MemoryIssueStage(
    input
        isStage
    );

    modport MemoryRegisterReadStage(
    input
        backEnd
    );

    modport MemoryExecutionStage(
    input
        backEnd
    );

    modport MemoryTagAccessStage(
    input
        backEnd
    );

    modport MemoryAccessStage(
    input
        backEnd
    );

    modport MemoryRegisterWriteStage(
    input
        clk,
        rst,
        backEnd
    );

    modport CommitStage(
    input
        cmStage
    );

    modport BypassController(
    input
        backEnd
    );

    modport BypassNetwork(
    input
        backEnd
    );

    modport VectorBypassNetwork(
    input
        backEnd
    );

    modport DCache(
    input
        backEnd
    );

    modport LoadStoreUnit(
    input
        backEnd
    );

    modport ReplayQueue(
    output
        isStageStallUpper
    );

    modport BranchPredictor(
    input
        ifStage
    );

    modport RecoveryManager(
    output
        cmStageFlushUpper
    );

    modport ActiveList(
    output
        activeListEmpty
    );

    modport InterruptController(
    input 
        wholePipelineEmpty,
    output 
        npStageSendBubbleLowerForInterrupt
    );

endinterface : ControllerIF

// ---- Controller.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;
import PipelineTypes::*;
import DebugTypes::*;

module Controller(
    ControllerIF.Controller port,
    DebugIF.Controller debug
);

    PipelineControll npStage;
    PipelineControll ifStage;
    PipelineControll pdStage;
    PipelineControll idStage;
    PipelineControll rnStage;
    PipelineControll dsStage;

    PipelineControll scStage;
    PipelineControll isStage;
    PipelineControll backEnd;
    PipelineControll cmStage;
    logic stallByDecodeStage;

    always_comb begin

        //
        // See comments in ControllerIF for stall/clear
        //

        stallByDecodeStage = FALSE;

        //
        // --- Front-end control
        //
        if( port.rst ) begin
            // リセット時にパイプラインラッチに無効化フラグを書くため，stall はFALSE に
            //              stall/ clear
            npStage = { FALSE, TRUE };
            ifStage = { FALSE, TRUE };
            pdStage = { FALSE, TRUE };
            idStage = { FALSE, TRUE };
            rnStage = { FALSE, TRUE };
            dsStage = { FALSE, TRUE };

        end
        else begin
            //
            // 通常時
            //              stall/ clear
            npStage = { FALSE, FALSE };
            ifStage = { FALSE, FALSE };
            pdStage = { FALSE, FALSE };
            idStage = { FALSE, FALSE };
            rnStage = { FALSE, FALSE };
            dsStage = { FALSE, FALSE };

            //
            // A request from lower stages has a higher priority.
            //
            if( port.cmStageFlushUpper ) begin
                // Clear ops not in the active list when branch misprediction is detected.
                //              stall/ clear
                npStage = { FALSE, FALSE };
                ifStage = { FALSE, TRUE };
                pdStage = { FALSE, TRUE };
                idStage = { FALSE, TRUE };
                rnStage = { FALSE, TRUE };
                dsStage = { FALSE, TRUE };

            end
            else if( port.rnStageSendBubbleLower ) begin
                //
                // Stall and send a bubble to lower stages because there are not enough
                // physical registers
                //              stall/ clear
                npStage = { TRUE,  FALSE };
                ifStage = { TRUE,  FALSE };
                pdStage = { TRUE,  FALSE };
                idStage = { TRUE,  FALSE };
                rnStage = { TRUE,  TRUE  }; // 後続ステージにバブル（NOP）を送る
            end
            else if( port.rnStageFlushUpper ) begin
                //
                // リネーマより上流をフラッシュ
                //              stall/ clear
                npStage = { FALSE, FALSE };
                ifStage = { FALSE, TRUE };
                pdStage = { FALSE, TRUE };
                idStage = { FALSE, TRUE };

            end
            else if( port.idStageStallUpper ) begin
                //
                // デコーダより上流（フェッチャ）をストール
                // マイクロOp デコードを行うためにとめているため，
                // バブルは不要
                //              stall/ clear
                npStage = { TRUE,  FALSE };
                ifStage = { TRUE,  FALSE };
                pdStage = { TRUE,  FALSE };
                idStage = { TRUE,  FALSE };

                stallByDecodeStage = TRUE;
            end
            else if(
                port.ifStageSendBubbleLower
            ) begin
                //
                // I-Cache miss.
                // Stop PC update and Send NOPs to the lower stages.
                //          stall/ clear
                npStage = { TRUE, TRUE };  
                ifStage = { TRUE, TRUE };  
            end
            else if(
                port.npStageSendBubbleLower || 
                port.npStageSendBubbleLowerForInterrupt
            ) begin
                //
                // Interrupt
                //
                npStage = { TRUE, TRUE };  
            end
        end


        port.npStage = npStage;
        port.ifStage = ifStage;
        port.pdStage = pdStage;
        port.idStage = idStage;
        port.rnStage = rnStage;
        port.dsStage = dsStage;
        port.stallByDecodeStage = stallByDecodeStage;

        //
        // --- Back-end control
        //

        if( port.rst ) begin
            // リセット時にパイプラインラッチに無効化フラグを書くため，stall はFALSE に
            //              stall/ clear
            scStage = { FALSE, TRUE };
            isStage = { FALSE, TRUE };
            backEnd = { FALSE, TRUE };
            cmStage = { FALSE, TRUE };

        end
        else begin
            //
            // A request from lower stages has a higher priority.
            //
            if (port.isStageStallUpper) begin
                // Stall scheduler
                scStage = { TRUE, FALSE };
                isStage = { TRUE, FALSE };
                backEnd = { FALSE, FALSE };
                cmStage = { FALSE, FALSE };
            end
            else begin
                //
                // 通常時
                //              stall/ clear
                scStage = { FALSE, FALSE };
                isStage = { FALSE, FALSE };
                backEnd = { FALSE, FALSE };
                cmStage = { FALSE, FALSE };
            end
        end

        port.scStage = scStage;
        port.isStage = isStage;
        port.backEnd = backEnd;
        port.cmStage = cmStage;

        // パイプライン全体で生きている命令がいるかどうか
        port.wholePipelineEmpty = 
            npStage.clear &&            // IF は clear されない限り何か有効な命令をフェッチする
            port.ifStageEmpty &&
            port.pdStageEmpty &&
            port.idStageEmpty && 
            port.rnStageEmpty &&
            port.activeListEmpty;

`ifndef RSD_DISABLE_DEBUG_REGISTER
        // Debug Register
        debug.npStagePipeCtrl = npStage;
        debug.ifStagePipeCtrl = ifStage;
        debug.pdStagePipeCtrl = pdStage;
        debug.idStagePipeCtrl = idStage;
        debug.rnStagePipeCtrl = rnStage;
        debug.dsStagePipeCtrl = dsStage;
        debug.backEndPipeCtrl = backEnd;
        debug.cmStagePipeCtrl = cmStage;
        debug.stallByDecodeStage = stallByDecodeStage;
`endif
    end

endmodule
// ---- ResetController.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;

module ResetController #(
    parameter CYCLE_OF_RESET_SEQUENCE = 10000
)(
    input  logic clk, rstTrigger, locked,
    output logic rst, rstStart
);
    logic unsigned [ $clog2(CYCLE_OF_RESET_SEQUENCE):0 ] count;
    
    always_ff @(posedge clk or posedge rstTrigger) begin
        // --- rst
        // - rstTriggerがアサートされた後、
        //   CYCLE_OF_RESET_SEQUENCEサイクルの間アサートされ続ける
        if ( rstTrigger || !locked ) begin
            count <= 0;
            rst <= TRUE;
        end
        else if ( rst ) begin
            count <= count + 1;
            rst <= ( count >= CYCLE_OF_RESET_SEQUENCE ? FALSE : TRUE );
        end
        else begin
            count <= 0;
            rst <= FALSE;
        end
    end
    
    // --- rstStart
    // - リセットの開始時に1サイクルだけアサートされる信号線。
    //   RAMなどを初期化する回路は、
    //   リセット信号がアサートされている間(CYCLE_OF_RESET_SEQUENCEサイクル)駆動するが、
    //   その初期化回路もリセットを行う必要がある。
    //   初期化回路はrstがアサートされている間動くので、
    //   rstをリセット信号としては使用できない。
    //   そこで、初期化回路のリセットにはrstStartを用いる。
    always_comb begin
        rstStart = ( rst && count == 0 ) ? TRUE : FALSE;
    end
endmodule
// ---- Privileged/InterruptController.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// CSR Unit
//


import BasicTypes::*;
import CSR_UnitTypes::*;

module InterruptController(
    CSR_UnitIF.InterruptController csrUnit,
    ControllerIF.InterruptController ctrl,
    NextPCStageIF.InterruptController fetchStage,
    RecoveryManagerIF.InterruptController recoveryManager
);
    logic reqInterrupt, triggerInterrupt;
    CSR_BodyPath csrReg;
    always_comb begin
        csrReg = csrUnit.csrWholeOut;

        // いまのところタイマ割り込みのみ
        reqInterrupt = 
            csrReg.mstatus.MIE &&
            csrReg.mie.MTIE &&
            csrReg.mip.MTIP;

        // パイプライン全体が空になるまでフェッチをとめる        
        ctrl.npStageSendBubbleLowerForInterrupt =
            reqInterrupt;
        
        // * パイプライン全体が空になったら割り込みをかける
        // * パイプラインが空でもリカバリマネージャが PC を書き換えている途中の
        //   可能性があるため，きちんと待つ必要がある
        // * reqInterrupt は csrReg のみをみて決定しているので，
        //   要求を出したことによって，CSR 内で MIE が落とされてループするということは
        //   ないはず
        triggerInterrupt = 
            ctrl.wholePipelineEmpty && 
            !recoveryManager.unableToStartRecovery && 
            reqInterrupt;

        csrUnit.triggerInterrupt = triggerInterrupt;
        csrUnit.interruptRetAddr = fetchStage.pcOut;

        fetchStage.interruptAddrWE = triggerInterrupt;
        fetchStage.interruptAddrIn = csrUnit.interruptTargetAddr;
    end

endmodule
// ---- Privileged/CSR_Unit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// CSR Unit
//


import BasicTypes::*;
import MemoryMapTypes::*;
import CSR_UnitTypes::*;
import OpFormatTypes::*;
import SchedulerTypes::*;

module CSR_Unit(
    CSR_UnitIF.CSR_Unit port
);

    CSR_BodyPath csrReg, csrNext;
    DataPath rv;
    CSR_ValuePath wv;
    DataPath mcycle;    // for debug
    AddrPath jumpTarget;
    CommitLaneCountPath regCommitNum;

    always_ff@(posedge port.clk) begin
        if (port.rst) begin
            csrReg <= '0;
            regCommitNum <= '0;
        end
        else begin
            csrReg <= csrNext;
            regCommitNum <= port.commitNum;
        end
    end
    always_comb begin
        mcycle = csrReg.mcycle;
        
        // Read a CSR value
        unique case (port.csrNumber) 
            CSR_NUM_MSTATUS:    rv = csrReg.mstatus;
            CSR_NUM_MIP:        rv = csrReg.mip;
            CSR_NUM_MIE:        rv = csrReg.mie;
            CSR_NUM_MCAUSE:     rv = csrReg.mcause;
            CSR_NUM_MTVEC:      rv = csrReg.mtvec;
            CSR_NUM_MTVAL:      rv = csrReg.mtval;
            CSR_NUM_MEPC:       rv = csrReg.mepc;
            CSR_NUM_MSCRATCH:   rv = csrReg.mscratch;

            CSR_NUM_MCYCLE:   rv = csrReg.mcycle;
            CSR_NUM_MINSTRET: rv = csrReg.minstret;

            default:          rv = '0;
        endcase 


        // Writeback 
        csrNext = csrReg;

        // Update Cycles
        csrNext.mcycle = csrNext.mcycle + 1;
        csrNext.minstret = csrNext.minstret + regCommitNum;

        wv = '0;

        if (port.triggerInterrupt) begin
            // Interrupt
            csrNext.mstatus.MPIE = csrNext.mstatus.MIE; // MIE の古い値
            csrNext.mstatus.MIE = 0;    // グローバル割り込み許可を落とす
            csrNext.mepc = ToAddrFromPC(port.interruptRetAddr); // 割り込み発生時の PC
            csrNext.mtval = ToAddrFromPC(port.interruptRetAddr);// PC?
            
            csrNext.mcause.isInterrupt = TRUE;
            csrNext.mcause.code.interruptCode = CSR_CAUSE_INTERRUPT_CODE_TIMER;
            //$display("int: from %x", port.interruptRetAddr);
        end
        else if (port.triggerExcpt) begin
            if (port.excptCause == EXEC_STATE_TRAP_MRET) begin
                // MRET
                csrNext.mstatus.MIE = csrNext.mstatus.MPIE; // MIE の古い値に戻す
                //$display("mret: to %x", csrNext.mepc);
            end
            else begin
                // Trap
                csrNext.mstatus.MPIE = csrNext.mstatus.MIE; // MIE の古い値
                csrNext.mstatus.MIE = 0;    // グローバル割り込み許可を落とす
                csrNext.mepc = ToAddrFromPC(port.excptCauseAddr); // 例外の発生元 PC を書き込む
                csrNext.mtval = port.excptCauseDataAddr;// ECALL/EBREAK の場合は PC?
                
                csrNext.mcause.isInterrupt = FALSE;
                csrNext.mcause.code.trapCode = ToTrapCodeFromExecState(port.excptCause);
                //$display("trap: from %x", csrNext.mepc);

            end
        end
        else if (port.csrWE) begin
            // Operation
            unique case (port.csrCode) 
                CSR_WRITE:  wv = port.csrWriteIn;
                CSR_SET:    wv = rv | port.csrWriteIn;
                CSR_CLEAR:  wv = rv & (~port.csrWriteIn);
                default:    wv = port.csrWriteIn;    // ???
            endcase

            unique case (port.csrNumber) 
                CSR_NUM_MSTATUS: begin
                    //csrNext.mstatus.MIE = wv.mstatus.MIE;
                    //csrNext.mstatus.MPIE = wv.mstatus.MPIE;
                    csrNext.mstatus = wv;
                   //$display("mstatus: %x", wv);
                end

                // MIP                
                // > Only the bits corresponding to lower-privilege 
                // > software interrupts (USIP, SSIP), timer interrupts (UTIP,
                // > STIP), and external interrupts (UEIP, SEIP) in mip are writable 
                // > through this CSR address; the remaining bits are read-only.
                // Currently, only MTIP is supported and thus this is write only.
                //CSR_NUM_MIP:        csrNext.mip = wv;

                CSR_NUM_MIE:begin
                    csrNext.mie = wv;
                    //$display("mie: %x", wv);
                end
                CSR_NUM_MCAUSE:     csrNext.mcause = wv;
                CSR_NUM_MTVEC:      csrNext.mtvec = wv;
                CSR_NUM_MTVAL:      csrNext.mtval = wv;
                CSR_NUM_MEPC:       csrNext.mepc = wv;
                CSR_NUM_MSCRATCH:   csrNext.mscratch = wv;

                CSR_NUM_MCYCLE:     csrNext.mcycle = wv;
                CSR_NUM_MINSTRET:   csrNext.minstret = wv;
                default:            wv = '0;    // dummy
            endcase 
        end

        csrNext.mip.MTIP = port.reqTimerInterrupt;  // Timer interrupt request

        port.csrReadOut = rv;
        if (port.excptCause == EXEC_STATE_TRAP_MRET) begin
            port.excptTargetAddr = csrReg.mepc;
        end
        else begin
            port.excptTargetAddr = {csrReg.mtvec.base, CSR_MTVEC_BASE_PADDING};
        end
        port.interruptTargetAddr = ToPC_FromAddr({
            (csrReg.mtvec.mode == CSR_MTVEC_MODE_VECTORED) ? 
                csrReg.mtvec.base + csrReg.mcause.code : csrReg.mtvec.base, 
                CSR_MTVEC_BASE_PADDING
        });

        port.csrWholeOut = csrReg;
    end

    `RSD_ASSERT_CLK(
        port.clk, 
        !(port.triggerExcpt && !(port.excptCause inside {
            EXEC_STATE_TRAP_ECALL, 
            EXEC_STATE_TRAP_EBREAK, 
            EXEC_STATE_TRAP_MRET,
            EXEC_STATE_FAULT_LOAD_MISALIGNED,
            EXEC_STATE_FAULT_LOAD_VIOLATION,
            EXEC_STATE_FAULT_STORE_MISALIGNED,
            EXEC_STATE_FAULT_STORE_VIOLATION,
            EXEC_STATE_FAULT_INSN_ILLEGAL,
            EXEC_STATE_FAULT_INSN_VIOLATION,
            EXEC_STATE_FAULT_INSN_MISALIGNED
        })),
        "Invalid exception cause is passed"
    );

    `RSD_ASSERT_CLK(
        port.clk, 
        !(
            (port.triggerExcpt && port.csrWE) || 
            (port.triggerInterrupt && port.csrWE) || 
            (port.triggerExcpt && port.triggerInterrupt)
        ),
        "CSR update, trap or interrupt are performed at the same cycle"
    );

endmodule : CSR_Unit

// ---- Privileged/CSR_UnitIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// The interface of a CSR unit.
//


import BasicTypes::*;
import MemoryMapTypes::*;
import OpFormatTypes::*;
import MicroOpTypes::*;
import SchedulerTypes::*;
import CSR_UnitTypes::*;

interface CSR_UnitIF(input logic clk, rst, rstStart);

    logic csrWE;  // CSR write enable
    CSR_NumberPath csrNumber;   // CSR number
    CSR_Code csrCode;           // CSR operation code (ex. set, clear...)
    DataPath csrReadOut;        // a register value read from CSR 
    DataPath csrWriteIn;        // a value to be written to CSR
    CSR_BodyPath csrWholeOut;   // whole values of CSR

    // Exception = trap or fault
    // Trap request
    logic   triggerExcpt;
    ExecutionState excptCause;
    PC_Path excptCauseAddr;     // EBREAK/ECALL 時の mepc
    AddrPath excptTargetAddr;   // Trap vector or MRET return target
    AddrPath excptCauseDataAddr;     // fault 発生時のデータアドレス

    // Interrupt
    logic triggerInterrupt;
    PC_Path interruptRetAddr;
    PC_Path interruptTargetAddr;

    // Timer interrupt request
    logic reqTimerInterrupt;

    // Used in updating minstret
    CommitLaneCountPath commitNum;

    modport MemoryExecutionStage(
    input
        clk, rst, rstStart,
        csrReadOut,
    output 
        csrWE,
        csrNumber,
        csrCode,
        csrWriteIn
    );

    // 割り込みは以下の流れで要求が流れる
    // IO_Unit -> reqTimerInterrupt ->
    // CSR_Unit -> csrReg.mie.MTIE ->
    // InterruptController -> triggerInterrupt -> 
    // FetchStage and CSR_Unit
    modport IO_Unit(
    output 
        reqTimerInterrupt
    );

    // For counter update
    modport CommitStage (
    output
        commitNum
    );


    modport RecoveryManager(
    input
        excptTargetAddr,
    output
        triggerExcpt,
        excptCauseAddr,
        excptCause,
        excptCauseDataAddr
    );

    modport CSR_Unit(
    input
        clk, rst, rstStart,
        csrWE,
        csrNumber,
        csrCode,
        csrWriteIn,
        triggerExcpt,
        excptCauseAddr,
        excptCause,
        excptCauseDataAddr,
        commitNum,
        reqTimerInterrupt,
        triggerInterrupt,
        interruptRetAddr,
    output 
        csrWholeOut,
        csrReadOut,
        interruptTargetAddr,
        excptTargetAddr
    );

    modport InterruptController(
    input
        clk, rst, rstStart,
        csrWholeOut,
        interruptTargetAddr,
    output
        triggerInterrupt,
        interruptRetAddr
    );

endinterface
// ---- IO/IO_Unit.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// UI Unit
//


import BasicTypes::*;
import LoadStoreUnitTypes::*;
import MemoryMapTypes::*;
import IO_UnitTypes::*;
import DebugTypes::*;

module IO_Unit(
    IO_UnitIF.IO_Unit port,
    CSR_UnitIF.IO_Unit csrUnit
);

    // Timer register
    TimerRegsters tmReg;
    TimerRegsters tmNext;

    // tohost: the low word last stored there
    DataPath tohostReg;
    // Serial input: the low byte last stored there
    logic [7:0] serialInAckReg;
    always_ff@(posedge port.clk) begin
        if (port.rst) begin
            tohostReg <= '0;
            serialInAckReg <= '0;
        end
        else if (port.ioWE && port.ioWriteAddrIn.addr == PHY_ADDR_TOHOST) begin
            tohostReg <= port.ioWriteDataIn;
        end
        else if (port.ioWE && port.ioWriteAddrIn.addr == PHY_ADDR_SERIAL_INPUT) begin
            serialInAckReg <= port.ioWriteDataIn[7:0];
        end
    end
    assign port.tohost = tohostReg;
    assign port.serialInAck = serialInAckReg;
    always_ff@(posedge port.clk) begin
        if (port.rst) begin
            tmReg <= '0;
        end
        else begin
            tmReg <= tmNext;
        end
    end

    PhyRawAddrPath phyRawReadAddr, phyRawWriteAddr;

    always_comb begin
        phyRawReadAddr = port.ioReadAddrIn.addr;
        phyRawWriteAddr = port.ioWriteAddrIn.addr;

        // Update timer
        tmNext = tmReg;
        tmNext.mtime.raw = tmNext.mtime.raw + 1;

        // Generate a timer interrupt signal
        csrUnit.reqTimerInterrupt = 
            tmNext.mtime.raw >= tmNext.mtimecmp.raw ? TRUE : FALSE;
        //$display("time, cmp: %d, %d", tmNext.mtime.raw, tmNext.mtimecmp.raw);

        // Write a timer regsiter
        if (port.ioWE) begin
            //$display("IO write %0x: %0x", port.ioWriteAddrIn, port.ioWriteDataIn);
            if (phyRawWriteAddr == PHY_ADDR_TIMER_LOW) begin
                tmNext.mtime.split.low = port.ioWriteDataIn;
            end
            else if (phyRawWriteAddr == PHY_ADDR_TIMER_HI) begin
                tmNext.mtime.split.hi = port.ioWriteDataIn;
            end
            else if (phyRawWriteAddr == PHY_ADDR_TIMER_CMP_LOW) begin
                tmNext.mtimecmp.split.low = port.ioWriteDataIn;
            end
            else if (phyRawWriteAddr == PHY_ADDR_TIMER_CMP_HI) begin
                tmNext.mtimecmp.split.hi = port.ioWriteDataIn;
            end
            //$display(tmNext.mtime.raw);
            //$display(tmNext.mtimecmp.raw);
        end

        // Read a timer rigister
        if (phyRawReadAddr == PHY_ADDR_TOHOST) begin
            port.ioReadDataOut = tohostReg;
        end
        else if (phyRawReadAddr == PHY_ADDR_TOHOST + 4) begin
            port.ioReadDataOut = '0;
        end
        else if (phyRawReadAddr == PHY_ADDR_SERIAL_INPUT) begin
            port.ioReadDataOut = {16'h0, port.serialIn};
        end
        else if (phyRawReadAddr == PHY_ADDR_TIMER_LOW) begin
            port.ioReadDataOut = tmReg.mtime.split.low;
        end
        else if (phyRawReadAddr == PHY_ADDR_TIMER_HI) begin
            port.ioReadDataOut = tmReg.mtime.split.hi;
        end
        else if (phyRawReadAddr == PHY_ADDR_TIMER_CMP_LOW) begin
            port.ioReadDataOut = tmReg.mtimecmp.split.low;
        end
        else begin
            //if (port.ioReadAddrIn == PHY_ADDR_TIMER_CMP_HI) begin
            port.ioReadDataOut = tmReg.mtimecmp.split.hi;
        end
    end


    always_comb begin
        // Serial IO
        port.serialWE = FALSE;
        port.serialWriteDataOut = port.ioWriteDataIn[SERIAL_OUTPUT_WIDTH-1 : 0];
        if (port.ioWE && phyRawWriteAddr == PHY_ADDR_SERIAL_OUTPUT) begin
            port.serialWE = TRUE;
        end
    end
endmodule
// ---- IO/IO_UnitIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// The interface of a load/store unit.
//


import BasicTypes::*;
import LoadStoreUnitTypes::*;
import IO_UnitTypes::*;
import MemoryMapTypes::*;

interface IO_UnitIF(
    input 
        logic clk, rst, rstStart,
    output
        logic serialWE,
        SerialDataPath serialWriteDataOut
);
    // Write request from a store qeueue 
    logic ioWE;
    DataPath ioWriteDataIn;
    PhyAddrPath ioWriteAddrIn;

    // Read request from a load pipeline
    DataPath ioReadDataOut;
    PhyAddrPath ioReadAddrIn;

    // The low word last stored to tohost
    DataPath tohost;
    // Serial input: {seq, char} from the host, and the seq taken
    logic [15:0] serialIn;
    logic [7:0] serialInAck;

    modport IO_Unit(
    input 
        clk, rst, rstStart,
        ioWE,
        ioWriteDataIn,
        ioWriteAddrIn,
        ioReadAddrIn,
        serialIn,
    output
        ioReadDataOut,
        serialWE,
        serialWriteDataOut,
        tohost,
        serialInAck
    );

    modport MemoryAccessStage(
    input 
        ioReadDataOut,
    output
        ioReadAddrIn
    );

    modport StoreCommitter(
    output
        ioWE,
        ioWriteDataIn,
        ioWriteAddrIn
    );


endinterface : IO_UnitIF


// ---- Primitives/FlipFlop.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.



import BasicTypes::*;


//
// Usage: FlipFlop#(.FF_WIDTH(32)) ff( out, in , clk, rst );
//

//
// Usage: FlipFlop#(.FF_WIDTH(32)) ff( out, in , clk, rst );
//
module FlipFlop #( parameter FF_WIDTH = 32, parameter RESET_VALUE = 0 )
(
    output logic [FF_WIDTH-1:0] out,
    
    input  logic [FF_WIDTH-1:0] in,
    input  logic clk, 
    input  logic rst
);

    logic [FF_WIDTH-1:0] body;
    
    // rst or write
    always_ff@( posedge clk )           // synchronous rst 
    begin
        if( rst == 1 )                  // rst 
            body <= RESET_VALUE;
        else
            body <= in;
    end
    
    assign out = body;

endmodule : FlipFlop


// Flip flop with write enable
module FlipFlopWE #( parameter FF_WIDTH = 32, parameter RESET_VALUE = 0 )
(
    output logic [FF_WIDTH-1:0] out,

    input  logic [FF_WIDTH-1:0] in,
    input  logic we,  

    input  logic clk, 
    input  logic rst
);

    logic [FF_WIDTH-1:0] body;
    
    // rst or write
    always_ff@( posedge clk )           // synchronous rst 
    begin
        if( rst == 1 )                  // rst 
            body <= RESET_VALUE;
        else if( we )                   // write data
            body <= in;
        else
            body <= body;
    end
    
    assign out = body;


endmodule : FlipFlopWE

// ---- Primitives/FreeList.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// A free list for an issue queue entries.
//

import BasicTypes::*;

module FreeList #(
    parameter SIZE = 1,
    parameter ENTRY_WIDTH = 1 // MultiWidthFreeListではENTRY_WIDTH
)( 
input 
    logic clk,
    logic rst,
    logic push,
    logic pop,
    logic [ ENTRY_WIDTH-1:0 ] pushedData,
output
    logic full,
    logic empty,
    logic [ ENTRY_WIDTH-1:0 ] headData
);

    localparam BIT_WIDTH = $clog2( SIZE );
    typedef logic [BIT_WIDTH-1:0] IndexPath;

    IndexPath headPtr;
    IndexPath tailPtr;

    // size, initial head, initial tail, initial count
    QueuePointer #( SIZE, 0, 0, SIZE )
        pointer(
            .clk( clk ),
            .rst( rst ),
            .push( push ),
            .pop( pop ),
            .full( full ),
            .empty( empty ),
            .headPtr( headPtr ),
            .tailPtr( tailPtr )
        );
        

    logic [ ENTRY_WIDTH-1:0 ] freeList[ SIZE-1:0 ];

    always_ff @( posedge clk ) begin
        if( rst ) begin
            for( int i = 0; i < SIZE; i++ ) begin
                freeList[i] <= i;
            end
        end
        else begin
            if( push ) begin
                freeList[ tailPtr ] <= pushedData;
            end
        end
    end
    
    always_comb begin
        headData = freeList[ headPtr ];
    end

endmodule : FreeList

module MultiWidthFreeList #(
    parameter SIZE = 16,
    parameter ENTRY_BIT_SIZE = 4,
    parameter PUSH_WIDTH = 4,
    parameter POP_WIDTH = 4,
    parameter INITIAL_LENGTH = SIZE
)( 
input 
    logic clk,
    logic rst,
    logic rstStart,
    logic push [ PUSH_WIDTH ],
    logic pop [ POP_WIDTH ],
    logic [ ENTRY_BIT_SIZE-1:0 ] pushedData [ PUSH_WIDTH ],
output
    logic [ $clog2(SIZE):0 ] count,
    logic [ ENTRY_BIT_SIZE-1:0 ] poppedData [ POP_WIDTH ]
);

    localparam INDEX_BIT_SIZE = $clog2(SIZE);
    typedef logic [INDEX_BIT_SIZE-1: 0] IndexPath;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    typedef logic [INDEX_BIT_SIZE:0] CountPath;
    
    // --- Control headPtr, tailPtr and count
    IndexPath headPtr;
    IndexPath tailPtr;
    logic [ $clog2(PUSH_WIDTH):0 ] pushCount;
    logic [ $clog2(POP_WIDTH):0 ] popCount;
    
        
    MultiWidthQueuePointer #(
        .SIZE( SIZE ),
        .INITIAL_HEAD_PTR( 0 ), 
        .INITIAL_TAIL_PTR( INITIAL_LENGTH ),
        .INITIAL_COUNT( INITIAL_LENGTH ),
        .PUSH_WIDTH( PUSH_WIDTH ),
        .POP_WIDTH( POP_WIDTH )
    ) queuePointer (
        .clk( clk ),
        .rst( rst ),
        .push( pushCount != 0 ),
        .pop( popCount != 0 ),
        .pushCount( pushCount ),
        .popCount( popCount ),
        .headPtr( headPtr ),
        .tailPtr( tailPtr ),
        .count( count )
    );


    // --- Data Array of Free List
    logic we[PUSH_WIDTH];
    Value wv[PUSH_WIDTH];
    IndexPath wa[PUSH_WIDTH];

    Value rv[POP_WIDTH];
    IndexPath ra[POP_WIDTH];
    
    IndexPath rstIndex;

    //NarrowDistributedMultiPortRAM #( 
    DistributedMultiBankRAM #( 
        .ENTRY_NUM( SIZE ), 
        .ENTRY_BIT_SIZE( ENTRY_BIT_SIZE ),
        .READ_NUM( POP_WIDTH ),
        .WRITE_NUM( PUSH_WIDTH )
    ) freeList (
        .clk( clk ),
        .wa( wa ),
        .we( we ),
        .wv( wv ),
        .ra( ra ),
        .rv( rv )
    );
    
    // リセット時に、各エントリの内容をエントリの番号で初期化する
    // すなわち、 entry[0] = 0, entry[1] = 1, entry[2] = 2 ... となる
    always_ff @ (posedge clk) begin
        if (rstStart) begin
            rstIndex <= 0;
        end
        else if ( rstIndex >= SIZE - PUSH_WIDTH ) begin
            rstIndex <= 0;
        end
        else begin
            rstIndex <= rstIndex + PUSH_WIDTH;
        end
    end
    
    
    always_comb begin

        pushCount = 0;
        for (int i = 0; i < PUSH_WIDTH; i++) begin
            if ((tailPtr + pushCount) >= SIZE) begin
                // Compensate the index to point in the freelist
                wa[i] = tailPtr + pushCount - SIZE;
            end
            else begin
                wa[i] = tailPtr + pushCount;
            end
            wv[i] = pushedData[i];
            we[i] = push[i];
            if (push[i]) begin
                pushCount += 1;
            end
        end
        
        // "ra" is serialized for multi-banking.
        for (int i = 0; i < POP_WIDTH; i++) begin
            if ((headPtr + i) >= SIZE) begin
                ra[i] = headPtr + i - SIZE;
            end
            else begin
                ra[i] = headPtr + i;
            end
        end

        popCount = 0;
        for (int i = 0; i < POP_WIDTH; i++) begin
            poppedData[i] = rv[popCount];
            if (pop[i]) begin
                popCount += 1;
            end
        end
        
        if (rst) begin
            for (int i = 0; i < PUSH_WIDTH; i++) begin
                wa[i] = rstIndex + i;
                wv[i] = rstIndex + i;
                // エントリ数が PUSH_WIDTH の整数倍じゃなかった場合の処理
                we[i] = (wa[i] >= rstIndex) && (wa[i] < SIZE);
            end
        end
    end
    
endmodule : MultiWidthFreeList

// ---- Primitives/Queue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Controller implementeation of a queue (FIFO).
//


import BasicTypes::*;

//
// 1-input/1-output queue.
// The "tailPtr" points the address of a next pushed entry.
//
module QueuePointer #( parameter
    SIZE = 1,
    INITIAL_HEAD_PTR = 0,
    INITIAL_TAIL_PTR = 0,
    INITIAL_COUNT = 0
)(
input
    logic clk,
    logic rst,
    logic push,
    logic pop,
output
    logic full,
    logic empty,
    logic [$clog2(SIZE)-1:0] headPtr,
    logic [$clog2(SIZE)-1:0] tailPtr
);

    localparam BIT_WIDTH = $clog2( SIZE );
    typedef logic [BIT_WIDTH-1:0] IndexPath;
    typedef logic [BIT_WIDTH:0] CountPath;

    IndexPath regHeadStorage, nextHeadStorage;
    IndexPath regTailStorage, nextTailStorage;
    CountPath regCount, nextCount;

    always_ff @( posedge clk ) begin
        if (rst) begin
            regHeadStorage <= INITIAL_HEAD_PTR;
            regTailStorage <= INITIAL_TAIL_PTR;
            regCount <= INITIAL_COUNT;

            //assert( INITIAL_HEAD + INITIAL_COUNT == INITIAL_TAIL );
        end
        else begin
            regHeadStorage <= nextHeadStorage;
            regTailStorage <= nextTailStorage;
            regCount <= nextCount;
        end
    end

    always_comb begin
        full = ( regCount == SIZE ) ? TRUE : FALSE;
        empty = ( regCount == 0 ) ? TRUE : FALSE;

        nextHeadStorage = regHeadStorage;
        nextTailStorage = regTailStorage;
        nextCount = regCount;

        if (push) begin
            if (regTailStorage == SIZE-1) begin
                nextTailStorage = 0;
            end
            else begin
                nextTailStorage++;
            end

            nextCount++;
        end

        if (pop) begin
            if (regHeadStorage == SIZE-1) begin
                nextHeadStorage = 0;
            end
            else begin
                nextHeadStorage++;
            end

            nextCount--;
        end

        headPtr = regHeadStorage;
        tailPtr = regTailStorage;
    end

    // Assertion
    `RSD_ASSERT_CLK(clk, !(full && push), "Push to a full queue.");
    `RSD_ASSERT_CLK(clk, !(empty && pop), "Pop from an empty queue.");
endmodule

//
// 1-input/1-output queue with its entry count.
// The "tailPtr" points the address of a next pushed entry.
//
module QueuePointerWithEntryCount #( parameter
    SIZE = 1,
    INITIAL_HEAD_PTR = 0,
    INITIAL_TAIL_PTR = 0,
    INITIAL_COUNT = 0
)( 
input 
    logic clk,
    logic rst,
    logic push,
    logic pop,
output
    logic full,
    logic empty,
    logic [$clog2(SIZE)-1:0] headPtr,
    logic [$clog2(SIZE)-1:0] tailPtr,
    logic [$clog2(SIZE):0] count
);

    localparam BIT_WIDTH = $clog2( SIZE );
    typedef logic [BIT_WIDTH-1:0] IndexPath;
    typedef logic [BIT_WIDTH:0] CountPath;

    IndexPath regHeadStorage, nextHeadStorage;
    IndexPath regTailStorage, nextTailStorage;
    CountPath regCount, nextCount;

    always_ff @( posedge clk ) begin
        if (rst) begin
            regHeadStorage <= INITIAL_HEAD_PTR;
            regTailStorage <= INITIAL_TAIL_PTR;
            regCount <= INITIAL_COUNT;
            
            //assert( INITIAL_HEAD + INITIAL_COUNT == INITIAL_TAIL );
        end
        else begin
            regHeadStorage <= nextHeadStorage;
            regTailStorage <= nextTailStorage;
            regCount <= nextCount;
        end
    end
    
    always_comb begin
        full = ( regCount == SIZE ) ? TRUE : FALSE;
        empty = ( regCount == 0 ) ? TRUE : FALSE;
    
        nextHeadStorage = regHeadStorage;
        nextTailStorage = regTailStorage;
        nextCount = regCount;

        if (push) begin
            if (regTailStorage == SIZE-1) begin
                nextTailStorage = 0;
            end
            else begin
                nextTailStorage++;
            end

            nextCount++;
        end
        if (pop) begin
            if (regHeadStorage == SIZE-1) begin
                nextHeadStorage = 0;
            end
            else begin
                nextHeadStorage++;
            end

            nextCount--;
        end
        
        headPtr = regHeadStorage;
        tailPtr = regTailStorage;
        count = regCount;
    end

    // Assertion
    `RSD_ASSERT_CLK(clk, !(full && push), "Push to a full queue.");
    `RSD_ASSERT_CLK(clk, !(empty && pop), "Pop from an empty queue.");

endmodule

//
// N-input/N-output queue.
// The "tailPtr" points the address of a next pushed entry.
//
module MultiWidthQueuePointer #( parameter
    SIZE = 1,
    INITIAL_HEAD_PTR = 0,
    INITIAL_TAIL_PTR = 0,
    INITIAL_COUNT = 0,
    PUSH_WIDTH = 1,
    POP_WIDTH = 1,
    ENABLE_SPECIFIED_ENTRY_NUM = FALSE
)(
input
    logic clk,
    logic rst,
    logic push,
    logic pop,
    logic [$clog2(PUSH_WIDTH):0] pushCount,
    logic [$clog2(POP_WIDTH):0] popCount,
output
    logic [$clog2(SIZE)-1:0] headPtr,
    logic [$clog2(SIZE)-1:0] tailPtr,
    logic [$clog2(SIZE):0] count
);

    localparam INDEX_BIT_WIDTH = $clog2(SIZE);
    typedef logic [INDEX_BIT_WIDTH-1:0] IndexPath;
    typedef logic unsigned [INDEX_BIT_WIDTH:0] CountPath;

    IndexPath regHead, nextHead;
    IndexPath regTail, nextTail;
    CountPath regCount, nextCount;

    always_ff @(posedge clk) begin
        if(rst) begin
            regHead <= INITIAL_HEAD_PTR;
            regTail <= INITIAL_TAIL_PTR;
            regCount <= INITIAL_COUNT;
        end
        else begin
            regHead <= nextHead;
            regTail <= nextTail;
            regCount <= nextCount;
        end
    end

    always_comb begin
        nextTail = regTail;
        if (push) begin
            nextTail += pushCount;

            if (nextTail >= SIZE) begin
                nextTail -= SIZE;
            end
        end
    end

    always_comb begin
        nextHead = regHead;
        if (pop) begin
            nextHead += popCount;

            if (nextHead >= SIZE) begin
                nextHead -= SIZE;
            end
        end
        
    end

    always_comb begin
        nextCount = regCount;
        if(push) begin
            nextCount += pushCount;
        end
        if(pop) begin
            nextCount -= popCount;
        end

        headPtr = regHead;
        tailPtr = regTail;
        count = regCount;
    end

    `RSD_ASSERT_CLK(clk, rst || regCount <= SIZE, "The count of a queue execeeds its size.");

endmodule

//
// N-input/N-output queue.
// The "tailPtr" points the address of a next pushed entry.
// Tail pointer and count is recovered in one cycle.
//
module SetTailMultiWidthQueuePointer #( parameter
    SIZE = 1,
    INITIAL_HEAD_PTR = 0,
    INITIAL_TAIL_PTR = 0,
    INITIAL_COUNT = 0,
    PUSH_WIDTH = 1,
    POP_WIDTH = 1
)(
input
    logic clk,
    logic rst,
    logic push,
    logic pop,
    logic [$clog2(PUSH_WIDTH):0] pushCount,
    logic [$clog2(POP_WIDTH):0] popCount,
    logic setTail,
    logic [$clog2(SIZE)-1:0] setTailPtr,
output
    logic [$clog2(SIZE)-1:0] headPtr,
    logic [$clog2(SIZE)-1:0] tailPtr,
    logic [$clog2(SIZE):0] count
);

    localparam INDEX_BIT_WIDTH = $clog2(SIZE);
    typedef logic [INDEX_BIT_WIDTH-1:0] IndexPath;
    typedef logic unsigned [INDEX_BIT_WIDTH:0] CountPath;

    IndexPath regHead, nextHead;
    IndexPath regTail, nextTail;
    IndexPath roundedSetTailPtr;
    CountPath regCount, nextCount;
    always_ff @(posedge clk) begin
        if (rst) begin
            regHead <= INITIAL_HEAD_PTR;
            regTail <= INITIAL_TAIL_PTR;
            regCount <= INITIAL_COUNT;

            //assert( INITIAL_HEAD + INITIAL_COUNT == INITIAL_TAIL );
        end
        else begin
            regHead <= nextHead;
            regTail <= nextTail;
            regCount <= nextCount;
        end
    end

    always_comb begin
        nextTail = regTail;
        if (push) begin
            nextTail += pushCount;
        
            if (nextTail >= SIZE) begin
                nextTail -= SIZE;
            end
        end
        else if (setTail) begin
            nextTail = roundedSetTailPtr;
        end
    end

    always_comb begin
        nextHead = regHead;
        if (pop) begin
            nextHead += popCount;

            if (nextHead >= SIZE) begin
                nextHead -= SIZE;
            end
        end
    end

    always_comb begin
        nextCount = regCount;
        roundedSetTailPtr = setTailPtr;
        if (push) begin
            nextCount += pushCount;
        end
        else if (setTail) begin
            if (setTailPtr >= SIZE) begin
                roundedSetTailPtr = setTailPtr - SIZE;
            end

            nextCount = ( regHead <= roundedSetTailPtr ) ? 
                roundedSetTailPtr - regHead : SIZE + roundedSetTailPtr - regHead;
        end
        if (pop) begin
            nextCount -= popCount;
        end

        headPtr = regHead;
        tailPtr = regTail;
        count = regCount;
    end

    `RSD_ASSERT_CLK(clk, rst || regCount <= SIZE, "The count of a queue execeeds its size.");

endmodule



//
// N-input/N-output queue.
// In this queue, the tail pointer can be popped and pushed.
// The "tailPtr" points the address of a next pushed entry.
//
module BiTailMultiWidthQueuePointer #( parameter
    SIZE = 1,
    INITIAL_HEAD_PTR = 0,
    INITIAL_TAIL_PTR = 0,
    INITIAL_COUNT = 0,
    PUSH_WIDTH = 1,
    POP_WIDTH = 1
)(
input
    logic clk,
    logic rst,
    logic pushTail,
    logic popTail,
    logic popHead,
    logic [$clog2(PUSH_WIDTH):0] pushTailCount,
    logic [$clog2(POP_WIDTH):0] popTailCount,
    logic [$clog2(POP_WIDTH):0] popHeadCount,
output
    logic [$clog2(SIZE)-1:0] headPtr,
    logic [$clog2(SIZE)-1:0] tailPtr,
    logic [$clog2(SIZE):0] count
);

    localparam INDEX_BIT_WIDTH = $clog2(SIZE);
    typedef logic [INDEX_BIT_WIDTH-1:0] IndexPath;
    typedef logic unsigned [INDEX_BIT_WIDTH:0] CountPath;

    IndexPath regHead, nextHead;
    IndexPath regTail, nextTail;
    CountPath regCount, nextCount;

    always_ff @(posedge clk) begin
        if(rst) begin
            regHead <= INITIAL_HEAD_PTR;
            regTail <= INITIAL_TAIL_PTR;
            regCount <= INITIAL_COUNT;
        end
        else begin
            regHead <= nextHead;
            regTail <= nextTail;
            regCount <= nextCount;
        end
    end

    always_comb begin
        nextHead = regHead;

        if (popHead) begin
            nextHead += popHeadCount;
            if (nextHead >= SIZE) begin
                nextHead -= SIZE;
            end
        end
    end

    always_comb begin
        nextTail = regTail;

        if (pushTail) begin
            nextTail += pushTailCount;
            
            if (nextTail >= SIZE) begin
                nextTail -= SIZE;
            end
        end
        else if (popTail) begin
            nextTail -= popTailCount;

            if (nextTail >= SIZE) begin
                nextTail += SIZE;
            end
        end
    end

    always_comb begin
        nextCount = regCount;
        if (pushTail) begin
            nextCount += pushTailCount;

        end
        else if (popTail) begin
            nextCount -= popTailCount;
        end

        if(popHead) begin
            nextCount -= popHeadCount;
        end

        headPtr = regHead;
        tailPtr = regTail;
        count = regCount;
    end

    // Assertion
    `RSD_ASSERT_CLK(clk, rst || regCount <= SIZE, "The count of a queue execeeds its size.");
    `RSD_ASSERT_CLK(clk, rst || !(pushTail && popTail), "BiTailMultiWidthQueuePointer is pushed and popped simultaneously.");

endmodule


//
// N-input/N-output queue.
// In this queue, the tail pointer can be popped and pushed.
// The "tailPtr" points the address of a next pushed entry.
// Tail pointer and count is recovered in one cycle.
//
module SetTailBiTailMultiWidthQueuePointer #( parameter
    SIZE = 1,
    INITIAL_HEAD_PTR = 0,
    INITIAL_TAIL_PTR = 0,
    INITIAL_COUNT = 0,
    PUSH_WIDTH = 1,
    POP_WIDTH = 1
)(
input
    logic clk,
    logic rst,
    logic pushTail,
    logic popTail,
    logic popHead,
    logic [$clog2(PUSH_WIDTH):0] pushTailCount,
    logic [$clog2(POP_WIDTH):0] popTailCount,
    logic [$clog2(POP_WIDTH):0] popHeadCount,
    logic setTail,
    logic [$clog2(SIZE)-1:0] setTailPtr,
output
    logic [$clog2(SIZE)-1:0] headPtr,
    logic [$clog2(SIZE)-1:0] tailPtr,
    logic [$clog2(SIZE):0] count
);

    localparam INDEX_BIT_WIDTH = $clog2(SIZE);
    typedef logic [INDEX_BIT_WIDTH-1:0] IndexPath;
    typedef logic unsigned [INDEX_BIT_WIDTH:0] CountPath;

    IndexPath regHead, nextHead;
    IndexPath regTail, nextTail;
    IndexPath roundedSetTailPtr;
    CountPath regCount, nextCount;

    always_ff @(posedge clk) begin
        if(rst) begin
            regHead <= INITIAL_HEAD_PTR;
            regTail <= INITIAL_TAIL_PTR;
            regCount <= INITIAL_COUNT;

            //assert( INITIAL_HEAD + INITIAL_COUNT == INITIAL_TAIL );
        end
        else begin
            regHead <= nextHead;
            regTail <= nextTail;
            regCount <= nextCount;
        end
    end

    always_comb begin
        nextHead = regHead;

        if (popHead) begin
            nextHead += popHeadCount;
            if (nextHead >= SIZE) begin
                nextHead -= SIZE;
            end
        end
    end

    always_comb begin
        nextTail = regTail;

        if (pushTail) begin
            nextTail += pushTailCount;
            
            if (nextTail >= SIZE) begin
                nextTail -= SIZE;
            end
        end
        else if (popTail) begin
            nextTail -= popTailCount;

            if (nextTail >= SIZE) begin
                nextTail += SIZE;
            end
        end
        else if (setTail) begin
            nextTail = roundedSetTailPtr;
        end
    end

    always_comb begin
        nextCount = regCount;
        roundedSetTailPtr = setTailPtr;
        
        if (pushTail) begin
            nextCount += pushTailCount;
        end
        else if (popTail) begin
            nextCount -= popTailCount;
        end
        else if (setTail) begin
            if (setTailPtr >= SIZE) begin
                roundedSetTailPtr = setTailPtr - SIZE;
            end

            nextCount = ( regHead <= roundedSetTailPtr ) 
                ? roundedSetTailPtr - regHead : SIZE + roundedSetTailPtr - regHead;
        end

        if (popHead) begin
            nextCount -= popHeadCount;
        end

        headPtr = regHead;
        tailPtr = regTail;
        count = regCount;
    end

    `RSD_ASSERT_CLK(clk, rst || regCount <= SIZE, "The count of a queue execeeds its size.");
    `RSD_ASSERT_CLK(clk, rst || !(pushTail && popTail), "BiTailMultiWidthQueuePointer is pushed and popped simultaneously.");

endmodule

// ---- Primitives/RAM.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- RAM implementation.
//


//
// -- Block RAM configured for READ_FIRST mode.
// 
// You can get a read value 1-cycle after you set a read address.
// When you write and read simultaneously, a read value becomes
// the written value .
//

// Simple Dual Port RAM ( 1-read / 1-write )
module BlockDualPortRAM #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] wa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0] ra,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    
`ifdef RSD_SYNTHESIS_OPT_MICROSEMI
    Value array[ENTRY_NUM];   // synthesis syn_ramstyle = "lsram"
`else
    Value array[ENTRY_NUM];   // synthesis syn_ramstyle = "block_ram"
`endif

    always_ff @(posedge clk) begin
        rv <= array[ra];
        if(we) 
            array[wa] <= wv;
    end


    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && wa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );

        `RSD_ASSERT_CLK_FMT(
            clk,
            !(ra >= ENTRY_NUM),
            ("Read from the outside of the RAM array.")
        );
    endgenerate

endmodule : BlockDualPortRAM


// True Dual Port RAM ( 2-read/write )
module BlockTrueDualPortRAM #( 
    parameter ENTRY_NUM = 16, 
    parameter ENTRY_BIT_SIZE = 1,
    parameter PORT_NUM  = 2 // Do NOT change this parameter to synthesize True Dual Port RAM
)( 
    input logic clk,
    input logic we[PORT_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] rwa[PORT_NUM],
    input logic [ENTRY_BIT_SIZE-1: 0] wv[PORT_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[PORT_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

`ifdef RSD_SYNTHESIS_OPT_MICROSEMI
    Value array[ENTRY_NUM];   // synthesis syn_ramstyle = "lsram"
`else
    Value array[ENTRY_NUM];   // synthesis syn_ramstyle = "block_ram"
`endif
    
`ifdef RSD_SYNTHESIS_DESIGN_COMPILER
    // Design Compiler does not accept the statements for Synplify
    always_ff @(posedge clk) begin
        for (int i = 0; i < PORT_NUM; i++) begin
            rv[i] <= array[ rwa[i] ];
            if(we[i]) 
                array[ rwa[i] ] <= wv[i];
        end
    end
`else
    // These statements are for Synplify.
    // The following circuit must be written in a *generate* clause.
    // This is because Synplify generates a circuit that detects writing to the same address if *generate* clause is not used. 
    // This circuit does not affect the operation, but a broken circuit is generated due to a bug of Synplify.
    generate
        for (genvar i = 0; i < PORT_NUM; i++) begin
            always_ff @(posedge clk) begin
                rv[i] <= array[ rwa[i] ];
                if(we[i]) 
                    array[ rwa[i] ] <= wv[i];
            end
        end
    endgenerate
`endif

    generate
        for (genvar j = 0; j < PORT_NUM; j++) begin
            for (genvar i = 0; i < PORT_NUM; i++) begin
                `RSD_ASSERT_CLK_FMT(
                    clk,
                    !(we[i] && we[j] && rwa[i] == rwa[j] && i != j),
                    ("Multiple ports(%x,%x) write to the same entry.", i, j)
                );
            end
        end

        for (genvar i = 0; i < PORT_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                !(rwa[i] >= ENTRY_NUM),
                ("Port (%x) read from or write to the outside of the RAM array.", i)
            );
        end
    endgenerate

endmodule : BlockTrueDualPortRAM


module BlockMultiPortRAM #( 
    parameter ENTRY_NUM = 4, 
    parameter ENTRY_BIT_SIZE = 8, 
    parameter READ_NUM  = 2,
    parameter WRITE_NUM = 2
)( 
    input logic clk,
    input logic we[WRITE_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

    // When using *generate*, a circuit for write arbitration is not created
    generate 
        if (WRITE_NUM > 1) begin

            localparam WRITE_NUM_BIT_SIZE = $clog2( WRITE_NUM );
            typedef logic [WRITE_NUM_BIT_SIZE-1: 0] Select;

            Select select [ENTRY_NUM];
            Value rvBank [READ_NUM][WRITE_NUM];

            logic weReg[WRITE_NUM];
            Address waReg[WRITE_NUM];
            
            // Block RAM read is delayed by 1 cycle
            // use a register for select
            Address raReg[READ_NUM];

            always_ff @(posedge clk) begin
                raReg <= ra;
                weReg <= we;
                waReg <= wa;
            end
                
        
            // Duplicate as many as needed for read/write
            for (genvar j = 0; j < WRITE_NUM; j++) begin
                for (genvar i = 0; i < READ_NUM; i++) begin
                    BlockDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                        rBank(clk, we[j], wa[j], wv[j], ra[i], rvBank[i][j]);
                end
            end

            for (genvar i = 0; i < READ_NUM; i++) begin
                assign rv[i] = rvBank[i][select[raReg[i]]];
            end
            
            for (genvar j = 0; j < WRITE_NUM; j++) begin
                always_ff @(posedge clk) begin
                    if (weReg[j]) begin
                        select[ waReg[j] ] <= j;
                    end
                end
            end
        end
        else begin
            // For single write port RAM.
            // Duplicate as many as needed for read
            for (genvar i = 0; i < READ_NUM; i++) begin
                BlockDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                    rBank(clk, we[0], wa[0], wv[0], ra[i], rv[i]);
            end
        end

    endgenerate

    // For Debug
    `ifndef RSD_SYNTHESIS
        Value debugValue[ENTRY_NUM];
        always_ff @(posedge clk) begin
            for (int i = 0; i < WRITE_NUM; i++) begin
                if (we[i]) begin
                    debugValue[ wa[i] ] <= wv[i];
                end
            end
        end
    `endif


    generate
        for (genvar i = 0; i < READ_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                !(ra[i] >= ENTRY_NUM),
                ("Port (%x) read from the outside of the RAM array.", i)
            );
        end
        for (genvar i = 0; i < WRITE_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                !(we[i] && wa[i] >= ENTRY_NUM),
                ("Port (%x) write to the outside of the RAM array.", i)
            );
        end
    endgenerate
    
endmodule : BlockMultiPortRAM


//
// BlockRAM initialized at power-on
// Initialization is NOT performed at reset
//
module InitializedBlockRAM #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64,
    parameter INIT_HEX_FILE = "code.hex"
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] wa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0] ra,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

`ifdef RSD_SYNTHESIS
    Value array[ENTRY_NUM]; // synthesis syn_ramstyle = "block_ram"
`else
    // This signal will be written in a test bench, so set public for verilator.
    Value array[ENTRY_NUM] /*verilator public*/;
`endif

    Address raReg;

    always_ff @(posedge clk) begin
        if(we)
            array[wa] <= wv;
            
        raReg <= ra;
    end
    
    always_comb begin
        rv = array[raReg];
    end

    initial begin
        if (INIT_HEX_FILE != "") begin
            $readmemh(INIT_HEX_FILE, array);
        end
        else begin
            $display(
                "INIT_HEX_FILE in InitializedBlockRAM is not specified, so no file is read."
            );
        end
    end

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && wa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );

        `RSD_ASSERT_CLK_FMT(
            clk,
            !(ra >= ENTRY_NUM),
            ("Read from the outside of the RAM array.")
        );
    endgenerate
    
endmodule : InitializedBlockRAM


//
// InitializedBlockRAM that supports a bandwidth of 64 bits or less
//
module InitializedBlockRAM_ForNarrowRequest #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64,
    parameter INIT_HEX_FILE = "code.hex"
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] wa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0] ra,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);

    // Request side
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    localparam ENTRY_BIT_WIDTH = $clog2(ENTRY_BIT_SIZE);

    // Since the hex file is read in 128 bits units, the memory array is also 128 bits units.
    localparam HEX_FILE_ENTRY_BIT_SIZE = 128;
    // Calculates the index width when the memory array is configured in 128 bits units from the bandwidth
    // ********-------   : 128 bits memory array (Actual memory array)
    // *********------  : 64 bits memory array (Externally visible memory array)
    // (Index)   (Offset)
    // The sum of the bit width of Index and Offset is always the same
    localparam HEX_FILE_ENTRY_BIT_WIDTH = $clog2(HEX_FILE_ENTRY_BIT_SIZE);
    localparam HEX_FILE_INDEX_BIT_SIZE = INDEX_BIT_SIZE + ENTRY_BIT_WIDTH - HEX_FILE_ENTRY_BIT_WIDTH;

    // Hex file memory array
    localparam HEX_BLOCK_OFFSET_INDEX = 
        (INDEX_BIT_SIZE > HEX_FILE_INDEX_BIT_SIZE) ? INDEX_BIT_SIZE - HEX_FILE_INDEX_BIT_SIZE : 1;
    typedef logic [HEX_FILE_INDEX_BIT_SIZE-1: 0] HexArrayIndex;
    typedef logic [HEX_FILE_ENTRY_BIT_SIZE-1: 0] HexArrayValue;
    typedef logic [HEX_BLOCK_OFFSET_INDEX-1:0] HexArrayEntryOffset;

    // Raise an error if the bandwidth is greater than 128 bits
    `RSD_STATIC_ASSERT(
        HEX_FILE_ENTRY_BIT_WIDTH <= ENTRY_BIT_SIZE, 
        "Set ENTRY_BIT_SIZE less than or equal to 128 bits"
    );

    function automatic HexArrayEntryOffset GetBlockOffsetFromAddress(Address addr);
        if (INDEX_BIT_SIZE > HEX_FILE_INDEX_BIT_SIZE)  begin
            return addr[HEX_BLOCK_OFFSET_INDEX-1:0];
        end
        else begin
            return '0;
        end
    endfunction

    function automatic HexArrayIndex GetHexArrayIndexFromAddress(Address addr);
        if (INDEX_BIT_SIZE > HEX_FILE_INDEX_BIT_SIZE)  begin
            return addr[INDEX_BIT_SIZE-1:HEX_BLOCK_OFFSET_INDEX];
        end
        else begin
            return addr;
        end
    endfunction

`ifdef RSD_SYNTHESIS
    HexArrayValue array[1 << HEX_FILE_INDEX_BIT_SIZE]; // synthesis syn_ramstyle = "block_ram"
`else
    // This signal will be written in a test bench, so set public for verilator.
    HexArrayValue array[1 << HEX_FILE_INDEX_BIT_SIZE] /*verilator public*/;
`endif

    Address raReg;
    HexArrayIndex hexFileRA;
    HexArrayValue hexFileRV;
    HexArrayEntryOffset hexFileRAOffset;

    HexArrayIndex hexFileWA;
    HexArrayValue hexFileWV;
    HexArrayEntryOffset hexFileWAOffset;
    HexArrayValue tmpWriteEntry;

    always_ff @(posedge clk) begin
        if (we) begin
            array[hexFileWA] <= hexFileWV;
        end
            
        raReg <= ra;
    end
    
    // Read request
    always_comb begin
        // Read from the hex file array
        hexFileRA = GetHexArrayIndexFromAddress(raReg);
        hexFileRAOffset =GetBlockOffsetFromAddress(raReg);
        hexFileRV = array[hexFileRA];
        // Reads the position specified by the offset in the 128 bits entry
        rv = hexFileRV[hexFileRAOffset*ENTRY_BIT_SIZE+:ENTRY_BIT_SIZE];
    end

    // Write request
    always_comb begin
        // Write to the hex file array
        hexFileWA = GetHexArrayIndexFromAddress(wa);
        hexFileWAOffset = GetBlockOffsetFromAddress(wa);

        // Since only the appropriate part of the 128-bit entry needs 
        // to be rewritten, read the data once
        tmpWriteEntry = array[hexFileWA];
        // Update only the appropriate parts
        tmpWriteEntry[hexFileWAOffset*ENTRY_BIT_SIZE+:ENTRY_BIT_SIZE] = wv;
        hexFileWV = tmpWriteEntry;
    end

    initial begin
        if (INIT_HEX_FILE != "") begin
            $readmemh(INIT_HEX_FILE, array);
        end
        else begin
            $display(
                "INIT_HEX_FILE in InitializedBlockRAM is not specified, so no file is read."
            );
        end
    end

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && wa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );

        `RSD_ASSERT_CLK_FMT(
            clk,
            !(ra >= ENTRY_NUM),
            ("Read from the outside of the RAM array.")
        );
    endgenerate

endmodule : InitializedBlockRAM_ForNarrowRequest


//
// InitializedBlockRAM that supports a bandwidth of 256 bits or more
//
module InitializedBlockRAM_ForWideRequest #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64,
    parameter INIT_HEX_FILE = "code.hex"
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] wa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0] ra,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);

    // Request side
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    localparam ENTRY_BIT_WIDTH = $clog2(ENTRY_BIT_SIZE);

    // Since the hex file is read in 128 bits units, the memory array is also 128 bits units.
    localparam HEX_FILE_ENTRY_BIT_SIZE = 128;
    // Calculates the index width when the memory array is configured in 128 bits units from the bandwidth
    // ********-------   : 128 bits memory array (Actual memory array)
    // *******--------   : 256 bits memory array  (Externally visible memory array)
    // (Index)   (Offset)
    // The sum of the bit width of Index and Offset is always the same
    localparam HEX_FILE_ENTRY_BIT_WIDTH = $clog2(HEX_FILE_ENTRY_BIT_SIZE);
    localparam HEX_FILE_INDEX_BIT_SIZE = 
        INDEX_BIT_SIZE + ENTRY_BIT_WIDTH - HEX_FILE_ENTRY_BIT_WIDTH;

    // Since the bandwidth is wide, 
    // read is realized by accessing hexArray multiple times.
    // Therefore, calculate how many times hexArray needs to be accessed
    localparam DIFF_BIT_WIDTH = (HEX_FILE_INDEX_BIT_SIZE > INDEX_BIT_SIZE) ? 
        HEX_FILE_INDEX_BIT_SIZE - INDEX_BIT_SIZE : 1;
    typedef logic [DIFF_BIT_WIDTH-1:0] CountPath;
    localparam HEX_BLOCK_FILL_NUM = (HEX_FILE_INDEX_BIT_SIZE > INDEX_BIT_SIZE) ?
        1 << DIFF_BIT_WIDTH : 1;

    // Hex file memory array
    typedef logic [HEX_FILE_INDEX_BIT_SIZE-1: 0] HexArrayIndex;
    typedef logic [HEX_FILE_ENTRY_BIT_SIZE-1: 0] HexArrayValue;

    // Raise an error if the bandwidth is smaller than or equal to 128 bits
    `RSD_STATIC_ASSERT(
        HEX_FILE_ENTRY_BIT_WIDTH <= ENTRY_BIT_WIDTH, 
        "Set ENTRY_BIT_SIZE more than 128 bits"
    );

    function automatic HexArrayIndex GetHexArrayIndexFromAddress(Address addr, CountPath count);
        if (HEX_FILE_INDEX_BIT_SIZE > INDEX_BIT_SIZE) begin
            return {addr, count};
        end
        else begin
            return addr;
        end
    endfunction

`ifdef RSD_SYNTHESIS
    HexArrayValue array[1 << HEX_FILE_INDEX_BIT_SIZE]; // synthesis syn_ramstyle = "block_ram"
`else
    // This signal will be written in a test bench, so set public for verilator.
    HexArrayValue array[1 << HEX_FILE_INDEX_BIT_SIZE] /*verilator public*/;
`endif

    Address raReg;
    HexArrayIndex hexFileRA[HEX_BLOCK_FILL_NUM];
    HexArrayValue hexFileRV[HEX_BLOCK_FILL_NUM];

    HexArrayIndex hexFileWA[HEX_BLOCK_FILL_NUM];
    HexArrayValue hexFileWV[HEX_BLOCK_FILL_NUM];

    always_ff @(posedge clk) begin
        if (we) begin
            for (int i = 0; i < HEX_BLOCK_FILL_NUM; i++) begin
                array[hexFileWA[i]] <= hexFileWV[i];
            end
        end
            
        raReg <= ra;
    end
    
    // Read request
    always_comb begin
        // Read from the hex file array
        for (int i = 0; i < HEX_BLOCK_FILL_NUM; i++) begin
            hexFileRA[i] = GetHexArrayIndexFromAddress(raReg, i);
            hexFileRV[i] = array[hexFileRA[i]];
            rv[HEX_FILE_ENTRY_BIT_SIZE*i+:HEX_FILE_ENTRY_BIT_SIZE] = hexFileRV[i];
        end
    end

    // Write request
    always_comb begin
        // Write to the hex file array
        for (int i = 0; i < HEX_BLOCK_FILL_NUM; i++) begin
            hexFileWA[i] = GetHexArrayIndexFromAddress(wa, i);
            hexFileWV[i] = wv[HEX_FILE_ENTRY_BIT_SIZE*i+:HEX_FILE_ENTRY_BIT_SIZE];
        end
    end

    initial begin
        if (INIT_HEX_FILE != "") begin
            $readmemh(INIT_HEX_FILE, array);
        end
        else begin
            $display(
                "INIT_HEX_FILE in InitializedBlockRAM is not specified, so no file is read."
            );
        end
    end

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && wa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );

        `RSD_ASSERT_CLK_FMT(
            clk,
            !(ra >= ENTRY_NUM),
            ("Read from the outside of the RAM array.")
        );
    endgenerate

endmodule : InitializedBlockRAM_ForWideRequest


//
// Single Port RAM using Distributed RAM
// multi read/write

module DistributedSinglePortRAM #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] rwa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

    Value array[ENTRY_NUM]; // synthesis syn_ramstyle = "select_ram"
    
    always_ff @(posedge clk) begin
        if(we)
            array[rwa] <= wv;
    end
    
    always_comb begin
        rv = array[rwa];
    end

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && rwa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );
    endgenerate

endmodule : DistributedSinglePortRAM

//
// Multi ports RAM using Distributed RAM
// multi read/write
//

// 1-read / 1-write
module DistributedDualPortRAM #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] wa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0] ra,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);

    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    Value array[ENTRY_NUM];  // synthesis syn_ramstyle = "select_ram"

    always_ff @(posedge clk) begin
        if(we)
            array[wa] <= wv;
    end
    
    always_comb begin
        rv = array[ra];
    end

`ifndef RSD_SYNTHESIS
    initial begin
        for (int i = 0; i < ENTRY_NUM; i++) begin
            for (int j = 0; j < ENTRY_BIT_SIZE; j++) begin
                array[i][j] = 0;
            end
        end
    end
`endif

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && wa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );
    endgenerate

endmodule : DistributedDualPortRAM

// 1-read / 1-write
module RegisterDualPortRAM #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0] wa,
    input logic [ENTRY_BIT_SIZE-1: 0] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0] ra,
    output logic [ENTRY_BIT_SIZE-1: 0] rv
);

    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    Value array[ENTRY_NUM];   // synthesis syn_ramstyle = "registers"

    always_ff @(posedge clk) begin
        if(we)
            array[wa] <= wv;
    end
    
    always_comb begin
        rv = array[ra];
    end

`ifndef RSD_SYNTHESIS
    initial begin
        for (int i = 0; i < (ENTRY_NUM); i++) begin
            for (int j = 0; j < ENTRY_BIT_SIZE; j++) begin
                array[i][j] = 0;
            end
        end
    end
`endif

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(we && wa >= ENTRY_NUM),
            ("Write to the outside of the RAM array.")
        );

        `RSD_ASSERT_CLK_FMT(
            clk,
            !(ra >= ENTRY_NUM),
            ("Read from the outside of the RAM array.")
        );
    endgenerate

endmodule : RegisterDualPortRAM


// 1-read-write / (N-1)-read ports
module DistributedSharedMultiPortRAM #( 
    parameter ENTRY_NUM = 128, 
    parameter ENTRY_BIT_SIZE = 64,
    parameter READ_NUM  = 4
)( 
    input logic clk,
    input logic we,
    input logic [$clog2(ENTRY_NUM)-1: 0 ] rwa,
    input logic [ENTRY_BIT_SIZE-1: 0 ] wv,
    input logic [$clog2(ENTRY_NUM)-1: 0 ] ra[READ_NUM-1],
    output logic [ENTRY_BIT_SIZE-1: 0 ] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    
    Value array[ ENTRY_NUM ];  // synthesis syn_ramstyle = "select_ram"

    always_ff @(posedge clk) begin
        if(we)
            array[rwa] <= wv;
    end
    
    always_comb begin
        for (int i = 0; i < READ_NUM-1; i++) begin
            rv[i] = array[ ra[i] ];
        end
        rv[READ_NUM-1] = array[rwa];
    end

    generate
        `RSD_ASSERT_CLK_FMT(
            clk,
            !(rwa >= ENTRY_NUM),
            ("Port (%x) read from or write to the outside of the RAM array.", 0)
        );

        for (genvar i = 0; i < READ_NUM-1; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                !(ra >= ENTRY_NUM),
                ("Port (%x) read from the outside of the RAM array.", i+1)
            );
        end
    endgenerate
        
endmodule : DistributedSharedMultiPortRAM



// N-read / M-write (Use Live Value Table)
module LVT_DistributedMultiPortRAM #( 
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 63, 
    parameter READ_NUM = 3,
    parameter WRITE_NUM = 3
)( 
    input logic clk,
    input logic we[ WRITE_NUM ],
    input logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    
    // avoid logic[-1:0] when WRITE_NUM == 1
    localparam WRITE_NUM_BIT_SIZE = WRITE_NUM == 1 ? 1 : $clog2(WRITE_NUM);
    typedef logic [WRITE_NUM_BIT_SIZE-1: 0] LiveValue;

    // When using *generate*, a circuit for write arbitration is not created
    generate 
        
        if (WRITE_NUM > 1) begin
            Value rvBank[READ_NUM][WRITE_NUM];
            LiveValue lvi[WRITE_NUM];
            LiveValue lvo[READ_NUM];

`ifdef RSD_SYNTHESIS_OPT_MICROSEMI
            RegisterMultiPortRAM #(ENTRY_NUM, WRITE_NUM_BIT_SIZE, READ_NUM, WRITE_NUM)
                lvt(clk, we, wa, lvi, ra, lvo);
`else
            // For Xilinx
            XOR_DistributedMultiPortRAM #(ENTRY_NUM, WRITE_NUM_BIT_SIZE, READ_NUM, WRITE_NUM)
                lvt(clk, we, wa, lvi, ra, lvo);
`endif

            // Duplicate as many as needed for read/write
            for (genvar j = 0; j < WRITE_NUM; j++) begin
                for ( genvar i = 0; i < READ_NUM; i++) begin
                    DistributedDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                        rBank(clk, we[j], wa[j], wv[j], ra[i], rvBank[i][j]);
                end
            end

            for (genvar i = 0; i < READ_NUM; i++) begin
                assign rv[i] = rvBank[i][ lvo[i] ];
            end
            
            for (genvar i = 0; i < WRITE_NUM; i++) begin
                assign lvi[i] = i;
            end
        end
        else begin
            // For single write port RAM.
            // Duplicate as many as needed for read
            for (genvar i = 0; i < READ_NUM; i++) begin
                DistributedDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                    rBank(clk, we[0], wa[0], wv[0], ra[i], rv[i]);
            end
        end
        
    endgenerate
    
    // For Debug
`ifndef RSD_SYNTHESIS
    // This signal will be written in a test bench, so set public for verilator.
    Value debugValue[ ENTRY_NUM ] /*verilator public*/;  
    always_ff @ ( posedge clk ) begin
        for(int i = 0; i < WRITE_NUM; i++) begin
            if( we[i] )
                debugValue[ wa[i] ] <= wv[i];
        end
    end

    generate
        for (genvar i = 0; i < READ_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                debugValue[ra[i]] == rv[i],
                ("The read output of a port(%x) is incorrect.", i)
            );
        end
    endgenerate
`endif
    
endmodule : LVT_DistributedMultiPortRAM


//
// XOR based LUT RAM.
// "Multi-ported memories for FPGAs via XOR", Laforest, Charles Eric et. al., 
// FPGA 2012
//

module XOR_DistributedMultiPortRAM #( 
    parameter ENTRY_NUM = 32, 
    parameter ENTRY_BIT_SIZE = 2, 
    parameter READ_NUM  = 8,
    parameter WRITE_NUM = 2
)( 
    input  logic clk,
    input  logic we[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input  logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    
    localparam WRITE_NUM_BIT_SIZE = $clog2(WRITE_NUM);
    
    Value rwbWriteValue[WRITE_NUM];
    Address wbReadAddr[WRITE_NUM];
    Value wbReadValue[WRITE_NUM][WRITE_NUM];

    Address rbReadAddr[READ_NUM];
    Value rbReadValue[WRITE_NUM][READ_NUM];

    generate 
        
        // Horizontal banks: the same address and value is written.
        // Vertical banks: they are xor-ed.
        
        
        // A w-bank is a bank for feeding values to write ports of other banks.
        // wB(j,i): 
        //   wB(0,0)     wB(0,1) ... wB(0,#WN-1) 
        //   wB(1,0)     wB(1,1) ... wB(1,#WN-1) 
        //   ...
        //   wB(#WN-1,0) wB(1,1) ... wB(#WN-1,#WN-1) 
        
        for (genvar j = 0; j < WRITE_NUM; j++) begin : wj
            for (genvar i = 0; i < WRITE_NUM; i++) begin : wi
                if (j != i) begin
                    // The bank of i == j is not necessary.
                    DistributedDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                        wBank(clk, we[j], wa[j], rwbWriteValue[j], wbReadAddr[i], wbReadValue[j][i]);
                end
            end
        end


        // A r-bank is a bank for feeding values to read ports.
        // wB(j,i): 
        //   rB(0,0)     rB(0,1) ... rB(0,#RN-1) 
        //   rB(1,0)     rB(1,1) ... rB(1,#RN-1) 
        //   ...
        //   rB(#WN-1,0) rB(1,1) ... rB(#WN-1,#RN-1) 
        
        for (genvar j = 0; j < WRITE_NUM; j++) begin : rj
            for (genvar i = 0; i < READ_NUM; i++) begin : ri
                DistributedDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                    rBank(clk, we[j], wa[j], rwbWriteValue[j], rbReadAddr[i], rbReadValue[j][i]);
            end
        end

    endgenerate
    
    
    always_comb begin
        // Read from w-banks.
        for (int j = 0; j < WRITE_NUM; j++) begin
            wbReadAddr[j] = wa[j];
        end

        // XOR
        for (int i = 0; i < WRITE_NUM; i++) begin
            rwbWriteValue[i] = wv[i];
            for (int j = 0; j < WRITE_NUM; j++) begin
                if (i != j) begin
                    rwbWriteValue[i] ^= wbReadValue[j][i];
                end
            end
        end

        // Read from r-banks.
        for (int i = 0; i < READ_NUM; i++) begin
            rbReadAddr[i] = ra[i];
        end

        // XOR
        for (int i = 0; i < READ_NUM; i++) begin
            rv[i] = 0;
            for (int j = 0; j < WRITE_NUM; j++) begin
                rv[i] ^= rbReadValue[j][i];
            end
        end
    end
    
    generate
        for (genvar j = 0; j < WRITE_NUM; j++) begin
            for (genvar i = 0; i < WRITE_NUM; i++) begin
                `RSD_ASSERT_CLK_FMT(
                    clk,
                    !(we[i] && we[j] && wa[i] == wa[j] && i != j),
                    ("Multiple ports(%x,%x) write to the same entry.", i, j)
                );
            end
        end
    endgenerate
    
    // For Debug
`ifndef RSD_SYNTHESIS
    Value debugValue[ENTRY_NUM];
    always_ff @(posedge clk) begin
        for (int i = 0; i < WRITE_NUM; i++) begin
            if (we[i])
                debugValue[ wa[i] ] <= wv[i];
        end
    end

    generate
        for (genvar i = 0; i < READ_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                debugValue[ra[i]] == rv[i],
                ("The read output of a port(%x) is incorrect.", i)
            );
        end
    endgenerate
`endif

endmodule : XOR_DistributedMultiPortRAM


// N-read / M-write (use Live Value Table)
module DistributedMultiPortRAM #( 
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 63, 
    parameter READ_NUM = 3,
    parameter WRITE_NUM = 3
)( 
    input logic clk,
    input logic we[ WRITE_NUM ],
    input logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

    generate 
        if ((READ_NUM < 2 && WRITE_NUM && ENTRY_BIT_SIZE < 8) || 
            (INDEX_BIT_SIZE <= 4 && ENTRY_BIT_SIZE > 64)) begin
`ifdef RSD_SYNTHESIS_OPT_MICROSEMI
            RegisterMultiPortRAM #(ENTRY_NUM, ENTRY_BIT_SIZE, READ_NUM, WRITE_NUM)
                body(clk, we, wa, wv, ra, rv);
`else
            // For Xilinx
            XOR_DistributedMultiPortRAM #(ENTRY_NUM, ENTRY_BIT_SIZE, READ_NUM, WRITE_NUM)
                body(clk, we, wa, wv, ra, rv);
`endif
        end
        else begin
            LVT_DistributedMultiPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE, READ_NUM, WRITE_NUM)
                body(clk, we, wa, wv, ra, rv);
        end
    endgenerate

    // For Debug
`ifndef RSD_SYNTHESIS
    Value debugValue[ENTRY_NUM] /*verilator public*/;
    always_ff @(posedge clk) begin
        for (int i = 0; i < WRITE_NUM; i++) begin
            if (we[i])
                debugValue[ wa[i] ] <= wv[i];
        end
    end

    generate
        for (genvar i = 0; i < READ_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                debugValue[ra[i]] == rv[i],
                ("The read output of a port(%x) is incorrect.", i)
            );
        end
    endgenerate
`endif
    
endmodule


//
// LUT+FF
//

module RegisterMultiPortRAM #( 
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 2, 
    parameter READ_NUM = 8,
    parameter WRITE_NUM = 4
)( 
    input logic clk,
    input logic we[WRITE_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

`ifdef RSD_SYNTHESIS_OPT_MICROSEMI
    Value array[ENTRY_NUM]; // synthesis syn_ramstyle = "registers"
`else
    Value array[ENTRY_NUM];
`endif 

    generate 
        for (genvar i = 0; i < WRITE_NUM; i++) begin
            always_ff @(posedge clk) begin
                if (we[i])
                    array[ wa[i] ] <= wv[i];
            end
        end
    endgenerate

    always_comb begin
        for (int i = 0; i < READ_NUM; i++) begin
            rv[i] = array[ ra[i] ];
        end
    end

endmodule : RegisterMultiPortRAM


//
// --- Distributed RAM consisting of multiple banks
// In a functional simulation, a bank conflict is detected as an error
//
module DistributedMultiBankRAM #( 
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 63, 
    parameter READ_NUM  = 4,
    parameter WRITE_NUM = 2
)( 
    input  logic clk,
    input  logic we[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input  logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

    localparam BANK_NUM_BIT_WIDTH = $clog2(READ_NUM > WRITE_NUM ? READ_NUM : WRITE_NUM);
    localparam BANK_NUM = 1 << BANK_NUM_BIT_WIDTH;


    generate
        if (BANK_NUM >= 2) begin
            DistributedMultiBankRAM_ForGE2Banks#(ENTRY_NUM, ENTRY_BIT_SIZE, READ_NUM, WRITE_NUM)
                rBank(clk, we, wa, wv, ra, rv);
        end
        else begin
            DistributedDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                rBank(clk, we[0], wa[0], wv[0], ra[0], rv[0]);
        end
    endgenerate


`ifndef RSD_SYNTHESIS
    // For Debug
    // This signal will be written in a test bench, so set public for verilator.
    Value debugValue[ ENTRY_NUM ] /*verilator public*/;
    initial begin
        for (int i = 0; i < ENTRY_NUM; i++) begin
            for (int j = 0; j < ENTRY_BIT_SIZE; j++) begin
                debugValue[i][j] = 0;
            end
        end
    end

    always_ff @(posedge clk) begin
        for (int i = 0; i < WRITE_NUM; i++) begin
            if (we[i])
                debugValue[ wa[i] ] <= wv[i];
        end
    end

    generate
        for (genvar i = 0; i < READ_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                debugValue[ ra[i] ] == rv[i],
                ("The read output of a port(%x) is incorrect.", i)
            );
        end
    endgenerate
`endif

endmodule : DistributedMultiBankRAM

//
// --- Distributed RAM consisting of multiple banks
// Generated in DistributedMultiBankRAM when the number of banks is 2 or more
//
module DistributedMultiBankRAM_ForGE2Banks #( 
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 63, 
    parameter READ_NUM  = 4,
    parameter WRITE_NUM = 2
)( 
    input  logic clk,
    input  logic we[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input  logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    
    localparam BANK_NUM_BIT_WIDTH = $clog2(READ_NUM > WRITE_NUM ? READ_NUM : WRITE_NUM);
    localparam BANK_NUM = 1 << BANK_NUM_BIT_WIDTH;
    localparam BANK_INDEX_BIT_SIZE = INDEX_BIT_SIZE - BANK_NUM_BIT_WIDTH;

    
    Address waBank[BANK_NUM];
    Address raBank[BANK_NUM];
    Value rvBank[BANK_NUM];
    Value wvBank[BANK_NUM];
    logic weBank[BANK_NUM];
    
    // Raise error if the number of entries is not a multiple of 
    // the number of banks
    `RSD_STATIC_ASSERT(
        ENTRY_NUM % BANK_NUM == 0,
        "Set the number of entries a multiple of the number of banks."
    );

    generate 
        for (genvar i = 0; i < BANK_NUM; i++) begin
            if (ENTRY_BIT_SIZE < 8) begin
                RegisterDualPortRAM#(ENTRY_NUM / BANK_NUM, ENTRY_BIT_SIZE)
                    rBank(
                        clk, 
                        weBank[i], 
                        waBank[i][INDEX_BIT_SIZE-1 : BANK_NUM_BIT_WIDTH], 
                        wvBank[i], 
                        raBank[i][INDEX_BIT_SIZE-1 : BANK_NUM_BIT_WIDTH], 
                        rvBank[i]
                    );
            end
            else begin
                DistributedDualPortRAM#(ENTRY_NUM / BANK_NUM, ENTRY_BIT_SIZE)
                    rBank(
                        clk, 
                        weBank[i], 
                        waBank[i][INDEX_BIT_SIZE-1 : BANK_NUM_BIT_WIDTH], 
                        wvBank[i], 
                        raBank[i][INDEX_BIT_SIZE-1 : BANK_NUM_BIT_WIDTH], 
                        rvBank[i]
                    );
            end
        end
    endgenerate
    
    always_comb begin

        for (int b = 0; b < BANK_NUM; b++) begin
            weBank[b] = '0;     // It must be 0.
            waBank[b] = wa[0];  // Don't care
            wvBank[b] = wv[0];
            
            for (int i = 0; i < WRITE_NUM; i++) begin
                if (we[i] && wa[i][BANK_NUM_BIT_WIDTH-1 : 0] == b) begin
                    weBank[b] = we[i];
                    waBank[b] = wa[i];
                    wvBank[b] = wv[i];
                    break;
                end
            end
        end

        for (int b = 0; b < BANK_NUM; b++) begin
            raBank[b] = ra[0]; // Don't care
            for (int i = 0; i < READ_NUM; i++) begin
                if (ra[i][BANK_NUM_BIT_WIDTH-1 : 0] == b) begin
                    raBank[b] = ra[i];
                    break;
                end
            end
        end

        for (int i = 0; i < READ_NUM; i++) begin
            rv[i] = rvBank[0];  // Don't care
            for (int b = 0; b < BANK_NUM; b++) begin
                if (ra[i][BANK_NUM_BIT_WIDTH-1 : 0] == b) begin
                    rv[i] = rvBank[b];
                    break;
                end
            end
        end
        
    end

    generate
        for (genvar j = 0; j < WRITE_NUM; j++) begin
            for (genvar i = 0; i < WRITE_NUM; i++) begin
                `RSD_ASSERT_CLK_FMT(
                    clk,
                    !(we[i] && we[j] && wa[i][BANK_NUM_BIT_WIDTH-1 : 0] == wa[j][BANK_NUM_BIT_WIDTH-1 : 0] && i != j),
                    ("Multiple ports(%x,%x) write to the same bank.", i, j)
                );
            end
        end
        for (genvar j = 0; j < READ_NUM; j++) begin
            for (genvar i = 0; i < READ_NUM; i++) begin
                `RSD_ASSERT_CLK_FMT(
                    clk,
                    !(ra[i][BANK_NUM_BIT_WIDTH-1 : 0] == ra[j][BANK_NUM_BIT_WIDTH-1 : 0] && i != j),
                    ("Multiple ports(%x,%x) read from the same bank.", i, j)
                );
            end
        end
    endgenerate
    
endmodule : DistributedMultiBankRAM_ForGE2Banks


//
// --- Block RAM consisting of multiple banks
// In a functional simulation, a bank conflict is detected as an error
//
module BlockMultiBankRAM #(
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 63, 
    parameter READ_NUM  = 2,
    parameter WRITE_NUM = 2
)( 
    input  logic clk,
    input  logic we[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input  logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;

    localparam BANK_NUM_BIT_WIDTH = $clog2(READ_NUM > WRITE_NUM ? READ_NUM : WRITE_NUM);
    localparam BANK_NUM = 1 << BANK_NUM_BIT_WIDTH;

    generate 
        if (BANK_NUM >= 2) begin
            BlockMultiBankRAM_Body#(ENTRY_NUM, ENTRY_BIT_SIZE, READ_NUM, WRITE_NUM)
                rBank(clk, we, wa, wv, ra, rv);
        end
        else begin
            BlockDualPortRAM#(ENTRY_NUM, ENTRY_BIT_SIZE)
                rBank(clk, we[0], wa[0], wv[0], ra[0], rv[0]);
        end
    endgenerate

`ifndef RSD_SYNTHESIS
    // For Debug
    // This signal will be written in a test bench, so set public for verilator.
    Value debugValue[ ENTRY_NUM ] /*verilator public*/;
    initial begin
        for (int i = 0; i < ENTRY_NUM; i++) begin
            for (int j = 0; j < ENTRY_BIT_SIZE; j++) begin
                debugValue[i][j] = 0;
            end
        end
    end

    Value rvReg[READ_NUM];
    always_ff @(posedge clk) begin
        for (int i = 0; i < READ_NUM; i++) begin
            rvReg[i] <= debugValue[ ra[i] ];
        end
        for (int i = 0; i < WRITE_NUM; i++) begin
            if (we[i])
                debugValue[ wa[i] ] <= wv[i];
        end

    end

    generate
        for (genvar i = 0; i < READ_NUM; i++) begin
            `RSD_ASSERT_CLK_FMT(
                clk,
                rvReg[i] == rv[i],
                ("The read output of a port(%x) is incorrect", i)
            );
        end
    endgenerate
`endif

endmodule : BlockMultiBankRAM


//
// --- Block RAM consisting of multiple banks
// Generated in BlockMultiBankRAM when the number of banks is 2 or more
//
module BlockMultiBankRAM_Body #(
    parameter ENTRY_NUM = 64, 
    parameter ENTRY_BIT_SIZE = 63, 
    parameter READ_NUM  = 2,
    parameter WRITE_NUM = 2
)( 
    input  logic clk,
    input  logic we[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] wa[WRITE_NUM],
    input  logic [ENTRY_BIT_SIZE-1: 0] wv[WRITE_NUM],
    input  logic [$clog2(ENTRY_NUM)-1: 0] ra[READ_NUM],
    output logic [ENTRY_BIT_SIZE-1: 0] rv[READ_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    typedef logic [INDEX_BIT_SIZE-1: 0] Address;
    typedef logic [ENTRY_BIT_SIZE-1: 0] Value;
    
    localparam BANK_NUM_BIT_WIDTH = $clog2(READ_NUM > WRITE_NUM ? READ_NUM : WRITE_NUM);
    localparam BANK_NUM = 1 << BANK_NUM_BIT_WIDTH;
    localparam BANK_INDEX_BIT_SIZE = INDEX_BIT_SIZE - BANK_NUM_BIT_WIDTH;

    
    Address waBank[BANK_NUM];
    Address raBank[BANK_NUM];
    Value rvBank[BANK_NUM];
    Value wvBank[BANK_NUM];
    logic weBank[BANK_NUM];

    Address raReg[BANK_NUM];

    // Raise error if the number of entries is not a multiple of 
    // the number of banks
    `RSD_STATIC_ASSERT(
        ENTRY_NUM % BANK_NUM == 0,
        "Set the number of entries a multiple of the number of banks."
    );
    
    generate 
        for (genvar i = 0; i < BANK_NUM; i++) begin
            BlockDualPortRAM#(ENTRY_NUM/BANK_NUM, ENTRY_BIT_SIZE)
                rBank(
                    clk, 
                    weBank[i], 
                    waBank[i][INDEX_BIT_SIZE-1 : BANK_NUM_BIT_WIDTH], 
                    wvBank[i], 
                    raBank[i][INDEX_BIT_SIZE-1 : BANK_NUM_BIT_WIDTH], 
                    rvBank[i]
                );
        end
    endgenerate
    
    always_ff @(posedge clk) begin
        for (int i = 0; i < BANK_NUM; i++) begin
            raReg[i] <= ra[i];
        end
    end

    always_comb begin

        for (int b = 0; b < BANK_NUM; b++) begin
            weBank[b] = '0;     // It must be 0.
            waBank[b] = wa[0];  // Don't care
            wvBank[b] = wv[0];
            
            for (int i = 0; i < WRITE_NUM; i++) begin
                if (we[i] && wa[i][BANK_NUM_BIT_WIDTH-1 : 0] == b) begin
                    weBank[b] = we[i];
                    waBank[b] = wa[i];
                    wvBank[b] = wv[i];
                    break;
                end
            end
        end

        for (int b = 0; b < BANK_NUM; b++) begin
            raBank[b] = ra[0]; // Don't care
            for (int i = 0; i < READ_NUM; i++) begin
                if (ra[i][BANK_NUM_BIT_WIDTH-1 : 0] == b) begin
                    raBank[b] = ra[i];
                    break;
                end
            end
        end

        for (int i = 0; i < READ_NUM; i++) begin
            rv[i] = rvBank[0];  // Don't care
            for (int b = 0; b < BANK_NUM; b++) begin
                if (raReg[i][BANK_NUM_BIT_WIDTH-1 : 0] == b) begin
                    rv[i] = rvBank[b];
                    break;
                end
            end
        end
    end

    generate
        for (genvar j = 0; j < WRITE_NUM; j++) begin
            for (genvar i = 0; i < WRITE_NUM; i++) begin
                `RSD_ASSERT_CLK_FMT(
                    clk,
                    !(we[i] && we[j] && wa[i][BANK_NUM_BIT_WIDTH-1 : 0] == wa[j][BANK_NUM_BIT_WIDTH-1 : 0] && i != j),
                    ("Multiple ports(%x,%x) write to the same bank.", i, j)
                );
            end
        end
        for (genvar j = 0; j < READ_NUM; j++) begin
            for (genvar i = 0; i < READ_NUM; i++) begin
                `RSD_ASSERT_CLK_FMT(
                    clk,
                   !(ra[i][BANK_NUM_BIT_WIDTH-1 : 0] == ra[j][BANK_NUM_BIT_WIDTH-1 : 0] && i != j),
                    ("Multiple ports(%x,%x) read from the same bank.", i, j)
                );
            end
        end
    endgenerate

endmodule : BlockMultiBankRAM_Body
// ---- Primitives/LRU_Counter.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


import BasicTypes::*;

module LRU_Counter #( parameter WAY_NUM = 2, INDEX_BIT_WIDTH = 1, PORT_WIDTH = 1 )
(
input
    logic clk, rst,
    logic [ INDEX_BIT_WIDTH-1:0 ] index [ PORT_WIDTH ],
    logic access [ PORT_WIDTH ],
    logic [ $clog2(WAY_NUM)-1:0 ] accessWay [ PORT_WIDTH ],
output
    logic [ $clog2(WAY_NUM)-1:0 ] leastRecentlyAccessedWay [ PORT_WIDTH ]
);
    localparam ENTRY_NUM = 1 << INDEX_BIT_WIDTH;

    typedef logic unsigned [ $clog2(WAY_NUM)-1:0 ] LRU_Rank;
    typedef logic unsigned [ $clog2(PORT_WIDTH)-1:0 ] LRU_PortNum;
    typedef struct packed {
        LRU_Rank [ WAY_NUM-1:0 ] rank; // larger value means more recently accessd
    } LRU_Entry;

    LRU_Entry body [ ENTRY_NUM ];
    LRU_Entry readEntry [ PORT_WIDTH ];
    LRU_Entry writeEntry [ PORT_WIDTH ];
    
    logic we [ PORT_WIDTH ];
    
    always_comb begin
        for ( int i = 0; i < PORT_WIDTH; i++ ) begin
            // we, readEntry
            readEntry[i] = body[ index[i] ];
            we[i] = access[i];
            for ( int j = 0; j < i; j++ ) begin
                // Prevent write-conflict
                if ( we[j] == TRUE && index[i] == index[j] ) begin
                    we[i] = FALSE;
                end
            end
            
            // writeEntry
            if ( readEntry[i].rank[ accessWay[i] ] == WAY_NUM - 1 ) begin
                // It happened to access the way accessd most recently.
                for ( int j = 0; j < WAY_NUM; j++ ) begin
                    writeEntry[i].rank[j] = readEntry[i].rank[j];
                end
            end
            else begin
                for ( int j = 0; j < WAY_NUM; j++ ) begin
                    if ( j == accessWay[i] ) begin
                        writeEntry[i].rank[j] = WAY_NUM - 1;
                    end
                    else begin
                        writeEntry[i].rank[j] = ( readEntry[i].rank[j] == 0 ? 0 : readEntry[i].rank[j] - 1 );
                    end
                end
            end
        end

        // leastRecentlyAccessedWay
        for ( int i = 0; i < PORT_WIDTH; i++ ) begin
            leastRecentlyAccessedWay[i] = 0;
            for ( int j = 0; j < WAY_NUM; j++ ) begin
                if ( readEntry[i].rank[j] == 0 )
                    leastRecentlyAccessedWay[i] = j;
            end
        end
    end

    always_ff @ ( posedge clk ) begin
        if ( rst ) begin
            for ( int i = 0; i < ENTRY_NUM; i++ )
                for ( int j = 0; j < WAY_NUM; j++ )
                    body[i].rank[j] <= 0;
        end
        else begin
            for ( int i = 0; i < PORT_WIDTH; i++ )
                if ( we[i] )
                    body[ index[i] ] <= writeEntry[i];
        end
    end

endmodule
// ---- Primitives/Picker.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Pick requests.
// a.k.a. priority encoder.
//
module Picker #( 
    parameter ENTRY_NUM = 4,
    parameter GRANT_NUM = 2
)( 
input
    logic [ENTRY_NUM-1:0] req,
output
    logic [ENTRY_NUM-1:0] grant,
    logic [$clog2(ENTRY_NUM)-1:0] grantPtr[GRANT_NUM],
    logic granted[GRANT_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    
    logic [ENTRY_NUM-1:0] reqTmp;
    
    always_comb begin

        reqTmp = req;
        grant = '0;
        for (int p = 0; p < GRANT_NUM; p++) begin
            
            granted[p] = '0;
            grantPtr[p] = '0;
            
            for (int e = 0; e < ENTRY_NUM; e++) begin
                if(reqTmp[e]) begin
                    grant[e] = '1;
                    granted[p] = '1;
                    grantPtr[p] = e;
                    reqTmp[e] = '0;
                    break;
                end
            end
        end
    end
    
endmodule : Picker


//
// Requests are interleaved.
// ex. ENTRY_NUM = 4, GRANT_NUM = 2 case:
//   granted[0] = pick(req[0], req[2]);
//   granted[0] = pick(req[1], req[3]);
//
//
module InterleavedPicker #( 
    parameter ENTRY_NUM = 4,
    parameter GRANT_NUM = 2
)( 
input
    logic [ENTRY_NUM-1:0] req,
output
    logic [ENTRY_NUM-1:0] grant,
    logic [$clog2(ENTRY_NUM)-1:0] grantPtr[GRANT_NUM],
    logic granted[GRANT_NUM]
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    
    logic [ENTRY_NUM-1:0] reqTmp;
    
    always_comb begin

        reqTmp = req;
        grant = '0;
        for (int p = 0; p < GRANT_NUM; p++) begin
            
            granted[p] = '0;
            grantPtr[p] = 0;
            
            for (int e = p; e < ENTRY_NUM; e += GRANT_NUM) begin
                if(reqTmp[e]) begin
                    grant[e] = '1;
                    granted[p] = '1;
                    grantPtr[p] = e;
                    reqTmp[e] = '0;
                    break;
                end
            end
        end
    end
    
endmodule : InterleavedPicker




//
// Pick a request between a head and a tail.
// It outputs an encoded picked position.
// A request that is closer to a tail has a higher priority.
// "tailPtr" refers 1 + "the end of a valid region", thus all requests are invalid
//  if head=tail.
//

module CircularRangePicker #( 
    parameter ENTRY_NUM = 16
)( 
input
    logic [$clog2(ENTRY_NUM)-1:0] headPtr,
    logic [$clog2(ENTRY_NUM)-1:0] tailPtr,
    logic [ENTRY_NUM-1:0] request,
output
    logic [$clog2(ENTRY_NUM)-1:0] grantPtr,
    logic picked
);
    localparam INDEX_BIT_SIZE = $clog2(ENTRY_NUM);
    //localparam ENTRY_NUM = 1 << INDEX_BIT_SIZE;
    
    logic [ENTRY_NUM*2-1:0] rightShifterIn;
    logic [ENTRY_NUM-1:0] shiftedReq;
    logic [INDEX_BIT_SIZE-1:0] shiftedGrant;
    
    // Generate a right shifter.
    // When the width of a shifter is greater than 16, a hand-implemented shifter 
    // is faster than a verilog shift operator.
    generate 
        // Generate special version.
        if(ENTRY_NUM == 16) begin 
            CircularRangePickerRightShifter16 rightShifter(rightShifterIn[30:0], tailPtr, shiftedReq);
        end
        else begin
            CircularRangePickerRightShifter#(ENTRY_NUM*2, INDEX_BIT_SIZE, ENTRY_NUM) 
                rightShifter(rightShifterIn, tailPtr, shiftedReq);
        end
    endgenerate
    
    always_comb begin
        
        // Shift and move a tail to a higer position.
        //  a9876543210  a9876543210
        // <---t***h---><---t***h---> >> tp(7) => <----------t><***h------->
        // <***h---t***><***h---t***> >> tp(3) => <---***h---t><******h---->
        
        // This is equivalent to "shiftedReq = {request, request} >> tailPtr;"
        rightShifterIn = {request, request};

        // Pick the highest request.
        picked = 1'b0;
        shiftedGrant = 0;
        
        for(int i = 0; i < ENTRY_NUM; i++) begin
            if(shiftedReq[i]) begin
                shiftedGrant = i;
                picked = 1'b1;
            end
        end
        
        // Shift and restore original poistion.
        //  a9876543210  a9876543210              a9876543210  a9876543210
        // <-----------><***h-------> + tp(7) => <----***h---><----------->
        // <-----------><******h----> + tp(3) => <--------***><***h------->
        if (shiftedGrant + tailPtr < ENTRY_NUM) begin
            grantPtr = shiftedGrant + tailPtr;
        end
        else begin
            grantPtr = shiftedGrant + tailPtr - ENTRY_NUM;
        end

        //$display("t:%x, h:%x, sr:%b sg:%x, sp:%x", tailPtr, headPtr, shiftedReq, shiftedGrant, grantPtr);


        // Invalidate invalid grant.
        
        // Implementation A: it is faster than B by 1 LUT, but its area is larger 
        // than that of B by 22 LUTs.
        if(tailPtr >= headPtr) begin
            if(ENTRY_NUM + headPtr - tailPtr > shiftedGrant) begin
                picked = 1'b0;
            end
        end 
        else begin
            if(headPtr - tailPtr > shiftedGrant) begin
                picked = 1'b0;
            end
        end

        /*
        // Implementation B.
        if(tailPtr >= headPtr) begin
            if(headPtr > grantPtr || grantPtr >= tailPtr) begin
                picked = 1'b0;
            end
        end begin
            if(headPtr > grantPtr && grantPtr >= tailPtr) begin
                picked = 1'b0;
            end
        end
        */
        
    end
endmodule : CircularRangePicker


//
// --- Internal sub modules.
//

// A special version of a right shift operation for 16 entries.
module CircularRangePickerRightShifter16(
    input logic [30:0] shiftIn,
    input logic [3:0] shiftAmount,
    output logic [15:0] shiftOut
);
    logic [16*2-1:0] shiftTmp;
    always_comb begin
        shiftTmp = shiftIn;
        // A 4:1 selecter will be  mapped to 6 input LUT.
        case(shiftAmount[3:2])
            2'h3: shiftTmp = shiftTmp[30:12];
            2'h2: shiftTmp = shiftTmp[26:8];
            2'h1: shiftTmp = shiftTmp[22:4];
            //2'h0: 
            default: shiftTmp = shiftTmp[18:0];
        endcase
        case(shiftAmount[1:0])
            2'h3: shiftTmp = shiftTmp[18:3];
            2'h2: shiftTmp = shiftTmp[17:2];
            2'h1: shiftTmp = shiftTmp[16:1];
            //2'h0: 
            default: shiftTmp = shiftTmp[15:0];
        endcase
        shiftOut = shiftTmp;
    end
endmodule

// A generic version of a right shift operation.
module CircularRangePickerRightShifter #( 
    parameter INPUT_WIDTH = 32,
    parameter SHIFT_AMOUNT_WIDTH = 4,
    parameter OUTPUT_WIDTH = 16
)(
    input logic [INPUT_WIDTH-1:0] shiftIn,
    input logic [SHIFT_AMOUNT_WIDTH-1:0] shiftAmount,
    output logic [OUTPUT_WIDTH-1:0] shiftOut
);
    always_comb begin
        shiftOut = shiftIn >> shiftAmount;
    end
endmodule
// ---- Primitives/Multiplier.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Multiplier implementation.
//


// 符号付き乗算器を生成するモジュール
module Multiplier #(
    parameter BIT_WIDTH = 32
)(
    input  logic signed [   BIT_WIDTH-1:0 ] srcA,
    input  logic signed [   BIT_WIDTH-1:0 ] srcB,
    output logic signed [ 2*BIT_WIDTH-1: 0] dst
);

    assign dst = srcA * srcB;   // synthesis syn_dspstyle = "dsp48"
    
endmodule : Multiplier

module SignExtender #( 
    parameter BIT_WIDTH = 32
)(
    input  logic [   BIT_WIDTH-1:0 ] in, 
    input  logic sign,
    output logic [   BIT_WIDTH:0 ] out
);
    always_comb begin
        if (sign) begin
            out = {in[BIT_WIDTH-1], in};
        end
        else begin
            out = {1'b0, in};
        end
    end    
endmodule : SignExtender


// パイプライン化された乗算器
// PIPELINE_DEPTHは2以上でなければならない
module PipelinedMultiplier #(
    parameter BIT_WIDTH = 32,
    parameter PIPELINE_DEPTH = 3
)(
    input  logic clk, stall,
    input  logic [   BIT_WIDTH-1:0 ] srcA,
    input  logic [   BIT_WIDTH-1:0 ] srcB,
    input  logic signA,
    input  logic signB,
    output logic [ 2*BIT_WIDTH-1:0 ] dst
);
    localparam RESULT_PIPELINE_DEPTH = PIPELINE_DEPTH - 2;
    logic signed [ 2*BIT_WIDTH+1:0 ] pipeReg [RESULT_PIPELINE_DEPTH]; // synthesis syn_pipeline = 1
    logic signed [ 2*BIT_WIDTH+1:0 ] mulResult;

    logic signed [ BIT_WIDTH:0 ] exSrcA;
    logic signed [ BIT_WIDTH:0 ] exSrcB;
    logic signed [ BIT_WIDTH:0 ] exSrcA_Reg;
    logic signed [ BIT_WIDTH:0 ] exSrcB_Reg;

    SignExtender #( 
        .BIT_WIDTH(BIT_WIDTH) 
    ) signExtenderA (
        .in(srcA),
        .sign(signA),
        .out(exSrcA)
    );

    SignExtender #( 
        .BIT_WIDTH(BIT_WIDTH) 
    ) signExtenderB (
        .in(srcB),
        .sign(signB),
        .out(exSrcB)
    );

    
    `RSD_STATIC_ASSERT(
        PIPELINE_DEPTH > 2,
        "A pipeline depth of a PipelinedMultiplier module must be more than 2."
    );
    
    always_comb begin
        (* use_dsp48 = "yes" *)
        mulResult = exSrcA_Reg * exSrcB_Reg;   // synthesis syn_dspstyle = "dsp48"
        dst = pipeReg[RESULT_PIPELINE_DEPTH-1][2*BIT_WIDTH-1:0];
    end

    always_ff @(posedge clk) begin
        if (stall) begin
            exSrcA_Reg <= exSrcA_Reg;
            exSrcB_Reg <= exSrcB_Reg;
            for ( int i = 0; i < RESULT_PIPELINE_DEPTH; i++) begin
                pipeReg[i] <= pipeReg[i];
            end
        end
        else begin
            // At the first stage, only sign extension is performed,
            // because automatic pipeline synthesize may be applicable to 
            // pure multiplication operation.
            exSrcA_Reg <= exSrcA;
            exSrcB_Reg <= exSrcB;

            pipeReg[0] <= mulResult;
            for ( int i = 1; i < RESULT_PIPELINE_DEPTH; i++) begin
                pipeReg[i] <= pipeReg[i-1];
            end
        end
    end

`ifndef RSD_SYNTHESIS
    initial begin
        for ( int i = 0; i < PIPELINE_DEPTH-1; i++)
            pipeReg[i] <= '0;
    end
`endif
    
endmodule : PipelinedMultiplier
// ---- Primitives/Divider.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- Divider Unit
// This unit performs 32bit/32bit = 32bit using the nonrestoring division method
//

import BasicTypes::*;
 
module Divider(
input
    logic clk, rst,         // clock, reset
    logic req,              // request a new operation
    DataPath dividend,
    DataPath divisor,
    logic isSigned,          // operation is performed in a singed mode
output
    logic finished,
    DataPath quotient,
    DataPath remainder
);
    // 演算幅
    // 符号なしを，符号付きに拡張するので +1 する
    // 32-bit 符号なしは，33ビット符号付きの正の値とする
    parameter LOOP_COUNT = DATA_WIDTH + 1;

    // 演算はさらに +1 ビットの幅で行う
    // これは左シフト時に，符号ビットが上位に追い出されて消滅してしまうのをふせぐため
    // 1ビット余計に持っておけば，必ず符号は残る
    parameter DIVIDER_WIDTH = LOOP_COUNT + 1;
    typedef logic [DIVIDER_WIDTH-1:0] DividerPath;

    // オーバーフロー判定用定数
    parameter DATA_MINUS_ONE = (1 << DATA_WIDTH) - 1;
    parameter DATA_MINIMUM = (1 << (DATA_WIDTH - 1));


    // Internal registers
    DividerPath regZ, nextZ;  // dividend
    DividerPath regD, nextD;  // divisor
    DividerPath regQ, nextQ;  // quotient
    DividerPath regR, nextR;  // remainder
    logic regSigned, nextSigned; // signed or unsigned


    logic [$clog2(LOOP_COUNT+1)-1:0] regCounter, nextCounter;

    typedef enum logic[1:0]
    {
        PHASE_FINISHED = 0,     // Division is finished. It outputs results to quotient, remainder 
        PHASE_PROCESSING = 1,   // In processing
        PHASE_COMPENSATING = 2  // In processing for compensating results
    } Phase;
    Phase regPhase, nextPhase;

     always_ff @(posedge clk) begin
        if (rst) begin
            regZ <= 0;
            regD <= 0;
            regQ <= 0;
            regR <= 0;
            regPhase <= PHASE_FINISHED;
            regCounter <= 0;
            regSigned <= FALSE;
        end
        else begin
            regZ <= nextZ;
            regD <= nextD;
            regQ <= nextQ;
            regR <= nextR;
            regPhase <= nextPhase;
            regCounter <= nextCounter;
            regSigned <= nextSigned;
        end
     end


     always_comb begin
        finished = (regPhase == PHASE_FINISHED) ? TRUE : FALSE;

        if (req) begin
            /*
            // 入力を 64bit に符号拡張
            dividend = dividend_src | (p_sign ? ((uint64_t)0xffffffff << 32) : 0);
            dividend = dividend & op_mask;
            divisor = divisor_src | (s_divisor ? ((uint64_t)0xffffffff << 32) : 0);
            divisor = divisor & op_mask;
            */

            // A request is accepted regardless of the current phase
            if (isSigned) begin
                // Sign extend
                // 2 bits are added because DIVIDER_WIDTH = DATA_WIDTH + 2
                nextZ = dividend[DATA_WIDTH - 1] ? {2'b11, dividend} : {2'b00, dividend};
                nextD = divisor[DATA_WIDTH - 1] ? {2'b11, divisor} : {2'b00, divisor};
            end
            else begin
                nextZ = {2'b00, dividend};
                nextD = {2'b00, divisor};
            end

            /*
            uint64_t q = 0;
            uint64_t pr = p_sign ? -1 : 0;  // pr は符号拡張してうめておく
            */
            nextQ = 0;
            nextR = nextZ[DIVIDER_WIDTH-1] ? -1 : 0;   // not DATA_WIDTH-1!

            nextSigned = isSigned;
            nextPhase = PHASE_PROCESSING;
            nextCounter = 0;
        end
        else begin 
            nextZ = regZ;
            nextD = regD;
            nextQ = regQ;
            nextR = regR;
            nextSigned = regSigned;
            nextCounter = regCounter;

            // Sign
            //signZ = regZ[DATA_WIDTH - 1];
            //signD = regD[DATA_WIDTH - 1];

            if (regPhase == PHASE_PROCESSING) begin

                // 左に桁上げ
                // op_mask の幅が +1 されているのは，このとき符号ビットが消滅しないように
                // するため
                //uint64_t new_bit = ((dividend >> (dividend_length - 1 - i)) & 1);
                //pr = (pr << 1) | new_bit;
                //pr &= op_mask;
                nextR = (regR << 1) | regZ[LOOP_COUNT - 1 - regCounter];
                
                //$display("regCounter:%d, nextR[DIVIDER_WIDTH-1]:%d, regZ[DATA_WIDTH-1]:%d", regCounter, nextR[DIVIDER_WIDTH-1], regZ[DATA_WIDTH-1]);
                
                // if (s_pr != s_divisor) {
                if (nextR[DIVIDER_WIDTH-1] != regD[DIVIDER_WIDTH-1]) begin
                    nextR += regD;
                    // q <<= 1;
                    nextQ = regQ << 1;
                end
                else begin
                    nextR -= regD;
                    // q <<= 1;
                    // q |= 1;
                    nextQ = (regQ << 1) | 1;
                end

                nextCounter = regCounter + 1;
                nextPhase = (nextCounter >= LOOP_COUNT) ? PHASE_COMPENSATING : PHASE_PROCESSING;
            end
            else if (regPhase == PHASE_COMPENSATING) begin

                // -1,1 から通常のバイナリへのデコード
                nextQ = (regQ << 1) + 1;
                nextR = regR;

                //bool s_pr = ((pr >> dividend_length) & 1);
                //uint64_t result_mask = ((uint64_t)1 << (dividend_length)) - 1;
                
                if (regR[DATA_WIDTH+1-1:0] == 0) begin
                    // 余りが 0 の時は補正はいらない
                end 
                else begin
                    if (regR[DATA_WIDTH+1-1:0] == regD[DATA_WIDTH+1-1:0]) begin
                        // 余りが序数と一致した場合，戻す
                        nextR -= regD;
                        nextQ += 1;
                    end
                    else if (regR[DATA_WIDTH+1-1:0] + regD[DATA_WIDTH+1-1:0] == 0) begin
                        // 余りが序数の反転と一致した場合，戻す
                        nextR += regD;
                        nextQ -= 1;
                    end
                    else if (regZ[DATA_WIDTH+1-1] != regR[DATA_WIDTH+1-1]) begin
                        // p_sign = (dividend_src & 0x80000000);
                        // s_pr = 
                        // 序数と余りの符号が一致しない場合，補正する
                        if (regR[DATA_WIDTH+1-1] != regD[DATA_WIDTH+1-1]) begin
                            nextR += regD;
                            nextQ -= 1;
                        end
                        else begin
                            nextR -= regD;
                            nextQ += 1;
                        end
                    end

                    // Results on division by zero or overflow are difined by 
                    // RISC-V specification.
                    if (regD == 0) begin
                        // Division by zero
                        nextQ = -1;
                        nextR = regZ;
                    end
                    else if (regSigned && regZ == DATA_MINIMUM && regD == DATA_MINUS_ONE) begin 
                        // Sigined division can cause overflow
                        // ex. 8 bits signed division "-0x80 / -1 = 0x80"
                        // causes overflow because the resulst 0x80 > 0x7f
                        nextQ = regZ;
                        nextR = 0;
                    end
                end
                nextPhase = PHASE_FINISHED;
            end
            else begin  // PHASE_FINISHED
                nextPhase = regPhase;
            end
        end

        // Output results
        quotient = regQ;
        remainder = regR;

     end

endmodule : Divider


module QuickDivider(
input
    logic clk, rst,         // clock, reset
    logic req,              // request a new operation
    DataPath dividend,
    DataPath divisor,
    logic isSigned,          // operation is performed in a singed mode
output
    logic finished,
    DataPath quotient,
    DataPath remainder
);


    // 演算幅
    // 符号なしを，符号付きに拡張するので +1 する
    // 32-bit 符号なしは，33-bit 符号付きの正の値とする
    parameter DIVIDER_WIDTH = DATA_WIDTH + 1;
    typedef logic [DIVIDER_WIDTH-1:0] DividerPath;

    function automatic logic [$clog2(DIVIDER_WIDTH+1)-1:0] CountSignificantBits(
    input
        DividerPath dividend
    );
        // 1 <= CountSignificantBits <= 33

        // CountSignificantBits == 1 if dividend == 0 or dividend == -1
        CountSignificantBits = 1;
        for (int i = DIVIDER_WIDTH-2; i >= 0; --i) begin
            if (dividend[DIVIDER_WIDTH-1] != dividend[i]) begin
                CountSignificantBits = i + 2;
                break;
            end
        end

    endfunction

    // 商の最大ビット数
    parameter MAX_LOOP_COUNT = DATA_WIDTH + 1;

    // オーバーフロー判定用定数
    parameter DATA_MINUS_ONE = (1 << DATA_WIDTH) - 1;
    parameter DATA_MINIMUM = (1 << (DATA_WIDTH - 1));


    // Internal registers
    DividerPath regZ, nextZ;  // dividend
    DividerPath regD, nextD;  // divisor
    DividerPath regQ, nextQ;  // quotient
    DividerPath regR, nextR;  // remainder
    logic regSigned, nextSigned; // signed or unsigned


    logic [$clog2(MAX_LOOP_COUNT+1)-1:0] regCounter, nextCounter;

    typedef enum logic[1:0]
    {
        PHASE_FINISHED = 0,     // Division is finished. It outputs results to quotient, remainder 
        PHASE_FIRSTBIT = 1,     // In processing first bit
        PHASE_PROCESSING = 2,   // In processing
        PHASE_COMPENSATING = 3  // In processing for compensating results
    } Phase;
    Phase regPhase, nextPhase;

    always_ff @(posedge clk) begin
        if (rst) begin
            regZ <= 0;
            regD <= 0;
            regQ <= 0;
            regR <= 0;
            regPhase <= PHASE_FINISHED;
            regCounter <= 0;
            regSigned <= FALSE;
        end
        else begin
            regZ <= nextZ;
            regD <= nextD;
            regQ <= nextQ;
            regR <= nextR;
            regPhase <= nextPhase;
            regCounter <= nextCounter;
            regSigned <= nextSigned;
        end
    end


    always_comb begin
        finished = (regPhase == PHASE_FINISHED) ? TRUE : FALSE;

        if (req) begin
            // 入力を演算幅である 33-bit 符号付き整数に変換

            // A request is accepted regardless of the current phase
            if (isSigned) begin
                // Sign extend
                // 1 bits are added because DIVIDER_WIDTH = DATA_WIDTH + 1
                nextZ = dividend[DATA_WIDTH - 1] ? {1'b1, dividend} : {1'b0, dividend};
                nextD = divisor[DATA_WIDTH - 1] ? {1'b1, divisor} : {1'b0, divisor};
            end
            else begin
                nextZ = {1'b0, dividend};
                nextD = {1'b0, divisor};
            end

            // nextQ は次のサイクルで埋められるので↓は意味なし
            nextQ = 0;
            // nextR は符号拡張して埋めておく
            nextR = nextZ[DIVIDER_WIDTH-1] ? -1 : 0;

            nextSigned = isSigned;
            nextPhase = PHASE_FIRSTBIT;
            // 被除数の絶対値が小さいとき 32+α サイクルも計算する必要はない
            // 商の立ち方は -1 を T と書くことにして
            // その場合商が正の時 1TTTTTT... 商が負の時 T111111... となる
            // 先頭の 0 を許せば  000001T...            000001T というような
            // 商を立てることができ，無駄を省くことができる
            // 除数のことを考慮せず，保守的に0でない商が立つビット幅を求める
            // （除数の絶対値が大きい場合は，商の長さをさらに短くできる）
            // 商は最大でも CountSiginificatntBits(nextZ) ビットで表せる
            nextCounter = CountSignificantBits(nextZ);
        end
        else begin 
            nextZ = regZ;
            nextD = regD;
            nextQ = regQ;
            nextR = regR;
            nextSigned = regSigned;
            nextCounter = regCounter;

            // Sign
            //signZ = regZ[DATA_WIDTH - 1];
            //signD = regD[DATA_WIDTH - 1];

            if (regPhase == PHASE_FIRSTBIT) begin

                // 左に桁上げ
                nextR = (regR << 1) | regZ[regCounter - 1];

                if (regR[DIVIDER_WIDTH-1] != regD[DIVIDER_WIDTH-1]) begin
                    nextR += regD;
                    // 実際に立つ商は T だが，最上位ビットは追い出し，
                    // 最終的な結果に表れないようにしている
                    // ただし商の符号を決めるために使われる
                    // 補正前商の先頭が T ということはデコード後は負の値
                    // よって符号拡張を見越して事前に埋めておく
                    nextQ = -1;
                end
                else begin
                    nextR -= regD;
                    // 実際に立つ商は 1 でありそれ以外は同上
                    // 補正前商の先頭が 1 ということはデコード後は正の値
                    nextQ = 0;
                end

                nextCounter = regCounter - 1;
                nextPhase = (nextCounter == 0) ? PHASE_COMPENSATING : PHASE_PROCESSING;
            end
            else if (regPhase == PHASE_PROCESSING) begin

                // 左に桁上げ
                nextR = (regR << 1) | regZ[regCounter - 1];
                
                //$display("regCounter:%d, nextR[DIVIDER_WIDTH-1]:%d, regZ[DATA_WIDTH-1]:%d", regCounter, nextR[DIVIDER_WIDTH-1], regZ[DATA_WIDTH-1]);
                
                // signR = regR[DIVIDER_WIDTH-1]
                // 桁上げしたものではなく元の値を参照することで
                // 符号ビットが追い出される問題が発生しなくなる
                if (regR[DIVIDER_WIDTH-1] != regD[DIVIDER_WIDTH-1]) begin
                    nextR += regD;
                    // q <<= 1;
                    nextQ = regQ << 1;
                end
                else begin
                    nextR -= regD;
                    // q <<= 1;
                    // q |= 1;
                    nextQ = (regQ << 1) | 1;
                end

                nextCounter = regCounter - 1;
                nextPhase = (nextCounter == 0) ? PHASE_COMPENSATING : PHASE_PROCESSING;
            end
            else if (regPhase == PHASE_COMPENSATING) begin

                // -1(T),1 から通常のバイナリへのデコード
                // q の中では T は 0，1 は 1 として表現されている
                // 前者の寄与は-(~q) ，後者の寄与は q
                // 足し合わせると q + (-(~q)) == q + (q+1)
                // よって以下の式になる
                nextQ = (regQ << 1) + 1;
                nextR = regR;

                // 補正前商は最近接丸めで奇数に丸めた商
                // * 真の商が偶数の時，補正が必要
                // * 余りがある場合，ゼロへの丸めになるよう補正が必要
                if (regR == 0) begin
                    // 余りが 0 の時は補正はいらない
                end 
                else begin
                    if (regR == regD) begin
                        // 余りが除数と一致した場合，戻す
                        // 割り切れて真の商が偶数かつ除数が負の時に発生
                        nextR -= regD;
                        nextQ += 1;
                    end
                    else if (regR == -regD) begin
                        // 余りが除数の反転と一致した場合，戻す
                        // 割り切れて真の商が偶数かつ除数が正の時に発生
                        nextR += regD;
                        nextQ -= 1;
                    end
                    else if (regR[DIVIDER_WIDTH-1] != regZ[DIVIDER_WIDTH-1]) begin
                        // 除数と余りの符号が一致しない場合，補正する
                        if (regR[DIVIDER_WIDTH-1] != regD[DIVIDER_WIDTH-1]) begin
                            nextR += regD;
                            nextQ -= 1;
                        end
                        else begin
                            nextR -= regD;
                            nextQ += 1;
                        end
                    end
                end

                // Results on division by zero or overflow are difined by 
                // RISC-V specification.
                if (regD == 0) begin
                    // Division by zero
                    nextQ = -1;
                    nextR = regZ;
                end
                else if (regSigned && regZ == DATA_MINIMUM && regD == DATA_MINUS_ONE) begin 
                    // Sigined division can cause overflow
                    // ex. 8 bits signed division "-0x80 / -1 = 0x80"
                    // causes overflow because the resulst 0x80 > 0x7f
                    nextQ = regZ;
                    nextR = 0;
                end

                nextPhase = PHASE_FINISHED;
            end
            else begin  // PHASE_FINISHED
                nextPhase = regPhase;
            end
        end

        // Output results
        quotient = regQ;
        remainder = regR;

    end

endmodule : QuickDivider
// ---- Debug/Debug.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Debug
//

import BasicTypes::*;
import MemoryMapTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import LoadStoreUnitTypes::*;
import PipelineTypes::*;
import DebugTypes::*;

module Debug (
    DebugIF.Debug port,
    output PC_Path lastCommittedPC
);

`ifndef RSD_DISABLE_DEBUG_REGISTER
    DebugRegister next;
    
    always_comb begin
        // Signal from each stage
        for ( int i = 0; i < FETCH_WIDTH; i++ ) begin
            next.npReg[i] = port.npReg[i];
            next.ifReg[i] = port.ifReg[i];
        end
        for ( int i = 0; i < DECODE_WIDTH; i++ ) begin
            next.idReg[i] = port.idReg[i];
        end
        for ( int i = 0; i < DECODE_WIDTH; i++ ) begin
            next.pdReg[i] = port.pdReg[i];
        end
        for ( int i = 0; i < RENAME_WIDTH; i++ ) begin
            next.rnReg[i] = port.rnReg[i];
        end
        for ( int i = 0; i < DISPATCH_WIDTH; i++ ) begin
            next.dsReg[i] = port.dsReg[i];
        end
        for ( int i = 0; i < INT_ISSUE_WIDTH; i++ ) begin
            next.intIsReg[i] = port.intIsReg[i];
            next.intRrReg[i] = port.intRrReg[i];
            next.intExReg[i] = port.intExReg[i];
            next.intRwReg[i] = port.intRwReg[i];
        end

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        for ( int i = 0; i < COMPLEX_ISSUE_WIDTH; i++ ) begin
            next.complexIsReg[i] = port.complexIsReg[i];
            next.complexRrReg[i] = port.complexRrReg[i];
            next.complexExReg[i] = port.complexExReg[i];
            next.complexRwReg[i] = port.complexRwReg[i];
        end
`endif
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            next.memIsReg[i] = port.memIsReg[i];
            next.memRrReg[i] = port.memRrReg[i];
            next.memExReg[i] = port.memExReg[i];
            next.maReg[i] = port.maReg[i];
            next.mtReg[i] = port.mtReg[i];
            next.memRwReg[i] = port.memRwReg[i];
        end
        for ( int i = 0; i < COMMIT_WIDTH; i++ ) begin
            next.cmReg[i] = port.cmReg[i];
        end
        
        for ( int i = 0; i < ISSUE_QUEUE_ENTRY_NUM; i++ ) begin
            next.scheduler[i]  = port.scheduler[i];
            next.issueQueue[i] = port.issueQueue[i];
        end

        next.toRecoveryPhase = port.toRecoveryPhase;
        next.activeListHeadPtr = port.activeListHeadPtr;
        next.activeListCount = port.activeListCount;
        
        // PipelineControl
        next.npStagePipeCtrl = port.npStagePipeCtrl;
        next.ifStagePipeCtrl = port.ifStagePipeCtrl;
        next.pdStagePipeCtrl = port.pdStagePipeCtrl;
        next.idStagePipeCtrl = port.idStagePipeCtrl;
        next.rnStagePipeCtrl = port.rnStagePipeCtrl;
        next.dsStagePipeCtrl = port.dsStagePipeCtrl;
        next.backEndPipeCtrl = port.backEndPipeCtrl;
        next.cmStagePipeCtrl = port.cmStagePipeCtrl;
        next.stallByDecodeStage = port.stallByDecodeStage;
        
        // last committed PC
        lastCommittedPC = port.lastCommittedPC;
        
        // Others
        next.loadStoreUnitAllocatable = port.loadStoreUnitAllocatable;
        next.storeCommitterPhase = port.storeCommitterPhase;
        next.storeQueueCount = port.storeQueueCount;
        next.busyInRecovery = port.busyInRecovery;
        next.storeQueueEmpty = port.storeQueueEmpty;
    end

    DebugRegister debugRegister;
    always_ff @(posedge port.clk) begin
        debugRegister <= next;
    end
    
    always_comb begin
        port.debugRegister = debugRegister;
    end
`else
    always_comb begin
        port.debugRegister = FALSE; // Suppresing warning.
    end
`endif
endmodule : Debug
// ---- Debug/DebugIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- DebugIF
//

import BasicTypes::*;
import MemoryMapTypes::*;
import DebugTypes::*;
import RenameLogicTypes::*;
import SchedulerTypes::*;
import LoadStoreUnitTypes::*;
import PipelineTypes::*;

interface DebugIF( input logic clk, rst );
    
`ifndef RSD_DISABLE_DEBUG_REGISTER
    // Mainモジュール外部へ出力する信号群
    DebugRegister debugRegister;
    
    // debugRegisterの入力となる信号群
    // 各ステージからデータを集める
    NextPCStageDebugRegister npReg [ FETCH_WIDTH ];
    FetchStageDebugRegister   ifReg [ FETCH_WIDTH ];
    PreDecodeStageDebugRegister pdReg [ DECODE_WIDTH ];
    DecodeStageDebugRegister    idReg [ DECODE_WIDTH ];
    RenameStageDebugRegister    rnReg [ RENAME_WIDTH ];
    DispatchStageDebugRegister  dsReg [ DISPATCH_WIDTH ];
    
    IntegerIssueStageDebugRegister         intIsReg [ INT_ISSUE_WIDTH ];
    IntegerRegisterReadStageDebugRegister  intRrReg [ INT_ISSUE_WIDTH ];
    IntegerExecutionStageDebugRegister     intExReg [ INT_ISSUE_WIDTH ];
    IntegerRegisterWriteStageDebugRegister intRwReg [ INT_ISSUE_WIDTH ];

`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    ComplexIntegerIssueStageDebugRegister         complexIsReg [ COMPLEX_ISSUE_WIDTH ];
    ComplexIntegerRegisterReadStageDebugRegister  complexRrReg [ COMPLEX_ISSUE_WIDTH ];
    ComplexIntegerExecutionStageDebugRegister     complexExReg [ COMPLEX_ISSUE_WIDTH ];
    ComplexIntegerRegisterWriteStageDebugRegister complexRwReg [ COMPLEX_ISSUE_WIDTH ];
`endif

    MemoryIssueStageDebugRegister          memIsReg [ MEM_ISSUE_WIDTH ];
    MemoryRegisterReadStageDebugRegister   memRrReg [ MEM_ISSUE_WIDTH ];
    MemoryExecutionStageDebugRegister      memExReg [ MEM_ISSUE_WIDTH ];
    MemoryTagAccessStageDebugRegister      mtReg    [ MEM_ISSUE_WIDTH ];
    MemoryAccessStageDebugRegister         maReg    [ MEM_ISSUE_WIDTH ];
    MemoryRegisterWriteStageDebugRegister  memRwReg [ MEM_ISSUE_WIDTH ];

    CommitStageDebugRegister cmReg [ COMMIT_WIDTH ];

    SchedulerDebugRegister  scheduler [ ISSUE_QUEUE_ENTRY_NUM ];
    IssueQueueDebugRegister issueQueue [ ISSUE_QUEUE_ENTRY_NUM ];

    PC_Path lastCommittedPC;
    logic recover, toRecoveryPhase;
    ActiveListIndexPath activeListHeadPtr;
    ActiveListCountPath activeListCount;
    
    // debugRegisterの入力となる信号群
    // パイプラインコントローラからデータを集める
    PipelineControll npStagePipeCtrl;
    PipelineControll ifStagePipeCtrl;
    PipelineControll pdStagePipeCtrl;
    PipelineControll idStagePipeCtrl;
    PipelineControll rnStagePipeCtrl;
    PipelineControll dsStagePipeCtrl;
    PipelineControll backEndPipeCtrl;
    PipelineControll cmStagePipeCtrl;
    logic stallByDecodeStage;

    logic loadStoreUnitAllocatable;
    logic storeCommitterPhase;
    StoreQueueCountPath storeQueueCount;
    logic busyInRecovery;
    logic storeQueueEmpty;

    modport Debug (
    input 
        clk,
        rst,
        npReg,
        ifReg,
        pdReg,
        idReg,
        rnReg,
        dsReg,
        intIsReg,
        intRrReg,
        intExReg,
        intRwReg,
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
        complexIsReg,
        complexRrReg,
        complexExReg,
        complexRwReg,
`endif
        memIsReg,
        memRrReg,
        memExReg,
        maReg,
        mtReg,
        memRwReg,
        cmReg,
        scheduler,
        issueQueue,
        recover,
        toRecoveryPhase,
        activeListHeadPtr,
        activeListCount,
        lastCommittedPC,
        npStagePipeCtrl,
        ifStagePipeCtrl,
        pdStagePipeCtrl,
        idStagePipeCtrl,
        rnStagePipeCtrl,
        dsStagePipeCtrl,
        backEndPipeCtrl,
        cmStagePipeCtrl,
        stallByDecodeStage,
        loadStoreUnitAllocatable,
        storeCommitterPhase,
        storeQueueCount,
        busyInRecovery,
        storeQueueEmpty,
    output
        debugRegister
    );
    
    modport StoreCommitter (
    output
        loadStoreUnitAllocatable,
        storeCommitterPhase,
        storeQueueCount,
        busyInRecovery,
        storeQueueEmpty
    );
    
    modport Controller (
    output
        npStagePipeCtrl,
        ifStagePipeCtrl,
        pdStagePipeCtrl,
        idStagePipeCtrl,
        rnStagePipeCtrl,
        dsStagePipeCtrl,
        backEndPipeCtrl,
        cmStagePipeCtrl,
        stallByDecodeStage
    );
    
    modport ActiveList (
    output
        activeListHeadPtr,
        activeListCount
    );
    
    modport Scheduler (
    output
        scheduler
    );
    
    modport IssueQueue (
    output
        issueQueue
    );

    modport NextPCStage (
    output
        npReg
    );

    modport FetchStage (
    output
        ifReg
    );

    modport PreDecodeStage (
    output
        pdReg
    );

    modport DecodeStage (
    output
        idReg
    );
    
    modport RenameStage (
    output
        rnReg
    );

    modport DispatchStage (
    output
        dsReg
    );
    
    modport IntegerIssueStage (
    output
        intIsReg
    );
    
    modport IntegerRegisterReadStage (
    output
        intRrReg
    );
    
    modport IntegerExecutionStage (
    output
        intExReg
    );
    
    modport IntegerRegisterWriteStage (
    output
        intRwReg
    );
    
`ifndef RSD_MARCH_UNIFIED_MULDIV_MEM_PIPE
    modport ComplexIntegerIssueStage (
    output
        complexIsReg
    );
    
    modport ComplexIntegerRegisterReadStage (
    output
        complexRrReg
    );
    
    modport ComplexIntegerExecutionStage (
    output
        complexExReg
    );
    
    modport ComplexIntegerRegisterWriteStage (
    output
        complexRwReg
    );
`endif
    
    modport MemoryIssueStage (
    output
        memIsReg
    );
    
    modport MemoryRegisterReadStage (
    output
        memRrReg
    );
    
    modport MemoryExecutionStage (
    output
        memExReg
    );
    
    modport MemoryTagAccessStage (
    output
        mtReg
    );

    modport MemoryAccessStage (
    output
        maReg
    );
    
    modport MemoryRegisterWriteStage (
    output
        memRwReg
    );

    modport CommitStage (
    output
        lastCommittedPC,
        recover,
        toRecoveryPhase,
        cmReg
    );
    
`else

    // When debug signals are disabled.
    PC_Path lastCommittedPC;
    DebugRegister debugRegister;
    
    modport Debug (
        input clk, lastCommittedPC,
        output debugRegister
        
    );
    
    modport StoreCommitter (
        input clk
    );
    
    modport Controller (
        input clk
    );
    
    modport ActiveList (
        input clk
    );
    
    modport Scheduler (
        input clk
    );
    
    modport IssueQueue (
        input clk
    );
    
    modport FetchStage (
        input clk
    );

    modport NextPCStage (
        input clk
    );

    modport PreDecodeStage (
        input clk
    );

    modport DecodeStage (
        input clk
    );
    
    modport RenameStage (
        input clk
    );

    modport DispatchStage (
        input clk
    );
    
    modport IntegerIssueStage (
        input clk
    );
    
    modport IntegerRegisterReadStage (
        input clk
    );
    
    modport IntegerExecutionStage (
        input clk
    );
    
    modport IntegerRegisterWriteStage (
        input clk
    );
    
    modport ComplexIntegerIssueStage (
        input clk
    );
    
    modport ComplexIntegerRegisterReadStage (
        input clk
    );
    
    modport ComplexIntegerExecutionStage (
        input clk
    );
    
    modport ComplexIntegerRegisterWriteStage (
        input clk
    );
    
    modport MemoryIssueStage (
        input clk
    );
    
    modport MemoryRegisterReadStage (
        input clk
    );
    
    modport MemoryExecutionStage (
        input clk
    );
    
    modport MemoryTagAccessStage (
        input clk
    );
    modport MemoryAccessStage (
        input clk
    );
    
    modport MemoryRegisterWriteStage (
        input clk
    );

    modport CommitStage (
        input clk,
        output lastCommittedPC
    );
`endif


endinterface : DebugIF
// ---- Debug/HardwareCounter.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// HardwareCounter
// 実行サイクル数など、性能を解析する上で必要な値をカウントするモジュール
//

import BasicTypes::*;
import DebugTypes::*;

//
// 面積削減のため、実行サイクル数のカウントだけやるモジュール
//
module SimpleHardwareCounter (
    HardwareCounterIF.HardwareCounter port
);
`ifndef RSD_DISABLE_HARDWARE_COUNTER
    // リセットが解除されてからのサイクル数
    DataPath countCycle;
    
    always_ff @(posedge port.clk) begin
        if ( port.rst ) begin
            countCycle <= 0;
        end
        else begin
            countCycle <= countCycle + 1;
        end
    end

    // データの出力
    always_comb begin
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            port.hardwareCounterData[i] = countCycle;
        end
    end
`else
    always_comb begin
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            port.hardwareCounterData[i] = 0; // Suppresing warning.
        end
    end
`endif
endmodule : SimpleHardwareCounter

//
// すべてのHWカウンタを持つモジュール
//
module HardwareCounter (
    HardwareCounterIF.HardwareCounter port
);
`ifndef RSD_DISABLE_HARDWARE_COUNTER
    // リセットが解除されてからのサイクル数
    DataPath countCycle;
    
    // ロードがDキャッシュにミスした回数
    DataPath countLoadMiss, nextCountLoadMiss;
    
    // コミット関係
    DataPath countCommit;
    DataPath countRefetchThisPC;
    DataPath countRefetchNextPC;
    DataPath countRefetchBrTarget;
    
    always_ff @(posedge port.clk) begin
        if ( port.rst ) begin
            countCycle <= 0;
            countCommit <= 0;
            countRefetchThisPC <= 0;
            countRefetchNextPC <= 0;
            countRefetchBrTarget <= 0;
            countLoadMiss <= 0;
        end
        else begin
            countCycle <= countCycle + 1;
            countCommit <= countCommit + port.commitNum;
            countRefetchThisPC <=
                countRefetchThisPC + ( port.refetchThisPC ? 1 : 0 );
            countRefetchNextPC <=
                countRefetchNextPC + ( port.refetchNextPC ? 1 : 0 );
            countRefetchBrTarget <=
                countRefetchBrTarget + ( port.refetchBrTarget ? 1 : 0 );
            countLoadMiss <= nextCountLoadMiss;
        end
    end
    
    // 面倒なカウント
    always_comb begin
        nextCountLoadMiss = countLoadMiss;
        for ( int i = 0; i < MEM_ISSUE_WIDTH; i++ ) begin
            if ( port.loadMiss[i] )
                nextCountLoadMiss++;
        end
    end
    
    // データの出力
    DataPath hardwareCounterData[ LOAD_ISSUE_WIDTH ];
    always_comb begin
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            case ( port.hardwareCounterType[i] )
            default:
                port.hardwareCounterData[i] = 0;
            HW_CNT_TYPE_CYCLE:
                port.hardwareCounterData[i] = countCycle;
            HW_CNT_TYPE_COMMIT:
                port.hardwareCounterData[i] = countCommit;
            HW_CNT_TYPE_REFETCH_THIS_PC:
                port.hardwareCounterData[i] = countRefetchThisPC;
            HW_CNT_TYPE_REFETCH_NEXT_PC:
                port.hardwareCounterData[i] = countRefetchNextPC;
            HW_CNT_TYPE_REFETCH_BR_TARGET:
                port.hardwareCounterData[i] = countRefetchBrTarget;
            HW_CNT_TYPE_LOAD_MISS:
                port.hardwareCounterData[i] = countLoadMiss;
            endcase
        end

        port.hardwareCounterData = hardwareCounterData;
    end
`else
    always_comb begin
        for ( int i = 0; i < LOAD_ISSUE_WIDTH; i++ ) begin
            port.hardwareCounterData[i] = 0; // Suppresing warning.
        end
    end
`endif
endmodule : HardwareCounter
// ---- Debug/HardwareCounterIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// --- HardwareCounterIF
//

import BasicTypes::*;
import DebugTypes::*;

interface HardwareCounterIF( input logic clk, rst );
    
`ifndef RSD_DISABLE_HARDWARE_COUNTER
    // LoadStoreUnitでハードウェアカウンタを読み出す際の信号線
    HardwareCounterType hardwareCounterType[ LOAD_ISSUE_WIDTH ];
    DataPath hardwareCounterData[ LOAD_ISSUE_WIDTH ];
    
    // ロードがDキャッシュミスしたかどうか
    logic loadMiss[ MEM_ISSUE_WIDTH ];
    
    // コミット関係
    CommitLaneCountPath commitNum;
    logic refetchThisPC;
    logic refetchNextPC;
    logic refetchBrTarget;
    
    modport HardwareCounter (
    input
        clk,
        rst,
        loadMiss,
        commitNum,
        refetchThisPC,
        refetchNextPC,
        refetchBrTarget,
        hardwareCounterType,
    output
        hardwareCounterData
    );
    
    modport LoadStoreUnit (
    input
        hardwareCounterData,
    output
        hardwareCounterType
    );
    
    modport MemoryTagAccessStage (
    output
        loadMiss
    );
    
    modport CommitStage (
    output
        commitNum,
        refetchThisPC,
        refetchNextPC,
        refetchBrTarget
    );
`else
    // Dummy to surpress warning.
    DataPath hardwareCounterData[ LOAD_ISSUE_WIDTH ];

    modport HardwareCounter (
    input
        clk,
    output
        hardwareCounterData
    );
    
    modport LoadStoreUnit (
        input clk
    );
    
    modport MemoryTagAccessStage (
        input clk
    );

    modport CommitStage (
        input clk
    );
`endif


endinterface : HardwareCounterIF
// ---- Memory/ControlQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// ControlQueue
//

import BasicTypes::*;
import MemoryTypes::*;

module ControlQueue ( 
input 
    logic clk,
    logic rst,
    logic push,
    logic pop,
    logic [ PS_PL_CTRL_QUEUE_DATA_BIT_SIZE-1:0 ] pushedData,
output
    logic full,
    logic empty,
    logic [ PS_PL_CTRL_QUEUE_DATA_BIT_SIZE-1:0 ] headData
);

    typedef logic [PS_PL_CTRL_QUEUE_ADDR_BIT_SIZE-1:0] IndexPath;

    IndexPath headPtr;
    IndexPath tailPtr;

    // size, initial head, initial tail, initial count
    QueuePointer #( PS_PL_CTRL_QUEUE_SIZE, 0, 0, 0 )
        pointer(
            .clk( clk ),
            .rst( rst ),
            .push( push ),
            .pop( pop ),
            .full( full ),
            .empty( empty ),
            .headPtr( headPtr ),
            .tailPtr( tailPtr )
        );
        

    logic [ PS_PL_CTRL_QUEUE_DATA_BIT_SIZE-1:0 ] controlQueue[ PS_PL_CTRL_QUEUE_SIZE ]; // synthesis syn_ramstyle = "select_ram"

    always_ff @( posedge clk ) begin
        if( push ) begin
            controlQueue[ tailPtr ] <= pushedData;
        end
    end
    
    always_comb begin
        headData = controlQueue[ headPtr ];
    end

endmodule : ControlQueue

 
// ---- Memory/Axi4Memory.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.




import BasicTypes::*;
import MemoryTypes::*;
import CacheSystemTypes::*;

module Axi4Memory
(
Axi4MemoryIF.Axi4 port,
input
    AddrPath memAccessAddr,
    MemoryEntryDataPath memAccessWriteData,
    logic memAccessRE,
    logic memAccessWE,
output
    logic memAccessReadBusy,    // メモリリードアクセス要求を受け付けられない
    logic memAccessWriteBusy,    // メモリライトアクセス要求を受け付けられない
    MemAccessSerial nextMemReadSerial, // RSDの次の読み出し要求に割り当てられるシリアル(id)
    MemWriteSerial nextMemWriteSerial, // RSDの次の書き込み要求に割り当てられるシリアル(id)
    logic memReadDataReady, // TRUEなら、メモリの読出しデータあり
    MemoryEntryDataPath memReadData, // メモリの読出しデータ
    MemAccessSerial memReadSerial, // メモリの読み出しデータのシリアル
    MemAccessResponse memAccessResponse // メモリ書き込み完了通知
);

    // RD/WR addr must be buffered for the correct operation.
    logic [MEMORY_AXI4_ADDR_BIT_SIZE-1:0] next_addr;

    always_ff @(posedge port.M_AXI_ACLK) begin
        if (port.M_AXI_ARESETN == 0) begin
            next_addr <= '0;
        end
        else begin
            next_addr <= memAccessAddr[MEMORY_AXI4_ADDR_BIT_SIZE-1:0];
        end
    end

    // function called clogb2 that returns an integer which has the
    //value of the ceiling of the log base 2

      // function called clogb2 that returns an integer which has the 
      // value of the ceiling of the log base 2.                      
      function automatic integer clogb2 (input integer bit_depth);              
      begin                                                           
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
          bit_depth = bit_depth >> 1;                                 
        end                                                           
      endfunction                                                     

    // C_TRANSACTIONS_NUM is the width of the index counter for 
    // number of write or read transaction.
     localparam integer C_TRANSACTIONS_NUM = clogb2(MEMORY_AXI4_BURST_LEN-1);

    // Burst length for transactions, in MEMORY_AXI4_DATA_BIT_NUMs.
    // Non-2^n lengths will eventually cause bursts across 4K address boundaries.
     localparam integer C_MASTER_LENGTH    = 12;
    // total number of burst transfers is master length divided by burst length and burst size
     localparam integer C_NO_BURSTS_REQ = C_MASTER_LENGTH-clogb2((MEMORY_AXI4_BURST_LEN*MEMORY_AXI4_DATA_BIT_NUM/8)-1);
    // Example State machine to initialize counter, initialize write transactions, 
    // initialize read transactions and comparison of read data with the 
    // written data words.
    parameter [1:0] IDLE = 2'b00, // This state initiates AXI4Lite transaction 
            // after the state machine changes state to INIT_WRITE 
            // when there is 0 to 1 transition on INIT_AXI_TXN
        INIT_WRITE   = 2'b01, // This state initializes write transaction,
            // once writes are done, the state machine 
            // changes state to INIT_READ 
        INIT_READ = 2'b10, // This state initializes read transaction
            // once reads are done, the state machine 
            // changes state to INIT_COMPARE 
        INIT_COMPARE = 2'b11; // This state issues the status of comparison 
            // of the written data with the read data    

     reg [1:0] mst_exec_state;

    // AXI4LITE signals
    //AXI4 internal temp signals
    // reg [MEMORY_AXI4_ADDR_BIT_SIZE-1 : 0]     axi_awaddr;
    logic [MEMORY_AXI4_ADDR_BIT_SIZE-1 : 0]     axi_awaddr;
    // reg      axi_awvalid;
    logic axi_awvalid;
    //reg [MEMORY_AXI4_DATA_BIT_NUM-1 : 0]     axi_wdata;
    logic [MEMORY_AXI4_DATA_BIT_NUM-1 : 0]     axi_wdata;
    reg      axi_wlast;
    reg      axi_wvalid;
    reg      axi_bready;
    //reg [MEMORY_AXI4_ADDR_BIT_SIZE-1 : 0]     axi_araddr;
    logic [MEMORY_AXI4_ADDR_BIT_SIZE-1 : 0]     axi_araddr;
    reg      axi_arvalid;
    reg      axi_rready;
    //write beat count in a burst
    reg [C_TRANSACTIONS_NUM : 0]     write_index;
    //read beat count in a burst
    reg [C_TRANSACTIONS_NUM : 0]     read_index;
    //size of MEMORY_AXI4_BURST_LEN length burst in bytes
    wire [C_TRANSACTIONS_NUM+2 : 0]     burst_size_bytes;
    //The burst counters are used to track the number of burst transfers of MEMORY_AXI4_BURST_LEN burst length needed to transfer 2^C_MASTER_LENGTH bytes of data.
    reg [C_NO_BURSTS_REQ : 0]     write_burst_counter;
    reg [C_NO_BURSTS_REQ : 0]     read_burst_counter;
    reg      start_single_burst_write;
    reg      start_single_burst_read;
    reg      writes_done;
    reg      reads_done;
    reg      error_reg;
    // reg      compare_done;
    reg      read_mismatch;
    reg      burst_write_active;
    reg      burst_read_active;
    reg [MEMORY_AXI4_DATA_BIT_NUM-1 : 0]     expected_rdata;
    //Interface response error flags
    wire      write_resp_error;
    wire      read_resp_error;
    wire      wnext;
    wire      rnext;
    reg      init_txn_ff;
    reg      init_txn_ff2;
    reg      init_txn_edge;
    wire      init_txn_pulse;

//
// --- memoryReadReqIDFreeList
//
    // Readリクエストのための定義
    // 1なら使用済みreadReqIDをpushする
    logic pushFreeReadReqID;
    logic [MEMORY_AXI4_READ_ID_WIDTH-1: 0] pushedFreeReadReqID;
    // 1ならフリーのreadReqIDをpopする
    logic popFreeReadReqID;
    logic [MEMORY_AXI4_READ_ID_WIDTH-1: 0] popedFreeReadReqID;
    // 1ならmemoryReadReqIDFreeListがfull
    logic readReqIDFreeListFull;
    // 1ならmemoryReadReqIDFreeListが空
    logic readReqIDFreeListEmpty;

    // memoryReadReqQueueにpushするmemoryReadReq
    MemoryReadReq pushedMemoryReadReq;
    // 1ならmemoryReadReqQueueにpushする
    logic pushMemoryReadReq;
    // 1ならmemoryReadReqQueueからpopする
    logic popMemoryReadReq;
    // 1ならmemoryReadReqQueueがfull
    logic memoryReadReqQueueFull;
    // 1ならmemoryReadReqQueueが空
    logic memoryReadReqQueueEmpty;
    // memoryReadReqQueueの先頭にあるmemoryReadReq
    MemoryReadReq popedMemoryReadReq;

    //
    MemoryEntryDataPath nextMemoryReadData;
    logic memoryReadDataTableWE;
    logic [MEMORY_AXI4_READ_ID_WIDTH-1: 0] memoryReadDataID;
    MemoryEntryDataPath memoryReadData;
    

//
// --- memoryReadReqIDFreeList
//
    FreeList #(
        .SIZE(MEMORY_AXI4_READ_ID_NUM),
        .ENTRY_WIDTH(MEMORY_AXI4_READ_ID_WIDTH)
    ) memoryReadReqIDFreeList ( 
        .clk(port.M_AXI_ACLK),
        .rst(~port.M_AXI_ARESETN),
        .push(pushFreeReadReqID),
        .pop(popFreeReadReqID),
        .pushedData(pushedFreeReadReqID),
        .full(readReqIDFreeListFull),
        .empty(readReqIDFreeListEmpty),
        .headData(popedFreeReadReqID)
    );

    // 利用可能なreadReqIDがなければ新しいリードリクエストは受け付けられない
    assign memAccessReadBusy = readReqIDFreeListEmpty;

    // メモリからのデータの読み出しが完了し，coreにデータを送ったら対応するIDはフリーになる
    assign pushFreeReadReqID = memReadDataReady;
    assign pushedFreeReadReqID = memoryReadDataID;

    // 利用可能なreadReqIDがあり，かつリード要求がcoreから来ていたら新しいreadReqIDをpopする
    assign popFreeReadReqID = (~readReqIDFreeListEmpty && memAccessRE) ? 1'd1 : 1'd0;

    // 次のRSDのリード要求に割り当てられるシリアルはFreelistの先頭にある
    assign nextMemReadSerial = popedFreeReadReqID;

//
// --- memoryReadReqQueue
//
    MemoryReadReqQueue memoryReadReqQueue ( 
        .clk(port.M_AXI_ACLK),
        .rst(~port.M_AXI_ARESETN),
        .push(pushMemoryReadReq),
        .pop(popMemoryReadReq),
        .pushedData(pushedMemoryReadReq),
        .full(memoryReadReqQueueFull),
        .empty(memoryReadReqQueueEmpty),
        .headData(popedMemoryReadReq)
    );

    // freelistからpopされたreadReqIDをmemoryReadReqQueueに入力する
    assign pushedMemoryReadReq.id = popedFreeReadReqID;

    // coreからのリードリクエストのアドレスをmemoryReadReqQueueに入力する
    assign pushedMemoryReadReq.addr = memAccessAddr[MEMORY_AXI4_ADDR_BIT_SIZE-1:0];

    // freelistからreadReqIDがpopされた場合，coreからリクエストが来ていて，かつ受付可能であることを意味しているのでpush
    assign pushMemoryReadReq = popFreeReadReqID;

    // リクエストキューにリクエストが存在し，かつそのリクエストをハンドシェイクによってメモリに伝達できた場合そのリクエストをpopする
    assign popMemoryReadReq = (~memoryReadReqQueueEmpty && port.M_AXI_ARREADY && axi_arvalid) ? 1'd1 : 1'd0;

//
// --- memoryReadDataTable
//
    DistributedDualPortRAM #( 
        .ENTRY_NUM(MEMORY_AXI4_READ_ID_NUM), 
        .ENTRY_BIT_SIZE(MEMORY_ENTRY_BIT_NUM)
    ) memoryReadDataTable ( 
        .clk(port.M_AXI_ACLK),
        .we(memoryReadDataTableWE),
        .wa(memoryReadDataID),
        .wv(nextMemoryReadData),
        .ra(memoryReadDataID),
        .rv(memoryReadData)
    );

    // メモリからデータを受け取ったらテーブル内のデータを更新
    assign memoryReadDataTableWE = (port.M_AXI_RVALID && axi_rready) ? 1'd1: 1'd0;
    // memoryReadDataTableのアドレスはメモリから届いたデータのID
    assign memoryReadDataID = port.M_AXI_RID;
    // データがメモリから届いたら，テーブルのエントリの上位ビットに挿入する
    generate 
        if (MEMORY_ENTRY_BIT_NUM == MEMORY_AXI4_DATA_BIT_NUM) begin
            assign nextMemoryReadData = port.M_AXI_RDATA;
        end
        else begin
            assign nextMemoryReadData = {port.M_AXI_RDATA, memoryReadData[MEMORY_ENTRY_BIT_NUM-1: MEMORY_AXI4_DATA_BIT_NUM]};
        end
    endgenerate

    // バースト転送が終わったらそのエントリはデータの受信が完了したのでcoreにデータを送る．
    assign memReadDataReady = (port.M_AXI_RVALID && axi_rready && port.M_AXI_RLAST) ? 1'd1 : 1'd0;
    assign memReadData = nextMemoryReadData;
    assign memReadSerial = memoryReadDataID;
  

//
// --- definition for AXI4 write
//
    // memoryReadReqQueueにpushするmemoryReadReq
    MemoryEntryDataPath pushedMemoryWriteData;
    // 1ならmemoryReadReqQueueにpushする
    logic pushMemoryWriteData;
    // 1ならmemoryReadReqQueueからpopする
    logic popMemoryWriteData;
    // 1ならmemoryReadReqQueueがfull
    logic memoryWriteDataQueueFull;
    // 1ならmemoryReadReqQueueが空
    logic memoryWriteDataQueueEmpty;
    // memoryReadReqQueueの先頭にあるmemoryReadReq
    MemoryEntryDataPath popedMemoryWriteData;
    // memoryReadReqQueueのポインタ
    MemWriteSerial memoryWriteDataQueueHeadPtr;
    MemWriteSerial memoryWriteDataQueueTailPtr;
    // シフトするためのデータバッファ
    MemoryEntryDataPath memoryWriteData;

//
// --- memoryReadReqQueue
//
    MemoryWriteDataQueue memoryWriteDataQueue ( 
        .clk(port.M_AXI_ACLK),
        .rst(~port.M_AXI_ARESETN),
        .push(pushMemoryWriteData),
        .pop(popMemoryWriteData),
        .pushedData(pushedMemoryWriteData),
        .full(memoryWriteDataQueueFull),
        .empty(memoryWriteDataQueueEmpty),
        .headData(popedMemoryWriteData),
        .headPtr(memoryWriteDataQueueHeadPtr),
        .tailPtr(memoryWriteDataQueueTailPtr)
    );

    // メモリがライトリクエストを受け入れ可能で，かつcoreがライトリクエストを送信したらキューにデータを入れる
    assign pushMemoryWriteData = (memAccessWE && port.M_AXI_AWREADY && ~memoryWriteDataQueueFull) ? 1'd1 : 1'd0;

    // coreからのデータをmemoryWriteDataQueueにpushする
    assign pushedMemoryWriteData = memAccessWriteData;

    // headデータの書き込みが完了したらpopする
    assign popMemoryWriteData = (port.M_AXI_BVALID && axi_bready) ? 1'd1 : 1'd0;
                              //(port.M_AXI_BVALID && axi_bready && (memoryWriteDataQueueHeadPtr == port.M_AXI_BID)) ? 1'd1 : 1'd0;

    // メモリがライトリクエストを受け入れ不可能か，memoryWriteDataQueueがフルなら新しいリクエストは受付不可能
    assign memAccessWriteBusy = (~port.M_AXI_AWREADY || memoryWriteDataQueueFull) ? 1'd1 : 1'd0;

    // AXIバスから書き込み完了応答がきたら，RSDに通知する
    assign memAccessResponse.valid = (port.M_AXI_BVALID && axi_bready) ? 1'd1 : 1'd0;
    assign memAccessResponse.serial = port.M_AXI_BID;

    // RSDからのライト要求を入れるmemoryWriteDataQueueのエントリインデックスがその要求のシリアルになる．
    assign nextMemWriteSerial = memoryWriteDataQueueTailPtr;

//
// --- axi4 signals
//
    // リード要求アドレスはmemoryReadReqQueueの先頭のリクエストに入っている．
    assign axi_araddr = popedMemoryReadReq.addr;

    // coreからのライトリクエストをバスに出力する
    assign axi_awvalid = memAccessWE;

    // coreからのライトリクエストと同時にくるアドレスをバスに出力する
    assign axi_awaddr = memAccessAddr[MEMORY_AXI4_ADDR_BIT_SIZE-1:0];

    // I/O Connections assignments

    //I/O Connections. Write Address (AW)
    // 対応するデータをmemoryWriteDataQueueにpushするポインタがIDとなる
    assign port.M_AXI_AWID    = memoryWriteDataQueueTailPtr;//'b0;
    //The AXI address is a concatenation of the target base address + active offset range
    assign port.M_AXI_AWADDR    = MEMORY_AXI4_BASE_ADDR + axi_awaddr;
    //Burst LENgth is number of transaction beats, minus 1
    assign port.M_AXI_AWLEN    = MEMORY_AXI4_BURST_LEN - 1;
    //Size should be MEMORY_AXI4_DATA_BIT_NUM, in 2^SIZE bytes, otherwise narrow bursts are used
    assign port.M_AXI_AWSIZE    = clogb2((MEMORY_AXI4_DATA_BIT_NUM/8)-1);
    //INCR burst type is usually used, except for keyhole bursts
    // Burst type (AWBURST) is INCR (2'b01). 
    assign port.M_AXI_AWBURST    = 2'b01;
    // AXI4 does NOT support locked transactions.
    assign port.M_AXI_AWLOCK    = 1'b0;
    //Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
    assign port.M_AXI_AWCACHE    = 4'b0010;
    assign port.M_AXI_AWPROT    = 3'h0;
    assign port.M_AXI_AWQOS    = 4'h0;
    // AWUSER is ignored with HP0~3. It should be set appropriately with ACP ports.
    assign port.M_AXI_AWUSER    = 'b1;
    assign port.M_AXI_AWVALID    = axi_awvalid;
    //Write Data(W)
    assign port.M_AXI_WDATA    = axi_wdata;
    //All bursts are complete and aligned in this example
    assign port.M_AXI_WSTRB    = {(MEMORY_AXI4_DATA_BIT_NUM/8){1'b1}};
    assign port.M_AXI_WLAST    = axi_wlast;
    // WUSER is ignored.
    assign port.M_AXI_WUSER    = 'b0;
    assign port.M_AXI_WVALID    = axi_wvalid;
    //Write Response (B)
    assign port.M_AXI_BREADY    = axi_bready;
    //Read Address (AR)
    // memoryReadReqQueueの先頭に発行するリードリクエストのidが入っている
    assign port.M_AXI_ARID    = popedMemoryReadReq.id;//'b0;
    assign port.M_AXI_ARADDR    = MEMORY_AXI4_BASE_ADDR + axi_araddr;
    //Burst LENgth is number of transaction beats, minus 1
    assign port.M_AXI_ARLEN    = MEMORY_AXI4_BURST_LEN - 1;
    //Size should be MEMORY_AXI4_DATA_BIT_NUM, in 2^n bytes, otherwise narrow bursts are used
    assign port.M_AXI_ARSIZE    = clogb2((MEMORY_AXI4_DATA_BIT_NUM/8)-1);
    //INCR burst type is usually used, except for keyhole bursts
    // Burst type (ARBURST) is INCR (2'b01). 
    assign port.M_AXI_ARBURST    = 2'b01;
    // AXI4 does NOT support locked transactions.
    assign port.M_AXI_ARLOCK    = 1'b0;
    //Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
    assign port.M_AXI_ARCACHE    = 4'b0010;
    assign port.M_AXI_ARPROT    = 3'h0;
    assign port.M_AXI_ARQOS    = 4'h0;
    // ARUSER is ignored with HP0~3. It should be set appropriately with ACP ports.
    assign port.M_AXI_ARUSER    = 'b1;
    assign port.M_AXI_ARVALID    = axi_arvalid;
    //Read and Read Response (R)
    assign port.M_AXI_RREADY    = axi_rready;
    //Example design I/O
    // assign TXN_DONE    = compare_done;
    //Burst size in bytes
    assign burst_size_bytes    = MEMORY_AXI4_BURST_LEN * MEMORY_AXI4_DATA_BIT_NUM/8;
    // assign init_txn_pulse    = (!init_txn_ff2) && init_txn_ff;


    // //Generate a pulse to initiate AXI transaction.
    // always_ff @(posedge port.M_AXI_ACLK)                                              
    //   begin                                                                        
    //     // Initiates AXI transaction delay    
    //     if (port.M_AXI_ARESETN == 0 )                                                   
    //       begin                                                                    
    //         init_txn_ff <= 1'b0;                                                   
    //         init_txn_ff2 <= 1'b0;                                                   
    //       end                                                                               
    //     else                                                                       
    //       begin  
    //         init_txn_ff <= INIT_AXI_TXN;
    //         init_txn_ff2 <= init_txn_ff;                                                                 
    //       end                                                                      
    //   end     


    //--------------------
    //Write Address Channel
    //--------------------

    // The purpose of the write address channel is to request the address and 
    // command information for the entire transaction.  It is a single beat
    // of information.

    // The AXI4 Write address channel in this example will continue to initiate
    // write commands as fast as it is allowed by the slave/interconnect.
    // The address will be incremented on each accepted address transaction,
    // by burst_size_byte to point to the next address. 

      // always_ff @(posedge port.M_AXI_ACLK)                                   
      // begin                                                                
                                                                           
      //   if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                           
      //     begin                                                            
      //       axi_awvalid <= 1'b0;                                           
      //     end                                                              
      //   // If previously not valid , start next transaction                
      //   else if (~axi_awvalid && start_single_burst_write)                 
      //     begin                                                            
      //       axi_awvalid <= 1'b1;                                           
      //     end                                                              
      //   /* Once asserted, VALIDs cannot be deasserted, so axi_awvalid      
      //   must wait until transaction is accepted */                         
      //   else if (port.M_AXI_AWREADY && axi_awvalid)                             
      //     begin                                                            
      //       axi_awvalid <= 1'b0;                                           
      //     end                                                              
      //   else                                                               
      //     axi_awvalid <= axi_awvalid;                                      
      //   end                                                                
                                                                           
                                                                           
    // Next address after AWREADY indicates previous address acceptance    
      // always_ff @(posedge port.M_AXI_ACLK)                                         
      // begin                                                                
      //   if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                            
      //     begin                                                            
      //       axi_awaddr <= 'b0;                                             
      //     end                                                              
      //   else if (port.M_AXI_AWREADY && axi_awvalid)                             
      //     begin                                                            
      //       axi_awaddr <= next_addr;                   
      //     end                                                              
      //   else                                                               
      //     axi_awaddr <= axi_awaddr;                                        
      //   end                                                                


    //--------------------
    //Write Data Channel
    //--------------------

    //The write data will continually try to push write data across the interface.

    //The amount of data accepted will depend on the AXI slave and the AXI
    //Interconnect settings, such as if there are FIFOs enabled in interconnect.

    //Note that there is no explicit timing relationship to the write address channel.
    //The write channel has its own throttling flag, separate from the AW channel.

    //Synchronization between the channels must be determined by the user.

    //The simpliest but lowest performance would be to only issue one address write
    //and write data burst at a time.

    //In this example they are kept in sync by using the same address increment
    //and burst sizes. Then the AW and W channels have their transactions measured
    //with threshold counters as part of the user logic, to make sure neither 
    //channel gets too far ahead of each other.

    //Forward movement occurs when the write channel is valid and ready

      assign wnext = port.M_AXI_WREADY & axi_wvalid;                                   
                                                                                        
    // WVALID logic, similar to the axi_awvalid always block above                      
      always_ff @(posedge port.M_AXI_ACLK)                                                      
      begin                                                                             
        if (port.M_AXI_ARESETN == 0 )                                                        
          begin                                                                         
            axi_wvalid <= 1'b0;                                                         
          end                                                                           
        // If previously not valid, start next transaction                              
        else if (~axi_wvalid && start_single_burst_write)                               
          begin                                                                         
            axi_wvalid <= 1'b1;                                                         
          end                                                                           
        /* If WREADY and too many writes, throttle WVALID                               
        Once asserted, VALIDs cannot be deasserted, so WVALID                           
        must wait until burst is complete with WLAST */                                 
        else if (wnext && axi_wlast)                                                    
          axi_wvalid <= 1'b0;                                                           
        else                                                                            
          axi_wvalid <= axi_wvalid;                                                     
      end                                                                               
                                                                                        
                                                                                        
    //WLAST generation on the MSB of a counter underflow                                
    // WVALID logic, similar to the axi_awvalid always block above                      
      always_ff @(posedge port.M_AXI_ACLK)                                                      
      begin                                                                             
        if (port.M_AXI_ARESETN == 0 )                                                        
          begin                                                                         
            axi_wlast <= 1'b0;                                                          
          end                                                                           
        // axi_wlast is asserted when the write index                                   
        // count reaches the penultimate count to synchronize                           
        // with the last write data when write_index is b1111                           
        // else if (&(write_index[C_TRANSACTIONS_NUM-1:1])&& ~write_index[0] && wnext)  
        else if (((write_index == MEMORY_AXI4_BURST_LEN-2 && MEMORY_AXI4_BURST_LEN >= 2) && wnext) || (MEMORY_AXI4_BURST_LEN == 1 ))
          begin                                                                         
            axi_wlast <= 1'b1;                                                          
          end                                                                           
        // Deassrt axi_wlast when the last write data has been                          
        // accepted by the slave with a valid response                                  
        else if (wnext)                                                                 
          axi_wlast <= 1'b0;                                                            
        else if (axi_wlast && MEMORY_AXI4_BURST_LEN == 1)                                   
          axi_wlast <= 1'b0;                                                            
        else                                                                            
          axi_wlast <= axi_wlast;                                                       
      end                                                                               
                                                                                        
                                                                                        
    /* Burst length counter. Uses extra counter register bit to indicate terminal       
     count to reduce decode logic */                                                    
      always_ff @(posedge port.M_AXI_ACLK)                                                      
      begin                                                                             
        if (port.M_AXI_ARESETN == 0 || start_single_burst_write == 1'b1)    
          begin                                                                         
            write_index <= 0;                                                           
          end                                                                           
        else if (wnext && (write_index != MEMORY_AXI4_BURST_LEN-1))                         
          begin                                                                         
            write_index <= write_index + 1;                                             
          end                                                                           
        else                                                                            
          write_index <= write_index;                                                   
      end                                                                               

    generate 
        // バースト転送のため書き込みデータを1転送ごとにシフトしていく
        if (MEMORY_ENTRY_BIT_NUM == MEMORY_AXI4_DATA_BIT_NUM) begin
            always_ff @(posedge port.M_AXI_ACLK)                                                      
            begin                                                                             
                if (port.M_AXI_ARESETN == 0)                                                         
                memoryWriteData <= '0;                                                                                                                
                else if (start_single_burst_write)                                                                            
                // バースト転送開始時にmemoryWriteDataQueueの先頭のデータをコピーする
                memoryWriteData <= popedMemoryWriteData;
                else if (wnext)
                // 1ワード(AXIバス幅単位)の送信が終わったら送信するデータをシフトする
                memoryWriteData <= memoryWriteData;
            end         
        end
        else begin
            always_ff @(posedge port.M_AXI_ACLK)                                                      
            begin                                                                             
                if (port.M_AXI_ARESETN == 0)                                                         
                memoryWriteData <= '0;                                                                                                                
                else if (start_single_burst_write)                                                                            
                // バースト転送開始時にmemoryWriteDataQueueの先頭のデータをコピーする
                memoryWriteData <= popedMemoryWriteData;
                else if (wnext)
                // 1ワード(AXIバス幅単位)の送信が終わったら送信するデータをシフトする
                memoryWriteData <= {{MEMORY_AXI4_DATA_BIT_NUM{1'd0}}, memoryWriteData[MEMORY_ENTRY_BIT_NUM-1:MEMORY_AXI4_DATA_BIT_NUM]};
            end         
        end
    endgenerate 
    
      assign axi_wdata = memoryWriteData[MEMORY_AXI4_DATA_BIT_NUM-1: 0]; 
                                                                                        
    // /* Write Data Generator                                                             
    //  Data pattern is only a simple incrementing count from 0 for each burst  */         
    //   always_ff @(posedge port.M_AXI_ACLK)                                                      
    //   begin                                                                             
    //     if (port.M_AXI_ARESETN == 0)                                                         
    //       axi_wdata <= '0;                                                             
    //     // //else if (wnext && axi_wlast)                                                  
    //     // //  axi_wdata <= 'b0;                                                           
    //     // else if (wnext)                                                                 
    //     //   axi_wdata <= axi_wdata + 1;                                                   
    //     else                                                                            
    //       axi_wdata <= memoryWriteData[MEMORY_AXI4_DATA_BIT_NUM-1: 0];                                                       
    //   end                                                                             

      always_ff @(posedge port.M_AXI_ACLK)                                                      
      begin    
        if (port.M_AXI_ARESETN == 0) begin
          start_single_burst_write <= 1'b0; 
        end
        if (~start_single_burst_write && ~burst_write_active && ~memoryWriteDataQueueEmpty)                       
          begin                                                                                     
            start_single_burst_write <= 1'b1;                                                       
          end                                                                                       
        else                                                                                        
          begin                                                                                     
            start_single_burst_write <= 1'b0; //Negate to generate a pulse                          
          end   
      end

    //----------------------------
    //Write Response (B) Channel
    //----------------------------

    //The write response channel provides feedback that the write has committed
    //to memory. BREADY will occur when all of the data and the write address
    //has arrived and been accepted by the slave.

    //The write issuance (number of outstanding write addresses) is started by 
    //the Address Write transfer, and is completed by a BREADY/BRESP.

    //While negating BREADY will eventually throttle the AWREADY signal, 
    //it is best not to throttle the whole data channel this way.

    //The BRESP bit [1] is used indicate any errors from the interconnect or
    //slave for the entire write burst. This example will capture the error 
    //into the ERROR output. 

      always_ff @(posedge port.M_AXI_ACLK)                                     
      begin                                                                 
        if (port.M_AXI_ARESETN == 0)                                            
          begin                                                             
            axi_bready <= 1'b0;                                             
          end                                                               
        // accept/acknowledge bresp with axi_bready by the master           
        // when port.M_AXI_BVALID is asserted by slave                           
        else if (port.M_AXI_BVALID && ~axi_bready)                               
          begin                                                             
            axi_bready <= 1'b1;                                             
          end                                                               
        // deassert after one clock cycle                                   
        else if (axi_bready)                                                
          begin                                                             
            axi_bready <= 1'b0;                                             
          end                                                               
        // retain the previous value                                        
        else                                                                
          axi_bready <= axi_bready;                                         
      end                                                                   
                                                                            
                                                                            
    //Flag any write response errors                                        
      assign write_resp_error = axi_bready & port.M_AXI_BVALID & port.M_AXI_BRESP[1]; 


    //----------------------------
    //Read Address Channel
    //----------------------------

    //The Read Address Channel (AW) provides a similar function to the
    //Write Address channel- to provide the tranfer qualifiers for the burst.

    //In this example, the read address increments in the same
    //manner as the write address channel.

      always_ff @(posedge port.M_AXI_ACLK)                                 
      begin                                                              
                                                                         
        if (port.M_AXI_ARESETN == 0)                                         
          begin                                                          
            axi_arvalid <= 1'b0;                                         
          end                                                            
        // If previously not valid , start next transaction 
        // memoryReadReqQueueが空でない場合，送信すべきリクエストがあるので送信する
        else if (~axi_arvalid && ~memoryReadReqQueueEmpty)                
          begin                                                          
            axi_arvalid <= 1'b1;                                         
          end                                                            
        else if (port.M_AXI_ARREADY && axi_arvalid)                           
          begin                                                          
            axi_arvalid <= 1'b0;                                         
          end                                                            
        else                                                             
          axi_arvalid <= axi_arvalid;                                    
      end                                                                
                                                   

    // // Next address after ARREADY indicates previous address acceptance  
    //   always_ff @(posedge port.M_AXI_ACLK)                                       
    //   begin                                                              
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                          
    //       begin                                                          
    //         axi_araddr <= 'b0;                                           
    //       end                                                            
    //     else if (port.M_AXI_ARREADY && axi_arvalid)                           
    //       begin                                                          
    //         axi_araddr <= next_addr;                 
    //       end                                                            
    //     else                                                             
    //       axi_araddr <= axi_araddr;                                      
    //   end                                                                


    //--------------------------------
    //Read Data (and Response) Channel
    //--------------------------------

     // Forward movement occurs when the channel is valid and ready   
      //assign rnext = port.M_AXI_RVALID && axi_rready;                            
                                                                            
                                                                            
    // // Burst length counter. Uses extra counter register bit to indicate    
    // // terminal count to reduce decode logic                                
    //   always_ff @(posedge port.M_AXI_ACLK)                                          
    //   begin                                                                 
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 || start_single_burst_read)                  
    //       begin                                                             
    //         read_index <= 0;                                                
    //       end                                                               
    //     else if (rnext && (read_index != MEMORY_AXI4_BURST_LEN-1))              
    //       begin                                                             
    //         read_index <= read_index + 1;                                   
    //       end                                                               
    //     else                                                                
    //       read_index <= read_index;                                         
    //   end                                                                   
                                                                            
                                                                            
    /*                                                                      
     The Read Data channel returns the results of the read request          
                                                                            
     In this example the data checker is always able to accept              
     more data, so no need to throttle the RREADY signal                    
     */                                                                     
      always_ff @(posedge port.M_AXI_ACLK)                                          
      begin                                                                 
        if (port.M_AXI_ARESETN == 0)                  
          begin                                                             
            axi_rready <= 1'b0;                                             
          end                                                               
        // accept/acknowledge rdata/rresp with axi_rready by the master     
        // when port.M_AXI_RVALID is asserted by slave                           
        else if (port.M_AXI_RVALID)                       
          begin                                      
             if (port.M_AXI_RLAST && axi_rready)          
              begin                                  
                axi_rready <= 1'b0;                  
              end                                    
             else                                    
               begin                                 
                 axi_rready <= 1'b1;                 
               end                                   
          end                                        
        // retain the previous value                 
      end                                            
                                                                            
    // //Check received read data against data generator                       
    //   always_ff @(posedge port.M_AXI_ACLK)                                          
    //   begin                                                                 
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                   
    //       begin                                                             
    //         read_mismatch <= 1'b0;                                          
    //       end                                                               
    //     //Only check data when RVALID is active                             
    //     else if (rnext && (port.M_AXI_RDATA != expected_rdata))                  
    //       begin                                                             
    //         read_mismatch <= 1'b1;                                          
    //       end                                                               
    //     else                                                                
    //       read_mismatch <= 1'b0;                                            
    //   end                                                                   
                                                                            
    //Flag any read response errors                                         
      assign read_resp_error = axi_rready & port.M_AXI_RVALID & port.M_AXI_RRESP[1];  


    //----------------------------------------
    //Example design read check data generator
    //-----------------------------------------

    //Generate expected read data to check against actual read data

      // always_ff @(posedge port.M_AXI_ACLK)                     
      // begin                                                  
      //   if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)// || port.M_AXI_RLAST)             
      //       expected_rdata <= 'b1;                            
      //   else if (port.M_AXI_RVALID && axi_rready)                  
      //       expected_rdata <= expected_rdata + 1;             
      //   else                                                  
      //       expected_rdata <= expected_rdata;                 
      // end                                                    


    //----------------------------------
    //Example design error register
    //----------------------------------

    //Register and hold any data mismatches, or read/write interface errors 

      always_ff @(posedge port.M_AXI_ACLK)                                 
      begin                                                              
        if (port.M_AXI_ARESETN == 0)                                          
          begin                                                          
            error_reg <= 1'b0;                                           
          end                                                            
        else if (write_resp_error || read_resp_error)   
          begin                                                          
            error_reg <= 1'b1;                                           
          end                                                            
        else                                                             
          error_reg <= error_reg;                                        
      end                                                                


    // //--------------------------------
    // //Example design throttling
    // //--------------------------------

    // // For maximum port throughput, this user example code will try to allow
    // // each channel to run as independently and as quickly as possible.

    // // However, there are times when the flow of data needs to be throtted by
    // // the user application. This example application requires that data is
    // // not read before it is written and that the write channels do not
    // // advance beyond an arbitrary threshold (say to prevent an 
    // // overrun of the current read address by the write address).

    // // From AXI4 Specification, 13.13.1: "If a master requires ordering between 
    // // read and write transactions, it must ensure that a response is received 
    // // for the previous transaction before issuing the next transaction."

    // // This example accomplishes this user application throttling through:
    // // -Reads wait for writes to fully complete
    // // -Address writes wait when not read + issued transaction counts pass 
    // // a parameterized threshold
    // // -Writes wait when a not read + active data burst count pass 
    // // a parameterized threshold

    //  // write_burst_counter counter keeps track with the number of burst transaction initiated            
    //  // against the number of burst transactions the master needs to initiate                                   
    //   always_ff @(posedge port.M_AXI_ACLK)                                                                              
    //   begin                                                                                                     
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                                                                 
    //       begin                                                                                                 
    //         write_burst_counter <= 'b0;                                                                         
    //       end                                                                                                   
    //     else if (port.M_AXI_AWREADY && axi_awvalid)                                                                  
    //       begin                                                                                                 
    //         if (write_burst_counter[C_NO_BURSTS_REQ] == 1'b0)                                                   
    //           begin                                                                                             
    //             write_burst_counter <= write_burst_counter + 1'b1;                                              
    //             //write_burst_counter[C_NO_BURSTS_REQ] <= 1'b1;                                                 
    //           end                                                                                               
    //       end                                                                                                   
    //     else                                                                                                    
    //       write_burst_counter <= write_burst_counter;                                                           
    //   end                                                                                                       
                                                                                                                
    //  // read_burst_counter counter keeps track with the number of burst transaction initiated                   
    //  // against the number of burst transactions the master needs to initiate                                   
    //   always_ff @(posedge port.M_AXI_ACLK)                                                                              
    //   begin                                                                                                     
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
    //       begin                                                                                                 
    //         read_burst_counter <= 'b0;                                                                          
    //       end                                                                                                   
    //     else if (port.M_AXI_ARREADY && axi_arvalid)                                                                  
    //       begin                                                                                                 
    //         if (read_burst_counter[C_NO_BURSTS_REQ] == 1'b0)                                                    
    //           begin                                                                                             
    //             read_burst_counter <= read_burst_counter + 1'b1;                                                
    //             //read_burst_counter[C_NO_BURSTS_REQ] <= 1'b1;                                                  
    //           end                                                                                               
    //       end                                                                                                   
    //     else                                                                                                    
    //       read_burst_counter <= read_burst_counter;                                                             
    //   end                                                                                                       
                                                                                                                
                                                                                                                
    //   //implement master command interface state machine                                                        
                                                                                                                
    //   always_ff @ ( posedge port.M_AXI_ACLK)                                                                            
    //   begin                                                                                                     
    //     if (port.M_AXI_ARESETN == 1'b0 )                                                                             
    //       begin                                                                                                 
    //         // reset condition                                                                                  
    //         // All the signals are assigned default values under reset condition                                
    //         mst_exec_state      <= IDLE;                                                                
    //         start_single_burst_write <= 1'b0;                                                                   
    //         start_single_burst_read  <= 1'b0;                                                                   
    //         compare_done      <= 1'b0;                                                                          
    //         ERROR <= 1'b0;   
    //       end                                                                                                   
    //     else                                                                                                    
    //       begin                                                                                                 
                                                                                                                
    //         // state transition                                                                                 
    //         case (mst_exec_state)                                                                               
                                                                                                                
    //           IDLE:                                                                                     
    //             // This state is responsible to wait for user defined C_M_START_COUNT                           
    //             // number of clock cycles.                                                                      
    //             if ( init_txn_pulse == 1'b1)                                                      
    //               begin                                                                                         
    //                 mst_exec_state  <= INIT_WRITE;                                                              
    //                 ERROR <= 1'b0;
    //                 compare_done <= 1'b0;
    //               end                                                                                           
    //             else                                                                                            
    //               begin                                                                                         
    //                 mst_exec_state  <= IDLE;                                                            
    //               end                                                                                           
                                                                                                                
    //           INIT_WRITE:                                                                                       
    //             // This state is responsible to issue start_single_write pulse to                               
    //             // initiate a write transaction. Write transactions will be                                     
    //             // issued until burst_write_active signal is asserted.                                          
    //             // write controller                                                                             
    //             if (writes_done)                                                                                
    //               begin                                                                                         
    //                 mst_exec_state <= INIT_READ;//                                                              
    //               end                                                                                           
    //             else                                                                                            
    //               begin                                                                                         
    //                 mst_exec_state  <= INIT_WRITE;                                                              
                                                                                                                
    //                 if (~axi_awvalid && ~start_single_burst_write && ~burst_write_active)                       
    //                   begin                                                                                     
    //                     start_single_burst_write <= 1'b1;                                                       
    //                   end                                                                                       
    //                 else                                                                                        
    //                   begin                                                                                     
    //                     start_single_burst_write <= 1'b0; //Negate to generate a pulse                          
    //                   end                                                                                       
    //               end                                                                                           
                                                                                                                
    //           INIT_READ:                                                                                        
    //             // This state is responsible to issue start_single_read pulse to                                
    //             // initiate a read transaction. Read transactions will be                                       
    //             // issued until burst_read_active signal is asserted.                                           
    //             // read controller                                                                              
    //             if (reads_done)                                                                                 
    //               begin                                                                                         
    //                 mst_exec_state <= INIT_COMPARE;                                                             
    //               end                                                                                           
    //             else                                                                                            
    //               begin                                                                                         
    //                 mst_exec_state  <= INIT_READ;                                                               
                                                                                                                
    //                 if (~axi_arvalid && ~burst_read_active && ~start_single_burst_read)                         
    //                   begin                                                                                     
    //                     start_single_burst_read <= 1'b1;                                                        
    //                   end                                                                                       
    //                else                                                                                         
    //                  begin                                                                                      
    //                    start_single_burst_read <= 1'b0; //Negate to generate a pulse                            
    //                  end                                                                                        
    //               end                                                                                           
                                                                                                                
    //           INIT_COMPARE:                                                                                     
    //             // This state is responsible to issue the state of comparison                                   
    //             // of written data with the read data. If no error flags are set,                               
    //             // compare_done signal will be asseted to indicate success.                                     
    //             //if (~error_reg)                                                                               
    //             begin                                                                                           
    //               ERROR <= error_reg;
    //               mst_exec_state <= IDLE;                                                               
    //               compare_done <= 1'b1;                                                                         
    //             end                                                                                             
    //           default :                                                                                         
    //             begin                                                                                           
    //               mst_exec_state  <= IDLE;                                                              
    //             end                                                                                             
    //         endcase                                                                                             
    //       end                                                                                                   
    //   end //MASTER_EXECUTION_PROC                                                                               
                                                                                                                
                                                                                                                
      // burst_write_active signal is asserted when there is a burst write transaction                          
      // is initiated by the assertion of start_single_burst_write. burst_write_active                          
      // signal remains asserted until the burst write is accepted by the slave                                 
      always_ff @(posedge port.M_AXI_ACLK)                                                                              
      begin                                                                                                     
        if (port.M_AXI_ARESETN == 0)                                                                                 
          burst_write_active <= 1'b0;                                                                           
                                                                                                                
        //The burst_write_active is asserted when a write burst transaction is initiated                        
        else if (start_single_burst_write)                                                                      
          burst_write_active <= 1'b1;                                                                           
        else if (port.M_AXI_BVALID && axi_bready)                                                                    
          burst_write_active <= 0;                                                                              
      end                                                                                                       
                                                                                                                
    //  // Check for last write completion.                                                                        
                                                                                                                
    //  // This logic is to qualify the last write count with the final write                                      
    //  // response. This demonstrates how to confirm that a write has been                                        
    //  // committed.                                                                                              
                                                                                                                
    //   always_ff @(posedge port.M_AXI_ACLK)                                                                              
    //   begin                                                                                                     
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
    //       writes_done <= 1'b0;                                                                                  
                                                                                                                
    //     //The writes_done should be associated with a bready response                                           
    //     //else if (port.M_AXI_BVALID && axi_bready && (write_burst_counter == {(C_NO_BURSTS_REQ-1){1}}) && axi_wlast)
    //     else if (port.M_AXI_BVALID && (write_burst_counter[C_NO_BURSTS_REQ]) && axi_bready)                          
    //       writes_done <= 1'b1;                                                                                  
    //     else                                                                                                    
    //       writes_done <= writes_done;                                                                           
    //     end                                                                                                     
                                                                                                                
    //   // burst_read_active signal is asserted when there is a burst write transaction                           
    //   // is initiated by the assertion of start_single_burst_write. start_single_burst_read                     
    //   // signal remains asserted until the burst read is accepted by the master                                 
    //   always_ff @(posedge port.M_AXI_ACLK)                                                                              
    //   begin                                                                                                     
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
    //       burst_read_active <= 1'b0;                                                                            
                                                                                                                
    //     //The burst_write_active is asserted when a write burst transaction is initiated                        
    //     else if (start_single_burst_read)                                                                       
    //       burst_read_active <= 1'b1;                                                                            
    //     else if (port.M_AXI_RVALID && axi_rready && port.M_AXI_RLAST)                                                     
    //       burst_read_active <= 0;                                                                               
    //     end                                                                                                     
                                                                                                                
                                                                                                                
    //  // Check for last read completion.                                                                         
                                                                                                                
    //  // This logic is to qualify the last read count with the final read                                        
    //  // response. This demonstrates how to confirm that a read has been                                         
    //  // committed.                                                                                              
                                                                                                                
    //   always_ff @(posedge port.M_AXI_ACLK)                                                                              
    //   begin                                                                                                     
    //     if (port.M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
    //       reads_done <= 1'b0;                                                                                   
                                                                                                                
    //     //The reads_done should be associated with a rready response                                            
    //     //else if (port.M_AXI_BVALID && axi_bready && (write_burst_counter == {(C_NO_BURSTS_REQ-1){1}}) && axi_wlast)
    //     else if (port.M_AXI_RVALID && axi_rready && (read_index == MEMORY_AXI4_BURST_LEN-1) && (read_burst_counter[C_NO_BURSTS_REQ]))
    //       reads_done <= 1'b1;                                                                                   
    //     else                                                                                                    
    //       reads_done <= reads_done;                                                                             
    //     end                                                                                                     

    // Add user logic here

    // User logic ends

    endmodule
// ---- Memory/Axi4MemoryIF.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// Axi4MemoryIF
//

import BasicTypes::*;
import MemoryTypes::*;
import CacheSystemTypes::*;

interface Axi4MemoryIF;

    // // Initiate AXI transactions
    // input wire  INIT_AXI_TXN;
    // // Asserts when transaction is complete
    // output wire  TXN_DONE;
    // // Asserts when ERROR is detected
    // output reg  ERROR;
    // Global Clock Signal.
    logic  M_AXI_ACLK;
    // Global Reset Singal. This Signal is Active Low
    logic  M_AXI_ARESETN;
    // Master Interface Write Address ID
    logic [MEMORY_AXI4_WRITE_ID_WIDTH-1 : 0] M_AXI_AWID;
    // Master Interface Write Address
    logic [MEMORY_AXI4_ADDR_BIT_SIZE-1 : 0] M_AXI_AWADDR;
    // Burst length. The burst length gives the exact number of transfers in a burst
    logic [7 : 0] M_AXI_AWLEN;
    // Burst size. This signal indicates the size of each transfer in the burst
    logic [2 : 0] M_AXI_AWSIZE;
    // Burst type. The burst type and the size information; 
    // determine how the address for each transfer within the burst is calculated.
    logic [1 : 0] M_AXI_AWBURST;
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    logic  M_AXI_AWLOCK;
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    logic [3 : 0] M_AXI_AWCACHE;
    // Protection type. This signal indicates the privilege
    // and security level of the transaction; and whether
    // the transaction is a data access or an instruction access.
    logic [2 : 0] M_AXI_AWPROT;
    // Quality of Service; QoS identifier sent for each write transaction.
    logic [3 : 0] M_AXI_AWQOS;
    // Optional User-defined signal in the write address channel.
    logic [MEMORY_AXI4_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER;
    // Write address valid. This signal indicates that
    // the channel is signaling valid write address and control information.
    logic  M_AXI_AWVALID;
    // Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
    logic  M_AXI_AWREADY;
    // Master Interface Write Data.
    logic [MEMORY_AXI4_DATA_BIT_NUM-1 : 0] M_AXI_WDATA;
    // Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
    logic [MEMORY_AXI4_DATA_BIT_NUM/8-1 : 0] M_AXI_WSTRB;
    // Write last. This signal indicates the last transfer in a write burst.
    logic  M_AXI_WLAST;
    // Optional User-defined signal in the write data channel.
    logic [MEMORY_AXI4_WUSER_WIDTH-1 : 0] M_AXI_WUSER;
    // Write valid. This signal indicates that valid write
    // data and strobes are available
    logic  M_AXI_WVALID;
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    logic  M_AXI_WREADY;
    // Master Interface Write Response.
    logic [MEMORY_AXI4_WRITE_ID_WIDTH-1 : 0] M_AXI_BID;
    // Write response. This signal indicates the status of the write transaction.
    logic [1 : 0] M_AXI_BRESP;
    // Optional User-defined signal in the write response channel
    logic [MEMORY_AXI4_BUSER_WIDTH-1 : 0] M_AXI_BUSER;
    // Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
    logic  M_AXI_BVALID;
    // Response ready. This signal indicates that the master
    // can accept a write response.
    logic  M_AXI_BREADY;
    // Master Interface Read Address.
    logic [MEMORY_AXI4_READ_ID_WIDTH-1 : 0] M_AXI_ARID;
    // Read address. This signal indicates the initial
    // address of a read burst transaction.
    logic [MEMORY_AXI4_ADDR_BIT_SIZE-1 : 0] M_AXI_ARADDR;
    // Burst length. The burst length gives the exact number of transfers in a burst
    logic [7 : 0] M_AXI_ARLEN;
    // Burst size. This signal indicates the size of each transfer in the burst
    logic [2 : 0] M_AXI_ARSIZE;
    // Burst type. The burst type and the size information; 
    // determine how the address for each transfer within the burst is calculated.
    logic [1 : 0] M_AXI_ARBURST;
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    logic  M_AXI_ARLOCK;
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    logic [3 : 0] M_AXI_ARCACHE;
    // Protection type. This signal indicates the privilege
    // and security level of the transaction; and whether
    // the transaction is a data access or an instruction access.
    logic [2 : 0] M_AXI_ARPROT;
    // Quality of Service; QoS identifier sent for each read transaction
    logic [3 : 0] M_AXI_ARQOS;
    // Optional User-defined signal in the read address channel.
    logic [MEMORY_AXI4_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER;
    // Write address valid. This signal indicates that
    // the channel is signaling valid read address and control information
    logic  M_AXI_ARVALID;
    // Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
    logic  M_AXI_ARREADY;
    // Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
    logic [MEMORY_AXI4_READ_ID_WIDTH-1 : 0] M_AXI_RID;
    // Master Read Data
    logic [MEMORY_AXI4_DATA_BIT_NUM-1 : 0] M_AXI_RDATA;
    // Read response. This signal indicates the status of the read transfer
    logic [1 : 0] M_AXI_RRESP;
    // Read last. This signal indicates the last transfer in a read burst
    logic  M_AXI_RLAST;
    // Optional User-defined signal in the read address channel.
    logic [MEMORY_AXI4_RUSER_WIDTH-1 : 0] M_AXI_RUSER;
    // Read valid. This signal indicates that the channel
    // is signaling the required read data.
    logic  M_AXI_RVALID;
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    logic  M_AXI_RREADY;

    modport Axi4(
    input 
        M_AXI_ACLK,
        M_AXI_ARESETN,
    output
        M_AXI_AWID,
        M_AXI_AWADDR,
        M_AXI_AWLEN,
        M_AXI_AWSIZE,
        M_AXI_AWBURST,
        M_AXI_AWLOCK,
        M_AXI_AWCACHE,
        M_AXI_AWPROT,
        M_AXI_AWQOS,
        M_AXI_AWUSER,
        M_AXI_AWVALID,
    input
        M_AXI_AWREADY,
    output
        M_AXI_WDATA,
        M_AXI_WSTRB,
        M_AXI_WLAST,
        M_AXI_WUSER,
        M_AXI_WVALID,
    input
        M_AXI_WREADY,
        M_AXI_BID,
        M_AXI_BRESP,
        M_AXI_BUSER,
        M_AXI_BVALID,
    output
        M_AXI_BREADY,
        M_AXI_ARID,
        M_AXI_ARADDR,
        M_AXI_ARLEN,
        M_AXI_ARSIZE,
        M_AXI_ARBURST,
        M_AXI_ARLOCK,
        M_AXI_ARCACHE,
        M_AXI_ARPROT,
        M_AXI_ARQOS,
        M_AXI_ARUSER,
        M_AXI_ARVALID,
    input
        M_AXI_ARREADY,
        M_AXI_RID,
        M_AXI_RDATA,
        M_AXI_RRESP,
        M_AXI_RLAST,
        M_AXI_RUSER,
        M_AXI_RVALID,
    output
        M_AXI_RREADY
    );

    modport Axi4Write(
    input 
        M_AXI_ACLK,
        M_AXI_ARESETN,
    output
        M_AXI_AWID,
        M_AXI_AWADDR,
        M_AXI_AWLEN,
        M_AXI_AWSIZE,
        M_AXI_AWBURST,
        M_AXI_AWLOCK,
        M_AXI_AWCACHE,
        M_AXI_AWPROT,
        M_AXI_AWQOS,
        M_AXI_AWUSER,
        M_AXI_AWVALID,
    input
        M_AXI_AWREADY,
    output
        M_AXI_WDATA,
        M_AXI_WSTRB,
        M_AXI_WLAST,
        M_AXI_WUSER,
        M_AXI_WVALID,
    input
        M_AXI_WREADY,
        M_AXI_BID,
        M_AXI_BRESP,
        M_AXI_BUSER,
        M_AXI_BVALID,
    output
        M_AXI_BREADY
    );

    modport Axi4Read(
    input 
        M_AXI_ACLK,
        M_AXI_ARESETN,
    output
        M_AXI_ARID,
        M_AXI_ARADDR,
        M_AXI_ARLEN,
        M_AXI_ARSIZE,
        M_AXI_ARBURST,
        M_AXI_ARLOCK,
        M_AXI_ARCACHE,
        M_AXI_ARPROT,
        M_AXI_ARQOS,
        M_AXI_ARUSER,
        M_AXI_ARVALID,
    input
        M_AXI_ARREADY,
        M_AXI_RID,
        M_AXI_RDATA,
        M_AXI_RRESP,
        M_AXI_RLAST,
        M_AXI_RUSER,
        M_AXI_RVALID,
    output
        M_AXI_RREADY
    );

endinterface : Axi4MemoryIF

// ---- Memory/MemoryReadReqQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// MemoryReadReqQueue
//

import BasicTypes::*;
import MemoryTypes::*;

module MemoryReadReqQueue ( 
input 
    logic clk,
    logic rst,
    logic push,
    logic pop,
    MemoryReadReq pushedData,
output
    logic full,
    logic empty,
    MemoryReadReq headData
);

    typedef logic [MEMORY_AXI4_READ_ID_WIDTH-1: 0] IndexPath;

    IndexPath headPtr;
    IndexPath tailPtr;

    // size, initial head, initial tail, initial count
    QueuePointer #( MEMORY_AXI4_READ_ID_NUM, 0, 0, 0 )
        pointer(
            .clk( clk ),
            .rst( rst ),
            .push( push ),
            .pop( pop ),
            .full( full ),
            .empty( empty ),
            .headPtr( headPtr ),
            .tailPtr( tailPtr )
        );
        

    logic [ MEMORY_AXI4_READ_ID_WIDTH+MEMORY_AXI4_ADDR_BIT_SIZE-1:0 ] memoryReadReqQueue[ MEMORY_AXI4_READ_ID_NUM ]; // synthesis syn_ramstyle = "select_ram"

    always_ff @( posedge clk ) begin
        if( push ) begin
            memoryReadReqQueue[ tailPtr ] <= pushedData;
        end
    end
    
    always_comb begin
        headData = memoryReadReqQueue[ headPtr ];
    end

endmodule : MemoryReadReqQueue

 
// ---- Memory/MemoryWriteDataQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.


//
// MemoryWriteDataQueue
//

import BasicTypes::*;
import MemoryTypes::*;

module MemoryWriteDataQueue ( 
input 
    logic clk,
    logic rst,
    logic push,
    logic pop,
    MemoryEntryDataPath pushedData,
output
    logic full,
    logic empty,
    MemoryEntryDataPath headData,
    logic [MEMORY_AXI4_WRITE_ID_WIDTH-1: 0] headPtr,
    logic [MEMORY_AXI4_WRITE_ID_WIDTH-1: 0] tailPtr
);

    // typedef logic [MEMORY_AXI4_WRITE_ID_WIDTH-1: 0] IndexPath;

    // IndexPath headPtr;
    // IndexPath tailPtr;

    // size, initial head, initial tail, initial count
    QueuePointer #( MEMORY_AXI4_WRITE_ID_NUM, 0, 0, 0 )
        pointer(
            .clk( clk ),
            .rst( rst ),
            .push( push ),
            .pop( pop ),
            .full( full ),
            .empty( empty ),
            .headPtr( headPtr ),
            .tailPtr( tailPtr )
        );
        

    logic [ MEMORY_ENTRY_BIT_NUM-1:0 ] memoryWriteDataQueue[ MEMORY_AXI4_WRITE_ID_NUM ]; // synthesis syn_ramstyle = "select_ram"

    always_ff @( posedge clk ) begin
        if( push ) begin
            memoryWriteDataQueue[ tailPtr ] <= pushedData;
        end
    end
    
    always_comb begin
        headData = memoryWriteDataQueue[ headPtr ];
    end

endmodule : MemoryWriteDataQueue

 
// ---- Memory/MemoryRequestQueue.sv
// Copyright 2019- RSD contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.



//
// MemoryRequestQueue
//

import BasicTypes::*;
import MemoryTypes::*;

module MemoryRequestQueue( 
input 
    logic clk,
    logic rst,
    logic push,
    MemoryRequestData pushedData,
output
    logic hasRequest,
    MemoryRequestData requestData
);

    typedef logic [$clog2(MEM_REQ_QUEUE_SIZE)-1:0] IndexPath;
    logic pop;
    logic full, empty;

    IndexPath headPtr;
    IndexPath tailPtr;
    LatencyCountPath count, countReg;
    integer RANDOM_VALUE;

    // size, initial head, initial tail, initial count
    QueuePointer #( MEM_REQ_QUEUE_SIZE, 0, 0, 0 )
        pointer(
            .clk( clk ),
            .rst( rst ),
            .push( push ),
            .pop( pop ),
            .full( full ),
            .empty( empty ),
            .headPtr( headPtr ),
            .tailPtr( tailPtr )
        );
        
    MemoryRequestData memoryRequestQueue[ MEM_REQ_QUEUE_SIZE ];

    always_ff @(posedge clk) begin
        if (push) begin
            memoryRequestQueue[ tailPtr ] <= pushedData;
        end

        if (rst) begin
            countReg <= '0;
        end
        else begin
            countReg <= count;
        end
    end

    always_comb begin
        if (rst) begin
`ifndef RSD_SYNTHESIS
    `ifndef RSD_FUNCTIONAL_SIMULATION_VERILATOR
            // Pass seed value first
            // NOTE: this cannot be done in initial begin,
            // because $urandom is thread local
            RANDOM_VALUE = $urandom(RANDOM_LATENCY_SEED) % VARIAVBLE_WIDTH;
    `else
            RANDOM_VALUE = 0;
    `endif
`else
            RANDOM_VALUE = 0;
`endif
        end
        
        count = countReg;

        if (!empty) begin
            // There is some request in the queue
            if (count == RANDOM_VALUE) begin
                // Issue memory request
                pop = TRUE;
                count = '0;
`ifndef RSD_SYNTHESIS
    `ifndef RSD_FUNCTIONAL_SIMULATION_VERILATOR
                // Set next memory latency
                RANDOM_VALUE = $urandom() % VARIAVBLE_WIDTH; 
    `endif
`endif
                // for debug
                // $display("Latency set to %d", RANDOM_VALUE);
            end
            else begin
                // Wait until the determined latency has passed
                pop = FALSE;
                count++;
            end
        end
        else begin
            // There is no request in the queue
            pop = FALSE;
        end

        hasRequest = pop;
        requestData = memoryRequestQueue[ headPtr ];
    end

    assert property(@(posedge clk) !( full ))
        else $error("Cannot response so many memory request.");

endmodule : MemoryRequestQueue
`undef REF
