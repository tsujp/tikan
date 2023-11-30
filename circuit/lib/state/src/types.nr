type Bitboard = u64;
type BitboardIndex = u6; // 6-bits required to index 64-bit bitboard.

global REQUIRED_BITBOARDS: Field = 8;

// 6x2 bitboard board storage.

// XXX: No unit structs or enums in Noir yet. Here and elsewhere this is a poor
//   man's enum.
mod BitboardOf {
    // XXX: MUST appear in same order as mod Player.
    global WHITE: u3 = 0;
    global BLACK: u3 = 1;
    // XXX: MUST appear in same order as mod Piece.
    global KNIGHT: u3 = 2;
    global BISHOP: u3 = 3;
    global ROOK: u3 = 4;
    global QUEEN: u3 = 5;
    global KING: u3 = 6;
    global PAWN: u3 = 7;
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
mod Piece {
    global KNIGHT: u3 = 0;
    global BISHOP: u3 = 1;
    global ROOK: u3 = 2;
    global QUEEN: u3 = 3;
    global KING: u3 = 4;
    global PAWN: u3 = 5;
}

mod SlidingDirection {
    global HORIZONTAL: u3 = 0;
    global VERTICAL: u3 = 1;
    global DIAGONAL: u3 = 2;
    global ANTI_DIAGONAL: u3 = 3;
}

struct Move {}

struct Turn {
    piece: u3,
    from: BitboardIndex,
    to: BitboardIndex,
    promotion_piece: u2
}

struct Game {
    // Square positions accessed in LERLEF order.
    bbs: [Bitboard; REQUIRED_BITBOARDS],
    army: u1,
    castle_rights: u4,
    en_passant: BitboardIndex,
    halfmove: Field,
    fullmove: Field
}

// TOOD: Put SHIFTED_ANTI_DIAGONAL and other such constants here.

// TODO: When traits are no longer experimental have `validate` done that way.
// trait Validateable {
//     fn validate(slf: Self);
// }
