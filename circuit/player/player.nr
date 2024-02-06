use dep::std::println;
use dep::std::collections::vec::Vec;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Game, Turn, Piece};

// TODO: Both players compute fog, if they verify the others' proof then the fog must be
//       good and so we can then say "where you fog overlaps, your piece is revealed."

fn main(
    // [GAME] Current before-turn gamestate.
    game: pub Game,
    // [MOVE] Players private turn to alter that gamestate and return new
    //   gamestate.
    turn: Turn,
    turn_salt: pub Field,
    turn_commitment: pub Field
) -> pub Game {
    // `Game` has assertions that check a `Move` is valid against the current
    //   gamestate (which `Game` represents); so this will fail if invalid.
    let new_gamestate = game.apply(turn);

    // XXX: Maybe there's a better way than adding checks here?
    if game.fullmove == 1 {
        if game.army == 0 {
            // White's first turn.
            assert(turn.bbs[0] == 0x42, "WHITE starting KNIGHT");
            assert(turn.bbs[1] == 0x24, "WHITE starting BISHOP");
            assert(turn.bbs[2] == 0x81, "WHITE starting ROOK");
            assert(turn.bbs[3] == 0x8, "WHITE starting QUEEN");
            assert(turn.bbs[4] == 0x10, "WHITE starting KING");
            assert(turn.bbs[5] == 0xff00, "WHITE starting PAWN");
        }
        // TODO: Black.
        // } else {
        //     // Black's first turn.
        // }
    }

    // XXX: Concatenating Field arrays is currently cancer, so do multiple
    //      commitment steps.
    let game_hash = pedersen_commitment(game.decompose()).x;
    let turn_hash = pedersen_commitment(turn.decompose()).x;
    let computed_commitment = pedersen_commitment([game_hash, turn_hash, turn_salt]).x;

    // Verify no tampering by checking commitments against prior state and the
    //   turn made against that state.
    assert(computed_commitment == turn_commitment);

    new_gamestate
}

// TODO: Another bitboard `lights` tracking which pieces have their
//       lights turned on.
// TODO: White array and black array with state commitments for square indices
//       if those pieces are hidden, so for X piece its on this square and its lights are on/off.
// TODO: This means game starts with bitboards functionally empty and all
//       pieces as state commitments.
// TODO: When a player plays a move (e.g. white first move) they can provide their secret input to
//       the circuit which is their pieces and their lights, this may the move validation logic can
//       check for a valid move. They do have to provide the commitments still because those need to
//       be sent to black with the circuit output for them to verify.
// TOOD: Where an opponents light area intersects (i.e. overlaps) the square a piece
//       of yours is on you must open your commitment, revealing the piece. This opening can be
//       checked against your prior commitments to see if you're lying or not.

// #[test]
// fn valid_turn_advances_game() {
//     // println(f"");

//     // Precomputed commitment for these values:
//     // 0x0ce7455bc1f72a29c691ead1751bc866d7d34bf8c46a7778038ca1ddaaf362a0

//     let w1 = Game {
//         bbs: [
//             0x080000f7ff,
//             0xffef001000000000,
//             0x4200000000000042,
//             0x2400000000000024,
//             0x8100000000000081,
//             0x0800000000000008,
//             0x1000000000000010,
//             0xef00180000f700,
//             0xeeffff6f0000
//         ],
//         army: 0,
//         castle_rights: 15,
//         en_passant: 44, // e6
//         halfmove: 0,
//         fullmove: 1,
//         has_fog: true
//     };

//     let turn = Turn { piece: Piece::PAWN, from: 35, to: 44, promotion_piece: 0 };
//     let turn_salt = 1337;

//     // An invalid turn would cause `main` to fail assertion.
//     let _ = main(
//         w1,
//         turn,
//         turn_salt,
//         0x0ce7455bc1f72a29c691ead1751bc866d7d34bf8c46a7778038ca1ddaaf362a0
//     );
// }

// TODO:
// #[test(should_fail)]
// fn invalid_turn_fails_proving() {

// }


// #[test]
// fn valid_turn_advances_game() {
//     // Precomputed commitment for these values:
//     // 0x0ce7455bc1f72a29c691ead1751bc866d7d34bf8c46a7778038ca1ddaaf362a0

//      // Starting board.
//     // let g_public = Game {
//     //     // Public start of the game, no move yet, from white's perspective.
//     //     bbs: [
//     //         0, // White isn't revealed at all.
//     //         0, // Neither is black.
//     //         0, // .'. no pieces are revealed.
//     //         0, // "
//     //         0, // "
//     //         0, // "
//     //         0, // "
//     //         0 // "
//     //     ],
//     //     army: 0,
//     //     castle_rights: 15, // TODO: Would need to blind this too...
//     //     en_passant: 0, // TODO: And this...
//     //     halfmove: 0,
//     //     fullmove: 1,
//     //     has_fog: true,
//     //     lit: [0xffffffff, 0xffffffff00000000],
//     //     lamp: 0xffff00000000ffff
//     // };

//     let g_public_first_turn_only = Game {
//         // Public start of the game, no move yet, from white's perspective.
//         bbs: [
//           0xFFFF,
//           0xFFFF000000000000,
//           0x4200000000000042,
//           0x2400000000000024,
//           0x8100000000000081,
//           0x0800000000000008,
//           0x1000000000000010,
//           0x00FF00000000FF00
//         ],
//         army: 0,
//         castle_rights: 15, // TODO: Would need to blind this too...
//         en_passant: 0, // TODO: And this...
//         halfmove: 0,
//         fullmove: 1,
//         has_fog: true,
//         lit: [0xffffffff, 0xffffffff00000000],
//         lamp: 0xffff00000000ffff
//     };

//     // Turn includes white's private bb state (or make this a seperate data structure PlayerState).
//     let turn = Turn {
//         piece: Piece::PAWN,
//         from: 11,
//         to: 27,
//         promotion_piece: 0,
//         lights: true,
//         // White's PRIVATE state. The library circuit will add state which should be revealed to the
//         //   public `Game` struct as required.
//         // TODO: What stops me lying about the following BBs here.
//         bbs: [
//             0x42,
//             0x24,
//             0x81,
//             0x8,
//             0x10,
//             0xff00
//         ]
//     };
//     let turn_salt = 1337;

//     // An invalid turn would cause `main` to fail assertion.
//     let output = main(
//         g_public_first_turn_only,
//         turn,
//         // turn_salt,
//         // 0x0ce7455bc1f72a29c691ead1751bc866d7d34bf8c46a7778038ca1ddaaf362a0
//     );
    
//     println(output);
// }
