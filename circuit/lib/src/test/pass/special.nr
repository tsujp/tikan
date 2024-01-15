use dep::state::types::{Game, BitboardIndex, Promote};
use crate::test::util::cc as cc;
use crate::test::util::swiss as t;

//
// PASSING SPECIAL
//

global PAWN_START_RANKS: [BitboardIndex; 16] = [
    8, 9, 10, 11, 12, 13, 14, 15,
    48, 49, 50, 51, 52, 53, 54, 55
];

// ---------------------------------------------------------------------------
// ---------------------------------------------- PROMOTION

// ---------------- White and black vertical promotions.

#[test]
fn pawn_promote_vertical_white() {
    let _ = t::sc::PAWN[2].assert_delta_promote(
        t::Piece::PAWN,
        t::sq::a7,
        t::sq::a8,
        Promote::KNIGHT,
        [(t::bb::WHITE, t::bb::PAWN, 0x64820000000000), (t::bb::WHITE, t::bb::KNIGHT, 0x100000000000042)]
    );

    let _ = t::sc::PAWN[2].assert_delta_promote(
        t::Piece::PAWN,
        t::sq::f7,
        t::sq::f8,
        Promote::BISHOP,
        [(t::bb::WHITE, t::bb::PAWN, 0x45820000000000), (t::bb::WHITE, t::bb::BISHOP, 0x2000000000000024)]
    );

    let _ = t::sc::PAWN[2].assert_delta_promote(
        t::Piece::PAWN,
        t::sq::g7,
        t::sq::g8,
        Promote::ROOK,
        [(t::bb::WHITE, t::bb::PAWN, 0x25820000000000), (t::bb::WHITE, t::bb::ROOK, 0x4000000000000081)]
    );

    let _ = t::sc::PAWN[2].assert_delta_promote(
        t::Piece::PAWN,
        t::sq::a7,
        t::sq::a8,
        Promote::QUEEN,
        [(t::bb::WHITE, t::bb::PAWN, 0x64820000000000), (t::bb::WHITE, t::bb::QUEEN, 0x100000000000008)]
    );
}

#[test]
fn pawn_promote_vertical_black() {}

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT CAPTURE

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT TARGET

// A pawn that has just double-pushed should be the en-passant target.
#[test]
fn pawn_en_passant_target_double() {
    let piece = t::Piece::PAWN;
    let double_move_delta = 16;
    let en_passant_delta = 8; // Same as a single move.

    let sut_white = cc(t::sc::PAWN[0].game, piece);
    let sut_black = cc(t::sc::PAWN[1].game, piece);

    for from in PAWN_START_RANKS {
        let data: (u6, Game) = if from > 15 {
            let to = from - double_move_delta;
            let ep = from - en_passant_delta;
            (ep, sut_black(from, to))
        } else {
            let to = from + double_move_delta;
            let ep = from + en_passant_delta;
            (ep, sut_white(from, to))
        };

        assert(data.0 == data.1.en_passant);
    }
}

// Do not set a pawn that single-pushed as the en-passant target.
#[test]
fn pawn_en_passant_target_single() {
    let piece = t::Piece::PAWN;
    let single_move_delta = 8;

    let sut_white = cc(t::sc::PAWN[0].game, piece);
    let sut_black = cc(t::sc::PAWN[1].game, piece);

    for from in PAWN_START_RANKS {
        let data: Game = if from > 15 {
            let to = from - single_move_delta;
            sut_black(from, to)
        } else {
            let to = from + single_move_delta;
            sut_white(from, to)
        };

        assert(data.en_passant == 0);
    }
}

// TODO: PR that empty tests should not be considered as ran, i.e. they should
//       be ignored. A test should require an `assert` is made as well as
//       having the `#[test]` attribute.
// En-passant targets are only valid for the subsequent turn and must be
//   cleared afterwards (automatically of course).
#[test]
fn pawn_en_passant_target_clear_1() {
    let game = t::sc::PAWN[0].game;
    let piece = t::Piece::PAWN;

    let white_to_move = cc(game, piece);

    let post_white = white_to_move(11, 27); // White d2 -> d4.
    assert(post_white.en_passant == 19); // En-passant target is d3 (behind d4).
    let black_to_move = cc(post_white, piece);
    let post_black = black_to_move(55, 47); // Black h7 -> h6.
    assert(post_black.en_passant == 0); // En-passant target should be reset.
}

#[test]
fn pawn_en_passant_target_clear_2() {
    let game = t::sc::PAWN[1].game;
    let piece = t::Piece::PAWN;

    let black_to_move = cc(game, piece);

    let post_black = black_to_move(50, 34); // Black c7 -> c5.
    assert(post_black.en_passant == 42); // En-passant target is c6 (behind c7).
    let white_to_move = cc(post_black, piece);
    let post_white = white_to_move(8, 16); // White a2 -> a3.
    assert(post_white.en_passant == 0); // En-passant target should be reset.
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT CAPTURE
