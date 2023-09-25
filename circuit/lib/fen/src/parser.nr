use dep::std::println;
use dep::std::option::Option;

// Common idiom from Ruby to intentionally misspell a reserved keyword when
//   used internally as part of some abstracted functionality. There you may
//   spell `class` as `clazz` if it needs to be held in a variable for example.
use crate::types as Tipe;

// use dep::state::Foo;
// mod statez;
// use crate::statez::Board;
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

// bitboard: ~/programming/~aztec/tikan/circuit/lib/state/src/board/bitboard.nr

fn custom_any<T, N, Env>(arr: [T; N], f: fn[Env](T) -> (bool)) -> Option<T> {
    let mut ret = Option::none();

    for ele in arr {
        if f(ele) {
            ret = Option::some(ele);
        }
    };

    ret
}

struct Parser {
    stage: Field,
    square: u64,
    board: Board,
    // pawn_bb: u64,
}

impl Parser {
    fn new() -> Self {
        Self {
            stage: 0,
            square: 0,
            board: Board::new(),
            // pawn_bb: 0,
        }
    }

    fn incr_stage(&mut self) {
        self.stage += 1;
    }

    fn incr_square(&mut self, n: u64) {
        self.square += n;
    }

    fn foo(self) {
        println("fen parser foo called");
    }
}

// NB: Until bitshifting with a mix of constants and parameterised values is fixed
//     use this wrapper (and the corresponding for right-shifts) since it magically
//     fixes the problem and allows base-1 bitshifts.
// NB: Tracking issue: https://github.com/noir-lang/noir/issues/2399
fn bs_l(rdx: u64, n: u64) -> u64 {
    (rdx as u64) << n
}


fn parse_board_stage(p: &mut Parser, c: u8) {
    let __idx = p.square; // No expressions allowed in println.
    println(f"Board, idx: u{__idx}, c: c{c}");

    // No early return or loop continue, so must nest to avoid
    //   later code. If-else chains are much more expensive.
    if c == Tipe::CORPUS.rank_delimit {
        println(f"    -> rank delimiter, skip");
    } else {
        let is_p = of_pieces(Tipe::CORPUS.pawn, c);
        if is_p.is_some() {
            // let (plyr_idx, the_p): (u8, u8) = { is_p.unwrap() };
            let (plyr_idx, the_p): (u8, u8) = is_p.unwrap();
            println(f"    -> FOUND: c{the_p} for player: u{plyr_idx}");
            // NB: When bitshifting inline works again this can be replaced
            //     with `... |= 1 << a.square_index;`
            // p.pawn_bb |= bs_l(1, p.square);
            p.board.put_player_piece(plyr_idx, Piece::PAWN, p.square);
        }

        let en = custom_any(Tipe::CORPUS.empty_n, |noo| c == noo);

        if (en.is_some()) {
            let __en = en.unwrap_unchecked();
            // 0x30 is the offset at which ASCII digits start.
            let __en_val = __en - 0x30;
            println(f"    -> Empty square count: c{__en} -- u{__en_val}");
            p.incr_square(__en_val as u64);
        } else {
            // No early returns so this is here.
            p.incr_square(1);
        }
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
        if c == Tipe::CORPUS.segment_delimit {
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
                
        // No type-formatting yet (e.g. print as integer not hex) so tag
        //   manually and pipe through sed for a poor man's version.
        // println(f"u{i}    b{fa} b{fb} b{fc} b{fd} b{fe} b{ff} b{fg} b{fh}");

        // NB: No expressions in format strings currently.
        let i_disp_w = i_w + 1;
        println(f"u{i_disp_w}    u{fa_w} u{fb_w} u{fc_w} u{fd_w} u{fe_w} u{ff_w} u{fg_w} u{fh_w}");
    }

    println("+++++++++++++++++++++++++++++++++++++++");

    fenParser.board
}

// NB: Cannot use custom type for `want` (see NB for `Corpus` struct; the
//     compiler will panic).
fn of_pieces(want: [Tipe::Char; 2], check: Tipe::Char) -> Option<(u8, Tipe::Char)> {
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

#[test]
fn test_of_pieces() {
    let t_1 = of_pieces(Tipe::CORPUS.pawn, Tipe::CORPUS.w_pawn);
    // assert(t_1.unwrap().0 == 0);
    assert_eq(t_1.unwrap().0, 0);

    let t_2 = of_pieces(Tipe::CORPUS.pawn, 0x00);
    // assert(t_2.is_some(), "NUL byte is not a valid FEN piece character");
    // assert(t_2.is_some() == true);

    // if t_1.is_some() {
    //     let (plyr_idx, the_p): (u8, u8) = t_1.unwrap();
    //     assert(plyr_idx == 0);
    // }
}

fn stb_parse_fen<T, N>(input_fen: str<N>) -> Board {
    parse_fen(input_fen.as_bytes())
}

#[test]
fn test_parse_fen() {
    // let foo = stb_parse_fen("4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
    stb_parse_fen("4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1");
    let foo = 0;

    // assert(foo == 0);
    assert_eq(foo, 0);
}
