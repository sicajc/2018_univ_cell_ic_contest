
//Arbitor
localparam  ARB_IDLE       = 0;
localparam  ARB_COMPARING  = 1;
localparam  ARB_HE_MATCH   = 2;
localparam  ARB_CG_MATCH   = 3;
localparam  ARB_BOTH_MATCH = 4;
localparam  ARB_UNMATCH    = 5;
localparam  ARB_DONE       = 6;

wire arb_state_IDLE     ;
wire arb_state_COMPARING ;
wire arb_state_HE_MATCH  ;
wire arb_state_CG_MATCH  ;
wire arb_state_BOTH_MATCH;
wire arb_state_DONE     ;


assign arb_state_IDLE       = arb_current_state == ARB_IDLE;
assign arb_state_COMPARING  = arb_current_state == ARB_COMPARING;
assign arb_state_HE_MATCH   = arb_current_state == ARB_HE_MATCH;
assign arb_state_CG_MATCH   = arb_current_state == ARB_CG_MATCH;
assign arb_state_BOTH_MATCH = arb_current_state == ARB_BOTH_MATCH;
assign arb_state_DONE       = arb_current_state == ARB_DONE;


//Arbiter
always @(posedge clk or posedge reset)
begin
    arb_current_state <= reset ? ARB_IDLE : arb_next_state;
end

always @(*)
begin
    case(arb_current_state)
        ARB_IDLE:
        begin
            arb_next_state      = Start_Comparing ? ARB_COMPARING : ARB_IDLE;
            Comparing_done_flag = 0;
            he_interrupt        = 0;
            cg_interrupt        = 0;
            match               = 0;
            valid               = 0;
        end
        ARB_COMPARING:
        begin
            case({he_done_flag,cg_done_flag,he_match_flag,cg_match_flag})
                4'b0000:
                begin
                    arb_next_state = ARB_COMPARING;
                end
                4'b0001:
                begin
                    arb_next_state = ARB_CG_MATCH;
                end
                4'b0010:
                begin
                    arb_next_state = ARB_HE_MATCH;
                end
                4'b0011:
                begin
                    arb_next_state = ARB_BOTH_MATCH;
                end
                4'b1100:
                begin
                    arb_next_state = ARB_UNMATCH;
                end
                default:
                begin
                    arb_next_state = ARB_IDLE;
                end
            endcase

            Comparing_done_flag = 0;
            he_interrupt        = 0;
            cg_interrupt        = 0;
            match               = 0;
            valid               = 0;
        end
        ARB_CG_MATCH:
        begin
            arb_next_state      = ARB_DONE;
            Comparing_done_flag = 1;
            he_interrupt        = 1;
            cg_interrupt        = 0;
            match               = 1;
            valid               = 1;
        end
        ARB_HE_MATCH:
        begin
            arb_next_state      = ARB_DONE;
            Comparing_done_flag = 1;
            he_interrupt        = 0;
            cg_interrupt        = 1;
            match               = 1;
            valid               = 1;
        end
        ARB_BOTH_MATCH:
        begin
            arb_next_state      = ARB_DONE;
            Comparing_done_flag = 1;
            he_interrupt        = 0;
            cg_interrupt        = 0;
            match               = 1;
            valid               = 1;
        end
        ARB_DONE:
        begin
            arb_next_state      = ARB_IDLE;
            Comparing_done_flag = 1;
            he_interrupt        = 0;
            cg_interrupt        = 0;
            match               = 0;
            valid               = 0;
        end
        default:
        begin
            arb_next_state      = ARB_IDLE;
            Comparing_done_flag = 0;
            he_interrupt        = 0;
            cg_interrupt        = 0;
            match               = 0;
            valid               = 0;
        end
    endcase
end
