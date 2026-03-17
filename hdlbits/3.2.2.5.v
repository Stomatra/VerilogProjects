module top_module (
    input clk,
    input reset,
    input enable,
    output [3:0] Q,
    output c_enable,
    output c_load,
    output [3:0] c_d
); //

    always @(posedge clk) begin
        if(reset) begin
            Q <= 4'b0;
        end else if(enable) begin
            count4 the_counter (clk, c_enable, c_load, c_d, Q);
        end
    end

endmodule
