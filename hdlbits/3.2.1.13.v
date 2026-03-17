module top_module (
    input clk,
    input x,
    output z
); 
    wire d1,d2,d3;
    wire q1,q2,q3;
    wire resetn;
    assign resetn=1'b0;
    assign d1=x^q1;
    dff dff1(d1,clk,resetn,q1);
    assign d2=x&~q2;
    dff dff2(d2,clk,resetn,q2);
    assign d3=q1|~q3;
    dff dff3(d3,clk,resetn,q3);
    assign z=q1|q2|q3;
endmodule

module dff(
    input d_in,
    input clk,
    input resetn,
    output reg q_out
);
    always @(posedge clk) begin
        if(resetn == 1'b0) begin
            q_out <= 1'b0;
        end else begin
            q_out <= d_in;
        end
    end

endmodule