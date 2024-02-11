use dep::std::hash::{pedersen_hash, pedersen_commitment};
use dep::std::ec::swcurve::affine as sw;
use dep::std::ec::tecurve::affine as te;
use dep::std::ec::consts::te::baby_jubjub;

fn main() {
  let alpha = 420;
  let omega = 69;

  let bjj = baby_jubjub();

  let c__alpha = pedersen_commitment([alpha]);
  let c__omega = pedersen_commitment([omega]);

  let da_point = bjj.curve.elligator2_map(420);

  // ------------------------------------------- BABY JUBJUB.

  // Probably needs to be modulo bjj but cannot modulo Fields easily...
  // let bjj_h__alpha = pedersen_hash([alpha]); // In real world would include a salt.
  // let bjj_h__omega = pedersen_hash([omega]); // In real world would include a salt.

  // First parameters are secret salts.
  let bjj_h__alpha = bjj.curve.mul(12345, bjj.curve.elligator2_map(alpha));
  let bjj_h__alpha = bjj.curve.mul(67890, bjj.curve.elligator2_map(omega));

  // Create curve `Point`s from our hash by multiplying by generator.
  let bjj_p__alpha = bjj.curve.mul(bjj_h__alpha, bjj.curve.gen);
  let bjj_p__omega = bjj.curve.mul(bjj_h__omega, bjj.curve.gen);

  let bjj_c__add = bjj.curve.add(bjj_p__alpha, bjj_p__omega);

  // Add point for field value 420 to point of hashed field value 69.
  let bjj_c__check = bjj.curve.add(da_point, bjj_p__omega);

  dep::std::println(f""); // Start.

  dep::std::println(f"INPUTS");
  dep::std::println(f"  alpha: {alpha}  a");
  dep::std::println(f"  omega: {omega}  o");
  dep::std::println(f"");
  dep::std::println(f"");

  dep::std::println(f"BABY JUBJUB");
  // dep::std::println(f"       alpha hashed: {bjj_h__alpha}  ph(a)");
  // dep::std::println(f"       omega hashed: {bjj_h__omega}  ph(o)");
  dep::std::println(f"        alpha point: {bjj_h__alpha}  ph(a)");
  dep::std::println(f"        omega point: {bjj_h__alpha}  ph(a)");
  dep::std::println(f"");
  dep::std::println(f"        alpha point: {bjj_p__alpha}  bjj_mul(a, G1)");
  dep::std::println(f"        omega point: {bjj_p__omega}  bjj_mul(o, G1)");
  dep::std::println(f"");
  dep::std::println(f"    computed commit: {bjj_c__add}");
  dep::std::println(f"  homomorphic check: {bjj_c__check}");

  dep::std::println(f"");





  // let mah_value = sw::Point::new(420, 0);
  // dep::std::println(mah_value);
  // let bn254 = sw::Curve::new(21888242871839275222246405745257275088548364400416034343698204186575808495617, 3, sw::Point::new(1, 2));
  // let p__alpha = sw::Point::new(c__alpha.x, c__alpha.y);
  // let p__omega = sw::Point::new(c__omega.x, c__omega.y);
  // dep::std::println(p__alpha);
  // dep::std::println(p__omega);
  // let added = bn254.add(p__alpha, p__omega);
  // dep::std::println(f"added commit: {added}");
  // dep::std::println(bn254.swu_map(420, 0));

  // CONTROL (expect one of these to appear in COMPUTED).
  // let c__add_real = pedersen_commitment([alpha + omega]);
  // let c__mul_real = pedersen_commitment([alpha * omega]);
  // let c__dec_real = pedersen_commitment([alpha, omega]); // `dec` for `decompose`.

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
