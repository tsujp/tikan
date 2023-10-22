use dep::std::println;

use dep::state::board::Board;

// type Char = u8;
// mod ns;

#[test]
fn test_valid_input_gamestate() {
    println(f"t-0x69"); // Fix nargo missing newline and reset test scope.

    // TODO: On turn 1 hardcode valid starting position bitboard serialisation
    //       state (because we're not a generic engine).

    // Minimum valid starting board.
    //   * FEN: `4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1`
    // let b1 = Board::from_serial([
    //     0xff10,
    //     0x10ff000000000000,
    //     0x00ff00000000ff00,
    //     0x00,
    //     0x00,
    //     0x00,
    //     0x00,
    //     0x1000000000000010,
    //     0x0,
    //     0x0000,
    //     0x0,
    //     0x0,
    //     0x1
    // ]);

    // Proper starting board.
    //   * FEN: `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`
    let b2 = Board::from_serial(
        [
            0xffff, // White board
            0xffff000000000000, // Black board
            0x00ff00000000ff00, // Pawns
            0x4200000000000042, // Knights
            0x2400000000000024, // Bishops
            0x8100000000000081, // Rooks
            0x0800000000000008, // Queens
            0x1000000000000010 // Kings
        ],
        0, // Current army's turn (Board::Piece enum index 0 = white, 1 = black)
        0x1111, // Bitmask castle rights K Q k q, 1 = can, 0 = cannot
        0, // En-passant target square index (LERLEF index, 6-bits),
        0, // Halfmove count
        1 // Fullmove count
    );

    // TODO: Can board validation come from previous proof?
    // TODO: Within `Board` is has validated that board state
    //       is not illegal, now we can apply a maybe illegal
    //       move. If illegal then fail an assert.

    // Legal move (white's turn, as b2 specifies current army's turn).
    let wat = b2.apply_move(
        3, // knight (piece ID of 3)
        6, // g1
        21, // f3
        0, // no capture
        0 // no promotion
    );

    // 0x200000, // f3
    // Illegal move.
    // 0x800, // d2

    // A move encoded as array of 5 required fields:
        // Piece ID: 3-bits,          (Board::Piece enum)
        // From square: 64-bits,      (LERLEF)
        // To square: 64-bits,        (LERLEF)
        // Capture: 1-bit,            (0 false, 1 true)
        // Promotion piece: 3-bits,   (Board::Piece enum)
    

    // let xyz = Board::new();

    // println(f"t-0x69"); // Fix nargo missing newline and reset test scope.

    // Removing pawns should remove them as-by BERLEF indexing. So, here on the
    //   second rank first 3 pawns should be missing with the bitboard for
    //   those pawns missing the BERLEF-indexed 1s. The 7th rank is also
    //   altered, and so should miss the last 4 BERLEF-indexed 1s.
    // check_bb_from_fen(
    //     stb_parse_fen("4k3/3ppppp/8/8/8/8/PPPP4/4K3 w - - 0 1"),
    //     [
    //         0xf008,
    //         0x081f000000000000,
    //         0x001f00000000f000,
    //         0x00,
    //         0x00,
    //         0x00,
    //         0x00,
    //         0x0800000000000008
    //     ]
    // );

    // println(f"t-0x69"); // Fix nargo missing newline and reset test scope.
    // And after the move 1. e4:
    // rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1

    // And then after 1. ... c5:
    // rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2

    // And then after 2. Nf3:
    // rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2

    // Various FEN strings taken from: https://ia902908.us.archive.org/26/items/pgn-standard-1994-03-12/PGN_standard_1994-03-12.txt
    // 4k3/8/8/8/8/8/4P3/4K3 w - - 5 39 

    // XXX: Not necessarily the case.
    // TODO: Add failure output and detection (to say failed test suite overall)
    //       in the conversions script.
    assert(true);
}














// TODO: Does the compiler remove println statements when compiled properly or
//       do they remain? If the latter pipe through awk to remove lines with
//       println before passing to Nargo for compilation.

// Mailbox representations require signed integers.
// Bitboard represents do not require signed integers.
// Want maximum _lack_ of third-party dependency (stdlib only).

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

// Test helper to dump board state as bitfields which can be trivially
//   serialised by a simple web frontend to visually show board state. This
//   is being done instead of printing to stdout as with many tests such a
//   long output will be tedious to explore.
// This isn't on the Board struct since it's a _test_ helper not an
//   implementation detail.
// fn dump_board(b: Board) -> () {
//     let _ = b; // To temp silence unused var message.
//     println(f"dump board called\n");
//     // for bb in b.pieces {
//     //     let d = bb.data;
//     //     println(f"k{d}");
//     // };
// }


// XXX: Test-helper only.
// TODO: Noir doesn't allow template strings in assertion messages and also
//       does not print if an assertion fails and also assertions do not
//       display the actual values, only that it failed (arguably useless)
//       so this convoluted workaround is employed.
// fn check_bb_from_fen(board: Board, check_bbs: [u64; 8]) {
//     let mut idx = 0;

//     for bb in board.pieces {
//         // FIXME: No expressions in template strings so pollution with temp
//         //        values is required.
//         let bb_data = bb.data;
//         let check_bb = check_bbs[idx];

//         if bb_data == check_bb {
//             println(f"t-0x01");
//         } else {
//             println(f"t-0x00 Expected equal values, '{bb_data}' == '{check_bb}' (given) bb index: u-{idx}");
//         }

//         idx += 1;
//     }
// }



// TODO: Simple higher order function which takes a lambda to run stuff
//       and wraps that lambda in `println(f"t-0x69"); lambda; assert(true);`


// Circuit should take input as current board (which both players accept as correct) and 
//   a private witness move. The resulting circuit output is the new FEN board state
//   and the private witness move which, if doing a move in fog, is blinded by a
//   Pedersen hash state-commitment; else the private witness move is made public as
//   it does not contain sensitive information.
// Example: Input `FEN ; SAN` ... Output `NEW_FEN ; [ SAN_BLINDED | SAN ]`
// fn assert_valid_move(before_board: [u32; 4], after_board: [u32; 4], move: u32) {
//     // Hardcoded +1 value, i.e. a "move" here is adding 1 and only 1 to some number
//     //   in the board, adding nothing or adding 2 or -1 etc is invalid!

//     // TODO: Check `move` can index before and after board
    
//     // let applied_board = {
//     //     before_board[move] += 1;
//     //     before_board
//     // };

//     let mut applied_board = before_board;
//     applied_board[move] += 1;

//     assert(applied_board == after_board);
// }

