use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::lib::{Piece, Board, Move};

fn main (
  // Player turn inputs.
  cur_board: pub Board, // As claimed by player.
  pst_board: pub Board, // As claimed by player.
  move: Move,
  state_commitment: pub PedersenPoint
) {
  let move_hash = pedersen_hash(move.decompose());
  let pst_board_hash = pedersen_hash(pst_board.decompose());

  // `.apply_move()` constrains `move` validity againt the given `cur_board`. So things
  //   like how the piece is moving, whether a capture is legal and so on. It is assumed
  //   that there is in-fact only a single way to go from valid `cur_board` state to
  //   `pst_board` state in a single valid `move` hence we do not need a commitment
  //   to `cur_board` as a commitment involving `move` and `pst_board` (what
  //   `state_commitment` is) implicitly provides that so long as our assumption holds.
  //
  // XXX: Probably in the realm of information theory but I am pretty sure that there IS
  //      only one way to transition between two game-states (nodes) in the rules of
  //      Chess when you can only do so along one edge. There's probably a name for this
  //      type of graph.
  let real_pst_board = cur_board.apply_move(move);

  // Real and claimed post-move board match. Since `pst_board` is public input to this
  //   circuit if this verifies we can trust that public input `pst_board` is now
  //   the `cur_board` for the subsequent players' turn.
  let real_pst_board_hash = pedersen_hash(real_pst_board.decompose());
  assert(real_pst_board_hash == pst_board_hash);

  // TODO: Haven't we done this in-part above? Hmmm.
  // We also need to check that the players' move was in-fact against the `cur_board`
  //   and produced the `pst_board`.
  let computed_commitment = pedersen_commitment([move_hash, real_pst_board_hash]);

  assert(computed_commitment.x == state_commitment.x, "Bad commitment x");
  assert(computed_commitment.y == state_commitment.y, "Bad commitment y");
}













// fn main(
//     verification_key : [Field; 114],
//     proof : [Field; 94],
//     public_inputs : [Field; 1],
//     key_hash : Field,
//     input_aggregation_object : [Field; 16],
//     proof_b : [Field; 94],
// ) -> pub [Field; 16] {
//     let output_aggregation_object_a = std::verify_proof(
//         verification_key.as_slice(),
//         proof.as_slice(),
//         public_inputs.as_slice(),
//         key_hash,
//         input_aggregation_object
//     );

//     let output_aggregation_object = std::verify_proof(
//         verification_key.as_slice(),
//         proof_b.as_slice(),
//         public_inputs.as_slice(),
//         key_hash,
//         output_aggregation_object_a
//     );

//     let mut output = [0; 16];
//     for i in 0..16 {
//         output[i] = output_aggregation_object[i];
//     }
//     output
// }
