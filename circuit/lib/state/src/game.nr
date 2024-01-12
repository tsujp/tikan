use dep::std::{wrapping_add, wrapping_mul, wrapping_sub};

use dep::std::collections::vec::Vec;

use crate::types::{Bitboard, BitboardIndex, REQUIRED_BITBOARDS, PIECE_OFFSET, BitboardOf, Player, Piece, Sliding, Game, Turn, Move};

use dep::util::bit_logic as bl;

global STARTING_BITBOARDS: [Bitboard; REQUIRED_BITBOARDS] = [
  0xFFFF,
  0xFFFF000000000000,
  0x4200000000000042,
  0x2400000000000024,
  0x8100000000000081,
  0x0800000000000008,
  0x1000000000000010,
  0x00FF00000000FF00,
  // TODO: Put proper starting fog mask here.
  0x42069,
];

// Determine whether a move is horizontal, vertical, diagonal, or anti-diagonal
//   and then transforms the move into a rank-equivalent (for feeding into
//   `valid_rank_move`).
fn rankified_sliding_data(
    from_idx6: u6,
    to_idx6: u6,
    from_bb: Bitboard,
    to_bb: Bitboard,
    us: Bitboard,
    them: Bitboard
) -> (u3, (BitboardIndex, Bitboard, Bitboard, Bitboard, Bitboard)) {
    // TODO: `let mut transposed` at the top cheaper or more expensive gate wise?
    let mut move_data: (u3, (BitboardIndex, Bitboard, Bitboard, Bitboard, Bitboard)) = (7, (0, 0, 0, 0, 0));

    if (bl::rank_idx_6_6(from_idx6) == bl::rank_idx_6_6(to_idx6)) {
        // Horizontal move if the rank indices are the same.
        move_data = (Sliding::HORIZONTAL, (from_idx6, from_bb, to_bb, us, them));
    } else if (bl::file_idx_6_6(from_idx6) == bl::file_idx_6_6(to_idx6)) {
        // Vertical move if file indices are the same.
        move_data = (Sliding::VERTICAL, file_as_rank(from_idx6, to_idx6, bl::file_idx_6_3(to_idx6), us, them));
    } else if (bl::on_same_diagonal(from_idx6, to_idx6)) {
        let diag_mask = bl::diagonal_mask_64(from_bb);

        let c_from_idx = bl::file_idx_6_6(from_idx6);

        // `C`ollapsed, etc.
        let c_from_bb = bl::collapse_diagonal_to_rank_64_8(from_bb) as u64;
        let c_to_bb = bl::collapse_diagonal_to_rank_64_8(to_bb) as u64;
        let c_us = bl::collapse_diagonal_to_rank_64_8(us & diag_mask) as u64;
        let c_them = bl::collapse_diagonal_to_rank_64_8(them & diag_mask) as u64;

        move_data = (Sliding::DIAGONAL, (c_from_idx, c_from_bb, c_to_bb, c_us, c_them));
    } else if (bl::on_same_anti_diagonal(from_idx6, to_idx6)) {
        let diag_mask = bl::anti_diagonal_mask_64(from_bb);

        // TODO: This is the same as above except the `diag_mask` is different, suck this out to it's own thing later.

        let c_from_idx = bl::file_idx_6_6(from_idx6);

        // `C`ollapsed, etc.
        let c_from_bb = bl::collapse_diagonal_to_rank_64_8(from_bb) as u64;
        let c_to_bb = bl::collapse_diagonal_to_rank_64_8(to_bb) as u64;
        let c_us = bl::collapse_diagonal_to_rank_64_8(us & diag_mask) as u64;
        let c_them = bl::collapse_diagonal_to_rank_64_8(them & diag_mask) as u64;

        move_data = (Sliding::ANTI_DIAGONAL, (c_from_idx, c_from_bb, c_to_bb, c_us, c_them));
    } else {
        assert(false, "Improper move pattern for given sliding piece");
    }

    move_data
}

