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
