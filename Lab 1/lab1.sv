function void print_instruction(input logic [31:0] pc, input logic [31:0] instruction);
    // Extract instruction fields
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [11:0] imm12;       // Immediate for I-Type
    logic [19:0] imm20;       // Immediate for U-Type
    logic signed [31:0] imm_j; // Immediate for J-Type
    logic signed [31:0] imm_b; // Immediate for B-Type
    logic signed [31:0] imm_s; // Immediate for S-Type

    // Decode the instruction fields
    opcode = instruction[6:0];
    rd = instruction[11:7];
    funct3 = instruction[14:12];
    rs1 = instruction[19:15];
    rs2 = instruction[24:20];
    funct7 = instruction[31:25];
    imm12 = instruction[31:20];
    imm20 = instruction[31:12];
    imm_j = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
    imm_b = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    imm_s = {instruction[31:25], instruction[11:7]};

    // Print PC and instruction
    $write("%08x: %08x    ", pc, instruction);

    // Decode and handle each opcode
    case (opcode)
        // ------------------- R-Type Instructions -------------------
        7'b0110011: begin
            case (funct3)
                3'b000: $write("%s x%0d, x%0d, x%0d\n", 
                               (funct7 == 7'b0000000) ? "add" : "sub",
                               rd, rs1, rs2);
                3'b001: $write("sll x%0d, x%0d, x%0d\n", rd, rs1, rs2);
                3'b010: $write("slt x%0d, x%0d, x%0d\n", rd, rs1, rs2); // Set less than
                3'b011: $write("sltu x%0d, x%0d, x%0d\n", rd, rs1, rs2); // Set less than unsigned
                3'b100: $write("xor x%0d, x%0d, x%0d\n", rd, rs1, rs2);
                3'b101: $write("%s x%0d, x%0d, %0d\n", 
                               (funct7 == 7'b0000000) ? "srl" : "sra",
                               rd, rs1, rs2); // Shift right logical/arithmetic
                3'b110: $write("or x%0d, x%0d, x%0d\n", rd, rs1, rs2);
                3'b111: $write("and x%0d, x%0d, x%0d\n", rd, rs1, rs2);
                default: $write("Unknown R-Type Instruction\n");
            endcase
        end
        // ------------------- I-Type Instructions -------------------
        7'b0010011: begin
            case (funct3)
                3'b000: $write("addi x%0d, x%0d, %0d\n", rd, rs1, $signed(imm12));
                3'b001: $write("slli x%0d, x%0d, %0d\n", rd, rs1, instruction[24:20]); // Shift left logical
                3'b010: $write("slti x%0d, x%0d, %0d\n", rd, rs1, $signed(imm12)); // Set less than immediate
                3'b011: $write("sltiu x%0d, x%0d, %0d\n", rd, rs1, $signed(imm12)); // Set less than immediate unsigned
                3'b100: $write("xori x%0d, x%0d, %0d\n", rd, rs1, $signed(imm12));
                3'b101: $write("%s x%0d, x%0d, %0d\n",
                               (instruction[31:25] == 7'b0000000) ? "srli" : "srai",
                               rd, rs1, instruction[24:20]); // Shift right logical/arithmetic immediate
                3'b110: $write("ori x%0d, x%0d, %0d\n", rd, rs1, $signed(imm12));
                3'b111: $write("andi x%0d, x%0d, %0d\n", rd, rs1, $signed(imm12));
                default: $write("Unknown I-Type Instruction\n");
            endcase
        end
        // ------------------- Miscellaneous Instructions -------------------
        7'b0001111: begin
            case (funct3)
                3'b000: $write("fence\n"); // Fence instruction
                default: $write("Unknown Miscellaneous Instruction\n");
            endcase
        end
        // ------------------- System Instructions -------------------
        7'b1110011: begin
            if (instruction[31:20] == 12'b0)
                $write("ecall\n"); // Environment call
            else if (instruction[31:20] == 12'b000000000001)
                $write("ebreak\n"); // Breakpoint
            else
                $write("Unknown System Instruction\n");
        end
        // ------------------- Load Instructions -------------------
        7'b0000011: begin
            case (funct3)
                3'b000: $write("lb x%0d, %0d(x%0d)\n", rd, $signed(imm12), rs1); // Load byte
                3'b001: $write("lh x%0d, %0d(x%0d)\n", rd, $signed(imm12), rs1); // Load halfword
                3'b010: $write("lw x%0d, %0d(x%0d)\n", rd, $signed(imm12), rs1); // Load word
                3'b100: $write("lbu x%0d, %0d(x%0d)\n", rd, $signed(imm12), rs1); // Load byte unsigned
                3'b101: $write("lhu x%0d, %0d(x%0d)\n", rd, $signed(imm12), rs1); // Load halfword unsigned
                default: $write("Unknown Load Instruction\n");
            endcase
        end
        // ------------------- Store Instructions -------------------
        7'b0100011: begin
            case (funct3)
                3'b000: $write("sb x%0d, %0d(x%0d)\n", rs2, $signed(imm_s), rs1); // Store byte
                3'b001: $write("sh x%0d, %0d(x%0d)\n", rs2, $signed(imm_s), rs1); // Store halfword
                3'b010: $write("sw x%0d, %0d(x%0d)\n", rs2, $signed(imm_s), rs1); // Store word
                default: $write("Unknown Store Instruction\n");
            endcase
        end
        // ------------------- Branch Instructions -------------------
        7'b1100011: begin
            case (funct3)
                3'b000: $write("beq x%0d, x%0d, %0d\n", rs1, rs2, $signed(imm_b)); // Branch if equal
                3'b001: $write("bne x%0d, x%0d, %0d\n", rs1, rs2, $signed(imm_b)); // Branch if not equal
                3'b100: $write("blt x%0d, x%0d, %0d\n", rs1, rs2, $signed(imm_b)); // Branch if less than
                3'b101: $write("bge x%0d, x%0d, %0d\n", rs1, rs2, $signed(imm_b)); // Branch if greater than or equal
                3'b110: $write("bltu x%0d, x%0d, %0d\n", rs1, rs2, $signed(imm_b)); // Branch if less than unsigned
                3'b111: $write("bgeu x%0d, x%0d, %0d\n", rs1, rs2, $signed(imm_b)); // Branch if greater or equal unsigned
                default: $write("Unknown Branch Instruction\n");
            endcase
        end
        // ------------------- Jump Instructions -------------------
        7'b1101111: $write("jal x%0d, %0d\n", rd, $signed(imm_j)); // JAL
        7'b1100111: $write("jalr x%0d, %0d(x%0d)\n", rd, $signed(imm12), rs1); // JALR
        // ------------------- U-Type Instructions -------------------
        7'b0110111: $write("lui x%0d, 0x%x\n", rd, imm20);         // Load upper immediate
        7'b0010111: $write("auipc x%0d, 0x%x\n", rd, imm20);       // Add upper immediate to PC
        default: $write("Unknown Instruction\n");
    endcase
endfunction
