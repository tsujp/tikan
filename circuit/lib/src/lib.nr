use dep::std::println;
use dep::std::collections::vec::Vec;
// use dep::std::unsafe::zeroed;
use dep::std::option::Option;

type Char = u8;

use dep::fen::parser::parse_fen;
use dep::fen::types::REQUIRED_LENGTH;

use dep::state::board::Board;

// TODO: Does the compiler remove println statements when compiled properly or
//       do they remain? If the latter pipe through awk to remove lines with
//       println before passing to Nargo for compilation.

// Mailbox representations require signed integers.
// Bitboard represents do not require signed integers.
// Want maximum _lack_ of third-party dependency (stdlib only).

// struct FenDynamic {
//     // - - - - Pieces.
//     // - - En passant.
//     en_passant: [Char; 2],
//     // - - - - Turns.
//     // - - Halfmove, fullmove counters.
//     halfmove: u16, // 16 bits is 65k moves, match _probably_ won't go that long.
//     fullmove: u16,
// }


// Bitboard:
//   - 2 colour bitboards; white and black with all their pieces.
//   - 6 piece colour-agnostic bitboards; e.g. both white and black's pawns in a
//     single pawn bitboard.
//
// To calculate only black's pawns bitwise AND black's bitboard and the pawn
//   bitboard.

// Using both a bitboard and mailbox as a bitboard can provide fast masks for
//   fog and piece exchange (capture) after a move is deemed legal.


// Mailbox:
//   TODO: This for move verification.

// Using mailbox for easier move verification; doing so with bitboards would
//   require trickery (albeit well documented on ChessProgramming.org) that
//   currently is less intuitive. So: use that which you currently understand
//   so you're able to debug and solve problems.

// -------------------

// Only pawns and one king each:
// 4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1

// Normal starting fen:
// rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

// Lazy helper for tests to avoid typing `as_bytes()` everywhere. Hopefully
//   this is recognised by Nargo as unused in non-test code and erased from
//   compiled ACIR (TODO: Check that) but this is tiny and a one-off in the
//   event it is not. String-to-bytes => stb.
// OPT: Will this be statically removed by the compiler since it's only used by
//      functions annotated with `#[test]`?
// TODO: Is there a nice way to make this functions return type generic from
//       the calee's `parse_fen` (currently u64). Higher order functions look
//       like they still require explicit return types; only their parameters
//       (and in the case of closures) can be generic (I think).
fn stb_parse_fen<T, N>(input_fen: str<N>) -> Board {
    parse_fen(input_fen.as_bytes())
}

#[test]
fn test_parse_fen() {
    println("Bitboard value:");
    let foo = stb_parse_fen("4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
    println("-------");

    assert(0 == 0);
}

fn assert_valid_move(before_board: [u32; 4], after_board: [u32; 4], move: u32) {
    // Hardcoded +1 value, i.e. a "move" here is adding 1 and only 1 to some number
    //   in the board, adding nothing or adding 2 or -1 etc is invalid!

    // TODO: Check `move` can index before and after board
    
    // let applied_board = {
    //     before_board[move] += 1;
    //     before_board
    // };

    let mut applied_board = before_board;
    applied_board[move] += 1;

    assert(applied_board == after_board);
}
