use dep::state::types::{Game, Turn, BitboardIndex, Promote};
use crate::test::util::{cc, cc_promote, assert_bbs};
use crate::test::util::swiss as t;

//
// PASSING SPECIAL
//

// White x8, Black x8.
global PAWN_START_RANKS: [BitboardIndex; 16] = [
    8, 9, 10, 11, 12, 13, 14, 15,
    48, 49, 50, 51, 52, 53, 54, 55
];

// ---------------------------------------------------------------------------
// ---------------------------------------------- PROMOTION

// ---------------- White and black vertical promotions

#[test]
fn pawn_promote_vertical() {
    let piece = t::Piece::PAWN;
    let single_move_delta = 8;

    let white = t::sg::init(
        t::Player::WHITE,
        // White pawns on last rank before promotion.
        [(t::bb::WHITE, t::bb::PAWN, 0xFF000000000000)]
    ).game;
    let sut_white = cc_promote(white, piece);

    let black = t::sg::init(
        t::Player::BLACK,
        // Black pawns on last rank before promotion.
        [(t::bb::BLACK, t::bb::PAWN, 0xFF00)]
    ).game;
    let sut_black = cc_promote(black, piece);

    // Index into poor-man's enum `Promote`.
    let mut promote_piece: u8 = 0;

    // We don't really need the SeedGame structure for these tests so it's not used for speed.
    for from in PAWN_START_RANKS {
        let data: (Game, Game, u8) = if from > 15 {
            // White promotion at black's end.
            let to = from + single_move_delta;
            (white, sut_white(from, to, promote_piece), to)
        } else {
            // Black promotion at white's end.
            let to = from - single_move_delta;
            (black, sut_black(from, to, promote_piece), to)
        };

        let nuked_pawn = (2 as Field).pow_32(from as Field) as u64;
        let base = data.0;
        let real = data.1;
        let to = data.2 as Field;

        let mut expected = real.bbs;

        // Overwrite the real bitboards (resulting from our implementation) with
        //   what we expect them to be; so if they differ the following assert
        //   will fail.
        expected[t::bb::PAWN] = base.bbs[t::bb::PAWN] ^ nuked_pawn;
        expected[(promote_piece as u8) + 2] = (2 as Field).pow_32(to) as u64;

        assert_bbs(real, expected);

        promote_piece = dep::std::wrapping_add(promote_piece, 1);
    }
}

// ---------------- White diagonal promotions (i.e. with captures)

#[test]
fn pawn_promote_diag() {
    // Vertical test already did many squares with different pieces, this
    //   test is more focused so we'll again use SeedGame. We also only test
    //   white because both players being able to promote was tested in vertical.

    let piece = t::Piece::PAWN;

    // [RANK]                        [INDICES]

    //    8      . 56   . 57  bP 58  bP 59  bP 60   . 61   . 62   . 63
    //    7     wP 48  bP 49  wP 50   . 51   . 52  wP 53  wP 54   . 55
    //    6      . 40  wP 41   . 42   . 43   . 44   . 45   . 46  wP 47
    //    5      . 32   . 33   . 34   . 35   . 36   . 37   . 38   . 39
    //    4      . 24   . 25   . 26   . 27   . 28   . 29   . 30   . 31
    //    3      . 16   . 17   . 18   . 19   . 20   . 21   . 22   . 23
    //    2      .  8   .  9   . 10   . 11   . 12   . 13   . 14   . 15
    //    1     wR  0  wN  1  wB  2  wQ  3  wK  4  wB  5  wN  6  wR  7

    //           a      b      c      d      e      f      g      h      [FILE]

    let white = t::sg::init(
        t::Player::WHITE,
        [
        (t::bb::WHITE, t::bb::KNIGHT, 0x42),
        (t::bb::BLACK, t::bb::KNIGHT, 0x0),
        (t::bb::WHITE, t::bb::BISHOP, 0x24),
        (t::bb::BLACK, t::bb::BISHOP, 0x0),
        (t::bb::WHITE, t::bb::ROOK, 0x81),
        (t::bb::BLACK, t::bb::ROOK, 0x0),
        (t::bb::WHITE, t::bb::QUEEN, 0x8),
        (t::bb::BLACK, t::bb::QUEEN, 0x0),
        (t::bb::WHITE, t::bb::KING, 0x10),
        (t::bb::BLACK, t::bb::KING, 0x0),
        (t::bb::WHITE, t::bb::PAWN, 0x65820000000000),
        (t::bb::BLACK, t::bb::PAWN, 0x1C02000000000000)
    ]
    );

    let _ = white.assert_delta_promote(
        piece,
        t::sq::c7,
        t::sq::d8,
        Promote::KNIGHT,
        [
        (t::bb::WHITE, t::bb::PAWN, 0x61820000000000),
        (t::bb::BLACK, t::bb::PAWN, 0x1402000000000000),
        (t::bb::WHITE, t::bb::KNIGHT, 0x800000000000042)
    ]
    );
    let _ = white.assert_delta_promote(
        piece,
        t::sq::f7,
        t::sq::e8,
        Promote::ROOK,
        [
        (t::bb::WHITE, t::bb::PAWN, 0x45820000000000),
        (t::bb::BLACK, t::bb::PAWN, 0xC02000000000000),
        (t::bb::WHITE, t::bb::ROOK, 0x1000000000000081)
    ]
    );
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT CAPTURE

#[test]
fn pawn_en_passant_capture_white() {
    let _ = t::sc::PAWN[2].assert_delta(
        t::Piece::PAWN,
        t::sq::d5,
        t::sq::e6,
        [
        (t::bb::WHITE, t::bb::PAWN, 0x100000807700),
        (t::bb::BLACK, t::bb::PAWN, 0xEF000000000000)
    ]
    );
}

#[test]
fn pawn_en_passant_capture_black() {
    let _ = t::sc::PAWN[3].assert_delta(
        t::Piece::PAWN,
        t::sq::g4,
        t::sq::h3,
        [
        (t::bb::WHITE, t::bb::PAWN, 0x1126C0000),
        (t::bb::BLACK, t::bb::PAWN, 0x1863800800000)
    ]
    );
}

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
        let data: (u8, Game) = if from > 15 {
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
// ---------------------------------------------- CASTLING

// TODO
