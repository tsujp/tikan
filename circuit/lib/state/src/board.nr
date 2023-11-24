use dep::std::{println, wrapping_add, wrapping_mul, wrapping_sub};

use dep::std::collections::vec::Vec;

use crate::types::{Bitboard, BitboardIndex, REQUIRED_BITBOARDS, BitboardOf, Player, Piece};
use dep::util::utility::{assert_u64, assert_u6, assert_u4, assert_u1};
use crate::move::{Move, knight_moves};

use dep::util::bit_logic as bl;

// TODO: Rename `Board` to `Game` or something.

struct Board {
    // Square positions accessed in LERLEF order.
    bbs: [Bitboard; REQUIRED_BITBOARDS],
    army: u1,
    castle_rights: u4,
    en_passant: BitboardIndex,
    halfmove: Field,
    fullmove: Field
}

global STARTING_BITBOARDS: [Bitboard; REQUIRED_BITBOARDS] = [
  0xffff,
  0xffff000000000000,
  0x4200000000000042,
  0x2400000000000024,
  0x8100000000000081,
  0x0800000000000008,
  0x1000000000000010,
  0x00ff00000000ff00
];

fn assert_piece(p: Field) -> u3 {
    let p_cast: u3 = p as u3;

    assert(
        (p == p_cast as Field)
            & (BitboardOf::PAWN as u3 <= p_cast)
            & (p_cast <= BitboardOf::KING as u3),
        "Given piece is NOT a pawn, knight, bishop, rook, queen, or king."
    );

    p_cast
}

// See https://www.chessprogramming.org/Flipping_Mirroring_and_Rotating#Flip_about_the_Diagonal
global SHIFTED_ANTI_DIAGONAL: u64 = 0x02040810204081;

global PAWN_START_RANKS: [Bitboard; 2] = [
    0xFF00,
    0xFF000000000000
];

global NOT_8_RANK: u64 = 0x00ffffffffffffff;
global NOT_1_RANK: u64 = 0xffffffffffffff00;

global A_FILE: u64 = 0x0101010101010101;
global NOT_A_FILE: u64 = 0xfefefefefefefefe;
global NOT_H_FILE: u64 = 0x7f7f7f7f7f7f7f7f;

// // Same as NOT_8_RANK & NOT_H_FILE;
// global FILL_A1_G7_MASK: u64 = 0x7f7f7f7f7f7f7f;

// // Same as NOT_1_RANK & NOT_A_FILE;
// global FILL_B2_H8_MASK: u64 = 0xfefefefefefefe00;


// Returns arguments for `valid_orthogonal_move` for the given file.
// To get a file as a rank the board must be rotated 90 degrees clockwise.
fn file_as_rank (
    from_idx6: u6,
    to_idx6: u6,
    file_idx3: u3,
    us: Bitboard,
    them: Bitboard
) -> (u6, u64, u64, u64, u64) {
    let file_mask64 = A_FILE * (1 << file_idx3 as u64);
    let file_shift64 = 7 - file_idx3;
    
    // Multiplying the H file by the shifted anti-diagonal bitboard moves the
    //   H-file bits (in the same order in terms of bitwise significance) to
    //   the 8th rank (north-edge of the board).
    // Shifting the 8th rank 56 places to the right moves it to the 1st rank.
    let us_bb8 = wrapping_mul(
        SHIFTED_ANTI_DIAGONAL,
        // only our pieces    // shift to H file
        (file_mask64 & us) << (file_shift64 as u64)
    ) >> 56;

    let them_bb8 = wrapping_mul(
        SHIFTED_ANTI_DIAGONAL,
        (file_mask64 & them) << (file_shift64 as u64)
    ) >> 56;

    let from_idx3 = bl::rank_idx_6_3(from_idx6) as u6;
    let from_bb = 1 << (from_idx3 as u64);
    let to_bb = 1 << (bl::rank_idx_6_3(to_idx6) as u64);

    (from_idx3, from_bb, to_bb, us_bb8, them_bb8)
}


