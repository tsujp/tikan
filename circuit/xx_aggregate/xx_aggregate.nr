use dep::lib::{BOARD_ORDINAL, MOVE_ORDINAL};

#[recursive]
fn main(
    public: [Field; (BOARD_ORDINAL + MOVE_ORDINAL) * 2],
    // proof: [Field; 93 + BOARD_ORDINAL + MOVE_ORDINAL],
    proof: [Field; 93],
    vk: [Field; 114],
    vk_hash: Field,
) {
    dep::std::verify_proof(vk.as_slice(), proof.as_slice(), public.as_slice(), vk_hash);
}
