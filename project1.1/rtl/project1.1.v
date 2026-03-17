module Test (
    //单比特(1位)
    wire a;
    reg flag;

    //多比特(向量)
    wire [7:0]  data;//8位
    reg  [15:0] counter;//16位
    wire [3:0]  nibble;//4位

    reg  [7:0] mem [0:255];//256个8位寄存器(类似内存)

    //格式:<位宽>'<进制><值>
    4'b1010//4位二进制数，值为1010
    8'hFF//8位十六进制数，值为FF(255)
    12'd255//12位十进制数，值为255
    16'o777//16位八进制数，值为777

    //不指定位宽(默认32位)
    'b1010  //二进制10
    'hFF    //十六进制255
    42      //十进制42

    //特殊值
    4'bxxxx //不定态
    4'bzzzz //高阻态

    //下划线增强可读性
    32'h1234_5678//32位十六进制数，值为12345678
    8'b1111_0000 //8位二进制数，值为240

    //算术运算符
    //+ 加法
    //- 减法
    //* 乘法
    /// 除法
    //% 取模

    //示例
    wire [7:0] a = 8'd10
    wire [7:0] b = 8'd3
    wire [7:0] sum=a+b//sum=13,因为10加3等于13
    wire [7:0] product=a*b//product=30,因为10乘3等于30

    //位运算符
    //~ 按位取反
    //& 按位与
    //| 按位或
    //^ 按位异或
    //~^ 按位同或

    //示例
    wire [3:0] a =4'b1000
    wire [3:0] b =4'b1110

    assign c=a&b//c=4'b1000，因为只有最高位都是1，其他位至少有一个是0
    assign d=a|b//d=4'b1110，因为只要有一个位是1，结果就是1
    assign e=a^b//e=4'b0110，因为只有第二位和第三位不同，结果是1
    assign f=~a//f=4'b0111，因为按位取反将1000的每一位取反得到0111

    //归约运算符
    //& 归约与(所有位 AND)
    //| 归约或(所有位 OR)
    //^ 归约异或(奇偶校验)

    wire [3:0] data =4'b1010;

    assign parity=^data;//parity=1，因为1010中有两个1，奇数个1的异或结果为1
    assign all_high=&data;//all_high=0，因为1010中有一个0，归约与结果为0
    assign any_high=|data;//any_high=1，因为1010中至少有一个1，归约或结果为1

    //逻辑运算符
    //! 逻辑非
    //|| 逻辑或
    //&& 逻辑与

    //返回1(true)或0(false)
    wire a=5;
    wire b=0;
    wire c=(a && b);//c=0，因为b为0，逻辑与结果为假
    wire d=(a || b);//d=1，因为a为非零，逻辑或结果为真

    //关系运算符
    //== 等于
    //!= 不等于
    //> 大于
    //< 小于
    //>= 大于等于
    //<= 小于等于

    //示例
    wire [3:0] a=4'd5;
    wire [3:0] b=4'd10;
    wire result=(a < b);//result=1，因为5小于10

    //移位运算符
    //<< 逻辑左移
    //>> 逻辑右移
    //<<< 算术左移(同逻辑左移)
    //>>> 算术右移(保留符号位)

    //示例
    wire [7:0] data=8'b0000_1010;//8位二进制数，值为10
    wire [7:0] left=data<<2;//left=8'b0010_1000，因为逻辑左移2位将数据乘以4
    wire [7:0] right=data>>2;//right=8'b0000_0010，因为逻辑右移2位将数据除以4

    //拼接运算符
    {a,b} //将a和b拼接成一个更宽的向量，a在高位，b在低位
    {n{a}}//将a重复n次拼接成一个更宽的向量

    //示例
    wire [3:0] a=4'b1010;
    wire [3:0] b=4'b0011;

    wire [7:0] c={a,b};//c=8'b1010_0011，因为将a和b拼接成一个8位向量
    wire [7:0] d={4{a[3]}};//d=8'b1111_1111，因为a[3]是1，重复4次拼接成一个8位向量
    wire [11:0] e={4'b0,a,b};//e=12'b0000_1010_0011，因为将4位0、a和b拼接成一个12位向量

    //条件运算符(三目运算符)
    condition ? true_value : false_value//如果condition为真，结果是true_value，否则是false_value

    //示例
    wire [3:0] a=4'd5;
    wire [3:0] b=4'd10;
    wire [3:0] result = (a > b) ? a : b;//result=10，因为条件a > b为假，结果是b的值10

    //多路选择
    wire [7:0] out=(sel=2'b00) ? a :
                   (sel=2'b01) ? b :
                   (sel=2'b10) ? c : d;//根据sel的值选择输出a、b、c或d
    
);
endmodule

module mux4to1(
    input wire[1:0] sel,
    input wire[7:0] in0, in1, in2, in3,
    output wire[7:0] out
);
    //多路选择器，根据sel的值选择输出in0、in1、in2或in3
    assign out=(sel==2'b00) ? in0 :
               (sel==2'b01) ? in1 :
               (sel==2'b10) ? in2 : in3;//根据sel的值选择输出in0、in1、in2或in3

endmodule

module mux4to1 (
    input wire [1:0] sel,
    input wire [7:0] in0, in1, in2, in3,
    output reg [7:0] out
);
    //always @(*)表示对所有输入敏感
    always @(*) begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
        endcase
    end
endmodule