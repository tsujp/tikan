import { describe as __describe, test as __test } from 'bun:test'
import type { Describe, Test } from 'bun:test'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { Match } from '#test/harness'

// Satanic, yes.
globalThis.__TEST_PATH = []
const TEST_PATH = globalThis.__TEST_PATH

declare module 'bun:test' {
    // TODO: Is there a way to have this require `rejects` in-front or otherwise
    //       compile-time type errors (we know it _should_ receive a rejected
    //       promise but as of now don't have compile-time types for that?)
    interface Matchers {
        withCircuitError(expected_message?: string): void
    }
}

function matcherInspect(obj: unknown) {
    // TODO: Respect `NO_COLOR`.
    return Bun.inspect(obj, { colors: true, depth: 0 })
}

// Cannot do a similar technique with `describe`, output does not sequence.
export function describe(...args: Parameters<Describe>) {
    TEST_PATH.push(args[0])
    __describe(args[0], args[1])
    TEST_PATH.pop()
}

export function test(...args: Parameters<Test>) {
    const test_path = structuredClone([...TEST_PATH, args[0]]).join(' > ')

    __test(
        args[0],
        async () => {
            Bun.stderr.writer().write(`::test::${test_path}\n`)
            await args[1]()
            Bun.stderr.writer().write(`::endtest::${test_path}\n`)
        },
        args[2] ?? 5000,
    )
}

const CIRCUIT_EXECUTION_FAIL_BASE = 'Circuit execution failed: Error: '

// Custom `expect.extend(matcher)`
export function withCircuitError(
    circuit_error: unknown,
    expected_message = 'Cannot satisfy constraint',
) {
    if (circuit_error instanceof Error === false) {
        return {
            pass: false,
            message: `expected: Error\nreceived: ${matcherInspect(circuit_error)}\n`,
        }
    }

    const full_message = `${CIRCUIT_EXECUTION_FAIL_BASE}${expected_message}`

    if (circuit_error.message === full_message) {
        return {
            pass: true,
            message: () =>
                `expected (not): ${full_message}\nreceived: ${circuit_error.message}\n`,
        }
    }

    return {
        pass: false,
        message: () => `expected: ${full_message}\nreceived: ${circuit_error.message}\n`,
    }
}

export function getMatchWithBackend() {
    const match = Match.new({
        white: globalThis.TIKAN_WHITE,
        black: globalThis.TIKAN_BLACK,
        start: globalThis.TIKAN_START,
    })

    const start_cr = structuredClone(globalThis.TIKAN_START)

    const start_be = new BarretenbergBackend(start_cr, { threads: 8 })
    const start_nr = new Noir(start_cr, start_be)

    return {
        match,
        start_nr,
        [Symbol.asyncDispose]: async () => {
            // TODO: Why does `.destroy()` take indefinite time?
            // await start_nr.destroy()
            // await start_be.destroy()
        },
    }
}

export function getMatch() {
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
