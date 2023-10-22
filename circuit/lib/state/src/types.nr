// 64 bits used for the 64 squares in a chess board. Strictly
//   speaking this is a _bitFIELD_ but _bitBOARD_ better
//   describes how we use the bitfield and is the nomenclature
//   in Chess software.
type Bitboard = u64;
type BitboardIndex = u6; // 6-bits required to index 64-bit bitboard.
