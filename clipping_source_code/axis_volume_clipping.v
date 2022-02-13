`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent
// Engineer: Arthur Brown
// 
// Create Date: 03/23/2018 01:23:15 PM
// Module Name: axis_volume_controller
// Description: AXI-Stream volume controller intended for use with AXI Stream Pmod I2S2 controller.
//              Whenever a 2-word packet is received on the slave interface, it is multiplied by 
//              the value of the switches, taken to represent the range 0.0:1.0, then sent over the
//              master interface. Reception of data on the slave interface is halted while processing and
//              transfer is taking place.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_volume_clipping #(
    parameter SWITCH_WIDTH = 4, // WARNING: this module has not been tested with other values of SWITCH_WIDTH, it will likely need some changes
    parameter DATA_WIDTH = 24
) (
    input wire clk,
    input wire btn,
    input wire [SWITCH_WIDTH-1:0] sw,
    
    //AXIS SLAVE INTERFACE
    input  wire [DATA_WIDTH-1:0] s_axis_data,
    input  wire s_axis_valid,
    output reg  s_axis_ready = 1'b1,
    input  wire s_axis_last,
    
    // AXIS MASTER INTERFACE
    output reg [DATA_WIDTH-1:0] m_axis_data = 1'b0,
    output reg m_axis_valid = 1'b0,
    input  wire m_axis_ready,
    output reg m_axis_last = 1'b0
);
    localparam MULTIPLIER_WIDTH = 24;
    
    // store data to be manipulated 
    reg [MULTIPLIER_WIDTH+DATA_WIDTH-1:0] data [1:0];
        
    // reg to save btn and sw values    
    reg btn_r = 1'b0;    
    reg [SWITCH_WIDTH-1:0] sw_sync_r [2:0];
    wire [SWITCH_WIDTH-1:0] sw_sync = sw_sync_r[2];
    
    // volume multiplier
    reg [MULTIPLIER_WIDTH:0] multiplier = 'b0; // range of 0x00:0x10 for width=4

    // threshold levels for clipping 
    reg [MULTIPLIER_WIDTH:0] threshold_h = {1'b0, 7'b001111, 16'h0000};
    reg [MULTIPLIER_WIDTH:0] threshold_l = {1'b1, 7'b000001, 16'h0000};
    
    wire m_select = m_axis_last;
    wire m_new_word = (m_axis_valid == 1'b1 && m_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire m_new_packet = (m_new_word == 1'b1 && m_axis_last == 1'b1) ? 1'b1 : 1'b0;
    
    wire s_select = s_axis_last;
    wire s_new_word = (s_axis_valid == 1'b1 && s_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire s_new_packet = (s_new_word == 1'b1 && s_axis_last == 1'b1) ? 1'b1 : 1'b0;
    reg s_new_packet_r = 1'b0;
    
    // threshold to be updated with volume level 
    reg [MULTIPLIER_WIDTH+DATA_WIDTH-1:0] thresh_h = 'b0; 
    reg [MULTIPLIER_WIDTH+DATA_WIDTH-1:0] thresh_l = 'b0;
    
    always@(posedge clk) begin
    
        // save switches and button values 
        sw_sync_r[2] <= sw_sync_r[1];
        sw_sync_r[1] <= sw_sync_r[0];
        sw_sync_r[0] <= sw;
               
        btn_r <= btn;
        
        // update multiplier variable: 24 bit (6 groups of 4 bit with values equal to sw_sync)
        multiplier <= {sw_sync,{MULTIPLIER_WIDTH{1'b0}}} / {SWITCH_WIDTH{1'b1}};

        s_new_packet_r <= s_new_packet;
        
    end
    
    always@(posedge clk)
        if (s_new_word == 1'b1) begin// sign extend and register AXIS slave data
            data[s_select] = {{MULTIPLIER_WIDTH{s_axis_data[DATA_WIDTH-1]}}, s_axis_data};
            
            // prepare threshold values to be multiplied 
            thresh_h = {{MULTIPLIER_WIDTH{threshold_h[DATA_WIDTH-1]}}, threshold_h};
            thresh_l = {{MULTIPLIER_WIDTH{threshold_l[DATA_WIDTH-1]}}, threshold_l};
            
        end else if (s_new_packet_r == 1'b1) begin         
                
                // core volume control algorithm, infers a DSP48 slice
                data[0] = $signed(data[0]) * multiplier; 
                data[1] = $signed(data[1]) * multiplier;
                
                // threshold volume scaling 
                thresh_h = $signed(thresh_h) * multiplier;
                // assuming same value for negative clipping, can be changed for different positive/negative threshold values
                thresh_l = ~thresh_h + 1; 
                
            // clipping code: if values are higher/lower than thresh_h/thresh_l assign these values 
            // clipping effect is active only when pressing btn 0 on the board             
            if (btn_r == 1'b1) begin
               if (data[0][MULTIPLIER_WIDTH+DATA_WIDTH-1] == 1'b0) begin
                    if (data[0] > thresh_h) begin
                        data[0] = thresh_h ;
                    end 
               end
               if (data[0][MULTIPLIER_WIDTH+DATA_WIDTH-1] == 1'b1) begin
                    if (data[0] < thresh_l) begin
                        data[0] = thresh_l; 
                    end 
               end
               if (data[1][MULTIPLIER_WIDTH+DATA_WIDTH-1] == 1'b0) begin
                    if (data[1] > thresh_h) begin
                        data[1] = thresh_h ;
                    end 
               end
               if (data[1][MULTIPLIER_WIDTH+DATA_WIDTH-1] == 1'b1) begin
                    if (data[1] < thresh_l) begin
                        data[1] = thresh_l; 
                    end 
               end
             end 
         end


   // updating variables for input and output data control      
    always@(posedge clk)
        if (s_new_packet_r == 1'b1)
            m_axis_valid <= 1'b1;
        else if (m_new_packet == 1'b1)
            m_axis_valid <= 1'b0;
            
    always@(posedge clk)
        if (m_new_packet == 1'b1)
            m_axis_last <= 1'b0;
        else if (m_new_word == 1'b1)
            m_axis_last <= 1'b1;
            
    always@(m_axis_valid, data[0], data[1], m_select)
        if (m_axis_valid == 1'b1) begin
            m_axis_data = data[m_select][MULTIPLIER_WIDTH+DATA_WIDTH-1:MULTIPLIER_WIDTH];
        end else
            m_axis_data = 'b0;
            
 
    always@(posedge clk)
        if (s_new_packet == 1'b1)
            s_axis_ready <= 1'b0;
        else if (m_new_packet == 1'b1)
            s_axis_ready <= 1'b1;

endmodule
