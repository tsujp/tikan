import { Piece } from '../types'

const fog_lit_start_board = {
    // Public start of the game, no move yet, from white's perspective.
    bbs: [
        '0', // White isn't revealed at all.
        '0', // Neither is black.
        '0', // .'. no pieces are revealed.
        '0', // "
        '0', // "
        '0', // "
        '0', // "
        '0', // "
        // fog is like 'anti fog' so 64-1s is all squares illuminated.
        '0xffffffffffffffff',
    ],
    army: 0,
    castle_rights: 15, // TODO: Would need to blind this too...
    en_passant: 0, // TODO: And this...
    halfmove: 0,
    fullmove: 1,
    has_fog: true,
    lamp: '0xffff00000000ffff'
} as const

// White starts game, black accepts their valid move.
export const white_valid_pawns = {
    // Scenario 1.
    double_pawn_push: {
        public_state: fog_lit_start_board,
        white_private_pieces: [
            '0x42',
            '0x24',
            '0x81',
            '0x10',
            '0x8',
            '0xff00'
        ],
        white_move: {
            piece: Piece.PAWN,
            from: 14, // g2
            to: 30, // g4
            promotion_piece: 0,
        },
    },
} as const
