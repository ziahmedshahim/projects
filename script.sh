#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION -------------------------------------------------------------
# Change these if your filenames or top-level name differ
TOP_MODULE=UART
OUTPUT_EXE=simv
SOURCE_FILES="design.sv tx.sv rx.sv tb.sv"

# --- CLEAN UP -------------------------------------------------------------------
echo "Cleaning previous run..."
rm -rf $OUTPUT_EXE csrc ucli.key simv.daidir *.log

# --- COMPILE -------------------------------------------------------------------
echo "Compiling $TOP_MODULE..."
vcs -full64 -sverilog $SOURCE_FILES \
    -ntb_opts uvm-1.2 \
    -debug_access+all \
    -o $OUTPUT_EXE

echo "Compilation successful."

# --- SIMULATE ------------------------------------------------------------------
echo "Running simulation..."
./$OUTPUT_EXE +verbose -l simulation.log

echo "Simulation complete.  Logs ? simulation.log"

# --- OPTIONAL: WAVEFORM VIEWER ------------------------------------------------
 #If your testbench dumps a VCD or FSDB, you can launch GTKWave or Verdi:
 gtkwave waveform.vcd &
 verdi -vpd dump.vpd &


