import { type AllCircuits } from '../types'
import { COMMAND_DESC, COMMAND_SUCCESS, logCommand, logHeading } from './misc'
import { behaviour as args } from './parse_args'

// Block while printing chosen Nargo information; this is extremely important
//   being that Nargo comprises the system under test and having to guess
//   what version (e.g. multiple installs) is being used sucks, so print it.
export async function checkTestEnvironment (wd: string, circuits: AllCircuits) {
    logHeading('Environment')

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

    // ------------------------------ Compile circuits.

    logHeading('Circuits')

    // Fuck efficiency.
    const all_circuits = [
        ...circuits.bin.map(({ name }) => name),
        ...circuits.lib.map(({ name }) => name),
    ]
        .join(', ')

    console.write(COMMAND_DESC('found circuits'))
    console.log(COMMAND_SUCCESS(all_circuits))

    await logCommand(
        [['nargo', 'compile', '--workspace', args.s.do ? args.s.payload : ''], { cwd: wd }],
        'compile workspace',
        'ERROR COMPILING CIRCUITS',
    )

    // ------------------------------ Check artifacts are present.

    const artifact_checks = circuits.bin.map(({ name, root, artifact }) => {
        return new Promise(async (resolve) => {
            // Check we know path to compiled circuit (arguably pedantic since we
            //   import it later but fine for now; also slow).
            const chk_artifact = await logCommand(
                [['test', '-f', artifact], { cwd: wd }],
                `artifacts '${name}'`,
                `circuit ARTIFACTS MISSING expected at '${root}'`,
            )

            return resolve(chk_artifact)
        })
    })

    // Order is orchestrated within relevant promises (only relevant for bin).
    // const circuit_checks = await Promise.all([...lib_checks, ...bin_checks])
    const circuit_checks = await Promise.all([...artifact_checks])

    logHeading('Tests')

    return { checks: circuit_checks.every((res) => res === true), args }
}
