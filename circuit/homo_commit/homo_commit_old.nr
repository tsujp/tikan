use dep::std::hash::{pedersen_commitment, PedersenPoint};
// use dep::std::ec::swcurve::affine::{Curve, Point};
use dep::std::ec::swcurve::affine as sw_aff;
use dep::std::ec::montcurve::affine as mn_aff;

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

  let c__alpha = pedersen_commitment([alpha]);
  let c__omega = pedersen_commitment([omega]);

  let grump_b = 0x34394632b724eaacc388229877910c0223fa97acb319311dd7056026000005a;
  let grump_y = 0x14b34cf69dc25d68aa7b8cf435dfafbb23d3446f21c77dc311b2dff1448c41d8;

  let grumpkin = mn_aff::Curve::new(0, grump_b, mn_aff::Point::new(1, grump_y)); // grumpkin.


  // let bn254 = sw_aff::Curve::new(0, 3, sw_aff::Point::new(1, 2)); // bn254.

  // grumpkin `b`
  // 0xdd7056026000005a, 0x223fa97acb319311, 0xcc388229877910c0, 0x34394632b724eaa
  // 0x34394632b724eaacc388229877910c0223fa97acb319311dd7056026000005a

  // grumpkin `y`
  // 0x11b2dff1448c41d8UL, 0x23d3446f21c77dc3UL, 0xaa7b8cf435dfafbbUL, 0x14b34cf69dc25d68UL
  // 0x14b34cf69dc25d68aa7b8cf435dfafbb23d3446f21c77dc311b2dff1448c41d8

  let grump_b = 0x34394632b724eaacc388229877910c0223fa97acb319311dd7056026000005a;
  let grump_y = 0x14b34cf69dc25d68aa7b8cf435dfafbb23d3446f21c77dc311b2dff1448c41d8;

  let grump_1 = sw_aff::Curve {
    a: 1,
    b: grump_b,
    gen: sw_aff::Point::new(1, grump_y)
  };

  dep::std::println(f"what");
  dep::std::println(grump_1.swu_map(1, 420));

  // let bn254 = mn_aff::Curve::new( 0x34394632b724eaacc388229877910c0223fa97acb319311dd7056026000005a, mn_aff::Point::new(1, 0x14b34cf69dc25d68aa7b8cf435dfafbb23d3446f21c77dc311b2dff1448c41d8)); // grumpkin.

  // let mah_value = Point::new(420, 0);
  // dep::std::println(mah_value);
  // let bjj = Curve::new(0, -17, Point::new(1, 2));
  // let p__alpha = sw_aff::Point::new(c__alpha.x, c__alpha.y);
  // let p__omega = sw_aff::Point::new(c__omega.x, c__omega.y);
  // dep::std::println(p__alpha);
  // dep::std::println(p__omega);
  // let added = bn254.add(p__alpha, p__omega);
  // dep::std::println(added);

  // CONTROL (expect one of these to appear in COMPUTED).
  let c__add_real = pedersen_commitment([alpha + omega]);
  let c__mul_real = pedersen_commitment([alpha * omega]);
  let c__dec_real = pedersen_commitment([alpha, omega]); // `dec` for `decompose`.

  // COMPUTED (attempted homomorphic equivalent).
  let c__add_commit = add_pc(c__alpha, c__omega);
  let c__mul_commit = mul_pc(c__alpha, c__omega);
  // let c__dec_commit = pedersen_commitment([c__alpha.x, c__alpha.y, c__omega.x, c__omega.y]);
  let c__dec_commit = pedersen_commitment([1]);

  let c__dec_commit_a = pedersen_commitment([add_pc(c__alpha, c__omega)]);
  let c__dec_commit_b = pedersen_commitment([mul_pc(c__alpha, c__omega)]);
  let bar = c__alpha.x + omega;
  let foo = c__alpha.x * omega;

  dep::std::println(f""); // Start.

  dep::std::println(f"INPUTS");
  dep::std::println(f"  alpha (a): {alpha}  =>  {c__alpha} c(a)");
  dep::std::println(f"  omega (o): {omega}    =>  {c__omega} c(o)");

  dep::std::println(f"");
  dep::std::println(f"CONTROL  (real)");
  dep::std::println(f"  add: {c__add_real}   c(a + o)");
  dep::std::println(f"  mul: {c__mul_real}   c(a * o)");
  dep::std::println(f"  dec: {c__dec_real}   c(a , o)");

  dep::std::println(f"");
  dep::std::println(f"COMPUTED (commits)");
  dep::std::println(f"  add: {c__add_commit}   c(a) + c(o)");
  dep::std::println(f"  mul: {c__mul_commit}   c(a) * c(o)");
  dep::std::println(f"  dec: {c__dec_commit} c(c(a) , c(o))");

  dep::std::println(f"  dec: {c__dec_commit_a}");
  dep::std::println(f"  dec: {c__dec_commit_b}");
  dep::std::println(f"bar: {bar}");
  dep::std::println(f"foo: {foo}");


  dep::std::println(f""); // End.
}
