use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::std::println as puts;
use dep::std::print as put;


fn main() {
  let ting = 101 / 5; // 20.2 i.e. 20 floor integer, i.e. 0x14 hex.

  let wat = 10 / 4;

  puts(19 / 5);

  // puts((101 * ting) - ting);

  puts(ting - (ting * (1/101)));

  // puts(wat * 2);

  // puts(ting - (1 / 5));


  let numer = 101;
  let denom = 6;

  let res = numer / denom;
  puts(res);
  puts((res * (denom/numer)) - res);
  puts("");
  puts("");
  puts("");

  puts(101 / 4);
  puts(101 / 5);
  puts(101 / 6);
}
