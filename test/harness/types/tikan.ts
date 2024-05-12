import type { HexInt } from '#test/harness/types'

// Tikan library types.nr Piece mod (poor man's enum in Noir).
export const Piece = {
    KNIGHT: 0,
    BISHOP: 1,
    ROOK: 2,
    QUEEN: 3,
    KING: 4,
    PAWN: 5,
} as const

// TODO: Circuilt build step parses output json ABI and puts the type here (optimisation), for now manually doing this is more than fine.

// Tikan library game.nr struct.
export type Game = {
    bbs: [HexInt, 8]
    // bbs: [HexIntLiteral<string>, 8]
    army: boolean
    castle_rights: number
    en_passant: number
    halfmove: number
    fullmove: number
}

// Tikan library turn.nr struct.
export type Turn = {
    piece: typeof Piece
    from: number
    to: number
    promotion_piece: number
}
