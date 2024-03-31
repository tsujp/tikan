use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};

//
// CORE
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- STATE (DE)SERIALISATION

//
// Game has 4 pieces for which we need to know:
//   (1) On which square the piece is on, indexed over [0, 24] i.e. closed range.
//   (2) Whether the piece has it's lights turned on [0, 1].
//
// So 8 characters are required for this. There are two special encoding patterns
//   regarding captured pieces and blinded pieces. The former comes from the
//   (informal) constraint of a constant input size, so avoid extra special-
//   purpose padding-characters we:
//     (3) Represent a captured piece as having no index value, with lights on.
//     (4) Represent a blinded piece as having no index value, with lights off.
//
// In-situ (3) and (4) appear as: `-B` and `-A` respectively. Since a lights on
//   piece must have a public index value we can double-duty this position by
//   saying it must be captured. Lights off pieces are hidden (unless revealed
//   by an enemy's lit-area) and so, by default, have no (public) index value.
//
// Finally we need a representation of the current players' turn (white or black)
//   and the total number of halfmoves. Since this is an example game not
//   intended to be played seriously we'll use a single character for the latter
//   meaning a maximum of 25 half-turns can occur.
//
// All up this is 8 characters for pieces, and 1 character each for turn and
//   turn count for a total of 10 characters.
//

global PLAYER_PIECES = 2;

global SERIALISED_PIECE_WIDTH = 2;
global SERIALISED_PIECES = 8;

// Keep in-sync with sum of PIECES and TOTAL. Noir compiler doesn't like expressions
//   for globals (even if all consituents of said expressions are globals too).
global SERIALISED_STATE_TOTAL = 10; // 8 + 2 (turn and halfmove).

// Move input involves the players own pieces as well as the from and to squares
//   for the piece being moved. Each player has equal pieces so this is half
//   of SERIALISED_PIECES plus 2 = 6.
global SERIALISED_MOVE_TOTAL = 6;

type Char = u8;
type Chars<N> = [Char; N];

// Cannot construct `str` programmatically in Noir at the moment, and using `Chars`
//   for input would make public inputs SERIALISED_TOTAL count long, which is
//   antithetical to the point of serialisation: reducing public inputs to an
//   absolute minimum.

// Board.
type SerialisedStateIn = str<SERIALISED_STATE_TOTAL>; // `str` here.
type SerialisedStateOut = Chars<SERIALISED_STATE_TOTAL>;

// Piece.
type SerialisedPiece = Chars<SERIALISED_PIECE_WIDTH>;

// Move.
type SerialisedMove = str<SERIALISED_MOVE_TOTAL>; // `str` here.

struct Corpus {
  codepoint_start: Char,
  codepoint_end: Char,
  empty_value: Char,
}

global CORPUS = Corpus {
  // Codepoints are in DECIMAL.
  codepoint_start: 65, // Integer ASCII codepoint start and end (inclusive).
  codepoint_end: 90,
  empty_value: 45 // ASCII hyphen `-`.
};

