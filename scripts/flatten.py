#!/usr/bin/env python3
"""Writes the RSD core as one SystemVerilog file, with every `include
expanded.

The harness reads the core through `include(inline, ...)` in a Veryl source,
and synthesis gets no include path or macro list, so both are written into
the file. The sources are the packages (TYPES) and modules (MODULES) of
Processor/Src/Makefiles/CoreSources.inc.mk, less the board tops and the
simulation memory. BasicMacros.sv goes in once, at the top. PATCHES below
lists what is changed.

    scripts/flatten.py <RSD checkout> > rtl/rsd.sv   (or: make rsd)
"""
import pathlib
import re
import subprocess
import sys

INCLUDE = re.compile(r'^\s*`include\s+"([^"]+)"')
# One source sets a timescale and the others do not, which simulators refuse
# when the files become one.
TIMESCALE = re.compile(r'^\s*`timescale\b')
# Two functions end in "endfunction;". Vivado takes that for a syntax error
# once it is inside a module.
ENDFUNCTION = re.compile(r'^(\s*endfunction)\s*;\s*$')

# What SynthesisMacros.sv sets for Vivado, with these changes:
# - RSD_SYNTHESIS_FPGA, not RSD_SYNTHESIS_ZEDBOARD: the serial output is
#   8 bits wide, one character per write.
# - RSD_USE_EXTERNAL_MEMORY: the AXI4 port carries 32-bit addresses.
DEFINES = [
    ("RSD_SYNTHESIS", ""),
    ("RSD_SYNTHESIS_VIVADO", ""),
    ("RSD_SYNTHESIS_FPGA", ""),
    ("RSD_DISABLE_DEBUG_REGISTER", ""),
    ("RSD_USE_EXTERNAL_MEMORY", ""),
    ("RSD_MARCH_INT_ISSUE_WIDTH", "2"),
    ("REF", "input"),
]

# Not used here: the board tops, the simulation memory, and the AXI4-Lite
# registers that talk to the Zynq PS.
SKIP = {
    "Main_Zynq_Wrapper.sv",
    "Main_Zynq.sv",
    "Memory/Memory.sv",
    "Memory/Axi4LiteControlRegisterIF.sv",
    "Memory/Axi4LiteControlRegister.sv",
}


# Changes to RSD, each applied to text that must occur exactly once.
#
# tohost: riscv-tests report through an 8-byte word at 0x8000_1000. The data
# cache writes back, so the host cannot see that word in memory. These make
# it an I/O address: a store to it goes out, in order and only once it
# retires, as the serial output does, and the core's `tohost` output holds
# the low word last stored there.
#
# Serial input at 0x4000_2004: a load returns the core's `serialIn` input,
# {seq[7:0], char[7:0]}, which the host sets, and a store puts its low byte on
# the `serialInAck` output. The host gives a new character with the next seq
# once serialInAck shows the last one. RSD may run an I/O load early, again,
# or on a path it then drops, and before an older I/O store has gone out; a
# load with no side effect and a seq to compare are correct under all of it.
PATCHES = {
    "Memory/MemoryMapTypes.sv": [
        ("localparam PHY_ADDR_SERIAL_OUTPUT = 20'h0_2000;\n",
         "localparam PHY_ADDR_SERIAL_OUTPUT = 20'h0_2000;\n"
         "localparam LOG_ADDR_SERIAL_INPUT = 32'h4000_2004;\n"
         "localparam PHY_ADDR_SERIAL_INPUT = 20'h0_2004;\n"
         "localparam LOG_ADDR_TOHOST = 32'h8000_1000;\n"
         "localparam PHY_ADDR_TOHOST = 20'h0_3000;\n"),
        ("    if (addr == LOG_ADDR_SERIAL_OUTPUT) begin\n",
         "    if (LOG_ADDR_TOHOST <= addr && addr < LOG_ADDR_TOHOST + 8) begin\n"
         "        return MMT_IO;\n"
         "    end\n"
         "    else if (addr == LOG_ADDR_SERIAL_INPUT) begin\n"
         "        return MMT_IO;\n"
         "    end\n"
         "    else if (addr == LOG_ADDR_SERIAL_OUTPUT) begin\n"),
        ("    if (logAddr == LOG_ADDR_SERIAL_OUTPUT) begin\n",
         "    if (LOG_ADDR_TOHOST <= logAddr && logAddr < LOG_ADDR_TOHOST + 8) begin\n"
         "        phyAddr.isIO = TRUE;\n"
         "        phyAddr.addr = PHY_ADDR_TOHOST + logAddr[2:0];\n"
         "    end\n"
         "    else if (logAddr == LOG_ADDR_SERIAL_INPUT) begin\n"
         "        phyAddr.isIO = TRUE;\n"
         "        phyAddr.addr = PHY_ADDR_SERIAL_INPUT;\n"
         "    end\n"
         "    else if (logAddr == LOG_ADDR_SERIAL_OUTPUT) begin\n"),
    ],
    "IO/IO_UnitIF.sv": [
        ("    PhyAddrPath ioReadAddrIn;\n",
         "    PhyAddrPath ioReadAddrIn;\n"
         "\n"
         "    // The low word last stored to tohost\n"
         "    DataPath tohost;\n"
         "    // Serial input: {seq, char} from the host, and the seq taken\n"
         "    logic [15:0] serialIn;\n"
         "    logic [7:0] serialInAck;\n"),
        ("        ioReadAddrIn,\n    output\n",
         "        ioReadAddrIn,\n        serialIn,\n    output\n"),
        ("        serialWE,\n        serialWriteDataOut\n    );\n",
         "        serialWE,\n        serialWriteDataOut,\n        tohost,\n        serialInAck\n    );\n"),
    ],
    "IO/IO_Unit.sv": [
        ("    TimerRegsters tmNext;\n",
         "    TimerRegsters tmNext;\n"
         "\n"
         "    // tohost: the low word last stored there\n"
         "    DataPath tohostReg;\n"
         "    // Serial input: the low byte last stored there\n"
         "    logic [7:0] serialInAckReg;\n"
         "    always_ff@(posedge port.clk) begin\n"
         "        if (port.rst) begin\n"
         "            tohostReg <= '0;\n"
         "            serialInAckReg <= '0;\n"
         "        end\n"
         "        else if (port.ioWE && port.ioWriteAddrIn.addr == PHY_ADDR_TOHOST) begin\n"
         "            tohostReg <= port.ioWriteDataIn;\n"
         "        end\n"
         "        else if (port.ioWE && port.ioWriteAddrIn.addr == PHY_ADDR_SERIAL_INPUT) begin\n"
         "            serialInAckReg <= port.ioWriteDataIn[7:0];\n"
         "        end\n"
         "    end\n"
         "    assign port.tohost = tohostReg;\n"
         "    assign port.serialInAck = serialInAckReg;\n"),
        ("        // Read a timer rigister\n        if (phyRawReadAddr == PHY_ADDR_TIMER_LOW) begin\n",
         "        // Read a timer rigister\n"
         "        if (phyRawReadAddr == PHY_ADDR_TOHOST) begin\n"
         "            port.ioReadDataOut = tohostReg;\n"
         "        end\n"
         "        else if (phyRawReadAddr == PHY_ADDR_TOHOST + 4) begin\n"
         "            port.ioReadDataOut = '0;\n"
         "        end\n"
         "        else if (phyRawReadAddr == PHY_ADDR_SERIAL_INPUT) begin\n"
         "            port.ioReadDataOut = {16'h0, port.serialIn};\n"
         "        end\n"
         "        else if (phyRawReadAddr == PHY_ADDR_TIMER_LOW) begin\n"),
    ],
    "Core.sv": [
        ("    logic memAccessWriteBusy,\noutput\n",
         "    logic memAccessWriteBusy,\n    logic [15:0] serialIn,\noutput\n"),
        ("    SerialDataPath serialWriteData\n);\n",
         "    SerialDataPath serialWriteData,\n    DataPath tohost,\n    logic [7:0] serialInAck\n);\n"),
        ("    IO_UnitIF ioUnitIF(clk, rst, rstStart, serialWE, serialWriteData);\n",
         "    IO_UnitIF ioUnitIF(clk, rst, rstStart, serialWE, serialWriteData);\n"
         "    assign tohost = ioUnitIF.tohost;\n"
         "    assign ioUnitIF.serialIn = serialIn;\n"
         "    assign serialInAck = ioUnitIF.serialInAck;\n"),
    ],
}

