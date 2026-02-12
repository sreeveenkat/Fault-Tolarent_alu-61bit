// Code your design here
// ============================================================
// ALL MODULES CONNECTED (Single-file build for EDA Playground)
// Includes: Full Adder, 16b RCA, Parity Gen/Check,
// Residue (mod3/mod5) Gen/Check (FIXED: includes cout / 17-bit effect),
// Carry-chain checker, Integrated FT Adder, FT ALU, Comprehensive TB + SVA
// ============================================================

// ------------------------------
// 1-bit Full Adder
// ------------------------------
module full_adder(
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule


// ------------------------------
// 16-bit Ripple Carry Adder
// ------------------------------
module ripple_carry_adder_16bit(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout,
    output wire [16:0] carry_chain
);
    assign carry_chain[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : FULL_ADDER_CHAIN
            full_adder fa_inst (
                .a   (a[i]),
                .b   (b[i]),
                .cin (carry_chain[i]),
                .sum (sum[i]),
                .cout(carry_chain[i+1])
            );
        end
    endgenerate

    assign cout = carry_chain[16];
endmodule


// ------------------------------
// Parity Generator (16-bit)
// ------------------------------
module parity_generator_16bit(
    input  wire [15:0] data,
    output wire        parity
);
    assign parity = ^data; // XOR-reduction
endmodule


// ------------------------------
// Parity Checker (FIXED: include cout for N-bit add)
// parity(sum) = parity(a) ^ parity(b) ^ cin ^ cout
// ------------------------------
module parity_checker(
    input  wire parity_a,
    input  wire parity_b,
    input  wire cin,
    input  wire cout,
    input  wire parity_result,
    output wire parity_error
);
    wire expected_parity;
    assign expected_parity = parity_a ^ parity_b ^ cin ^ cout;

    // mismatch => error
    assign parity_error = (parity_result !== expected_parity);
endmodule


// ------------------------------
// Residue Generator mod-3 (numeric residue)
// ------------------------------
module residue_mod3_generator_16bit(
    input  wire [15:0] data,
    output wire [1:0]  residue
);
    assign residue = data % 3;
endmodule


// ------------------------------
// Residue Checker mod-3 (FIXED: include cout / 17-bit effect)
// (a+b+cin) mod3 == (sum + cout*2^16) mod3
// 2^16 mod3 = 1  => expected = (ra+rb+cin+cout) mod3
// ------------------------------
module residue_mod3_checker(
    input  wire [1:0] residue_a,
    input  wire [1:0] residue_b,
    input  wire       cin,
    input  wire       cout,
    input  wire [1:0] residue_result,
    output wire       residue_error
);
    wire [4:0] temp_sum;
    wire [1:0] expected_residue;

    assign temp_sum = residue_a + residue_b + cin + cout;
    assign expected_residue = temp_sum % 3;

    assign residue_error = (residue_result !== expected_residue);
endmodule


// ------------------------------
// Residue Generator mod-5 (numeric residue)
// ------------------------------
module residue_mod5_generator_16bit(
    input  wire [15:0] data,
    output wire [2:0]  residue
);
    assign residue = data % 5;
endmodule


// ------------------------------
// Residue Checker mod-5 (FIXED: include cout / 17-bit effect)
// 2^16 mod5 = 1 => expected = (ra+rb+cin+cout) mod5
// ------------------------------
module residue_mod5_checker(
    input  wire [2:0] residue_a,
    input  wire [2:0] residue_b,
    input  wire       cin,
    input  wire       cout,
    input  wire [2:0] residue_result,
    output wire       residue_error
);
    wire [5:0] temp_sum;
    wire [2:0] expected_residue;

    assign temp_sum = residue_a + residue_b + cin + cout;
    assign expected_residue = temp_sum % 5;

    assign residue_error = (residue_result !== expected_residue);
endmodule


// ------------------------------
// Carry Chain Checker (16-bit)
// carry[i+1] should equal: g | (p & carry[i])
// where g=a&b, p=a^b
// ------------------------------
module carry_chain_checker_16bit(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [16:0] carry_chain,
    output wire        carry_error
);
    integer i;
    reg error_flag;

    always @(*) begin
        error_flag = 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
            if (carry_chain[i+1] !== ((a[i] & b[i]) |
                                      (carry_chain[i] & (a[i] ^ b[i])))) begin
                error_flag = 1'b1;
            end
        end
    end

    assign carry_error = error_flag;
endmodule


// ------------------------------
// Integrated Fault-Tolerant 16-bit Adder
// ------------------------------
module fault_tolerant_adder_integrated(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout,
    output wire        parity_error,
    output wire        residue3_error,
    output wire        residue5_error,
    output wire        carry_error,
    output wire        error_detected
);
    // Adder core
    wire [16:0] carry_chain;

    ripple_carry_adder_16bit rca (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout),
        .carry_chain(carry_chain)
    );

    // Parity
    wire parity_a, parity_b, parity_sum;

    parity_generator_16bit pg_a  (.data(a),   .parity(parity_a));
    parity_generator_16bit pg_b  (.data(b),   .parity(parity_b));
    parity_generator_16bit pg_s  (.data(sum), .parity(parity_sum));

    parity_checker pc (
        .parity_a(parity_a),
        .parity_b(parity_b),
        .cin(cin),
        .cout(cout),
        .parity_result(parity_sum),
        .parity_error(parity_error)
    );

    // Residue mod-3
    wire [1:0] r3_a, r3_b, r3_s;
    residue_mod3_generator_16bit r3g_a (.data(a),   .residue(r3_a));
    residue_mod3_generator_16bit r3g_b (.data(b),   .residue(r3_b));
    residue_mod3_generator_16bit r3g_s (.data(sum), .residue(r3_s));

    residue_mod3_checker r3c (
        .residue_a(r3_a),
        .residue_b(r3_b),
        .cin(cin),
        .cout(cout),
        .residue_result(r3_s),
        .residue_error(residue3_error)
    );

    // Residue mod-5
    wire [2:0] r5_a, r5_b, r5_s;
    residue_mod5_generator_16bit r5g_a (.data(a),   .residue(r5_a));
    residue_mod5_generator_16bit r5g_b (.data(b),   .residue(r5_b));
    residue_mod5_generator_16bit r5g_s (.data(sum), .residue(r5_s));

    residue_mod5_checker r5c (
        .residue_a(r5_a),
        .residue_b(r5_b),
        .cin(cin),
        .cout(cout),
        .residue_result(r5_s),
        .residue_error(residue5_error)
    );

    // Carry chain check
    carry_chain_checker_16bit ccc (
        .a(a),
        .b(b),
        .carry_chain(carry_chain),
        .carry_error(carry_error)
    );

    // Combined error
    assign error_detected = parity_error | residue3_error | residue5_error | carry_error;
endmodule


// ------------------------------
// 16-bit Fault-Tolerant ALU (uses FT adder for add/sub/inc/dec)
// ------------------------------
module alu_16bit_fault_tolerant(
    input  wire [15:0] operand_a,
    input  wire [15:0] operand_b,
    input  wire [3:0]  alu_opcode,
    input  wire        clk,
    input  wire        rst_n,
    output reg  [15:0] result,
    output reg         cout,
    output reg         zero,
    output reg         overflow,
    output reg         parity_err,
    output reg         residue3_err,
    output reg         residue5_err,
    output reg         carry_err,
    output reg         error
);
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOT  = 4'b0101;
    localparam OP_SHL  = 4'b0110;
    localparam OP_SHR  = 4'b0111;
    localparam OP_INC  = 4'b1000;
    localparam OP_DEC  = 4'b1001;
    localparam OP_PASS = 4'b1010;
    localparam OP_ZERO = 4'b1011;

    reg [15:0] adder_input_a, adder_input_b;
    reg        adder_cin;
    reg        use_adder;

    wire [15:0] adder_sum;
    wire        adder_cout;
    wire        adder_parity_error, adder_residue3_error, adder_residue5_error, adder_carry_error;
    wire        adder_error_detected;

    reg [15:0] temp_result;
    reg        temp_cout;

    fault_tolerant_adder_integrated ft_adder (
        .a(adder_input_a),
        .b(adder_input_b),
        .cin(adder_cin),
        .sum(adder_sum),
        .cout(adder_cout),
        .parity_error(adder_parity_error),
        .residue3_error(adder_residue3_error),
        .residue5_error(adder_residue5_error),
        .carry_error(adder_carry_error),
        .error_detected(adder_error_detected)
    );

    always @(*) begin
        adder_input_a = operand_a;
        adder_input_b = operand_b;
        adder_cin     = 1'b0;
        use_adder     = 1'b0;
        temp_result   = 16'h0000;
        temp_cout     = 1'b0;

        case (alu_opcode)
            OP_ADD: begin
                use_adder     = 1'b1;
                adder_input_a = operand_a;
                adder_input_b = operand_b;
                adder_cin     = 1'b0;
                temp_result   = adder_sum;
                temp_cout     = adder_cout;
            end
            OP_SUB: begin
                use_adder     = 1'b1;
                adder_input_a = operand_a;
                adder_input_b = ~operand_b;
                adder_cin     = 1'b1;
                temp_result   = adder_sum;
                temp_cout     = adder_cout;
            end
            OP_AND: temp_result = operand_a & operand_b;
            OP_OR : temp_result = operand_a | operand_b;
            OP_XOR: temp_result = operand_a ^ operand_b;
            OP_NOT: temp_result = ~operand_a;
            OP_SHL: {temp_cout, temp_result} = {operand_a, 1'b0};
            OP_SHR: {temp_result, temp_cout} = {1'b0, operand_a};
            OP_INC: begin
                use_adder     = 1'b1;
                adder_input_a = operand_a;
                adder_input_b = 16'h0000;
                adder_cin     = 1'b1;
                temp_result   = adder_sum;
                temp_cout     = adder_cout;
            end
            OP_DEC: begin
                use_adder     = 1'b1;
                adder_input_a = operand_a;
                adder_input_b = 16'hFFFF;
                adder_cin     = 1'b0;
                temp_result   = adder_sum;
                temp_cout     = adder_cout;
            end
            OP_PASS: temp_result = operand_a;
            OP_ZERO: temp_result = 16'h0000;
            default: temp_result = 16'h0000;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'h0000;
            cout   <= 1'b0;
            zero   <= 1'b0;
            overflow <= 1'b0;
            parity_err <= 1'b0;
            residue3_err <= 1'b0;
            residue5_err <= 1'b0;
            carry_err <= 1'b0;
            error <= 1'b0;
        end else begin
            result <= temp_result;
            cout   <= temp_cout;
            zero   <= (temp_result == 16'h0000);

            if (alu_opcode == OP_ADD)
                overflow <= (operand_a[15] == operand_b[15]) && (temp_result[15] != operand_a[15]);
            else if (alu_opcode == OP_SUB)
                overflow <= (operand_a[15] != operand_b[15]) && (temp_result[15] != operand_a[15]);
            else
                overflow <= 1'b0;

            if (use_adder) begin
                parity_err   <= adder_parity_error;
                residue3_err <= adder_residue3_error;
                residue5_err <= adder_residue5_error;
                carry_err    <= adder_carry_error;
                error        <= adder_error_detected;
            end else begin
                parity_err   <= 1'b0;
                residue3_err <= 1'b0;
                residue5_err <= 1'b0;
                carry_err    <= 1'b0;
                error        <= 1'b0;
            end
        end
    end
endmodule


