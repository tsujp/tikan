// Commitment helpers.

// --------------------------------------------------------------
// --------------------------------------------------------------
// V1
use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::lib::{Piece, Board, Move};

struct State {
  cur_board: Board,
  move: Move,
}

struct Input {
  state: Option<State>
}

struct Output {
  state_commitment: Option<(PedersenPoint, Board)>
}

// Commitment that `move` produces post-move board state `pst_board`.
fn state_commitment(state: State) -> (PedersenPoint, Board) {
  let pst_board = state.cur_board.apply_move(state.move);

  // TODO: Should these hashes also be `commitment` or is only the final one
  //       being a `commitment` enough? Here and elsewhere.
  let move_hash = pedersen_hash(state.move.decompose());
  let pst_board_hash = pedersen_hash(pst_board.decompose());

  (pedersen_commitment([move_hash, pst_board_hash]), pst_board)
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
