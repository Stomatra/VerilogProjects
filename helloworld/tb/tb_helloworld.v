// ========================================
// 测试平台: tb_helloworld
// 功能: 测试 helloworld 模块
// 作者: Stomatra
// 日期: 2026-03-18
// ========================================

`timescale 1ns/1ps

module tb_helloworld;

    // ========================================
    // 1. 参数定义
    // ========================================
    parameter CLK_PERIOD = 10;  // 时钟周期 10ns (100MHz)

    // ========================================
    // 2. 信号声明
    // ========================================
    reg         clk;
    reg         rst_n;
    reg  [7:0]  data_in;
    wire [7:0]  data_out;

    // ========================================
    // 3. 时钟生成
    // ========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ========================================
    // 4. 例化待测设计 (DUT)
    // ========================================
    helloworld u_helloworld (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in),
        .data_out (data_out)
    );

    // ========================================
    // 5. 激励生成
    // ========================================
    initial begin
        // 初始化信号
        rst_n   = 0;
        data_in = 8'h00;

        // 打印测试开始信息
        $display("========================================");
        $display("  helloworld Testbench");
        $display("  Start Time: %0t", $time);
        $display("========================================");

        // 复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        $display("[%0t] Reset released", $time);

        // 测试用例 1
        #(CLK_PERIOD);
        data_in = 8'hAA;
        $display("[%0t] Test 1: data_in = 0x%h", $time, data_in);

        // 测试用例 2
        #(CLK_PERIOD * 2);
        data_in = 8'h55;
        $display("[%0t] Test 2: data_in = 0x%h", $time, data_in);

        // 测试用例 3
        #(CLK_PERIOD * 2);
        data_in = 8'hFF;
        $display("[%0t] Test 3: data_in = 0x%h", $time, data_in);

        // 等待几个周期
        #(CLK_PERIOD * 5);

        // 测试结束
        $display("========================================");
        $display("  Simulation Finished!");
        $display("  End Time: %0t", $time);
        $display("========================================");
        $finish;
    end

    // ========================================
    // 6. 波形文件生成
    // ========================================
    initial begin
        $dumpfile("sim/tb_helloworld.vcd");
        $dumpvars(0, tb_helloworld);
    end

    // ========================================
    // 7. 监控输出（可选）
    // ========================================
    // initial begin
    //     $monitor("Time=%0t clk=%b rst_n=%b data_in=%h data_out=%h", 
    //         $time, clk, rst_n, data_in, data_out);
    // end

endmodule
