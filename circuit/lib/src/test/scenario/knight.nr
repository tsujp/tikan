// use dep::state::types::Game;

// //
// // KNIGHT BOARD SCENARIOS
// //

// // ---------------------------------------------------------------------------

// // BOARD_SCENARIOS: Knight boards.

// global SCENARIOS: [Game; N] = [

// Game {
//     bbs: [ 0x8100000000000081, 0, 0x8100000000000081, 0, 0, 0, 0, 0 ],
//     army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
// },

// // Board with knights one-move away from each other.
// Game {
//     bbs: [ 0x14000800140000, 0, 0x14000800140000, 0, 0, 0, 0, 0 ],
//     army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
// },

// // Dense board with lots of (and only) white pieces.
// Game {
//     bbs: [ 0x8124520008422481, 0, 0x8124520008422481, 0, 0, 0, 0, 0 ],
//     army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
// },

// ];

// Board with 4 white rooks in each corner: a1, a8, h8, h1.
// global N_01: Game = Game {
//     bbs: [ 0x8100000000000081, 0, 0x8100000000000081, 0, 0, 0, 0, 0 ],
//     army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
// };

// // Board with knights one-move away from each other.
// global N_02: Game = Game {
//     bbs: [ 0x14000800140000, 0, 0x14000800140000, 0, 0, 0, 0, 0 ],
//     army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
// };

// // Dense board with lots of (and only) white pieces.
// global N_03: Game = Game {
//     bbs: [ 0x8124520008422481, 0, 0x8124520008422481, 0, 0, 0, 0, 0 ],
//     army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
// };

// XXX: Test helper only.
// fn _apply(game: Game, from: BitboardIndex, to: BitboardIndex) {
//     let _ = game.apply(Turn { piece: Piece::KNIGHT, from, to, promotion_piece: 0 });
// }
