/*Create a set of counters suitable for use as a 12-hour clock (with am/pm indicator). Your counters are clocked by a fast-running clk, with a pulse on ena whenever your clock should increment (i.e., once per second).
创建一组适合用作 12 小时制时钟（带上午/下午指示器）的计数器。您的计数器由快速运行的 clk 驱动，每当您的时钟应递增时（即每秒一次）， ena 上会产生一个脉冲。

reset resets the clock to 12:00 AM. pm is 0 for AM and 1 for PM. hh, mm, and ss are two BCD (Binary-Coded Decimal) digits each for hours (01-12), minutes (00-59), and seconds (00-59). Reset has higher priority than enable, and can occur even when not enabled.
reset 将时钟重置为 12:00 AM。 pm 为 0 表示上午，为 1 表示下午。 hh 、 mm 和 ss 分别表示小时（01-12）、分钟（00-59）和秒（00-59）的两个 BCD（二进制编码十进制）数字。重置的优先级高于使能，即使未使能时也可能发生重置。

The following timing diagram shows the rollover behaviour from 11:59:59 AM to 12:00:00 PM and the synchronous reset and enable behaviour.
以下时序图展示了从 11:59:59 AM 到 12:00:00 PM 的翻转行为，以及同步复位和使能的行为。*/

module top_module(
    input clk,
    input reset,
    input ena,
    output pm,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss); 
    
    wire [6:1] enable;
    wire [7:0] hh_r;
    
    assign enable[1]=ena && (ss[3:0]==4'h9);
    assign enable[2]=enable[1]&&(ss[7:4]==4'h5);
    assign enable[3]=enable[2]&&(mm[3:0]==4'h9);
    assign enable[4]=enable[3]&&(mm[7:4]==4'h5);
    assign enable[5]=enable[4]&&(hh[3:0]==4'hb);
    assign enable[6]=enable[5]&&(hh[7:4]==4'h1);
    
    BCD_cnt #(.START(4'h0),.END(4'h9)) ss9(clk,reset,ena,ss[3:0]);
    BCD_cnt #(.START(4'h0),.END(4'h5)) ss5(clk,reset,enable[1],ss[7:4]);

    BCD_cnt #(.START(4'h0),.END(4'h9)) mm9(clk,reset,enable[2],mm[3:0]);
    BCD_cnt #(.START(4'h0),.END(4'h5)) mm5(clk,reset,enable[3],mm[7:4]);

    BCD_cnt #(.START(4'h0),.END(4'hb)) hhb(clk,reset,enable[4],hh_r[3:0]);
    BCD_cnt #(.START(4'h0),.END(4'h1)) hh1(clk,reset,enable[5],hh_r[7:4]);

    wire toggle_pm=enable[4]&&(hh_r[7:4]==4'h0)&&(hh_r[3:0]==4'hb);

    always @(posedge clk) begin
        if(reset)
            pm<=1'b0;
        else if(toggle_pm)
            pm<=~pm;
        else
            pm<=pm;
    end

    assign hh=  
            (hh_r[3:0]==4'h0)?8'h12:
            ((hh_r[3:0]>4'h9)?{4'h1,hh_r[3:0]-4'ha}:
                              {4'h0,hh_r[3:0]});
    
endmodule

module BCD_cnt(
    input clk,
    input reset,
    input ena,
    output reg [3:0] q
);
    parameter START=4'h0,END=4'h9;
    
    always @(posedge clk) begin
        if(reset)
            q<=START;
        else if(ena)
            q<=(q==END)?START:q+4'h1;
        else
            q<=q;
    end
endmodule
