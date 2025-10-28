`timescale 1ns/1ps

// ==========================
// TESTBENCH FOR SIMD CORE
// ==========================
module tb_simd_core;

    parameter WIDTH = 32;
    parameter LANES = 4;

    logic clk, rst;
    logic [2:0] opcode;
    logic signed [WIDTH-1:0] A [0:LANES-1];
    logic signed [WIDTH-1:0] B [0:LANES-1];
    logic signed [WIDTH-1:0] R [0:LANES-1];

    // Instantiate DUT
    simd_core #(WIDTH, LANES) DUT (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .A(A),
        .B(B),
        .R(R)
    );

    // -----------------------------------------------
    // Clock generation
    // -----------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ==================================================
    //  Functional Coverage 
    // ==================================================
    logic signed [1:0] A_sign;
    logic signed [1:0] B_sign;

    always_comb begin
        if (A[0] > 0)      A_sign = 1;
        else if (A[0] < 0) A_sign = -1;
        else               A_sign = 0;

        if (B[0] > 0)      B_sign = 1;
        else if (B[0] < 0) B_sign = -1;
        else               B_sign = 0;
    end

    covergroup simd_cov;
        // Opcode bins
        coverpoint opcode {
            bins add  = {3'b000};
            bins sub  = {3'b001};
            bins and_ = {3'b010};
            bins or_  = {3'b011};
            bins mul  = {3'b100};
            illegal_bins illegal_opcode = {[3'b101:3'b111]};
        }

        // Operand sign bins
        coverpoint A_sign {
            bins neg  = {-1};
            bins zero = {0};
            bins pos  = {1};
        }

        coverpoint B_sign {
            bins neg  = {-1};
            bins zero = {0};
            bins pos  = {1};
        }

        // Cross coverage
        opcode_x_sign: cross opcode, A_sign, B_sign;
    endgroup

    simd_cov cov_inst = new();

    // ==================================================
    // Self-checking task
    // ==================================================
    task automatic check_result(
        input [2:0] op,
        input logic signed [WIDTH-1:0] A_ref [0:LANES-1],
        input logic signed [WIDTH-1:0] B_ref [0:LANES-1],
        input logic signed [WIDTH-1:0] R_dut [0:LANES-1]
    );
        logic signed [WIDTH-1:0] expected;
        string op_name;
        begin
            case (op)
                3'b000: op_name = "ADD";
                3'b001: op_name = "SUB";
                3'b010: op_name = "AND";
                3'b011: op_name = "OR";
                3'b100: op_name = "MUL";
                default: op_name = "ILLEGAL";
            endcase

            $display("---- Operation: %s (opcode=%b) ----", op_name, op);
            for (int i = 0; i < LANES; i++) begin
                case (op)
                    3'b000: expected = A_ref[i] + B_ref[i];
                    3'b001: expected = A_ref[i] - B_ref[i];
                    3'b010: expected = A_ref[i] & B_ref[i];
                    3'b011: expected = A_ref[i] | B_ref[i];
                    3'b100: expected = A_ref[i] * B_ref[i];
                    default: expected = 32'hDEADBEEF;
                endcase

                if (R_dut[i] !== expected)
                    $display("ERROR: Lane %0d | A=%0d | B=%0d | %s | Expected=%0d | Got=%0d",
                             i, A_ref[i], B_ref[i], op_name, expected, R_dut[i]);
                else
                    $display("PASS : Lane %0d | A=%0d | B=%0d | %s | Result=%0d",
                             i, A_ref[i], B_ref[i], op_name, R_dut[i]);
            end
            $display("--------------------------------------\n");
        end
    endtask

    // ==================================================
    // Simulation Sequence
    // ==================================================
    initial begin
        $display("==== SIMD Core Simulation Started ====");
        $dumpfile("simd_core.vcd");
        $dumpvars(0, tb_simd_core);

        rst = 1;
        opcode = 0;
        #10 rst = 0;

        // ---------------- Directed tests ----------------
        $display("\n===== Directed Testing Phase =====");
        A = '{10, 20, 30, 40};
        B = '{1, 2, 3, 4};

        for (int op = 0; op <= 4; op++) begin
            opcode = op;
            @(posedge clk); @(posedge clk);
            cov_inst.sample();
            check_result(opcode, A, B, R);
        end

        // ---------------- Sign Coverage Phase ----------------
        $display("\n===== Enhanced Sign Coverage Phase =====");
        for (int op = 0; op <= 4; op++) begin
            opcode = op;

            // Case 1: Both Positive
            A = '{10, 10, 10, 10};
            B = '{5, 5, 5, 5};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();

            // Case 2: Both Negative
            A = '{-10, -10, -10, -10};
            B = '{-5, -5, -5, -5};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();

            // Case 3: Both Zero
            A = '{0, 0, 0, 0};
            B = '{0, 0, 0, 0};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();

            // Case 4: A positive, B negative
            A = '{10, 20, 30, 40};
            B = '{-1, -2, -3, -4};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();

            // Case 5: A negative, B positive
            A = '{-10, -20, -30, -40};
            B = '{5, 5, 5, 5};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();

            // Case 6: A zero, B positive
            A = '{0, 0, 0, 0};
            B = '{5, 5, 5, 5};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();

            // Case 7: A positive, B zero
            A = '{10, 10, 10, 10};
            B = '{0, 0, 0, 0};
            @(posedge clk); @(posedge clk);
            cov_inst.sample();
        end

        // ---------------- Randomized Testing Phase ----------------
        $display("\n===== Randomized Testing Phase ======");
        repeat (200) begin
            opcode = $urandom_range(0, 4);
            for (int i = 0; i < LANES; i++) begin
                int sel = $urandom_range(0, 9);
                if (sel == 0)
                    A[i] = 0;
                else if (sel < 5)
                    A[i] = $urandom_range(-100, -1);
                else
                    A[i] = $urandom_range(1, 100);

                sel = $urandom_range(0, 9);
                if (sel == 0)
                    B[i] = 0;
                else if (sel < 5)
                    B[i] = $urandom_range(-100, -1);
                else
                    B[i] = $urandom_range(1, 100);
            end

            @(posedge clk); @(posedge clk);
            cov_inst.sample();
            check_result(opcode, A, B, R);
        end

        // ---------------- Coverage Completion Phase ----------------
        $display("\n===== Coverage Completion Phase =====");

        // Existing coverage close cases
        opcode = 3'b001; A = '{-10, -20, -30, -40}; B = '{0, 0, 0, 0}; @(posedge clk); cov_inst.sample(); // SUB, A neg, B zero
        opcode = 3'b010; A = '{-10, -20, -30, -40}; B = '{0, 0, 0, 0}; @(posedge clk); cov_inst.sample(); // AND, A neg, B zero
        opcode = 3'b011; A = '{-10, -20, -30, -40}; B = '{0, 0, 0, 0}; @(posedge clk); cov_inst.sample(); // OR, A neg, B zero
        opcode = 3'b010; A = '{0, 0, 0, 0}; B = '{-10, -20, -30, -40}; @(posedge clk); cov_inst.sample(); // AND, A zero, B neg
        opcode = 3'b011; A = '{0, 0, 0, 0}; B = '{-10, -20, -30, -40}; @(posedge clk); cov_inst.sample(); // OR, A zero, B neg

        // Added to close last uncovered bin
        opcode = 3'b001; A = '{0, 0, 0, 0}; B = '{-5, -5, -5, -5}; @(posedge clk); cov_inst.sample(); // SUB, A zero, B neg

        $display("==== SIMD Core Verification Complete! ====");
        $finish;
    end

    // ==================================================
    // Assertion for illegal opcode
    // ==================================================
    always @(posedge clk) begin
        assert (opcode <= 3'b100)
        else $error("Illegal opcode detected: %0b", opcode);
    end

endmodule

