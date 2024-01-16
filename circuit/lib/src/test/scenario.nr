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
    Scenario { no_fog: t::sg::init(0, bb_defs), with_fog: t::sg::init_fog(0, bb_defs) }
}

// ----

fn mk_s_TWO<N>(turn: u1, bb_defs: [t::sg::BbDef; N]) -> t::sg::SeededGame {
    t::sg::init(turn, bb_defs)
}

// ***************************************************************************

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

    // [RANK]                        [INDICES]

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

// ---------------------------------------------------------------------------
// ---------------------------------------------- BISHOPS

// TODO: This test scenario can go into COMMON when thats reworked to use the
//       improved t::sg::SeededGame isntead of Scenario.
global COMMON_SLIDING: [t::sg::SeededGame; 1] = [

    // ---------------- Scenario 0

    // Sliding pieces in position to capture others if only there wasn't fog
    //   in the way, i.e. none of these pieces can legally capture the intended
    //   others.
    // TODO: Board render.
    t::sg::init_fog(t::Player::WHITE, [
        (t::bb::WHITE, t::bb::BISHOP, 0x1), // To take black queen.
        (t::bb::BLACK, t::bb::BISHOP, 0x100000000000000),
        (t::bb::WHITE, t::bb::ROOK, 0x1000000001000000), // To take black rook.
        (t::bb::BLACK, t::bb::ROOK, 0x80000010),
        (t::bb::WHITE, t::bb::QUEEN, 0x80), // To take black bishop.
        (t::bb::BLACK, t::bb::QUEEN, 0x8000000000000000),
    ]),
];

// ---------------------------------------------------------------------------
// ---------------------------------------------- PAWNS

global PAWN: [t::sg::SeededGame; 4] = [

    // ---------------- Scenario 0

    // Pawns for both players on their respective starting ranks.
    mk_s_TWO(t::Player::WHITE, [
        (t::bb::WHITE, t::bb::PAWN, 0xFF00),
        (t::bb::BLACK, t::bb::PAWN, 0xFF000000000000)
    ]),

    // ---------------- Scenario 1

    // Same as scenario 0 except black's turn.
    mk_s_TWO(t::Player::BLACK, [
        (t::bb::WHITE, t::bb::PAWN, 0xFF00),
        (t::bb::BLACK, t::bb::PAWN, 0xFF000000000000)
    ]),

    // ---------------- Scenario 2

    // White en-passant capture scenario.

    // [RANK]                        [INDICES]

    //    8     bR 56  bN 57  bB 58  bQ 59  bK 60  bB 61  bN 62  bR 63
    //    7     bP 48  bP 49  bP 50  bP 51   . 52  bP 53  bP 54  bP 55
    //    6      . 40   . 41   . 42   . 43   . 44   . 45   . 46   . 47
    //    5      . 32   . 33   . 34  wP 35  bP 36   . 37   . 38   . 39
    //    4      . 24   . 25   . 26   . 27   . 28   . 29   . 30   . 31
    //    3      . 16   . 17   . 18   . 19   . 20   . 21   . 22  wP 23
    //    2     wP  8  wP  9  wP 10   . 11  wP 12  wP 13  wP 14   . 15
    //    1     wR  0  wN  1  wB  2  wQ  3  wK  4  wB  5  wN  6  wR  7

    //           a      b      c      d      e      f      g      h      [FILE]
    t::sg::init_ep(
        t::Player::WHITE,
        [
            (t::bb::WHITE, t::bb::KNIGHT, 0x42),
            (t::bb::BLACK, t::bb::KNIGHT, 0x4200000000000000),
            (t::bb::WHITE, t::bb::BISHOP, 0x24),
            (t::bb::BLACK, t::bb::BISHOP, 0x2400000000000000),
            (t::bb::WHITE, t::bb::ROOK, 0x81),
            (t::bb::BLACK, t::bb::ROOK, 0x8100000000000000),
            (t::bb::WHITE, t::bb::QUEEN, 0x8),
            (t::bb::BLACK, t::bb::QUEEN, 0x800000000000000),
            (t::bb::WHITE, t::bb::KING, 0x10),
            (t::bb::BLACK, t::bb::KING, 0x1000000000000000),
            (t::bb::WHITE, t::bb::PAWN, 0x800807700),
            (t::bb::BLACK, t::bb::PAWN, 0xEF001000000000)
        ],
        t::sq::e6 // e6 can be captured via en-passant.
    ),

    // ---------------- Scenario 3

    // Black en-passant capture scenario.

    // [RANK]                        [INDICES]

    //    8     bR 56  bN 57  bB 58  bQ 59  bK 60  bB 61  bN 62  bR 63
    //    7     bP 48   . 49   . 50   . 51   . 52   . 53   . 54   . 55
    //    6      . 40  bP 41  bP 42   . 43   . 44   . 45   . 46  bP 47
    //    5     wP 32   . 33   . 34  bP 35  bP 36  bP 37   . 38   . 39
    //    4      . 24  wP 25   . 26   . 27  wP 28   . 29  bP 30  wP 31
    //    3      . 16   . 17  wP 18  wP 19   . 20  wP 21  wP 22   . 23
    //    2      .  8   .  9   . 10   . 11   . 12   . 13   . 14   . 15
    //    1     wR  0  wN  1  wB  2  wQ  3  wK  4  wB  5  wN  6  wR  7

    //           a      b      c      d      e      f      g      h      [FILE]
    t::sg::init_ep(
        t::Player::BLACK,
        [
            (t::bb::WHITE, t::bb::KNIGHT, 0x42),
            (t::bb::BLACK, t::bb::KNIGHT, 0x4200000000000000),
            (t::bb::WHITE, t::bb::BISHOP, 0x24),
            (t::bb::BLACK, t::bb::BISHOP, 0x2400000000000000),
            (t::bb::WHITE, t::bb::ROOK, 0x81),
            (t::bb::BLACK, t::bb::ROOK, 0x8100000000000000),
            (t::bb::WHITE, t::bb::QUEEN, 0x8),
            (t::bb::BLACK, t::bb::QUEEN, 0x800000000000000),
            (t::bb::WHITE, t::bb::KING, 0x10),
            (t::bb::BLACK, t::bb::KING, 0x1000000000000000),
            (t::bb::WHITE, t::bb::PAWN, 0x1926C0000),
            (t::bb::BLACK, t::bb::PAWN, 0x1863840000000),
        ],
        t::sq::h3 // h3 can be captured via en-passant.
    ),
];
