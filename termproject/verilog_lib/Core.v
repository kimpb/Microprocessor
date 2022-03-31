
module Core(

	output wire [63:0] o_pm_addr, //pm addr
	output wire o_pm_cs, //pm chip select
	input wire [31:0] i_pm_data, //pm read data

	output wire [63:0] o_dm_addr, //dm addr
	output wire o_dm_cs, //dm chip select
	output wire [63:0] o_dm_we, //read = 0, write = 1
	output wire [63:0] o_dm_data, //dm write data
	input wire [63:0] i_dm_data, // dm read data
	
	input wire i_clk,
	input wire i_rst
);



wire ALUop1;
wire ALUop0; // ALUcontrolsignals
wire [6:0] funct7;
wire [2:0] funct3;
wire [6:0] opcode;
wire [4:0] rs2;
wire [4:0] rs1;
wire [4:0] rd;
wire [63:0] PC;


wire [7:0] IDEX_ctrlsignal;
wire [3:0] IDEX_ALUcontrolinput;
wire [4:0] IDEX_rs1;
wire [4:0] IDEX_rs2;
wire [4:0] IDEX_rd;
wire [31:0] IDEX_tempinstruction;
wire [31:0] IDEX_instruction;
wire [2:0] IDEX_i_type;
wire IDEX_takebranch;
wire IDEX_stall;

wire [7:0] EXMEM_ctrlsignal;
wire [4:0] EXMEM_rs1;
wire [4:0] EXMEM_rs2;
wire [63:0] EXMEM_readdata2;
wire [4:0] EXMEM_rd;
wire [63:0] EXMEM_ALUresult;
wire [31:0] EXMEM_instruction;
wire [2:0] EXMEM_i_type;

wire [7:0] MEMWB_ctrlsignal;
wire [4:0] MEMWB_rs1;
wire [4:0] MEMWB_rs2;
wire [63:0] MEMWB_readdata2;
wire [63:0] MEMWB_ALUresult;
wire [4:0] MEMWB_rd;
wire [2:0] MEMWB_i_type;
wire [31:0] MEMWB_instruction;

wire [7:0] ctrlsignal;

wire [63:0] IDEXA;
wire [63:0] IDEXB; 
wire [2:0] i_type; // intruction type




wire [31:0] instruction; // instruction order change
wire [63:0] ALUinput1;
wire [63:0] ALUinput2;
wire [63:0] ALUresult;
wire [3:0] ALUcontrolinput;

assign funct7[6:0] = instruction[31:25];
assign funct3[2:0] = instruction[14:12];
assign opcode[6:0] = instruction[6:0];
assign rs2[4:0] = instruction[24:20];
assign rs1[4:0] = instruction[19:15];
assign rd[4:0] = instruction[11:7];

wire [63:0] temp_pmaddr;

assign o_pm_addr = stall? temp_pmaddr - 1: temp_pmaddr;


Dregister_rst #(
    .WIDTH(64),
	.RESET_VALUE(64'b0)
)pmaddress(
    .i(temp_PC+4>>2),
	.o(temp_pmaddr),
	.i_clk(i_clk),
	.i_rst(i_rst)
);

