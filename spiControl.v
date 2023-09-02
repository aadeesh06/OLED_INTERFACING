`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 28.08.2023 12:22:16
// Design Name:
// Module Name: spiControl
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module spiControl(clock, reset, data_in, load_data, spi_clock, spi_data, done_send);
    input clock; // On board Zynq clock(100 MHz)
    input reset;
    input [7:0] data_in;
    input load_data; // signal indicates new data for transmission
    output spi_clock;  // maximum 10 MHz
    output reg spi_data;
    output reg done_send; // signal indicates that data has been sent over spi interface
   
    reg [2:0] counter = 0;
    reg [2:0] dataCount;
    reg [7:0] shiftReg;
    reg [1:0] state;
    reg clock_10;
    reg CE;
    assign spi_clock = (CE == 1) ? clock_10 : 1'b1;
    localparam IDLE = 2'b00, SEND = 2'b01, DONE = 2'b10;
    always @(posedge clock)
    begin
        if(counter != 4)
            counter <= counter + 1;
        else
            counter <= 0;
    end
    initial    // this initial block is not manadatory. It is only for simulation purposes.
    begin
        clock_10 <= 0;
    end
    always @(posedge clock)
    begin
        if(counter == 4)
            clock_10 <= ~clock_10;
    end
   
   
    always @(negedge clock_10)    // data should be sent at negative edge of clock so that oled can read it at positive edge
    begin
        if(reset)
        begin
            state <= IDLE;
            dataCount <= 0;
            done_send <= 0;
            CE <= 0;
            spi_data <= 1'b0;
        end
        else
        begin
            case(state)
                IDLE: begin
                            if(load_data)    // when data is to be sent
                            begin
                                shiftReg <= data_in;
                                state <= SEND;
                                dataCount <= 0;
                            end
                      end
                SEND: begin
                            spi_data <= shiftReg[7];
                            shiftReg <= {shiftReg[6:0], 1'b0};   // 6 bit now becomes seventh bit
                            CE <= 1;
                            if(dataCount != 7)
                                dataCount <= dataCount + 1;
                           
                            else    // when data count is 7
                                state <= DONE;
                           
                      end
                 
                  DONE: begin
                            CE <= 0;
                            done_send <= 1'b1;
                            if(!load_data)
                            begin
                                done_send <= 1'b0;
                                state <= IDLE;
                            end
                        end
            endcase
                   
        end
    end
endmodule