`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.08.2023 15:26:01
// Design Name: 
// Module Name: oledControl
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


module oledControl(
    input clock, // 100 MHz onboard clock
    input reset,
    
    input [6:0] send_data,
    input send_data_valid,
    output reg send_done,
    output wire oled_spi_clk,
    output wire oled_spi_data,
    output reg oled_vdd,
    output reg oled_vbat,
    output reg oled_reset_n,
    output reg oled_dc_n
    );
    reg [4:0] oled_state, oled_next_state;
    reg oled_start_delay;
    reg [7:0] oled_spi_data_in;
    reg oled_load_data;
    reg [1:0]current_page;
    reg [7:0] column_counter;
    reg [3:0] byte_counter;
    wire [63:0] char_bit_map;
    
    wire oled_delay_done;
    wire oled_done_send;
    localparam IDLE = 'd0, DELAY = 'd1, INIT = 'd2, RESET = 'd3, CHARGED_PUMP = 'd4, CHARGED_PUMP1 = 'd5, WAIT_SPI = 'd6, PRE_CHARGE = 'd7;
    localparam PRE_CHARGE1 = 'd8, VBAT_ON = 'd9, CONTRAST = 'd10, CONTRAST1 = 'd11, SEG_REMAP = 'd12, SCAN_DIR = 'd13, COM_PIN = 'd14, COM_PIN1 = 'd15, DISPLAY_ON = 'd16, FULL_DISPLAY = 'd17, DONE = 'd18;
    localparam PAGE_ADDRESS= 'd19, PAGE_ADDRESS1 = 'd20, PAGE_ADDRESS2 = 'd21, COLUMN_ADDRESS = 'd22, SEND_DATA = 'd23;
    always @(posedge clock)
    begin 
        if(reset)
        begin
            oled_state <= IDLE;
            oled_next_state <= IDLE;
            oled_vdd <= 1'b1;
            oled_vbat <= 1'b1;
            oled_reset_n <= 1'b1;
            oled_dc_n <= 1'b1;
            oled_start_delay <= 1'b0;
            oled_spi_data_in <= 8'b0;
            oled_load_data <= 1'b0;
            current_page <= 2'b0;
            send_done <= 1'b0;
            column_counter <= 1'b0;
        end
        else 
        begin
            case(oled_state)
                IDLE:   begin
                            oled_vbat <= 1'b1;
                            oled_reset_n <= 1'b1;
                            oled_dc_n <= 1'b0;
                            oled_vdd <= 1'b0;
                            oled_state <= DELAY;
                            oled_next_state <= INIT;
                        end
                DELAY:  begin
                            oled_start_delay <= 1'b1;
                            if(oled_delay_done)
                            begin 
                                oled_state <= oled_next_state;
                                oled_start_delay <= 1'b0;
                            end
                        end
                INIT:   begin
                            oled_spi_data_in <= 'hAE;
                            oled_load_data <= 1'b1;
                            if(oled_done_send)
                            begin
                                oled_load_data <= 1'b0;
                                oled_reset_n <= 1'b0;
                                oled_state <= DELAY; 
                                oled_next_state <= RESET;
                            end
                        end
                RESET:  begin
                             oled_reset_n <= 1'b1;
                             oled_state <= DELAY;
                             oled_next_state <= CHARGED_PUMP;
                        end
                CHARGED_PUMP:   begin
                                    oled_spi_data_in <= 'h8D;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= CHARGED_PUMP1;
                                    end 
                                end
                WAIT_SPI:      begin
                                    if(!oled_done_send)
                                    begin
                                        oled_state <= oled_next_state; 
                                end
                            end
                        
                CHARGED_PUMP1:  begin 
                                    oled_spi_data_in <= 'h14;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= PRE_CHARGE;
                                    end 
                                end      
                PRE_CHARGE:     begin 
                                    oled_spi_data_in <= 'hD9;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= PRE_CHARGE1;
                                    end 
                                end
                PRE_CHARGE1:    begin 
                                    oled_spi_data_in <= 'hF1;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= VBAT_ON;
                                    end 
                                end
                 VBAT_ON:       begin
                                    oled_vbat <= 1'b0;
                                    oled_state <= DELAY;
                                    oled_next_state <= CONTRAST;
                                end
                 CONTRAST:      begin
                                    oled_spi_data_in <= 'h81;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= CONTRAST1;
                                    end 
                                end        
                 CONTRAST1:     begin 
                                    oled_spi_data_in <= 'hFF;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= SEG_REMAP;
                                    end 
                                end
                 SEG_REMAP:     begin 
                                    oled_spi_data_in <= 'hA0;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= SCAN_DIR;
                                    end
                                end
                 SCAN_DIR:      begin 
                                    oled_spi_data_in <= 'hC0;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= COM_PIN;
                                    end
                                end 
                 COM_PIN:       begin
                                    oled_spi_data_in <= 'hDA;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= COM_PIN1;
                                    end
                                end
                 COM_PIN1:      begin
                                    oled_spi_data_in <= 'h00;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= DISPLAY_ON;
                                    end 
                                end
                 DISPLAY_ON:    begin   
                                    oled_spi_data_in <= 'hAF;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= PAGE_ADDRESS;//FULL_DISPLAY;
                                    end 
                                end   
                  PAGE_ADDRESS: begin
                                        oled_spi_data_in <= 'h22;
                                        oled_load_data <= 1'b1;
                                        oled_dc_n <= 1'b0;
                                        if(oled_done_send)
                                        begin
                                            oled_load_data <= 1'b0;
                                            oled_state <= WAIT_SPI;
                                            oled_next_state <= PAGE_ADDRESS1; 
                                        end
                                end
                  PAGE_ADDRESS1:    begin 
                                        oled_spi_data_in <= current_page;
                                        oled_load_data <= 1'b1;
                                        if(oled_done_send)
                                        begin
                                            oled_load_data <= 1'b0;
                                            oled_state <= WAIT_SPI;
                                            current_page <= current_page + 1;
                                            oled_next_state <= PAGE_ADDRESS2; 
                                        end
                                        
                                    end
                  PAGE_ADDRESS2:    begin 
                                        oled_spi_data_in <= current_page;
                                        oled_load_data <= 1'b1;
                                        if(oled_done_send)
                                        begin
                                            oled_load_data <= 1'b0;
                                            oled_state <= WAIT_SPI;
                                            
                                            oled_next_state <= COLUMN_ADDRESS; 
                                        end
                                    end
                  COLUMN_ADDRESS: begin
                                        oled_spi_data_in <= 'h10; 
                                        oled_load_data <= 1'b1;
                                        if(oled_done_send)
                                        begin
                                            oled_load_data <= 1'b0;
                                            oled_state <= WAIT_SPI;
                                            oled_next_state <= DONE; 
                                        end
                                   end
                         
                 /*FULL_DISPLAY:    begin   
                                    oled_spi_data_in <= 'hA5;
                                    oled_load_data <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        oled_next_state <= DONE;
                                    end 
                                end*/
                 DONE:          begin 
                                    send_done <= 1'b0;
                                    if(send_data_valid & column_counter != 128 & !send_done)
                                    begin 
                                        oled_state <= SEND_DATA;
                                        byte_counter <= 8;
                                    end
                                    else if(send_data_valid & column_counter == 128 & !send_done)
                                    begin
                                        oled_state <= PAGE_ADDRESS; 
                                        column_counter <= 0;
                                        byte_counter <= 8;
                                    end
                                end  
                 SEND_DATA:     begin 
                                    oled_spi_data_in <= char_bit_map[(byte_counter* 8 - 1)-:8];
                                    oled_load_data <= 1'b1;
                                    oled_dc_n <= 1'b1;
                                    if(oled_done_send)
                                    begin
                                        column_counter <= column_counter + 1;
                                        oled_load_data <= 1'b0;
                                        oled_state <= WAIT_SPI;
                                        if(byte_counter != 1)
                                        begin
                                            byte_counter <= byte_counter - 1;
                                            oled_next_state <= SEND_DATA; 
                                        end 
                                        else 
                                        begin
                                            oled_next_state <= DONE; 
                                            send_done <= 1'b1;
                                        end
                                    end   
                                end                             
            endcase 
        end
    end
    
    delayGen delay(
    .clock(clock),
    .delayEn(oled_start_delay),
    .delayDone(oled_delay_done)
    );
    
    spiControl SC(
    .clock(clock), // On board Zynq clock(100 MHz)
    .reset(reset),
    .data_in(oled_spi_data_in),
    .load_data(oled_load_data), // signal indicates new data for transmission
    .spi_clock(oled_spi_clk),  // maximum 10 MHz
    .spi_data(oled_spi_data),
    .done_send(oled_done_send));
    
    charROM(
    .address(send_data), // 7 bit ascii code
    .data(char_bit_map)
    );
    
endmodule
