use dep::std::println;
use dep::std::option::Option;

// Really zkFEN types hence alias.
use crate::types as FEN;

use dep::state::board::Board as Board;
use dep::state::board::Piece as Piece;

// Ideally an array of unit structs (or an enum) which can be pattern-matched
//   over (unit structs better as a type system) but neither approach is easily
//   possible in Noir currently (0.10.3) so a simple integer to control parsing
//   stages is used.

// Parsing stages.
// NB: No unit structs or enums in Noir so this pattern instead.
mod Stage {
    global BOARD: Field = 0;
    global TURN: Field = 1;
    global CASTLE: Field = 2;
    global PASSANT: Field = 3;
    global HALFMOVE: Field = 4;
    global FULLMOVE: Field = 5;

    // TODO: Stages for Pedersen hash when fog of war.
}

// TODO: PR for this into the standard library.
// Find is like `any` except it returns the matched value.
fn find<T, N, Env>(arr: [T; N], f: fn[Env](T) -> (bool)) -> Option<T> {
    let mut ret = Option::none();

    for ele in arr {
        if f(ele) {
            ret = Option::some(ele);
        }
    };

    ret
}

struct Parser {
    // Stage of parsing.
    stage: Field,
    // Square index we're at.
    square: u64,
    // Two-by-six '2x6' bitboard serialised gamestate.
    board: Board,
    // TODO: State commitment here or as part of Board? Probably as part of Board.
}

impl Parser {
    fn new() -> Self {
        Self {
            stage: 0,
            square: 0,
            board: Board::new(),
        }
    }

    fn incr_stage(&mut self) {
        self.stage += 1;
    }

    fn incr_square(&mut self, n: u64) {
        self.square += n;
    }
}


// Commonly want to check if an option is `Some`, then unwrap it and run a
//   side-effect. Existing `Option` methods require return values which
//   pollutes code if all we care about is maybe doing some logic.
fn maybe_do<T, Env>(d: Option<T>, f: fn[Env](T) -> ()) {
    if d.is_some() {
        f(d.unwrap_unchecked());
    }
}


// Returns a tuple of enums (board::Piece) representing the piece and player
//   found for the character checked. (TODO: When proper enums, real typing).
fn piece_for_player(check: FEN::Char) -> Option<(Field, Field)> {
    // This implementation simplifies a much longer if-else chain at the
    //   call-site and itself adds a negligible amount of gates as the loops
    //   involved check the same quantity of values as doing so manually
    //   with boolean logic which cannot be short-circuited in Noir.
    let mut ret = Option::none();

    // Enum board::Piece values WHITE and BLACK occupy 0 and 1 respectively
    //   so piece values start at 2.
    let mut piece_idx = 2;

    for piece_tuples in FEN::PIECE_SEARCH_ORDER {
        let mut player_idx = 0;

        for w in piece_tuples {
            if check == w {
                ret = Option::some((player_idx, piece_idx));
            }

            player_idx += 1;
        };

        piece_idx += 1;
    };

    ret
}


fn parse_board_stage(p: &mut Parser, c: u8) {
    // let __idx = p.square; // No expressions allowed in println.
    // println(f"Board, idx: u{__idx}, c: c{c}");

    // No early return or loop continue, so must nest to avoid; if-else chains
    //   are much more expensive.
    if c != FEN::CORPUS.rank_delimit {
        // Check if current character `c` is a valid integer (as ASCII) in zkFEN
        //   string which represents the sequential count of empty squares.
        
        let idx_increment = find(FEN::CORPUS.empty_n, |num| c == num);

        // Not a valid integer we care about, probably a piece.
        if idx_increment.is_none() {
            maybe_do(
                piece_for_player(c),
                |(player, piece): (Field, Field)| {
                    // println(f"foo u{player} bar c{piece}");
                    p.board.put_player_piece(player, piece, p.square);
                }
            );
        }

        // Ifthere is no valid empty-count then increment the square index by
        //   1 since we must have read a piece.
        // 0x30 is the offset at which ASCII digits start.
        p.incr_square(idx_increment.map_or(1, |ascii_num| ascii_num - 0x30) as u64);
    }
}


