import chalk from 'chalk'
import { type CircuitDefinition } from '../types'

const roseChar = '-'
const successNoStdout = `${chalk.gray('<')}${chalk.green('success')}${chalk.gray('>')}`

class NonZeroReturnError extends Error {
    constructor (message: string, cause: string) {
        super(message)
        this.name = 'NonZeroReturnError'
        this.cause = cause
    }
}

// Single line string only; if left and right padding is odd will preference
//   left side (i.e. right side will receive the extra str pad).
export function padCentre (str: string, padStr: string, max = 80) {
    if (str.length > max) {
        return str
    }

    const spaceStr = ` ${str} `

    return spaceStr.padStart(Math.floor(spaceStr.length / 2) + Math.floor(max / 2), padStr)
        .padEnd(max, padStr)
}

// Prints pre-formatted test environment item for sanity preamble.
function logItem (item: string, str: string) {
    return console.log(`${chalk.cyan(item)}${chalk.gray(':')} ${chalk.reset(str)}`)
}

function logItemError (item: string, str: string) {
    // Not console.error because this test harness is mostly to facilitate sanely
    //   orchestrating Nargo for integration and end-to-end tests and not for
    //   perfect logging etc. Outputting to console.error (stderr) will require
    //   explicit buffer synchronisation which is way too much for _orchestrating
    //   nargo_.
    return console.log(
        `${chalk.red('[ERROR]')} ${chalk.cyan(item)}${chalk.gray(':')} ${chalk.reset(str)}`,
    )
}

export function logCommand (
    cmdDef: Parameters<typeof Bun.spawnSync>,
    item: string,
    errMsg: string,
) {
    try {
        const { exitCode, stdout, stderr } = Bun.spawnSync(...cmdDef)

        if (exitCode !== 0) {
            throw new NonZeroReturnError(errMsg, new TextDecoder().decode(stderr).trim())
        } else {
            const cmdStdout = new TextDecoder().decode(stdout).trim()
            logItem(item, cmdStdout.length === 0 ? successNoStdout : cmdStdout)
        }
    } catch (e: unknown) {
        // XXX: TypeScript has cursed exception type-narrowing in switch-case even
        //      though JavaScript uses non-value exceptions, hilarious. Hey guys
        //      let's have an exception system where you cannot even narrow on
        //      exception types in a switch-case who would ever need that??????
        if (e instanceof Error) {
            logItemError(item, e.stack ?? '<NO STACK TRACE>')
            if (e.cause) {
                console.log(`\n${e.cause}`)
            }
        }

        // Errors.
        return false
    }

    // No errors.
    return true
}

// Block while printing chosen Nargo information; this is extremely important
//   being that Nargo comprises the system under test and having to guess
//   what version (e.g. multiple installs) is being used sucks, so print it.
export function checkTestEnvironment (wd: string, circuits: CircuitDefinition) {
    console.log(
        chalk.yellow(padCentre('Check test environment & build circuits', roseChar)),
    )

    logItem('cwd', wd)

    // ------------------------------ Actual checks like command availability.

    // This executes immediately and fills prechecks with true/false values.
    const envChecks = [
        logCommand(
            [['command', '-v', 'nargo'], { cwd: wd }],
            'nargo executable',
            'Nargo executable not found in $PATH',
        ),
        logCommand(
            [['nargo', '--version'], { cwd: wd }],
            'nargo ver',
            'could not determine Nargo version',
        ),
    ]

    const envSuccess = envChecks.every((res) => res === true)

    if (envSuccess === false) {
        console.log(chalk.red('ENVIRONMENT CHECKS FAILED!'))
    }

    // ------------------------------ Compile circuits.

    // TODO XXX
    // For now we rebuild every time tests are run because `bun test` cannot
    //   receive cli arguments? augment `runner.ts` to workaround this.
    // Spoke to Jared on Bun's Discord and he confirmed `bun test` does not pass
    //   arguments to test scripts but they may implement `--` to then allow
    //   this. If I have time, and this isn't implemented by then, have a crack
    //   at a PR for this.

    const buildStub = ['nargo', 'compile', '--include-keys']

    const circuitSuccess = Object.entries(circuits).every(([name, details]) => {
        // Build circuit.
        const build = logCommand(
            [buildStub, { cwd: details.path }],
            `circuit compile '${name}'`,
            `COULD NOT COMPILE circuit '${name}' at ${details.path}`,
        )
        // Check we know path to compiled circuit (arguably pedantic since we
        //   import it later but fine for now; also slow).
        const artifact = logCommand(
            [['test', '-f', details.circuit], { cwd: wd }],
            `circuit artifacts for '${details.path}'`,
            `circuit ARTIFACTS MISSING expected at '${details.circuit}'`,
        )

        return (build && artifact) === true
    })

    console.log(chalk.yellow(roseChar.repeat(80)))

    return envSuccess && circuitSuccess
}
