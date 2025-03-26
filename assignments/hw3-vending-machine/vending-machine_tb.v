`timescale 1ns/1ps
`include "vending-machine.v"

// =======================================================
// Testbench for vendingMachine
// -------------------------------------------------------
// This testbench drives several scenarios:
//   1. Inserting coins to purchase an item (with change returned).
//   2. Inserting coins then pressing the return button.
//   3. Attempting a purchase on an out–of–stock item.
//   4. Attempting a purchase when the change cannot be made.
//   5. Driving multiple coin signals in the same cycle.
//   6. Exact Change Transaction.
//   7. Rapid Successive Transactions.
//   8. Mid-Transaction Reset.
// =======================================================
module vendingMachine_tb;
  reg         clk;
  reg         reset;
  reg         coin_dollar;
  reg         coin_half;
  reg         coin_quarter;
  reg         coin_dime;
  reg         coin_nickel;
  reg  [2:0]  product_select;
  reg         product_select_valid;
  reg  [5:0]  stock_sensor;
  reg         return_button;
  reg         avail_dollar;
  reg         avail_half;
  reg         avail_quarter;
  reg         avail_dime;
  reg         avail_nickel;
  wire        dispense_product;
  wire [4:0]  coin_return;
  wire        exact_change_light;
  wire [5:0]  out_of_stock_light;
  
  // Instantiate the vendingMachine module
  vendingMachine uut (
      .clk                (clk),
      .reset              (reset),
      .coin_dollar        (coin_dollar),
      .coin_half          (coin_half),
      .coin_quarter       (coin_quarter),
      .coin_dime          (coin_dime),
      .coin_nickel        (coin_nickel),
      .product_select     (product_select),
      .product_select_valid(product_select_valid),
      .stock_sensor       (stock_sensor),
      .return_button      (return_button),
      .avail_dollar       (avail_dollar),
      .avail_half         (avail_half),
      .avail_quarter      (avail_quarter),
      .avail_dime         (avail_dime),
      .avail_nickel       (avail_nickel),
      .dispense_product   (dispense_product),
      .coin_return        (coin_return),
      .exact_change_light (exact_change_light),
      .out_of_stock_light (out_of_stock_light)
  );
  
  // Clock generation: 10ns period
  always #5 clk = ~clk;
  
