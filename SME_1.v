module SME(clk,
           reset,
           chardata,
           isstring,
           ispattern,
           valid,
           match,
           match_index);
    /*-------------------------------------PARAMETERS declarations----------------------------*/
    parameter CHAR_LENGTH          = 8;
    parameter STRING_LENGTH        = 32;
    parameter PATTERN_INDEX_LENGTH = 3;
    parameter STRING_INDEX_LENGTH  = 5;
    parameter INDEX_WIDTH          = 5;
    parameter PATTERN_LENGTH       = 8;

    /*-------------------------------------ASCII-----------------------------------------------*/
    // ^ = 8'H5E , $ = 8'H24 , _ = 8'H5f ,  . = 8'h2e
    localparam HAT    = 8'h5e;
    localparam DOLLAR = 8'h24;
    localparam SPACE  = 8'h5f;
    localparam DOT    = 8'h2e;


    /*----------------------------Input output of SME------------------------------------------------*/
    input clk;
    input reset;
    input[CHAR_LENGTH-1:0] chardata;
    input isstring;
    input ispattern;


    output reg valid;
    output reg match;
    output reg[INDEX_WIDTH-1:0] match_index;


    /*----------------------------------------SME_CTR------------------------------------------*/
    reg[3:0] sme_current_state,sme_next_state;
    localparam   IDLE            = 0;
    localparam   RD_PATTERN      = 1;
    localparam   RD_STRING       = 2;
    localparam   PREPROCESS      = 3;
    localparam   COMPARING       = 4;
    localparam   DONE            = 5;
    localparam   START_COMPARING = 6;
    localparam  START_PREPROCESS = 7;

    wire sme_state_IDLE;
    wire sme_state_RD_PATTERN;
    wire sme_state_RD_STRING;
    wire sme_state_START_PREPROCESS;
    wire sme_state_START_COMPARING;
    wire sme_state_PREPROCESS;
    wire sme_state_COMPARING;
    wire sme_state_DONE;

    assign sme_state_IDLE             = sme_current_state == IDLE;
    assign sme_state_RD_PATTERN       = sme_current_state == RD_PATTERN;
    assign sme_state_RD_STRING        = sme_current_state == RD_STRING;
    assign sme_state_PREPROCESS       = sme_current_state == PREPROCESS;
    assign sme_state_COMPARING        = sme_current_state == COMPARING;
    assign sme_state_DONE             = sme_current_state == DONE;
    assign sme_state_START_COMPARING  = sme_current_state == START_COMPARING;
    assign sme_state_START_PREPROCESS = sme_current_state == START_PREPROCESS;

    reg Start_preprocessing;
    reg Start_Comparing;
    reg Preprocessing_done_flag;
    reg Comparing_done_flag;
    reg Done_flag;

    /*---------------------RD_DATA--------------------*/
    integer string_index;
    integer pattern_index;
    reg[CHAR_LENGTH-1:0] string_reg[0:STRING_LENGTH-1];
    reg[CHAR_LENGTH-1:0] pattern_reg[0:PATTERN_LENGTH-1];
    reg[PATTERN_INDEX_LENGTH-1:0] pattern_length_general_reg;
    reg[PATTERN_INDEX_LENGTH-1:0] pattern_length_he_reg;
    reg[STRING_INDEX_LENGTH-1:0] string_length_reg;
    reg[INDEX_WIDTH-1:0] rd_string_index_reg;
    reg[INDEX_WIDTH-1:0] rd_pattern_index_reg;

    /*--------------------Preprocessing-----------------*/
    reg[2:0] pp_current_state,pp_next_state;
    reg[CHAR_LENGTH-1:0] pattern_he_reg[0:PATTERN_LENGTH-1];
    reg[CHAR_LENGTH-1:0] pattern_general_reg[0:PATTERN_LENGTH-1];
    localparam PP_IDLE       = 0 ;
    localparam PP_PROCESSING = 1;
    localparam PP_DONE       = 2;

    wire pp_state_IDLE ;
    wire pp_state_PROCESSING;
    wire pp_state_DONE;

    assign pp_state_IDLE       = pp_current_state == PP_IDLE ;
    assign pp_state_PROCESSING = pp_current_state == PP_PROCESSING;
    assign pp_state_DONE       = pp_current_state == PP_DONE;

    /*--------------------Comparing---------------------*/
    reg com_done_flag;

    reg[CHAR_LENGTH-1:0] cg_shf_left_string_reg[0:STRING_LENGTH-1];
    reg[PATTERN_INDEX_LENGTH-1:0] cg_match_index_reg;
    reg[PATTERN_LENGTH-1:0] cg_match_map;

    wire[STRING_INDEX_LENGTH-1:0] cg_shf_amount_reg;
    wire cg_eos_flag;
    wire cg_match_flag;

    reg[CHAR_LENGTH-1:0] he_shf_left_string_reg[0:STRING_LENGTH-1];
    reg[PATTERN_INDEX_LENGTH-1:0] he_shf_amount_reg;
    reg[PATTERN_INDEX_LENGTH-1:0] he_match_index_reg;
    reg[PATTERN_LENGTH-1:0] he_match_map;

    wire he_match_flag;
    wire he_shf_amount_zero;

    //COMPARING CTR
    reg[3:0] com_current_state,com_next_state;

    //compare general
    localparam COM_IDLE      = 0;
    localparam COM_COMPARING = 1;
    localparam COM_MATCH     = 2;
    localparam COM_UNMATCH   = 3;
    localparam COM_SLL       = 4;
    localparam COM_DONE      = 5;
    localparam COM_RD_STRING = 6;

    wire com_state_IDLE;
    wire com_state_COMPARING;
    wire com_state_MATCH;
    wire com_state_UNMATCH;
    wire com_state_SLL;
    wire com_state_DONE;
    wire com_state_RD_STRING;

    assign com_state_IDLE      = com_current_state == COM_IDLE;
    assign com_state_COMPARING = com_current_state == COM_COMPARING;
    assign com_state_MATCH     = com_current_state == COM_MATCH;
    assign com_state_UNMATCH   = com_current_state == COM_UNMATCH;
    assign com_state_SLL       = com_current_state == COM_SLL;
    assign com_state_DONE      = com_current_state == COM_DONE;
    assign com_state_RD_STRING = com_current_state == COM_RD_STRING;


    /*----MAIN----*/
    /*---------------------SME_CTR-----------------------*/
    always @(posedge clk or posedge reset)
        sme_current_state <= reset ? IDLE : sme_next_state;

    always @(*)
    begin
        case(sme_current_state)
            IDLE:
            begin
                sme_next_state                                  = isstring ? RD_STRING : IDLE;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b000;
            end
            RD_STRING:
            begin
                sme_next_state                                  = isstring ? RD_STRING : ispattern ? RD_PATTERN : IDLE;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b000;
            end
            RD_PATTERN:
            begin
                sme_next_state                                  = ispattern ? RD_PATTERN : START_PREPROCESS;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b000;
            end
            START_PREPROCESS:
            begin
                sme_next_state                                  = PREPROCESS;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b100;
            end
            PREPROCESS:
            begin
                sme_next_state                                  = Preprocessing_done_flag ? START_COMPARING : PREPROCESS;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b000;
            end
            START_COMPARING:
            begin
                sme_next_state                                  = COMPARING;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b010;
            end
            COMPARING:
            begin
                sme_next_state                                  = Comparing_done_flag ? DONE : COMPARING;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b000;
            end
            DONE:
            begin
                sme_next_state                                  = isstring ? RD_STRING : ispattern ? RD_PATTERN : IDLE;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b001;
            end

            default:
            begin
                sme_next_state                                  = isstring ? RD_STRING : RD_PATTERN;
                {Start_preprocessing,Start_Comparing,Done_flag} = 3'b000;
            end
        endcase
    end

    /*------------------RD_DATA&STR_PT_CAL---------------*/
    //read_string_index_reg
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            rd_string_index_reg <= 0;
        end
        else
        begin
            case(sme_current_state)
                DONE:
                begin
                    rd_string_index_reg <= isstring ? 0 : rd_string_index_reg;
                end
                RD_STRING:
                begin
                    rd_string_index_reg <= isstring ? rd_string_index_reg + 1 : rd_string_index_reg;
                end
                default:
                begin
                    rd_string_index_reg <= rd_string_index_reg;
                end
            endcase
        end
    end

    //string_length_reg
    always @(negedge clk or posedge reset)
    begin
        string_length_reg <= reset ? 0 : isstring ? string_length_reg + 1 : string_length_reg;
    end
    //rd_pattern_index_reg
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            rd_pattern_index_reg <= 0;
        end
        else
        begin
            case(sme_current_state)
                DONE:
                begin
                    rd_pattern_index_reg <= 0;
                end
                RD_PATTERN:
                begin
                    rd_pattern_index_reg <= ispattern ? rd_pattern_index_reg + 1 : rd_pattern_index_reg;
                end
                default:
                begin
                    rd_pattern_index_reg <= rd_pattern_index_reg;
                end
            endcase
        end
    end

    //string_reg
    always @(negedge clk or posedge reset)
    begin
        if (reset)
        begin
            for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index + 1)
            begin
                string_reg[string_index] <= {CHAR_LENGTH{1'b0}};
            end
        end
        else
        begin
            case(sme_current_state)
                DONE:
                begin
                    for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index + 1)
                    begin
                        string_reg[string_index] <= isstring ? {CHAR_LENGTH{1'b0}} : string_reg[string_index];
                    end
                end
                RD_STRING:
                begin
                    string_reg[rd_string_index_reg] <= isstring ? chardata : string_reg[rd_string_index_reg];
                end
                default:
                begin
                    for(string_index = 0 ; string_index < STRING_LENGTH ; string_index = string_index + 1)
                    begin
                        string_reg[string_index] <= string_reg[string_index];
                    end
                end
            endcase
        end
    end

    //pattern_reg
    always @(negedge clk or posedge reset)
    begin
        if (reset)
        begin
            for(pattern_index = 0 ; pattern_index < PATTERN_LENGTH ; pattern_index = pattern_index + 1)
            begin
                pattern_reg[pattern_index] <= {CHAR_LENGTH{1'b0}};
            end
        end
        else
        begin
            case(sme_current_state)
                DONE:
                begin
                    for(pattern_index = 0 ; pattern_index < PATTERN_LENGTH ; pattern_index = pattern_index + 1)
                    begin
                        pattern_reg[pattern_index] <= ispattern || isstring ? {CHAR_LENGTH{1'b0}} : pattern_reg[pattern_index];
                    end
                end
                RD_PATTERN:
                begin
                    pattern_reg[rd_pattern_index_reg] <= ispattern ? chardata : pattern_reg[rd_pattern_index_reg];
                end
                default:
                begin
                    for(pattern_index = 0 ; pattern_index < PATTERN_LENGTH ; pattern_index = pattern_index + 1)
                    begin
                        pattern_reg[pattern_index] <= pattern_reg[pattern_index];
                    end
                end
            endcase
        end
    end

    //pattern_length_general_reg
    always @(negedge clk or posedge reset)
    begin
        if (reset || sme_state_DONE)
        begin
            pattern_length_general_reg <= 0;
        end
        else
        begin
            pattern_length_general_reg <= ispattern ? pattern_length_general_reg + 1 : pattern_length_general_reg;
        end
    end

    //pattern_length_he_reg
    always @(negedge clk or posedge reset)
    begin
        if (reset || sme_state_DONE)
        begin
            pattern_length_he_reg <= 0;
        end
        else
        begin
            // ^ and $ doesnt counts
            if (ispattern && sme_state_RD_PATTERN)
            begin // ^ = 8'H5E $ = 8'H24
                if (chardata == HAT || chardata == DOLLAR)
                begin
                    pattern_length_he_reg <= pattern_length_he_reg;
                end
                else
                begin
                    pattern_length_he_reg <= pattern_length_he_reg + 1;
                end
            end
            else
            begin
                pattern_length_he_reg <= pattern_length_he_reg;
            end
        end
    end


    /*-----------------------------Preprocessing----------------------------*/
    //Preprocess CTR
    //GENERAL Compare
//CTR
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
        end
        COM_RD_STRING:
        begin
            com_next_state = COM_COMPARING;
            com_done_flag  = 0;
        end
        COM_COMPARING:
        begin
            com_next_state = he_match_flag ? COM_DONE : cg_match_flag ? COM_DONE : COM_COMPARING;
            com_done_flag  = 0;
        end
        COM_SLL:
        begin

            com_done_flag  = 0;
        end
        COM_MATCH:
        begin
            com_next_state = COM_DONE;
            com_done_flag  = 0;
        end
        COM_DONE:
        begin
            com_next_state = Start_Comparing ? COM_IDLE : COM_DONE;
            com_done_flag  = 1;
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
    else if(com_state_DONE)
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
    else if(com_state_DONE)
    begin

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
assign cg_match_flag      = &cg_match_map;

//he_shf_amount_reg
always @(negedge clk or posedge reset)
begin
    if (reset)
    begin
        he_shf_amount_reg <= 0;
    end
    else
    begin
        case(com_current_state)
            COM_IDLE:
            begin
                he_shf_amount_reg <= Start_Comparing ? string_length_reg - pattern_length_he_reg : 0;
            end
            COM_SLL:
            begin
                he_shf_amount_reg <= he_shf_amount_reg - 1;
            end
            default:
            begin
                he_shf_amount_reg <= he_shf_amount_reg;
            end
        endcase
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
    else if(com_state_IDLE)
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
    else if(com_state_IDLE)
    begin
        match_index <= 'd0;
    end
    else
    begin
        case()



        endcase
    end
end
endmodule
