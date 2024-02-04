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

logHeading('Executing tests')

// Hardcoded `bin` tests only for now.
import { join } from 'path'
const wd = join(root_dir, 'test')
// ---/

// TODO: Add a listener up here such that if the circuit files change then
//       we re-run checkTestEnvironment. THen add a flag so we can control that.

// TODO: This works and re-runs tests!
const precheck_proc = Bun.spawn(['bun', '--watch', 'test', 'e2e.test.ts'], {
    cwd: wd,
    stdout: 'inherit'
})

// precheck_proc.stdin.write('HELLO THERE!')
// precheck_proc.stdin.flush()

const precheck_success = await precheck_proc.exited.then((code) => code)
console.log('[RUNNER] exit code:', precheck_success)

// ------ build

// console.log('adsadsaads', Bun.argv)

// * * * * * * * * * * * * * * * * * * * * * * * TEST SUITE EXECUTION
// * * * * * * * * * * * * *

// If precheck process exits with success then the test suite can be started.
