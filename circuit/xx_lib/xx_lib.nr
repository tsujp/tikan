use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};

//
// CORE
//

// OPT: Can use field comparison instead? See: https://github.com/noir-lang/noir/pull/4042

struct Piece {
  idx: u8,
  lights: bool,
  // file: u8,
  // rank: u8,
}

impl Piece {
  // fn starting(file: u8, rank: u8) -> Self {
  fn starting(idx: u8) -> Self {
    Self {
      // file,
      // rank,
      idx,
      lights: true,
    }
  }

  // fn decompose(self) -> [Field; 3] {
  fn decompose(self) -> [Field; 2] {
    [
      // self.file as Field,
      // self.rank as Field,
      self.idx as Field,
      self.lights as Field,
    ]
  }
}

// Players are distinguished as: 0 = white; 1 = black.
global PLAYER_COUNT: Field = 2;

type PlayerPieces = [Piece; 2];

struct Board {
  // Pieces for each player.
  players: [PlayerPieces; PLAYER_COUNT],
  // State commitments.
  commits: [PedersenPoint; PLAYER_COUNT],
  // Player's turn.
  turn: u1,
  halfmove: u8,
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- BOARD

impl Board {
  // Could use this to bring the starting board into the circuit but they're public
  //   input anyway so I think _not_ doing that for now is fine.
  // fn starting() -> Self {
  //   Self {
  //     players: [
  //       [Piece::starting(1, 0), Piece::starting(3, 0)],
  //       [Piece::starting(1, 4), Piece::starting(3, 4)],
  //     ],
  //     turn: 0,
  //     halfmove: 0,
  //   }
  // }

  // Nargo appears to crash if I try and print the `.players` member; so an array
  //   of an array of structs. Decompose it ourselves I guess.
  unconstrained fn print(self) {
    // let fields = [
    //   "trn",
    //   "hlf",
    //   "w_x",
    //   "w_y",
    //   "b_x",
    //   "b_y"
    // ];

    // let piece_fields = [
    //   "idx",
    //   "lit"
    // ];

    let decomposed = self.decompose();

    // Magic number `6` from count of non-piece fields on `Board` struct. See
    //   `decompose` method comments.
    // for _i in 0..decomposed.len() {
    //   let i = _i as u8;

    //   let k = if i >= 6 {
    //     if i % 2 == 0 { dep::std::print(f"  "); } // Pad between pieces.
    //     piece_fields[i % 2]
    //   } else {
    //     fields[i]
    //   };

    //   // dep::std::print(f"key is: {k} /  ");

    //   let v = decomposed[i];

    //   dep::std::print(f"{k}=u-{v} ");
    // }


    // Nah, just do it the mostly old-fashioned way.
    let tn = decomposed[0];
    let hlf = decomposed[1];
    let w_x = decomposed[2];
    let w_y = decomposed[3];
    let b_x = decomposed[4];
    let b_y = decomposed[5];

    dep::std::print(f"t=u-{tn} ");
    dep::std::print(f"h=u-{hlf}  "); // 2 pad on end.

    for _i in 6..decomposed.len() {
      let i = _i as u8;

      let k = if i % 2 == 0 {
        dep::std::print(f"  "); // Pad between pieces.
        "idx"
      } else {
        "lit"
      };

      let v = decomposed[i];

      dep::std::print(f"{k}=u-{v} ");
    }

    dep::std::print(f"   wht={ x={w_x}, y={w_y} }   ");
    dep::std::print(f"blk={ x={b_x}, y={b_y} }");


    // Or if quick and dirty:
    // dep::std::print(self.decompose());
  }

  fn apply_move(self, move: Move) -> Self {
      let from: u8 = move.from;
      let to: u8 = move.to;

      assert((0 <= from) & (from <= 24), "No such from index");
      assert((0 <= to) & (to <= 24), "No such to index");
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

      // The only piece in this game (all pieces are the same type) can move omnidirectionally
      //   one square only.
      // Not an efficient but this is for prototyping so who cares.
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

      // TODO: Update players' piece state.

      // Self {
      //   players: self.players,
      //   commits: self.commits, // TODO: Update.
      //   turn: !self.turn,
      //   halfmove: self.halfmove + 1,
      // }

      let new_board = Self {
        players: self.players,
        commits: self.commits, // TODO: Update.
        turn: !self.turn,
        halfmove: self.halfmove + 1,
      };
      // dep::std::println(new_board);
      new_board
    }

  // - 3 members in `Piece`, 2 arrays of 2 `Pieces` = 3 * 2 * 2 = 12.
  // - 2 members in `PedersenPoint`, array of 2 = 2 * 2 = 4.
  // - Other `Board` members = 2.
  // = 12 + 4 + 2 = 18.
  fn decompose(self) -> [Field; 14] {
    let mut decomp = [0; 14];

    decomp[0] = self.turn as Field;
    decomp[1] = self.halfmove as Field;

    let mut idx_offset = 2;

    // Each player.
    for i in 0..PLAYER_COUNT {
      // Commitments.
      decomp[idx_offset] = self.commits[i].x;
      decomp[idx_offset + 1] = self.commits[i].y;
      idx_offset += 2;

      // Pieces.
      for j in 0..self.players[i].len() {
        let pce_decomp = self.players[i][j].decompose();
        for k in 0..pce_decomp.len() {
          decomp[idx_offset] = pce_decomp[k];
          idx_offset += 1;
        }
      }
    }

    // dep::std::println(decomp);

    decomp
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE

struct Move {
  // Players private record of their pieces.
  pieces: PlayerPieces,
  from: u8,
  to: u8,
  // from_file: u8,
  // from_rank: u8,
  // to_file: u8,
  // to_rank: u8
}

impl Move {
  // - 3 members in `Piece`, 1 array of 2 `Pieces` = 3 * 1 * 2 = 6.
  // - 4 fields in `Move` struct.
  // = 6 + 4 = 10.
  fn decompose(self) -> [Field; 6] {
    let mut decomp = [0; 6];

    decomp[0] = self.from as Field;
    decomp[1] = self.to as Field;

    // decomp[0] = self.from_file as Field;
    // decomp[1] = self.from_rank as Field;
    // decomp[2] = self.to_file as Field;
    // decomp[3] = self.to_rank as Field;

    let mut idx_offset = 2;

    // Pieces.
    for i in 0..self.pieces.len() {
      let pce_decomp = self.pieces[i].decompose();
      for j in 0..pce_decomp.len() {
        decomp[idx_offset] = pce_decomp[j];
        idx_offset += 1;
      }
    }

    // dep::std::println(decomp);

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
