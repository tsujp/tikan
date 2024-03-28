// Starting position for players.


// --------------------------------------------------------------
// --------------------------------------------------------------
// V3
use dep::std::hash::pedersen_commitment;
use dep::lib::{Piece, Board, PlayerPieces};


fn main(player: pub u1, start_commitment: pub Field, salt: Field) -> pub (Board, Field) {
  // Fixed starting board.
  let board = Board::starting();
  let board_hash = pedersen_commitment(board.decompose()).x;

  // Fixed starting pieces for given player.
  let pieces = if player == 0 {
    // White starts with 2 pieces on {file, rank}: {1,0} and {3,0}.
    [Piece::starting(1, 0), Piece::starting(3, 0)]
  } else {
    // Black: {1,4} and {3,4}.
    [Piece::starting(1, 4), Piece::starting(3, 4)]
  };

  // TODO: Dynamic, adding or removing pieces (to the structs) breaks this.
  let mut pieces_decomp = [0; 6];
  let mut idx_offset = 0;
  for i in 0..pieces.len() {
    let pce_decomp = pieces[i].decompose();
    for k in 0..pce_decomp.len() {
      pieces_decomp[idx_offset] = pce_decomp[k];
      idx_offset += 1;
    }
  }
  let pieces_hash = pedersen_commitment(pieces_decomp).x;

  let commitment = pedersen_commitment([
    board_hash,
    pieces_hash,
    player as Field,
    salt,
  ]).x;

  assert(start_commitment == commitment);

  // Starting board and commitment.
  (board, commitment)
}
// END V3





// --------------------------------------------------------------
// --------------------------------------------------------------
// V2
// use dep::std::hash::pedersen_commitment;
// use dep::lib::{Piece, Board};


// // TODO: Salt later?
// fn main(board: pub Board, player: pub u1) -> pub Field {
//     // AFAIK the alternative is doing this within this circuit which is very slow, so try V3.
//   assert(board.halfmove == 0);
//   assert(board.turn == 0);
//   assert((board.players[0][0].file == 1) & (board.players[0][0].rank == 0));
//   assert(board.players[0][0].lit);
//   assert((board.players[0][1].file == 3) & (board.players[0][1].rank == 0));
//   assert(board.players[0][1].lit);
//   assert((board.players[1][0].file == 1) & (board.players[1][0].rank == 4));
//   assert(board.players[1][0].lit);
//   assert((board.players[1][1].file == 3) & (board.players[1][1].rank == 4));
//   assert(board.players[1][1].lit);

//   // Produce the commitment for them...?

//   let board_hash = pedersen_commitment(board.decompose()).x;

//   let commitment = pedersen_commitment([
//     player as Field,
//     board_hash,
//   ]).x;

//   commitment
// }
// END V2





// --------------------------------------------------------------
// --------------------------------------------------------------
// V1, I dont think this works. Need public input and.. a commitment(?) to
//   lay out the starting board state. Try that in V2.

// struct Piece {
//   // OPT: Could bit-pack into single struct member as {file, rank} only require
//   //      3-bits each and we have an 8-bit integer twice. Furthermore extracting
//   //      the values would be done with constant bitwise values which are also
//   //      powers of 2 (we'd split the u8 into 2xu4) so it should be wicked fast
//   //      and reduce (guessing marginally) proving/verification time as there are
//   //      less circuit outputs now (1 struct member and not 2). Gate-golf that later.
//   file: u8, // Noir only allows 1, 8, 16, and 64-bit sized integers now.
//   rank: u8,
// }

// // INVES: Add salt? I don't think it's required for the _starting_ positions unless we allow
// //          changing them but that's a stretch goal and dubious as to whether anyone would
// //          even want non-standard starting positions.
// fn main(player: pub u1) -> pub [Piece; 2] {
//   let pieces = if player == 0 {
//     // White starts with 2 pieces on {file, rank}: {1,0} and {3,0}.
//     [Piece { file: 1, rank: 0 }, Piece { file: 3, rank: 0 }]
//   } else {
//     // Black: {1,4} and {3,4}.
//     [Piece { file: 1, rank: 4 }, Piece { file: 3, rank: 4 }]
//   };

//   // let commitment = pedersen_commitment([pieces.file as Field, pieces.rank as Field, salt]).x;
//   // commitment

//   pieces
// }
// END V1
