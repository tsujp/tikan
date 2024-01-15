use crate::test::util::swiss as t;

//
// PASSING COMMON
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- NORMAL CAPTURES CORRECT STATE

// TODO

// TODO: Tests that a knight can capture a piece and the state of the `Game` afterwards matches (correct pieces removed etc).

// TODO: Piece captures except special moves (e.g. en-passant) go here.

// ---------------- Knights

// #[test]
// fn knight_capture_knight() {

// }

// #[test]
// fn knight_capture_bishop() {

// }

// #[test]
// fn knight_capture_rook() {

// }

// #[test]
// fn knight_capture_queen() {

// }

// #[test]
// fn knight_capture_king() {

// }

// #[test]
// fn knight_capture_pawn() {

// }

// ---------------- Bishops

// #[test]
// fn bishop_capture_knight() {

// }

// #[test]
// fn bishop_capture_bishop() {

// }

// #[test]
// fn bishop_capture_rook() {

// }

// #[test]
// fn bishop_capture_queen() {

// }

// #[test]
// fn bishop_capture_king() {

// }

// #[test]
// fn bishop_capture_pawn() {

// }

// ---------------- Rooks

// #[test]
// fn rook_capture_knight() {

// }

// #[test]
// fn rook_capture_bishop() {

// }

// #[test]
// fn rook_capture_rook() {

// }

// #[test]
// fn rook_capture_queen() {

// }

// #[test]
// fn rook_capture_king() {

// }

// #[test]
// fn rook_capture_pawn() {

// }

// ---------------- Queens

// #[test]
// fn queen_capture_knight() {

// }

// #[test]
// fn queen_capture_bishop() {

// }

// #[test]
// fn queen_capture_rook() {

// }

// #[test]
// fn queen_capture_queen() {

// }

// #[test]
// fn queen_capture_king() {

// }

// #[test]
// fn queen_capture_pawn() {

// }

// ---------------- Kings

// #[test]
// fn king_capture_knight() {

// }

// #[test]
// fn king_capture_bishop() {

// }

// #[test]
// fn king_capture_rook() {

// }

// #[test]
// fn king_capture_queen() {

// }

// #[test]
// fn king_capture_king() {

// }

// #[test]
// fn king_capture_pawn() {

// }

// ---------------- Pawns (no en-passant)

// #[test]
// fn pawn_capture_knight() {
//     dep::std::println(sc::COMMON[1].no_fog);

// // white
// // 0x2214000000 // pawns
// // 0x40000000000 // knight
// // 0x8000000 // bishop
// // 0x4100 // rook
// // 0x8 // queen
// // 0x40000 // king

// // black
// // 0x410000000000 // pawns
// // 0x1000002000000 // knight
// // 0x42000000000000 // bishop
// // 0x2004000000000000 // rook
// // 0x8000000000 // queen
// // 0x100000000000 // king

// }

// #[test]
// fn pawn_capture_bishop() {

// }

// #[test]
// fn pawn_capture_rook() {

// }

#[test]
fn pawn_capture_queen() {
    let piece = t::Piece::PAWN;

    let white_s1 = t::sg::init(
        [
        (t::bb::WHITE, t::bb::QUEEN, 0x24000000000),
        (t::bb::WHITE, t::bb::PAWN, 0x40000000),
        (t::bb::BLACK, t::bb::QUEEN, 0x2000000000),
        (t::bb::BLACK, t::bb::PAWN, 0x4200000000000)
    ]
    );

    // g4 to f5 (white capture).
    let black_s1 = white_s1.assert_delta(
        piece,
        t::sq::g4,
        t::sq::f5,
        [
        (t::bb::BLACK, t::bb::QUEEN, 0),
        (t::bb::WHITE, t::bb::PAWN, 0x2000000000)
    ]
    );

    // f6 to g5 (black capture).
    let _ = black_s1.assert_delta(
        piece,
        t::sq::f6,
        t::sq::g5,
        [
        (t::bb::BLACK, t::bb::PAWN, 0x4004000000000),
        (t::bb::WHITE, t::bb::QUEEN, 0x20000000000)
    ]
    );

    // c7 to b6 (black capture).
    let _ = black_s1.assert_delta(
        piece,
        t::sq::c7,
        t::sq::b6,
        [
        (t::bb::BLACK, t::bb::PAWN, 0x220000000000),
        (t::bb::WHITE, t::bb::QUEEN, 0x4000000000)
    ]
    );
}

// #[test]
// fn pawn_capture_king() {
// }

#[test]
fn pawn_capture_pawn() {
    let piece = t::Piece::PAWN;

    let white_s1 = t::sg::init(
        [
        (t::bb::WHITE, t::bb::QUEEN, 0x24000000000),
        (t::bb::WHITE, t::bb::PAWN, 0x40000000),
        (t::bb::BLACK, t::bb::QUEEN, 0x2000000000),
        (t::bb::BLACK, t::bb::PAWN, 0x4200000000000)
    ]
    );

    // g4 to f5 (white capture).
    let black_s1 = white_s1.assert_delta(
        piece,
        t::sq::g4,
        t::sq::f5,
        [
        (t::bb::BLACK, t::bb::QUEEN, 0),
        (t::bb::WHITE, t::bb::PAWN, 0x2000000000)
    ]
    );

    // f6 to g5 (black capture).
    let _ = black_s1.assert_delta(
        piece,
        t::sq::f6,
        t::sq::g5,
        [
        (t::bb::BLACK, t::bb::PAWN, 0x4004000000000),
        (t::bb::WHITE, t::bb::QUEEN, 0x20000000000)
    ]
    );

    // c7 to b6 (black capture).
    let _ = black_s1.assert_delta(
        piece,
        t::sq::c7,
        t::sq::b6,
        [
        (t::bb::BLACK, t::bb::PAWN, 0x220000000000),
        (t::bb::WHITE, t::bb::QUEEN, 0x4000000000)
    ]
    );
}
