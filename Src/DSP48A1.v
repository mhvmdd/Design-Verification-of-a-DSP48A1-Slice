module DSP48A1 (
    // ///DATA PORTS/// //
    input [17:0] A, B, D,
    input [47:0] C,

    input CARRYIN,

    output [35:0] M,
    output [47:0] P,
    output CARRYOUT,
    output CARRYOUTF,

    // ///CONTROL SIGNALS/// //
    input clk,
    input [7:0] OPMODE,

    // ///CLK ENABLE/// //
    input CEA, CEB, CEC, CED, CEM, CEP,
    input CECARRYIN,
    input CEOPMODE,

    // ///RESET ENABLE/// //
    input RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP,

    // ///CASCADE PORTS/// //
    input [17:0] BCIN,
    output [17:0] BCOUT,

    input [47:0] PCIN,
    output [47:0] PCOUT
);
//------------- PARAMETERS --------------- 
parameter A0REG = 0, A1REG = 1; // Sig A
parameter B0REG = 0, B1REG = 1; //Sig B
parameter CREG = 1;//Sig C
parameter DREG = 1;//Sig D 
parameter MREG = 1;//Sig M 
parameter PREG = 1;//Sig P
parameter CARRYINREG = 1;//Sig carryin
parameter CARRYOUTREG = 1;//Sig carryout
parameter OPMODEREG = 1; //Sig opmode
parameter CARRYINSEL = "OPMODE5"; // "OPMODE5"  or "CARRYIN"
parameter B_INPUT = "DIRECT"; // "DIRECT" or "CASCADE"
parameter RSTTYPE = "SYNC";// "SYNC" or "ASYNC"

