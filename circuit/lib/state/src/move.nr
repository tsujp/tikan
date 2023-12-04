use dep::std::{println, wrapping_add, wrapping_mul, wrapping_sub};
use dep::util::bit_logic as bl;
use crate::types::{Bitboard, BitboardIndex, Move, Game, Turn, Piece, Sliding};
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
            piece: turn.piece + 2, // Offset to types.nr::BitboardOf
            from_bb: 0 as Bitboard | 1 << tf,
            to_bb: 0 as Bitboard | 1 << tt
        }
    }
}

// Returns arguments for `valid_rank_move` for the given file.
// To get a file as a rank the board must be rotated 90 degrees clockwise.
fn file_as_rank(from_idx6: u6, to_idx6: u6, file_idx3: u3, us: Bitboard, them: Bitboard) -> (u6, u64, u6, u64, u64, u64) {
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
fn collapse_diag(from_bb: Bitboard, to_bb: Bitboard, us_occ_bb: Bitboard, them_occ_bb: Bitboard) -> (Bitboard, Bitboard, Bitboard, Bitboard) {
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

// To be returned from all `PIECE_legal` functions (common interface), only
//   some have data we actually care about updating however.
// struct MoveDelta {
//     special_bb: Bitboard,
//     en_passant: BitboardIndex,
// }

// TODO: Continue `game.nr` refactoring. Want to get that big if-statement to
// 1. if pawn
// 2. else if knight
// 3. compute sliding move mask (since all remaining pieces are sliders)
// 4. if king restrict that mask to 1 taxicab distance about the king

// fn pawn_legal(d: Data) {
//     // Universal shift offset (only applies when black moves).
//     // TODO: u64 back to Bitboard when `nargo fmt` plain:: bug fixed.
//     let dir = (d.game.army as u64) << 4;

//     let mut en_passant: BitboardIndex = 0;

//     let mut moves = if (bb::PAWN_START_RANKS[d.game.army] & d.from_bb) > 0 {
//         // Double push, mark ourselves as an en-passant target.
//         // TODO: Shift by direction, needs to be square BEHIND so we can
//         // use one simple lookup by index. Current Jordan to past Jordan.. what? Look at this later on.
//         en_passant = d.turn.to;

//         // Double push first move; generalised shift.
//         let __tmp = (d.from_bb << 8) >> dir;
//         __tmp | (__tmp << 8) >> dir
//     } else {
//         // Single push first move; generalised shift.
//         (d.from_bb << 8) >> dir
//     };

//     // File mask of pawn.
//     let file = bb::A_FILE * (1 << (d.from_idx64 & 7));

//     // Mask of pieces in current file, pawns can only capture diagonally
//     //   so exclude these squares from our push options (if they so
//     //   happen to intersect).
//     let same_file_blockers = (self.bbs[army] | self.bbs[!army]) & file;
//     moves &= !same_file_blockers;

//     // En passant target.
//     let ep = (1 << self.en_passant as plain::Bitboard);

//     // Mask of legal diagonal movements (because an enemy piece lets
//     //   us capture); this does not include en passant.
//     let diags = (((5 << from_idx - 1) << 8) >> dir) & self.bbs[!army];
//     moves |= (diags | ep);

//     // let foo_bb = ep_bb;
//     // to_bb = ep_bb;

//     // println(f"k-0xFF k-{from_bb} k-{moves} k-{same_file_blockers} k-{ep} k-{diags} k-{foo_bb} k-0x00 k-0x00");
//     // println(f"k-0x0");

//     assert(bl::is_bit_set(moves, to_idx), "PAWN move is INVALID");

//     // The (at this point) valid move was an en passant capture, need
//     //   to set the capture bitboard with the correct index.
//     if (move.to == self.en_passant) {
//         // println("was an ep capture");
//         let ep_bb = (ep >> 8) << dir;
//         special_bb = ep_bb;
//     }
// }

// ---------------------------------------------------------------------------
// ---------------------------------------------- PIECE LEGAL CHECKS

fn knight_legal(d: Data) {
    // Product of absolute difference between rank/file of to/from squares must
    //   be 2 for the move to be valid.
    let r1 = bl::rank_idx_6_6(d.turn.from);
    let r2 = bl::rank_idx_6_6(d.turn.to);

    let f1 = bl::file_idx_6_6(d.turn.from);
    let f2 = bl::file_idx_6_6(d.turn.to);

    assert((bl::abs_6(r1, r2) as u12 * bl::abs_6(f1, f2) as u12) == 2, "KNIGHT move PATTERN");

    // As well as not landing on a friendly piece.
    let friendlies = d.game.bbs[d.game.army];
    assert((friendlies & d.to_bb) == 0, "KNIGHT move BLOCKED");
}

fn rank_legal(from_idx6: BitboardIndex, from_bb: Bitboard, to_bb: Bitboard, us: Bitboard, them: Bitboard) -> bool {
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

impl Move {
    // Assert move is good, return optional special_bb data to XOR.
    pub fn check_legal(game: Game, turn: Turn) -> bool {
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

        // Check the move is legal.
        // TODO: Can I treat pawns as a weird bishop / rook and simply restrict the movement based on where it's moving to? I think I can and then I can reuse the sliding logic I already have.
        // if turn.piece == Piece::PAWN {
        //     pawn_legal(in_data);
        // }
        if turn.piece == Piece::KNIGHT {
            knight_legal(in_data);
        } else {
            let (direction, rankified_data) = rankified_sliding_data(in_data);

            // If absolute difference between rankified to/from indices is
            //   greater than 1 it's invalid.
            if turn.piece == Piece::KING {
                // TODO: Put the `to` here in rankified data also?
                // TODO: Take out `to`? Adds a lot of gates and is only needed
                //       in this condition.
                let abs_diff = bl::abs_6(rankified_data.from, rankified_data.to);

                // King tried to move more than 1 square.
                let king_bad = !(abs_diff > 1);

                // ... XXX [1] (10 gates).
                if direction == Sliding::VERTICAL {
                    assert(king_bad, "KING move VERTICAL PATTERN");
                } else if direction == Sliding::HORIZONTAL {
                    assert(king_bad, "KING move HORIZONTAL PATTERN");
                } else if direction == Sliding::DIAGONAL {
                    assert(king_bad, "KING move DIAGONAL PATTERN");
                } else if direction == Sliding::ANTI_DIAGONAL {
                    assert(king_bad, "KING move ANTI DIAGONAL PATTERN");
                }
            }

            let is_valid = rank_legal(rankified_data.from, rankified_data.from_bb, rankified_data.to_bb, rankified_data.us, rankified_data.them);

            // ... XXX [1] (10 gates).
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

        true
    }

    // XXX: Having to put tests in another file requires I make this `pub` to test it. Yuck. Should be able to put unit tests in the same file and EASILY be able to run them.
    pub fn TEST_ONLY_rankified_sliding_data(game: Game, turn: Turn) -> (u3, RankifiedTurn) {
        rankified_sliding_data(Data::init(game, turn))
    }
}
