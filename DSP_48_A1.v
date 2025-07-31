`include "Reg_or_wire.v"



module DSP48A1_wrapper #(
    parameter A0REG = 0, /* REG OR NOT  */
    parameter A1REG = 1,
    parameter B0REG = 0,
    parameter B1REG = 1,
    parameter DREG  = 1,
    parameter MREG  = 1,
    parameter PREG  = 1,
    parameter CREG  = 1,
    parameter CARRYINREG = 1,
    parameter CARRYOUTREG = 1,
    parameter OPMODEREG = 1 ,
    parameter CARRYINSEL = "OPMODE5", // "CARRYIN" or "OPMODE[5]"
    parameter B_INPUT = "DIRECT",    // "DIRECT" or "CASCADE"
    parameter RSTTYPE = "SYNC"       // "SYNC" or "ASYNC"
)(
    input  wire [17:0] A,
    input  wire [17:0] B,
    input  wire [17:0] D,
    input  wire [47:0] C,
    input  wire        CLK,
    input  wire        CARRYIN,
    input  wire  [7:0] OPMODE,
    input  wire  [17:0] BCIN,
    input  wire [47:0] PCIN,
    input wire CEA, CEB, CED, CEM, CEP, CEC  , CECARRYIN , CEOPMODE ,
    input wire RSTA, RSTB, RSTD, RSTM, RSTP , RSTC , RSTCARRYIN , RSTOPMODE,

    output wire [17:0] BCOUT,
    output wire [47:0] PCOUT,
    output wire [47:0] P,
    output wire [35:0] M,
    output wire        CARRYOUT ,
    output wire        CARRYOUTF 

    
);

    // Internal signals for register stages
    wire [17:0] A_reg0, A_reg1;
    wire [17:0] B_reg0, B_reg1;
    wire [17:0] B_i;
    wire [17:0] D_reg;
    wire [47:0] C_reg;
    wire [47:0] M_reg;
    wire [7:0]  opmode_reg;
    wire [17:0] pre_add ;
    wire [17:0] r1 ;
    wire [35:0] r2 ;
    wire [35:0] m ; // output of M reg
    wire [47:0] cn ; // concatenate d[11:0] , a ,b 
    wire [47:0] s ; // input_1 of x Mux
    wire ci ; // input of carry in reg
    wire CIN ; // output of carry in reg
    reg [47:0] x , z ; // outputs of x and z muxs
    wire [47:0] p ; // output of post_adder_sub
    wire co ; // carry our from post_adder_sub




    
//  pipeline_1 registers

    //  A0 
   
    
    GenericRegMux #( // reg or wire
                .WIDTH(18),
                .A0REG(A0REG),
                .RSTTYPE(RSTTYPE)
            ) a0 (
                .CLK(CLK),
                .RSTA(RSTA),
                .CEA(CEA),
                .A(A),
                .A_reg0(A_reg0)
            );


    
    // mux (B_INPUT)
    generate
        if(B_INPUT=="DIRECT")
           assign  B_i = B ;

        else if(B_INPUT=="CASCADE")   
           assign  B_i = BCIN ;
        else
           assign B_i = 18'b0 ;

    endgenerate


    //  B0 
    GenericRegMux #( // reg or wire
                .WIDTH(18),
                .A0REG(B0REG),
                .RSTTYPE(RSTTYPE)
            ) b0 (
                .CLK(CLK),
                .RSTA(RSTB),
                .CEA(CEB),
                .A(B),
                .A_reg0(B_reg0)
            );




    //  C 
    GenericRegMux #( // reg or wire
                .WIDTH(48),
                .A0REG(CREG),
                .RSTTYPE(RSTTYPE)
            ) c (
                .CLK(CLK),
                .RSTA(RSTC),
                .CEA(CEC),
                .A(C),
                .A_reg0(C_reg)
            );



    //  D
    GenericRegMux #( // reg or wire
                .WIDTH(18),
                .A0REG(DREG),
                .RSTTYPE(RSTTYPE)
            ) d (
                .CLK(CLK),
                .RSTA(RSTD),
                .CEA(CED),
                .A(D),
                .A_reg0(D_reg)
            );




    //  OPMODE
    GenericRegMux #( // reg or wire
                .WIDTH(8),
                .A0REG(OPMODEREG),
                .RSTTYPE(RSTTYPE)
            ) op (
                .CLK(CLK),
                .RSTA(RSTOPMODE),
                .CEA(CEOPMODE),
                .A(OPMODE),
                .A_reg0(opmode_reg)
            );

    // end of stage one

    // pre_adder/subtractor 

    assign pre_add = ((opmode_reg[6]) ? D_reg - B_reg0 : D_reg + B_reg0 ) ;
    assign r1 = ((opmode_reg[4]) ? pre_add : B_reg0 );

// pipeline_2 registers
    // B1_reg
    GenericRegMux #( // reg or wire
                .WIDTH(18),
                .A0REG(B1REG),
                .RSTTYPE(RSTTYPE)
            ) b1 (
                .CLK(CLK),
                .RSTA(RSTB),
                .CEA(CEB),
                .A(r1),
                .A_reg0(B_reg1)
            );



    // A1_reg
    GenericRegMux #( // reg or wire
                .WIDTH(18),
                .A0REG(A1REG),
                .RSTTYPE(RSTTYPE)
            ) a1 (
                .CLK(CLK),
                .RSTA(RSTA),
                .CEA(CEA),
                .A(A_reg0),
                .A_reg0(A_reg1)
            );

    // multiplier
    assign r2 = A_reg1 * B_reg1 ;

    // concatenate
    assign cn = {D_reg[11:0] , A_reg1 , B_reg1 };

    // Bcout 
    assign BCOUT = B_reg1 ;



   
//  pipeline_3 registers ( Mreg and carryin_reg)

    // M reg
     GenericRegMux #( // reg or wire
                .WIDTH(36),
                .A0REG(MREG),
                .RSTTYPE(RSTTYPE)
            ) Mreg (
                .CLK(CLK),
                .RSTA(RSTM),
                .CEA(CEM),
                .A(r2),
                .A_reg0(m)
            );
    // input for Mux (concatenate to 48 bit)
    assign s = { 12'b0, m };

    // M output (connected to FPGA)
    assign M = m ;


    // carry in Mux
    generate
        if(CARRYINSEL=="OPMODE5")
           assign  ci = opmode_reg[5] ;

        else if(B_INPUT=="CARRYIN")   
           assign  ci = CARRYIN ;
        else
           assign ci = 1'b0 ;

    endgenerate
    //carry reg
    GenericRegMux #( // reg or wire
                .WIDTH(1),
                .A0REG(CARRYINREG),
                .RSTTYPE(RSTTYPE)
            ) Cin_reg (
                .CLK(CLK),
                .RSTA(RSTCARRYIN),
                .CEA(CECARRYIN),
                .A(ci),
                .A_reg0(CIN)
            );


    // x mux
    always @(*) begin
        case(opmode_reg[1:0])
        2'b00 : x = 48'b0 ;
        2'b01 : x = s ;
        2'b10 : x = P ;
        2'b11 : x = cn ;

        default : x = 48'b0;

        endcase
    end


    // z mux
    always @(*) begin
        case(opmode_reg[3:2])
        2'b00 : z = 48'b0 ;
        2'b01 : z = PCIN ;
        2'b10 : z = P ;
        2'b11 : z = C_reg ;

        default : z = 48'b0;

        endcase
    end


    // post_adder_output
    assign {co , p} = ((opmode_reg[7]) ? (z - (x+CIN)) : (z + x + CIN)); 

    
//  pipeline_4 registers (Preg and carry_cascaded_reg)
    //Preg
    GenericRegMux #( // reg or wire
                .WIDTH(48),
                .A0REG(PREG),
                .RSTTYPE(RSTTYPE)
            ) Preg (
                .CLK(CLK),
                .RSTA(RSTP),
                .CEA(CEP),
                .A(p),
                .A_reg0(P)
            );
    // Pcout cascaded
    assign PCOUT = P ;


    // carry_out cascaded
    GenericRegMux #( // reg or wire
                .WIDTH(1),
                .A0REG(CARRYOUTREG),
                .RSTTYPE(RSTTYPE)
            ) Cout_reg (
                .CLK(CLK),
                .RSTA(RSTCARRYIN),
                .CEA(CECARRYIN),
                .A(co),
                .A_reg0(CARRYOUT)
            );
            
    // carry out to FPGA
    assign CARRYOUTF = CARRYOUT ;

   





   

   

endmodule
