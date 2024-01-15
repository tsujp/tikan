use dep::std::{println, wrapping_add, wrapping_mul, wrapping_sub};
use dep::std::option::Option;
use dep::util::bit_logic as bl;
use crate::types::{Bitboard, BitboardIndex, BitboardOf, Move, Game, Turn, Piece, Player, Sliding, MoveResult, SpecialBbs, PIECE_OFFSET};
use crate::bitboards as bb;

//
// Move validation and output special bitboard state.
//

// XXX HERE
// Validate a move as the big if statement stuff in `game.nr` (previously `board.nr`) does but do not return any bitboard masking stuff for special shit e.g. pawn en-passant captures. Instead return an Option poor mans enum which `game.nr` will if over to construct the special mask there. Seperation of concerns and all that.

// XXX [1]
//   Due to limitations with `assert` error messages (only literals) and for
//     test discrimination over how a move is being interpreted a bunch of `if`
//     statements are added purely to provide different assert messages to check
//     in said tests (that a move is failing on the correct path). When `assert`
//     supports templated strings all those `if` statements can be removed.

// ---------------------------------------------------------------------------

// When rankified white pawns starting index (from which they can double-push)
//   is always 1 and black's is always 6.
// `BitboardIndex` as we need to compare it to the rankified value which is this
//   type.
// global PAWN_START_RANKIFIED: [BitboardIndex; 2] = [1, 6];

// // Similarly the promotion ranks when rankified for white and black are 7 and 0.
// global PAWN_PROMOTION_RANKIFIED: [BitboardIndex; 2] = [7, 0];

// ---------------------------------------------------------------------------

// Hacky-ish way to make the interface to each piece-type's validation function
//   less brittle / verbose.
// OPT: A way to improve that in future?
struct Data {
    game: Game,
    turn: Turn,
    from_idx64: Bitboard,
    to_idx64: Bitboard,
    piece: u3,
    from_bb: Bitboard,
    to_bb: Bitboard
}

impl Data {
    pub fn init(game: Game, turn: Turn) -> Self {
        let tf = turn.from as Bitboard;
        let tt = turn.to as Bitboard;

        Self {
            game: game,
            turn: turn,
            from_idx64: tf,
            to_idx64: tt,
            piece: turn.piece + PIECE_OFFSET, // Offset to types.nr::BitboardOf
            from_bb: 0 as Bitboard | 1 << tf,
            to_bb: 0 as Bitboard | 1 << tt
        }
    }
}

