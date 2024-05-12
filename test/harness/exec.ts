// Controlled by environment variable `GITHUB_ACTIONS` being set to string `true`
//   as said env var controls Bun annotating test files in `stderr` output with
//   `::group::FILE_PATH` and `::endgroup::FILE_PATH`; we piggyback off of this.

const ANNOTATE_OUTPUT = process.env.GITHUB_ACTIONS === 'true'

// INPRO: Idea is to augment Bun's `$` such that executed command has no output by
//        default but if a logging function is passed as the last argument the command
//        output is logged using that function.
import { $ } from 'bun'

export type ExecThis = {
    cmd: string
    wd: string
    stdout: string
    stderr: string
    exit_code: number
}

import type { Logger } from '#test/loggies'
import { NonZeroReturnError } from '#test/harness/utility'

export async function $exec<const L extends Logger>(
    cmd: string,
    logger?: L,
    ...logger_rest: Parameters<L>
) {
    // Disable escaping as WE'RE using this API (not randoms) and we want to
    //   write commands literally instead of as string arrays.
    const {
        stdout: cmd_stdout,
        stderr: cmd_stderr,
        exitCode,
    } = await $`${{ raw: cmd }}`.nothrow().quiet()

    const stdout = cmd_stdout.toString().trimEnd()
    const stderr = cmd_stderr.toString()

    // TODO: Add the checking of `GITHUB_ACTIONS` env var into `loggies` stuff.

    const __this = {
        cmd,
        wd: process.cwd(),
        stdout,
        stderr,
        exit_code: exitCode, // Not a library (yet?) so fuck programs that use non-zero exit success.
    }

    if (logger) {
        logger.call(__this, ...logger_rest)

        return exitCode === 0
    }

    if (exitCode !== 0) {
        console.log(`command: '${cmd}' failed`)
        // TODO: Allow custom error as first param to NonZeroReturnError.
        throw new NonZeroReturnError(stderr, stderr)
    }

    // TODO: If I return std{out, err} probably don't need the extra callback checks for SilenceLogParam on the default logger.
    return [stdout, stderr]
}
