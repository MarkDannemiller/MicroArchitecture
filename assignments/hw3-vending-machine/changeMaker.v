// =======================================================
// Submodule: changeMaker
// -------------------------------------------------------
// This module implements a simple state machine that, given an
// input change amount (in cents) and coin availability signals,
// outputs (one per clock cycle) a 5–bit one–hot coin return code.
// It attempts to give back the largest coin first. If it cannot
// dispense any coin for the remaining change (because the
// availability signal is low), then the remainder is “stolen”.
// =======================================================
module changeMaker(
    input             clk,
    input             reset,
    input             start,      // one–cycle pulse to load change_in
    input      [8:0]  change_in,  // change amount in cents
    input             avail_dollar,
    input             avail_half,
    input             avail_quarter,
    input             avail_dime,
    input             avail_nickel,
    output reg [4:0]  coin_out,   // one–hot: [4]=dollar, [3]=half, [2]=quarter, [1]=dime, [0]=nickel
    output reg        done        // high when change return is complete
);

  reg [8:0] rem_change; // remaining change amount
  
  // State machine for changeMaker:
  localparam CM_IDLE = 2'd0;
  localparam CM_MAKE = 2'd1;
  localparam CM_DONE = 2'd2;
  reg [1:0] state;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state      <= CM_IDLE;
      rem_change <= 9'd0;
      coin_out   <= 5'd0;
      done       <= 1'b0;
    end else begin
      case (state)
        // --------------
        // CM_IDLE: Wait for a start pulse. When start is asserted, latch the
        // change amount.
        // --------------
        CM_IDLE: begin
          coin_out <= 5'd0;
          done     <= 1'b0;
          if (start) begin
            rem_change <= change_in;
            state      <= CM_MAKE;
          end
        end

        // --------------
        // CM_MAKE: Each clock cycle, if the remaining change is nonzero,
        // output one coin (largest denomination available) and subtract its value.
        // If no coin is available for the remaining amount, “steal” the remainder.
        // --------------
        CM_MAKE: begin
          coin_out <= 5'd0; // default: no coin output
          if (rem_change == 9'd0) begin
            state <= CM_DONE;
          end else if (rem_change >= 9'd100 && avail_dollar) begin
            coin_out   <= 5'b10000; // dispense dollar coin
            rem_change <= rem_change - 9'd100;
          end else if (rem_change >= 9'd50 && avail_half) begin
            coin_out   <= 5'b01000; // dispense half–dollar
            rem_change <= rem_change - 9'd50;
          end else if (rem_change >= 9'd25 && avail_quarter) begin
            coin_out   <= 5'b00100; // dispense quarter
            rem_change <= rem_change - 9'd25;
          end else if (rem_change >= 9'd10 && avail_dime) begin
            coin_out   <= 5'b00010; // dispense dime
            rem_change <= rem_change - 9'd10;
          end else if (rem_change >= 9'd5 && avail_nickel) begin
            coin_out   <= 5'b00001; // dispense nickel
            rem_change <= rem_change - 9'd5;
          end else begin
            // If no coin is available for the remaining change, "steal" the remainder.
            rem_change <= 9'd0;
            state      <= CM_DONE;
          end
        end

        // --------------
        // CM_DONE: Change making is complete.
        // --------------
        CM_DONE: begin
          coin_out <= 5'd0;
          done     <= 1'b1;
          // Once done, wait for start to go low (or for a reset) before returning to IDLE.
          if (!start)
            state <= CM_IDLE;
        end

        default: state <= CM_IDLE;
      endcase
    end
  end

endmodule