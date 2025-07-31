`timescale 1ns / 1ps

module DSP48A1_tb();

    
    // Inputs
    reg [17:0] A, B, D;
    reg [47:0] C, PCIN;
    reg [7:0]  OPMODE;
    reg [17:0] BCIN;
    reg CLK, RSTA, RSTB, RSTD, RSTM, RSTP, RSTC, RSTCARRYIN, RSTOPMODE;
    reg CEA, CEB, CED, CEM, CEP, CEC, CECARRYIN, CEOPMODE;
    reg CARRYIN;

    // Outputs
    wire [17:0] BCOUT;
    wire [47:0] PCOUT;
    wire [47:0] P;
    wire [35:0] M;
    wire CARRYOUT;
    wire CARRYOUTF;

    integer errors = 0;

    // Instantiate the DUT
    DSP48A1_wrapper dut (
        .A(A), .B(B), .D(D), .C(C), .CLK(CLK), .CARRYIN(CARRYIN), .OPMODE(OPMODE),
        .BCIN(BCIN), .PCIN(PCIN),
        .CEA(CEA), .CEB(CEB), .CED(CED), .CEM(CEM), .CEP(CEP), .CEC(CEC),
        .CECARRYIN(CECARRYIN), .CEOPMODE(CEOPMODE),
        .RSTA(RSTA), .RSTB(RSTB), .RSTD(RSTD), .RSTM(RSTM), .RSTP(RSTP),
        .RSTC(RSTC), .RSTCARRYIN(RSTCARRYIN), .RSTOPMODE(RSTOPMODE),
        .BCOUT(BCOUT), .PCOUT(PCOUT), .P(P), .M(M), .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF)
    );

    // Clock generation
    always #5 CLK = ~CLK;

task reset;
    begin
    // Assert resets
    RSTA = 1; RSTB = 1; RSTD = 1; RSTM = 1; RSTP = 1;
    RSTC = 1; RSTCARRYIN = 1; RSTOPMODE = 1;

    // De-assert enables
    CEA = 0; CEB = 0; CED = 0; CEM = 0; CEP = 0;
    CEC = 0; CECARRYIN = 0; CEOPMODE = 0;

    @(negedge CLK);

    // Check outputs are zero after reset
    if (BCOUT !== 0 || PCOUT !== 0 || P !== 0 || M !== 0 || CARRYOUT !== 0 || CARRYOUTF !== 0) begin
        $display("[RESET ERROR] Outputs not zero after reset");
        errors = errors + 1;
    end
    else begin
        $display("[RESET correct] Outputs  zero after reset");

    end

    // De-assert resets
    RSTA = 0; RSTB = 0; RSTD = 0; RSTM = 0; RSTP = 0;
    RSTC = 0; RSTCARRYIN = 0; RSTOPMODE = 0;

    // Enable clock enables
    CEA = 1; CEB = 1; CED = 1; CEM = 1; CEP = 1;
    CEC = 1; CECARRYIN = 1; CEOPMODE = 1;
    end
endtask


    // Self-checking Task
task check_outputs(input [17:0] exp_BCOUT, input [35:0] exp_M,input [47:0] exp_P, input exp_COUT);
    begin
        if (BCOUT !== exp_BCOUT || M !== exp_M || P !== exp_P || CARRYOUT !== exp_COUT || CARRYOUTF !== exp_COUT) begin
            $display("[ERROR] Inputs: A=%d B=%d D=%d C=%d PCIN=%d", A, B, D, C, PCIN);
            $display("Expected -> BCOUT: %h, M: %h, P: %h, CARRYOUT: %b", exp_BCOUT, exp_M, exp_P, exp_COUT);
            $display("Got -> BCOUT: %h, M: %h, P: %h, CARRYOUT: %b", BCOUT, M, P, CARRYOUT);
            errors = errors + 1;
        end
        else begin
            $display("[correct test] Inputs: A=%d B=%d D=%d C=%d PCIN=%d", A, B, D, C, PCIN);
            $display("Expected -> BCOUT: %h, M: %h, P: %h, CARRYOUT: %b", exp_BCOUT, exp_M, exp_P, exp_COUT);
            $display("Got -> BCOUT: %h, M: %h, P: %h, CARRYOUT: %b", BCOUT, M, P, CARRYOUT);
        end
    end
endtask

    // Initial Block (Stimulus)
    initial begin
        CLK = 0;
        reset;

        // Test Path 1
        A = 20; B = 10; C = 350; D = 25;
        BCIN = $random(); PCIN = $random(); CARRYIN = $random();
        OPMODE = 8'b11011101;
        repeat(4) @(negedge CLK);
        check_outputs(18'hF, 36'h12C, 48'h32, 1'b0);

        // Test Path 2
        A = 20; B = 10; C = 350; D = 25;
        BCIN = $random(); PCIN = $random(); CARRYIN = $random();
        OPMODE = 8'b00010000;
        repeat(3) @(negedge CLK); 
        check_outputs(18'h23, 36'h2BC, 48'h0, 1'b0);

        // Test Path 3
        A = 20; B = 10; C = 350; D = 25;
        BCIN = $random(); PCIN = $random(); CARRYIN = $random();
        OPMODE = 8'b00001010;
        repeat(3) @(negedge CLK); // 4 or 3 (i think 3 is correct because we not change the values of a , b, c ,and d)
        check_outputs(18'hA, 36'hC8, P, CARRYOUT); // Previous P & CARRYOUT

        // Test Path 4
        A = 5; B = 6; C = 350; D = 25; PCIN = 3000;
        BCIN = $random();  CARRYIN = $random();        
        OPMODE = 8'b10100111;
        repeat(3) @(negedge CLK);   
        check_outputs(18'h6, 36'h1E, 48'hFE6FFFEC0BB1, 1'b1);

        // Final Report
        if (errors == 0)
            $display("All tests passed successfully!");
        else
            $display("Total Errors: %d", errors);

        $stop;
    end

endmodule
