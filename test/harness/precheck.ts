import type { AllCircuits } from '#test/harness/types'
import { COMMAND_DESC, COMMAND_SUCCESS } from '#test/harness/utility'
import { $exec, SilenceLogParam, log } from '#test/harness'

export async function assertEnvironment(wd: string, circuits: AllCircuits) {
    log.heading('Check and load', true)

    console.log(COMMAND_DESC('project', wd))

    // ------------------------------ Command availability, versions.
    const env_cmds = [
        $exec(
            'command -v nargo',
            log.command,
            'nargo bin',
            'Nargo executable not found in PATH',
        ),
        $exec(
            'nargo --version',
            log.command,
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

    // Bun version.
    console.log(COMMAND_DESC('bun', `${Bun.version} (${Bun.revision.slice(0, 8)})`))

    // Exit early.
    if ((await Promise.all(env_cmds)).every((res) => res === true) === false) {
        throw new Error('Environment checks failed')
    }

    // ------------------------------ Compile circuits.

    // Fuck efficiency.
    const all_circuits = [
        ...circuits.bin.map(({ name }) => name),
        ...circuits.lib.map(({ name }) => name),
    ].join(', ')

    console.write(COMMAND_DESC('found circuits'))
    console.log(COMMAND_SUCCESS(all_circuits))

    // Consisting of (1) clean (2) compile (3) check for artifacts.
    console.write(COMMAND_DESC('recompile'))

    await $exec(
        'rm -f target/*.json',
        log.command,
        SilenceLogParam,
        'COULD NOT REMOVE EXISTING ARTIFACTS',
        SilenceLogParam,
    )

    let compile_stats = ''
    await $exec(
        'nargo compile --workspace',
        log.command,
        SilenceLogParam,
        'ERROR COMPILING CIRCUITS',
        (_, stderr) => {
            // TODO: `nargo` does not respect NO_COLOR as such this regex could
            //       be better (i.e. by including `:`) but the ANSI escape codes
            //       with no option to disable them ruin this.
            compile_stats = `(${stderr?.match(/warning/g)?.length ?? 0} warn)`

            return SilenceLogParam
        },
    )

    // ------------------------------ Check artifacts are present.

    const artifact_names: Array<string> = []
    const artifact_checks = circuits.bin.map(({ name, root, artifact }) => {
        // Check we know path to compiled circuit (arguably pedantic since we
        //   import it later but fine for now; also slow).
        artifact_names.push(name)
        return $exec(
            `test -f ${artifact}`,
            log.command,
            SilenceLogParam,
            `circuit ARTIFACT MISSING, expected at '${root}'`,
            SilenceLogParam,
        )
    })

    // Order is orchestrated within relevant promises (only relevant for bin).
    const circuit_checks = await Promise.all([...artifact_checks])
    const all_good = circuit_checks.every((res) => res === true)

    // For printing's sake.
    // TODO: Capture any warning text?
    if (all_good) {
        console.log(COMMAND_SUCCESS(`${compile_stats} ${artifact_names.join(', ')}`))
        return
    }

    // Otherwise not all is good.
    throw new Error('Failed to assert test environment')
}
