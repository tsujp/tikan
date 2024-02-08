// Commitment helpers.

// --------------------------------------------------------------
// --------------------------------------------------------------
// V1
use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::lib::{Piece, Board, Move};

struct State {
  board: Board,
  move: Move,
}

struct Input {
  state: Option<State>
}

struct Output {
  state_commitment: Option<PedersenPoint>
}

// Commitment for post-move board state.
fn state_commitment(state: State) -> PedersenPoint {
  // TODO: Should these hashes also be `commitment` or is only the final one
  //       being a `commitment` enough?
  // let current_board_hash = pedersen_hash(state.board.decompose());
  let move_hash = pedersen_hash(state.move.decompose());
  let new_board_hash = pedersen_hash(state.board.apply_move(state.move).decompose());

  pedersen_commitment([move_hash, new_board_hash])
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
