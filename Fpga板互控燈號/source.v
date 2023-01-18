
`timescale 1ns / 1ps

module source(clk,rst,in,Dinout,LED);

    input clk,rst,in;
    inout  Dinout;
    output reg LED;

    wire Dout,Din;

    assign Dout = 0 ;

    assign Dinout = in ?Dout :1'bz;
    assign Din    = in ?1'b1 :Dinout;

    always @(*) begin
        if(rst) 
            LED <= 0;
        else begin
            if(Din == 0)  
                LED <= 1;
            else
                LED <= 0;
        end
    end

endmodule
