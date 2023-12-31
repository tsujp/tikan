import { Piece } from '../types'

const valid_start_board = {
    bbs: [
        '0xffff', // White board
        '0xffff000000000000', // Black board
        '0x4200000000000042', // Knights
        '0x2400000000000024', // Bishops
        '0x8100000000000081', // Rooks
        '0x0800000000000008', // Queens
        '0x1000000000000010', // Kings
        '0x00ff00000000ff00', // Pawns
    ],
    army: 0, // Current army's turn (Board::Piece enum index)
    castle_rights: 15, // Bitmask castle rights K Q k q, 1 = yes, 0 = no
    en_passant: 0, // En-passant target square index (LERLEF 6-bits)
    halfmove: 0, // Halfmove count
    fullmove: 1, // Fullmove count
} as const

// White starts game, black accepts their valid move.
export const white_valid_pawns = {
    // Variant 1.
    double_pawn_push: {
        input_board: valid_start_board,
        white_move: {
            piece: Piece.PAWN,
            from: 14, // g2
            to: 30, // g4
            promotion_piece: 0,
        },
    },
    // Variant 2
    single_pawn_push: {
        input_board: valid_start_board,
        white_move: {
            piece: Piece.PAWN,
            from: 14, // g2
            to: 22, // g3
            promotion_piece: 0,
        },
    },
} as const
