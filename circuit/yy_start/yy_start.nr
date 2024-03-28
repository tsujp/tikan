#[recursive]
fn main (
    some_num: u64
) {
    assert(some_num > 1);
}

#[test]
fn foo_test() {
    main(
        69
    );
}
