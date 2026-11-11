# make -C sim    runs asm/smoke.elf on rsd_top in Verilator (5.x)
-include ../local.mk
CROSS     ?= riscv64-unknown-elf-
VERILATOR ?= verilator
AXI       := ../dependencies/std/axi_if/axi_pkg.sv ../dependencies/std/axi_if/axi_if.sv
SV        := ../rtl/rsd_top.sv

run: obj_dir/Vtb smoke.hex
	obj_dir/Vtb

obj_dir/Vtb: tb.sv $(SV)
	$(VERILATOR) --binary --timing -j 8 -Wno-fatal -Wno-lint -Wno-style -Wno-UNOPTFLAT \
		--top-module tb tb.sv $(AXI) $(SV)

$(SV): ../rtl/rsd_top.veryl ../rtl/rsd.sv ../rtl/rsd_axi.sv ../Veryl.lock
	cd .. && veryl build

# 64-bit words, as the memory model holds them
smoke.hex: ../asm/smoke.elf
	$(CROSS)objcopy -O binary $< smoke.bin
	python3 -I -c "import sys; b = open('smoke.bin', 'rb').read(); b += bytes(-len(b) % 8); \
	print('\n'.join('%016x' % int.from_bytes(b[i:i + 8], 'little') for i in range(0, len(b), 8)))" > $@

clean:
	rm -rf obj_dir smoke.bin smoke.hex
