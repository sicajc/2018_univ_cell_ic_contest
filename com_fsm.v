always @(posedge clk or posedge reset)
begin
    com_current_state <= reset ? COM_IDLE : com_next_state;
end

always @(*)
begin
    case(com_current_state)
        COM_IDLE:
        begin
            com_next_state = Start_Comparing ? COM_RD_STRING : COM_IDLE;
            com_done_flag  = 0;
            he_shf_start   = 0;
        end
        COM_RD_STRING:
        begin
            com_next_state = COM_COMPARING;
            com_done_flag  = 0;
            he_shf_start   = 0;
        end
        COM_COMPARING:
        begin
            com_next_state = he_match_flag ? COM_DONE : cg_match_flag ? COM_DONE : COM_COMPARING;
            com_done_flag  = 0;
            he_shf_start   = 1;
        end
        COM_SLL:
        begin
            com_next_state = he_match_flag ? COM_DONE : cg_match_flag ? COM_DONE : COM_COMPARING;
            com_done_flag  = 0;
            he_shf_start   = 1;
        end
        COM_DONE:
        begin
            com_next_state = Start_Comparing ? COM_IDLE : COM_DONE;
            com_done_flag  = 1;
            he_shf_start   = 0;
        end
    endcase
end

//cg_match_index
always @(negedge clk or posedge reset)
begin
    if (reset)
    begin
        cg_match_index_reg <= 0 ;
    end
    else if (com_state_DONE)
    begin
        cg_match_index_reg <= 0;
    end
    else
    begin
        cg_match_index_reg <= com_state_SLL ? cg_match_index_reg + 1 : cg_match_index_reg;
    end
end

assign cg_eos_flag = (cg_match_index_reg == string_length_reg - pattern_length_general_reg);


//cg_shf_left_string_reg
always @(negedge clk or posedge reset)
begin
    if (reset)
    begin
        for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index+1)
        begin
            cg_shf_left_string_reg[string_index] <= 0;
        end
    end
    else if (com_state_DONE)
    begin
        for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index+1)
        begin
            cg_shf_left_string_reg[string_index] <= 0;
        end
    end
    else
    begin
        for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index+1)
        begin
            case(com_current_state)
                COM_COMPARING:
                begin
                    for(pattern_index = 0;pattern_index<PATTERN_LENGTH;pattern_index = pattern_index+1)
                    begin
                        if (pattern_general_reg[pattern_index] == DOT || pattern_general_reg[pattern_index] == 0)
                        begin
                            cg_match_map[pattern_index] = 1;
                        end
                        else if (pattern_general_reg[pattern_index] == cg_shf_left_string_reg[pattern_index])
                        begin
                            cg_match_map[pattern_index] = 1;
                        end
                        else
                        begin
                            cg_match_map[pattern_index] = 0;
                        end
                    end
                end
                COM_SLL:
                begin
                    if (string_index == STRING_LENGTH-1)
                        cg_shf_left_string_reg[string_index] <= 0;
                    else
                        cg_shf_left_string_reg[string_index] <= cg_shf_left_string_reg[string_index+1];
                end
                COM_DONE:
                begin
                    cg_shf_left_string_reg[string_index] <= 0;
                end
                COM_RD_STRING:
                begin
                    cg_shf_left_string_reg[string_index] <= string_reg[string_index];
                end
                default:
                begin
                    cg_shf_left_string_reg[string_index] <= cg_shf_left_string_reg[string_index];
                end
            endcase
        end
    end
end

assign cg_shf_amount_reg = string_length_reg - pattern_length_general_reg;
assign cg_match_flag     = &cg_match_map;

//he_shf_flag
always @(*)
begin
    if (he_shf_start)
    begin
        he_shf_flag <= 1'b1;
    end
    else if (he_shf_amount_zero)
    begin
        he_shf_flag <= 1'b0;
    end
    else
    begin
        he_shf_flag <= 1'b0;
    end
end

//he_shf_amount_reg
always @(negedge clk or posedge reset)
begin
    if (reset)
    begin
        he_shf_amount_reg <= 0;
    end
    else
    begin
        if (com_state_IDLE)
        begin
            he_shf_amount_reg <= string_length_reg - pattern_he_reg;
        end
        else if (he_shf_flag)
        begin
            he_shf_amount_reg <= he_shf_amount_reg - 1;
        end
        else
        begin
            he_shf_amount_reg <= he_shf_amount_reg;
        end
    end
end

assign he_shf_amount_zero = he_shf_amount_reg == 0;

//he_match_index
always @(negedge clk or posedge reset)
begin
    if (reset)
    begin
        he_match_index_reg <= 0 ;
    end
    else if (com_state_IDLE)
    begin

    end
    else
    begin

    end
end

assign he_eos_flag = (he_shf_amount_reg == 0);

//he_shf_left_string_reg
always @(negedge clk or posedge reset)
begin
    if (reset)
    begin
        for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index+1)
        begin
            he_shf_left_string_reg[string_index] <= 'd0;
            he_match_map[pattern_index]          <= 'd0;
        end
    end
    else
    begin
        for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index+1)
        begin
            case(com_current_state)
                COM_COMPARING:
                begin
                    for(pattern_index = 0;pattern_index<PATTERN_LENGTH;pattern_index = pattern_index+1)
                    begin
                        if (pattern_he_reg[pattern_index] == DOT || pattern_he_reg[pattern_index] == 0)
                        begin
                            he_match_map[pattern_index] = 1'b1;
                        end
                        else if (pattern_general_reg[pattern_index] == he_shf_left_string_reg[pattern_index])
                        begin
                            he_match_map[pattern_index] = 1'b0;
                        end
                        else
                        begin
                            he_match_map[pattern_index] = 1'b0;
                        end
                    end
                    he_shf_left_string_reg[string_index] <= he_shf_left_string_reg[string_index];
                end
                COM_SLL:
                begin
                    if (string_index == STRING_LENGTH-1)
                    begin
                        he_shf_left_string_reg[string_index] <= 0;
                    end
                    else
                    begin
                        he_shf_left_string_reg[string_index] <= he_shf_left_string_reg[string_index+1];
                    end
                    he_match_map[pattern_index] <= he_match_map[pattern_index];
                end
                COM_DONE:
                begin
                    he_shf_left_string_reg[string_index] <= 0;
                    he_match_map[pattern_index]          <= he_match_map[pattern_index];
                end
                COM_RD_STRING:
                begin
                    he_shf_left_string_reg[string_index] <= string_reg[string_index];
                    he_match_map[pattern_index]          <= he_match_map[pattern_index];
                end
                default:
                begin
                    he_shf_left_string_reg[string_index] <= he_shf_left_string_reg[string_index];
                    he_match_map[pattern_index]          <= he_match_map[pattern_index];
                end
            endcase
        end
    end
end

assign he_match_flag = &he_match_map;

//Match_index_reg
always @(negedge clk or negedge reset)
begin
    if (reset)
    begin
        match_index <= 'd0;
    end
    else if (com_state_IDLE)
    begin
        match_index <= 'd0;
    end
    else
    begin
        case()



        endcase
    end
end
