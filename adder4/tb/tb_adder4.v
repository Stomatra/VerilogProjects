`timescale 1ns/1ps

module tb_adder4;
    reg  [3:0] a, b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;

    adder4 u_adder4 (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        $display("========================================");
        $display("  4-bit Adder Testbench");
        $display("========================================");
        $display("Time\t a    b    cin | sum  cout | Expected");
        $display("------------------------------------------------");

        // 测试用例
        a = 4'd3;  b = 4'd5;  cin = 0; #10;
        $display("%0t\t %d + %d + %d | %d    %d   | 8, 0 %s", 
            $time, a, b, cin, sum, cout, 
            (sum == 8 && cout == 0) ? "✓" : "✗");

        a = 4'd15; b = 4'd1;  cin = 0; #10;
        $display("%0t\t %d + %d + %d | %d    %d   | 0, 1 %s", 
            $time, a, b, cin, sum, cout, 
            (sum == 0 && cout == 1) ? "✓" : "✗");

        a = 4'd7;  b = 4'd8;  cin = 1; #10;
        $display("%0t\t %d + %d + %d | %d    %d   | 0, 1 %s", 
            $time, a, b, cin, sum, cout, 
            (sum == 0 && cout == 1) ? "✓" : "✗");

        a = 4'd0;  b = 4'd0;  cin = 1; #10;
        $display("%0t\t %d + %d + %d | %d    %d   | 1, 0 %s", 
            $time, a, b, cin, sum, cout, 
            (sum == 1 && cout == 0) ? "✓" : "✗");

        $display("========================================");
        $finish;
    end

    initial begin
        $dumpfile("sim/tb_adder4.vcd");
        $dumpvars(0, tb_adder4);
    end
endmodule