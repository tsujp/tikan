import { type AllCircuits } from '../types'
import { behaviour as args } from './parse_args'
import { logCommand, logHeading, COMMAND_DESC } from './misc'

// Block while printing chosen Nargo information; this is extremely important
//   being that Nargo comprises the system under test and having to guess
//   what version (e.g. multiple installs) is being used sucks, so print it.
export async function checkTestEnvironment(wd: string, circuits: AllCircuits) {
    logHeading('Check test environment & build circuits')

    console.log(COMMAND_DESC('project root', wd))

    // ------------------------------ Command availability, versions.

    const env_cmds = [
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

    // Exit early.
    if ((await Promise.all(env_cmds)).every((res) => res === true) === false) {
        console.error('ENVIRONMENT CHECKS FAILED!')
        return false
    }

    // ------------------------------ Compile binary circuits, check library circuits.

    const lib_checks = circuits.lib.map(({ name, root }) =>
        // Check constraint system (as we cannot compile a library circuit).
        logCommand(
            [['nargo', 'check', args.s.do ? args.s.payload : ''], { cwd: root }],
            `[lib] check '${name}'`,
            `circuit CONSTRAINT SYSTEM ERROR in ${root}`,
        )
    )

    const bin_checks = circuits.bin.map(({ name, root, artifact }) => {
        return new Promise(async (resolve) => {
            // Build circuit.
            const chk_build = await logCommand(
                // XXX: Upstream `--include-keys` to `nargo compile` was removed.
                [['nargo', 'compile', args.s.do ? args.s.payload : ''], { cwd: root }],
                `[bin] compile '${name}'`,
                `COULD NOT COMPILE circuit '${name}' at ${root}`,
            )
            // Early return on build circuit, no point checking if we couldn't build.
            if (chk_build === false) return resolve(false)

            // Check we know path to compiled circuit (arguably pedantic since we
            //   import it later but fine for now; also slow).
            const chk_artifact = await logCommand(
                [['test', '-f', artifact], { cwd: wd }],
                `[bin] artifacts '${name}'`,
                `circuit ARTIFACTS MISSING expected at '${root}'`,
            )

            return resolve(chk_artifact)
        })
    })

    // Order is orchestrated within relevant promises (only relevant for bin).
    const circuit_checks = await Promise.all([...lib_checks, ...bin_checks])

    return { checks: circuit_checks.every((res) => res === true), args }
}
