import { Piece } from '../types'

const fog_lit_start_board = {
    // Public start of the game, no move yet, from white's perspective.
    bbs: [
        0, // White isn't revealed at all.
        0, // Neither is black.
        0, // .'. no pieces are revealed.
        0, // "
        0, // "
        0, // "
        0, // "
        0 // "
        // If we need a normal starting base we subtract from here it is:
        // '0xFFFF',
        // '0xFFFF000000000000',
        // '0x4200000000000042',
        // '0x2400000000000024',
        // '0x8100000000000081',
        // '0x0800000000000008',
        // '0x1000000000000010',
        // '0x00FF00000000FF00'
    ],
    army: 0,
    castle_rights: 15, // TODO: Would need to blind this too...
    en_passant: 0, // TODO: And this...
    halfmove: 0,
    fullmove: 1,
    has_fog: true,
    lit: ['0xffffffff', '0xffffffff00000000'],
    lamp: '0xffff00000000ffff'
} as const

// White starts game, black accepts their valid move.
export const white_valid_pawns = {
    // Scenario 1.
    double_pawn_push: {
        public_state: fog_lit_start_board,
        white_move: {
            piece: Piece.PAWN,
            from: 14, // g2
            to: 30, // g4
            promotion_piece: 0,
            lights: true,
            // White private pieces
            bbs: [
                '0x42',
                '0x24',
                '0x81',
                '0x8',
                '0x10',
                '0xff00'
            ]
        },
    },
} as const
