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

type PlayerPieces = [Piece; 2];

struct Board {
  // Pieces for each player.
  players: [PlayerPieces; 2],
  // Player's turn.
  turn: u1,
  halfmove: u8,
}

impl Board {
  fn starting() -> Self {
    Self {
      players: [
        [Piece::starting(1, 0), Piece::starting(3, 0)],
        [Piece::starting(1, 4), Piece::starting(3, 4)],
      ],
      turn: 0,
      halfmove: 0,
    }
  }

  // 3 members in `Piece`, 2 arrays of 2 `Pieces` = 3 * 2 * 2 = 12.
  // Other `Board` members = 2.
  // = 12 + 2 = 14.
  fn decompose(self) -> [Field; 14] {
    let mut decomp = [0; 14];

    decomp[0] = self.turn as Field;
    decomp[1] = self.halfmove as Field;

    let mut idx_offset = 2;

    for i in 0..self.players.len() {
      for j in 0..self.players[i].len() {
        let pce_decomp = self.players[i][j].decompose();
        for k in 0..pce_decomp.len() {
          decomp[idx_offset] = pce_decomp[k];
          idx_offset += 1;
        }
      }
    }

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
