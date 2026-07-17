#!/usr/bin/env bash
# smoke.sh — verify the yosys bundle/image: version + a trivial synth run.
# Usage: smoke.sh <bundle-dir | image-ref>
set -euo pipefail
T="${1:?usage: smoke.sh <bundle-dir | image-ref>}"
run() { if [ -d "$T" ]; then bash -lc "source '$T/env.sh'; $1"; else docker run --rm "$T" bash -lc "$1"; fi; }

echo ">> version"; run 'yosys --version | head -1'
echo ">> trivial synth"
run 'printf "module t(input a,b, output y); assign y=a&b; endmodule\n" > /tmp/t.v; \
     yosys -q -p "read_verilog /tmp/t.v; synth; stat" >/dev/null 2>&1 && echo "synth OK"'
echo ">> smoke PASSED for $T"
