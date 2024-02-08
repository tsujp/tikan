use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};

// OPT: Can use field comparison instead? See: https://github.com/noir-lang/noir/pull/4042
struct Piece {
  file: u8,
  rank: u8,
  lit: bool,
}

impl Piece {
  fn starting(file: u8, rank: u8) -> Self {
    Self {
      file,
      rank,
      lit: true,
    }
  }

  fn decompose(self) -> [Field; 3] {
    [
      self.file as Field,
      self.rank as Field,
      self.lit as Field,
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

impl Board {
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

  fn apply_move(self, move: Move) -> Self {
      // The only piece in this game (all pieces are the same type) can move omnidirectionally
      //   one square only.
      // Compute absolute difference movement of file and rank.
      let file_diff = if move.from_file > move.to_file { move.from_file - move.to_file } else { move.to_file - move.from_file };
      let rank_diff = if move.from_rank > move.to_rank { move.from_rank - move.to_rank } else { move.to_rank - move.from_rank };

      // TODO: Check player has that piece at that position to even move.

      // Move is valid if at most 1 chebyshev-distance in all axes is traversed.
      assert((file_diff <= 1) & (rank_diff <= 1), "Illegal move pattern");

      // TODO: Update players' piece state.

      Self {
        players: self.players,
        commits: self.commits, // TODO: Update.
        turn: !self.turn,
        halfmove: self.halfmove + 1,
      }
    }

  // - 3 members in `Piece`, 2 arrays of 2 `Pieces` = 3 * 2 * 2 = 12.
  // - 2 members in `PedersenPoint`, array of 2 = 2 * 2 = 4.
  // - Other `Board` members = 2.
  // = 12 + 4 + 2 = 18.
  fn decompose(self) -> [Field; 18] {
    let mut decomp = [0; 18];

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
      // Commitments.
      decomp[idx_offset] = self.commits[i].x;
      decomp[idx_offset + 1] = self.commits[i].y;
      idx_offset += 2;
    }

    dep::std::println(decomp);

    // [
    //   self.turn as Field,
    //   self.halfmove as Field,
    //   //
    //   self.players[0][0].file as Field,
    //   self.players[0][0].rank as Field,
    //   self.players[0][0].lit as Field,
    //   //
    //   self.players[0][1].file as Field,
    //   self.players[0][1].rank as Field,
    //   self.players[0][1].lit as Field,
    //   //
    //   self.players[1][0].file as Field,
    //   self.players[1][0].rank as Field,
    //   self.players[1][0].lit as Field,
    //   //
    //   self.players[1][1].file as Field,
    //   self.players[1][1].rank as Field,
    //   self.players[1][1].lit as Field,
    // ]

    decomp
  }
}

struct Move {
  from_file: u8,
  from_rank: u8,
  to_file: u8,
  to_rank: u8
}

impl Move {
  fn decompose(self) -> [Field; 4] {
    [
      self.from_file as Field,
      self.from_rank as Field,
      self.to_file as Field,
      self.to_rank as Field,
    ]
  }
}










// fn main(
//     verification_key : [Field; 114],
//     proof : [Field; 94],
//     public_inputs : [Field; 1],
//     key_hash : Field,
//     input_aggregation_object : [Field; 16],
//     proof_b : [Field; 94],
// ) -> pub [Field; 16] {
//     let output_aggregation_object_a = std::verify_proof(
//         verification_key.as_slice(),
//         proof.as_slice(),
//         public_inputs.as_slice(),
//         key_hash,
//         input_aggregation_object
//     );

//     let output_aggregation_object = std::verify_proof(
//         verification_key.as_slice(),
//         proof_b.as_slice(),
//         public_inputs.as_slice(),
//         key_hash,
//         output_aggregation_object_a
//     );

//     let mut output = [0; 16];
//     for i in 0..16 {
//         output[i] = output_aggregation_object[i];
//     }
//     output
// }
