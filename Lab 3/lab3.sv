`ifndef _core_v
`define _core_v
`include "system.sv"
`include "base.sv"
`include "memory_io.sv"
`include "memory.sv"

/*

This is a very simple 6 stage multicycle RISC-V 32bit design.

The stages are fetch, decode, execute, memory, memory, writeback

*/

`include "base.sv"
`include "system.sv"
`include "memory_io.sv"


module core(
    input logic       clk
    ,input logic      reset
    ,input logic      [`word_address_size-1:0] reset_pc
    ,output memory_io_req   inst_mem_req
    ,input  memory_io_rsp   inst_mem_rsp
    ,output memory_io_req   data_mem_req
    ,input  memory_io_rsp   data_mem_rsp
    );

`include "riscv32_common.sv"

typedef enum {
    stage_fetch
    ,stage_decode
    ,stage_execute
    ,stage_mem
    ,stage_writeback
}   stage;

stage   current_stage;


word_address    pc;

assign inst_mem_req.addr = pc;
assign inst_mem_req.valid = inst_mem_rsp.ready && (stage_fetch == current_stage);
assign inst_mem_req.do_read = (stage_fetch == current_stage) ? 4'b1111 : 0;

instr32    latched_instruction_read;
always_ff @(posedge clk) begin
    if (inst_mem_rsp.valid) begin
        latched_instruction_read <= inst_mem_rsp.data;
    end

end

instr32    fetched_instruction;
assign fetched_instruction = (inst_mem_rsp.valid) ? inst_mem_rsp.data : latched_instruction_read;

tag     rs1;
tag     rs2;
word    rd1;
word    rd2;
tag     wbs;
word    wbd;
logic   wbv;
word    reg_file_rd1;
word    reg_file_rd2;
word    imm;
funct3  f3;
funct7  f7;
opcode_q op_q;
instr_format format;

word    reg_file[0:31];

always @(fetched_instruction) begin
    rs1 = decode_rs1(fetched_instruction);
    rs2 = decode_rs2(fetched_instruction);
    wbs = decode_rd(fetched_instruction);
    f3 = decode_funct3(fetched_instruction);
    op_q = decode_opcode_q(fetched_instruction);
    format = decode_format(op_q);
    imm = decode_imm(fetched_instruction, format);
    wbv = decode_writeback(op_q);
    f7 = decode_funct7(fetched_instruction, format);
end

logic read_reg_valid;
logic write_reg_valid;

always_ff @(posedge clk) begin
    if (read_reg_valid) begin
        reg_file_rd1 <= reg_file[rs1];
        reg_file_rd2 <= reg_file[rs2];
    end
    else if (write_reg_valid)
        reg_file[wbs] <= wbd;
end

always_comb begin
    read_reg_valid = false;
    write_reg_valid = false;
    if (current_stage == stage_decode) begin
        read_reg_valid = true;
    end

    if (current_stage == stage_writeback && wbv) begin
        write_reg_valid = true;
    end
end

always_comb begin
    if (rs1 == `tag_size'd0)
        rd1 = `word_size'd0;
    else
        rd1 = reg_file_rd1;        
    if (rs2 == `tag_size'd0)
        rd2 = `word_size'd0;
    else
        rd2 = reg_file_rd2;        
end

ext_operand exec_result_comb;
word next_pc_comb;
always @(*) begin
    exec_result_comb = execute(
        cast_to_ext_operand(rd1),
        cast_to_ext_operand(rd2),
        cast_to_ext_operand(imm),
        pc,
        op_q,
        f3,
        f7);
    next_pc_comb = pc + 4;
end

word exec_result;
word next_pc;
always_ff @(posedge clk) begin
    if (current_stage == stage_execute) begin
        exec_result <= exec_result_comb[`word_size-1:0];
        next_pc <= next_pc_comb;
    end
end

// Added stuff
always_comb begin
    // Default values
    data_mem_req = memory_io_no_req32;
    data_mem_req.addr = exec_result;
    data_mem_req.valid = (current_stage == stage_mem);

    case (op_q)
        q_load: begin
            data_mem_req.do_read = 4'b1111; // Assuming we're dealing with full word load (LW)
        end
        q_store: begin
            data_mem_req.do_write = 4'b1111; // Assuming we're dealing with full word store (SW)
            data_mem_req.data = rd2;
        end
        // Handle other load/store variants (LB, SB) similarly...
    endcase
end

always_ff @(posedge clk) begin
    if (current_stage == stage_mem && data_mem_rsp.valid) begin
        if (op_q == q_load) begin
            wbd <= data_mem_rsp.data; // Load the data into the destination register
        end
    end
end
// end of added stuff

always_comb begin
    wbd = exec_result;
end

always_ff @(posedge clk) begin
    if (reset)
        pc <= reset_pc;
    else begin
        if (current_stage == stage_writeback)
            pc <= next_pc;
    end
end

always_ff @(posedge clk) begin
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
            default:
                current_stage <= stage_fetch;
        endcase
    end
end

endmodule : core
`endif
