`timescale 1ns/1ps

// ==========================
// SIMD CORE
// ==========================
module simd_core #(
    parameter WIDTH = 32,
    parameter LANES = 4
)(
    input  logic clk,
    input  logic rst,
    input  logic [2:0] opcode,                      // 000=ADD,001=SUB,010=AND,011=OR,100=MUL
    input  logic signed [WIDTH-1:0] A [0:LANES-1],
    input  logic signed [WIDTH-1:0] B [0:LANES-1],
    output logic signed [WIDTH-1:0] R [0:LANES-1]
);

    integer i;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < LANES; i++)
                R[i] <= '0;
        end
        else begin
            for (i = 0; i < LANES; i++) begin
                case (opcode)
                    3'b000: R[i] <= A[i] + B[i]; // ADD
                    3'b001: R[i] <= A[i] - B[i]; // SUB
                    3'b010: R[i] <= A[i] & B[i]; // AND
                    3'b011: R[i] <= A[i] | B[i]; // OR
                    3'b100: R[i] <= A[i] * B[i]; // MUL
                    default: R[i] <= 32'hDEADBEEF; // Illegal opcode
                endcase
            end
        end
    end

endmodule
