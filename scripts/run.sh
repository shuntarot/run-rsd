#!/usr/bin/env bash
# Runs a program on the board and prints its serial output.
#
#   scripts/run.sh [-t SECONDS] <elf>
#
# The ELF is loaded while the core is held in reset, then the core is
# released. The serial output is printed as it comes until the program writes
# tohost (rsd_bsp::exit), and the script exits with the program's status: 124
# after -t seconds (default 10) without one. HIO picks another hio. This is
# the runner of `cargo run`.

set -u

timeout=10
while getopts "t:h" opt; do
    case $opt in
        t) timeout=$OPTARG ;;
        *) sed -n '2,10s/^# \{0,1\}//p' "$0"; exit 2 ;;
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

# The value of `o_tohost`, as `hio read` prints it.
tohost() {
    "$hio" read o_tohost | grep -o '0x[0-9a-f]*' | tail -1
}

printf 'reset --hold\nload mem %s\nreset --release\n' "$1" |
    "$hio" run - > /dev/null || exit 1

end=$((SECONDS + timeout))
while :; do
    value=$(tohost) || exit 1
    drain
    [ "${value:-0x00000000}" != 0x00000000 ] && break
    if [ $SECONDS -ge $end ]; then
        echo "timeout: the program did not end in $timeout s" >&2
        exit 124
    fi
done
exit $(( value >> 1 ))
