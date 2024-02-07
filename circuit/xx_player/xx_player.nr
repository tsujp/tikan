// struct Square {
//   fog: bool, // Whether square is in fog.
//   lit_by: u2, // Which player (might be) illuminating the square. 0 = white, 1 = black, 3 = no one.
// }

use dep::lib::{Piece, Board, Move};

// Q: Can I execute the turn logic and then recursive verify the prior proof and output
//      the aggregation object and the new board state?

#[recursive]
fn main (
  // Recursive proof.
  verification_key : [Field; 114], // Vk.
  proof : [Field; 93], // Proof to be verified.
  public_inputs : [Field; 7], // Public inputs to the proof-to-be-verified.
  key_hash : Field, // Vk hash.
  //
  // Player turn inputs.
  board: pub Board,
  move: Move
) -> pub Field {
  // At the start of the game the `proof` is the one from `xx_start_proof`. Since
  //   the start of the game is the first aggregation the input aggregation will
  //   be completely zeroed.
  dep::std::verify_proof(
    verification_key.as_slice(),
    proof.as_slice(),
    public_inputs.as_slice(),
    key_hash
  );

  // The only piece in this game (all pieces are the same type) can move omnidirectionally
  //   one square only.
  // Compute absolute difference movement of file and rank.
  let file_diff = if move.from_file > move.to_file { move.from_file - move.to_file } else { move.to_file - move.from_file };
  let rank_diff = if move.from_rank > move.to_rank { move.from_rank - move.to_rank } else { move.to_rank - move.from_rank };

  // Move is valid if at most 1 square in all axes is traversed.
  assert((file_diff <= 1) & (rank_diff <= 1), "Illegal move pattern");

  // New commitment from player moving on the board?

  // let new_board = Board {
  //   white: board.white,
  //   black: board.black,
  //   turn: !board.turn
  // };

  // new_board
  420
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
