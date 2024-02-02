use dep::std::println;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Turn, Game, Piece};

fn main(game: Game, turn: Turn, turn_salt: Field) -> pub Field {
    let game_hash = pedersen_commitment(game.decompose()).x;
    let turn_hash = pedersen_commitment(turn.decompose()).x;

    let computed_commitment = pedersen_commitment([game_hash, turn_hash, turn_salt]).x;

    computed_commitment
}


// OPT: Doing this per piece and requiring `game` must be slow eh? Speedup and/or protocol change
//      later after lights work.
// XXX: Regarding above OPT; only have to do the commitment for the moved piece no if we pre-generate
//      what the starting board scenarios look like for players ahead of time?
// XXX: `game` here has to be the _public_ gamestate otherwise when the opponent tries to
//      verify the commitment it will fail unless white reveals more private state which defeats
//      the point.
// fn commit_piece(game: Game, piece: u3, idx: u6) -> pub Field {

// }

// #[test]
// fn  test_commit_piece {
//     // When white moves they commit against this public state.
//     let w_public = Game {
//         // Public start of the game, no move yet, from white's perspective.
//         bbs: [
//             0, // White isn't revealed at all.
//             0, // Neither is black.
//             0, // .'. no pieces are revealed.
//             0, // "
//             0, // "
//             0, // "
//             0, // "
//             0, // "
//             // fog is like 'anti fog' so 64-1s is all squares illuminated.
//             0xffffffffffffffff
//         ],
//         army: 0,
//         castle_rights: 15, // TODO: Would need to blind this too...
//         en_passant: 0, // TODO: And this...
//         halfmove: 0,
//         fullmove: 1,
//         has_fog: true
//     };

//     let w_private = Game {
//         // Private start of the game for white.
//         bbs: [
//             0xffff, // White knows where they are.
//             0, // They do not know where black is since this is also 0 in the public game.
//             0x42, // All the pieces here would .'. only be whites.
//             0x24, // "
//             0x81, // "
//             0x10, // "
//             0x8, // "
//             0xff00, // "
//             // fog is like 'anti fog' so 64-1s is all squares illuminated.
//             0xffffffffffffffff
//         ],
//         army: 0,
//         castle_rights: 15, // TODO: Would need to blind this too...
//         en_passant: 0, // TODO: And this...
//         halfmove: 0,
//         fullmove: 1,
//         has_fog: true
//     }
// }

#[test]
fn example_move_commitment() {
    let w1 = Game {
        bbs: [
            0x080000f7ff,
            0xffef001000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xef00180000f700,
            0xeeffff6f0000
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 44, // e6
        halfmove: 0,
        fullmove: 1,
        has_fog: true
    };

    // From white performs en passant capture ep1 w1
    let move = Turn { piece: Piece::PAWN, from: 35, to: 44, promotion_piece: 0 };

    let move_salt = 1337;

    let mc = main(w1, move, move_salt);
    println(mc);
}

// #[test]
// fn black_initiate_commitment() {
//     let move_salt = 0;
//     let mc = pedersen_commitment([0, 0, 0]);
//     println(mc);
// }

// struct PieceCommitment {
//     // TODO: Ye olde constrain on 0 - 5 as is required elsewhere for types.nr::Piece.
//     piece: u3,
//     // TODO: From u6 to BitboardIndex (which is a u6 so same thing).
//     idx: u6
// }
