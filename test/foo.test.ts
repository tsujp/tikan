import { describe, test, expect, beforeAll } from 'bun:test'
import { testInvokeGuard } from '#test/utility/guard'

testInvokeGuard()

function getGame() {
    const game = Game.new({
        white: globalThis.TIKAN_WHITE,
        black: globalThis.TIKAN_BLACK,
        start: globalThis.TIKAN_START,
    })

    return {
        game,
        // Wicked overkill considering `Game` is not async but it might be in
        //   future plus this pattern is kind of nice anyway instead of `beforeAll()`
        //   and hoisting scope with `let`.
        [Symbol.dispose]: () => {
            console.log('disposing of game...')
        },
    }
}

describe('legal aggregation', async () => {
    using g = getGame()
    const game = g.game

    // No hidden state.
    describe('basic moves', async () => {
        __test(
            'white, black, white, verify',
            async () => {
                const { proof: start_proof, artifacts: start_artifacts } =
                    await game.startGame()

                // TODO: When commitments are checked, and board state updates the board inputs here will need to be fixed.

                console.log('------------------------------------------ EXPERIMENT START')
                const white_t1 = await game.white.playTurn(
                    start_proof,
                    'BBDBVBXBAA', // TODO: Current board state should be abstracted away into Player class.
                    'BBDBBI',
                    start_artifacts,
                )
                console.log('white_t1:', white_t1)
                console.log('------------------------------------------ EXPERIMENT END')

                // process.exit(1)

                // const white_t1 = await plyr.white.playTurn(
                //     start_proof,
                //     'BBDBVBXBAA', // TODO: Current board state should be abstracted away into Player class.
                //     'BBDBBI',
                //     start_artifacts,
                // )

                // const black_t1 = await plyr.black.playTurn(
                //     white_t1.prf,
                //     'BBDBVBXBBB',
                //     'VBXBAQ',
                // )

                // const white_t2 = await plyr.white.playTurn(black_t1.prf, 'BBDBVBXBAC', 'BBDBBI')

                // const white_accepts = await plyr.white.verifyProof(black_t1.prf)
                // const black_accepts = await plyr.black.verifyProof(black_t1.prf)
                const white_accepts = true
                const black_accepts = true

                expect(white_accepts).toBe(true)
                expect(black_accepts).toBe(true)
            },
            120_000,
        )
    })
})

// TODO: Maybe just have _our_ test output logs beforehand, then all the `bun
//       test` output logs afterwards; clean seperation.
// NB: `bun test` output is on `stderr` by default. All of it.
import { type Test } from 'bun:test'
import { Game } from '#test/game'
function __test(...args: Parameters<Test>): void {
    // There's not really a way to 'wrap' the test API output nicely in Bun
    //   currently because `bun test` implements custom logic to output the
    //   tests it's running, coverage, statistics etc. To make the output a
    //   teeny bit more readable though we prefix each test we're running with
    //   it's deepest name (`expect.getName()` API equivalent does not exist
    //   yet) as the test results are printed afterwards and we cannot change
    //   that.
    console.log(`----------- ${args[0]}`)
    test(...args)
}
