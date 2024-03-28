#[recursive]
fn main (
    verification_key: [Field; 114],
    // proof: [Field; 93], /* Proof as fields 1 proof */
    // proof: [Field; 186], /* Proof as fields 2 proofs */
    proof: [Field; 1],
    public_inputs: [Field; 0],
    key_hash: Field
) {
    // Q: How to split a proof into fields? So given the big proof hex output how to split that correctly into fields. See how noir_js does it to start off with.

    let foo = dep::std::hash::hash_to_field(proof);
    dep::std::println(foo);

    // `proof` length must be a multiple of 93.

    // dep::std::verify_proof(
    //     verification_key.as_slice(),
    //     proof.as_slice(),
    //     public_inputs.as_slice(),
    //     key_hash
    // );
}
