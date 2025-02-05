`ifndef _core_v
`define _core_v
`include "system.sv"
`include "base.sv"
`include "memory_io.sv"
`include "memory.sv"


module core(
    input logic       clk
    ,input logic      reset
    ,input logic      [`word_address_size-1:0] reset_pc
    ,output memory_io_req   inst_mem_req
    ,input  memory_io_rsp   inst_mem_rsp
    ,output memory_io_req   data_mem_req
    ,input  memory_io_rsp   data_mem_rsp
    );

typedef enum {
    stage_fetch
    ,stage_decode
    ,stage_execute
    ,stage_mem
    ,stage_writeback
}   stage;

stage   current_stage;

// program counter and instruction memory
word pc;
word instruction;        // Holds fetched instruction

// Register file and intermediate values
word regfile[0:31];      // 32 general-purpose registers
word rs1_data, rs2_data; // Source register values
word imm;                // Immediate value
word alu_result;         // ALU computation result

// Instruction fields
logic [6:0] opcode;
logic [4:0] rd, rs1, rs2;
logic [2:0] funct3;
logic [6:0] funct7;
logic [19:0] imm20;  // Immediate for U-Type instructions

always_comb begin
    if (current_stage == stage_fetch) begin
        inst_mem_req.addr = pc;          // Fetch instruction at PC
        inst_mem_req.do_read = 4'b1111; // Read all 4 bytes
        inst_mem_req.valid = 1'b1;      // Request is valid
    end else begin
        inst_mem_req.valid = 1'b0;      // Default: no request
    end
end

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        pc <= reset_pc;                 // Initialize PC on reset
    else if (current_stage == stage_writeback)
        pc <= pc + 4;                   // Increment PC for next instruction
end

// Decode stage
always_comb begin
    if (current_stage == stage_decode) begin
        instruction = inst_mem_rsp.data;  // Fetch instruction from memory response
        opcode = instruction[6:0];       // Extract opcode
        rd     = instruction[11:7];      // Destination register
        funct3 = instruction[14:12];     // function 3 bits 
        rs1    = instruction[19:15];     // Source register 1
        rs2    = instruction[24:20];     // Source register 2
        funct7 = instruction[31:25];     // function 7 bits
        imm    = $signed(instruction[31:20]); // Sign-extended immediate value
        imm20  = instruction[31:12];     // Immediate for U-Type (AUIPC)
        rs1_data = regfile[rs1];         // Read data from rs1
        rs2_data = regfile[rs2];         // Read data from rs2
    end
end

// Execute stage
always_comb begin
    if (current_stage == stage_execute) begin
        case (opcode)
            7'b0110111: alu_result = {imm20, 12'b0};  // LUI: Load upper immediate
            7'b0010111: alu_result = pc + {imm20, 12'b0}; // AUIPC: PC + (imm << 12)
            default: begin
                case (funct3)
                    3'b000: alu_result = (funct7 == 7'b0100000) ? rs1_data - rs2_data : rs1_data + rs2_data; // ADD/SUB
                    3'b001: alu_result = rs1_data << rs2_data[4:0]; // SLL (Shift Left Logical)
                    3'b101: alu_result = (funct7 == 7'b0100000) ? $signed(rs1_data) >>> rs2_data[4:0] : rs1_data >> rs2_data[4:0]; // SRA/SRL
                    default: alu_result = 32'b0;
                endcase
            end
        endcase
    end
end

// Writeback stage
always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 32; i++) begin
            regfile[i] <= 32'b0; // Reset registers
        end
    end else if (current_stage == stage_writeback) begin
        if (opcode == 7'b0110111 || opcode == 7'b0010111 || opcode == 7'b0110011 || opcode == 7'b0010011) begin
            regfile[rd] <= alu_result; // Write ALU result to register file
        end
    end
end

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        current_stage <= stage_fetch;
    else begin
        case (current_stage)
            stage_fetch:
                current_stage <= stage_decode;
            stage_decode:
                current_stage <= stage_execute;
            stage_execute:
                current_stage <= stage_mem;
            stage_mem:
                current_stage <= stage_writeback;
            stage_writeback:
                current_stage <= stage_fetch;
            default: begin
                $display("Should never get here");
                current_stage <= stage_fetch;
            end
        endcase
    end
end


endmodule

`endif
