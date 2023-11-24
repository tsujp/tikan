use dep::std::println;

use dep::util::bit_logic as bl;


global TWO: Field = 2;


// XXX: Test helper only.
fn test_diagonal_masks <T, N>(mask_defs: [[Field; 2]; N]) {
    for i in 0 .. mask_defs.len() {
        let about_idx = mask_defs[i][0];
        let expected = mask_defs[i][1];
        let result = bl::diagonal_mask_64(about_idx as u64) as Field;

        assert(expected == result);

        // DBG: Uncomment 2 lines, view in bb_viewer.
        // println(f"k-0xFF k-{about_idx} k-{result}");
        // println(f"k-0x0");
    }
}

// TODO: Make it higher order later on, slightly DRYer (within reason).
// XXX: Test helper only.
fn test_anti_diagonal_masks <T, N>(mask_defs: [[Field; 2]; N]) {
    for i in 0 .. mask_defs.len() {
        let about_idx = mask_defs[i][0];
        let expected = mask_defs[i][1];
        let result = bl::anti_diagonal_mask_64(about_idx as u64) as Field;

        assert(expected == result);

        // DBG: Uncomment 2 lines, view in bb_viewer.
        println(f"k-0xFF k-{about_idx} k-{result}");
        println(f"k-0x0");
    }
}


// ---------------------------------------------------------------------------
// ---------------------------------------------- DIAGONALS


// Test diagonals which are 8 squares long (main diagonal).
#[test]
fn diagonal_mask__main_8 () {
    // Diagonal from a1 to h8 (1, 9, 18, 27, 36, 45, 54, 63).
    let indices_a1_h8 = [
        [1, 0x8040201008040200],
        [TWO.pow_32(9), 0x8040201008040001],
        [TWO.pow_32(18), 0x8040201008000201],
        [TWO.pow_32(27), 0x8040201000040201],
        [TWO.pow_32(36), 0x8040200008040201],
        [TWO.pow_32(45), 0x8040001008040201],
        [TWO.pow_32(54), 0x8000201008040201],
        [TWO.pow_32(63), 0x40201008040201]
    ];

    test_diagonal_masks(indices_a1_h8);
}


// Test diagonals which are 7 squares long.
#[test]
fn diagonal_mask__main_7 () {
    // Diagonal from a2 to g8 (8, 17, 26, 35, 44, 53, 62).
    let indices_a2_g8 = [
        [TWO.pow_32(8), 0x4020100804020000],
        [TWO.pow_32(17), 0x4020100804000100],
        [TWO.pow_32(26), 0x4020100800020100],
        [TWO.pow_32(35), 0x4020100004020100],
        [TWO.pow_32(44), 0x4020000804020100],
        [TWO.pow_32(53), 0x4000100804020100],
        [TWO.pow_32(62), 0x20100804020100]
    ];

    test_diagonal_masks(indices_a2_g8);

    // Diagonal from b1 to h7 (1, 10, 19, 28, 37, 46, 55).
    let indices_b1_h7 = [
        [TWO.pow_32(1), 0x80402010080400],
        [TWO.pow_32(10), 0x80402010080002],
        [TWO.pow_32(19), 0x80402010000402],
        [TWO.pow_32(28), 0x80402000080402],
        [TWO.pow_32(37), 0x80400010080402],
        [TWO.pow_32(46), 0x80002010080402],
        [TWO.pow_32(55), 0x402010080402]
    ];

    test_diagonal_masks(indices_b1_h7);
}


