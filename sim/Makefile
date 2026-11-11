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
	rm -rf obj_dir smoke.bin smoke.hex isa

# make -C sim isa ISA=<riscv-tests>/share/riscv-tests/isa
# runs rv32ui-p-* and rv32um-p-* (TESTS picks others) and sums them up. A test
# whose tohost is not at 0x8000_1000, where this RSD reports, is skipped.
ISA   ?=
TESTS ?= rv32ui-p-* rv32um-p-*

isa: obj_dir/Vtb
	@test -n "$(ISA)" || { echo "set ISA=<riscv-tests>/share/riscv-tests/isa"; exit 2; }
	@mkdir -p isa; pass=0; total=0; \
	for f in $(addprefix $(ISA)/,$(TESTS)); do \
		case $$f in *.dump) continue;; esac; \
		n=$$(basename $$f); \
		if ! $(CROSS)nm $$f | grep -q '^80001000 . tohost$$'; then echo "skip     $$n (tohost is not at 0x8000_1000)"; continue; fi; \
		$(CROSS)objcopy -O binary $$f isa/$$n.bin; \
		python3 -I -c "$(HEX64)" isa/$$n.bin > isa/$$n.hex; \
		r=$$(obj_dir/Vtb +isa +hex=isa/$$n.hex | sed -n 's/^tohost //p'); \
		total=$$((total + 1)); \
		if [ "$$r" = 1 ]; then pass=$$((pass + 1)); echo "pass     $$n"; \
		elif [ "$$r" = 0 ]; then echo "timeout  $$n"; \
		else echo "fail $$((r >> 1)) $$n"; fi; \
	done; echo "passed $$pass/$$total"; [ $$pass = $$total ]

HEX64 = import sys; b = open(sys.argv[1], 'rb').read(); b += bytes(-len(b) % 8); \
	print('\n'.join('%016x' % int.from_bytes(b[i:i + 8], 'little') for i in range(0, len(b), 8)))

.PHONY: isa
