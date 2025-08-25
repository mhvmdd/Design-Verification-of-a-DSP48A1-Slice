module DSP48A1_tb();
// ///DATA PORTS/// //
reg [17:0] A, B, D;
reg [47:0] C;

reg CARRYIN;

wire [35:0] M;
wire [47:0] P;

wire CARRYOUT;
wire CARRYOUTF;

// ///CONTROL SIGNALS/// //
reg clk;
reg [7:0] OPMODE;

// ///CLK ENABLE/// //
reg CEA, CEB, CEC, CED, CEM, CEP;
reg CECARRYIN;
reg CEOPMODE;

// ///RESET ENABLE/// //
reg RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP;

// ///CASCADE PORTS/// //
reg [17:0] BCIN;
wire [17:0] BCOUT;

reg [47:0] PCIN;
wire [47:0] PCOUT;

// Instantiate the DUT 
DSP48A1 dd (
    .A(A), .B(B), .C(C), .D(D), .CARRYIN(CARRYIN),
    .M(M), .P(P), .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF),
    .clk(clk), .OPMODE(OPMODE),
    .CEA(CEA), .CEB(CEB), .CEC(CEC), .CED(CED), .CEM(CEM), .CEP(CEP),
    .CECARRYIN(CECARRYIN), .CEOPMODE(CEOPMODE),
    .RSTA(RSTA), .RSTB(RSTB), .RSTC(RSTC), .RSTCARRYIN(RSTCARRYIN),
    .RSTD(RSTD), .RSTM(RSTM), .RSTOPMODE(RSTOPMODE), .RSTP(RSTP),
    .BCIN(BCIN), .BCOUT(BCOUT), .PCIN(PCIN), .PCOUT(PCOUT)
);

initial begin
    clk = 0;
    forever #1 clk = ~clk;
end

initial begin

    // Assert all active-high reset signals 
    RSTA = 1; 
    RSTB = 1; 
    RSTC = 1; 
    RSTCARRYIN = 1; 
    RSTD = 1; 
    RSTM = 1; 
    RSTOPMODE = 1; 
    RSTP = 1;   
    // Drive all remaining inputs with random values 
    A = $random;
    B = $random;
    C = $random;
    D = $random;
    CARRYIN = $random;  
    BCIN = $random;
    PCIN = $random;
    OPMODE = $random;

    @(negedge clk);

    // Check if all outputs are zero
    if (P != 48'd0 || M != 36'd0 || CARRYOUT != 1'b0 || CARRYOUTF != 1'b0 || 
        BCOUT != 18'd0 || PCOUT != 48'd0) begin
        $display("ERROR: Outputs are NOT zero during reset");
        $stop;
    end else begin
        $display("PASS: All outputs are correctly zeroe");
    end

    RSTA = 0; 
    RSTB = 0; 
    RSTC = 0; 
    RSTCARRYIN = 0; 
    RSTD = 0; 
    RSTM = 0; 
    RSTOPMODE = 0; 
    RSTP = 0; 

    // Enable all clock enables
    CEA = 1;
    CEB = 1;
    CEC = 1;
    CED = 1;
    CEM = 1;
    CEP = 1;
    CECARRYIN = 1;
    CEOPMODE = 1;

    // Testing Path 1
    A = 20;
    B = 10;
    C = 350;
    D = 25;
    OPMODE = 8'b11011101;

    BCIN = $random;
    PCIN = $random;
    CARRYIN = $random;

    repeat (4) @(negedge clk);

    if (
    BCOUT != 18'h00f ||
    M != 36'h012c ||
    P != 48'h0032 ||
    PCOUT != 48'h0032 ||
    CARRYOUT != 1'b0 ||
    CARRYOUTF != 1'b0
    ) begin
        $display("ERROR: Outputs do NOT match expected values at time %0t", $time);
        $stop;
    end else begin
        $display("PASS: All outputs match expected values at time %0t", $time);
    end


    // Testing Path 2
    A = 20;
    B = 10;
    C = 350;
    D = 25;
    OPMODE = 8'b00010000;

    BCIN = $random;
    PCIN = $random;
    CARRYIN = $random;

    repeat (3) @(negedge clk);

    if (
    BCOUT != 18'h023 ||
    M != 36'h02bc ||
    P != 48'h0 ||
    PCOUT != 48'h0 ||
    CARRYOUT != 1'b0 ||
    CARRYOUTF != 1'b0
    ) begin
        $display("ERROR: Outputs do NOT match expected values at time %0t", $time);
        $stop;
    end else begin
        $display("PASS: All outputs match expected values at time %0t", $time);
    end

    // Testing Path 3
    A = 20;
    B = 10;
    C = 350;
    D = 25;
    OPMODE = 8'b00001010;

    BCIN = $random;
    PCIN = $random;
    CARRYIN = $random;

    repeat (3) @(negedge clk);

    if (
    BCOUT != 18'h00a ||
    M != 36'h00c8 ||
    P != PCOUT ||
    CARRYOUT != CARRYOUTF
    ) begin
        $display("ERROR: Outputs do NOT match expected values at time %0t", $time);
        $stop;
    end else begin
        $display("PASS: All outputs match expected values at time %0t", $time);
    end

    // Testing Path 4
    A = 5;
    B = 6;
    C = 350;
    D = 25;
    OPMODE = 8'b10100111;

    BCIN = $random;
    PCIN = 3000;
    CARRYIN = $random;

    repeat (3) @(negedge clk);

    if (
    BCOUT != 18'h006 ||
    M != 36'h001e ||
    P != 48'hfe6fffec0bb1||
    PCOUT !=48'hfe6fffec0bb1 ||
    CARRYOUT != 1'b1||
    CARRYOUTF != 1'b1
    ) begin
        $display("ERROR: Outputs do NOT match expected values at time %0t", $time);
        $stop;
    end else begin
        $display("PASS: All outputs match expected values at time %0t", $time);
    end
    $stop;
end
endmodule