fn assert_piece(p: Field) -> u3 {
    let p_cast: u3 = p as u3;

    assert(
        (p == p_cast as Field) & (BitboardOf::PAWN as u3 <= p_cast) & (p_cast <= BitboardOf::KING as u3), "Given piece is NOT a pawn, knight, bishop, rook, queen, or king."
    );

    p_cast
}

// See https://www.chessprogramming.org/Flipping_Mirroring_and_Rotating#Flip_about_the_Diagonal
global SHIFTED_ANTI_DIAGONAL: u64 = 0x02040810204081;

global PAWN_START_RANKS: [Bitboard; 2] = [
    0xFF00,
    0xFF000000000000
];

global NOT_8_RANK: u64 = 0x00FFFFFFFFFFFFFF;
global NOT_1_RANK: u64 = 0xFFFFFFFFFFFFFF00;

global A_FILE: u64 = 0x0101010101010101;
global NOT_A_FILE: u64 = 0xFEFEFEFEFEFEFEFE;
global NOT_H_FILE: u64 = 0x7F7F7F7F7F7F7F7F;

// Returns arguments for `valid_rank_move` for the given file.
// To get a file as a rank the board must be rotated 90 degrees clockwise.
fn file_as_rank(
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
    )
        >> 56;

    let them_bb8 = wrapping_mul(
        SHIFTED_ANTI_DIAGONAL,
        (file_mask64 & them) << (file_shift64 as u64)
    )
        >> 56;

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
fn valid_rank_move(
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

    // TODO: This can go into `get_masked_move_data` instead.
    let rank_shift64 = bl::rank_start_idx_6(from_idx6) as u64; // 1.1
    let rank_mask64 = bl::rank_mask_6_64(from_idx6); // 1.2

    let us_bb8 = ((rank_mask64 & us) >> rank_shift64) as u8; // 1.3
    let them_bb8 = ((rank_mask64 & them) >> rank_shift64) as u8; // 1.3

    let from_bb8 = (from_bb >> rank_shift64) as u8; // 1.4
    let to_bb8 = (to_bb >> rank_shift64) as u8; // 1.4
    // ---/ end TODO.

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

    // DBG: Uncomment 2 lines, view in bb_web.
    // println(f"k-0xFF k-{us} k-{them} k-{west_ray} k-{east_ray} k-{valid_west} k-{valid_east} k-{valid_moves} k-0x00");
    // println(f"k-0x0");

    (valid_moves & to_bb8) > 0
}

// These APIs are mostly for testing because inputs to circuits in the wild
//   auto-instantiate the `Game` struct directly instead of calling a
//   method, this method makes it easier than having multiple test helpers
//   spread all over the place.
// XXX: Put here and not on the `Game` struct because doing so there is giving:
//      `expected global variable got local variable` in other files.
pub fn init<N>(given_bbs: [u64; N], with_fog: bool) -> Game {
    let required_bbs = REQUIRED_BITBOARDS as u64; // Cannot use in println as `REQUIRED_BITBOARDS`.

    if N == 0 {
        assert(false, "Need at least 1 Bitboard");
    } else if N > required_bbs {
        // Cannot template assertion messages.
        dep::std::println(f"At most can receive {required_bbs} Bitboards, given {N}");
        assert(false, "Too many Bitboards given, see REQUIRED_BITBOARDS");
    }

    // FIXME: Lots of compiler type errors in here for some reason??
    // FIXME: Cannot instantiate as [0 as Bitboard; REQUIRED_BITBOARDS] due to
    //        LSP formatting `plain::Bitboard` bug.
    // let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as Bitboard; REQUIRED_BITBOARDS];
    // let mut set_bbs: [Bitboard; REQUIRED_BITBOARDS] = dep::std::unsafe::zeroed();
    let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as u64; REQUIRED_BITBOARDS];

    for idx in 0..given_bbs.len() {
        bbs[idx] = given_bbs[idx];
        // bbs[idx] = (given_bbs[idx] as u64); // Types erased by unsafe::zeroed().
    }

    // Last bitboard is fog. If the bitboard is all 1s it means to compute fog for the board.
    bbs[BitboardOf::FOG] = if with_fog {
        compute_fog(bbs[BitboardOf::WHITE], bbs[BitboardOf::BLACK])
    } else {
        0xFFFFFFFFFFFFFFFF // u64 max.
    };

    Game { bbs, army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1 }
}

