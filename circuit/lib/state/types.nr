use dep::std::option::Option;

type Bitboard = u64;
type BitboardIndex = u8; // 6-bits required to index 64-bit bitboard.

global REQUIRED_BITBOARDS = 9;

global PIECE_OFFSET: u8 = 2;

// 6x2 bitboard board storage.

// XXX: No unit structs or enums in Noir yet. Here and elsewhere this is a poor
//   man's enum.
mod BitboardOf {
    // XXX: MUST appear in same order as mod Player.
    global WHITE: u8 = 0;
    global BLACK: u8 = 1;
    // XXX: MUST appear in same order as mod Piece.
    global KNIGHT: u8 = 2;
    global BISHOP: u8 = 3;
    global ROOK: u8 = 4;
    global QUEEN: u8 = 5;
    global KING: u8 = 6;
    global PAWN: u8 = 7;
    global FOG: u8 = 8;
}

mod Player {
    global WHITE: u1 = 0;
    global BLACK: u1 = 1;
}

// XXX [420]
//   Laid out this way (pawn last with king) as when promoting a pawn you cannot
//   promote to another pawn or a king leaving 4 possible pieces which can be
//   described with 2-bits and those selfsame pieces are in that range when
//   pawns and kings are enumerated last.
// XXX: TypeScript type of the same name is bound to this.
mod Piece {
    global KNIGHT: u8 = 0;
    global BISHOP: u8 = 1;
    global ROOK: u8 = 2;
    global QUEEN: u8 = 3;
    global KING: u8 = 4;
    global PAWN: u8 = 5;
}

// Needs it's own because u8 -> u8. Must be in the same order as Piece.
// @TEST_SUITE:BIND_PLEASE
mod Promote {
    global KNIGHT: u8 = 0;
    global BISHOP: u8 = 1;
    global ROOK: u8 = 2;
    global QUEEN: u8 = 3;
}

mod Sliding {
    global HORIZONTAL: u8 = 0;
    global VERTICAL: u8 = 1;
    global DIAGONAL: u8 = 2;
    global ANTI_DIAGONAL: u8 = 3;
}

struct Move {}

struct SpecialBbs {
    remove: Bitboard,
    summon: (Bitboard, u8),
}

struct MoveResult {
    en_passant: Option<BitboardIndex>,
    ep_capture_bb: Option<Bitboard>,
    special_bbs: SpecialBbs
}

struct Turn {
    piece: u8,
    from: BitboardIndex,
    to: BitboardIndex,
    promotion_piece: u8
}

struct Game {
    // Square positions accessed in LERLEF order.
    bbs: [Bitboard; REQUIRED_BITBOARDS],
    army: u1,
    castle_rights: u8,
    en_passant: BitboardIndex,
    halfmove: Field,
    fullmove: Field,
    // Realistically this will always be true however current bitboard-based
    //   fog computation is very slow, this field exists purely to speed up
    //   tests. I hate it but yadda yadda rewrite into arrays.
    has_fog: bool
}

// TOOD: Put SHIFTED_ANTI_DIAGONAL and other such constants here.

// TODO: When traits are no longer experimental have `validate` done that way.
// trait Validateable {
//     fn validate(slf: Self);
// }
