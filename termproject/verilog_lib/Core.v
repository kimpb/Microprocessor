
module Core(

	output wire [63:0] o_pm_addr, //pm addr
	output wire o_pm_cs, //pm chip select
	input wire [31:0] i_pm_data, //pm read data

	output wire [63:0] o_dm_addr, //dm addr
	output wire o_dm_cs, //dm chip select
	output wire o_dm_rw, //read = 0, write = 1
	output wire [63:0] o_dm_data, //dm write data
	input wire [63:0] i_dm_data, // dm read data
	
	input wire i_clk,
	input wire i_rst
);


wire ALUSrc;
wire MemtoReg;
wire RegWrite;
wire MemRead;
wire MemWrite;
wire Branch;
wire ALUOp1;
wire ALUop0; // ALUcontrolsignals

wire [31:0] trans_pm_data; // instruction order change
wire [63:0] prev_pm_addr;
wire [63:0] ALUinput1;
wire [63:0] ALUinput2;
wire [63:0] ALUresult;
wire [3:0] ALUcontrolinput;

Dregister_rst #(
    .WIDTH(10),
	.RESET_VALUE(10'b0)
)u1(
    .i(o_pm_addr[9:0] + 1'b1),
	.o(o_pm_addr[9:0]),
	.i_clk(i_clk),
	.i_rst(i_rst)
);
wire [63:0] readdata1;
wire [63:0] readdata2; 
wire [2:0] i_type; // intruction type
assign o_pm_cs = 1'b1;
assign trans_pm_data = {i_pm_data[7:0],i_pm_data[15:8],i_pm_data[23:16],i_pm_data[31:24]};

RegFile_32x64bit reg0(
    .i_read0(1'b1),
    .i_read_addr0(trans_pm_data[19:15]),
    .o_read_data0(readdata1),
    .i_read1(trans_pm_data[5]),
    .i_read_addr1(trans_pm_data[24:20]),
    .o_read_data1(readdata2),
    .i_write(RegWrite),
    .i_write_addr(trans_pm_data[24:20]),
    .i_write_data(readdata1),
    .i_clk(i_clk),
    .i_rst(i_rst));

wire [7:0] LUTOUT;
LUT #(
        .ROM_FILE("dec.bin"),
        .INPUT_WIDTH(3),
        .OUTPUT_WIDTH(8)
)LUTO(
        .i(i_type[2:0]),
        .o(LUTOUT)
);

wire [63:0] signext;

assign i_type = (trans_pm_data[6:0] == 7'b0110011) ? 3'b000 : (trans_pm_data[6:0] == 7'b0010011) ? 3'b001 : (trans_pm_data[6:0] == 7'b0000011) ? 3'b010 : (trans_pm_data[6:0] == 7'b0100011) ? 3'b011 : (trans_pm_data[6:0] == 7'b1100011) ? 3'b100 : (trans_pm_data[6:0] == 7'b1100111) ? 3'b101 : (trans_pm_data[6:0] == 7'b1101111) ? 3'b110 : 3'b111;
// instruction type 000 = R type, 001 = I type, 010 = LD, 011 = SD, 100 = BEQ, 101 = JALR, 110 = JAL, 111 = else

assign ALUSrc = LUTOUT[7]; 
assign MemtoReg = LUTOUT[6]; 
assign RegWrite = LUTOUT[5]; 
assign MemRead = LUTOUT[4]; 
assign MemWrite = LUTOUT[3]; 
assign Branch = LUTOUT[2]; 
assign ALUOp1 = LUTOUT[1]; 
assign ALUop0 = LUTOUT[0]; 
assign ALUinput1 = readdata1;
assign ALUinput2 = ALUSrc ? readdata2 : {32'b0,signext};
assign signext = trans_pm_data[31] ?  {52'b1,trans_pm_data[31:20]+1'b1} : {52'b0,trans_pm_data[31:20]};

endmodule
