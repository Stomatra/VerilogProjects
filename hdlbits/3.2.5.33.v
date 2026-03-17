module top_module (
    input clk,
    input resetn,    // active-low synchronous reset
    input x,
    input y,
    output f,
    output g
); 
    parameter A=4'd0,B=4'd1,C=4'd2,D0=4'd3,D1=4'd4,D2=4'd5,E=4'd6,F=4'd7,G0=4'd8,G1=4'd9,G2=4'd10,G3=4'd11;
    reg [3:0] state,next_state;

    always @(*) begin
        case(state)
            A:next_state=A;
            B:begin
                next_state=C;
                f=1'b1;
            end
            C:begin
                next_state=D0;
                f=1'b0;
            end
            D0:next_state=x?D1:D0;
            D1:next_state=x?D1:D2;
            D2:next_state=x?E:D1;
            E:begin
                next_state=F;
                g=1'b1;
            end
            F:next_state=y?G1:G2;
            G1:next_state=G1;
            G2:next_state=y?G1:G3;
            G3:begin
                next_state=G3;
                g=1'b0;
            end 
        endcase
    end
        
    
    always @(posedge clk) begin
        if(!resetn)
            state<=B;
        else
            state<=next_state;
    end
endmodule