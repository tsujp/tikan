use dep::std::println;

use dep::std::collections::vec::Vec;

use crate::types::{Bitboard, BitboardIndex, REQUIRED_BITBOARDS, BitboardOf, Player, Piece};
use dep::util::utility::{assert_u64, assert_u6, assert_u4, assert_u1};
use crate::move::{Move, knight_moves};

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

// global WHITE_PAWN_RANK: Bitboard = 0xFF00;
// global BLACK_PAWN_RANK: Bitboard = 0xFF000000000000;


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


// Checks that given occupancy has a bit of value 1 (set) at given LERLEF
//   index. Occupancy is a bitboard mask.
fn is_bit_set(occupancy: Bitboard, idx: Bitboard) -> bool {
    ((occupancy >> idx) & 1) as bool
}


// TODO: What happens when a function is called with invalid input in a compiled circuit? So far I know that:
//   (1) Currently when used within Noir (i.e. as an API)
//       there is no type validation (GH #3227).
//   (2) If used as circuit input via Prover.toml the type
//       is validated and range-checked (unlike #3227).
//   (3) Now what about a scenario similar to (2) but via
//       bb.js? If I provide a >64-bit value will it error
//       as in (2) or must I still do manual checks?
// XXX: For now, assume that (3) functions like (2).

global PAWN_START_RANKS: [Bitboard; 2] = [
    0xFF00,
    0xFF000000000000
];

global NOT_8_RANK: u64 = 0x00ffffffffffffff;
global NOT_1_RANK: u64 = 0xffffffffffffff00;

global A_FILE: u64 = 0x0101010101010101;
global NOT_A_FILE: u64 = 0xfefefefefefefefe;
global NOT_H_FILE: u64 = 0x7f7f7f7f7f7f7f7f;


// TODO: Put these elsewhere.
fn ms1b(b: Bitboard) -> Bitboard {
    // if (b == 0) {
    //     0
    // } else {
        let mut idx = b;
        idx |= idx >> 32;
        idx |= idx >> 16;
        idx |= idx >>  8;
        idx |= idx >>  4;
        idx |= idx >>  2;
        idx |= idx >>  1;

        (idx >> 1) + 1
    // }
}


// Least significant 1-bit is intersection of non-empty bitboard with it's two's
//   complement.
fn ls1b(b: Bitboard) -> Bitboard {
    b & -b
}


fn east_ray(about_idx: Bitboard) -> Bitboard {
    2 * ((1 << (about_idx | 7)) - (1 << about_idx))
}

fn west_ray(about_idx: Bitboard) -> Bitboard {
    (1 << about_idx) - (1 << (about_idx & 56))
}


impl Board {
    fn orthogonal_moves(self, from_idx: Bitboard) -> (Bitboard, Bitboard) {
        let from_bb = 1 as Bitboard << from_idx;

        let rank_mask = (0xff as Bitboard) << (from_idx & 56);
        let file_mask = A_FILE * (1 << (from_idx & 7));

        let rank_occ = self.bbs[!self.army] & rank_mask;

        //
        // RANK MOVES.
        // Ray masks EXCLUDE `from_bb`.
        let e_ray = east_ray(from_idx);
        let w_ray = west_ray(from_idx);

        // West/East moves including closest captureable enemy piece, if any.
        let east_possible = (rank_occ ^ (rank_occ - (2 * from_bb))) & rank_mask;
        let west_possible = w_ray ^ (ms1b(w_ray & self.bbs[!self.army]) - 1) & rank_mask;

        // Mask from end of rank up to (INCLUDING) square of closest friendly
        //   piece east of current position.
        let east_friendly_mask = !(ls1b(e_ray & self.bbs[self.army]) - 1) & rank_mask;

        // Mask from rank start up to (EXCLUDING) square of closest friendly
        //   piece west of current position.
        let west_friendly_mask = (ms1b(w_ray & self.bbs[self.army]) - 1) & rank_mask;

        // Final west/east moveset is the relative complement of the possible
        //   moves and the closest friendly piece mask.
        let east_moves = east_possible & !east_friendly_mask;
        let west_moves = west_possible & !west_friendly_mask;

        let rank_moves = west_moves | east_moves;
        // END RANK MOVES.
        //

        //
        // FILE MOVES.
        // Ray masks EXCLUDE `from_bb`.
        let n_ray = from_bb ^ -from_bb & file_mask;
        let s_ray = from_bb - 1 & file_mask;

        // North/South moves including closest captureable enemy piece, if any.
        let north_possible = ls1b(n_ray & self.bbs[!self.army]);
        let south_possible = ms1b(s_ray & self.bbs[!self.army]);

        // let north_friendly_mask = 0;
        
        let vertical_possible = north_possible ^ (north_possible - (2 * south_possible));
            // & file_mask
            // | south_possible;
        // END FILE MOVES.
        //

        // Working https://www.chessprogramming.org/Flipping_Mirroring_and_Rotating#Flip_about_the_Diagonal flip
        let shifted_anti_diag = 0x02040810204081;
        let col = file_mask & self.bbs[!self.army];
        
        let col_idx = (from_idx & 7);
        let diff = 7 - col_idx;
        let new_col = col << diff;

        let garbage = shifted_anti_diag * new_col;
        let good = garbage >> 56;


        // Reverse a single 8-bit bitboard?

        let reversed = (good * 0x0202020202 as Bitboard & 0x010884422010 as Bitboard) % 0x03ff;

        (good, reversed)

        // (rank_moves, file_moves)
    }