Dregister_rst #(
    .WIDTH(64),
	.RESET_VALUE(64'b0)
)programcount(
    .i(temp_PC+3'd4),
	.o(PC),
	.i_clk(i_clk),
	.i_rst(i_rst)
);




Dregister_rst #(
    .WIDTH(64),
	.RESET_VALUE(64'b0)
)IDEX(
    .i({ctrlsignal, temp_instruction, ALUcontrolinput, rs1, rs2, rd, i_type, takebranch, stall}),
	.o({IDEX_ctrlsignal, IDEX_instruction, IDEX_ALUcontrolinput, IDEX_rs1, IDEX_rs2, IDEX_rd, IDEX_i_type, IDEX_takebranch, IDEX_stall}),
	.i_clk(i_clk),
	.i_rst(i_rst)
);



Dregister_rst #(
    .WIDTH(186),
	.RESET_VALUE(186'b0)
)EXMEM(
    .i({IDEX_ctrlsignal, IDEX_instruction, IDEX_rs1, IDEX_rs2, ALUresult, IDEXB, IDEX_rd, IDEX_i_type}),
	.o({EXMEM_ctrlsignal, EXMEM_instruction, EXMEM_rs1, EXMEM_rs2, EXMEM_ALUresult, EXMEM_readdata2, EXMEM_rd, EXMEM_i_type}),
	.i_clk(i_clk),
	.i_rst(i_rst)
);

Dregister_rst #(
    .WIDTH(186),
	.RESET_VALUE(186'b0)
)MEMWB(
    .i({EXMEM_ctrlsignal, EXMEM_instruction, EXMEM_rs1, EXMEM_rs2, EXMEM_readdata2, EXMEM_ALUresult, EXMEM_rd, EXMEM_i_type}),
	.o({MEMWB_ctrlsignal, MEMWB_instruction, MEMWB_rs1, MEMWB_rs2, MEMWB_readdata2, MEMWB_ALUresult, MEMWB_rd, MEMWB_i_type}),
	.i_clk(i_clk),
	.i_rst(i_rst)
);




assign o_pm_cs = 1'b1;
assign instruction = {i_pm_data[7:0],i_pm_data[15:8],i_pm_data[23:16],i_pm_data[31:24]} ;

RegFile_32x64bit reg0(
    .i_read0(1'b1),
    .i_read_addr0(rs1),
    .o_read_data0(IDEXA),
    .i_read1(1'b1),
    .i_read_addr1(rs2),
    .o_read_data1(IDEXB),
    .i_write(updateregister),
    .i_write_addr(MEMWB_rd),
    .i_write_data(MEMWB_value),
    .i_clk(i_clk),
    .i_rst(i_rst));

LUT #(
        .ROM_FILE("dec.bin"),
        .INPUT_WIDTH(3),
        .OUTPUT_WIDTH(8)
)LUTO(
        .i(i_type[2:0]),
        .o(ctrlsignal)
);
// ctrlsignal[7] = ALUsrc, ctrlsignal[6] = MemtoReg, ctrlsignal[5] = Regwrite, ctrlsignal[4] = MemRead, ctrlsignal[3] = MemWrite, ctrlsignal[2] = Branch, ctrlsignal[1] = ALUop1, ctrlsignal[0] = ALUop0 

assign i_type = (instruction[6:0] == 7'b0110011) ? 3'b000 : (instruction[6:0] == 7'b0010011) ? 3'b001 : (instruction[6:0] == 7'b0000011) ? 3'b010 : (instruction[6:0] == 7'b0100011) ? 3'b011 : (instruction[6:0] == 7'b1100011) ? 3'b100 : (instruction[6:0] == 7'b1100111) ? 3'b101 : (instruction[6:0] == 7'b1101111) ? 3'b110 : 3'b111;
// instruction type 000 = R type, 001 = I type, 010 = LD, 011 = SD, 100 = BEQ, 101 = JALR, 110 = JAL, 111 = else

wire [1:0] ForwardA;
wire [1:0] ForwardB;
wire [63:0] MEMWB_value;
wire [31:0] temp_instruction;
wire [63:0] temp_PC;
wire takebranch;
wire stall;


assign temp_instruction = ((MEMWB_i_type == 3'b101) || (MEMWB_i_type == 3'b110) || (IDEX_i_type == 3'b101) || (IDEX_i_type == 3'b110) || (EXMEM_i_type == 3'b101) || (EXMEM_i_type == 3'b110)|| (~stall && takebranch) || stall || IDEX_takebranch) ? NOP : instruction;
assign temp_PC = stall? PC - 4: (~stall && takebranch) ? PC + {{52{IDEX_instruction[31]}}, IDEX_instruction[7], IDEX_instruction[30:25], IDEX_instruction[11:8], 1'b0} - 16 : (IDEX_i_type == 3'b110) ? PC + {{44{IDEX_instruction[31]}}, IDEX_instruction[19:12], IDEX_instruction[20], IDEX_instruction[30:21], 1'b0} - 12 : (IDEX_i_type == 3'b101) ? {{52{IDEX_instruction[31]}}, IDEX_instruction[31:20]} + IDEXA - 4 : PC;
assign stall = (IDEX_i_type == 3'b010) && (((IDEX_rd == rs1) || (IDEX_rd == rs2))) ? 1'b1 : 1'b0;
assign takebranch = (IDEX_i_type == 3'b100) && (IDEXA == IDEXB);
assign ALUcontrolinput = ({ALUop1,ALUop0} == 2'b00) ? 4'b0010 : ({ALUop1,ALUop0} == 2'b01) ? 4'b0110 : ({ALUop1,ALUop0} == 2'b10)&&({funct7,funct3} == 10'b0) ? 4'b0010 : ((i_type == 3'b001) && (funct3 == 3'b000)) ? 4'b0010 : ((i_type == 3'b001) && (funct3 == 3'b111)) ? 4'b0000 : ({ALUop1,ALUop0} == 2'b10)&&({funct7,funct3} == 10'b0100000000) ? 4'b0110 : ({ALUop1,ALUop0} == 2'b10)&&({funct7,funct3} == 10'b0000000111) ? 4'b0000 :({ALUop1,ALUop0} == 2'b10)&&({funct7,funct3} == 10'b0000000110) ? 4'b0001 : 4'b1111;
parameter LD = 7'b000_0011, SD = 7'b010_0011, BEQ = 7'b110_0011, NOP = 32'h0000_0013, ALUop = 7'b001_0011;


assign ForwardA = (EXMEM_ctrlsignal[5] && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs1)) ? 2'b10 : (MEMWB_ctrlsignal[5] && (MEMWB_rd != 5'b0) && ~(EXMEM_ctrlsignal[5] && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs1)) && (MEMWB_rd == IDEX_rs1)) ? 2'b01 : 2'b00;
assign ForwardB = (EXMEM_ctrlsignal[5] && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs2)) ? 2'b10 : (MEMWB_ctrlsignal[5] && (MEMWB_rd != 5'b0) && ~(EXMEM_ctrlsignal[5] && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs2)) && (MEMWB_rd == IDEX_rs2)) ? 2'b01 : 2'b00;


wire updateregister;
assign updateregister =  ((MEMWB_i_type == 3'b010) || (MEMWB_i_type == 3'b000) || (MEMWB_i_type == 3'b001) || (MEMWB_i_type == 3'b101) || (MEMWB_i_type == 3'b110))  && (MEMWB_rd != 5'b0) ? 1'b1 : 1'b0;
wire [6:0] IDEXop, EXMEMop, MEMWBop;
assign IDEXop = IDEX_instruction[6:0];
assign EXMEMop = EXMEM_instruction[6:0];
assign MEMWBop = MEMWB_instruction[6:0];
assign o_dm_addr = ((EXMEM_i_type == 3'b010) || (EXMEM_i_type == 3'b011)) ? EXMEM_ALUresult >> 2 : 64'b0;
assign MEMWB_rd = MEMWB_instruction[11:7];
assign o_dm_cs = ((EXMEM_i_type == 3'b010) || (EXMEM_i_type == 3'b011)) ? 1'b1 : 1'b0;
assign o_dm_we = (EXMEM_i_type == 3'b010) ? 64'b0 : (EXMEM_i_type == 3'b011) ? 64'hFFFF_FFFF_FFFF_FFFF : 64'b0;
assign MEMWB_value = (MEMWB_i_type == 3'b010) ? i_dm_data : ((MEMWB_i_type == 3'b101) || (MEMWB_i_type == 3'b110)) ? PC - 16  : MEMWB_ALUresult;
assign o_dm_data = (EXMEM_i_type == 3'b011) ? EXMEM_readdata2 : 64'b0;

assign ALUop1 = ctrlsignal[1]; 
assign ALUop0 = ctrlsignal[0]; 
assign ALUinput1 = (ForwardA == 2'b00) ? IDEXA : (ForwardA == 2'b10) ? EXMEM_ALUresult : (ForwardA == 2'b01) ? MEMWB_value : IDEXA;
assign ALUinput2 = IDEX_ctrlsignal[7] ? {{53{IDEX_instruction[31]}}, IDEX_instruction[30:20]} : (ForwardB == 2'b00) ? IDEXB : ((ForwardB == 2'b10) && (EXMEM_i_type == 3'b010)) ? i_dm_data : (ForwardB == 2'b10) ? EXMEM_ALUresult : (ForwardB == 2'b01) ? MEMWB_value : IDEXB;
assign ALUresult = (IDEX_i_type == 3'b010) ? ALUinput1 + {{53{IDEX_instruction[31]}}, IDEX_instruction[30:20]} : (IDEX_i_type == 3'b011) ? ALUinput1 + {{53{IDEX_instruction[31]}}, IDEX_instruction[30:25],IDEX_instruction[11:7]} : (IDEX_ALUcontrolinput == 4'b0010)? ALUinput1 + ALUinput2 : (IDEX_ALUcontrolinput == 4'b0110)? ALUinput1 - ALUinput2 : (IDEX_ALUcontrolinput == 4'b0000)? ALUinput1 & ALUinput2 : (IDEX_ALUcontrolinput == 4'b0001)? ALUinput1 | ALUinput2 : 64'b0;

endmodule
