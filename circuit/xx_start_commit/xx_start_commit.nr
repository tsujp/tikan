// Starting position for players.

// --------------------------------------------------------------
// --------------------------------------------------------------
// V1
use dep::std::hash::pedersen_commitment;
use dep::lib::{Piece, Board, PlayerPieces};

#[recursive]
fn main(board: pub Board, player: pub u1, pieces: pub PlayerPieces, salt: Field) -> pub Field {
  // Or `pedersen_hash` these pre-cursors and only `pedersen_commitment` the final?
  let board_hash = pedersen_commitment(board.decompose()).x;

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

  commitment
}
// END V1
