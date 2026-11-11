// Runs asm/smoke.elf on rsd_top. mem is an AXI4 memory of 256 KB from BASE
// whose channels stall for a varying number of cycles, the way DRAM behind a
// clock crossing does. The serial output is printed as it comes. Veryl's own
// simulator cannot run RSD (it is SystemVerilog), so this uses Verilator.
//
// With +isa, it runs a riscv-tests program instead (+hex=<file>) until it
// writes tohost, and prints "tohost <value>"; "tohost 0" is a timeout.
module tb;
    logic clk = 0;
    always #5 clk = ~clk;

    // dut_base in Harness.toml
    localparam logic [31:0] BASE  = 32'h8000_0000;
    localparam int          WORDS = 32768;  // 64-bit words: 256 KB
    // RSD resets for 10000 cycles before it fetches.
    localparam int          END   = 40000;

    logic [63:0] mem [0:WORDS-1];
    logic [31:0] want [0:9];

    logic [31:0] cycle = 0;
    logic        rst_n;
    integer      oor = 0, bad = 0, i, chars = 0;
    logic        uart_valid;
    logic [7:0]  uart_data;
    logic [31:0] tohost;
    logic        isa = 0;
    string       hex = "smoke.hex";
    // riscv-tests runs, in cycles: RSD's reset takes 10000 of them.
    localparam int ISA_END = 200000;

    assign rst_n = cycle >= 5;

    __std___axi4_if____std___axi4_pkg__32__8__6__1__1__1__1__1 axi ();

    run_rsd_rsd_top dut (
        .i_clk(clk), .i_rst(rst_n),
        .o_uart_valid(uart_valid), .o_uart_data(uart_data), .o_tohost(tohost),
        .mem(axi.master)
    );

    always @(posedge clk) begin
        if (uart_valid && !isa) begin
            $write("%c", uart_data);
            chars <= chars + 1;
        end
    end

    // Pseudo-random ready and response delays, so AW and W are taken in
    // either order and R / B come back late.
    logic [15:0] lfsr = 16'hace1;
    always @(posedge clk) lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

    logic        aw_got, w_got, ar_got;
    logic [31:0] aw_addr, ar_addr;  // offsets from BASE, as the harness makes them
    logic [5:0]  aw_id, ar_id;
    logic [63:0] w_data;
    logic [7:0]  w_strb;
    logic [2:0]  r_wait, b_wait;

    function automatic logic in_range(logic [31:0] off);
        return off < WORDS * 8;
    endfunction

    assign axi.awready = rst_n && !aw_got && lfsr[0];
    assign axi.wready  = rst_n && !w_got && lfsr[1];
    assign axi.arready = rst_n && !ar_got && lfsr[2];
    assign axi.bvalid  = aw_got && w_got && b_wait == 0;
    assign axi.bresp   = __std_axi4_config::resp_variants_OKAY;
    assign axi.bid     = aw_id;
    assign axi.buser   = 0;
    assign axi.rvalid  = ar_got && r_wait == 0;
    assign axi.rdata   = in_range(ar_addr) ? mem[ar_addr[17:3]] : 0;
    assign axi.rresp   = __std_axi4_config::resp_variants_OKAY;
    assign axi.rid     = ar_id;
    assign axi.rlast   = 1;
    assign axi.ruser   = 0;

    // RSD sends single whole 64-bit beats only.
    function automatic logic odd(logic [2:0] size, logic [7:0] len, logic [2:0] low);
        return size != 3'd3 || len != 0 || low != 0;
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            aw_got <= 0;
            w_got  <= 0;
            ar_got <= 0;
            r_wait <= 0;
            b_wait <= 0;
        end else begin
            if (axi.awvalid && axi.awready) begin
                aw_got  <= 1;
                aw_addr <= axi.awaddr - BASE;
                aw_id   <= axi.awid;
                b_wait  <= lfsr[5:3];
                if (odd(axi.awsize, axi.awlen, axi.awaddr[2:0])) bad = bad + 1;
            end
            if (axi.wvalid && axi.wready) begin
                w_got  <= 1;
                w_data <= axi.wdata;
                w_strb <= axi.wstrb;
                if (!axi.wlast) bad = bad + 1;
            end
            if (axi.arvalid && axi.arready) begin
                ar_got  <= 1;
                ar_addr <= axi.araddr - BASE;
                ar_id   <= axi.arid;
                r_wait  <= lfsr[8:6];
                if (odd(axi.arsize, axi.arlen, axi.araddr[2:0])) bad = bad + 1;
            end
            if (aw_got && w_got && b_wait != 0) b_wait <= b_wait - 1;
            if (ar_got && r_wait != 0) r_wait <= r_wait - 1;

            if (axi.bvalid && axi.bready) begin
                aw_got <= 0;
                w_got  <= 0;
                if (in_range(aw_addr)) begin
                    for (int b = 0; b < 8; b++)
                        if (w_strb[b]) mem[aw_addr[17:3]][b*8 +: 8] <= w_data[b*8 +: 8];
                end else begin
                    $display("write out of range: %h", aw_addr + BASE);
                    oor <= oor + 1;
                end
            end
            if (axi.rvalid && axi.rready) begin
                ar_got <= 0;
                if (!in_range(ar_addr)) begin
                    $display("read out of range: %h", ar_addr + BASE);
                    oor <= oor + 1;
                end
            end
        end
    end

    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem[i] = 0;
        isa = $test$plusargs("isa");
        void'($value$plusargs("hex=%s", hex));
        $readmemh(hex, mem);

        // What asm/smoke.S writes at 0x8000_2000, word by word. misa and
        // mhartid (+0x04, +0x08) are only printed.
        want[0] = 32'h21534e48; want[1] = 32'h0;        want[2] = 32'h0;
        want[3] = 32'hc0ffee42; want[4] = 32'h000f45f6; want[5] = 32'h44332211;
        want[6] = 32'h66665555; want[7] = 32'h12345678; want[8] = 32'h80000007;
        want[9] = 32'h600d600d;
    end

    function automatic logic [31:0] word(int off);
        logic [63:0] w = mem[off / 8];
        return off % 8 == 0 ? w[31:0] : w[63:32];
    endfunction

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (isa) begin
            if (tohost != 0 || cycle == ISA_END) begin
                $display("tohost %0d", tohost);
                $finish;
            end
        end else if (cycle == END) begin
            for (i = 0; i < 10; i = i + 1) begin
                if (i == 1 || i == 2 || word(32'h2000 + i * 4) == want[i]) begin
                    $display("+%h %h", 8'(i * 4), word(32'h2000 + i * 4));
                end else begin
                    $display("+%h %h  <- want %h", 8'(i * 4), word(32'h2000 + i * 4), want[i]);
                    bad = bad + 1;
                end
            end
            // Ten words of eight digits and a newline, then "done\n".
            if (chars != 95) begin
                $display("%0d characters on the serial output, want 95", chars);
                bad = bad + 1;
            end
            if (oor != 0) begin
                $display("%0d accesses out of range", oor);
                bad = bad + 1;
            end
            $display("tohost %h", tohost);
            if (tohost != 1) bad = bad + 1;
            if (bad == 0) $display("PASS");
            else $display("FAIL");
            $finish;
        end
    end
endmodule
