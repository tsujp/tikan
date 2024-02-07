
#[test(should_fail_with = "PAWN move is INVALID")]
fn test_pwn_pushes_illegal() {
    // Normal starting board; white's turn.
    let w1 = Game {
        bbs: [
            0xffff,// White board
            0xffff000000000000,// Black board
            0x4200000000000042,// Knights
            0x2400000000000024,// Bishops
            0x8100000000000081,// Rooks
            0x0800000000000008,// Queens
            0x1000000000000010,// Kings
            0x00ff00000000ff00// Pawns
        ],
        army: 0, // Current army's turn (Game::Piece enum index)
        castle_rights: 15, // Bitmask castle rights K Q k q, 1 = yes, 0 = no
        en_passant: 0, // En-passant target square index (LERLEF 6-bits)
        halfmove: 0, // Halfmove count
        fullmove: 1 // Fullmove count
    };
    // White triple push.
    let _ = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 14, // g2
        to: 38, // g5
        promotion_piece: 0
    }
    );
    // Diagonal push when not capturing.
    let _ = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 14, // g2
        to: 21, // f3
        promotion_piece: 0
    }
    );
    // TODO: File a bug report, if a scenario fails with the expected assertion message but then another scenario fails with a different assertion message the #[test] still passes even though it should fail. Are #[test]s only meant to ever handle a single assert? So now need to use a different test function to avoid this.
    // TODO: Test scenario for occupied square blocking a pawn.
    // let w2 = Game {
    //     bbs: [
    //         0x0800f7ff,
    //         0xfff7000800000000,
    //         0x4200000000000042,
    //         0x2400000000000024,
    //         0x8100000000000081,
    //         0x0800000000000008,
    //         0x1000000000000010,
    //         0xf700080800f700
    //     ],
    //     army: 0,
    //     castle_rights: 15,
    //     en_passant: 0,
    //     halfmove: 0,
    //     fullmove: 1
    // };
    // TODO: i.e. this silently "works" but it's actually failing with "Given army does NOT have a piece at expected LERLEF index"
    // let pp3 = w2.apply(
    //     Turn {
    //       piece: Piece::PAWN,
    //       from: 28, // because white has no pawn at this index
    //       to: 35,
    //       promotion_piece: 0
    //     }
    // );
}

#[test(should_fail_with = "PAWN move is INVALID")]
fn test_pwn_pushes_blocked() {
    // Game where white and black's d-file pawns are head-to-head.
    let w1 = Game {
        bbs: [
            0x0800f7ff,
            0xfff7000800000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xf700080800f700
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };
    // White attempts to push pawn forward 'into' black's pawn.
    let _ = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 27, // d4
        to: 35, // d5
        promotion_piece: 0
    }
    );

    // Game where white and black's d-file pawns are head-to-head.
    let b1 = Game {
        bbs: [
            0x0800f7ff,
            0xfff7000800000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xf700080800f700
        ],
        army: 1,
        castle_rights: 15,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };
    // Black attempts to push pawn forward 'into' white's pawn.
    let _ = b1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 35, // d5
        to: 27, // d4
        promotion_piece: 0
    }
    );

    // Game where white has pawns that block some of black's double-pushing.
    let b2 = Game {
        bbs: [
            0x204000009fff,
            0xffff000000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xff204000009f00
        ],
        army: 1,
        castle_rights: 15,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };
    // Black attempts to double push and 'skip over' a white pawn.
    let _ = b2.apply(
        Turn {
        piece: Piece::PAWN,
        from: 53, // f7
        to: 37, // f5
        promotion_piece: 0
    }
    );
    // Black attempts to push pawn forward 'into' white's pawn.
    let _ = b2.apply(
        Turn {
        piece: Piece::PAWN,
        from: 53, // f7
        to: 45, // f6
        promotion_piece: 0
    }
    );
    // Black attempts to double push pawn forward 'into' white's pawn.
    let _ = b2.apply(
        Turn {
        piece: Piece::PAWN,
        from: 54, // g7
        to: 38, // g5
        promotion_piece: 0
    }
    );
}

// TODO: tests that check en passant index is set correctly after a double push.

