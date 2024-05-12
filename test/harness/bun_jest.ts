import { describe as __describe, test as __test } from 'bun:test'
import type { Describe, Test } from 'bun:test'

// Satanic, yes.
// declare global {
//     var __TEST_PATH: Array<string>
// }

globalThis.__TEST_PATH = []

const TEST_PATH = globalThis.__TEST_PATH

// Cannot do a similar technique with `describe`, output does not sequence.
function describe(...args: Parameters<Describe>) {
    TEST_PATH.push(args[0])
    __describe(args[0], args[1])
    TEST_PATH.pop()
}

function test(...args: Parameters<Test>) {
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

export { describe, test }
