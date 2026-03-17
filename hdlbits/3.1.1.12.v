module top_module (input x, input y, output z);
    wire z1,z2,z3,z4,z12,z34;
    modA a1(x,y,z1);
    modB b1(x,y,z2);
    modA a2(x,y,z3);
    modB b2(x,y,z4);
    assign z12=z1|z2;
    assign z34=z3&z4;
    assign z=z12^z34;
endmodule

module modA (input x, input y, output z);
    assign z=(x^y)&x;
endmodule

module modB ( input x, input y, output z );
    assign z=~(x^y);
endmodule
