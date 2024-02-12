import { template } from '../utility/misc'

const VALID_WHITE_START = [{ idx: 1, lights: true }, { idx: 3, lights: true }] as const

const VALID_BLACK_START = [{ idx: 21, lights: true }, { idx: 23, lights: true }] as const

const VALID_START_BOARD = {
    halfmove: 0,
    turn: 0,
    commits: [
        { x: '0x0', y: '0x0' },
        { x: '0x0', y: '0x0' },
    ],
    players: [
        VALID_WHITE_START,
        VALID_BLACK_START,
    ]
} as const

export const legal__white_moves = {
    // Compass rose from starting position.
    'start board': (function* () {
        const from_idx = 1
        const to_indices = [0, 5, 6, 7, 2] // Compass rose about `from_idx`.

        yield template`move ${0} to ${1}`
        
        for (const to_idx in to_indices) {
            yield {
                cur_board: VALID_START_BOARD,
                move: {
                    pieces: VALID_WHITE_START,
                    from: from_idx,
                    to: to_idx,
                }
            }
        }
    })(),
    'start board, move 0 to 1': {
        cur_board: VALID_START_BOARD,
        move: {
            pieces: VALID_WHITE_START,
            from: 1,
            to: 2
        },
    },
    // 'start board, move {1} to {2}': {
    //     cur_board: VALID_START_BOARD,
    //     move: {
    //         pieces: VALID_WHITE_START,
    //         from: 1,
    //         to: 2
    //     },
    // },
} as const

export const illegal__white_moves = {
    // Legal move pattern however white does NOT have a piece at the claimed
    //   starting index.
    'legal move pattern, but no piece at `from` index': {
        cur_board: VALID_START_BOARD,
        move: {
            pieces: [{ idx: 2, lights: true }, { idx: 3, lights: true }],
            from: 2,
            to: 1
        },
    },
} as const

// const valid_start_board = {
//     bbs: [
//         '0xffff', // White board
//         '0xffff000000000000', // Black board
//         '0x4200000000000042', // Knights
//         '0x2400000000000024', // Bishops
//         '0x8100000000000081', // Rooks
//         '0x0800000000000008', // Queens
//         '0x1000000000000010', // Kings
//         '0x00ff00000000ff00', // Pawns
//         '0xffffffffffffffff', // Fog

//     ],
//     army: 0, // Current army's turn (Board::Piece enum index)
//     castle_rights: 15, // Bitmask castle rights K Q k q, 1 = yes, 0 = no
//     en_passant: 0, // En-passant target square index (LERLEF 6-bits)
//     halfmove: 0, // Halfmove count
//     fullmove: 1, // Fullmove count
//     has_fog: true,
// } as const

// // White starts game, black accepts their valid move.
// export const white_valid_pawns = {
//     // Variant 1.
//     double_pawn_push: {
//         input_board: valid_start_board,
//         white_move: {
//             piece: Piece.PAWN,
//             from: 14, // g2
//             to: 30, // g4
//             promotion_piece: 0,
//         },
//     },
//     // Variant 2
//     single_pawn_push: {
//         input_board: valid_start_board,
//         white_move: {
//             piece: Piece.PAWN,
//             from: 14, // g2
//             to: 22, // g3
//             promotion_piece: 0,
//         },
//     },
// } as const
