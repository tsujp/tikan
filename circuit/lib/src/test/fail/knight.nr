use crate::test::scenario::KNIGHT as K_SCENARIO;
use crate::test::util;
use dep::state::types::Piece;

//
// FAILING KNIGHT TESTS
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- NOTHING MOVE (ILLEGAL)

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move() {
    let _ = util::cc(K_SCENARIO[0], Piece::KNIGHT)(0, 0);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE PATTERN (ILLEGAL)

// ---------------- Scenario 0

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn empty_pattern_01() {
    let _ = util::cc(K_SCENARIO[0], Piece::KNIGHT)(1, 63);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn empty_pattern_02() {
    let _ = util::cc(K_SCENARIO[0], Piece::KNIGHT)(0, 35);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn empty_pattern_03() {
    let _ = util::cc(K_SCENARIO[0], Piece::KNIGHT)(0, 47);
}

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn empty_pattern_04() {
    let _ = util::cc(K_SCENARIO[0], Piece::KNIGHT)(19, 20);
}

// ---------------- Scenario 2

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn dense_pattern_01() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(42, 59);
}

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn dense_pattern_02() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(21, 31);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn dense_pattern_03() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(13, 32);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn dense_pattern_04() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(50, 2);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- BLOCKED (ILLEGAL)

// ---------------- Scenario 1

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_01() {
    let _ = util::cc(K_SCENARIO[1], Piece::KNIGHT)(35, 52);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_02() {
    let _ = util::cc(K_SCENARIO[1], Piece::KNIGHT)(35, 50);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_03() {
    let _ = util::cc(K_SCENARIO[1], Piece::KNIGHT)(35, 20);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_04() {
    let _ = util::cc(K_SCENARIO[1], Piece::KNIGHT)(35, 18);
}

// ---------------- Scenario 2

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_01() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(44, 27);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_02() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(44, 50);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_03() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(10, 27);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_04() {
    let _ = util::cc(K_SCENARIO[2], Piece::KNIGHT)(17, 27);
}
