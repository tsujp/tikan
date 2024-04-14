import type { AllCircuits } from '#test/types'
import { COMMAND_DESC, COMMAND_SUCCESS, logCommand, logHeading } from '#test/utility/misc'
import { behaviour as args } from '#test/utility/parse_args'

// Block while printing chosen Nargo information; this is extremely important
//   being that Nargo comprises the system under test and having to guess what
//   version (e.g. multiple installs) is being used sucks, so print it.
export async function checkTestEnvironment(wd: string, circuits: AllCircuits) {
    logHeading('Environment', true)

    console.log(COMMAND_DESC('project', wd))

    // ------------------------------ Command availability, versions.

    const env_cmds = [
        logCommand(
            [['command', '-v', 'nargo'], { cwd: wd }],
            'nargo bin',
            'Nargo executable not found in $PATH',
        ),
        logCommand(
            [['nargo', '--version'], { cwd: wd }],
            'noir ver',
            'could not determine Nargo version',
            (stdout) => {
                // Only care about first two lines, nargo and noirc versions.
                return stdout
                    .split('\n')
                    .slice(0, 2)
                    .map((t) => t.split(' = ')[1])
                    .join('  ')
            },
        ),
    ]

    // Exit early.
    if ((await Promise.all(env_cmds)).every((res) => res === true) === false) {
        console.error('ENVIRONMENT CHECKS FAILED!')
        return false
    }

    // ------------------------------ Compile circuits.

    logHeading('Circuits', true)

    // Fuck efficiency.
    const all_circuits = [
        ...circuits.bin.map(({ name }) => name),
        ...circuits.lib.map(({ name }) => name),
    ].join(', ')

    console.write(COMMAND_DESC('found circuits'))
    console.log(COMMAND_SUCCESS(all_circuits))

    // Consisting of (1) clean (2) compile (3) check for artifacts.
    console.write(COMMAND_DESC('recompile'))

    await logCommand(
        [['rm', '-f', 'target/*.json'], { cwd: wd }],
        // 'cleaning artifacts',
        false,
        'COULD NOT REMOVE EXISTING ARTIFACTS',
    )

    await logCommand(
        [
            [
                'nargo',
                'compile',
                '--workspace',
                // args.s.do ? args.s.payload : '',
                import.meta.env.NARGO_SILENT == null ? '' : '--silence-warnings',
            ],
            { cwd: wd },
        ],
        // 'compile workspace',
        false,
        'ERROR COMPILING CIRCUITS',
    )

    // ------------------------------ Check artifacts are present.

    const artifact_names: Array<string> = []
    const artifact_checks = circuits.bin.map(({ name, root, artifact }) => {
        // Check we know path to compiled circuit (arguably pedantic since we
        //   import it later but fine for now; also slow).
        artifact_names.push(name)
        return logCommand(
            [['test', '-f', artifact], { cwd: wd }],
            // `artifacts '${name}'`,
            false,
            `circuit ARTIFACT MISSING, expected at '${root}'`,
        )
    })

    // Order is orchestrated within relevant promises (only relevant for bin).
    const circuit_checks = await Promise.all([...artifact_checks])
    const all_good = circuit_checks.every((res) => res === true)

    // For printing's sake.
    if (all_good) {
        console.log(COMMAND_SUCCESS(artifact_names.join(', ')))
    }

    return { checks: all_good, args }
}
