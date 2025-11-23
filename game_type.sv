package game_types;
    typedef enum logic [3:0] {
        S_IDLE,
        S_SET_D3, S_SET_D2, S_SET_D1, S_SET_D0,
        S_GUESS_D3, S_GUESS_D2, S_GUESS_D1, S_GUESS_D0,
        S_SHOW_RESULT,
        S_WIN,
        S_LOSE
    } state_t;
endpackage