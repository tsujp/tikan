use dep::std::hash::{pedersen_hash, pedersen_commitment, PedersenPoint};
use dep::std::ec::swcurve::affine as sw;
use dep::std::ec::tecurve::affine as te;
use dep::std::ec::consts::te::baby_jubjub;


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


fn main() {
  let alpha = 420;
  let omega = 69;

  // ------------------------------------------- BABY JUBJUB.

  let bjj = baby_jubjub();

  let alpha_real = pedersen_commitment([alpha]);
  let omega_real = pedersen_commitment([omega]);

  let both_real = pedersen_commitment([alpha, omega]);
  let both_real_2 = pedersen_commitment([alpha_real.y, alpha_real.x, omega_real.x, omega_real.y]);

  // Points on bjj curve for field values.
  let bjj_p__alpha = bjj.curve.elligator2_map(alpha);
  let bjj_p__omega = bjj.curve.elligator2_map(alpha);

  let bjj_h__alpha = pedersen_commitment([alpha]).x;
  let bjj_h__omega = pedersen_commitment([omega]).x;

  // First parameters are salts; this binds us to our secret value (alpha or omega).
  // let bjj_h__alpha = bjj.curve.mul(alpha_salt, bjj_p__alpha);
  // let bjj_h__omega = bjj.curve.mul(omega_salt, bjj_p__omega);

  // Hide our hashed values by adding them to known points on the bjj curve.
  let bjj_c__alpha = bjj.curve.mul(bjj_h__alpha, bjj.base8);
  let bjj_c__omega = bjj.curve.mul(bjj_h__omega, bjj.base8);

  // Create a vector of commitments by adding two together.
  let bjj_c__real = bjj.curve.add(bjj_c__alpha, bjj_c__omega);

  // Add point for field value 420 to point of hashed field value 69.
  let bjj_c__check = bjj.curve.mul(bjj_h__alpha, bjj_p__alpha);

  dep::std::println(f""); // Start.

  dep::std::println(f"[[INPUTS]]");
  dep::std::println(f"  alpha: {alpha}  a");
  dep::std::println(f"  omega: {omega}    o");
  dep::std::println(f"");
  dep::std::println(f"");

  dep::std::println(f"[[BABY JUBJUB]]");
  dep::std::println(f"        alpha commit: {alpha_real}  pc(a)");
  dep::std::println(f"        omega commit: {omega_real}  pc(o)");
  dep::std::println(f"         both commit: {both_real}  pc(a, o)");
  dep::std::println(f"         both commit: {both_real_2}  pc(a, o)");
  dep::std::println(f"");
  // dep::std::println(f"       alpha hashed: {alpha_hash}  ");
  dep::std::println(f"       omega hashed: {bjj_p__omega}  bjj_mul(o, salt)");
  dep::std::println(f"");
  dep::std::println(f"       alpha commit: {bjj_p__alpha}  bjj_add(a, G1)");
  dep::std::println(f"       omega commit: {bjj_c__omega}  bjj_add(o, G1)");
  dep::std::println(f"");
  dep::std::println(f"    computed commit: {bjj_c__real}");
  dep::std::println(f"  homomorphic check: {bjj_c__check}");

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
