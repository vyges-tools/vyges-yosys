#!/usr/bin/env bash
# smoke.sh — verify the yosys synthesis bundle: yosys + yosys-abc + sta (OpenSTA).
# Usage: smoke.sh <bundle-dir | image-ref>
set -euo pipefail
T="${1:?usage: smoke.sh <bundle-dir | image-ref>}"
run() { if [ -d "$T" ]; then bash -lc "source '$T/env.sh'; $1"; else docker run --rm "$T" bash -lc "$1"; fi; }

echo ">> yosys version"; run 'yosys --version | head -1'
echo ">> yosys-abc present"; run 'yosys-abc -q "version" 2>/dev/null | head -1 || command -v yosys-abc'
echo ">> OpenSTA (sta) present"; run 'echo "exit" | sta -no_init -no_splash 2>&1 | grep -iE "opensta|[0-9]+\.[0-9]+" | head -1 || command -v sta'
echo ">> trivial synth"
run 'printf "module t(input a,b, output y); assign y=a&b; endmodule\n" > /tmp/t.v; yosys -q -p "read_verilog /tmp/t.v; synth; stat" >/dev/null 2>&1 && echo "synth OK"'
echo ">> smoke PASSED for $T"
