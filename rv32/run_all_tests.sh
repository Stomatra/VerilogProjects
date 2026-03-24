#!/usr/bin/env bash
# run_all_tests.sh
# Batch-run all RV32I instruction unit tests and print a PASS/FAIL report.
#
# Usage:
#   cd rv32/
#   bash run_all_tests.sh
#
# Requirements: iverilog + vvp in PATH (Icarus Verilog)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SIM_DIR="sim"
VVP="$SIM_DIR/tb_rv32.vvp"
TESTS_DIR="tests"

mkdir -p "$SIM_DIR"

echo "=============================================="
echo " RV32I Instruction Unit Test Suite"
echo "=============================================="
echo ""

# ---- Compile ----
echo "[INFO] Compiling testbench..."
iverilog -g2012 -o "$VVP" -I rtl rtl/*.v tb/tb_rv32.v 2>&1 \
  | grep -v "^$" | grep -E "error:|warning:" || true

if [ ! -f "$VVP" ]; then
    echo "[ERROR] Compilation failed – aborting."
    exit 1
fi
echo "[INFO] Compilation OK"
echo ""

# ---- Run tests ----
PASS=0
FAIL=0
TIMEOUT=0
FAIL_LIST=()

for hex_file in "$TESTS_DIR"/*.hex; do
    name=$(basename "$hex_file" .hex)
    output=$(vvp "$VVP" "+hex=$hex_file" 2>/dev/null)
    tb_line=$(echo "$output" | grep '\[TB\]' | tail -1)

    if echo "$tb_line" | grep -q "PASS"; then
        printf "  %-12s  PASS\n" "$name"
        PASS=$((PASS + 1))
    elif echo "$tb_line" | grep -q "FAIL"; then
        printf "  %-12s  FAIL  (%s)\n" "$name" "$tb_line"
        FAIL=$((FAIL + 1))
        FAIL_LIST+=("$name")
    else
        printf "  %-12s  TIMEOUT\n" "$name"
        TIMEOUT=$((TIMEOUT + 1))
        FAIL_LIST+=("$name(timeout)")
    fi
done

TOTAL=$((PASS + FAIL + TIMEOUT))

echo ""
echo "=============================================="
echo " Results: $PASS/$TOTAL PASS"
if [ ${#FAIL_LIST[@]} -gt 0 ]; then
    echo " Failed:  ${FAIL_LIST[*]}"
fi
echo "=============================================="

# Exit non-zero if any test failed
[ $((FAIL + TIMEOUT)) -eq 0 ]
