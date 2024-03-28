use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::std::println as puts;
use dep::std::print as put;


// Sum of x and y points of two pedersen commitments.
fn add_pc(a: PedersenPoint, b: PedersenPoint) -> Field {
  a.x + a.y + b.x + b.y
}

// XXX: Really some weird dot-product thing.
// Product of two pedersen commitments after summing each commitments x and y points.
fn mul_pc(a: PedersenPoint, b: PedersenPoint) -> Field {
  (a.x + a.y) * (b.x + b.y)
}

// Product of x and y points of two pedersen commitments.
fn prd_pc(a: PedersenPoint, b: PedersenPoint) -> Field {
  a.x * a.y * b.x * b.y
}


fn put_pc(pc: PedersenPoint) {
  let x = pc.x;
  let y = pc.y;
  put(f"{{x}, {y}}");
}

fn puts_pc(pc: PedersenPoint) {
  put_pc(pc);
  puts("");
}


fn main() {
  let alpha = 1;
  let gamma = 2;

  let omega = alpha + gamma;

  let alpha_real = pedersen_commitment([alpha]);
  let gamma_real = pedersen_commitment([gamma]);
  // Omega serves as the value we want to get to 'manually'.
  let omega_real = pedersen_commitment([omega]);

  // Order matters in the case of 2 and 3; 1,2,3 all produce different values.
  let hm_1 = pedersen_commitment([0, add_pc(alpha_real, gamma_real)]);
  let hm_2 = pedersen_commitment([mul_pc(alpha_real, gamma_real)]);
  let hm_3 = pedersen_commitment([prd_pc(alpha_real, gamma_real)]);

  let hm_4 = pedersen_commitment([alpha_real.x * gamma, alpha_real.y * gamma]);
  let hm_5 = pedersen_commitment([alpha_real.y, alpha_real.x, gamma]);
  let hm_6 = pedersen_hash([alpha]);
  let hm_7 = pedersen_hash([gamma]);
  let hm_8 = pedersen_hash([omega]);
  let hm_9 = pedersen_hash([hm_6 + gamma, 0]);
  // let hm_5 = pedersen_commitment([alpha_real]);


  puts(f"--------------------------------------------"); // Start.

  puts("[[INPUTS]]");
  puts(f"  alpha  a: {alpha}");
  puts(f"  gamma  g: {gamma}");
  puts("");
  puts(f"  omega  o: {omega}  (a + g)");
  puts("");
  puts("");

  puts("[[STDLIB COMMITMENTS]]");
  put("  alpha commit  pc(a): "); puts_pc(alpha_real);
  put("  gamma commit  pc(g): "); puts_pc(gamma_real);
  puts("");
  put("  omega commit  pc(o): "); puts_pc(omega_real);
  puts("");
  puts("");

  puts("[[HOMOMORPHIC ATTEMPTS]]");
  put("  hm_1  pc(a + o): "); puts_pc(hm_1);
  put("  hm_2  pc(a, o):  "); puts_pc(hm_2);
  put("  hm_3  pc(o, a):  "); puts_pc(hm_3);
  puts_pc(hm_4);
  puts_pc(hm_5);
  puts(hm_6);
  puts(hm_7);
  puts(hm_8);
  puts(hm_9);
  // dep::std::println(f"        alpha commit: {alpha_real}  pc(a)");
  // dep::std::println(f"        omega commit: {omega_real}  pc(o)");
  // dep::std::println(f"         both commit: {both_real}  pc(a, o)");
  // dep::std::println(f"         both commit: {both_real_2}  pc(a, o)");
  // dep::std::println(f"");
  // // dep::std::println(f"       alpha hashed: {alpha_hash}  ");
  // dep::std::println(f"       omega hashed: {bjj_p__omega}  bjj_mul(o, salt)");
  // dep::std::println(f"");
  // dep::std::println(f"       alpha commit: {bjj_p__alpha}  bjj_add(a, G1)");
  // dep::std::println(f"       omega commit: {bjj_c__omega}  bjj_add(o, G1)");
  // dep::std::println(f"");
  // dep::std::println(f"    computed commit: {bjj_c__real}");
  // dep::std::println(f"  homomorphic check: {bjj_c__check}");

  dep::std::println(f"");


  // ------------------------------------------- BN254 PEDERSEN.

  // let bn254 = sw::Curve::new(21888242871839275222246405745257275088548364400416034343698204186575808495617, 3, sw::Point::new(1, 2));
  // let bn254 = sw::Curve::new(0, 3, sw::Point::new(1, 2));

  // // Compute commitments.
  // let c__alpha = pedersen_commitment([alpha_salt + alpha]);
  // let c__omega = pedersen_commitment([omega_salt + omega]);

  // // Convert `PedersenPoint` to `Point` so we can call `.add()`.
  // let p__alpha = sw::Point::new(c__alpha.x, c__alpha.y);
  // let p__omega = sw::Point::new(c__omega.x, c__omega.y);

  // dep::std::println(p__alpha);
  // dep::std::println(p__omega);

  // let c__real = bn254.add(p__alpha, p__omega);
  // dep::std::println(f"added commit: {c__real}");

  // // CONTROL (expect one of these to appear in COMPUTED).
  // let c__add_real = pedersen_commitment([c__alpha.x * c__alpha.y * c__omega.x * c__omega.y, alpha_salt * omega_salt]);
  // let c__mul_real = pedersen_commitment([alpha * omega, alpha_salt * omega_salt]);
  // let c__dec_real = pedersen_commitment([alpha, omega, alpha_salt,omega_salt]); // `dec` for `decompose`.

  // // COMPUTED (attempted homomorphic equivalent).
  // let c__add_commit = add_pc(c__alpha, c__omega);
  // let c__mul_commit = mul_pc(c__alpha, c__omega);
  // // let c__dec_commit = pedersen_commitment([c__alpha.x, c__alpha.y, c__omega.x, c__omega.y]);
  // let c__dec_commit = pedersen_commitment([1]);

  // let c__dec_commit_a = pedersen_commitment([add_pc(c__alpha, c__omega)]);
  // let c__dec_commit_b = pedersen_commitment([mul_pc(c__alpha, c__omega)]);
  // let bar = c__alpha.x + omega;
  // let foo = c__alpha.x * omega;

  // dep::std::println(f""); // Start.

  // dep::std::println(f"INPUTS");
  // dep::std::println(f"  alpha (a): {alpha}  =>  {c__alpha} c(a)");
  // dep::std::println(f"  omega (o): {omega}    =>  {c__omega} c(o)");

  // dep::std::println(f"");
  // dep::std::println(f"CONTROL  (real)");
  // dep::std::println(f"  add: {c__add_real}   c(a + o)");
  // dep::std::println(f"  mul: {c__mul_real}   c(a * o)");
  // dep::std::println(f"  dec: {c__dec_real}   c(a , o)");

  // dep::std::println(f"");
  // dep::std::println(f"COMPUTED (commits)");
  // dep::std::println(f"  add: {c__add_commit}   c(a) + c(o)");
  // dep::std::println(f"  mul: {c__mul_commit}   c(a) * c(o)");
  // dep::std::println(f"  dec: {c__dec_commit} c(c(a) , c(o))");

  // dep::std::println(f"  dec: {c__dec_commit_a}");
  // dep::std::println(f"  dec: {c__dec_commit_b}");
  // dep::std::println(f"bar: {bar}");
  // dep::std::println(f"foo: {foo}");


  // dep::std::println(f""); // End.
}
