use dep::std::println;

use dep::state::game::Game;
use dep::state::turn::Turn;
use dep::state::types::{Piece, Bitboard, BitboardIndex};

use crate::test::util::dump_gamestate;

// TODO: Test pawn pushes
// TODO: Test en passant captures
// TODO: Test en passant output data is set correctly

// TODO: File a bug report attributes cannot have a full-stop in them. If you
//       put a full-stop at the end of that string it breaks everything. Same
//       with semicolons.

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn test_pawn_pushes_wrong_team() {
    // Normal starting board; black's turn.
    let b1 = Game {
        bbs: [
            0xffff,// White board
            0xffff000000000000,// Black board
            0x4200000000000042,// Knights
            0x2400000000000024,// Bishops
            0x8100000000000081,// Rooks
            0x0800000000000008,// Queens
            0x1000000000000010,// Kings
            0x00ff00000000ff00// Pawns
        ],
        army: 1, // Current army's turn (Game::Piece enum index)
        castle_rights: 15, // Bitmask castle rights K Q k q, 1 = yes, 0 = no
        en_passant: 0, // En-passant target square index (LERLEF 6-bits)
        halfmove: 0, // Halfmove count
        fullmove: 1 // Fullmove count
    };
    // White attempts to play on black's turn.
    // White triple push.
    let _ = b1.apply(
        Turn {
            piece: Piece::PAWN,
            from: 14, // g2
            to: 38, // g5
            promotion_piece: 0
        }
    );
    // Diagonal push when not capturing.
    let _ = b1.apply(
        Turn {
            piece: Piece::PAWN,
            from: 14, // g2
            to: 21, // f3
            promotion_piece: 0
        }
    );
    // White double push.
    let _ = b1.apply(
        Turn {
            piece: Piece::PAWN,
            from: 14, // g2
            to: 30, // g4
            promotion_piece: 0
        }
    );
    // White single push.
    let _ = b1.apply(
        Turn {
            piece: Piece::PAWN,
            from: 14, // g2
            to: 22, // g3
            promotion_piece: 0
        }
    );
}