// XXX: ADDED AS PART OF FOG, DOCS ETC PL0X.
// Creates a fog bitboard.
pub fn compute_fog(w: Bitboard, b: Bitboard) -> Bitboard {
    let all_pieces: Bitboard = w | b;

    let all_bits = (all_pieces as Field).to_le_bits(64);

    let mut fog: Bitboard = 0;

    // FIXME: Compiler `cannot determine loop bound at compile-time` for some reason.
    // for i in 0..all_bits.len() {
    for i in 0..64 {
        let bit = all_bits[i];

        let bit_fog = if bit == 1 {
            bl::taxi_mask((2 as Field).pow_32(i) as Bitboard)
        } else {
            0
        };

        fog |= bit_fog;
    }

    fog
}


impl Game {
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

    pub fn apply(self, move: Turn) -> Game {
        let army = self.army;
        let from_idx = move.from as Bitboard;
        let to_idx = move.to as Bitboard;
        let piece = move.piece + PIECE_OFFSET;

        let mut en_passant: BitboardIndex = 0;

        // let move_data = Move::check_legal(self, move);

        assert(
            bl::is_bit_set(
               self.bbs[army] & self.bbs[piece],
               from_idx
            ),
           "Piece in army does NOT EXIST at given index"
        );

        assert(
            from_idx != to_idx,
           "Cannot move onto your own square in the same turn"
        );

        let from_bb = 0 as Bitboard | 1 << from_idx;
        let to_bb = 0 as Bitboard | 1 << to_idx;

        let move_result = Move::check_legal(self, move);
        // dep::std::println(move_result);

        // TODO: Could probably make these accessed by keys to remove if-else
        //       chain, or at least order based on piece move frequencies but
        //       PREMATURE OPTIMISATION so do it later.
        // ----------------------------------------------
        // ----------------------------------------------
        if move.piece == Piece::KNIGHT {
            // Removed as part of legal-check refactor. TODO: Will clean-up once refactor complete.
        } else if move.piece == Piece::PAWN {
            // Removed as part of legal-check refactor. TODO: Will clean-up once refactor complete.
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::ROOK {
            // XXX [1] HERE AND ELSEWHERE...
            //   Due to limitations with `assert` error messages (only literals)
            //     and for test discrimination over how a move is being interpreted
            //     a bunch of `if` statements are added purely to provide different
            //     assert messages to check in tests (that a move is failing on
            //     the correct path). When `assert` supports templated strings
            //     all those `if` statements can be removed.

            let (direction, move_data) = rankified_sliding_data(move.from, move.to, from_bb, to_bb, self.bbs[army], self.bbs[!army]);

            let is_valid = valid_rank_move(move_data.0, move_data.1, move_data.2, move_data.3, move_data.4);

            if direction == Sliding::VERTICAL {
            assert(
                    is_valid,
                    // ... XXX [1] `vertical`
                    "ROOK move VERTICAL is INVALID"
                );
            } else if direction == Sliding::HORIZONTAL {
            assert(
                    is_valid,
                    // ... XXX [1] `horizontal`
                    "ROOK move HORIZONTAL is INVALID"
                );
            }
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::BISHOP {
            let (direction, move_data) = rankified_sliding_data(move.from, move.to, from_bb, to_bb, self.bbs[army], self.bbs[!army]);

            let is_valid = valid_rank_move(move_data.0, move_data.1, move_data.2, move_data.3, move_data.4);

            if direction == Sliding::DIAGONAL {

            assert(
                    is_valid,
                    // ... XXX [1] `diagonal`
                    "BISHOP move DIAGONAL is INVALID"
                );
            } else if direction == Sliding::ANTI_DIAGONAL {

            assert(
                    is_valid,
                    // ... XXX [1] `anti-diagonal`
                    "BISHOP move ANTI DIAGONAL is INVALID"
                );
            }
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::QUEEN {
            let (direction, move_data) = rankified_sliding_data(move.from, move.to, from_bb, to_bb, self.bbs[army], self.bbs[!army]);

            let is_valid = valid_rank_move(move_data.0, move_data.1, move_data.2, move_data.3, move_data.4);

            if direction == Sliding::VERTICAL {
            assert(is_valid,"QUEEN move VERTICAL is INVALID"); // XXX [1] `vertical`
            } else if direction == Sliding::HORIZONTAL {
            assert(
                    is_valid,
                    // ... XXX [1] `horizontal`
                    "QUEEN move HORIZONTAL is INVALID"
                );
            } else if direction == Sliding::DIAGONAL {

            assert(
                    is_valid,
                    // ... XXX [1] `diagonal`
                    "QUEEN move DIAGONAL is INVALID"
                );
            } else if direction == Sliding::ANTI_DIAGONAL {

            assert(
                    is_valid,
                    // ... XXX [1] `anti-diagonal`
                    "QUEEN move ANTI DIAGONAL is INVALID"
                );
            }
        // ----------------------------------------------
        // ----------------------------------------------
        } else if move.piece == Piece::KING {
            // let (direction, move_data) = rankified_sliding_data(move.from, move.to, from_bb, to_bb, self.bbs[army], self.bbs[!army]);

            // // TODO: In future if all ranks are pre-shifted to u8 could check indices are within 1 (numerically) either side to restrict king to single square instead.

            // // 0xfe = not a1 in first-rank ; 0x7f = not h1 in first-rank.
            // let not_h_file = 0x7F7F7F7F7F7F7F7F as Bitboard;
            // let not_a_file = 0xFEFEFEFEFEFEFEFE as Bitboard;

            // // Pretend everything outside the 1-taxicab range a king can move is all our pieces
            // //   thereby restricting king movement.
            // let king_mask = !(((not_a_file & move_data.1) >> 1) + ((not_h_file & move_data.1) << 1) + move_data.1);

            // let is_valid = valid_rank_move(move_data.0, move_data.1, move_data.2, king_mask | move_data.3, move_data.4);

            // if direction == Sliding::VERTICAL {
            // assert(is_valid,"KING move VERTICAL is INVALID"); // XXX [1] `vertical`
            // } else if direction == Sliding::HORIZONTAL {
            // assert(
            //         is_valid,
            //         // ... XXX [1] `horizontal`
            //         "KING move HORIZONTAL is INVALID"
            //     );
            // } else if direction == Sliding::DIAGONAL {

            // assert(
            //         is_valid,
            //         // ... XXX [1] `diagonal`
            //         "KING move DIAGONAL is INVALID"
            //     );
            // } else if direction == Sliding::ANTI_DIAGONAL {

            // assert(
            //         is_valid,
            //         // ... XXX [1] `anti-diagonal`
            //         "KING move ANTI DIAGONAL is INVALID"
            //     );
            // }
        // ----------------------------------------------
        // ----------------------------------------------
        } else {
            assert(false, "INVALID piece provided");
        };

        // TODO: Need anything specific for quiet moves anymore?
        // Specifically for quiet moves, or if captures only the capturing army.


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


        // ----------
        let mut new_bbs = self.bbs;

        // TODO: Rename `update_piece_bb` -> `us_update_bb`.
        // let update_piece_bb = from_bb ^ to_bb ^ move_result.special_bbs.remove;
        let update_piece_bb = from_bb ^ to_bb ^ move_result.special_bbs.remove;
        // dep::std::println(f"update_piece_bb: {update_piece_bb}"); // TODO: Uncomment later.

        // TODO: Rename `ep_capture_bb` -> `them_update_bb`.
        // let ep_capture_bb = move_result.ep_capture_bb.unwrap_or(to_bb);
        let ep_capture_bb = move_result.ep_capture_bb.unwrap_or(0);
        // dep::std::println(f"ep_capture_bb: {ep_capture_bb}"); // TODO: Uncomment later.

        let summon_bb = move_result.special_bbs.summon.0;
        let summon_piece = move_result.special_bbs.summon.1 as u3;
        // dep::std::println(f"summon_bb: {summon_bb}, {summon_piece}"); // TODO: Uncomment later.
        // TODO: PR cannot print global constants.
        // dep::std::println(f"piece_offset: {PIECE_OFFSET}");

        // dep::std::println(f"to_bb?: {to_bb}");

        // Since we don't take an input of the type of piece captured we need to
        //   execute this for every piece bitboard.
        let mut is_capture = false;
        for bb_idx in BitboardOf::KNIGHT..BitboardOf::PAWN + 1 {
            let current_bb = new_bbs[bb_idx];
            // dep::std::println(f"current bb: {current_bb}");

            // if ((bb_idx != piece as u4) & (new_bbs[bb_idx] & to_bb) > 0) {
            if ((new_bbs[bb_idx] & to_bb) > 0) {
                // Captured piece.
                new_bbs[bb_idx] ^= to_bb;
                // dep::std::println(f"wat: {to_bb}");
                is_capture = true;
            }
        }

        // dep::std::println(f"is capture?: {is_capture}");

        // Piece that did the moving.
        new_bbs[piece] ^= update_piece_bb ^ ep_capture_bb;

        new_bbs[summon_piece + PIECE_OFFSET] |= summon_bb;
        new_bbs[army] ^= (update_piece_bb | summon_bb);
        new_bbs[!army] ^= ep_capture_bb | if is_capture { to_bb } else { 0 };

        // dep::std::println(f"new_bbs: {new_bbs}");

        // ---------

        // Workaround for the panic.
        // let army3 = army as u3;
        // let enemy3 = (!army) as u3;

        // let special_remove_bb = move_result.special_bbs.remove;

        // Good for quiet moves.
        // let update_piece_mask = from_bb ^ to_bb ^ special_remove_bb;
        // dep::std::println(f"update_piece_mask: {update_piece_mask}");

        // let ep_capture_bb = move_result.ep_capture_bb.unwrap_or(0);
        // dep::std::println(f"update_capture_bb: {ep_capture_bb}");

        // let summon_mask = move_result.special_bbs.summon.0;
        // let summon_piece = move_result.special_bbs.summon.1;
        // dep::std::println(f"summon_mask: {summon_mask}");

        // let mut new_bbs = [0 as Bitboard; REQUIRED_BITBOARDS];
        // for i in 0 .. REQUIRED_BITBOARDS {
        //     let idx3 = i as u3;

        //     if (idx3 == piece) {
        //         dep::std::println("hit one");
        //         new_bbs[i] = (self.bbs[i] ^ update_piece_bb ^ ep_capture_bb) | summon_bb;
        //     } else if (idx3 == army3) {
        //         dep::std::println("hit two");
        //         new_bbs[i] = (self.bbs[i] ^ update_piece_bb) | summon_bb;
        //     } else if (idx3 == enemy3) {
        //         dep::std::println("hit three");
        //         new_bbs[i] = self.bbs[i] ^ ep_capture_bb;
        //     } else {
        //         dep::std::println("hit four");
        //         new_bbs[i] = self.bbs[i];
        //     }
        // }
        // dep::std::println(new_bbs);
        // End ugly workaround.

        // `fullmove` is incremented after black's turn.
        let fullmove = self.fullmove + if army == Player::BLACK { 1 } else { 0 };


        // TODO: Update castle rights.

        let mut new_board = Game {
            bbs: new_bbs,
            army: !army,
            castle_rights: self.castle_rights,
            en_passant: move_result.en_passant.unwrap_or(0),
            halfmove: self.halfmove,
            fullmove: fullmove
        };

        new_board
    }
}
