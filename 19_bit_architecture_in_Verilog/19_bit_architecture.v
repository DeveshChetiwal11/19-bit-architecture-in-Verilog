module CPU (
    input clk,
    input reset,
    input [18:0] instruction,  // Increased instruction width to accommodate 5-bit opcode
    output reg [18:0] r1,
    input [18:0] r2,
    input [18:0] r3,
    output reg [18:0] PC,
    output reg [18:0] SP,
    input [18:0] memory_data_in,
    output reg [18:0] memory_data_out,
    output reg [18:0] memory_addr,
    output reg memory_we
);

    // Opcode Definitions - Now 5-bit wide
    localparam ADD = 5'b00000;
    localparam SUB = 5'b00001;
    localparam MUL = 5'b00010;
    localparam DIV = 5'b00011;
    localparam AND = 5'b00100;
    localparam OR  = 5'b00101;
    localparam XOR = 5'b00110;
    localparam NOT = 5'b00111;
    localparam INC = 5'b01000;
    localparam DEC = 5'b01001;

    // Control Flow Opcodes
    localparam JMP = 5'b01010;
    localparam BEQ = 5'b01011;
    localparam BNE = 5'b01100;
    localparam CALL = 5'b01101;
    localparam RET = 5'b01110;

    // Memory Access Opcodes
    localparam LD = 5'b01111;
    localparam ST = 5'b10000;

    // Additional Custom Instruction Opcodes
    localparam FFT = 5'b10001;
    localparam ENC = 5'b10010;
    localparam DEC_CUSTOM = 5'b10011;
    localparam SHIFT_LEFT = 5'b10100;
    localparam SHIFT_RIGHT = 5'b10101;
    localparam ROTATE_LEFT = 5'b10110;
    localparam ROTATE_RIGHT = 5'b10111;

    // Internal Signals
    reg [18:0] stack [0:255];
    reg [4:0] opcode;  // Changed to 5-bit
    wire [18:0] result;

    // ALU Module
    ALU alu_unit (
        .r2(r2),
        .r3(r3),
        .opcode(opcode),
        .r1(result)
    );

    // Instruction Execution
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
            SP <= 255;
            memory_we <= 0;
        end else begin
            opcode <= instruction[18:14];  // Updated to 5-bit opcode extraction

            case (opcode)
                // Arithmetic Instructions
                ADD: r1 <= r2 + r3;
                SUB: r1 <= r2 - r3;
                MUL: r1 <= r2 * r3;
                DIV: r1 <= r2 / r3;
                INC: r1 <= r1 + 19'd1;
                DEC: r1 <= r1 - 19'd1;

                // Logical Instructions
                AND: r1 <= r2 & r3;
                OR:  r1 <= r2 | r3;
                XOR: r1 <= r2 ^ r3;
                NOT: r1 <= ~r2;

                // Shift and Rotate Instructions
                SHIFT_LEFT: r1 <= r2 << 1;
                SHIFT_RIGHT: r1 <= r2 >> 1;
                ROTATE_LEFT: r1 <= {r2[17:0], r2[18]};
                ROTATE_RIGHT: r1 <= {r2[0], r2[18:1]};

                // Control Flow Instructions
                JMP: PC <= instruction[13:0];  // Adjusted width due to opcode change

                BEQ: begin
                    if (r1 == r2)
                        PC <= instruction[13:0];
                    else
                        PC <= PC + 1;
                end

                BNE: begin
                    if (r1 != r2)
                        PC <= instruction[13:0];
                    else
                        PC <= PC + 1;
                end

                CALL: begin
                    stack[SP] <= PC + 1;
                    SP <= SP - 1;
                    PC <= instruction[13:0];
                end

                RET: begin
                    SP <= SP + 1;
                    PC <= stack[SP];
                end

                // Memory Access Instructions
                LD: begin
                    memory_addr <= instruction[13:0];
                    r1 <= memory_data_in;
                end

                ST: begin
                    memory_addr <= instruction[13:0];
                    memory_data_out <= r1;
                    memory_we <= 1;
                end

                // Custom Instructions (Placeholders)
                FFT: begin
                    r1 <= memory_data_in; // Placeholder
                end

                ENC: begin
                    r1 <= memory_data_in ^ memory_data_in[13:0]; // Placeholder
                end

                DEC_CUSTOM: begin
                    r1 <= memory_data_in ^ memory_data_in[13:0]; // Placeholder
                end

                default: begin end
            endcase

            if (opcode != JMP && opcode != BEQ && opcode != BNE && opcode != CALL && opcode != RET)
                PC <= PC + 1;
        end
    end
endmodule

module ALU (
    input [18:0] r2,
    input [18:0] r3,
    input [4:0] opcode,  // Changed to 5-bit
    output reg [18:0] r1
);
    // Opcodes - Updated to 5-bit
    localparam ADD = 5'b00000;
    localparam SUB = 5'b00001;
    localparam MUL = 5'b00010;
    localparam DIV = 5'b00011;
    localparam AND = 5'b00100;
    localparam OR  = 5'b00101;
    localparam XOR = 5'b00110;
    localparam NOT = 5'b00111;
    localparam INC = 5'b01000;
    localparam DEC = 5'b01001;

    // Added new shift and rotate opcodes
    localparam SHIFT_LEFT = 5'b10100;
    localparam SHIFT_RIGHT = 5'b10101;
    localparam ROTATE_LEFT = 5'b10110;
    localparam ROTATE_RIGHT = 5'b10111;

    always @(*) begin
        case (opcode)
            // Arithmetic Instructions
            ADD:  r1 = r2 + r3;
            SUB:  r1 = r2 - r3;
            MUL:  r1 = r2 * r3;
            DIV:  r1 = r2 / r3;
            INC:  r1 = r2 + 1;
            DEC:  r1 = r2 - 1;

            // Logical Instructions
            AND:  r1 = r2 & r3;
            OR:   r1 = r2 | r3;
            XOR:  r1 = r2 ^ r3;
            NOT:  r1 = ~r2;

            // New Shift and Rotate Instructions
            SHIFT_LEFT:   r1 = r2 << 1;
            SHIFT_RIGHT:  r1 = r2 >> 1;
            ROTATE_LEFT:  r1 = {r2[17:0], r2[18]};
            ROTATE_RIGHT: r1 = {r2[0], r2[18:1]};

            default: r1 = 19'b0;
        endcase
    end
endmodule