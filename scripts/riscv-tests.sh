#!/usr/bin/env bash
# Runs riscv-tests' isa tests on the board, one at a time, and sums them up
# per suite.
#
#   scripts/riscv-tests.sh [-t SECONDS] [-o FILE] <isa-dir> [PATTERN...]
#
# <isa-dir> is riscv-tests' `share/riscv-tests/isa` after `make install`.
# PATTERN picks tests by file name (shell glob); the default is rv32ui-p-*
# and rv32um-p-*. Run it from the repository root with HIO_REGS naming the
# harness's regs.json if it is not hns/regs.json; HIO picks another hio,
# CROSS another toolchain prefix for nm.
#
# Each test is loaded while the core is held in reset, then released, and
# `o_tohost` is read until the test writes it (-t, default 10 s). This RSD
# sends a store to tohost out as I/O only at 0x8000_1000; a test linked with
# tohost elsewhere is skipped. With -o, one line per test goes to FILE. The
# exit status is 1 when a test did not pass.

set -u

DEFAULT="rv32ui-p-* rv32um-p-*"

timeout=10
out=""
while getopts "t:o:h" opt; do
    case $opt in
        t) timeout=$OPTARG ;;
        o) out=$OPTARG ;;
        *) sed -n '2,18s/^# \{0,1\}//p' "$0"; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
if [ $# -lt 1 ] || [ ! -d "$1" ]; then
    echo "usage: $0 [-t SECONDS] [-o FILE] <riscv-tests isa dir> [PATTERN...]" >&2
    exit 2
fi
dir=$1
shift
patterns=${*:-$DEFAULT}
hio=${HIO:-hio}
# CROSS= (empty) takes the host's nm, which reads RISC-V ELF symbols too.
nm=${CROSS-riscv64-unknown-elf-}nm
if ! command -v "$nm" > /dev/null; then
    echo "$nm is not on PATH. Set CROSS to the toolchain prefix, or CROSS= for the host's nm." >&2
    exit 2
fi

tests=()
for p in $patterns; do
    for f in "$dir"/$p; do
        case $f in *.dump) continue ;; esac
        [ -f "$f" ] && tests+=("$f")
    done
done
if [ ${#tests[@]} -eq 0 ]; then
    echo "no test in $dir matches: $patterns" >&2
    exit 2
fi

# The value of `o_tohost`, as `hio read` prints it.
tohost() {
    "$hio" read o_tohost 2>/dev/null | grep -o '0x[0-9a-f]*' | tail -1
}

[ -n "$out" ] && : > "$out"
declare -A pass total
failed=0
for f in "${tests[@]}"; do
    name=$(basename "$f")
    suite=$(echo "$name" | sed -E 's/^(.*-[pv])-.*/\1/')
    if ! "$nm" "$f" | grep -q '^80001000 . tohost$'; then
        line="skip     $name  (tohost is not at 0x8000_1000)"
        echo "$line"
        [ -n "$out" ] && echo "$line" >> "$out"
        continue
    fi
    total[$suite]=$(( ${total[$suite]:-0} + 1 ))
    log=$(printf 'reset --hold\nload mem %s\nreset --release\n' "$f" | "$hio" run - 2>&1)
    if [ $? -ne 0 ]; then
        line="error    $name  $(echo "$log" | grep -m1 '^error:')"
        failed=1
    else
        value=0x00000000
        end=$((SECONDS + timeout))
        while [ $SECONDS -lt $end ]; do
            value=$(tohost)
            [ "${value:-0x00000000}" != 0x00000000 ] && break
        done
        v=$((value))
        if [ "$v" -eq 1 ]; then
            line="pass     $name"
            pass[$suite]=$(( ${pass[$suite]:-0} + 1 ))
        elif [ "$v" -eq 0 ]; then
            line="timeout  $name"
            failed=1
        else
            line="fail $(printf '%-3s' $((v >> 1))) $name"
            failed=1
        fi
    fi
    echo "$line"
    [ -n "$out" ] && echo "$line" >> "$out"
done

echo
printf '%-24s %s\n' suite passed
for s in $(printf '%s\n' "${!total[@]}" | sort); do
    printf '%-24s %d/%d\n' "$s" "${pass[$s]:-0}" "${total[$s]}"
done
exit $failed
