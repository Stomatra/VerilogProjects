module adder4(
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    // 5位相加：最高位作为 cout，低4位作为 sum
    assign {cout, sum} = a + b + cin;
endmodule