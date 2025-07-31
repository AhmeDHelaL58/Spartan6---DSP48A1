module GenericRegMux #(
    parameter integer WIDTH = 18,           // Width of input/output
    parameter A0REG = 1,                    // 1: Register, 0: Wire-through
    parameter RSTTYPE = "SYNC"              // "SYNC" or "ASYNC"
)(
    input  wire                   CLK,
    input  wire                   RSTA,
    input  wire                   CEA,
    input  wire [WIDTH-1:0]       A,
    output wire [WIDTH-1:0]       A_reg0
);

reg [WIDTH-1:0] A0_reg;

generate
    if (A0REG) begin : GEN_REGISTER
        
        if (RSTTYPE == "SYNC") begin : SYNC_RST
            always @(posedge CLK) begin
                if (RSTA)
                    A0_reg <= {WIDTH{1'b0}};
                else if (CEA)
                    A0_reg <= A;
            end
        end else begin : ASYNC_RST
            always @(posedge CLK or posedge RSTA) begin
                if (RSTA)
                    A0_reg <= {WIDTH{1'b0}};
                else if (CEA)
                    A0_reg <= A;
            end
        end

        assign A_reg0 = A0_reg;

    end else begin : GEN_WIRE
        assign A_reg0 = A;
    end
endgenerate

endmodule
