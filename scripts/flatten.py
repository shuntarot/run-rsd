#!/usr/bin/env python3
"""Writes the RSD core as one SystemVerilog file, with every `include
expanded.

The harness reads the core through `include(inline, ...)` in a Veryl source,
and synthesis gets no include path or macro list, so both are written into
the file. The sources are the packages (TYPES) and modules (MODULES) of
Processor/Src/Makefiles/CoreSources.inc.mk, less the board tops and the
simulation memory. BasicMacros.sv goes in once, at the top.

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


def expand(path, src, out):
    for line in path.read_text().splitlines():
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

    out = [f"// RSD ({rev}), Processor/Src with every `include expanded.",
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
