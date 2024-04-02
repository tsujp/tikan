use dep::lib::{Board, SerialisedStateIn};

#[recursive]
fn main(start_serial: SerialisedStateIn) {
    let sb = Board::deserialise(start_serial);

    // p1
    assert(sb.players[0][0].idx == 1);
    assert(sb.players[0][0].lights == true);
    assert(sb.players[0][0].captured == false);

    // p2
    assert(sb.players[0][1].idx == 3);
    assert(sb.players[0][1].lights == true);
    assert(sb.players[0][1].captured == false);

    // p3
    assert(sb.players[1][0].idx == 21);
    assert(sb.players[1][0].lights == true);
    assert(sb.players[1][0].captured == false);

    // p4
    assert(sb.players[1][1].idx == 23);
    assert(sb.players[1][1].lights == true);
    assert(sb.players[1][1].captured == false);

    assert(sb.turn == 0);
    assert(sb.halfmove == 0);
}