#[test]
fn test_en_passant_captures() {
    // Game where white can perform en-passant.
    let w1 = Game {
        bbs: [
            0x080000f7ff,
            0xffef001000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xef00180000f700
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 44, // e6
        halfmove: 0,
        fullmove: 1
    };
    // White performs en passant capture.
    let ep1 = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 35, // d5
        to: 44, // e6
        promotion_piece: 0
    }
    );
    dump_gamestate(0xE001, ep1);
    assert_bbs(
        ep1,
        [
        0x10000000f7ff,
        0xffef000000000000,
        0x4200000000000042,
        0x2400000000000024,
        0x8100000000000081,
        0x0800000000000008,
        0x1000000000000010,
        0xef10000000f700
    ]
    );

    // Game where black can perform en-passant.
    let b1 = Game {
        bbs: [
            0x2000dfff,
            0xffbf000040000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xbf00006000df00
        ],
        army: 1,
        castle_rights: 15,
        en_passant: 21, // f3
        halfmove: 0,
        fullmove: 1
    };
    // Black performs en passant capture.
    let ep2 = b1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 30, // g4
        to: 21, // f3
        promotion_piece: 0
    }
    );
    dump_gamestate(0xE002, ep2);
    assert_bbs(
        ep2,
        [
        0xdfff,
        0xffbf000000200000,
        0x4200000000000042,
        0x2400000000000024,
        0x8100000000000081,
        0x0800000000000008,
        0x1000000000000010,
        0xbf00000020df00
    ]
    );
    // TODO: Test scenarios with en passant at the edges of the board.
}

//
#[test]
fn test_pwn_pushes() {
    let w1 = Game {
        bbs: [
            0xffff,
            0xffff000000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0x00ff00000000ff00
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    // TODO: More pawn push test cases.

    // White double push.
    let pp1 = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 14, // g2
        to: 30, // g4
        promotion_piece: 0
    }
    );
    dump_gamestate(0x01, pp1);
    assert_bbs(
        pp1,
        [
        0x4000bfff,
        0xffff000000000000,
        0x4200000000000042,
        0x2400000000000024,
        0x8100000000000081,
        0x0800000000000008,
        0x1000000000000010,
        0xff00004000bf00
    ]
    );

    // White single push.
    let pp2 = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 14, // g2
        to: 22, // g3
        promotion_piece: 0
    }
    );
    dump_gamestate(0x02, pp2);
    assert_bbs(
        pp2,
        [
        0x40bfff,
        0xffff000000000000,
        0x4200000000000042,
        0x2400000000000024,
        0x8100000000000081,
        0x0800000000000008,
        0x1000000000000010,
        0xff00000040bf00
    ]
    );

    // White single push.
    let pp3 = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 9, // b2
        to: 25, // b4
        promotion_piece: 0
    }
    );
    dump_gamestate(0x03, pp3);
    assert_bbs(
        pp3,
        [
        0x0200fdff,
        0xffff000000000000,
        0x4200000000000042,
        0x2400000000000024,
        0x8100000000000081,
        0x0800000000000008,
        0x1000000000000010,
        0xff00000200fd00
    ]
    );

    // White single push.
    let pp4 = w1.apply(
        Turn {
        piece: Piece::PAWN,
        from: 9, // b2
        to: 17, // b3
        promotion_piece: 0
    }
    );
    dump_gamestate(0x04, pp4);
    assert_bbs(
        pp4,
        [
        0x02fdff,
        0xffff000000000000,
        0x4200000000000042,
        0x2400000000000024,
        0x8100000000000081,
        0x0800000000000008,
        0x1000000000000010,
        0xff00000002fd00
    ]
    );
}

