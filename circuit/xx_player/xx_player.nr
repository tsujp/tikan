use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::lib::{Piece, Board, Move};

fn main (
  // Player turn inputs.
  board: pub Board,
  move: Move,
  state_commitment: pub PedersenPoint
) {
  dep::std::println("hello!!!!!");
  let move_hash = pedersen_hash(move.decompose());
  let new_board = board.apply_move(move);
  let new_board_hash = pedersen_hash(new_board.decompose());
  let computed_commitment = pedersen_commitment([move_hash, new_board_hash]);

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
