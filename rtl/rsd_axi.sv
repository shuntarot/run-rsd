// The RSD core with RSD's own AXI4 master, as a module with plain ports.
// Adapted from RSD's Main_Zynq.sv: Copyright 2019- RSD contributors,
// Apache License 2.0 (LICENSE.RSD).
//
// Core and Axi4Memory talk through SystemVerilog interfaces and types from
// RSD's packages, which a Veryl source cannot name. This module keeps them
// inside. It is RSD's Main_Zynq with the memory, the program loader and the
// Zynq registers taken out.
//
// The AXI4 port carries RSD's physical address plus 0x1000_0000
// (MEMORY_AXI4_BASE_ADDR): 0x1000_0000 to 0x1000_ffff for the 64 KB from
// 0x0000_0000, and 0x1001_0000 up for the 256 KB from 0x8000_0000. Every
// transfer is one 64-bit beat, a whole cache line. Read IDs are 2 bits and
// write IDs 1 bit.
//
// RSD resets for 10000 cycles after rst_trigger falls: it clears its tables
// one entry per cycle (ResetController).

module rsd_axi_core (
    input  logic        clk,
    input  logic        rst_trigger,   // active high

    output logic [0:0]  awid,
    output logic [31:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,
    output logic        awlock,
    output logic [3:0]  awcache,
    output logic [2:0]  awprot,
    output logic [3:0]  awqos,
    output logic        awvalid,
    input  logic        awready,

    output logic [63:0] wdata,
    output logic [7:0]  wstrb,
    output logic        wlast,
    output logic        wvalid,
    input  logic        wready,

    input  logic [0:0]  bid,
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready,

    output logic [1:0]  arid,
    output logic [31:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,
    output logic        arlock,
    output logic [3:0]  arcache,
    output logic [2:0]  arprot,
    output logic [3:0]  arqos,
    output logic        arvalid,
    input  logic        arready,

    input  logic [1:0]  rid,
    input  logic [63:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rlast,
    input  logic        rvalid,
    output logic        rready,

    // A byte the program stored to 0x4000_2000
    output logic        serial_we,
    output logic [7:0]  serial_data,

    // The low word the program last stored to tohost (0x8000_1000)
    output logic [31:0] tohost
);
    import BasicTypes::*;
    import CacheSystemTypes::*;
    import MemoryTypes::*;
    import MemoryMapTypes::*;
    import IO_UnitTypes::*;
    import DebugTypes::*;

    logic rst, rstStart;

    ResetController rstController (
        .clk       (clk),
        .rstTrigger(rst_trigger),
        .locked    (TRUE),
        .rst       (rst),
        .rstStart  (rstStart)
    );

    AddrPath            memAccessAddr;
    PhyAddrPath         memAccessAddrFromCore;
    MemoryEntryDataPath memAccessWriteData;
    logic               memAccessRE;
    logic               memAccessWE;
    logic               memAccessReadBusy;
    logic               memAccessWriteBusy;
    MemAccessSerial     nextMemReadSerial;
    MemWriteSerial      nextMemWriteSerial;
    logic               memReadDataReady;
    MemoryEntryDataPath memReadData;
    MemAccessSerial     memReadSerial;
    MemAccessResponse   memAccessResponse;
    DebugRegister       debugRegister;
    PC_Path             lastCommittedPC;

    assign memAccessAddr = memAccessAddrFromCore;

    Axi4MemoryIF axi ();

    assign axi.M_AXI_ACLK    = clk;
    assign axi.M_AXI_ARESETN = ~rst;

    Axi4Memory axi4Memory (
        .port              (axi),
        .memAccessAddr     (memAccessAddr),
        .memAccessWriteData(memAccessWriteData),
        .memAccessRE       (memAccessRE),
        .memAccessWE       (memAccessWE),
        .memAccessReadBusy (memAccessReadBusy),
        .memAccessWriteBusy(memAccessWriteBusy),
        .nextMemReadSerial (nextMemReadSerial),
        .nextMemWriteSerial(nextMemWriteSerial),
        .memReadDataReady  (memReadDataReady),
        .memReadData       (memReadData),
        .memReadSerial     (memReadSerial),
        .memAccessResponse (memAccessResponse)
    );

    Core core (
        .clk               (clk),
        .rst               (rst),
        .rstStart          (rstStart),
        .memAccessAddr     (memAccessAddrFromCore),
        .memAccessWriteData(memAccessWriteData),
        .memAccessRE       (memAccessRE),
        .memAccessWE       (memAccessWE),
        .memAccessReadBusy (memAccessReadBusy),
        .memAccessWriteBusy(memAccessWriteBusy),
        .nextMemReadSerial (nextMemReadSerial),
        .nextMemWriteSerial(nextMemWriteSerial),
        .memReadDataReady  (memReadDataReady),
        .memReadData       (memReadData),
        .memReadSerial     (memReadSerial),
        .memAccessResponse (memAccessResponse),
        .serialWE          (serial_we),
        .serialWriteData   (serial_data),
        .tohost            (tohost),
        .lastCommittedPC   (lastCommittedPC),
        .debugRegister     (debugRegister)
    );

    assign awid    = axi.M_AXI_AWID;
    assign awaddr  = axi.M_AXI_AWADDR;
    assign awlen   = axi.M_AXI_AWLEN;
    assign awsize  = axi.M_AXI_AWSIZE;
    assign awburst = axi.M_AXI_AWBURST;
    assign awlock  = axi.M_AXI_AWLOCK;
    assign awcache = axi.M_AXI_AWCACHE;
    assign awprot  = axi.M_AXI_AWPROT;
    assign awqos   = axi.M_AXI_AWQOS;
    assign awvalid = axi.M_AXI_AWVALID;
    assign axi.M_AXI_AWREADY = awready;

    assign wdata  = axi.M_AXI_WDATA;
    assign wstrb  = axi.M_AXI_WSTRB;
    assign wlast  = axi.M_AXI_WLAST;
    assign wvalid = axi.M_AXI_WVALID;
    assign axi.M_AXI_WREADY = wready;

    assign axi.M_AXI_BID    = bid;
    assign axi.M_AXI_BRESP  = bresp;
    assign axi.M_AXI_BVALID = bvalid;
    assign bready = axi.M_AXI_BREADY;

    assign arid    = axi.M_AXI_ARID;
    assign araddr  = axi.M_AXI_ARADDR;
    assign arlen   = axi.M_AXI_ARLEN;
    assign arsize  = axi.M_AXI_ARSIZE;
    assign arburst = axi.M_AXI_ARBURST;
    assign arlock  = axi.M_AXI_ARLOCK;
    assign arcache = axi.M_AXI_ARCACHE;
    assign arprot  = axi.M_AXI_ARPROT;
    assign arqos   = axi.M_AXI_ARQOS;
    assign arvalid = axi.M_AXI_ARVALID;
    assign axi.M_AXI_ARREADY = arready;

    assign axi.M_AXI_RID    = rid;
    assign axi.M_AXI_RDATA  = rdata;
    assign axi.M_AXI_RRESP  = rresp;
    assign axi.M_AXI_RLAST  = rlast;
    assign axi.M_AXI_RVALID = rvalid;
    assign rready = axi.M_AXI_RREADY;
endmodule
