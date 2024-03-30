use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};

//
// CORE
//

// OPT: Can use field comparison instead? See: https://github.com/noir-lang/noir/pull/4042

struct Piece {
  idx: u8,
  lights: bool,
}

impl Piece {
  fn starting(idx: u8) -> Self {
    Self {
      idx,
      lights: true,
    }
  }

  fn decompose(self) -> [Field; 2] {
    [
      self.idx as Field,
      self.lights as Field,
    ]
  }
}

// Players are distinguished as: 0 = white; 1 = black.
global PLAYER_COUNT: u64 = 2;

// BUG: Type `PlayerPieces` is parsed as a slice instead of an array and so
//      breaks `main()` circuit methods with error:
// `---- Slices, references, or any type containing them may not be used in main or a contract function`
//
type PlayerPieces = [Piece; 2];

struct Board {
  // OPT: Could have the board input only the pieces of the player whose turn it
  //      is but this would require more orchestration to play, see gate difference
  //      later on.
  //
  // Pieces for each player.
  // players: [[Piece; 2]; PLAYER_COUNT],
  players: [PlayerPieces; PLAYER_COUNT],
  // Player's turn.
  turn: u1,
  halfmove: u8,
}

// - 2 members in `Piece`, 2 arrays of 2 `Pieces` = 2 * 2 * 2 = 8.
// - Other `Board` members = 2.
// => 8 + 2 = 10.
global BOARD_ORDINAL: Field = 10;

// ---------------------------------------------------------------------------
// ---------------------------------------------- BOARD

impl Board {
  fn apply_move(self, move: Move) -> Self {
      let mut new_players = self.players;

      let from: u8 = move.from;
      let to: u8 = move.to;

      assert((0 <= from) & (from <= 24), "No such 'from' square");
      assert((0 <= to) & (to <= 24), "No such 'to' square");
      assert(from != to, "Cannot move in-place");

      // TODO: Check destination `move.to` while we're here for captures or
      //       not capturing friendlies.
      let mut piece_idx: Option<u8> = Option::none();
      for i in 0..move.pieces.len() {
        if move.pieces[i].idx == from {
          piece_idx = Option::some(i as u8);
        }
      }
      assert(piece_idx.is_some(), "No piece on square");

      // The only piece in this game (all pieces are the same type) can move
      //   omnidirectionally one square only.
      // Not efficient but this is for prototyping so who cares.
      let move_delta = if to > from {
        to - from
      } else {
        from - to
      };

      let valid_move = (move_delta == 6) | (move_delta == 5)| (move_delta == 4) | (move_delta == 1);

      assert(valid_move, "Invalid move pattern");

      // TODO: It's ugly but constrain if halfmove == 0 (whites first turn) that white
      //       has correct starting pieces. And if halfmove == 1 (blacks first turn) that
      //       black has correct starting pieces.

      // Move is valid if at most 1 chebyshev-distance in all axes is traversed.
      // assert((file_diff <= 1) & (rank_diff <= 1), "Illegal move pattern");

      // Update players' piece state.
      new_players[self.turn][piece_idx.unwrap_unchecked()].idx = to;

      let new_board = Self {
        players: new_players,
        turn: !self.turn,
        halfmove: self.halfmove + 1,
      };
      new_board
    }

  fn decompose(self) -> [Field; BOARD_ORDINAL] {
    let mut decomp = [0; BOARD_ORDINAL];

    decomp[0] = self.turn as Field;
    decomp[1] = self.halfmove as Field;

    let mut idx_offset = 2;

    // Each player.
    for i in 0..PLAYER_COUNT {
      // Pieces.
      for j in 0..self.players[i].len() {
        let pce_decomp = self.players[i][j].decompose();
        for k in 0..pce_decomp.len() {
          decomp[idx_offset] = pce_decomp[k];
          idx_offset += 1;
        }
      }
    }

    decomp
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE

struct Move {
  // Players private record of their pieces.
  // pieces: [Piece; 2],
  pieces: PlayerPieces,
  from: u8,
  to: u8,
}

// - 2 members in `Piece`, 1 array of 2 `Pieces` =23 * 1 * 2 = 4.
// - Other `Move` members = 2.
// => 4 + 2 = 6.
global MOVE_ORDINAL: Field = 6;

impl Move {
  fn decompose(self) -> [Field; MOVE_ORDINAL] {
    let mut decomp = [0; MOVE_ORDINAL];

    decomp[0] = self.from as Field;
    decomp[1] = self.to as Field;

    let mut idx_offset = 2;

    // Pieces.
    for i in 0..self.pieces.len() {
      let pce_decomp = self.pieces[i].decompose();
      for j in 0..pce_decomp.len() {
        decomp[idx_offset] = pce_decomp[j];
        idx_offset += 1;
      }
    }

    decomp
  }
}

//
// STATE COMMITMENT HELPER
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- XX

// use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};

struct State {
  cur_board: Board,
  move: Move,
}

struct Input {
  state: Option<State>
}

// This API is dubious, but we're hacking right now. For invocation from Noir
//   tests in `xx_player`.
// impl Input {
//   pub fn move_commit(cur_board: Board, move: Move) -> Self {
//     Self {
//       state: Option::some(State { cur_board, move })
//     }
//   }
// }

// pub fn move_commit(cur_board: Board, move: Move) -> (PedersenPoint, Board) {
//   let commit = state_commitment(State { cur_board, move });

//   dep::std::println(commit.0);
//   // assert(commit.1.is_some(), "foo");
//   // dep::std::println(commit.1);

//   // assert(commit.state_commitment.is_some(), "Error constructing state commitment");
//   // TODO: No such method `expect`.. wat? Is `expect` broken for nested structs?
//   // let commitment = fn_output.state_commitment.expect(f"Error constructing move commitment");

//   commit
// }

struct Output {
  state_commitment: Option<(PedersenPoint, Board)>
}

// Commitment that `move` produces post-move board state `pst_board`.
pub fn state_commitment(state: State) -> (PedersenPoint, Board) {
  let pst_board = state.cur_board.apply_move(state.move);

  // dep::std::println(pst_board);

  // TODO: Should these hashes also be `commitment` or is only the final one
  //       being a `commitment` enough? Here and elsewhere.
  let move_hash = pedersen_hash(state.move.decompose());
  let pst_board_hash = pedersen_hash(pst_board.decompose());

  (pedersen_commitment([move_hash, pst_board_hash]), pst_board)
}

// TODO: Add salt later.
// pub fn commit_to(input: Input) -> Output {
//   let mut output = Output {
//     state_commitment: Option::none()
//   };

//   if input.state.is_some() {
//     output.state_commitment = Option::some(
//       state_commitment(input.state.unwrap_unchecked())
//     );
//   }

//   output
// }

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

//
// TESTS
//

// global T__VALID_START_BOARD =

// #[test]
// fn compass_moves() {

// }
