use dep::std;
 
// Pretend 4x4 board to start off with, so 16 bits.

// One type of piece in this pretend scenario so a total of 2 bitmask arrays
//   of 16 bits for each array. The first is the positions and the second is
//   the pieces which have their lights on.
// OR this could be done with a single 32 bit array per piece for a 4x4 board
//   as each pair of bits is [position, lights-on] respectively.



// `opponent_board` - pedersen hash of opponents board pieces
fn main(opponent_board: pub Field, army: u32) {
    // assert(x != y);
    assert(is_equal(x, y));
}