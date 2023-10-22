// TODO: These may be removeable once #3227 fixed: https://github.com/noir-lang/noir/issues/3227

// XXX: Using `pow_32` requires a seperate variable first... so this.
global MAX_U64: u64 = 18446744073709551615;

// XXX: Integer generics not working here, plus no way to template the assertion
//      message anyway.

// [WAT1]
// Integer types (let x: u6) and casts (foo as u12) result in the variable value
//   being its assigned value modulo the maximum value of its data type. So
//   `x` if set to `y` will be `y % 2^6`; `foo` would be `y % 2^12`. This means
//   assigning huge and obviously incorrect values to integers results in
//   modulo-remainder value assignment which is not obvious. Reported #3227.
// The workaround is to accept a Field, cast manually, and in addition to range
//   checking also check the expanded-cast (back to a Field) has not been
//   modulo-aletered.

pub fn assert_u64(u: Field) -> u64 { // WAT1
    let u_cast: u64 = u as u64;

    assert(
        // WAT1
        (u == u_cast as Field) & 0 <= u_cast & u_cast <= MAX_U64,
        "Given value is NOT within closed range 0 - 2^64 (18446744073709551615)."
    );

    u_cast
}

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
