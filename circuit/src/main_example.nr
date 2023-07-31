use dep::std;

fn is_equal(a : Field, b : Field) -> bool {
    a == b
}

fn main(x : Field, y : pub Field) {
    // assert(x != y);
    assert(is_equal(x, y));
}

#[test]
fn test_main() {

    assert(is_equal(1, 2) == false);
    assert(is_equal(1, 5) == false);
    assert(is_equal(1, 1) == true);
    assert(is_equal(5, 5) == true);

    // Uncomment to make test fail
    // main(1, 1);
}
