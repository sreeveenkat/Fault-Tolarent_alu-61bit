// ============================================================
// TESTBENCH
// ============================================================
module tb_alu_fault_tolerant_comprehensive;

    reg  [15:0] operand_a;
    reg  [15:0] operand_b;
    reg  [3:0]  alu_opcode;
    reg         clk;
    reg         rst_n;

    wire [15:0] result;
    wire        cout;
    wire        zero;
    wire        overflow;
    wire        parity_err;
    wire        residue3_err;
    wire        residue5_err;
    wire        carry_err;
    wire        error;

    integer test_num = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fault_inject_count = 0;
    integer fault_detect_count = 0;

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

    alu_16bit_fault_tolerant dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_opcode(alu_opcode),
        .clk(clk),
        .rst_n(rst_n),
        .result(result),
        .cout(cout),
        .zero(zero),
        .overflow(overflow),
        .parity_err(parity_err),
        .residue3_err(residue3_err),
        .residue5_err(residue5_err),
        .carry_err(carry_err),
        .error(error)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ======= SVA =======

    property p_zero_flag_correct;
        @(posedge clk) disable iff (!rst_n)
        (result == 16'h0000) |-> (zero == 1'b1);
    endproperty
    assert_zero: assert property (p_zero_flag_correct)
        else $error("[SVA ERROR] Zero flag not set when result is 0x0000");

    property p_error_flag_consistent;
        @(posedge clk) disable iff (!rst_n)
        (parity_err || residue3_err || residue5_err || carry_err) |-> error;
    endproperty
    assert_error: assert property (p_error_flag_consistent)
        else $error("[SVA ERROR] Combined error flag not set when individual error detected");

    property p_no_error_on_logical;
        @(posedge clk) disable iff (!rst_n)
        ($past(alu_opcode) inside {OP_AND, OP_OR, OP_XOR, OP_NOT, OP_SHL, OP_SHR, OP_PASS, OP_ZERO})
        |-> !error;
    endproperty
    assert_logical: assert property (p_no_error_on_logical)
        else $error("[SVA ERROR] Error flag set on non-arithmetic operation");

    property p_reset_clears;
        @(posedge clk)
        (!rst_n) |=> (result == 16'h0000) && !cout && !zero && !overflow && !error;
    endproperty
    assert_reset: assert property (p_reset_clears)
        else $error("[SVA ERROR] Reset did not clear outputs properly");

    property p_add_correct;
        @(posedge clk) disable iff (!rst_n)
        (alu_opcode == OP_ADD) && !error |=> (result == ($past(operand_a) + $past(operand_b)));
    endproperty
    assert_add: assert property (p_add_correct)
        else $error("[SVA ERROR] Addition result incorrect");

    // ======= TASKS =======

    task apply_test(
        input [15:0] a,
        input [15:0] b,
        input [3:0]  op,
        input [15:0] expected,
        input        expected_c,
        input string name
    );
        begin
            test_num = test_num + 1;

            operand_a  = a;
            operand_b  = b;
            alu_opcode = op;

            @(posedge clk);
            @(posedge clk);
            #1;

            if (result === expected && cout === expected_c && !error) begin
                pass_count = pass_count + 1;
                $display("[PASS %3d] %s | A=%h B=%h OP=%h | Result=%h (Exp=%h) C=%b",
                         test_num, name, a, b, op, result, expected, cout);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL %3d] %s | A=%h B=%h OP=%h | Result=%h (Exp=%h) C=%b Err=%b",
                         test_num, name, a, b, op, result, expected, cout, error);
            end
        end
    endtask

    // ---- FIXED FORCE (mask bus) ----
    task inject_sum_fault(
        input [15:0] a,
        input [15:0] b,
        input integer bit_pos,
        input string name
    );
        reg [15:0] mask;
        begin
            fault_inject_count = fault_inject_count + 1;

            operand_a  = a;
            operand_b  = b;
            alu_opcode = OP_ADD;

            @(posedge clk);
            @(posedge clk);
            #1;

            mask = 16'h0001 << bit_pos;
            force dut.adder_sum = dut.adder_sum ^ mask;

            @(posedge clk);
            #1;

            if (error) begin
                fault_detect_count = fault_detect_count + 1;
                $display("[FAULT DETECTED] %s at bit %2d | P=%b R3=%b R5=%b C=%b",
                         name, bit_pos, parity_err, residue3_err, residue5_err, carry_err);
            end else begin
                $display("[FAULT MISSED!] %s at bit %2d NOT DETECTED", name, bit_pos);
            end

            release dut.adder_sum;
            @(posedge clk);
        end
    endtask

    task inject_carry_fault(
        input [15:0] a,
        input [15:0] b,
        input integer carry_pos,
        input string name
    );
        reg [16:0] mask;
        begin
            fault_inject_count = fault_inject_count + 1;

            operand_a  = a;
            operand_b  = b;
            alu_opcode = OP_ADD;

            @(posedge clk);
            @(posedge clk);
            #1;

            mask = 17'h1 << carry_pos;
            force dut.ft_adder.rca.carry_chain = dut.ft_adder.rca.carry_chain ^ mask;

            @(posedge clk);
            #1;

            if (error) begin
                fault_detect_count = fault_detect_count + 1;
                $display("[CARRY FAULT DETECTED] %s at position %2d", name, carry_pos);
            end else begin
                $display("[CARRY FAULT MISSED!] %s at position %2d", name, carry_pos);
            end

            release dut.ft_adder.rca.carry_chain;
            @(posedge clk);
        end
    endtask

    task inject_multibit_fault(
        input [15:0] a,
        input [15:0] b,
        input [15:0] fault_mask,
        input string name
    );
        begin
            fault_inject_count = fault_inject_count + 1;

            operand_a  = a;
            operand_b  = b;
            alu_opcode = OP_ADD;

            @(posedge clk);
            @(posedge clk);
            #1;

            force dut.adder_sum = dut.adder_sum ^ fault_mask;

            @(posedge clk);
            #1;

            if (error) begin
                fault_detect_count = fault_detect_count + 1;
                $display("[MULTI-BIT FAULT DETECTED] %s | Mask=%h", name, fault_mask);
            end else begin
                $display("[MULTI-BIT FAULT MISSED!] %s | Mask=%h", name, fault_mask);
            end

            release dut.adder_sum;
            @(posedge clk);
        end
    endtask

    // ======= MAIN =======

    initial begin
        $dumpfile("alu_fault_tolerant_comprehensive.vcd");
        $dumpvars(0, tb_alu_fault_tolerant_comprehensive);

        operand_a  = 16'h0000;
        operand_b  = 16'h0000;
        alu_opcode = 4'h0;
        rst_n      = 0;

        #20;
        rst_n = 1;
        @(posedge clk);

        // Functional tests
        apply_test(16'h0001, 16'h0002, OP_ADD, 16'h0003, 0, "ADD: Simple");
        apply_test(16'hFFFF, 16'h0001, OP_ADD, 16'h0000, 1, "ADD: Carry out");
        apply_test(16'h1234, 16'h5678, OP_ADD, 16'h68AC, 0, "ADD: Random");

        apply_test(16'h0005, 16'h0003, OP_SUB, 16'h0002, 1, "SUB: Simple");

        apply_test(16'hAAAA, 16'h5555, OP_AND, 16'h0000, 0, "AND");
        apply_test(16'hAAAA, 16'h5555, OP_OR,  16'hFFFF, 0, "OR");
        apply_test(16'hF0F0, 16'h0000, OP_NOT, 16'h0F0F, 0, "NOT");

        // Fault injection
        inject_sum_fault(16'h1234, 16'h5678, 0,  "Bit 0 fault");
        inject_sum_fault(16'h1234, 16'h5678, 15, "Bit 15 fault");
        inject_carry_fault(16'hFFFF, 16'h0001, 8, "Carry fault pos8");
        inject_multibit_fault(16'h1234, 16'h5678, 16'h00FF, "8-bit fault");

        $display("\n========================================");
        $display("  TEST SUMMARY");
        $display("========================================");
        $display("Total Functional Tests:  %4d", test_num);
        $display("Passed:                  %4d", pass_count);
        $display("Failed:                  %4d", fail_count);
        $display("Fault Injections:        %4d", fault_inject_count);
        $display("Faults Detected:         %4d", fault_detect_count);
        $display("========================================\n");

        #50;
        $finish;
    end

endmodule