// Returns arguments for `valid_rank_move` for the given file.
// To get a file as a rank the board must be rotated 90 degrees clockwise.
fn file_as_rank(
    from_idx6: u6,
    to_idx6: u6,
    file_idx3: u3,
    us: Bitboard,
    them: Bitboard
) -> (u6, u64, u6, u64, u64, u64) {
    let file_mask64 = bb::A_FILE * (1 << file_idx3 as u64);
    let file_shift64 = 7 - file_idx3;

    // Multiplying the H file by the shifted anti-diagonal bitboard moves the
    //   H-file bits (in the same order in terms of bitwise significance) to
    //   the 8th rank (north-edge of the board).
    // Shifting the 8th rank 56 places to the right moves it to the 1st rank.
    let us_bb8 = wrapping_mul(
        bb::SHIFTED_ANTI_DIAGONAL,
        // only our pieces    // shift to H file
        (file_mask64 & us) << (file_shift64 as u64)
    )
        >> 56;

    let them_bb8 = wrapping_mul(
        bb::SHIFTED_ANTI_DIAGONAL,
        (file_mask64 & them) << (file_shift64 as u64)
    )
        >> 56;

    let from_idx3 = bl::rank_idx_6_3(from_idx6) as u6;
    let from_bb = 1 << (from_idx3 as u64);
    let to_bb = 1 << (bl::rank_idx_6_3(to_idx6) as u64);

    // To index is rank index when rotated 90-deg cw.
    let to_idx3 = bl::rank_idx_6_3(to_idx6) as u6;

    (from_idx3, from_bb, to_idx3, to_bb, us_bb8, them_bb8)
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- ANYTHING TO RANK

//
fn collapse_diag(
    from_bb: Bitboard,
    to_bb: Bitboard,
    us_occ_bb: Bitboard,
    them_occ_bb: Bitboard
) -> (Bitboard, Bitboard, Bitboard, Bitboard) {
    (
        bl::collapse_diagonal_to_rank_64_8(from_bb) as u64, bl::collapse_diagonal_to_rank_64_8(to_bb) as u64, bl::collapse_diagonal_to_rank_64_8(us_occ_bb) as u64, bl::collapse_diagonal_to_rank_64_8(them_occ_bb) as u64
    )
}

// TODO: `Bitboard` here can all be u8 (for a single rank) and `BitboardIndex` a u3. That requires the valid rank function to take uniform data so do it after that.
struct RankifiedTurn {
    from: BitboardIndex,
    from_bb: Bitboard,
    to: BitboardIndex,
    to_bb: Bitboard,
    us: Bitboard,
    them: Bitboard
}

impl RankifiedTurn {
    pub fn init(from: BitboardIndex, from_bb: Bitboard, to: BitboardIndex, to_bb: Bitboard, us: Bitboard, them: Bitboard) -> Self {
        Self {
            from,
            from_bb,
            to,
            to_bb,
            us,
            them
        }
    }
}

// Determine whether a move is horizontal, vertical, diagonal, or anti-diagonal
//   and then transforms the move into a rank-equivalent (for feeding into
//   `valid_rank_move`).
fn rankified_sliding_data(d: Data) -> (u3, RankifiedTurn) {
    let us = d.game.bbs[d.game.army];
    let them = d.game.bbs[!d.game.army];

    // TODO: `let mut transposed` at the top cheaper or more expensive gate wise?
    // let mut turn_data: (u3, RankifiedTurn) = (7, RankifiedTurn::init());

    if (bl::on_same_rank(d.turn.from, d.turn.to)) {
        // HORIZONTAL MOVE if the rank indices are the same.
        // TODO: Reduce this to first rank.
        (
            Sliding::HORIZONTAL, RankifiedTurn::init(d.turn.from, d.from_bb, d.turn.to, d.to_bb, us, them)
        )
    } else if (bl::on_same_file(d.turn.from, d.turn.to)) {
        // VERTICAL MOVE if file indices are the same.
        let f = file_as_rank(d.turn.from, d.turn.to, bl::file_idx_6_3(d.turn.to), us, them);

        (Sliding::VERTICAL, RankifiedTurn::init(f.0, f.1, f.2, f.3, f.4, f.5))
    } else {
        let (dir, mask) = if (bl::on_same_diagonal(d.turn.from, d.turn.to)) {
            // DIAGONAL MOVE.
            (Sliding::DIAGONAL, bl::diagonal_mask_64(d.from_bb))
        } else if (bl::on_same_anti_diagonal(d.turn.from, d.turn.to)) {
            // ANTI-DIAGONAL MOVE.
            (Sliding::ANTI_DIAGONAL, bl::anti_diagonal_mask_64(d.from_bb))
        } else {
            // I dislike that it has to be this way. Use a better pattern here.
            (1, 337)
        };

        // Yuck.
        if ((dir == 1) & (mask == 337)) {
            assert(false, "SLIDER move PATTERN");
        }

        let c = collapse_diag(d.from_bb, d.to_bb, us & mask, them & mask);

        // TODO: Wait why is it this and not rank?
        let c_from_idx = bl::file_idx_6_6(d.turn.from);
        let c_to_idx = bl::file_idx_6_6(d.turn.to);

        (dir, RankifiedTurn::init(c_from_idx, c.0, c_to_idx, c.1, c.2, c.3))
    }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- PIECE LEGAL CHECKS

// Knight legal movement.
fn knight_legal(d: Data) {
    // Product of absolute difference between rank/file of to/from squares must
    //   be 2 for the move to be valid.
    let r1 = bl::rank_idx_6_6(d.turn.from);
    let r2 = bl::rank_idx_6_6(d.turn.to);

    let f1 = bl::file_idx_6_6(d.turn.from);
    let f2 = bl::file_idx_6_6(d.turn.to);

    assert((bl::abs_6(r1, r2) as u12 * bl::abs_6(f1, f2) as u12) == 2, "KNIGHT move PATTERN");

    // TODO: When rewritten to arrays this part can become a simpler index
    //       check without having to use bit-logic.
    assert(bl::is_bit_set(d.game.bbs[BitboardOf::FOG], d.turn.to as u64), "KNIGHT move FOG");

    // As well as not landing on a friendly piece.
    let friendlies = d.game.bbs[d.game.army];
    assert((friendlies & d.to_bb) == 0, "KNIGHT move BLOCKED");
}

// Restricts a king to 1-chebyshev distance movement.
fn king_pre_legal(direction: u3, rankified_turn: RankifiedTurn) {
    // TODO: Take out `to`? Adds a lot of gates and is only needed
    //       in this condition.
    let abs_diff = bl::abs_6(rankified_turn.from, rankified_turn.to);

    // If absolute difference between rankified to/from indices is >1 then bad.
    let king_good = abs_diff == 1;

    // ... XXX [1] (10 gates).
    { // For folding.
        if direction == Sliding::VERTICAL {
            assert(king_good, "KING move VERTICAL PATTERN");
        } else if direction == Sliding::HORIZONTAL {
            assert(king_good, "KING move HORIZONTAL PATTERN");
        } else if direction == Sliding::DIAGONAL {
            assert(king_good, "KING move DIAGONAL PATTERN");
        } else if direction == Sliding::ANTI_DIAGONAL {
            assert(king_good, "KING move ANTI DIAGONAL PATTERN");
        }
    }
}

// Pawn legal movement.
//   1. Can only move diagonally once if there is an enemy piece at the target.
//   2. En-passant captures, and target setting for double-pushed pawns.
//   3. Double-push validation (i.e. only from that pawns home rank).
//   4. Promotions.
fn pawn_legal(d: Data, direction: u3, rankified_turn: RankifiedTurn, move_result: &mut MoveResult) {
    let player_white = d.game.army == Player::WHITE;

    let correct_direction = if (player_white) {
        bl::rank_idx_6_6(d.turn.to) > bl::rank_idx_6_6(d.turn.from)
    } else {
        bl::rank_idx_6_6(d.turn.to) < bl::rank_idx_6_6(d.turn.from)
    };

    let from_home_rank = (bb::PAWN_START_RANKS[d.game.army] & d.from_bb) > 0;
    let abs_diff = bl::abs_6(rankified_turn.from, rankified_turn.to);

    assert(direction != Sliding::HORIZONTAL, "PAWN move HORIZONTAL PATTERN");
    assert(correct_direction, "PAWN move DIRECTION PATTERN");

    // Even though captures and en-passant is diag-only we need these after
    //   pattern validation so lift them here rather than `mut` everything.

    // Possibly valid en-passant capture (as long as only 1 square away).
    let is_en_passant = d.turn.to == d.game.en_passant;

    // Otherwise can only capture diagonally if enemy occupies to square.
    let is_enemy_present = (d.to_bb & d.game.bbs[!d.game.army]) > 0;

    // A capture is only valid if an enemy occupies the target square, or if
    //   the target square is empty if said square is the en-passant target
    //   and finally in both cases where the move is only of 1-chebyshev distance.
    let valid_capture = (abs_diff == 1) & (is_enemy_present | is_en_passant);

    if direction == Sliding::VERTICAL {
        // No multi-pushes unless specifically a double-push IFF from pawns home rank.
        if ((abs_diff == 2) & from_home_rank) {
            // Legal to double-push; en-passant target is square behind the
            //   just double-pushed pawn.
            let square_behind = if (player_white) {
                d.turn.to - 8
            } else {
                d.turn.to + 8
            };
            move_result.en_passant = Option::some(square_behind);
        } else if (abs_diff > 1) {
            // Illegal double (maybe-multi) push (not from home rank).
            assert(false, "PAWN move MULTI-PUSH PATTERN");
        }
        // Later calls to `rank_legal` will determine if the pawn is blocked.
    } else if (direction == Sliding::DIAGONAL) | (direction == Sliding::ANTI_DIAGONAL) {
        // Like elsewhere this is organised in such a satanic way because we want
        //   to test things fail in a certain way and need the string literals
        //   in the right place.
        if (is_en_passant) {
            if (direction == Sliding::DIAGONAL) {
                assert(valid_capture, "PAWN special move DIAGONAL EN-PASSANT PATTERN");
            } else {
                assert(valid_capture, "PAWN special move ANTI-DIAGONAL EN-PASSANT PATTERN");
            }
            // Valid en-passant capture, set ep_capture_bb for correct piece capture XORing.
            let sq = if (player_white) {
                d.turn.to - 8
            } else {
                d.turn.to + 8
            };

            let sq_ahead = 1 << (sq as u64);

            move_result.ep_capture_bb = Option::some(sq_ahead);
        } else if (direction == Sliding::DIAGONAL) {
            assert(valid_capture, "PAWN move DIAGONAL CAPTURE PATTERN");
        } else {
            assert(valid_capture, "PAWN move ANTI-DIAGONAL CAPTURE PATTERN");
        }
    }

    // At this point the move is valid save for the final promotion check here.
    let at_promotion_rank = (bb::PAWN_END_RANKS[d.game.army] & d.to_bb) > 0;
    // println(f"promotion?: {at_promotion_rank}");

    // Don't need to check that `promotion_piece` is set because it must be for
    //   the circuit to even execute to here (cannot provide a null input for
    //   a u2).
    if (at_promotion_rank) {
        let blah = d.to_bb;
        println(f"to_bb: {blah}");
        // Promoted pawns get removed, for our purposes a "self-capture".
        move_result.special_bbs.remove = d.to_bb;
        move_result.special_bbs.summon = (d.to_bb, d.turn.promotion_piece);
        // The promoted piece is added. Promoted pieces do not have to have been
        //   previously captured (standard rule).
        //
    }
}

// Generalised rank movement validation for typical sliders. All pieces except
//   knights are considered sliders however pawns and kings have their own
//   special pre-checks due to their altered movement (in addition to calling
//   this function afterwards).
fn rank_legal(
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

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE

// I hate how much nesting is here.
impl Move {
    // Assert move is good, return optional special_bb data to XOR.
    pub fn check_legal(game: Game, turn: Turn) -> MoveResult {
        // Check piece actually exists.
        assert(
            // See `XXX [420]` for magic number 2.
            bl::is_bit_set(
                game.bbs[game.army] & game.bbs[turn.piece + 2],
                turn.from as Bitboard
            ),
           "Piece in army does NOT EXIST at given index"
        );

        // Check there's an actual move delta.
        assert(turn.from != turn.to, "Cannot move onto your own square in the same turn");

        // Helper-deduplication / convenient data-container.
        let in_data = Data::init(game, turn);

        let mut move_result = MoveResult {
            en_passant: Option::none(),
            ep_capture_bb: Option::none(),
            special_bbs: SpecialBbs {
                remove: 0,
                summon: (0, 0),
            },
        };

        // Knights are the only purely pattern-moving pieces.
        if turn.piece == Piece::KNIGHT {
            knight_legal(in_data);
        // Pawns are sliders but have such heavily restricted movement patterns
        //   it's not worth generalising them so they too have their own checks.
        } else if turn.piece == Piece::PAWN {
            let (direction, rankified_turn) = rankified_sliding_data(in_data);
            pawn_legal(in_data, direction, rankified_turn, &mut move_result);
        // Everything else is a generalise-able slider.
        } else {
            let (direction, rankified_turn) = rankified_sliding_data(in_data);

            // Kings can only move 1-chebyshev distance at a time.
            if turn.piece == Piece::KING { king_pre_legal(direction, rankified_turn); }

            let is_valid = rank_legal(rankified_turn.from, rankified_turn.from_bb, rankified_turn.to_bb, rankified_turn.us, rankified_turn.them);

            // ... XXX [1] (10 gates).
            { // For folding.
                if direction == Sliding::VERTICAL {
                    assert(is_valid, "SLIDER move VERTICAL BLOCKED");
                } else if direction == Sliding::HORIZONTAL {
                    assert(is_valid, "SLIDER move HORIZONTAL BLOCKED");
                } else if direction == Sliding::DIAGONAL {
                    assert(is_valid, "SLIDER move DIAGONAL BLOCKED");
                } else if direction == Sliding::ANTI_DIAGONAL {
                    assert(is_valid, "SLIDER move ANTI DIAGONAL BLOCKED");
                }
            }
        }

        move_result
    }

    // XXX: Having to put tests in another file requires I make this `pub` to test it. Yuck. Should be able to put unit tests in the same file and EASILY be able to run them.
    pub fn TEST_ONLY_rankified_sliding_data(game: Game, turn: Turn) -> (u3, RankifiedTurn) {
        rankified_sliding_data(Data::init(game, turn))
    }
}