// Test diagonals which are 6 squares long.
#[test]
fn diagonal_mask__main_6 () {
    // Diagonal from a3 to f8 (16, 25, 34, 43, 52, 61).
    let indices_a3_f8 = [
        [TWO.pow_32(16), 0x2010080402000000],
        [TWO.pow_32(25), 0x2010080400010000],
        [TWO.pow_32(34), 0x2010080002010000],
        [TWO.pow_32(43), 0x2010000402010000],
        [TWO.pow_32(52), 0x2000080402010000],
        [TWO.pow_32(61), 0x10080402010000]
    ];

    test_diagonal_masks(indices_a3_f8);

    // Diagonal from c1 to h6 (2, 11, 20, 29, 38, 47).
    let indices_c1_h6 = [
        [TWO.pow_32(2), 0x804020100800],
        [TWO.pow_32(11), 0x804020100004],
        [TWO.pow_32(20), 0x804020000804],
        [TWO.pow_32(29), 0x804000100804],
        [TWO.pow_32(38), 0x800020100804],
        [TWO.pow_32(47), 0x4020100804]
    ];

    test_diagonal_masks(indices_c1_h6);
}


// Test diagonals which are 5 squares long.
#[test]
fn diagonal_mask__main_5 () {
    // Diagonal from a4 to e8 (24, 33, 42, 51, 60).
    let indices_a4_e8 = [
        [TWO.pow_32(24), 0x1008040200000000],
        [TWO.pow_32(33), 0x1008040001000000],
        [TWO.pow_32(42), 0x1008000201000000],
        [TWO.pow_32(51), 0x1000040201000000],
        [TWO.pow_32(60), 0x08040201000000]
    ];

    test_diagonal_masks(indices_a4_e8);

    // Diagonal from d1 to h5 (3, 12, 21, 30, 39).
    let indices_d1_h5 = [
        [TWO.pow_32(3), 0x8040201000],
        [TWO.pow_32(12), 0x8040200008],
        [TWO.pow_32(21), 0x8040001008],
        [TWO.pow_32(30), 0x8000201008],
        [TWO.pow_32(39), 0x40201008]
    ];

    test_diagonal_masks(indices_d1_h5);
}


// Test diagonals which are 4 squares long.
#[test]
fn diagonal_mask__main_4 () {
    // Diagonal from a5 to d8 (32, 41, 50, 59).
    let indices_a5_d8 = [
        [TWO.pow_32(32), 0x0804020000000000],
        [TWO.pow_32(41), 0x0804000100000000],
        [TWO.pow_32(50), 0x0800020100000000],
        [TWO.pow_32(59), 0x04020100000000]
    ];

    test_diagonal_masks(indices_a5_d8);

    // Diagonal from d1 to h5 (4, 13, 22, 31).
    let indices_e1_h4 = [
        [TWO.pow_32(4), 0x80402000],
        [TWO.pow_32(13), 0x80400010],
        [TWO.pow_32(22), 0x80002010],
        [TWO.pow_32(31), 0x402010]
    ];

    test_diagonal_masks(indices_e1_h4);
}


// Test diagonals which are 3 squares long.
#[test]
fn diagonal_mask__main_3 () {
    // Diagonal from a6 to c8 (40, 49, 58).
    let indices_a6_c8 = [
        [TWO.pow_32(40), 0x0402000000000000],
        [TWO.pow_32(49), 0x0400010000000000],
        [TWO.pow_32(58), 0x02010000000000]
    ];

    test_diagonal_masks(indices_a6_c8);

    // Diagonal from f1 to h3 (5, 14, 23).
    let indices_f1_h3 = [
        [TWO.pow_32(5), 0x804000],
        [TWO.pow_32(14), 0x800020],
        [TWO.pow_32(23), 0x4020]
    ];

    test_diagonal_masks(indices_f1_h3);
}


// Test diagonals which are 2 squares long.
#[test]
fn diagonal_mask__main_2 () {
    // Diagonal from a7 to b8 (48, 57).
    let indices_a7_b8 = [
        [TWO.pow_32(48), 0x0200000000000000],
        [TWO.pow_32(57), 0x01000000000000]
    ];

    test_diagonal_masks(indices_a7_b8);

    // Diagonal from g1 to h2 (6, 15).
    let indices_g1_h2 = [
        [TWO.pow_32(6), 0x8000],
        [TWO.pow_32(15), 0x40]
    ];

    test_diagonal_masks(indices_g1_h2);
}


