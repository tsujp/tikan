use dep::std::println;

// use dep::state::board::Board;
use dep::lib::{Board, Move};

// XXX / TODO
// Board is always public input but can have missing values which are blinded by
//   a Pedersen commitment (as and when fog of war).
// fn main(board: pub tikan::Board, move: Field) -> pub Field {
// TODO: Another field with prior board proof.
// fn main(board: pub Board, move: Move) -> pub Board {
fn main(board: pub Board, move: Move) -> pub Board {
    // println("hi there");

    let new_state = board.apply(move);

    // board.validate();
    // move.validate();

    // If a move is given without a previous proof circuit should fail. Idea is
    //   first move os the game can be given without a previous proof but will
    //   assert that the board state is that of a starting game.

    // println(new_state);

    new_state
}
