#  DESIGN AND SYSTEMVERILOG-BASED VERIFICATION OF A 4-LANE SIMD VECTOR PROCESSOR CORE
 Implemented a 4-lane SIMD processor core for arithmetic and logic operations. Verified RTL using a SystemVerilog testbench with constrained-random stimulus and functional coverage.
## 🧠 Simulation Flow (Using Synopsys VCS & Verdi)

```bash
 1. Compile the Design
Use the following command to compile your design and testbench:
vcs simd.v tb_simd.v -lca -kdb -debug_access+all -full64

2. Run the Simulation
After successful compilation, run the simulation binary:
./simv

3. Generate Coverage Report
To enable coverage collection (line, condition, FSM, toggle, branch, assert, and functional coverage), use:
vcs -sverilog tb_simd_core.sv simd_core.sv -cm line+cond+fsm+tgl+branch+assert+func -cm_dir cov.vdb
This will create a coverage database file:
cov.vdb

4. View Waveforms in Verdi
To open the generated waveform (.vcd) file in Verdi:
verdi *.vcd &

5. View Coverage in Verdi
To visualize and analyze the coverage data (.vdb file) in Verdi:
verdi -cov -covdir cov.vdb &
