use dep::std::println;

// Poor man's enum of player types (by who moves first).
mod Player {
    global WHITE: Field = 0;
    global BLACK: Field = 1;
}


// 64 bits used for the 64 squares in a chess board. Strictly
//   speaking this is a _bitFIELD_ but _bitBOARD_ better
//   describes how we use the bitfield and is the nomenclature
//   in Chess software.
type Bitboard = u64;
type BitboardIndex = u6; // 6-bits required to index 64-bit bitboard.


// TODO: Move all of these to some utlity file:

// XXX: Using `pow_32` requires a seperate variable first... so this.
global MAX_U64: u64 = 18446744073709551615;

pub fn assert_u64(u: Field) -> u64 { // WAT1
    let u_cast: u64 = u as u64;

    assert(
        // WAT1
        (u == u_cast as Field) & 0 <= u_cast & u_cast <= MAX_U64,
        "Given value is NOT within closed range 0 - 2^64 (18446744073709551615)."
    );

    u_cast
}


// TODO: Currently impossible to make this generic, no way to specify a
//       generic integer type (without a lot of custom code).
// Checks the given u6 is within range 0 - 63 since Nargo will happily compile
//   if giving a value >u6.
pub fn assert_u6(u: Field) -> u6 { // WAT1
    let u_cast: u6 = u as u6;

    assert(
        // WAT1
        (u == u_cast as Field) & 0 <= u_cast & u_cast <= 63,
        "Given value is NOT within closed range 0 - 63."
    );

    u_cast
}

pub fn assert_u4(u: Field) -> u4 { // WAT1
    let u_cast: u4 = u as u4;

    assert(
        // WAT1
        (u == u_cast as Field) & 0 <= u_cast & u_cast <= 15,
        "Given value is NOT within closed range 0 - 15."
    );

    u_cast
}

pub fn assert_u1(u: Field) -> u1 { // WAT1
    let u_cast: u1 = u as u1;

    assert(
        // WAT1
        (u == u_cast as Field) & 0 <= u_cast & u_cast <= 1,
        "Given value is NOT within closed range 0 - 1."
    );

    u_cast
}
// struct Bitboard {
//     data: Bitfield,
// }


// impl Bitboard {
//     pub fn new() -> Self {
//         Self {
//             data: 0,
//         }
//     }
// }
