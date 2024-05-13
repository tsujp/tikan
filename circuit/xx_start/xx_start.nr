use dep::lib::{Board, SerialisedStateIn};

#[recursive]
fn main(start_serial: SerialisedStateIn) {
    let sb = Board::deserialise(start_serial);

    // Piece 1
    assert(sb.players[0][0].idx == 1);
    assert(sb.players[0][0].lights == true);
    assert(sb.players[0][0].captured == false);

    // Piece 2
    assert(sb.players[0][1].idx == 3);
    assert(sb.players[0][1].lights == true);
    assert(sb.players[0][1].captured == false);

    // Piece 3
    assert(sb.players[1][0].idx == 21);
    assert(sb.players[1][0].lights == true);
    assert(sb.players[1][0].captured == false);

    // Piece 4
    assert(sb.players[1][1].idx == 23);
    assert(sb.players[1][1].lights == true);
    assert(sb.players[1][1].captured == false);

    assert(sb.turn == 0);
    assert(sb.halfmove == 0);
}

// XXX: As at `0.26.0+a0f7474ae6bd74132efdb945d2eb2383f3913cce` cannot test a
//      function which is attributed with `#[recursive]`. Attempting to do so
//      panicks. So, the tests are in JS-land instead.
//
// #[test]
// fn legal_start_board() {
//     main("BBDBVBXBAA");
// }
