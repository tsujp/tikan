use dep::state::types::Game;

//
// BOARD SCENARIOS FOR TESTING
//

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// ---------------------------------------------- KNIGHTS

global KNIGHT: [Game; 3] = [

    // ---------------- Scenario 0

    // 4 white rooks in each corner: a1, a8, h8, h1.
    Game {
        bbs: [ 0x8100000000000081, 0, 0x8100000000000081, 0, 0, 0, 0, 0 ],
        army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
    },

    // ---------------- Scenario 1

    // Knights one-move away from each other.
    Game {
        bbs: [ 0x14000800140000, 0, 0x14000800140000, 0, 0, 0, 0, 0 ],
        army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
    },

    // ---------------- Scenario 2

    // Dense, lots of (and only) white pieces.
    Game {
        bbs: [ 0x8124520008422481, 0, 0x8124520008422481, 0, 0, 0, 0, 0 ],
        army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
    },

];
