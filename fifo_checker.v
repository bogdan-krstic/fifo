

module fifo_checker
  #( // parameters
     int SIZE = 8,
     int T_SIZE = 3,
     type T = logic [T_SIZE-1:0],
     int LOG_SIZE = $clog2(SIZE)
     )
   ( // port declarations
     // Interface with producer
     input logic p2f_irdy,
     input T data_in,
     input logic f2p_trdy,
     // Interface with consumer
     input logic f2c_irdy,
     input T data_out,
     input logic c2f_trdy,

     input logic clk,
     input logic rst
     );

   // verification block

   // objectives:
   // - sanity checks
   // - no overflow
   // - no underflow   
   // - data integrity

   // observer variables

   logic	 obs_enq;
   logic	 obs_deq;
   logic	 obs_full;
   logic	 obs_empty;	 
   
   assign obs_enq = p2f_irdy && f2p_trdy;
   assign obs_deq = f2c_irdy && c2f_trdy;

   logic [LOG_SIZE-1:0]	occupancy;

   always_ff @(posedge clk) begin
      if (rst) begin
	 occupancy <= 0;
      end
      else begin
	 occupancy <= occupancy + obs_enq - obs_deq;
      end
   end

   assign obs_full = (occupancy == SIZE);
   assign obs_empty = (occupancy == 0);

   // sanity checks
   
   enq_match: assert property (@(posedge clk) obs_enq == dut.enq);
   deq_match: assert property (@(posedge clk) obs_deq == dut.deq);
   full_match: assert property (@(posedge clk) obs_full == dut.full);
   hlp_empty_match: assert property (@(posedge clk) obs_empty == dut.empty);
  
   full_sanity: assert property (@(posedge clk) dut.full == obs_full);
   empty_sanity: assert property (@(posedge clk) dut.empty == obs_empty);
   
   // overflow/underflow

   no_overflow: assert property (@(posedge clk) !(obs_full && obs_enq));
   no_underflow: assert property (@(posedge clk) !(obs_empty && obs_deq));
   
   // data integrity
   
   typedef enum {Idle, Tracking, Quit} t_monitor;

   logic	start_tracking;

   t_monitor mst;

   T tracked_data;

   logic [LOG_SIZE-1:0]	counter;

   always_ff @(posedge clk) begin
      if (rst) begin
	 mst <= Idle;
	 counter <= 0;
	 tracked_data <= '0;	 
      end
      else if (mst == Idle && start_tracking && obs_enq) begin
	 mst <= Tracking;
	 tracked_data <= data_in;
	 counter <= obs_deq ? occupancy - 1: occupancy;
      end
      else if (mst == Tracking && counter != 0 && obs_deq) begin
	 counter <= counter - 1;
      end
      else if (mst == Tracking && obs_deq && counter == 0) begin
	 mst <= Quit;
      end
   end // always_ff @ (posedge clk)

   // data integrity main result

   data_integrity: assert property (@(posedge clk) mst == Tracking && obs_deq && counter == 0  |-> data_out == tracked_data);

   critical_lemma: assert property (@(posedge clk) mst == Tracking |->  dut.Q[(dut.rd_ptr + counter) % SIZE] == tracked_data);

   // helper results (used in proof structure)
   
   hlp_tracked_entry_not_at_wr_ptr_if_fifo_not_full: assert property (@(posedge clk) mst == Tracking && (dut.rd_ptr != dut.wr_ptr) |-> (dut.rd_ptr + counter) % SIZE != dut.wr_ptr);

   hlp_no_tracking_when_empty: assert property(@(posedge clk) !(mst == Tracking && obs_empty));

   hlp_ptr_size: assert property (@(posedge clk) (dut.rd_ptr < SIZE) && (dut.wr_ptr < SIZE));

   hlp_occ_distance: assert property (@(posedge clk) (dut.rd_ptr + occupancy) % SIZE == dut.wr_ptr);
   
   hlp_wrap_bit: assert property (@(posedge clk)
			      (!dut.wrap || (dut.rd_ptr >= dut.wr_ptr)) && (dut.wrap || (dut.wr_ptr >= dut.rd_ptr)));
   
					    
   
   tracking_and_obs_deq: cover property (@(posedge clk) mst == Tracking && obs_deq);
   tracking_and_ctr_zero: cover property (@(posedge clk) mst == Tracking && counter == 0);
   tracking: cover property (@(posedge clk) mst == Tracking);
   
endmodule // fifo_checker

   
	 

    
