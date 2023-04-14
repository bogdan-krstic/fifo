

module fifo
  #( // parameters
     int SIZE = 8,
     int T_SIZE = 3,
     type T = logic[T_SIZE-1:0],
     int LOG_SIZE = $clog2(SIZE)
     )
   ( // port declarations
     // Interface with producer
     input logic p2f_irdy,
     input T data_in,
     output logic f2p_trdy,
     // Interface with consumer
     output logic f2c_irdy,
     output T data_out,
     output logic c2f_trdy,

     input logic clk,
     input logic rst
     );

   T [SIZE-1:0] Q;
   logic [LOG_SIZE-1:0]	rd_ptr;
   logic [LOG_SIZE-1:0]	wr_ptr;

   logic		full;
   logic		empty;
   logic		wrap;

   logic		enq;
   logic		deq;
   

   // combinational block

   assign full = (rd_ptr == wr_ptr) && wrap;
   assign empty = (rd_ptr == wr_ptr) && !wrap;

   assign f2p_trdy = !full;
   assign f2c_irdy = !empty;

   assign enq = p2f_irdy && f2p_trdy;
   assign deq = f2c_irdy && c2f_trdy;

   assign data_out = deq ? Q[rd_ptr] : '0;
   

   // flip-flop block

   always_ff @(posedge(clk)) begin

      if (rst) begin
	 rd_ptr <= 0;
	 wr_ptr <= 0;
	 wrap <= 1'b0;
	 Q <= 0;
      end
     
      else begin 
	 if (enq) begin
	    Q[wr_ptr] <= data_in;
	    wr_ptr <= (wr_ptr + 1) % SIZE;
	    if (wr_ptr == SIZE-1) begin
	       wrap <= !wrap;
	    end
	 end
	 if (deq) begin
	    rd_ptr <= (rd_ptr + 1) % SIZE;
	    if (rd_ptr == SIZE-1) begin
	       wrap <= !wrap;
	    end
	 end
      end // else: !if(rst)
   end // always_ff @ (posedge(clk))
   
endmodule // fifo


   
	 
	 
	 
		     
      
		 
   