fn parse_integer(c: Char) -> u8 {
  // TODO: Can we have format-string assertions yet?
  assert((CORPUS.codepoint_start <= c) & (c <= CORPUS.codepoint_end), "Codepoint not in required range");

  c - CORPUS.codepoint_start
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- PIECE

struct Piece {
  idx: u8,
  lights: bool,
  captured: bool,
}

impl Piece {
  pub fn deserialise(serial: SerialisedPiece) -> Self {
    // Just unroll the loop ourselves; risky business to manually keep in-sync
    //   with `SERIALISED_PIECE_WIDTH` but yolo this is an _example_ proof of
    //   concept, save the real over-engineering for the main event.
    let __sqr = serial[0];

    let lights = parse_integer(serial[1]) as bool;

    let (idx, captured) = if __sqr == CORPUS.empty_value {
      (0, lights)
    } else {
      (parse_integer(__sqr), false)
    };

    Self {
      idx,
      lights,
      captured,
    }
  }

  fn serialise(self) -> SerialisedPiece {
    [
      if self.captured { CORPUS.empty_value } else { self.idx },
      // XXX: Compiler cannot resolve the fact that `Char` is a `u8` for casts here.
      self.lights as u8
    ]
  }
  
  fn starting(idx: u8) -> Self {
    Self {
      idx,
      lights: true,
      captured: false,
    }
  }

  // TOOD: Shouldn't need this anymore?
  // fn decompose(self) -> [Field; 3] {
  //   [
  //     self.idx as Field,
  //     self.lights as Field,
  //     self.captured as Field,
  //   ]
  // }
  // ----/
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- BOARD

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
  players: [PlayerPieces; PLAYER_COUNT],
  // Player's turn.
  turn: u1,
  halfmove: u8,
}

impl Board {
  pub fn deserialise(serial: SerialisedStateIn) -> Self {
    // Return state.
    let mut pieces: [PlayerPieces; PLAYER_COUNT] = dep::std::unsafe::zeroed();

    // Control.
    let bytes = serial.as_bytes();
    let piece_count = SERIALISED_PIECES / SERIALISED_PIECE_WIDTH;

    // Deserialise pieces.
    for piece_idx in 0..piece_count {
      let offset_idx = piece_idx * SERIALISED_PIECE_WIDTH;

      // let __sqr = bytes[offset_idx];
      // let __lit = bytes[offset_idx + 1];

      // let piece_lit = parse_integer(__lit) as bool;
      // let (piece_sqr, piece_cap) = if __sqr == CORPUS.empty_value {
      //   (0, piece_lit)
      // } else {
      //   (parse_integer(__sqr), false)
      // };

      // let piece = Piece {
      //   idx: piece_sqr,
      //   lights: piece_lit,
      //   captured: piece_cap,
      // };
      let piece = Piece::deserialise([
        bytes[offset_idx], bytes[offset_idx + 1]
      ]);

      // Hardcoded push, white 0 and 1, black 2 and 3. Risky manual sync blah blah.
      let player_piece_idx = piece_idx % 2;
      pieces[if piece_idx < 2 { 0 } else { 1 }][player_piece_idx] = piece;      
    }

    // Deserialise player turn and halfmove count. Risky manual sync blah blah.
    let turn = parse_integer(bytes[SERIALISED_PIECES]);
    assert((0 <= turn) & (turn <= 1), "Expected 'turn' to be 0 or 1");

    let halfmove = parse_integer(bytes[SERIALISED_PIECES + 1]);

    // dep::std::println(f"player pieces deserialised as: {pieces}");
    // dep::std::println(f"turn of: {turn}");
    // dep::std::println(f"halfmove: {halfmove}");
    
    Self {
      players: pieces,
      turn: turn as u1,
      halfmove,
    }
  }

  fn serialise(self) -> SerialisedStateOut {
    let mut serial: BoundedVec<Char, SERIALISED_STATE_TOTAL> = BoundedVec::new();

    for i in 0..PLAYER_COUNT {
      for j in 0..self.players[i].len() {
        serial.extend_from_array(self.players[i][j].serialise());
      }
    }

    serial.push(self.turn as u8);
    serial.push(self.halfmove);

    // dep::std::println(serial.storage());
    serial.storage()
  }

  fn apply_move(self, move: Move) -> Self {
    let mut new_players = self.players;

    let focus_piece = self.players[self.turn][move.idx];
    dep::std::println(focus_piece);

    // TODO: Assertions whether the player owns their claimed pieces is required
    //       to prevent people making moves on behalf of their opponent; add
    //       this extra check if required unless (when added) commitments
    //       implicitly solve it (which I feel like they will).

    let from: u8 = focus_piece.idx;
    let to: u8 = move.to;

    assert((0 <= from) & (from <= 24), "no such `from` square");
    assert((0 <= to) & (to <= 24), "no such `to` square");
    assert(from != to, "cannot move in-place");

    // TODO: Check destination `move.to` while we're here for captures or
    //       not capturing friendlies.
    // let mut piece_idx: Option<u8> = Option::none();
    // for i in 0..move.pieces.len() {
    //   if move.pieces[i].idx == from {
    //     piece_idx = Option::some(i as u8);
    //   }
    // }
    // assert(piece_idx.is_some(), "no piece on square");

    // The only piece in this game (all pieces are the same type) can move
    //   omnidirectionally one square only.
    // Not efficient but this is for prototyping so who cares.
    let move_delta = if to > from {
      to - from
    } else {
      from - to
    };

    dep::std::println(f"move delta: {move_delta}");

    // Move is valid if at most 1 chebyshev-distance in all axes is traversed.
    let valid_move = (move_delta == 6) | (move_delta == 5)| (move_delta == 4) | (move_delta == 1);
    assert(valid_move, "invalid move pattern");

    // TODO: It's ugly but constrain if halfmove == 0 (whites first turn) that white
    //       has correct starting pieces. And if halfmove == 1 (blacks first turn) that
    //       black has correct starting pieces.

    // Update players' piece state.
    // new_players[self.turn][piece_idx.unwrap_unchecked()].idx = to;
    new_players[self.turn][move.idx].idx = to;

    Self {
      players: new_players,
      turn: !self.turn,
      halfmove: self.halfmove + 1,
    }
  }

  // TODO: Delete, shouldn't need this now if we've already serialised the board.
  // fn decompose(self) -> [Field; BOARD_ORDINAL] {
  //   let mut decomp = [0; BOARD_ORDINAL];

  //   decomp[0] = self.turn as Field;
  //   decomp[1] = self.halfmove as Field;

  //   let mut idx_offset = 2;

  //   // Each player.
  //   for i in 0..PLAYER_COUNT {
  //     // Pieces.
  //     for j in 0..self.players[i].len() {
  //       let pce_decomp = self.players[i][j].decompose();
  //       for k in 0..pce_decomp.len() {
  //         decomp[idx_offset] = pce_decomp[k];
  //         idx_offset += 1;
  //       }
  //     }
  //   }

  //   decomp
  // }
  // END TODO/
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE

struct Move {
  // Players private record of their pieces.
  pieces: PlayerPieces,
  // Index of players piece they are trying to move.
  idx: u8,
  // Square they are moving `idx` piece to.
  to: u8,
}

impl Move {
  pub fn deserialise(serial: SerialisedMove) -> Self {
    let mut pieces: BoundedVec<Piece, 2> = BoundedVec::new();

    let bytes = serial.as_bytes();

    // TODO: Don't hardcode `2` here.
    for i in 0..PLAYER_PIECES {
      let offset_idx = i * SERIALISED_PIECE_WIDTH;

      pieces.push(Piece::deserialise([
        bytes[offset_idx], bytes[offset_idx + 1]
      ]));
    }

    // TODO: Don't hardcode `5` and `6` here.
    let idx = parse_integer(bytes[4]);
    assert((0 <= idx) & (idx <= PLAYER_PIECES as u8), f"move `idx` out of bounds [0, {PLAYER_PIECES}], got: {idx}");
    
    let to = parse_integer(bytes[5]);

    // dep::std::println(f"== move deserialised ==");
    // dep::std::println(f"pieces: {pieces}");
    // dep::std::println(f"from: {from}");
    // dep::std::println(f"to: {to}");

    Self {
      pieces: pieces.storage(),
      idx: idx as u8,
      to,
    }
  }
  
  // fn decompose(self) -> [Field; MOVE_ORDINAL] {
  //   let mut decomp = [0; MOVE_ORDINAL];

  //   decomp[0] = self.from as Field;
  //   decomp[1] = self.to as Field;

  //   let mut idx_offset = 2;

  //   // Pieces.
  //   for i in 0..self.pieces.len() {
  //     let pce_decomp = self.pieces[i].decompose();
  //     for j in 0..pce_decomp.len() {
  //       decomp[idx_offset] = pce_decomp[j];
  //       idx_offset += 1;
  //     }
  //   }

  //   decomp
  // }
}


// ---------------------------------------------------------------------------
// ---------------------------------------------- XX

// use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};

//
// STATE COMMITMENT HELPER
//

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
// pub fn state_commitment(state: State) -> (PedersenPoint, Board) {
//   let pst_board = state.cur_board.apply_move(state.move);

//   // dep::std::println(pst_board);

//   // TODO: Should these hashes also be `commitment` or is only the final one
//   //       being a `commitment` enough? Here and elsewhere.
//   let move_hash = pedersen_hash(state.move.decompose());
//   let pst_board_hash = pedersen_hash(pst_board.decompose());

//   (pedersen_commitment([move_hash, pst_board_hash]), pst_board)
// }

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
