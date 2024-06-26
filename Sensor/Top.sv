`timescale 1ns / 1ps

module top  #(parameter N=32)(
    input logic     clk,
    input logic rst,
    input logic miso,
    input logic reg_sel,
    input logic wr,
    input logic [N-1:0]  in_i,
    input logic [N-1:0]  addr_i,
    
    output logic cs_control,
    input logic mosi,
    output logic sclk,
    output logic tx_done_o,
    output logic [N-1:0]    out_o,
    output logic [7:0]  testmemo,
    output logic [7:0] memdir
);

logic [31:0]  control;
  logic [31:0]  instruccion_spi;
  logic [7:0]   dato_memoria;
  logic [7:0]   direccion;
  logic [7:0]   control_dir;
  logic         wr1_control;
  logic         wr1_datos;
  logic         wr2;
  logic [7:0]  puente_datos;
  logic [7:0]   rx_data;
  logic [9:0]  n_rx_end;
  logic         control_we;


//SPI

controlador_SPI SPI (
                    .clk_i(clk),
                    .rst_i(rst),
                    .MISO_i(miso),
                    .tx_data_i(dato_memoria),
                    .send_i(control[0]),
                    .n_tx_end_i(control [12:4]),
                    .rx_data_o(rx_data),
                    .cs_ctrl_o(cs_control),
                    .MOSI_o(mosi),
                    .sclk_o(sclk),
                    .tx_done_o(tx_done_o),
                    .n_rx_end_o(n_rx_end),
                    .all_1s_i(control[2]),
                    .all_0s_i(control[3]),
                    .instruccion_o(instruccion_spi),
                    .we_2_o(wr2)     
                     );
//Registro de control
registro_control reg_control (
        .clk(clk),
        .rst(rst),
        .IN1(in_i),
        .IN2(instruccion_spi),
        .WR1(wr1_control),
        .WR2(tx_done_o),
        .OUT(control)
    );
    //Registro de datos
    registro_datos reg_datos(
    .clk(clk),
    .rst(rst),
    .IN1(in_i),
    .IN2(instruccion_spi),
    .WR1(wr1_control),
    .WR2(tx_done_o),
    .OUT(control)
    );
//mux para cargar datos
  mux_2_to_1 #(32) carga_datos(
        .sel(control[0]),
        .in1(in_i),
        .in2(rx_data),
        .out(puente_datos)
    );
//mux WE RAM

 mux_2_to_1 #(1) write_enable_RAM(
        .sel(control[0]),
        .in1(wr1_datos),
        .in2(wr2),
        .out(control_we)
    );
    
//Cuenta de direcciones
   cuenta_direccion direcciones(
        .tx_done_o(tx_done_o),
        .reset_i(rst),
        .direccion_o(direccion)
    );

//mux direccion de datos

 mux_2_to_1 #(32) direccion_datos(
        .sel(control[0]),
        .in1(addr_i),
        .in2(direccion),
        .out(control_dir)
    );
//mux de salida de datos
 mux_2_to_1 #(32) salida(
        .sel(reg_sel),
        .in1(control),
        .in2(dato_memoria),
        .out(out_o)
    );

//demux para los WE de los registros.
 demux_1_to_2 write_enable_1(
        .en_i(wr),
        .sel_i(reg_sel),
        .reg1_o (wr1_control),
        .reg2_o (wr1_datos)
    );
  assign testmemo = dato_memoria;
    assign memdir = control_dir;
endmodule