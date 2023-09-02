`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.08.2023 11:14:06
// Design Name: 
// Module Name: sendModule
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


module sendModule(
    input clock, // 100 MHz onboard clock
    input reset,
    output oled_spi_clk,
    output oled_spi_data,
    output oled_vdd,
    output oled_vbat,
    output oled_reset_n,
    output oled_dc_n
    );
    
    localparam myString = "Hello world"; 
    localparam stringLen = 11;
    localparam IDLE = 'd0, SEND = 'd1, DONE = 'd2;
    reg [1:0] state;
    reg [7:0] send_data;
    reg send_data_valid;
    wire send_done;
    integer byte_counter;
    always @(posedge clock)
    begin
        if(reset)
        begin
            state <= IDLE;
            byte_counter <= stringLen; 
            send_data_valid <= 1'b0;
        end 
        else 
        begin
            case(state)
                IDLE:   begin
                            if(!send_done)
                            begin 
                                send_data <= myString[(byte_counter*8 - 1)-:8];    
                                send_data_valid <= 1'b1; 
                                state <= SEND;
                            end
                        end
                SEND:   begin 
                            if(send_done)
                            begin 
                                send_data_valid <= 1'b0; 
                                byte_counter <= byte_counter - 1;
                                if(byte_counter != 1)
                                    state <= IDLE;
                                else  
                                    state <= DONE;
                            end
                        end 
                DONE:   begin
                            state <= DONE; 
                        end
            endcase
        end
    end
    // at a time we will take one character from the string and send it to oled controller.
    oledControl(
    .clock(clock), // 100 MHz onboard clock
    .reset(reset),
    
    .send_data(send_data),
    .send_data_valid(send_data_valid),
    .send_done(send_done),
    .oled_spi_clk(oled_spi_clk),
    .oled_spi_data(oled_spi_data),
    .oled_vdd(oled_vdd),
    .oled_vbat(oled_vbat),
    .oled_reset_n(oled_reset_n),
    .oled_dc_n(oled_dc_n)
    );
endmodule
