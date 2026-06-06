// Serial divider for normalized fractions of the form 1.xxxxxx..
// Alexander López Parrado (2024)

module fractional_divider #(parameter N = 11)
                          (input wire clk,               // Global clock signal
                            input wire rst,              // Global reset signal
                            input wire start,            // To start division
                            input wire [N-1:0] dividend, // Dividend of the form 1.xxxxxxxx..xx
                            input wire [N-1:0] divisor,  // Divisor of the form 1.yyyyyyyy..yy
                            output [N-1:0] quotient,
                            output done);
    
    // Signals for datapath registers
    reg [N:0] divisor_reg;
    reg [N:0] remainder_reg;
    reg [N-1:0] quotient_shift_reg;
    
    // Signal for counter
    reg [$clog2(N):0] counter;
    
    // Signals for subtractor and multiplexers
    wire [N:0]sub_out;
    wire [N:0]input_mux_out;
    wire [N:0]remainder_mux_out;
    wire carry;
    wire ovf;
    
    // Signals for state machine
    reg state;
    reg en_shift;
    reg clr_shift;
    reg en_r;
    reg en_y;
    reg sel_rx;
    reg clr_counter;
    reg en_counter;
    
    // States for FSM
    localparam start_state = 0,compute_state = 1;
    
    
    // Datapath registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            divisor_reg        <= 0;
            remainder_reg      <= 0;
            quotient_shift_reg <= 0;
        end
        else begin
            
            // Divisor register
            if (en_y == 1)begin
                divisor_reg <= {1'b0,divisor};
            end
            // Remainder register
            if (en_r == 1) begin
                remainder_reg <= input_mux_out;
            end
            
            // Quotient shift register
            if (en_shift == 1) begin
                if (clr_shift == 0)
                    quotient_shift_reg <= {quotient_shift_reg[N-2:0],~carry};
                else
                    quotient_shift_reg <= 0;
            end
            
        end
    end
    
    // Datapath combinational circuits
    assign input_mux_out = (sel_rx == 0)?{remainder_mux_out[N-1:0],1'b0}:{1'b0,dividend};
    
    assign remainder_mux_out = (carry == 1)?remainder_reg:sub_out;
    
    assign sub_out = remainder_reg-divisor_reg;
    
    assign carry = sub_out[N];
    
    // FSM next state logic and state register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= start_state;
        end
        else begin
            
            case (state)
                start_state:
                if (start == 1)
                    state <= compute_state;
                else
                    state <= start_state;
                
                compute_state:
                
                if (ovf == 0)
                    state <= compute_state;
                else
                    state <= start_state;
                
                default:
                state <= start_state;
            endcase
            
        end
        
    end
    
    // FSM output logic
    always @(state,start,carry) begin
        case (state)
            start_state: begin
                
                
                if (start == 1) begin
                    clr_counter <= 1;
                    clr_shift   <= 1;
                    en_shift    <= 1;
                    en_counter  <= 1;
                    en_y        <= 1;
                    en_r        <= 1;
                    sel_rx      <= 1;
                end
                else begin
                    clr_counter <= 0;
                    en_counter  <= 0;
                    en_y        <= 0;
                    en_r        <= 0;
                    sel_rx      <= 0;
                    clr_shift   <= 0;
                    en_shift    <= 0;
                end
            end
            
            compute_state:
            begin
                
                en_y      <= 0;
                sel_rx    <= 0;
                clr_shift <= 0;
                
                if (ovf == 0) begin
                    clr_counter <= 0;
                    en_counter  <= 1;
                    en_shift    <= 1;
                    en_r        <= 1;
                end
                
                else begin
                    clr_counter <= 1;
                    en_counter  <= 1;
                    en_shift    <= 0;
                    en_r        <= 0;
                end               
            end
            
            
            
            default:
            begin
                en_shift    <= 0;
                clr_shift   <= 0;
                en_r        <= 0;
                en_y        <= 0;
                sel_rx      <= 0;
                clr_counter <= 0;
                en_counter  <= 0;                
            end
        endcase        
    end
    
    // Counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
        end
        else begin
            if (en_counter == 1) begin
                if (clr_counter == 1)
                    counter <= 0;                
                else
                counter <= counter+1;
                
            end
        end
    end
    
    // Overflow flag
    assign ovf = (counter == N)?1:0;    
    
    // Outputs connection
    assign quotient = quotient_shift_reg;
    assign done     = ovf;
endmodule