// Computing valid moves involves constructing two sets of masks for each
//   direction: negative (west) and positive (east).
//
// - The first mask is called "blockers" and masks from the location of the
//     closest friendly piece (if any) to the edge of the board in that direc-
//     tion. Since we cannot capture friendly pieces this masks squares we
//     cannot travel to (ignoring enemy piece positions).
// - The second mask is called "extent" and masks inclusively from the location
//     of the closest enemy piece (if any) to the edge of the board in that
//     direction.
//
// The union of "blockers" and "extent" now masks invalid square destinations
//   while allowing us to capture un-blocked (by our friendlies) enemy pieces
//   should any be present. To form the final valid move mask the relative
//   complement of the rank mask (without the from-piece's position set) is
//   taken.
fn valid_orthogonal_move (
    from_idx6: BitboardIndex,
    from_bb: Bitboard,
    to_bb: Bitboard,
    us: Bitboard,
    them: Bitboard
) -> bool {
    // STEP 1.
    //   1) Get index of square marking the start of the current rank so we can
    //        shift that rank down to the 1st (8-bits only) (and optionally back
    //        once done).
    //   2) Get mask of current rank so we can get occupancy masks.
    //   3) Get occupancy masks and shift to the first rank.
    //   4) Shift move from/to single occupancy masks to first rank.

    let rank_shift64 = bl::rank_start_idx_6(from_idx6) as u64; // 1.1
    let rank_mask64 = bl::rank_mask_6_64(from_idx6); // 1.2

    let us_bb8 = ((rank_mask64 & us) >> rank_shift64) as u8; // 1.3
    let them_bb8 = ((rank_mask64 & them) >> rank_shift64) as u8; // 1.3

    let from_bb8 = (from_bb >> rank_shift64) as u8; // 1.4
    let to_bb8 = (to_bb >> rank_shift64) as u8; // 1.4

    //
    // STEP 2.
    //   -- We have occupancy masks for friendly (us) and enemy (them) pieces
    //        as well as single occupancy masks of our moves starting square and
    //        ending square; all are in 8-bit values; i.e. a single rank.
    //
    //   1) Get index of from position (single set bit) as integer.
    //   2) Get west (negative) and east (positive) masks from (1) exclusive of
    //        that location; also called west/east rays.
    //   3) Get location of closest blocking piece (friendly only) and enemy
    //        piece in rays. These are single occupancy bitboards and in most
    //        cases if no such piece is found the bitboard is empty (i.e. 0)
    //        EXCEPT for the east extent which will default to the 7th bit
    //        being set (value 128) to allow correct mask computation.

    let from_idx3 = bl::file_idx_6_3(from_idx6); // 2.1

    let west_ray = bl::west_ray_3_8(from_idx3); // 2.2
    let east_ray = bl::east_ray_3_8(from_idx3); // 2.2

    // This is where "blockers" and "extent" comes into play.
    let west_b_bb8 = bl::ms1b_8(west_ray & us_bb8); // 2.3
    let west_e_bb8 = bl::ms1b_8(west_ray & them_bb8); // 2.3
    let east_b_bb8 = bl::ls1b_8(east_ray & us_bb8); // 2.3
    let east_e_bb8 = bl::ls1b_8((east_ray & them_bb8) | 128); // 2.3

    //    
    // STEP 3.
    //   -- With crucial masks set-up (ray masks) and our closest blockers in
    //        both rays known (if any) as well as the extent we can move to
    //        (ignoring those blockers) in both rays known (if any) we can now
    //        compute the final set of moves.
    //
    //   1) Mask ray from closest blocker in that range to the rays board edge
    //        INCLUDING THE LOCATION OF THE BLOCKER (if any). Said mask now
    //        represents squares we cannot ever move to as we're blocked by
    //        a friendly; if no friendlies block these masks are empty (i.e. 0).
    //   2) Mask ray from closest extent in that range to the rays board edge
    //        EXCLUDING THE LOCATION OF THE EXTENT PIECE (if any). Said mask now
    //        represents squares "behind" an enemy piece (if any); so if there
    //        are no blockers we could move up to and including the square of
    //        the enemy piece (to capture) but not _beyond_ (behind) it. If
    //        there are no enemy pieces the masks are empty (i.e. 0).
    //   3) Valid moves are the relative complement of the ray; and that ray's
    //        blocker and extent masks. i.e. for west: "squares in the west ray
    //        mask which are not in either the west blocker or extent masks".

    let west_block = bl::west_ray_3_8(bl::ms1b_idx_8_3(west_b_bb8)) | west_b_bb8; // 3.1
    let east_block = !wrapping_sub(east_b_bb8, 1); // 3.1
    
    let west_extent = bl::west_ray_3_8(bl::ms1b_idx_8_3(west_e_bb8)); // 3.2
    let east_extent = bl::east_ray_3_8(bl::ms1b_idx_8_3(east_e_bb8)); // 3.2

    let valid_west = west_ray & !(west_block | west_extent); // 3.3
    let valid_east = east_ray & !(east_block | east_extent); // 3.3

    let valid_moves = valid_west | valid_east;

    // println(f"k-0xFF k-{us} k-{them} k-{west_ray} k-{east_ray} k-{valid_west} k-{valid_east} k-{valid_moves} k-0x00");
    // println(f"k-0x0");

    // println(valid_moves);
    // println(to_bb8);

    (valid_moves & to_bb8) > 0
}


