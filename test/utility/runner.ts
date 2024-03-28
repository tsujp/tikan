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

const test_file = 'xx.e2e.test.ts'
const CIRCUITS_MSG = { kind: 'CIRCUITS', msg: circuits }

let test_proc = spawnTest(wd, test_file, CIRCUITS_MSG)

const ac = new AbortController();
const { signal } = ac;
const CLOSE_WATCHER_MSG = 'close watcher'

const watcher = watch(join(root_dir, 'test'), { recursive: true, signal })
    ; (async () => {
        try {
            for await (const event of watcher) {
                // console.log(`Detected ${event.eventType} in ${event.filename}`);

                if (event.filename?.endsWith('.test.ts')) {
                    // console.log('found test file', event.filename)
                    test_proc.kill()
                    await test_proc.exited

                    refresh_run++
                    test_proc = spawnTest(wd, test_file, CIRCUITS_MSG)
                    logHeading(`[${process.pid}->${test_proc.pid}] watch run: ${refresh_run}`)
                }
            }
        } catch (e) {
            if (e === CLOSE_WATCHER_MSG) {
                console.log('File watcher closed')
            } else {
                console.log(e)
            }
        }
    })()

// Trap cleanup.
process.on('SIGINT', async () => {
    console.log('Cleaning up...')

    // File watcher.
    ac.abort(CLOSE_WATCHER_MSG)

    // Child processes.
    test_proc.kill()
    await test_proc.exited
    console.log('Child processes killed')

    console.log('Done')
    process.exit(0)
})

// * * * * * * * * * * * * * * * * * * * * * * * TEST SUITE EXECUTION
// * * * * * * * * * * * * *
