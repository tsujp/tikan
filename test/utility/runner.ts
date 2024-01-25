// Calling process.exit() with any status code will prevent `bun --watch test`
//   from re-executing, so for the development task use a thin wrapper.

const wd = process.cwd()

// * * * * * * * * * * * * * * * * * * * * * * * PRE-CHECK EXECUTION
// * * * * * * * * * * * * *

const precheck_proc = Bun.spawn(['bun', 'test'], {
    cwd: wd,
    stderr: 'inherit',
    stdout: 'inherit',
})

const precheck_success = await precheck_proc.exited.then((code) => code)
console.log('exit code!', precheck_success)

// ------ build

console.log('adsadsaads', Bun.argv)

// * * * * * * * * * * * * * * * * * * * * * * * TEST SUITE EXECUTION
// * * * * * * * * * * * * *

// If precheck process exits with success then the test suite can be started.
