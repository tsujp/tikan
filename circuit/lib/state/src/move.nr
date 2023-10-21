use dep::std::println;

use crate::bitboard::Bitboard as Bitboard;

pub fn all_knight_moves(from_bb: Bitboard) -> Bitboard {
    let l1 = (from_bb >> 1) & 0x7f7f7f7f7f7f7f7f as Bitboard;
    let l2 = (from_bb >> 2) & 0x3f3f3f3f3f3f3f3f as Bitboard;
    let r1 = (from_bb << 1) & 0xfefefefefefefefe as Bitboard;
    let r2 = (from_bb << 2) & 0xfcfcfcfcfcfcfcfc as Bitboard;
    let h1 = l1 | r1;
    let h2 = l2 | r2;
    let res_mask = (h1<<16) | (h1>>16) | (h2<<8) | (h2>>8);
    println(f"(empty board) all valid moves: {res_mask}");

    res_mask
}

// Move validation (applying valid moves to produce new board state)

// Check is not considered as it is not a part of Fog of War Chess and constitutes a huge
//   amount of non-trivial effort for something which WILL be removed and .'. is
//   the definition of wasted time and energy.

// CURRENT FOCUS: Single and double pawn pushes with proof verification only.

// TODO: The of the pieces

// struct Move {
//     from_piece: u8,
//     from_square: u8,
//     to_square: u8,
//     capture: bool,
//     promotion_piece: u8,
// }

// impl Move {
//     pub fn new() -> Self {
//         Self {
//             // Values set to 999 as a poor man's initial invalid state, as
//             //   parsing a valid BERLEF-N input to set these should result in
//             //   a valid move. TODO: Less hacky version of this.
//             // TODO: Use Option instead of these satanic stub values.
//             from_piece: 999,
//             from_square: 999,
//             to_square: 999,
//             capture: false,
//             promotion_piece: 999,
//         }
//     }

//     // TODO: Probably just make the move mutable instead of nearly useless
//     //       method-setters like this.
//     pub fn set_from_piece(&mut self, piece: u8) {
//         self.from_piece = piece;
//     }

//     pub fn set_from_square(&mut self, square: u8) {
//         self.from_square = square;
//     }

//     pub fn set_to_square(&mut self, square: u8) {
//         self.to_square = square;
//     }

//     pub fn set_capture(&mut self, capture: bool) {
//         self.capture = capture;
//     }

//     pub fn set_promotion_piece(&mut self, piece: u8) {
//         self.promotion_piece = piece;
//     }
// }