    pub fn validate(self) {
        // TODO: In future this validates state commitment also?
        // TODO: Validate that masks match up. ACTUALLY we can verify the proof from the previous turn since we will hardcode the starting bitboard everything stems from (so long as our hardcoded bb is valid ;) )

        // TODO: Could accept any bbs input if first turn and generate a new `Game` struct with correct starting bb, investigate later.
        // First player-turn of the game.
        if ((self.fullmove == 1) & (self.army == Player::WHITE)) {
            // self.halfmove = 10;
            // // Check starting board is valid.
            // for i in 0 .. REQUIRED_BITBOARDS {
            //     assert(
            //         self.bbs[i] == STARTING_BITBOARDS[i],
            //         "Board pieces are "
            //     );
            // }
            
            println("first turn of game");
        }
        println("board validate called");
    }


    pub fn apply(self, move: Move) -> Board {
        let army = self.army;
        let from_idx = move.from as Bitboard;
        let to_idx = move.to as Bitboard;
        let piece = move.piece + 2;

        let mut en_passant: BitboardIndex = 0;

        assert(
            is_bit_set(
               self.bbs[army] & self.bbs[piece],
               from_idx
            ),
           "Given army does NOT have a piece at expected LERLEF index"
        );

        let from_bb = 0 as Bitboard | 1 << from_idx;
        let to_bb = 0 as Bitboard | 1 << to_idx;

        let mut special_bb = 0 as Bitboard;

        // TODO: Could probably make these accessed by keys to remove if-else
        //       chain, or at least order based on piece move frequencies but
        //       PREMATURE OPTIMISATION so do it later.
        if move.piece == Piece::KNIGHT {
            let moves = knight_moves(from_bb, self.bbs[army]);

            assert(
                is_bit_set(moves, to_idx),
                "KNIGHT move is INVALID either improper move pattern or square is already occupied by a piece on the same team"
            );
        } else if move.piece == Piece::PAWN {
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
                is_bit_set(moves, to_idx),
                "PAWN move is INVALID either improper move pattern or square is already occupied by a piece on the same team"
            );

            // The (at this point) valid move was an en passant capture, need
            //   to set the capture bitboard with the correct index.
            if (move.to == self.en_passant) {
                // println("was an ep capture");
                let ep_bb = (ep >> 8) << dir;
                special_bb = ep_bb;
            }
        } else if move.piece == Piece::ROOK {
            let mut moves = 0;

            // FILE STUFF
            // let a64 = army as Bitboard;

            // let file = A_FILE * (1 << (from_idx & 7));
            // let forward_fill = ((from_bb * A_FILE) ^ (a64 * file) & !(from_bb)) ^ from_bb;

            // let enemies_in_column = self.bbs[!army] & forward_fill;
            // let enemy_pawn = enemies_in_column & -enemies_in_column;
            
            // let ra = enemy_pawn ^ (enemy_pawn - (2 * from_bb));
            // let ra2 = ra & forward_fill;

            // println(f"k-0xFF k-{from_bb} k-{moves} k-{forward_fill} k-{enemy_pawn} k-{ra} k-{ra2} k-0x00 k-0x00");
            // println(f"k-0x0");
            // END FILE STUFF



            // MORE FILE STUFF USEABLE
            let us = self.bbs[army];
            let them = self.bbs[!army];


            // let a64 = army as Bitboard;
            // let not_a64 = (!army) as Bitboard;

            // let file = A_FILE * (1 << (from_idx & 7));
            // let forward_fill = ((from_bb * A_FILE) ^ (a64 * file) & !(from_bb)) ^ from_bb;
            // let asdf2 = ((from_bb * A_FILE) ^ (not_a64 * file) & !(from_bb)) ^ from_bb;

            // // Set all 1s above s1b (s1b = "solo-1-bit", only bit set in board)
            // let ff2 = from_bb ^ -from_bb;

            // // Union that with file mask for current file to get north-fill
            // let nf2 = ff2 & file;

            // let below_s1b = !from_bb & (from_bb - 1);
            // let sf2 = below_s1b & file;

            // let enemies_in_column = self.bbs[!army] & forward_fill;
            // let enemy_pawn = enemies_in_column & -enemies_in_column;
            
            // let ra = enemy_pawn ^ (enemy_pawn - (2 * from_bb));
            // let ra2 = ra & forward_fill;

            // // TODO: nicer way to do this?
            // let occ_below_piece = sf2 & self.bbs[!army];
            // let mut x = occ_below_piece;
            // x |= x >> 32;
            // x |= x >> 16;
            // x |= x >>  8;
            // x |= x >>  4;
            // x |= x >>  2;
            // x |= x >>  1;
            // // let mut msb = (x >> 1) + 1;
            // let mut msb = (x >> 1) + 1;

            
            // let ra4 = enemy_pawn ^ (enemy_pawn - (2 * msb));
            // let ra5 = ra4 & forward_fill;
            // END MORE FILE STUFF USEABLE


            
            // RANK MOVE
            // let r1 = (0xff as Bitboard) << (from_idx & 56);
            // let r1 = (0xff as Bitboard) << from_bb;
            // let r1 = 1 << (from_idx & 56);
            // let one = 1 as Bitboard;
            // let r1 = 2*( (one << (from_idx|7)) - (one << from_idx) ); // East ray.
            // let r1 = (one << from_idx) - (one << (from_idx&56)); // West ray.
            // let r1 = (one << (from_idx&56)); // West ray.


            // let ls1b = one << (from_idx | 7);
            // let _f = 2 as Bitboard;
            // let ls1b = one << (_f | 7);
            // let ls1b = (_f | 7);

            // let last_square_in_row = (_f | 7);

            // let ls1b = last_square_in_row 
            // let ls1b = (one << last_square_in_row) - (one << _f);
            // let ls1b = 2 * ((one << last_square_in_row) - (one << _f));

            // // rank mask
            // let rank_mask = (0xff as Bitboard) << (from_idx & 56);
            // let rank_occ = self.bbs[!army] & rank_mask;

            // let below = from_bb - 1 & rank_mask;
            // let above = below ^ rank_mask ^ from_bb;
            // let above_occ = above & self.bbs[!army];

            // let east_blocker = above_occ & -above_occ;

            // let mut x = self.bbs[!army] & below;
            // x |= x >> 32;
            // x |= x >> 16;
            // x |= x >>  8;
            // x |= x >>  4;
            // x |= x >>  2;
            // x |= x >>  1;
            // // let mut msb = (x >> 1) + 1;
            // let mut west_blocker = (x >> 1) + 1;

            // // let ls1b = 
            

            // // let moves = east_blocker - west_blocker;
            // // let moves = west_blocker ^ (west_blocker - (2 * east_blocker));
            // let moves = (((east_blocker ^ (east_blocker - (2 * west_blocker))) & rank_mask) | west_blocker) ^ from_bb;
            // END RANK MOVE




            // File
            
            // Rank
            let (rank_moves, file_moves) = self.orthogonal_moves(from_idx);

            let moves = rank_moves | file_moves;
            
            // println(f"k-0xFF k-{us} k-{them} k-{from_bb} k-{to_bb} k-{all_bits_below_occ} k-{ra2} k-{nf2} k-{sf2}");
            // println(f"k-0xFF k-{them} k-{forward_fill} k-{ra} k-{occ_below_piece} k-{msb} k-{ra4} k-{ra5} k-0x00");
            // println(f"k-0xFF k-0x00 k-0x00 k-0x00 k-0x00 k-0x00 k-0x00 k-0x00 k-0x00");
            // println(f"k-0xFF k-{us} k-{them} k-{moves} k-{rank_occ} k-{west_blocker} k-{east_blocker} k-{below} k-{above}");
            println(f"k-0xFF k-{us} k-{them} k-{moves} k-{rank_moves} k-{file_moves} k-0x00 k-0x00 k-0x00");
            println(f"k-0x0");
            

            // assert(
            //     is_bit_set(moves, to_idx),
            //     "ROOK move is INVALID either improper move pattern or square is already occupied by a piece on the same team"
            // );
        } else {
            assert(false, "INVALID piece provided");
        };
        
        // let moves = knight_moves(from_bb, self.bbs[army]);

        // println(f"moves: {moves}");

        // assert(
        //     is_bit_set(moves, to_idx),
        //     "Given move is INVALID either improper move pattern or square is already occupied by a piece on the same team"
        // );

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
            is_bit_set(
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
            is_bit_set(moves, to_idx),
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
