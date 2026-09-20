use std::hash::poseidon::bn254::hash_1;
use std::hash::poseidon::bn254::hash_2;
use binary_merkle_root::binary_merkle_root;

fn main(
    nullifier_hash: pub Field,
    root: pub Field,
    vote: pub bool,
    depth: pub u32,
    nullifier: Field,
    secret: Field,
    index: Field,
    siblings: [Field; 16],
) {
    assert(nullifier_hash == hash_1([nullifier]));
    let commitment = hash_2([nullifier, secret]);
    let computed_root = binary_merkle_root::compute_merkle_root(commitment, index, siblings, depth);
    assert(computed_root == root);
}