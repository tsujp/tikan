// FEN: Forsyth–Edwards Notation
//   - Online: https://www.chessprogramming.org/Forsyth-Edwards_Notation
//
//   `{Pieces} / {Turn} / {Castling} / {En passant} / {Halfmove} / {Fullmove}`
//
//   - In-situ each segment is seperated by a forward slash surrounded by a
//     space on both sides. Segments are informally hinted at above enclosed
//     in braces with the entire structure enclosed in backticks. Note that
//     the braces and backticks are not part of the FEN string in-situ.
//
//   * For {Pieces} - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//   - Each piece a single letter:
//       * Pawn   = P
//       * Knight = N
//       * Bishop = B
//       * Rook   = R
//       * Queen  = Q
//       * King   = K
//   - Described "top-left" to "bottom-right" from rank a8 to h1 (rank, file).
//   - White pieces in uppercase, black pieces in lowercase.
//   - If no pieces are present along a rank (row) a number (1-8) is given to
//     indicate the count of successive empty squares.
//
//   * For {Turn} - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//   - "w" means white to move, "b" means black to move.
//
//   * For {Castling} - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//   - Describes castle rights on "queen-side" and "king-side" with K and Q.
//       e.g. at the start of a game KQkq is the value, both sides have the
//            right to castle. If white moves their king-side rook the string
//            is now Qkq (K is absent as castle rights on king-side are gone).
//   - Casing the same as pieces.
//   - If neither side has castle rights empty value hyphen `-` is used.
//
//   * For {En passant} - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//   - Target square in algebraic notation (e.g. e3) where an en passant capture
//     can occur (IFF such a move can be legally made).
//   - If no en passant capture possibility empty value hyphen `-` is used.
//   - NB: Updated FEN spec only populates this field if such a move can be
//         legally made however this serves no purpose for us (we're not a
//         chess engine generating moves).
//   TODO: This leaks information if moved in fog, Pedersen it?
//
//   * For {Halfmove} - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//   - Count of full moves (i.e. one white and one black) since the last pawn
//     advance, or piece capture.
//   - When 100 (50 moves for each player) a draw can be claimed by the player
//     whose turn it is (see: fifty-move rule).
//   TODO: This will leak information in fog of war if moving a pawn in the
//         fog so either use Pedersen's homomorphic property to increment
//         when neccersary (with a salt value) or do away with it.
//
//   * For {Fullmove} - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//   - Count of full moves (i.e. one white and one black).
//   - Starts at 1 and is incremented after black's move.

// Compile-time (inlined maybe) constant.
// TODO: This will be longer when Pedersen hashes are on the end for state commitments.
global REQUIRED_LENGTH: u32 = 87;

// TODO: Replace `str` with `[u8; MAX_LENGTH];`
// type Fen = str<REQUIRED_LENGTH>;
type Char = u8;
type Chars<N> = [Char; N];
type Fen = Chars<REQUIRED_LENGTH>;


struct Corpus {
    // u8 for characters as that is their backing datatype in Noir.
    //
    // - - - - Pieces.
    // - - Pawns.
    w_pawn: Char,
    b_pawn: Char,
    pawn: Chars<2>,
    // - - Knights.
    w_knight: Char,
    b_knight: Char,
    knight: Chars<2>,
    // - - Bishops.
    w_bishop: Char,
    b_bishop: Char,
    bishop: Chars<2>,
    // - - Rooks.
    w_rook: Char,
    b_rook: Char,
    rook: Chars<2>,
    // - - Queens.
    w_queen: Char,
    b_queen: Char,
    queen: Chars<2>,
    // - - Kings.
    w_king: Char,
    b_king: Char,
    king: Chars<2>,
    // - - Successive empty squares (in rank).
    // TODO: [OPT] Slice and .any() instead for 1-8? Compare circuit gate sizing.
    empty_n: Chars<8>,
    // - - - - Grammar.
    // - - Empty segment value.
    empty_value: Char,
    // - - Punctuation.
    rank_delimit: Char,
    segment_delimit: Char,
}

// Compile-time (inlined maybe) constant.
global CORPUS = Corpus {
    w_pawn: 0x50,
    b_pawn: 0x70,
    pawn: [0x50, 0x70],

    w_knight: 0x4e,
    b_knight: 0x6e,
    knight: [0x4e, 0x6e],

    w_bishop: 0x42,
    b_bishop: 0x62,
    bishop: [0x42, 0x62],

    w_rook: 0x52,
    b_rook: 0x72,
    rook: [0x52, 0x72],

    w_queen: 0x51,
    b_queen: 0x71,
    queen: [0x51, 0x71],

    w_king: 0x4b,
    b_king: 0x6b,
    king: [0x4b, 0x6b],

    empty_n: [
        0x31,
        0x32,
        0x33,
        0x34,
        0x35,
        0x36,
        0x37,
        0x38,
    ],

    empty_value: 0x2d,
    rank_delimit: 0x2f,
    segment_delimit: 0x20,
};

// This feels dirty but having a nice way to associate a piece with its
//   proper index on deserialisation is key.
global PIECE_SEARCH_ORDER = [
    CORPUS.pawn,
    CORPUS.knight,
    CORPUS.bishop,
    CORPUS.rook,
    CORPUS.queen,
    CORPUS.king,
];