def make_list(mk, name):
    """The files of `NAME = \\` in a Makefile, up to the first line without
    a trailing backslash."""
    lines = mk.splitlines()
    start = next(i for i, l in enumerate(lines) if re.match(rf"^{name}\s*=", l))
    files = []
    for l in lines[start + 1:]:
        word = l.strip().rstrip("\\").strip()
        if word and not word.startswith("#"):
            files.append(word)
        if not l.rstrip().endswith("\\"):
            break
    return files


def patch(path, src):
    text = path.read_text()
    for old, new in PATCHES.get(str(path.relative_to(src)), []):
        if text.count(old) != 1:
            sys.exit(f"{path}: a patch does not apply: {old.splitlines()[0].strip()}")
        text = text.replace(old, new)
    return text


def expand(path, src, out):
    for line in patch(path, src).splitlines():
        m = INCLUDE.match(line)
        if m and m.group(1) == "BasicMacros.sv":
            continue
        if TIMESCALE.match(line):
            continue
        e = ENDFUNCTION.match(line)
        if e:
            line = e.group(1)
        if m:
            sys.exit(f"{path}: unexpected include: {line.strip()}")
        out.append(line)


def main():
    root = pathlib.Path(sys.argv[1]).resolve()
    src = root / "Processor/Src"
    mk = (src / "Makefiles/CoreSources.inc.mk").read_text()
    files = [f for f in make_list(mk, "TYPES") + make_list(mk, "MODULES")
             if f not in SKIP]

    git = ["git", "-C", str(root)]
    rev = subprocess.run(git + ["rev-parse", "--short", "HEAD"],
                         capture_output=True, text=True).stdout.strip()
    dirty = subprocess.run(git + ["status", "--porcelain", "--", "Processor/Src"],
                           capture_output=True, text=True).stdout.strip()
    if dirty:
        sys.exit(f"{root}: Processor/Src has local changes:\n{dirty}")

    out = [f"// RSD ({rev}), Processor/Src with every `include expanded, and",
           "// patched for tohost and a serial input (PATCHES in the script).",
           "// Written by scripts/flatten.py. Do not edit.",
           "// Copyright 2019- RSD contributors. Apache License 2.0 (LICENSE.RSD)."]
    out += [f"`define {k} {v}".rstrip() for k, v in DEFINES]
    out.append("// ---- BasicMacros.sv")
    out += (src / "BasicMacros.sv").read_text().splitlines()
    for f in files:
        out.append(f"// ---- {f}")
        expand(src / f, src, out)
    # The rest of the design is read after this file: take back the macros
    # with names that are not RSD's own.
    out.append("`undef REF")
    print("\n".join(out))


main()