// Parse zkFEN string to valid bitboard. Recursive parser not used since zkFEN
//   is a linear structure and not a tree.
pub fn parse_fen<T, N>(fen: [u8; N]) -> Board {
    let mut fenParser = Parser::new();

    // NB: Could use a generic on our fen parser but because we must explicitly
    //     annotate the type on the fold closure it gets syntatically messy
    //     very quickly... hence not doing so.
    let parsed = fen.fold(fenParser, |mut p: Parser, c| {
    
        // NB: Yes nested if-else and chains of if-else is nasty BUT that is
        //     the only path-forking control flow in Noir currently. If/when
        //     switch-case or match enter the language those can be used. It
        //     may be possible to approximate this using zeroed datastructures
        //     and options but that can be saved as an experiment for later.
        // TODO: Parsing for Pedersen hash when fog of war.
        // NB: Looks like _not_ using if-else here reduces circuit size?
        
        // No early return, need to nest.
        if c == FEN::CORPUS.segment_delimit {
            p.incr_stage();
        } else {       
            if p.stage == Stage::BOARD {
                parse_board_stage(&mut p, c);
            }

            if p.stage == Stage::TURN {
                println("parse turn");
            } 

            if p.stage == Stage::CASTLE {
                println("parse castle");
            } 

            if p.stage == Stage::PASSANT {
                println("parse en passant");
            } 

            if p.stage == Stage::HALFMOVE {
                println("parse halfmove");
            } 

            if p.stage == Stage::FULLMOVE {
                println("parse fullmove");
            }
        }

        // TODO: Parsing for Pedersen hash when fog of war.

        p
    });

    println("=> ENTIRE BOARD +++++++++++++++++++++++");


    // println(parsed.pawn_bb);
    // let attempt = parsed.pawn_bb as Field;
    let attempt = parsed.board.pieces[Piece::PAWN].data as Field;
    println(f"Board as integer: {attempt}");
    let mut arr = [0; 64];
    let bits = attempt.to_le_bits(64);
    for i in 0..64 {
        arr[i] = bits[i];
    }

    // No array slicing so do this (could also index literally but nah).
    println(f"        a    b    c    d    e    f    g    h");

    // NB: Cannot print without a newline i.e. no `print` only `println` and
    //     a format string with the rank number prepended panics the
    //     Nargo compiler for whatever reason so need to hardcode this.
    for i in 0..8 {
        let fa = bits[(i * 8) + 0];
        let fb = bits[(i * 8) + 1];
        let fc = bits[(i * 8) + 2];
        let fd = bits[(i * 8) + 3];
        let fe = bits[(i * 8) + 4];
        let ff = bits[(i * 8) + 5];
        let fg = bits[(i * 8) + 6];
        let fh = bits[(i * 8) + 7];
                
        // No type-formatting yet (e.g. print as integer not hex) so tag
        //   manually and pipe through sed for a poor man's version.
        // println(f"u{i}    b{fa} b{fb} b{fc} b{fd} b{fe} b{ff} b{fg} b{fh}");

        // NB: No expressions in format strings currently.
        let i_disp = i + 1;
        println(f"u{i_disp}    u{fa} u{fb} u{fc} u{fd} u{fe} u{ff} u{fg} u{fh}");
    }

    println("+++++++++++++++++++++++++++++++++++++++");


    println("=> WHITE BOARD +++++++++++++++++++++++");

    // println(parsed.pawn_bb);
    // let attempt = parsed.pawn_bb as Field;
    let attempt_w = parsed.board.pieces[Piece::WHITE].data as Field;
    let mut arr_w = [0; 64];
    let bits_w = attempt_w.to_le_bits(64);
    for i_w in 0..64 {
        arr_w[i_w] = bits_w[i_w];
    }

    // No array slicing so do this (could also index literally but nah).
    println(f"        a    b    c    d    e    f    g    h");

    // NB: Cannot print without a newline i.e. no `print` only `println` and
    //     a format string with the rank number prepended panics the
    //     Nargo compiler for whatever reason so need to hardcode this.
    for i_w in 0..8 {
        let fa_w = bits_w[(i_w * 8) + 0];
        let fb_w = bits_w[(i_w * 8) + 1];
        let fc_w = bits_w[(i_w * 8) + 2];
        let fd_w = bits_w[(i_w * 8) + 3];
        let fe_w = bits_w[(i_w * 8) + 4];
        let ff_w = bits_w[(i_w * 8) + 5];
        let fg_w = bits_w[(i_w * 8) + 6];
        let fh_w = bits_w[(i_w * 8) + 7];
                
        // NB: No expressions in format strings currently.
        let i_disp_w = i_w + 1;
        println(f"u{i_disp_w}    u{fa_w} u{fb_w} u{fc_w} u{fd_w} u{fe_w} u{ff_w} u{fg_w} u{fh_w}");
    }

    println("+++++++++++++++++++++++++++++++++++++++");

    fenParser.board
}

fn of_pieces(want: FEN::Chars<2>, check: FEN::Char) -> Option<(u8, FEN::Char)> {
    let mut ret = Option::none();

    let mut idx = 0;
    for w in want {
        if check == w {
            ret = Option::some((idx, check));
        }

        idx += 1;
    };

    ret
}

// #[test]
// fn test_of_pieces() {
//     let t_1 = of_pieces(FEN::CORPUS.pawn, FEN::CORPUS.w_pawn);
//     // assert(t_1.unwrap().0 == 0);
//     assert_eq(t_1.unwrap().0, 1);

//     let t_2 = of_pieces(FEN::CORPUS.pawn, 0x00);
//     // assert(t_2.is_some(), "NUL byte is not a valid FEN piece character");
//     assert(t_2.is_some() == true);

//     // if t_1.is_some() {
//     //     let (plyr_idx, the_p): (u8, u8) = t_1.unwrap();
//     //     assert(plyr_idx == 0);
//     // }
// }

// fn stb_parse_fen<T, N>(input_fen: str<N>) -> Board {
//     parse_fen(input_fen.as_bytes())
// }

// #[test]
// fn test_parse_fen() {
//     // let foo = stb_parse_fen("4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
//     stb_parse_fen("4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
//     let foo = 0;

//     // assert(foo == 0);
//     assert_eq(foo, 0);
// }