initial begin
    $dumpfile("vending-machine_tb.vcd");
    $dumpvars(0, vendingMachine_tb);
    $display("Vending Machine Testbench");
    // Initialize signals
    clk                 = 0;
    reset               = 1;
    coin_dollar         = 0;
    coin_half           = 0;
    coin_quarter        = 0;
    coin_dime           = 0;
    coin_nickel         = 0;
    product_select      = 3'd0;
    product_select_valid= 0;
    return_button       = 0;
    // Assume coin availability is good (all available)
    avail_dollar        = 1;
    avail_half          = 1;
    avail_quarter       = 1;
    avail_dime          = 1;
    avail_nickel        = 1;
    // All items in stock initially
    stock_sensor        = 6'b111111;
    
    #10;
    reset = 0;
    
    // -------------------------------------------
    // Test 1: Purchase a product (product index 2)
    // Insert coins to reach $2.00 (200 cents) then select.
    // Expected: product dispensed and 25 cents change returned.
    // -------------------------------------------
    $display("Test 1: Purchase product index 2 - Expect product dispensed and 25 cents change");
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +$1.00
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +$1.00 (Total = 200 cents)
    #10; product_select = 3'd2; product_select_valid = 1; #10; product_select_valid = 0;
    #100;
    
    // -------------------------------------------
    // Test 2: Cancel transaction via the return button.
    // Insert coins that sum to 150 cents then press return.
    // -------------------------------------------
    $display("Test 2: Cancel transaction - Expect full balance of 150 cents returned");
    #10; coin_quarter = 1; #10; coin_quarter = 0;  // +25 cents
    #10; coin_quarter = 1; #10; coin_quarter = 0;  // +25 cents (Total = 50)
    #10; coin_dollar  = 1; #10; coin_dollar  = 0;  // +100 cents (Total = 150)
    #10; return_button = 1; #10; return_button = 0;
    #100;
    
    // -------------------------------------------
    // Test 3: Attempt purchase when item is out–of–stock.
    // Mark product 4 as out–of–stock.
    // Insert coins totaling 190 cents then select product 4.
    // Expected: no product dispensed; full balance returned.
    // -------------------------------------------
    $display("Test 3: Purchase product index 4 (out-of-stock) - Expect no product and refund of all coins (190 cents)");
    stock_sensor[4] = 0; // product 4 out–of–stock
    #10; coin_dollar   = 1; #10; coin_dollar   = 0;  // +100 cents
    #10; coin_half     = 1; #10; coin_half     = 0;      // +50 cents (Total = 150)
    #10; coin_quarter  = 1; #10; coin_quarter  = 0;      // +25 cents (Total = 175)
    #10; coin_dime     = 1; #10; coin_dime     = 0;        // +10 cents (Total = 185)
    #10; coin_nickel   = 1; #10; coin_nickel   = 0;      // +5 cents  (Total = 190)
    #10; product_select = 3'd4; product_select_valid = 1; #10; product_select_valid = 0;
    #100;
    
    // -------------------------------------------
    // Test 4: "Steal" Scenario: Insufficient coin inventory for making change.
    // Setup: Insert $2.00 then select a product (product index 1).
    // But set avail_quarter, avail_dime, and avail_nickel to 0 so that 25¢ change
    // cannot be made (even though the product is in stock).
    // Expected: Product dispensed and the extra 25¢ is "stolen" (no coin returned).
    // -------------------------------------------
    $display("Test 4: Insufficient coin inventory for change - Expect product dispensed and no coin return for extra 25 cents");
    stock_sensor = 6'b111111;  // all in stock
    avail_dollar   = 1;
    avail_half     = 1;
    avail_quarter  = 0;  // quarter unavailable
    avail_dime     = 0;  // dime unavailable
    avail_nickel   = 0;  // nickel unavailable
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +100 cents
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +100 cents (Total = 200)
    #10; product_select = 3'd1; product_select_valid = 1; #10; product_select_valid = 0;
    #100;
    
    // -------------------------------------------
    // Test 5: Multiple Coins in the Same Cycle:
    // Drive more than one coin signal in one clock cycle.
    // Expected: Balance should increase by the sum of the coins.
    // -------------------------------------------
    $display("Test 5: Multiple coins in one cycle - Expect balance increased by 15 cents and refund of 15 cents upon return");
    avail_nickel = 1;  // Restore availability
    avail_dime   = 1;  // Restore availability
    avail_quarter = 1; // Restore availability
    #10;
      coin_dime   = 1;
      coin_nickel = 1;
    #10;
      coin_dime   = 0;
      coin_nickel = 0;
    #10; return_button = 1; #10; return_button = 0;
    #100;
    
    // -------------------------------------------
    // Test 6: Exact Change Transaction:
    // Insert exactly 175 cents (using coin_dollar, coin_half, and coin_quarter)
    // then select a product.
    // Expected: Product dispensed, no change returned, balance resets to zero.
    // -------------------------------------------
    $display("Test 6: Exact Change Transaction - Expect product dispensed with no change returned");
    stock_sensor = 6'b111111; // ensure product is in stock
    #10; coin_dollar  = 1; #10; coin_dollar  = 0;  // +100 cents
    #10; coin_half    = 1; #10; coin_half    = 0;  // +50 cents (Total = 150)
    #10; coin_quarter = 1; #10; coin_quarter = 0;  // +25 cents  (Total = 175)
    #10; product_select = 3'd0; product_select_valid = 1; #10; product_select_valid = 0;
    #100;
    
    // -------------------------------------------
    // Test 7: Rapid Successive Transactions:
    // Immediately begin a new transaction after one completes.
    // Expected: The machine resets correctly between transactions.
    // -------------------------------------------
    $display("Test 7: Rapid Successive Transactions - Machine accumulates coins correctly between transactions");
    // First transaction: successful purchase.
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +100 cents
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +100 cents (Total = 200)
    #10; product_select = 3'd1; product_select_valid = 1; #10; product_select_valid = 0;
    // Immediately start a second transaction: cancel transaction.
    #10; coin_quarter = 1; #10; coin_quarter = 0;  // +25 cents
    #10; coin_quarter = 1; #10; coin_quarter = 0;  // +25 cents (Total = 50)
    #10; coin_dollar  = 1; #10; coin_dollar  = 0;  // +100 cents (Total = 150)
    #10; return_button = 1; #10; return_button = 0;
    #100;
    
    // -------------------------------------------
    // Test 8: Mid-Transaction Reset:
    // While coins are being accumulated, assert the reset signal.
    // Expected: The state machine resets immediately, clearing the balance and outputs.
    // -------------------------------------------
    $display("Test 8: Mid-Transaction Reset - Expect state machine to reset and clear balance");
    // Insert some coins.
    #10; coin_dollar = 1; #10; coin_dollar = 0;  // +100 cents
    #10; coin_dime = 1; #10; coin_dime = 0;        // +10 cents (Total = 110)
    // Now assert reset mid-transaction.
    #10; reset = 1; #10; reset = 0;
    // Attempt a product selection (should be ignored because balance is now 0)
    #10; product_select = 3'd3; product_select_valid = 1; #10; product_select_valid = 0;
    #100;
    
    $finish;
end

endmodule
