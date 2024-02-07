// Calling process.exit() with any status code will prevent `bun --watch test`
//   from re-executing, so for the development task use a thin wrapper.

import { checkTestEnvironment } from './precheck'
import { getNoirCircuits, resolveProjectRootDir, logHeading } from './misc'

// * * * * * * * * * * * * * * * * * * * * * * * PRE-CHECK EXECUTION
// * * * * * * * * * * * * *

const root_dir = await resolveProjectRootDir()
const circuits = await getNoirCircuits(root_dir)

const { checks, args } = await checkTestEnvironment(root_dir, circuits)
if (checks === false) process.exit(1)

let refresh_run = 0
logHeading('Executing tests')

// Hardcoded `bin` tests only for now.
import { join } from 'path'
const wd = join(root_dir, 'test')
// ---/

// TODO: Add a listener up here such that if the circuit files change then
//       we re-run checkTestEnvironment. THen add a flag so we can control that.

// TODO: If this file changes and triggers a refresh from the start the previously spawned Bun.spawn
//       ends up hanging and we get double test run. Track and end that other one?

// INVES: You know, I'm not actually sure when these are imported. I have a feeling
//        they are hoisted but if not then I'd say it makes sense to only import
//        them here to prevent loading stuff we're never going to use if the environment
//        check fails (as we then exit with failure).
import { watch } from 'fs/promises'
import { spawnTest } from './spawn_test'
import { serialize } from 'bun:jsc'
const bufmsg = serialize({ kind: 'CIRCUITS', msg: circuits })
// let test_proc = Bun.spawn(['bun', 'test', 'fooe2e.test.ts'], {
//     cwd: wd,
//     stdin: 'pipe',
//     stdout: 'inherit',
//     // Wanted to use IPC but it doesn't work with this pattern of sending
//     //   messages after the first re-run for some reason.
// })
const test_file = 'xx.e2e.test.ts'
let test_proc = spawnTest(wd, test_file)
test_proc.stdin.write(bufmsg)
test_proc.stdin.flush()

const ac = new AbortController();
const { signal } = ac;

const watcher = watch(join(root_dir, 'test'), { recursive: true, signal });
(async () => {
    for await (const event of watcher) {
        // console.log(`Detected ${event.eventType} in ${event.filename}`);

        if (event.filename?.endsWith('.test.ts')) {
            // console.log('found test file', event.filename)
            test_proc.kill()
            await test_proc.exited

            // console.log('previous test process exited, restarting tests')
            refresh_run++
            logHeading(`Refresh run: ${refresh_run}`)
            test_proc = spawnTest(wd, test_file)
            test_proc.stdin.write(bufmsg)
            test_proc.stdin.flush()
        }
    }
})()

// Trap cleanup.
process.on('SIGINT', () => {
    // Does this clean up the watcher correctly?
    process.stdout.write('Closing watcher... ')
    ac.abort()
    console.log('done')

    console.log('Closing runner')

    process.exit(0)
})

// * * * * * * * * * * * * * * * * * * * * * * * TEST SUITE EXECUTION
// * * * * * * * * * * * * *
