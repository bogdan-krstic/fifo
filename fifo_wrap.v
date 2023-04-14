

module fifo_wrap
  #(
    int SIZE_ = 1000,
    type T_ = logic[2:0], // type of data entries
    localparam LOGSIZE = $clog2(SIZE_)
    )
   (
    // Interface with producer
    output logic f2p_trdy,
    input logic p2f_irdy,
    input T_ data_in,

    // Interface with consumer
    output logic f2c_irdy,
    input logic c2f_trdy,
    output T_ data_out,

    input logic clk,
    input logic rst
    );

   fifo
     #(
       .SIZE(SIZE_),
       .T(T_)
       )
   dut // design-under-test
     (
      .*
      );

   fifo_checker
     #(
       .SIZE(SIZE_),
       .T(T_)
       )
   chekker
     (
      .*
      );


endmodule // fifo_wrap
