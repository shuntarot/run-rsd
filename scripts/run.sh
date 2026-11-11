#!/usr/bin/env bash
# Runs a program on the board, with its serial output and input.
#
#   scripts/run.sh [-t SECONDS] <elf>
#
# The ELF is loaded while the core is held in reset, then the core is
# released. The serial output is printed as it comes, and what is typed (or
# piped in) goes to the serial input, until the program writes tohost
# (rsd_bsp::exit). The script then exits with the program's status. Ctrl-C
# leaves; -t gives up after SECONDS with status 124. HIO picks another hio.
# This is the runner of `cargo run`.

set -u
export LC_ALL=C

timeout=0
while getopts "t:h" opt; do
    case $opt in
        t) timeout=$OPTARG ;;
        *) sed -n '2,11s/^# \{0,1\}//p' "$0"; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
if [ $# -lt 1 ] || [ ! -f "$1" ]; then
    echo "usage: $0 [-t SECONDS] <elf>" >&2
    exit 2
fi
hio=${HIO:-hio}

# Prints what waits in the serial output's FIFO. Read as numbers: --text
# would end a partial line with a newline of its own.
drain() {
    local h
    "$hio" drain uart |
        sed -n 's/^ *[0-9]* *0x000000\([0-9a-f][0-9a-f]\)$/\1/p' |
        while read -r h; do printf '%b' "\\x$h"; done
}

# A register's value, as `hio read` prints it.
reg() {
    "$hio" read "$1" | grep -o '0x[0-9a-f]*' | tail -1
}

# Keys go through one at a time and are not echoed here: the program echoes.
if [ -t 0 ]; then
    saved=$(stty -g)
    trap 'stty "$saved"' EXIT
    trap 'exit 130' INT
    stty -icanon -echo
fi

# i_rx keeps its value over a reset of the core: start it from seq 0, as the
# program does.
printf 'reset --hold\nwrite i_rx 0\nload mem %s\nreset --release\n' "$1" |
    "$hio" run - > /dev/null || exit 1

seq=0       # the seq of the last character given to the program
pending=""  # typed, not given yet
input=1     # stdin is open
end=$((SECONDS + timeout))
while :; do
    value=$(reg o_tohost) || exit 1
    drain
    [ "${value:-0x00000000}" != 0x00000000 ] && break
    if [ "$timeout" != 0 ] && [ $SECONDS -ge $end ]; then
        echo "timeout: the program did not end in $timeout s" >&2
        exit 124
    fi

    while [ $input = 1 ]; do
        IFS= read -r -N1 -t 0.01 ch
        status=$?
        if [ $status = 0 ]; then
            pending+=$ch
            continue
        fi
        # Above 128: nothing more for now. Otherwise the input has ended.
        [ $status -le 128 ] && input=0
        break
    done
    # The next character, once the program has taken the last one.
    if [ -n "$pending" ] && [ $(( $(reg o_rx_ack) )) -eq $seq ]; then
        printf -v code '%d' "'${pending:0:1}"
        pending=${pending:1}
        seq=$(( (seq + 1) & 0xff ))
        "$hio" write i_rx $(( (seq << 8) | (code & 0xff) )) > /dev/null || exit 1
    fi
done
exit $(( value >> 1 ))
