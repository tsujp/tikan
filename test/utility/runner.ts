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

// process.on("beforeExit", (code) => {
//     console.log(`*&^!@#*&@#^* PROCESS EXIT ${code}`);
//     process.exit(1)
// });

logHeading('Executing tests')

// Hardcoded `bin` tests only for now.
import { join } from 'path'
const wd = join(root_dir, 'test')
// ---/

// TODO: Add a listener up here such that if the circuit files change then
//       we re-run checkTestEnvironment. THen add a flag so we can control that.

// TODO: If this file changes and triggers a refresh from the start the previously spawned Bun.spawn
//       ends up hanging and we get double test run. Track and end that other one?


// TODO: This works and re-runs tests!
// const precheck_proc = Bun.spawn(['bun', '--watch', 'test', 'e2e.test.ts'], {
//     cwd: wd,
//     // stdin: 'inherit',
//     stdout: 'inherit',
//     ipc(message, childProc) {
//         console.log('RUNNER MSG FROM CHILD:', message, childProc)
//     }
// })

// precheck_proc.send('hi there')

// precheck_proc.stdin.write('HELLO THERE!')
// precheck_proc.stdin.flush()

// const precheck_success = await precheck_proc.exited.then((code) => code)
// console.log('[RUNNER] exit code:', precheck_success)

// import { watch } from "fs";
// const watcher = watch(import.meta.dir, (event, filename) => {
//     console.log(`Detected ${event} in ${filename}`);
//   });

const bufmsg = serialize({ kind: 'CIRCUITS', msg: circuits })
let test_proc = Bun.spawn(['bun', 'test', 'e2e.test.ts'], {
    cwd: wd,
    stdin: 'pipe',
    stdout: 'inherit',
    // ipc(message, childProc) {
    //     console.log('RUNNER MSG FROM CHILD!!:', message, childProc)
    // }
})
// test_proc.send('hi there')

import { serialize, deserialize } from "bun:jsc";
// const bufmsg = serialize({ kind: 'CIRCUITS', msg: circuits })

test_proc.stdin.write(bufmsg)
test_proc.stdin.flush()
// test_proc.send({ kind: 'CIRCUITS', msg: circuits })
// test_proc.ref()

const ac = new AbortController();
const { signal } = ac;

import { watch } from "fs/promises";
// const watcher = watch(import.meta.dir, { signal });
const watcher = watch(join(root_dir, 'test'), { recursive: true, signal });
(async () => {
    for await (const event of watcher) {
        console.log(`Detected ${event.eventType} in ${event.filename}`);

        if (event.filename?.endsWith('.test.ts')) {
            console.log('found test file', event.filename)

            test_proc.kill()
            await test_proc.exited
            console.log('previous test process exited, restarting tests')
            test_proc = Bun.spawn(['bun', 'test', 'e2e.test.ts'], {
                cwd: wd,
                stdin: 'pipe',
                stdout: 'inherit',
                // ipc(message, childProc) {
                //     console.log('RUNNER MSG FROM CHILD:', message, childProc)
                // }
            })
            // test_proc.ref()

            // test_proc.send({ kind: 'CIRCUITS', msg: circuits })
        }
    }
})()

console.log('not hit')

//   import { watch } from "fs/promises";
// (async () => {
//     try {
//       const watcher = watch(__filename, { signal });
//       for await (const event of watcher)
//         console.log('watch event:', event);
//     } catch (err) {
//       if (err.name === 'AbortError')
//         return;
//       throw err;
//     }
//   })();

process.on("SIGINT", () => {
    // close watcher when Ctrl-C is pressed
    console.log("Closing watcher...");
    // watcher.close();

    // Does this clean up correctly?
    ac.abort()
    console.log('watcher obj is', watcher)

    console.log('closing runner....')

    process.exit(0);
});

// ------ build

// console.log('adsadsaads', Bun.argv)

// * * * * * * * * * * * * * * * * * * * * * * * TEST SUITE EXECUTION
// * * * * * * * * * * * * *

// If precheck process exits with success then the test suite can be started.