// Test diagonals which are 1 square long.
#[test]
fn diagonal_mask__main_1 () {
    // Diagonal a8 (56).
    let indices_a8 = [
        [TWO.pow_32(56), 0x00]
    ];

    test_diagonal_masks(indices_a8);

    // Diagonal h1 (7).
    let indices_h1 = [
        [TWO.pow_32(7), 0x00]
    ];

    test_diagonal_masks(indices_h1);
}


// ---------------------------------------------------------------------------
// ---------------------------------------------- ANTI-DIAGONALS


// Test anti-diagonals which are 8 squares long (main anti-diagonal).
#[test]
fn diagonal_mask__anti_8 () {
    // Anti-diagonal from a1 to h8 (7, 14, 21, 28, 35, 42, 49, 56).
    let indices_a8_h1 = [
        [TWO.pow_32(7), 0x0102040810204000],
        [TWO.pow_32(14), 0x0102040810200080],
        [TWO.pow_32(21), 0x0102040810004080],
        [TWO.pow_32(28), 0x0102040800204080],
        [TWO.pow_32(35), 0x0102040010204080],
        [TWO.pow_32(42), 0x0102000810204080],
        [TWO.pow_32(49), 0x0100040810204080],
        [TWO.pow_32(56), 0x02040810204080]
    ];

    test_anti_diagonal_masks(indices_a8_h1);
}


// Test anti-diagonals which are 7 squares long.
#[test]
fn diagonal_mask__anti_7 () {
    // Anti-diagonal from h2 to b8 (15, 22, 29, 36, 43, 50, 57).
    let indices_h2_b8 = [
        [TWO.pow_32(15), 0x0204081020400000],
        [TWO.pow_32(22), 0x0204081020008000],
        [TWO.pow_32(29), 0x0204081000408000],
        [TWO.pow_32(36), 0x0204080020408000],
        [TWO.pow_32(43), 0x0204001020408000],
        [TWO.pow_32(50), 0x0200081020408000],
        [TWO.pow_32(57), 0x04081020408000]
    ];

    test_anti_diagonal_masks(indices_h2_b8);

    // Anti-diagonal from g1 to a7 (6, 13, 20, 27, 34, 41, 48).
    let indices_g1_a7 = [
        [TWO.pow_32(6), 0x01020408102000],
        [TWO.pow_32(13), 0x01020408100040],
        [TWO.pow_32(20), 0x01020408002040],
        [TWO.pow_32(27), 0x01020400102040],
        [TWO.pow_32(34), 0x01020008102040],
        [TWO.pow_32(41), 0x01000408102040],
        [TWO.pow_32(48), 0x020408102040]
    ];

    test_anti_diagonal_masks(indices_g1_a7);
}


// Test anti-diagonals which are 6 squares long.
#[test]
fn diagonal_mask__anti_6 () {
    // Anti-diagonal from h3 to c8 (23, 30, 37, 44, 51, 58).
    let indices_h3_c8 = [
        [TWO.pow_32(23), 0x0408102040000000],
        [TWO.pow_32(30), 0x0408102000800000],
        [TWO.pow_32(37), 0x0408100040800000],
        [TWO.pow_32(44), 0x0408002040800000],
        [TWO.pow_32(51), 0x0400102040800000],
        [TWO.pow_32(58), 0x08102040800000]
    ];

    test_anti_diagonal_masks(indices_h3_c8);

    // Anti-diagonal from f1 to a6 (5, 12, 19, 26, 33, 40).
    let indices_f1_a6 = [
        [TWO.pow_32(5), 0x010204081000],
        [TWO.pow_32(12), 0x010204080020],
        [TWO.pow_32(19), 0x010204001020],
        [TWO.pow_32(26), 0x010200081020],
        [TWO.pow_32(33), 0x010004081020],
        [TWO.pow_32(40), 0x0204081020]
    ];

    test_anti_diagonal_masks(indices_f1_a6);
}


