`include "changeMaker.v"
`include "posnotedge.v"

// =======================================================
// Top-Level Module: vendingMachine
// -------------------------------------------------------
// This module implements a single-column 6-item vending
// machine (price = $1.75) that accepts coins (dollar, half‐
// dollar, quarter, dime, nickel), checks stock sensors,
// and (if needed) returns change using a submodule called
// changeMaker.
// 
// Note:
// - All asynchronous inputs (coins, buttons) are assumed to
//   have been synchronized externally or via double–FF
//   synchronizers.
// - The module does not “count” coin inventory but instead
//   accepts coin availability signals (avail_*).
// - The coin return output is a 5–bit one–hot vector (bit 4:
//   dollar; bit 3: half–dollar; bit 2: quarter; bit 1: dime;
//   bit 0: nickel).
// =======================================================
module vendingMachine(
    input             clk,
    input             reset,
    // Coin inputs (each is a one–cycle pulse when a coin is inserted)
    input             coin_dollar,   // 100 cents
    input             coin_half,     // 50 cents
    input             coin_quarter,  // 25 cents
    input             coin_dime,     // 10 cents
    input             coin_nickel,   // 5 cents
    // Product selection:
    input      [2:0]  product_select,      // selection: 0–5 (binary encoded)
    input             product_select_valid,// pulse (one cycle) indicating a selection
    // Stock sensors for the 6 items (1 = available)
    input      [5:0]  stock_sensor,
    // A “return” button (to cancel the transaction)
    input             return_button,
    // Coin availability signals (for change making)
    input             avail_dollar,
    input             avail_half,
    input             avail_quarter,
    input             avail_dime,
    input             avail_nickel,
    // Outputs:
    output reg        dispense_product,    // pulse: product dispensed
    output reg [4:0]  coin_return,         // one–hot coin returned (bit 4: dollar, …, bit 0: nickel)
    output reg        exact_change_light,  // lights if coin inventory is low (e.g. less than 20 nickels)
    output [5:0]      out_of_stock_light   // lights for product(s) that are out–of–stock
);

  // -------------------------------------------------------------------
  // Synchronize asynchronous inputs using posnotedge modules.
  // We only use the rising (edgeplus) outputs.
  // -------------------------------------------------------------------
  wire coin_dollar_edge;
  wire coin_half_edge;
  wire coin_quarter_edge;
  wire coin_dime_edge;
  wire coin_nickel_edge;
  wire product_select_valid_edge;
  wire return_button_edge;
  
  posnotedge sync_coin_dollar(
      .signal(coin_dollar),
      .clock(clk),
      .edgeplus(coin_dollar_edge),
      .edgeminus()
  );
  posnotedge sync_coin_half(
      .signal(coin_half),
      .clock(clk),
      .edgeplus(coin_half_edge),
      .edgeminus()
  );
  posnotedge sync_coin_quarter(
      .signal(coin_quarter),
      .clock(clk),
      .edgeplus(coin_quarter_edge),
      .edgeminus()
  );
  posnotedge sync_coin_dime(
      .signal(coin_dime),
      .clock(clk),
      .edgeplus(coin_dime_edge),
      .edgeminus()
  );
  posnotedge sync_coin_nickel(
      .signal(coin_nickel),
      .clock(clk),
      .edgeplus(coin_nickel_edge),
      .edgeminus()
  );
  posnotedge sync_product_select_valid(
      .signal(product_select_valid),
      .clock(clk),
      .edgeplus(product_select_valid_edge),
      .edgeminus()
  );
  posnotedge sync_return_button(
      .signal(return_button),
      .clock(clk),
      .edgeplus(return_button_edge),
      .edgeminus()
  );

  // -----------------------------
  // Internal registers and wires
  // -----------------------------
  reg [8:0] balance;  // 9–bit balance (max about $5 = 500 cents)
  reg [8:0] temp_balance; // temporary balance if user inserts a coin during change making
  
  // FSM states for top–level machine:
  localparam STATE_WAIT        = 2'd0; // waiting for coins/selection
  localparam STATE_INIT_CHANGE = 2'd1; // one–cycle pulse to start changeMaker
  localparam STATE_MAKE_CHANGE = 2'd2; // waiting while changeMaker returns coins
  reg [1:0] state;

  // Wires and registers for interfacing to changeMaker
  wire [4:0] cm_coin_out;
  wire       cm_done;
  reg        cm_start;
  reg [8:0]  cm_change_amount; // the change amount to be returned

  // Instantiate the changeMaker submodule.
  changeMaker cm (
      .clk         (clk),
      .reset       (reset),
      .start       (cm_start),
      .change_in   (cm_change_amount),
      .avail_dollar(avail_dollar),
      .avail_half  (avail_half),
      .avail_quarter(avail_quarter),
      .avail_dime  (avail_dime),
      .avail_nickel(avail_nickel),
      .coin_out    (cm_coin_out),
      .done        (cm_done)
  );

  // --------------------------------------
  // Exact Change Only Light
  // (lights if coin inventory is too low, e.g. if not enough nickels)
  // --------------------------------------
  always @(*) begin
      exact_change_light = ~avail_nickel;
  end

  assign out_of_stock_light = ~stock_sensor; // lights for out–of–stock items

  // ------------------------------
  // Top-Level FSM
  // ------------------------------
  // The machine always adds coin amounts when in the WAIT state.
  // When the user presses either the product selection button (with
  // sufficient funds) or the return button, the machine loads the
  // appropriate change (balance - price or full balance) and then
  // pulses the changeMaker to return coins one per cycle.
  // ------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state             <= STATE_WAIT;
      balance           <= 9'd0;
      temp_balance       <= 9'd0;
      dispense_product  <= 1'b0;
      coin_return       <= 5'd0;
      cm_start          <= 1'b0;
      cm_change_amount  <= 9'd0;
    end else begin
      case (state)
        // ------------------------------
        // STATE_WAIT: Accept coins and wait for a selection
        // ------------------------------
        STATE_WAIT: begin
          // Accumulate inserted coins (one clock cycle sums all coins that are high).
          balance <= balance + (coin_dollar_edge ? 9'd100 : 9'd0) +
                             (coin_half_edge     ? 9'd50  : 9'd0) +
                             (coin_quarter_edge  ? 9'd25  : 9'd0) +
                             (coin_dime_edge     ? 9'd10  : 9'd0) +
                             (coin_nickel_edge   ? 9'd5   : 9'd0);
                             
          // Clear outputs
          dispense_product   <= 1'b0;
          coin_return        <= 5'd0;
          cm_start           <= 1'b0;
          
          // If the user presses the return button, return the full balance.
          if (return_button_edge) begin
              cm_change_amount <= balance;
              state <= STATE_INIT_CHANGE;
              
          // Else if a product is selected...
          end else if (product_select_valid_edge) begin
              // Only process the selection if at least 175 cents have been inserted.
              if (balance >= 9'd175) begin
                  // Use a case statement to check the appropriate stock sensor.
                  case (product_select)
                    3'd0: begin
                      if (stock_sensor[0]) begin
                        dispense_product  <= 1'b1;
                        cm_change_amount  <= balance - 9'd175;
                      end else begin
                        cm_change_amount      <= balance;
                      end
                    end
                    3'd1: begin
                      if (stock_sensor[1]) begin
                        dispense_product  <= 1'b1;
                        cm_change_amount  <= balance - 9'd175;
                      end else begin
                        cm_change_amount      <= balance;
                      end
                    end
                    3'd2: begin
                      if (stock_sensor[2]) begin
                        dispense_product  <= 1'b1;
                        cm_change_amount  <= balance - 9'd175;
                      end else begin
                        cm_change_amount      <= balance;
                      end
                    end
                    3'd3: begin
                      if (stock_sensor[3]) begin
                        dispense_product  <= 1'b1;
                        cm_change_amount  <= balance - 9'd175;
                      end else begin
                        cm_change_amount      <= balance;
                      end
                    end
                    3'd4: begin
                      if (stock_sensor[4]) begin
                        dispense_product  <= 1'b1;
                        cm_change_amount  <= balance - 9'd175;
                      end else begin
                        cm_change_amount      <= balance;
                      end
                    end
                    3'd5: begin
                      if (stock_sensor[5]) begin
                        dispense_product  <= 1'b1;
                        cm_change_amount  <= balance - 9'd175;
                      end else begin
                        cm_change_amount      <= balance;
                      end
                    end
                    default: begin
                      // If an invalid selection, simply return full balance.
                      cm_change_amount <= balance;
                    end
                  endcase // case
                  state <= STATE_INIT_CHANGE;
              end
              // If there isn’t enough money inserted, ignore the selection.
          end
        end // STATE_WAIT

        // ------------------------------
        // STATE_INIT_CHANGE: Generate a one–cycle pulse to start changeMaker.
        // ------------------------------
        STATE_INIT_CHANGE: begin
            // Accumulate inserted coins (one clock cycle sums all coins that are high).
            balance <= balance + (coin_dollar_edge ? 9'd100 : 9'd0) +
                                    (coin_half_edge     ? 9'd50  : 9'd0) +
                                    (coin_quarter_edge  ? 9'd25  : 9'd0) +
                                    (coin_dime_edge     ? 9'd10  : 9'd0) +
                                    (coin_nickel_edge   ? 9'd5   : 9'd0);

            cm_start <= 1'b1;
            state <= STATE_MAKE_CHANGE;
        end

        // ------------------------------
        // STATE_MAKE_CHANGE: Wait while the changeMaker returns coins (1 coin per cycle).
        // When finished, clear the balance and return to waiting.
        // ------------------------------
        STATE_MAKE_CHANGE: begin
            cm_start   <= 1'b0;
            coin_return<= cm_coin_out;  // pass along the coin return output

            // Accumulate inserted coins (one clock cycle sums all coins that are high).
            temp_balance = temp_balance + (coin_dollar_edge ? 9'd100 : 9'd0) +
                                            (coin_half_edge     ? 9'd50  : 9'd0) +
                                            (coin_quarter_edge  ? 9'd25  : 9'd0) +
                                            (coin_dime_edge     ? 9'd10  : 9'd0) +
                                            (coin_nickel_edge   ? 9'd5   : 9'd0);
            if (cm_done) begin
                balance <= temp_balance; // 0 unless coins inserted during change making
                state   <= STATE_WAIT;
            end
        end

        default: state <= STATE_WAIT;
      endcase // case(state)
    end
  end

endmodule
