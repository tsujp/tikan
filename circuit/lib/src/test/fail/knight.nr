use dep::state::types::Game;
use crate::test::util::cc as cc;
use crate::test::util::swiss as t;

//
// FAILING KNIGHT TESTS
//

fn scenario(idx: u64, from: u6, to: u6) -> () {
    let _ = cc(t::sc::KNIGHT[idx].no_fog.game, t::Piece::KNIGHT)(from, to);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- NOTHING MOVE (ILLEGAL)

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move() {
    scenario(0, t::sq::a1, t::sq::a1);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE PATTERN (ILLEGAL)

// ---------------- Scenario 0

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn empty_pattern_01() {
    scenario(0, t::sq::b1, t::sq::h8);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn empty_pattern_02() {
    scenario(0, t::sq::a1, t::sq::d5);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn empty_pattern_03() {
    scenario(0, t::sq::a1, t::sq::h6);
}

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn empty_pattern_04() {
    scenario(0, t::sq::d3, t::sq::e3);
}

// ---------------- Scenario 2

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn dense_pattern_01() {
    scenario(2, t::sq::c6, t::sq::d8);
}

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn dense_pattern_02() {
    scenario(2, t::sq::f3, t::sq::h4);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn dense_pattern_03() {
    scenario(2, t::sq::f2, t::sq::a5);
}

#[test(should_fail_with = "KNIGHT move PATTERN")]
fn dense_pattern_04() {
    scenario(2, t::sq::c7, t::sq::c2);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- BLOCKED (ILLEGAL)

// ---------------- Scenario 1

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_01() {
    scenario(1, t::sq::d5, t::sq::e7);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_02() {
    scenario(1, t::sq::d5, t::sq::c7);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_03() {
    scenario(1, t::sq::d5, t::sq::e3);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn empty_blocked_04() {
    scenario(1, t::sq::d5, t::sq::c3);
}

// ---------------- Scenario 2

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_01() {
    scenario(2, t::sq::e6, t::sq::d4);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_02() {
    scenario(2, t::sq::e6, t::sq::c7);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_03() {
    scenario(2, t::sq::c2, t::sq::d4);
}

#[test(should_fail_with = "KNIGHT move BLOCKED")]
fn dense_blocked_04() {
    scenario(2, t::sq::b3, t::sq::d4);
}
