use crate::test::util::swiss as t;

//
// BOARD SCENARIOS FOR TESTING
//

struct Scenario {
    no_fog: t::sg::SeededGame,
    with_fog: t::sg::SeededGame,
}

// Make scenario.
fn mk_s<N>(bb_defs: [t::sg::BbDef; N]) -> Scenario {
    Scenario { no_fog: t::sg::init(bb_defs), with_fog: t::sg::init_fog(bb_defs) }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// ---------------------------------------------- COMMON

global COMMON: [Scenario; 2] = [

    // ---------------- Scenario 0

    // Board with mixed pieces some capable of capturing, intended for use with fog.
    // TODO: Put bitboard render.
    mk_s([
        (t::bb::WHITE, t::bb::KNIGHT, 0x10000200000000),
        (t::bb::BLACK, t::bb::KNIGHT, 0x4000),
        (t::bb::WHITE, t::bb::BISHOP, 0x2),
        (t::bb::BLACK, t::bb::BISHOP, 0x400000000000000),
        (t::bb::WHITE, t::bb::ROOK, 0x1000000),
        (t::bb::BLACK, t::bb::ROOK, 0x80000000),
        (t::bb::WHITE, t::bb::QUEEN, 0x8),
        (t::bb::BLACK, t::bb::QUEEN, 0x800000000000000),
        (t::bb::WHITE, t::bb::KING, 0x10),
        (t::bb::BLACK, t::bb::KING, 0x1000000000000000),
        (t::bb::WHITE, t::bb::PAWN, 0x442010000),
        (t::bb::BLACK, t::bb::PAWN, 0x5420000000000),
    ]),

    // ---------------- Scenario 1

    // Board with pieces mostly in positions to be captured, including captures
    //   resulting in one side having no more of the piece in question.

    //     [RANK]                        [INDICES]

    //    8      . 56   . 57   . 58   . 59   . 60  bR 61   . 62   . 63
    //    7     bN 48  bB 49  bR 50   . 51   . 52   . 53  bB 54   . 55
    //    6     bP 40   . 41  wN 42   . 43  bK 44   . 45  bP 46   . 47
    //    5      . 32  wP 33   . 34   . 35   . 36  wP 37   . 38  bQ 39
    //    4      . 24  bN 25  wP 26  wB 27  wP 28   . 29   . 30   . 31
    //    3      . 16   . 17  wK 18   . 19   . 20   . 21   . 22   . 23
    //    2     wR  8   .  9   . 10   . 11   . 12   . 13  wR 14   . 15
    //    1      .  0   .  1   .  2  wQ  3   .  4   .  5   .  6   .  7

    //           a      b      c      d      e      f      g      h      [FILE]
    mk_s([
        (t::bb::WHITE, t::bb::KNIGHT, 0x40000000000),
        (t::bb::BLACK, t::bb::KNIGHT, 0x1000002000000),
        (t::bb::WHITE, t::bb::BISHOP, 0x8000000),
        (t::bb::BLACK, t::bb::BISHOP, 0x42000000000000),
        (t::bb::WHITE, t::bb::ROOK, 0x4100),
        (t::bb::BLACK, t::bb::ROOK, 0x2004000000000000),
        (t::bb::WHITE, t::bb::QUEEN, 0x8),
        (t::bb::BLACK, t::bb::QUEEN, 0x8000000000),
        (t::bb::WHITE, t::bb::KING, 0x40000),
        (t::bb::BLACK, t::bb::KING, 0x100000000000),
        (t::bb::WHITE, t::bb::PAWN, 0x2214000000),
        (t::bb::BLACK, t::bb::PAWN, 0x410000000000)
    ]),
];

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// ---------------------------------------------- KNIGHTS

global KNIGHT: [Scenario; 3] = [

    // ---------------- Scenario 0

    // 4 Knights in each corner: a1, a8, h8, h1.
    mk_s([(t::bb::WHITE, t::bb::KNIGHT, 0x8100000000000081)]),

    // ---------------- Scenario 1

    // 5 Knights one-move away from each other.
    mk_s([(t::bb::WHITE, t::bb::KNIGHT, 0x14000800140000)]),

    // ---------------- Scenario 2

    // Dense, lots of (and only) white pieces.
    mk_s([(t::bb::WHITE, t::bb::KNIGHT,  0x8124520008422481)]),
];
