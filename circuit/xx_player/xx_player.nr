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
use dep::std::println;
use dep::std::print as pn;
use dep::lib::{State, state_commitment};

global T__VALID_WHITE_START = [ Piece { idx: 1, lights: true }, Piece { idx: 3, lights: true } ];
global T__VALID_BLACK_START = [ Piece { idx: 21, lights: true }, Piece { idx: 23, lights: true } ];

global T__VALID_START_BOARD = Board {
  turn: 0,
  halfmove: 0,
  commits: [
    PedersenPoint { x: 0, y: 0 }, // White commitment.
    PedersenPoint { x: 0, y: 0 }, // Black commitment.
  ],
  players: [T__VALID_WHITE_START, T__VALID_BLACK_START]
};

// fn __move_commit(board: Board, move: Move) -> {
//   commit_to(Input::move_commit(
//     T__VALID_START_BOARD,
//     Move { pieces: T__VALID_WHITE_START, from: 1, to: 0 }
//   ));
// }

fn __move_commit(cur_board: Board, move: Move) -> (PedersenPoint, Board) {
  let commit = state_commitment(State { cur_board, move });
  commit
}

fn __print_commit(data: (PedersenPoint, Board)) {
  data.1.print(); // Board.

  // let x = data.0.x;
  // let y = data.0.y;
  // dep::std::print(f" [{x}, {y}]");
}

fn test<Env, N, T>(name: fmtstr<N, T>, f: fn[Env]() -> ()) {
  // Start: Syslog protocol header.
  // For now hardcoded facility 16 (local use 0), severity 7 (debug), version 1.
  //   See: https://datatracker.ietf.org/doc/html/rfc5424#section-6.2.1
  // pn("<135>1 ");

  // NILVALUE since we cannot get timestamp here without an oracle which I cbf doing.
  // pn("2001-01-01T00:00:00.000 ");
  // pn("- "); // Hostname not important; ditto oracle too.
  // pn("xx_player "); // App-name.
  // pn("- "); // Proc-id. TODO: Spec says we could use this for grouping later on (e.g. context).
  // pn("- "); // Msg-id. Should identify type of message.
  // End: syslog header.


  dep::std::print(name); // Cannot do as `f"{name}: "` (nested format strings)...
  dep::std::print(f" -> "); // ...hence this.
  f();
  dep::std::println(f"");
}

#[test]
fn compass_moves__white__1() {
  let from = 1;
  let to_indices = [0, 5, 6, 7, 2]; // Compass rose about `from_idx`.

  // Don't want to use `.all()` because it requires another closure wrap on our
  //   custom `test` function.
  for i in 0..to_indices.len() {
    let to = to_indices[i];

    test(f"white compass-rose moves {from} to {to}", || {
      let white_commit = __move_commit(
        T__VALID_START_BOARD,
        Move { pieces: T__VALID_WHITE_START, from, to }
      );
      __print_commit(white_commit);
      // dep::std::print(white_commit.0);
      // white_commit.1.print();

      // TODO: Some assert pass so we can log shit.
    });
  }

  // test("white compass-rose moves", || {
  //   let white_commit = __move_commit(
  //     T__VALID_START_BOARD,
  //     Move { pieces: T__VALID_WHITE_START, from: 1, to: 0 }
  //   );
  //   white_commit.1.print();
  // });

  // white_commit.1.print();
  // dep::std::println(white_commit.1);
}