//OPMODE
wire [7:0] OPMODE_OUT;
generate
    if(OPMODEREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(8) OPMODE_REG (clk, RSTOPMODE, CEOPMODE, OPMODE, OPMODE_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(8) OPMODE_REG (clk, RSTOPMODE, CEOPMODE, OPMODE, OPMODE_OUT);
    end
    else assign OPMODE_OUT = OPMODE;
endgenerate

// BIN MUX
wire [17:0] B0MUX_OUT;
assign B0MUX_OUT = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 18'b0;
//B0
wire [17:0] B0_OUT;
generate
    if(B0REG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(18) B0_REG (clk, RSTB, CEB, B0MUX_OUT, B0_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(18) B0_REG (clk, RSTB, CEB, B0MUX_OUT, B0_OUT);
    end
    else assign B0_OUT = B0MUX_OUT;
endgenerate

//D
wire [17:0] D_OUT;
generate
    if(DREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(18) D_REG (clk, RSTD, CED, D, D_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(18) D_REG (clk, RSTD, CED, D, D_OUT);
    end
    else assign D_OUT = D;
endgenerate

//Pre ADDER/SUBTRACTOR
wire [17:0] PREADDSUB_OUT;
assign PREADDSUB_OUT = (OPMODE_OUT[6]) ? (D_OUT - B0_OUT) : (D_OUT + B0_OUT);

// Pre ADDER/SUBTRACTOR MUX
reg [17:0] B1MUX_OUT;
always @(*) begin
    if(OPMODE_OUT[4]) B1MUX_OUT = PREADDSUB_OUT;
    else B1MUX_OUT = B0_OUT;
end

//B1
wire [17:0] B1_OUT;
generate
    if(B1REG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(18) B1_REG (clk, RSTB, CEB, B1MUX_OUT, B1_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(18) B1_REG (clk, RSTB, CEB, B1MUX_OUT, B1_OUT);
    end
    else assign B1_OUT = B1MUX_OUT;
endgenerate
//BCOUT
assign BCOUT = B1_OUT;


//A0 
wire [17:0] A0_OUT;
generate
    if(A0REG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(18) A0_REG (clk, RSTA, CEA, A, A0_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(18) A0_REG (clk, RSTA, CEA, A, A0_OUT);
    end
    else assign A0_OUT = A;
endgenerate

//A1 
wire [17:0] A1_OUT;
generate
    if(A1REG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(18) A1_REG (clk, RSTA, CEA, A0_OUT, A1_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(18) A1_REG (clk, RSTA, CEA, A0_OUT, A1_OUT);
    end
    else assign A1_OUT = A0_OUT;
endgenerate

// Multiplier
wire [35:0] M_OUT;
assign M_OUT = A1_OUT * B1_OUT;

//M
generate
    if(MREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(36) M_REG (clk, RSTM, CEM, M_OUT, M);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(36) M_REG (clk, RSTM, CEM, M_OUT, M);
    end
    else assign M = M_OUT;
endgenerate

//C
wire [47:0] C_OUT;
generate
    if(CREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(48) C_REG (clk, RSTC, CEC, C, C_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(48) C_REG (clk, RSTC, CEC, C, C_OUT);
    end
    else assign C_OUT = C;
endgenerate

// Multiplixer X
reg [47:0] XMUX_OUT;
always @(*) begin
    case (OPMODE_OUT[1:0])
        2'b00: XMUX_OUT = 48'b0;
        2'b01: XMUX_OUT = {12'b0, M};
        2'b10: XMUX_OUT = PCOUT;
        default: XMUX_OUT = {D_OUT[11:0], A1_OUT, B1_OUT};
    endcase
end
// Multiplixer Z
reg [47:0] ZMUX_OUT;
always @(*) begin
    case (OPMODE_OUT[3:2])
        2'b00: ZMUX_OUT = 48'b0;
        2'b01: ZMUX_OUT = PCIN;
        2'b10: ZMUX_OUT = PCOUT;
        default: ZMUX_OUT = C_OUT;
    endcase
end

//CARRYIN
wire CARRYINMUX_OUT;
assign CARRYINMUX_OUT = (CARRYINSEL == "OPMODE5") ? OPMODE_OUT[5] : (CARRYINSEL == "CARRYIN") ? CARRYIN : 1'b0;

wire CARRYIN_OUT;
generate
    if(CARRYINREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(1) CARRYIN_REG (clk, RSTCARRYIN, CECARRYIN, CARRYINMUX_OUT, CARRYIN_OUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(1) CARRYIN_REG (clk, RSTCARRYIN, CECARRYIN, CARRYINMUX_OUT, CARRYIN_OUT);
    end
    else assign CARRYIN_OUT = CARRYINMUX_OUT;
endgenerate

// POST ADDER/SUBTRACTOR
wire [47:0] POSTADDSUB_OUT;
wire CARRYOUT_OUT;

assign {CARRYOUT_OUT, POSTADDSUB_OUT} = (OPMODE_OUT[7]) ? (ZMUX_OUT - (XMUX_OUT + CARRYIN_OUT)) : (ZMUX_OUT + (XMUX_OUT + CARRYIN_OUT));

//CARRYOUT
generate
    if(CARRYOUTREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(1) CARRYOUT_REG (clk, RSTCARRYIN, CECARRYIN, CARRYOUT_OUT, CARRYOUT);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(1) CARRYOUT_REG (clk, RSTCARRYIN, CECARRYIN, CARRYOUT_OUT, CARRYOUT);
    end
    else assign CARRYOUT = CARRYOUT_OUT;
endgenerate

assign CARRYOUTF = CARRYOUT;

//P
generate
    if(PREG) begin
        if(RSTTYPE == "SYNC") FF_SYNC #(48) P_REG (clk, RSTP, CEP, POSTADDSUB_OUT, P);
        else if (RSTTYPE == "ASYNC") FF_ASYNC #(48) P_REG (clk, RSTP, CEP, POSTADDSUB_OUT, P);
    end
    else assign P = POSTADDSUB_OUT;
endgenerate

//PCOUT
assign PCOUT = P;

endmodule

module FF_SYNC
#(
    parameter WIDTH = 1
)
(
    input  clk, rst, en,
    input [WIDTH-1:0] IN,
    output reg [WIDTH-1:0] Y
);
always @(posedge clk) begin
    if(rst) Y <= {WIDTH{1'b0}};
    else if (en) Y <= IN;
end
endmodule

module FF_ASYNC
#(
    parameter WIDTH = 1
)
(
    input  clk, rst, en,
    input [WIDTH-1:0] IN,
    output reg [WIDTH-1:0] Y
);
always @(posedge clk or posedge rst) begin
    if(rst) Y <= {WIDTH{1'b0}};
    else if (en) Y <= IN;
end
endmodule


