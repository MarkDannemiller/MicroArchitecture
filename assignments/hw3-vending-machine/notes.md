## Undergrads (EE 4375):
- Implement using Verilog a circuit that simulates a single column 6-item Coke machine where everything sells for $1.75.
- Cash only, no CCs.  Nickels, dimes, quarters, half-dollars, dollars. No pennies.
- If you don’t understand how a vending machine operates, get $20 in coins and figure it out edge cases. 
- Vending machines do not have count of inventory items or coins. They know empty TRUE / FALSE from sensors driven from testbench. 
- Show testbench simulation results to prove your design

## Vending Machine
- Input vector for the true/false stock of items from the test bench
- Return money if user selects empty item
- No delay required when returning money
- 1 coin at a time
- coin is a true/false sensor
- exact change only (less than 20 nickels)
- Look at `B520_PVA` and `B310_posnotedge` to see how to implement the posedge (do not posedge the coin)
   - All outside async signals go to D-flipflop
   - For posedge, add another flip flop
```
DIV-|--]----|--]----|--]---
   -|>-]   -|>-]   -|>-]
   |       |       |
Clk-----------------
```

### Putting in coins/returning coins
- Signal for insert coin tied to edge of clock
- Signal for coin returns tied to edge of clock
- "Exact change only" light -> only return extra change if it is available
   - Light up if coins are too low to make change
- Steal the rest of the balance if you can't return it
- Return button signal (always must press to get money back)

### Change Maker
- Vector in for balance
- Vector in for coin availability (true/false)
- Make this its own state machine
- Output a 5' vector of the coins to return

### Sizes of Objects:
- D, HD, Q, D, N -> coin input
- 9 bits for balance (max of $5)
- COINS
   - Don't count number of coins, just count the machine and user balance
   - Still need to store the number of coins for counter purposes
   - Just track the number of the coins through the test bench anad feed in the true/false as a signal
   - The machine in reality would feed the computer these signals

### Display
- Show output
   - Output lights for out of stock


Example:
- "B235_UART.v"
- "B240_catcase.v"  
- "B330_state.v"
   - Good example for showing vectorization of input states for test bench