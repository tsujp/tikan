// Commitment helpers.

// --------------------------------------------------------------
// --------------------------------------------------------------
// V1
use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::lib::{Piece, Board, Move, SerialisedStateIn, SerialisedMove};
use dep::std::ec::consts::te::baby_jubjub;
use dep::std::hash::poseidon2::Poseidon2 as poseidon2;

struct State {
  cur_state_serial: SerialisedStateIn,
  cur_move_serial: SerialisedMove,
  secret: Field,
}

struct Input {
  state: Option<State>
}

struct Output {
  state_commitment: Option<(Field, Field, Board)>
}

// Commitment that `move` produces post-move board state `pst_board`.
fn state_commitment(state: State) -> (Field, Field, Board) {
  let cur_board = Board::deserialise(state.cur_state_serial);
  let move = Move::deserialise(state.cur_move_serial);

  let pst_board = cur_board.apply_move(move);

  // TODO: Should these hashes also be `commitment` or is only the final one
  //       being a `commitment` enough? Here and elsewhere.
  // let move_hash = pedersen_hash(state.move.decompose());
  // let pst_board_hash = pedersen_hash(pst_board.decompose());

  // TODO: Take a salt.
  // let move_serial_arr = move.serialise().as_fields();
  let mut commit_to: BoundedVec<Field, 7> = BoundedVec::new();
  commit_to.extend_from_array(move.serialise().as_fields());
  commit_to.push(state.secret);

  let commitment = poseidon2::hash(commit_to.storage(), 7);
  dep::std::println(f"MOVE HASH IS: {commitment}");

  // Why bjj.base8?
  let bjj = baby_jubjub();
  let pubkey = bjj.curve.mul(state.secret, bjj.base8);

  // println(pubkey.x);
  // println(pubkey.y);

  // Why?
  let identity = poseidon2::hash([commitment, pubkey.x, pubkey.y], 3);

  // (pedersen_commitment([move_hash, pst_board_hash]), pst_board)
  (commitment, identity, pst_board)
}

// TODO: Add salt later.
fn main(input: Input) -> pub Output {
  let mut output = Output {
    state_commitment: Option::none()
  };

  if input.state.is_some() {
    output.state_commitment = Option::some(
      state_commitment(input.state.unwrap_unchecked())
    );
  }

  output
}
// END V1
