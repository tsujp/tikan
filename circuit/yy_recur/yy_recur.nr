#[recursive]
fn main (
    verification_key: [Field; 114],
    proof: [Field; 93], /* Proof as fields */
    public_inputs: [Field; 0],
    key_hash: Field
) {
    dep::std::verify_proof(
        verification_key.as_slice(),
        proof.as_slice(),
        public_inputs.as_slice(),
        key_hash
    );
}
