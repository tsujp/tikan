use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::lib::{Piece, Board, Move, SerialisedStateIn, SerialisedStateOut, SerialisedMove};

// TESTS TO WRITE:
//   - Not be able to move opponents pieces by providing them in the `pieces` list
//     of your `move` (tackle this _after_ commitments are added).

#[recursive]
fn main (
  // ---- RECURSION
  proof: [Field; 93],
  public: [Field; 26],
  vk: [Field; 114],
  vk_hash: Field,
  // ----
  // Player turn inputs.
  // cur_board: pub Board, // As claimed by player.
  // pst_board: pub Board, // As claimed by player.
  // move: Move,
  // moar_state: pub Field,
  cur_state_serial: pub SerialisedStateIn, // As claimed by player.
  cur_move_serial: SerialisedMove,
  secret: Field,
  // state_commitment: pub PedersenPoint,
) {
  if cur_state_serial != "BBDBVBXBAA" {
    dep::std::verify_proof(
      vk.as_slice(),
      proof.as_slice(),
      public.as_slice(),
      vk_hash,
    );
  }

  let cur_board = Board::deserialise(cur_state_serial);

  let move = Move::deserialise(cur_move_serial);

  // assert(5.lt(moar_state));
  // let bits = moar_state & 0xFF;
  // let biggy = U128::from_integer(moar_state);

  // let foobar = ([69, 255]).as_chars();
  // dep::std::println(f"foobar: {foobar}");

  // let move_serial_arr = move.serialise().as_fields();
  // dep::std::println(f"move_serial_arr: {move_serial_arr}");

  // let move_agen: [Char] = move.serialise().vert();

  // let move_hash = pedersen_hash(move.decompose());
  // let pst_board_hash = pedersen_hash(pst_board.decompose());

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
  let mut real_pst_board = cur_board.apply_move(move);

  // dep::std::println(f"MOVE: {move}");
  // dep::std::println(f"CUR: {cur_board}");
  // dep::std::println(f"POST: {real_pst_board}");
  // dep::std::println(real_pst_board.serialise());

  // Real and claimed post-move board match. Since `pst_board` is public input to this
  //   circuit if this verifies we can trust that public input `pst_board` is now
  //   the `cur_board` for the subsequent players' turn.
  // let real_pst_board_hash = pedersen_hash(real_pst_board.decompose());
  // assert(real_pst_board_hash == pst_board_hash);

  // TODO: Haven't we done this in-part above? Hmmm.
  // We also need to check that the players' move was in-fact against the `cur_board`
  //   and produced the `pst_board`.
  // let computed_commitment = pedersen_commitment([move_hash, real_pst_board_hash]);

  // assert(computed_commitment.x == state_commitment.x, "Bad commitment x");
  // assert(computed_commitment.y == state_commitment.y, "Bad commitment y");

  // real_pst_board.commits[!real_pst_board.turn] = state_commitment;

  // real_pst_board
}

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
// use dep::lib::{State, state_commitment};

// global T__VALID_WHITE_START = [ Piece { idx: 1, lights: true }, Piece { idx: 3, lights: true } ];
// global T__VALID_BLACK_START = [ Piece { idx: 21, lights: true }, Piece { idx: 23, lights: true } ];

// global T__VALID_START_BOARD = Board {
//   turn: 0,
//   halfmove: 0,
//   commits: [
//     PedersenPoint { x: 0, y: 0 }, // White commitment.
//     PedersenPoint { x: 0, y: 0 }, // Black commitment.
//   ],
//   players: [T__VALID_WHITE_START, T__VALID_BLACK_START]
// };

// fn __move_commit(cur_board: Board, move: Move) -> (PedersenPoint, Board) {
//   Log::step(f"commit to move");
//   let commit = state_commitment(State { cur_board, move });
//   Log::input(move);
//   // Log::input(cur_board.commits);
//   Log::output(commit.0);
//   commit
// }

// use dep::std::println as puts;
// use dep::std::print as put;

// fn __print_commit(data: (PedersenPoint, Board)) {
//   data.1.print(); // Board.

//   let x = data.0.x;
//   let y = data.0.y;
// }

// struct Log {}

// impl Log {
//   fn kind<N>(log_kind: str<N>) {
//     put(f"{log_kind}:")
//   }

//   pub fn test_name<N, T>(name: fmtstr<N, T>) {
//     Log::kind("T_NAME"); // Test name format string.
//     puts(name); // Cannot do as `f"0001 {name}"` hence this.
//   }

//   pub fn step<N, T>(step: fmtstr<N, T>) {
//     Log::kind("T_STEP");
//     puts(step);
//   }

//   pub fn commit(payload: (PedersenPoint, Board)) {
//     Log::kind("T_COMT");
//     put(payload.0);
//     puts(payload.1);
//   }

//   pub fn input<T>(data: T) {
//     // put("T___IN:");
//     Log::kind("T___IN");
//     puts(data);
//   }

//   pub fn output<T>(data: T) {
//     Log::kind("T__OUT");
//     puts(data);
//   }
// }

// fn test<Env, N, T>(name: fmtstr<N, T>, f: fn[Env]() -> ()) {
//   Log::test_name(name);
//   f();
// }

// #[test]
// fn execute__compass_moves__white__1() {
//   puts("");

//   let from = 1;
//   let to_indices = [0, 5, 6, 7, 2]; // Compass rose about `from_idx`.

//   // Don't want to use `.all()` because it requires another closure wrap on our
//   //   custom `test` function.
//   for i in 0..to_indices.len() {
//     let to = to_indices[i];

//     test(f"white compass-rose moves {from} to {to}", || {
//       let white_move = Move { pieces: T__VALID_WHITE_START, from, to };

//       let white_commit = __move_commit(
//         T__VALID_START_BOARD,
//         white_move
//       );
//     });
//   }
// }

// #[test]
// fn compass_moves__white__1() {
//   let from = 1;
//   let to_indices = [0, 5, 6, 7, 2]; // Compass rose about `from_idx`.

//   // Don't want to use `.all()` because it requires another closure wrap on our
//   //   custom `test` function.
//   for i in 0..to_indices.len() {
//     let to = to_indices[i];

//     test(f"white compass-rose moves {from} to {to}", || {
//       let white_move = Move { pieces: T__VALID_WHITE_START, from, to };

//       let white_commit = __move_commit(
//         T__VALID_START_BOARD,
//         white_move
//       );

//       let white_pst = main(
//         T__VALID_START_BOARD,
//         white_commit.1,
//         white_move,
//         white_commit.0
//       );

//       Log::output(white_pst)
//     });
//   }
// }

// #[test]
// fn white_legit_move() {
//   puts("");

//   test(f"white legit move", || {
//     let white_move = Move { pieces: T__VALID_WHITE_START, from: 1, to: 5 };

//     let white_commit = __move_commit(
//       T__VALID_START_BOARD,
//       white_move
//     );

//     let white_pst = main(
//       T__VALID_START_BOARD,
//       white_commit.1,
//       white_move,
//       white_commit.0
//     );

//     Log::output(white_pst)
//   });
// }
