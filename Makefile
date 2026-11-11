# make rsd       flatten the RSD sources into rtl/rsd.sv
# make asm       build asm/smoke.elf
# make sim       run asm/smoke.elf on rsd_top in Verilator (5.x)
#
# Tool and checkout locations default to PATH and a sibling RSD clone.
# Put anything specific to your machine in local.mk (not committed):
#
#   RSD       = /path/to/RSD
#   VERILATOR = /path/to/verilator/bin/verilator
#   CROSS     = /path/to/riscv64-unknown-elf-

-include local.mk
RSD ?= ../RSD

.PHONY: rsd asm sim

rsd:
	python3 -I scripts/flatten.py $(RSD) > rtl/rsd.sv

asm:
	$(MAKE) -C asm

sim:
	$(MAKE) -C sim
