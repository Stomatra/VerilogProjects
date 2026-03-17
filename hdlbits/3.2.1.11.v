module top_module (
	input clk,
	input L,
	input r_in,
	input q_in,
	output reg Q
);
    wire d0,d1,d2;
    wire q0,q1;
    choose c1(r_in,Q,L,d0);
    dff dff1(d0,clk,q0);
    choose c2(r_in,q0,L,d1);
    dff dff2(d1,clk,q1);
    xor_gate xor1(Q,q1,d2);
    choose c3(r_in,q1,L,d2);
    dff dff3(d2,clk,Q);
endmodule

module choose(
    input r_in,
    input q_in,
    input L,
    output D
);
    assign D = L ? r_in : q_in;
endmodule

module dff(
    input d_in,
    input clk,
    output reg q_out
);
    always @(posedge clk) begin
        q_out <= d_in;
    end
endmodule

module xor_gate(
    input a,
    input b,
    output z
);
    assign z = a ^ b;
endmodule