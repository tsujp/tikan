//
// FAILING COMMON TESTS
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- PIECES CANNOT MOVE INTO FOG

// XXX: These tests are tightly coupled to the fog pattern, if the fog pattern
//      is changed later (I think it might be honestly) these will need to
//      be re-written. All tests are tightly coupled but the baseline rules of
//      chess aren't really changing; maybe this is a non-statement.

// #[test]
// fn wat() {
//     let k = game::init([0x42, 0x4200000000000000, 0x4200000000000042], true);
//     dep::std::println(k);

//    let k1 = k.apply(Turn { piece: Piece::KNIGHT, from: 1, to: 18, promotion_piece: 0 });

//     dep::std::println(k1);
// }
