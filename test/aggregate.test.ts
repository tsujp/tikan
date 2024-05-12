import { Match, describe, test } from '#test/harness'
import { expect } from 'bun:test'

function getMatch() {
    const match = Match.new({
        white: globalThis.TIKAN_WHITE,
        black: globalThis.TIKAN_BLACK,
        start: globalThis.TIKAN_START,
    })

    return {
        match,
        // Wicked overkill considering `Game` is not async but it might be in
        //   future plus this pattern is kind of nice anyway instead of `beforeAll()`
        //   and hoisting scope with `let`.
        [Symbol.dispose]: () => {
            // TODO: When the dispose happens (and verify its actually happening AFTER cos it doesnt look like it...?)
            //       log the game somewhere appropriate?
            // console.log('disposing of game...')
        },
    }
}

describe('legal aggregation', () => {
    using g = getMatch()
    const match = g.match

    // No hidden state.
    describe('basic moves', () => {
        test('white, black, white, verify', async () => {
            const { proof: start_proof, artifacts: start_artifacts } = await match.startGame()

            const white_t1 = await match.white.playTurn(
                start_proof,
                'BBDBVBXBAA', // TODO: Current board state should be abstracted away into Player class.
                'BBDBBI',
                start_artifacts,
            )

            const black_t1 = await match.black.playTurn(white_t1.prf, 'BBDBVBXBBB', 'VBXBAQ')

            const white_t2 = await match.white.playTurn(black_t1.prf, 'BBDBVBXBAC', 'BBDBBI')

            const white_accepts = await match.white.verifyProof(white_t2.prf)
            const black_accepts = await match.black.verifyProof(white_t2.prf)

            expect(white_accepts).toBe(true)
            expect(black_accepts).toBe(true)
        }, 120000)
    })
})

describe('illegal aggregation', () => {
    using g = getMatch()
    const match = g.match

    describe('basic moves', () => {
        test('white lies, no verify', async () => {
            const { proof: start_proof, artifacts: start_artifacts } = await match.startGame()

            expect(true).toBe(true)
        })
    })
})