impl Board {
    // Returns an array of struct members as Fields, for use in hashing
    //   functions (e.g. Pedersen).
    fn decompose(self) -> [Field; 13] {
        [
            self.bbs[0] as Field,
            self.bbs[1] as Field,
            self.bbs[2] as Field,
            self.bbs[3] as Field,
            self.bbs[4] as Field,
            self.bbs[5] as Field,
            self.bbs[6] as Field,
            self.bbs[7] as Field,
            self.army as Field,
            self.castle_rights as Field,
            self.en_passant as Field,
            self.halfmove,
            self.fullmove
        ]
    }

    pub fn apply(self, move: Move) -> Board {
        let army = self.army;
        let from_idx = move.from as Bitboard;
        let to_idx = move.to as Bitboard;
        let piece = move.piece + 2;

        let mut en_passant: BitboardIndex = 0;

        assert(
            bl::is_bit_set(
               self.bbs[army] & self.bbs[piece],
               from_idx
            ),
           "Given army does NOT have a piece at expected LERLEF index"
        );

        let from_bb = 0 as Bitboard | 1 << from_idx;
        let to_bb = 0 as Bitboard | 1 << to_idx;

        let mut special_bb = 0 as Bitboard;

        // Generally need.
        let file_idx3 = bl::file_idx_6_3(move.from);
        // let file_mask64 = A_FILE * (1 << file_idx3);


        // TODO: Could probably make these accessed by keys to remove if-else
        //       chain, or at least order based on piece move frequencies but
        //       PREMATURE OPTIMISATION so do it later.
        // ----------------------------------------------
        // ----------------------------------------------
        if move.piece == Piece::KNIGHT {
            let moves = knight_moves(from_bb, self.bbs[army]);

            assert(
                bl::is_bit_set(moves, to_idx),
                "KNIGHT move is INVALID either improper move pattern or square is already occupied by a piece on the same team"
            );
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::PAWN {
            // TODO: Pawn promotion.
            
            // println(f"PAWN: [start mask] {from_bb} [idx] {from_idx}");
            
            // Universal shift offset (only applies when black moves).
            let dir = (army as Bitboard) << 4;

            let mut moves = if (PAWN_START_RANKS[army] & from_bb) > 0 {
                // Set us as the en passant target.
                // TODO: shift by direction, needs to be square BEHIND so we can
                // use one simple lookup by index.
                en_passant = move.to;

                // Double push first move; universal shift.
                let __tmp = (from_bb << 8) >> dir;
                __tmp | (__tmp << 8) >> dir
            } else {
                // Single push first move; universal shift.
                (from_bb << 8) >> dir
            };

            // File mask of pawn.
            let file = A_FILE * (1 << (from_idx & 7));

            // Mask of pieces in current file, pawns can only capture diagonally
            //   so exclude these squares from our push options (if they so
            //   happen to intersect).
            let same_file_blockers = (self.bbs[army] | self.bbs[!army]) & file;
            moves &= !same_file_blockers;

            // En passant target.
            let ep = (1 << self.en_passant as Bitboard);

            // Mask of legal diagonal movements (because an enemy piece lets
            //   us capture); this does not include en passant.
            let diags = (((5 << from_idx - 1) << 8) >> dir) & self.bbs[!army];
            moves |= (diags | ep);

            // let foo_bb = ep_bb;
            // to_bb = ep_bb;
           
            // println(f"k-0xFF k-{from_bb} k-{moves} k-{same_file_blockers} k-{ep} k-{diags} k-{foo_bb} k-0x00 k-0x00");
            // println(f"k-0x0");
            
            assert(
                bl::is_bit_set(moves, to_idx),
                "PAWN move is INVALID either improper move pattern or square is already occupied by a piece on the same team"
            );

            // The (at this point) valid move was an en passant capture, need
            //   to set the capture bitboard with the correct index.
            if (move.to == self.en_passant) {
                // println("was an ep capture");
                let ep_bb = (ep >> 8) << dir;
                special_bb = ep_bb;
            }
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::ROOK {
            // XXX [1] HERE AND ELSEWHERE...
            //   Due to limitations with `assert` error messages (only literals)
            //     and for test discrimination over how a move is being interpreted
            //     we pre-rotate the board before validating an orthogonal move.
            //     When assert supports template strings this can go inside the
            //     `valid_orthogonal_move` function itself.

            // Is this a horizontal or vertical move?
            if (file_idx3 == bl::file_idx_6_3(move.to)) {
                // Vertical, need to rotate board and indices before calling.

                // TODO: Could likely higher-order function this (later optimisations).
                let ftr_data = file_as_rank(
                    move.from,
                    move.to,
                    file_idx3,
                    self.bbs[army],
                    self.bbs[!army]
                );

                let is_valid = valid_orthogonal_move(
                    ftr_data.0,
                    ftr_data.1,
                    ftr_data.2,
                    ftr_data.3,
                    ftr_data.4
                );

                assert(
                    is_valid,
                    // ... and this XXX [1] `vertical`
                    "ROOK move VERTICAL is INVALID either improper move pattern or square is already occupied by a piece on the same team"
                );
            } else {
                // Horizontal, no rotation required.
                let is_valid = valid_orthogonal_move(move.from, from_bb, to_bb, self.bbs[army], self.bbs[!army]);

                assert(
                    is_valid,
                    // So we can do this XXX [1] `horizontal`
                    "ROOK move HORIZONTAL is INVALID either improper move pattern or square is already occupied by a piece on the same team"
                );
            }
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::BISHOP {
            // TODO

            let rank_idx = bl::rank_idx_6_3(move.from);
            
            let us = self.bbs[army];
            let sq = move.from as u64;          

            // Loops are unrolled anyway.
            // let mut _p_d: u64 = 0;
            // for i in 1 .. 8 {
            //     _p_d += ((from_bb as u127 << (9 * i)) as u64);
            // }

            // Loops are unrolled anyway.
            // let mut _n_d: u64 = 0;
            // for i in 1 .. 8 {
            //     _n_d += ((from_bb as u127 >> (9 * i)) as u64);
            // }

            // TODO: Positive anti-diagonal and negative anti-diagonal.

            // Dtaxi = |r2 - r1| + |f2 - f1|

            let n1: u64 = 20;
            let n2: u64 = 11; // expect absolute difference of 5

            // let mut blah = wrapping_sub(n1, n2);
            // let mut blah = bl::abs_diff(wrapping_sub(n1, n2));

           // int file1, file2, rank1, rank2;
           // int rankDistance, fileDistance;
           // file1 = sq1  & 7;
           // file2 = sq2  & 7;
           // rank1 = sq1 >> 3;
           // rank2 = sq2 >> 3;
           // rankDistance = abs (rank2 - rank1);
           // fileDistance = abs (file2 - file1);
           // return rankDistance + fileDistance;

            let f1 = move.from & 7;
            let f2 = move.to & 7;
            let r1 = move.from >> 3;
            let r2 = move.to >> 3;

            let rd = bl::abs_diff(wrapping_sub(r2, r1));
            let fd = bl::abs_diff(wrapping_sub(f2, f1));
            let blah = rd + fd;

  
            
            // int s = a >> 31; // cdq, signed shift, -1 if negative, else 0
            //    a ^= s;  // ones' complement if negative
            //    a -= s;  // plus one if negative -> two's complement if negative

            println(f"k-0xFF k-{us} k-{from_bb} k-{to_bb} k-0x00 k-0x00 k-0x00 k-{blah} k-0x00");
            println(f"k-0x0");

           //  b |= b >> 32;
           // b |= b >> 16;
           // b |= b >>  8;
           // let wat = b & 0xFF;

           //  b |= b >>  4;
           // b |= b >>  2;
           // b |= b >>  1;
           // b &= 0x0101010101010101 as u64;
           // b |= b >>  7;
           // b |= b >> 14;
           // b |= b >> 28;
           // let wat = b & 0xFF;


           //  let mut b = self.bbs[army];

           // let aFile   = 0x0101010101010101 as u64;
           // let antiDia = 0x0102040810204080 as u64;

           // b |= b >> 4;   // No masking needed
           // b |= b >> 2;   //    "         "
           // b |= b >> 1;   //    "         "
           // let wat = wrapping_mul((b & aFile), antiDia) >> 56;

            // println(f"k-0xFF k-{us} k-{from_bb} k-{diag} k-0x00 k-0x00 k-0x00 k-0x00 k-0x00");
            // println(f"k-0x0");
            
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::QUEEN {
            // TODO: Diagonal movement from bishop also.

            // Is this a horizontal or vertical move?
            if (file_idx3 == bl::file_idx_6_3(move.to)) {
                let ftr_data = file_as_rank(move.from, move.to, file_idx3, self.bbs[army], self.bbs[!army]);

                let is_valid = valid_orthogonal_move(ftr_data.0, ftr_data.1, ftr_data.2, ftr_data.3, ftr_data.4);

                assert(
                    is_valid,
                    // ... and this XXX [1] `vertical`
                    "QUEEN move VERTICAL is INVALID either improper move pattern or square is already occupied by a piece on the same team"
                );
            } else {
                // Horizontal, no rotation required.
                let is_valid = valid_orthogonal_move(move.from, from_bb, to_bb, self.bbs[army], self.bbs[!army]);

                assert(
                    is_valid,
                    // So we can do this XXX [1] `horizontal`
                    "QUEEN move HORIZONTAL is INVALID either improper move pattern or square is already occupied by a piece on the same team"
                );
            }
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::KING {
            // TODO
            // TODO: Can do the same for queen but have a mask such that only
            //       the squares immediately around the king are valid too.
        // ----------------------------------------------
        // ----------------------------------------------
        } else {
            assert(false, "INVALID piece provided");
        };
        
        // TODO: Need anything specific for quiet moves anymore?
        // Specifically for quiet moves, or if captures only the capturing army.

        // Good for quiet moves.
        let update_piece_mask = from_bb ^ to_bb;

        // let update_piece_bb = self.bbs[piece] ^ update_piece_mask;
        // let update_army_bb = self.bbs[army] ^ update_piece_mask;

        // println(f"update_piece_mask: {update_piece_mask}");
        // println(f"update_piece_bb: {update_piece_bb}");
        // println(f"update_army_bb: {update_army_bb}");

        // This causes a panic.
        // The application panicked (crashed).
        // Message:  internal error: entered unreachable code: Cannot flatten a dynamic array
        // Location: compiler/noirc_evaluator/src/ssa/acir_gen/acir_ir/acir_variable.rs:845
            // let mut bbs = self.bbs;

            // bbs[piece] ^= update_piece_mask;
            // bbs[army] ^= update_piece_mask;
        // End panic.

        // Workaround for the panic.
        let army3 = army as u3;
        let enemy3 = (!army) as u3;

        let mut new_bbs = [0 as Bitboard; REQUIRED_BITBOARDS];
        for i in 0 .. REQUIRED_BITBOARDS {
            let idx3 = i as u3;

            if (idx3 == piece) {
                new_bbs[i] = self.bbs[i] ^ update_piece_mask ^ special_bb;
            } else if (idx3 == army3) {
                new_bbs[i] = self.bbs[i] ^ update_piece_mask;
            } else if (idx3 == enemy3) {
                new_bbs[i] = self.bbs[i] ^ special_bb;
            } else {
                new_bbs[i] = self.bbs[i];
            }
        }
        // End ugly workaround.

        // `fullmove` is incremented after black's turn.
        let fullmove = self.fullmove + if army == Player::BLACK { 1 } else { 0 };

        let mut new_board = Board {
            bbs: new_bbs,
            army: !army,
            castle_rights: self.castle_rights,
            en_passant: en_passant,
            halfmove: self.halfmove,
            fullmove: fullmove
        };

        new_board
    }


    // Validates input move data _structure_ and then tries to apply the move to
    //   the current gamestate which may fail if the move is illegal.
    // From and to are taken as indices to save us doing bitscans or 2's
    //   complement tricks. We can simply validate its a value within closed
    //   range 0 - 63 and produce a bitboard mask ourselves.
    //
    // 'Structure' meaning, for example, that the `soldier` parameter is
    //     expected to be in closed range 2 - 7. A 3-bit unsigned integer can
    //     itself represent closed range 0 - 8; so this must be validated.
    pub fn apply_move(
        self,
        soldier: Field, // WAT1
        from_index: Field, // WAT1
        to_index: Field, // WAT1
        capture: Field, // TODO: Do we really need to set this vs infer it?
        promotion_soldier: Field // WAT1
    ) -> Self {
        let army = self.army;
        println(f"apply_move(): army u-{army} moves piece u-{soldier} from u-{from_index} to u-{to_index}  /  capture? u-{capture}");

        // Validate input (things from users are scary).
        let piece = assert_piece(soldier);
        let from_idx = assert_u6(from_index) as Bitboard;
        let to_idx = assert_u6(to_index) as Bitboard;

        // TODO: Do we NEED the capture bit set or can it be inferred?
        assert_u1(capture);

        // Validate piece to move is in-fact at starting position claimed.
        // TODO: Board instantiation `from_serial` would have already validated
        //       that bitboards match for given pieces so we can simply check
        //       the index in the bitboard now.
        assert(
            bl::is_bit_set(
               self.bbs[army] & self.bbs[piece],
               from_idx
            ),
           "Given army does NOT have a piece at expected LERLEF index."
        );

        // Piece at location valid; create bitboard with LERLEF-index bit set.
        let from_bb = 0 as Bitboard | 1 << from_idx;
        println(f"from_bb: {from_bb}");

        let moves = knight_moves(from_bb, self.bbs[army]);
        println(f"(current board) all valid moves: {moves}");

        // If `moves` has a 1 set at `to_idx` the requested move is valid.
        assert(
            bl::is_bit_set(moves, to_idx),
            "Given move is INVALID; either improper move pattern or square is already occupied by a piece in the same team."
        );

        // Move is now fully validated and we can update the gamestate bitboard
        //   for the current army and piece.
        let to_bb = 0 as Bitboard | 1 << to_idx;
        println(f"to_bb: {to_bb}");

        // A bitboard with the from and to positions both set to 1.
        let update_piece_mask = from_bb ^ to_bb;
        println(f"post-move update mask: {update_piece_mask}");

        // Since the positions in the (currently) unchanged piece bb will have
        //   only a single bit intersection (the from_bb) XORing the update
        //   mask with the original locations creates a bb with pieces in
        //   their correct locations post-move.
        let update_piece_bb = self.bbs[piece] ^ update_piece_mask;
        println(f"update_piece_bb: {update_piece_bb}");

        // Finally the army union bb must be updated.
        let update_army_bb = self.bbs[army] ^ update_piece_mask;
        println(f"update_army_bb: {update_army_bb}");

        let mut bbs = self.bbs;

        bbs[piece] ^= update_piece_mask;
        bbs[army] ^= update_piece_mask;

        let new_board = Board {
            bbs: bbs,
            army: !army,
            castle_rights: self.castle_rights,
            en_passant: self.en_passant,
            halfmove: self.halfmove,
            fullmove: self.fullmove
        };

        new_board
    }
}

