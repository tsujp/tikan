import { expect } from 'bun:test'
import { describe, getMatchWithBackend, test, withCircuitError } from '#test/harness'

expect.extend({ withCircuitError })

{
    // TODO: Bug in `Bun` or...? Appears to invoke symbol cleanup _before_ scope
    //       exit. Does this feature consider nested scope as a scope exit? Surely
    //       not since closures exist and the resource literally exists at
    //       runtime still... hmmm.
    await using M = getMatchWithBackend()

    describe('legal start boards', () => {
        // There is only one legal start board.
        describe('single legal start', () => {
            // This test is a bit weird because we kind of implement the body of
            //   `match.startGame` to test it but only because said body is simple
            //   in reality this should be in `xx_start.nr` itself but Nargo is
            //   bugged currently so here we are.
            test('startGame provides expected board', async () => {
                // By _not_ marking it `export` and then importing it from `match`
                //   we don't blindly follow ourselves.
                const VALID_START_BOARD = 'BBDBVBXBAA'

                const msg_expected = await M.match.startGame({
                    board: VALID_START_BOARD,
                    for_aggregation: false,
                })
                const msg_real = await M.match.startGame({ for_aggregation: false })

                const msg_expected_valid = await M.start_nr.verifyProof(msg_expected.proof)
                const msg_real_valid = await M.start_nr.verifyProof(msg_real.proof)

                expect(msg_expected_valid).toBe(true)
                expect(msg_real_valid).toBe(true)
            })
        })
    })

    describe('illegal start boards', () => {
        // await using M = getMatch()

        test('startGame fails to create proof', async () => {
            expect(M.match.startGame({ board: 'BBDBVBXBAB' })).rejects.withCircuitError() // Start halfturn not 0.
            expect(M.match.startGame({ board: 'BBDBVBXBBA' })).rejects.withCircuitError() // White not starting.

            // Invalid player (neither white/black) starting.
            expect(M.match.startGame({ board: 'BBDBVBXBCA' })).rejects.withCircuitError(
                "Assertion failed: Expected 'turn' to be 0 or 1",
            )

            expect(M.match.startGame({ board: 'BADBVBXBAA' })).rejects.withCircuitError() // Start piece (white) with lights off.
            expect(M.match.startGame({ board: 'ABDBVBXBAB' })).rejects.withCircuitError() // Start piece (white) wrong square.
            expect(M.match.startGame({ board: 'BBDBVAXBAB' })).rejects.withCircuitError() // Start piece (black) with lights off.
            expect(M.match.startGame({ board: 'BBDBWBXBAB' })).rejects.withCircuitError() // Start piece (black) wrong square.
        })
    })
}
