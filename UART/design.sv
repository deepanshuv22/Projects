module UART (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [7:0] data_in,
    output reg tx_busy,
    output reg [7:0] data_out
);

    reg [3:0] state; // UART state variable
    reg [10:0] count; // Counter for bit transmission
    reg [3:0] bit_count; // Counter for bit reception
    reg [7:0] tx_data; // Data to be transmitted

    wire tx_done; // Transmission complete signal

    // Transmitter
    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= 4'b0000;
            count <= 11'd0;
            tx_busy <= 1'b0;
        end
        else
        begin
            case (state)
                4'b0000: // Idle state
                    if (start)
                    begin
                        state <= 4'b0001;
                        count <= 11'd0;
                        tx_data <= data_in;
                        tx_busy <= 1'b1;
                    end
                4'b0001: // Start bit
                    begin
                        if (count < 11'd7)
                            count <= count + 1;
                        else
                        begin
                            count <= count + 1;
                            state <= 4'b0010;
                        end
                    end
                4'b0010: // Data bits
                    begin
                        if (count < 11'd10)
                            count <= count + 1;
                        else
                        begin
                            count <= count + 1;
                            state <= 4'b0011;
                        end
                    end
                4'b0011: // Stop bit
                    begin
                        if (count < 11'd11)
                            count <= count + 1;
                        else
                        begin
                            count <= count + 1;
                            state <= 4'b0000;
                            tx_busy <= 1'b0;
                        end
                    end
            endcase
        end
    end

    // Receiver
    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= 4'b0000;
            bit_count <= 4'd0;
            data_out <= 8'd0;
        end
        else
        begin
            case (state)
                4'b0000: // Idle state
                    begin
                        if (!start)
                            state <= 4'b0000;
                        else
                        begin
                            state <= 4'b0001;
                            bit_count <= 4'd0;
                            data_out <= 8'd0;
                        end
                    end
                4'b0001: // Start bit
                    begin
                        if (bit_count < 4'd7)
                            bit_count <= bit_count + 1;
                        else
                            state <= 4'b0010;
                    end
                4'b0010: // Data bits
                    begin
                        if (bit_count < 4'd10)
                        begin
                            bit_count <= bit_count + 1;
                            data_out <= {data_out[6:0], start};
                        end
                        else
                            state <= 4'b0011;
                    end
                4'b0011: // Stop bit
                    begin
                        state <= 4'b0000;
                        bit_count <= 4'd0;
                    end
            endcase
        end
    end

    assign tx_done = (state == 4'b0000 && count == 11'd11);

endmodule

module UART_Testbench;
    
    reg clk;
    reg reset;
    reg start;
    reg [7:0] data_in;
    wire tx_busy;
    wire [7:0] data_out;

    UART uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_in(data_in),
        .tx_busy(tx_busy),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate clock signal with 10ns period
    end

    initial begin
        reset = 1; // Start with reset asserted
        start = 0;
        data_in = 8'd0;
        #20 reset = 0; // Deassert reset after 100ns
        #10 start = 1; // Set start bit after 50ns
        #10 start = 0; // Clear start bit after 50ns
        #10 data_in = 8'd255; // Send data byte 255 (0xFF)
        #100 $finish; // End simulation after 500ns
    end

    // Monitor for displaying transmitted and received data
    always @(posedge clk)
    begin
        $display("Tx Busy: %b, Tx Data: %b, Rx Data: %b", tx_busy, data_in, data_out);
    end

endmodule
