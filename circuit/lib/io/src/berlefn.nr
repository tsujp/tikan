// // TODO: Can implement LAN/SAN/UCI later on. For now using a custom move
// //       encoding that matches how the internal board state is represented
// //       moves things along more quickly (a less complex parser is required).

// // TODO: Move blinding for when fog is added, i.e. a way to specify that this
// //       is a move in fog.

// // BERLEF Notation (BERLEF-N) specifies:
// //   (1) From-square piece ID as specified in Board::Piece.
// //         * Pawn, Knight, Bishop, Rook, Queen, King as 2, 3, 4, 5, 6, 7 resp.
// //   (2) From-square coordinate as a BERLEF _index_ (0-63).
// //   (3) To-square coordinate as a BERLEF _index_ (0-63).
// //   (4) If to-square piece is captured (ASCII character 0x23 (hash/pound #)).
// //   (5) A piece ID if a pawn-promotion occurs with the ID as in Board::Piece.

// // All 5 fields are required, if no value is appropriate (i.e. with (4) and (5))
// //   then a single hyphen is used to stub it. All fields are separated by a
// //   single space.
// //     * NB: Pawns _can_ capture onto a promotion square (i.e. do both in a
// //           single turn).

// // All 5 fields, except those which are stubbed with a hyphen, are encoded with
// //   a simple ASCII-offset scheme. Starting at ASCII code 0x30 (number zero)
// //   the next 63 (total of 64) codepoints are used to represent integers 0-63.
// //   This way a simple subtraction of 0x30 from the given codepoint yields an
// //   integer (base64 or string-integer parsing would be much more complex).
// // * NB: Base64 could be used but would require looping a 64-element array (the
// //       base64 alphabet) to map values to. String-integers could be used i.e.
// //       '56' for index 56, butthe parser would need to be able to read '5' and
// //       then '6' and then perform (5 * 10) + 6 to give 56... but given the
// //       current features in Noir this gets ugly very quickly.

// // Example BERLEF-N moves; parens for example visible delimiting:
// //
// //   (1) Black: (2 ; K - -) = Black moves its pawn (2) at BERLEF-indexed square
// //                            11 (d7, as ; is ASCII 0x3b and 0x3b - 0x30 =
// //                            decimal 11) to BERLEF-indexed square 27 (d5);
// //                            a double pawn push.
// //
// //   (2) White: (2 ` X - -) = White moves its pawn (2) at BERLEF-indexed square
// //                            48 (a2) to BERLEF-indexed square 40 (d3); a single
// //                            pawn push.

// use dep::std::println;
// use dep::state::board::Piece as Piece;
// use dep::state::move::Move as Move;

// // TODO: Put these in a better place since it's copy-pastad from the FEN parser.
// global REQUIRED_LENGTH: u32 = 11;

// // TODO: Replace `str` with `[u8; MAX_LENGTH];`
// type Char = u8;
// type Chars<N> = [Char; N];
// type Berlefn = Chars<REQUIRED_LENGTH>;
// // END TODO

// struct Corpus {
//     codepoint_start: Char,
//     codepoint_end: Char,
//     capture: Char,
//     empty_value: Char,
//     segment_delimit: Char,
// }

// global CORPUS = Corpus {
//     codepoint_start: 0x30, // Integer ASCII codepoint start and end (inclusive).
//     codepoint_end: 0x6f,
//     capture: 0x23, // ASCII pound `#`
//     empty_value: 0x2d, // ASCII hyphen `-`
//     segment_delimit: 0x20, // ASCII space ` `
// };

// // Stage of parsing BERLEF-N input string.
// mod Stage {
//     global FROM_PIECE: Field = 0;
//     global FROM_SQUARE: Field = 1;
//     global TO_SQUARE: Field = 2;
//     global CAPTURE: Field = 3;
//     global PROMOTION_PIECE: Field = 4;

//     // TODO: Move blinding when fog of war.
// }

// struct Parser {
//     stage: Field,
//     move: Move,
// }

// impl Parser {
//     fn new() -> Self {
//         Self {
//             stage: 0,
//             move: Move::new(),
//         }
//     }

//     fn incr_stage(&mut self) {
//         self.stage += 1;
//     }
// }

// // Parameters `l` and `h` (low and high) form a _closed_ range (inclusive).
// fn parse_integer_range(c: Char, l: u8, h: u8, required: bool) -> u8 {
//     let _ = required; // To silence unused variable until it's used in TODO.
//     println(f"Is c{c} in range (u{l}, u{h})?");

//     let c_int = c - CORPUS.codepoint_start as u8;

//     // TODO: Actually use `required` flag (for `-` stub optionals returning
//     //       the correct value).
//     // TODO: This should be an assert so we can terminate on invalid integer.
//     if l <= c_int & c_int <= h {
//         println(f"    Yes: u{c_int}");
//     }

//     c_int
// }

// // TODO: None of the `empty_value` logic is implemented currently.
// pub fn parse_berlefn<T, N>(berlefn: [u8; N]) -> Move {
//     let mut berlefnParser = Parser::new();

//     let parsed = berlefn.fold(berlefnParser, |mut p: Parser, c| {
//         if c == CORPUS.segment_delimit {
//             p.incr_stage();
//         } else {
//             if p.stage == Stage::FROM_PIECE {
//                 p.move.set_from_piece(
//                     parse_integer_range(
//                         c,
//                         Piece::PAWN as u8,
//                         Piece::KING as u8,
//                         true
//                     )
//                 );
//             }

//             if p.stage == Stage::FROM_SQUARE {
//                 p.move.set_from_square(
//                     parse_integer_range(c, 0, 63, true)
//                 );
//             }

//             if p.stage == Stage::TO_SQUARE {
//                 p.move.set_to_square(
//                     parse_integer_range(c, 0, 63, true)
//                 );
//             }

//             // TODO: Capture and promotion piece logic.
//             // if p.stage == Stage::CAPTURE {
//             //     let capture = parse_integer_range(c, CORPUS.capture, CORPUS.capture, false);
//             // }

//             // if p.stage == Stage::PROMOTION_PIECE {
//             //     let piece_id = parse_integer_range(
//             //         c,
//             //         Piece::PAWN as u8,
//             //         Piece::KING as u8,
//             //         false
//             //     );
//             // }
//         }

//         p
//     });

//     parsed.move
// }
