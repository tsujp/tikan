use dep::std::println;
use dep::std::collections::vec::Vec;
// use dep::std::unsafe::zeroed;
use dep::std::option::Option;

type Char = u8;

use dep::fen::parser::parse_fen;
use dep::fen::types as Tipe;
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

// #[test]
// fn test_of_pieces() {
//     // let t_1 = of_pieces(Tipe::CORPUS.pawn, Tipe::CORPUS.w_pawn);
//     // // assert(t_1.unwrap().0 == 0);
//     // assert_eq(t_1.unwrap().0, 1);

//     // let t_2 = of_pieces(Tipe::CORPUS.pawn, 0x00);
//     // // assert(t_2.is_some(), "NUL byte is not a valid FEN piece character");
//     // assert(t_2.is_some() == true);

//     // if t_1.is_some() {
//     //     let (plyr_idx, the_p): (u8, u8) = t_1.unwrap();
//     //     assert(plyr_idx == 0);
//     // }
// }

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
// fn stb_parse_fen<T, N>(input_fen: str<N>) -> () {
//     println(f""); // Fix for missing newline from default Nargo stdout.
//     let board = parse_fen(input_fen.as_bytes());
//     dump_board(board); // TODO: Uncomment later.
// }

fn stb_parse_fen<T, N>(input_fen: str<N>) -> Board {
    parse_fen(input_fen.as_bytes())
}


// Test helper to dump board state as bitfields which can be trivially
//   serialised by a simple web frontend to visually show board state. This
//   is being done instead of printing to stdout as with many tests such a
//   long output will be tedious to explore.
// This isn't on the Board struct since it's a _test_ helper not an
//   implementation detail.
fn dump_board(b: Board) -> () {
    println(f"dump board called\n");

    // println("=========== With original");
    // println(f"u0x22"); // Dec 34
    // println(f"u0x3a"); // Dec 58

    // println("=========== With original");
    // println(f"c0x22"); // Dec 34
    // println(f"c0x3a"); // Dec 58

    // println("=========== Without original");
    // println(f"c-0x22"); // Dec 34
    // println(f"c-0x3a"); // Dec 58
    
    // println("========== Without original");
    // println(f"u-0x22");
    // println(f"u-0x3a");

    
    println("========== With original");
    // println(f"k0xff00ff k0xabcabc");

    println("========== Without original");
    println(f"k-0xCAFE001 k-0xff00ff k-0xaabbcc k-0x123123");
    println(f"k-0xCAFE002 k-0xff00ff");
    println(f"k-0xCAFE003 k-0xaabbcc");

    // println("========= Without original");
    // println(f"k-0xff00ff");
    
    // for bb in b.pieces {
    //     let d = bb.data;
    //     println(f"k{d}");
    // };
}


// XXX: Test-helper only.
fn check_bb_from_fen(board: Board, check_bbs: [u64; 6]) {
    for bb in board.pieces {
        println(f"foo {bb}");
    }
}


#[test]
fn test_parse_fen() {
    println(f""); // Fix for missing newline from default Nargo stdout.
    // Minimum valid FEN board.
    let board = stb_parse_fen("4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
    check_bb_from_fen(board, [
        0xff00000000ff00,
        0x00,
        0x00,
        0x00,
        0x00,
        0xff00000000ff00
    ]);
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
