module uart_tb;

  // Parameters
  parameter CLK_PERIOD = 10; // 100MHz
  parameter CLOCK_FREQ = 100_000_000;
  parameter BAUD_RATE  = 9600;
  parameter WORK_FR    = CLOCK_FREQ / BAUD_RATE;  //  10416

  // Signals
  reg clk = 0;
  reg reset = 1;
  reg start = 0;
  reg [7:0] data_tx;
  wire [7:0] data_rx;
  wire ready_tx, ready, tx;
  wire parity_rx;

  // Loopback connection: TX connects directly to RX
  wire rx = tx;

  // Clock generation
  always #(CLK_PERIOD/2) clk = ~clk;

  // Instantiate UART
  UART uut (
    .CLK(clk),
    .RESET(reset),
    .RX(rx),
    .START(start),
    .DATA_TX(data_tx),
    .WORK_FR(WORK_FR[11:0]),
    .TX(tx),
    .DATA_RX(data_rx),
    .PARITY_RX(parity_rx),
    .READY_TX(ready_tx),
    .READY(ready)
  );

  // Test sequence
  initial begin
    $display("Starting UART testbench...");
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);

    // Reset
    #100;
    reset = 0;

    // Wait for TX to be ready
    wait(ready_tx == 1);

    // Send 0b10101010
    data_tx = 8'b10101010;
    start = 1;
    #CLK_PERIOD;
    start = 0;

    // Wait for RX to be ready
    wait(ready == 1);

    // Show results
    #50;
    $display("TX Data Sent   = %b", data_tx);
    $display("RX Data Recv'd = %b", data_rx);
    $display("Parity OK?     = %b", parity_rx);

    // Stop simulation
    #100;
    $finish;
  end
  
  initial begin
    $dumpfile("waveform.vcd");   
    $dumpvars();     
  end

endmodule