// Test anti-diagonals which are 5 squares long.
#[test]
fn diagonal_mask__anti_5 () {
    // Anti-diagonal from h4 to d8 (31, 38, 45, 52, 59).
    let indices_h4_d8 = [
        [TWO.pow_32(31), 0x0810204000000000],
        [TWO.pow_32(38), 0x0810200080000000],
        [TWO.pow_32(45), 0x0810004080000000],
        [TWO.pow_32(52), 0x0800204080000000],
        [TWO.pow_32(59), 0x10204080000000]
    ];

    test_anti_diagonal_masks(indices_h4_d8);

    // Anti-diagonal from e1 to a5 (4, 11, 18, 25, 32).
    let indices_e1_a5 = [
        [TWO.pow_32(4), 0x0102040800],
        [TWO.pow_32(11), 0x0102040010],
        [TWO.pow_32(18), 0x0102000810],
        [TWO.pow_32(25), 0x0100040810],
        [TWO.pow_32(32), 0x02040810]
    ];

    test_anti_diagonal_masks(indices_e1_a5);
}


// Test anti-diagonals which are 4 squares long.
#[test]
fn diagonal_mask__anti_4 () {
    // Anti-diagonal from h5 to e8 (39, 46, 53, 60).
    let indices_h5_e8 = [
        [TWO.pow_32(39), 0x1020400000000000],
        [TWO.pow_32(46), 0x1020008000000000],
        [TWO.pow_32(53), 0x1000408000000000],
        [TWO.pow_32(60), 0x20408000000000]
    ];

    test_anti_diagonal_masks(indices_h5_e8);

    // Anti-diagonal from d1 to a4 (3, 10, 17, 24).
    let indices_d1_a4 = [
        [TWO.pow_32(3), 0x01020400],
        [TWO.pow_32(10), 0x01020008],
        [TWO.pow_32(17), 0x01000408],
        [TWO.pow_32(24), 0x020408]
    ];

    test_anti_diagonal_masks(indices_d1_a4);
}


// Test anti-diagonals which are 3 squares long.
#[test]
fn diagonal_mask__anti_3 () {
    // Anti-diagonal from h6 to f8 (47, 54, 61).
    let indices_h6_f8 = [
        [TWO.pow_32(47), 0x2040000000000000],
        [TWO.pow_32(54), 0x2000800000000000],
        [TWO.pow_32(61), 0x40800000000000]
    ];

    test_anti_diagonal_masks(indices_h6_f8);

    // Anti-diagonal from c1 to a3 (2, 9, 16).
    let indices_c1_a3 = [
        [TWO.pow_32(2), 0x010200],
        [TWO.pow_32(9), 0x010004],
        [TWO.pow_32(16), 0x0204]
    ];

    test_anti_diagonal_masks(indices_c1_a3);
}


// Test anti-diagonals which are 2 squares long.
#[test]
fn diagonal_mask__anti_2 () {
    // Anti-diagonal from h7 to g8 (55, 62).
    let indices_h7_g8 = [
        [TWO.pow_32(55), 0x4000000000000000],
        [TWO.pow_32(62), 0x80000000000000]
    ];

    test_anti_diagonal_masks(indices_h7_g8);

    // Anti-diagonal from b1 to a2 (1, 8).
    let indices_b1_a2 = [
        [TWO.pow_32(1), 0x0100],
        [TWO.pow_32(8), 0x02]
    ];

    test_anti_diagonal_masks(indices_b1_a2);
}


// Test anti-diagonals which are 1 square long.
#[test]
fn diagonal_mask__anti_1 () {
    // Anti-diagonal h8 (63).
    let indices_h8 = [
        [TWO.pow_32(63), 0x00]
    ];

    test_anti_diagonal_masks(indices_h8);

    // Anti-diagonal a1 (0).
    let indices_a1 = [
        [TWO.pow_32(0), 0x00],
    ];

    test_anti_diagonal_masks(indices_a1);
}
