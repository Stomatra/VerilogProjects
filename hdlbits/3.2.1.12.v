module top_module (
    input clk,
    input w, R, E, L,
    output Q
);
    wire D1,D2;
    assign D1=E?w:Q;
    assign D2=L?R:D1;
    always @(posedge clk) begin
        Q <= D2;
    end
endmodule