// #[test]
fn test_valid_input_gamestate() {
    println(f"");
    // println(f"t-0x69"); // Fix nargo missing newline and reset test scope.

    // TODO: On turn 1 hardcode valid starting position bitboard serialisation
    //       state (because we're not a generic engine).

    // TODO: In future any overflow input will be checked when used in-code,
    //       until then we do nothing since when used externally input is
    //       checked as expected. Tracked via #3227.

    // Minimum valid starting board.
    //   * FEN: `4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1`
    // let b1 = Game::from_serial([
    //     0xff10,
    //     0x10ff000000000000,
    //     0x00,
    //     0x00,
    //     0x00,
    //     0x00,
    //     0x1000000000000010,
    //     0x00ff00000000ff00,
    //     0x0,
    //     0x0000,
    //     0x0,
    //     0x0,
    //     0x1
    // ]);

    // Proper starting board.
    //   * FEN: `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`
    let b = Game {
        bbs: [
            0xffff,// White board
            0xffff000000000000,// Black board
            0x4200000000000042,// Knights
            0x2400000000000024,// Bishops
            0x8100000000000081,// Rooks
            0x0800000000000008,// Queens
            0x1000000000000010,// Kings
            0x00ff00000000ff00// Pawns
        ],
        army: 0, // Current army's turn (Game::Piece enum index 0 = white, 1 = black)
        castle_rights: 0x1111, // Bitmask castle rights K Q k q, 1 = can, 0 = cannot
        en_passant: 0, // En-passant target square index (LERLEF index, 6-bits),
        halfmove: 0, // Halfmove count
        fullmove: 1 // Fullmove count
    };

    // TODO: Can board validation come from previous proof?
    // TODO: Within `Game` is has validated that board state
    //       is not illegal, now we can apply a maybe illegal
    //       move. If illegal then fail an assert.

    // Knight.
    let b_k1 = b.apply(
        Turn {
        piece: Piece::KNIGHT,
        from: 6, // g1
        to: 21, // f3
        promotion_piece: 0 // No promotion (implicitly knight though).
    }
    );
    // println(f"t-0x01");
    dump_gamestate(0x01, b_k1);

    // Pawn double push from start allowed.
    let b_p2 = b.apply(
        Turn {
        piece: Piece::PAWN,
        from: 9, // b2
        to: 25, // b4
        promotion_piece: 0
    }
    );
    // println(f"t-0x01");
    dump_gamestate(0x02, b_p2);

    // Pawn single push from start allowed.
    let b_p1 = b.apply(
        Turn {
        piece: Piece::PAWN,
        from: 9, // b2
        to: 17, // b3
        promotion_piece: 0
    }
    );
    // println(f"t-0x01");
    dump_gamestate(0x03, b_p1);
    // tw(|| {
    //     let b_p1 = b.apply(
    //         Turn {
    //             piece: Piece::PAWN,
    //             from: 9, // b2
    //             to: 17, // b3
    //             promotion_piece: 0
    //         }
    //     );
    //     println(f"t-0x01");
    //     dump_gamestate(0x03, b_p1);
    // })
    // 0x200000, // f3
    // Illegal move.
    // 0x800, // d2
    // A move encoded as array of 5 required fields:
    // Piece ID: 3-bits,          (Game::Piece enum)
    // From square: 64-bits,      (LERLEF)
    // To square: 64-bits,        (LERLEF)
    // Capture: 1-bit,            (0 false, 1 true)
    // Promotion piece: 3-bits,   (Game::Piece enum)
    // let xyz = Game::new();
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
    // assert(true);
}

// TODO: Does the compiler remove println statements when compiled properly or
//       do they remain? If the latter pipe through awk to remove lines with
//       println before passing to Nargo for compilation.

// Bitboard:
//   - 2 colour bitboards; white and black with all their pieces.
//   - 6 piece colour-agnostic bitboards; e.g. both white and black's pawns in a
//     single pawn bitboard.
//
// To calculate only black's pawns bitwise AND black's bitboard and the pawn
//   bitboard.

// Test helper to dump board state as bitfields which can be trivially
//   serialised by a simple web frontend to visually show board state. This
//   is being done instead of printing to stdout as with many tests such a
//   long output will be tedious to explore.
// This isn't on the Game struct since it's a _test_ helper not an
//   implementation detail.
fn dump_gamestate(t: Field, b: Game) -> () {
    let tag = t;

    let b0 = b.bbs[0];
    let b1 = b.bbs[1];
    let b2 = b.bbs[2];
    let b3 = b.bbs[3];
    let b4 = b.bbs[4];
    let b5 = b.bbs[5];
    let b6 = b.bbs[6];
    let b7 = b.bbs[7];

    // It needs to be on one line of output for our little helper script to nab.
    println(f"k-{tag} k-{b0} k-{b1} k-{b2} k-{b3} k-{b4} k-{b5} k-{b6} k-{b7}");

    // Plus horrible hack k-0x0 to prevent spamming bitboard server.
    println(f"k-0x0");
}

// Test helper. As there are no template assertion strings we
//   manually assert each bitboard index so we can have a specific
//   index in the assertion message which is used in testing.
fn assert_bbs(real: Game, checks: [u64; 8]) {
    assert(real.bbs[0] == checks[0], "WHITE bitboards do not match");

    assert(real.bbs[1] == checks[1], "BLACK bitboards do not match");

    assert(real.bbs[2] == checks[2], "KNIGHT bitboards do not match");

    assert(real.bbs[3] == checks[3], "BISHOP bitboards do not match");

    assert(real.bbs[4] == checks[4], "ROOK bitboards do not match");

    assert(real.bbs[5] == checks[5], "QUEEN bitboards do not match");

    assert(real.bbs[6] == checks[6], "KING bitboards do not match");

    assert(real.bbs[7] == checks[7], "PAWN bitboards do not match");
}

// TODO: Simple higher order function which takes a lambda to run stuff
//       and wraps that lambda in `println(f"t-0x69"); lambda; assert(true);`

// `tw` = `T`est `W`rap.
fn tw<Env>(test: fn[Env]() -> ()) {
    println("before");

    test();

    println("after");
}
