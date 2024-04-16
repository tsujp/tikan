import { join } from 'node:path'
import { readableStreamToText } from 'bun'
import chalk from 'chalk'
import { NonZeroReturnError } from '../types'

// TODO: waste time typing this (TypeScript) later.
// @ts-ignore
export const asyncMap = (items, fn) => Promise.all(items.map(fn))

// Resolve the root workspace, no other way to do this currently.
//   - Environment variables from `.env` files are not read when in a subdir.
export async function getProjectRoot(): Promise<string> {
    // No (big) recursive closures please.
    async function iter(cur: string): Promise<string> {
        const nxt = join(cur, '..')
        if (nxt === cur) {
            return Promise.reject('Workspace package.json not found in any parent directory')
        }

        const contents = await Bun.file(join(cur, 'package.json'))
            .json()
            .catch((e) => {
                // errno -2 is 'no such file or directory' which, if there is an error, is the only
                //   error we want to 'accept'.
                if (e.errno !== -2) {
                    console.error(e)
                    return Promise.reject('Unexpected error attempting to read file')
                }
            })

        if (contents?.workspaces) {
            return Promise.resolve(cur)
        }

        return iter(nxt)
    }

    return iter(process.cwd())
}

// TODO: Count literal values in here as well as provided template values so-as-to get
//       the length of the string? Since we only use ANSI escape sequences for colours
//       we can afford to do this.

// TODO: Docs; Types maybe.
export function template(strs, ...expressions) {
    return (...values) => {
        const dict = values[values.length - 1] || {}
        let result = strs[0]

        function getValue(k) {
            return (Number.isInteger(k) ? values[k] : dict[k]) ?? ''
        }

        function getStr(k) {
            return strs[k] ?? ''
        }

        for (let i = 0; i < expressions.length; i++) {
            const expr = expressions[i]

            if (typeof expr === 'string' && expr.startsWith('>>')) {
                const matched: [boolean, number] = [false, 0]
                let chalked_str = ''

                for (let j = i; j < expressions.length; j++) {
                    if (expressions[j] === ';') {
                        matched[0] = true
                        matched[1] = j
                        break
                    }

                    chalked_str += getValue(expressions[j]) + strs[j + 1]
                }

                if (matched[0] === false) {
                    throw new Error('Template string has no matching end')
                }

                // Yes, yes but nah.
                const colourised = Function(
                    'lib',
                    '_str',
                    `return ${expr.replace('>>', 'lib.')}(_str)`,
                )(chalk, chalked_str)

                i = matched[1] - 1
                result += colourised
            } else {
                result += getValue(expr) + strs[i + 1]
            }
        }

        return result
    }
}

// Bespoke hacky template syntax cos why not (experimenting).
// const COMMAND_DESC = template`${'>>cyan.bold'}${0}+${';'}${0} to ${'>>red'}${0} and ${1}${';'} ${2}: |`
export const COMMAND_DESC = template`${0}${'>>gray'}:${';'} ${1}`

const COMMAND_ERROR = template`\n${'>>red.bold'}error${';'} ${'>>bold'}${0}${';'}\
${3}
${'>>bold'}command${';'}: \`${1}\` in directory ${2}`

export const COMMAND_SUCCESS = template`${'>>green'}ok${';'} ${'>>hex("#BBB")'}${0}${';'}`

const EMPTY_FILLER = template`${'>>hex("#333")'}<${0}>${';'}`

// Asynchronously executes the given command and logs output success or error.
// Optional callback mutates success (only) output before printing.
export async function logCommand(
    cmd: Parameters<typeof Bun.spawnSync>,
    // Yes this API sucks, tacking this on for now. Rewrite all this trash later.
    desc: string | false,
    err: string,
    cb?: (cmd_stdout: string) => string,
) {
    try {
        // const { exitCode, stdout, stderr } = Bun.spawn(...cmd)
        const { exited, stdout, stderr } = Bun.spawn(...cmd)
        const exit_code = await exited
        if (typeof desc === 'string') {
            console.write(COMMAND_DESC(desc))
        }
        // TODO: PR for standard help messages from Nargo. `nargo help test` and
        //       `nargo test --help` both print in the same format, but
        //       `nargo info --help` prints in a different one as does `nargo help info`.
        //       XXX: How does golang print its help messages?
        //       ANS: Like `nargo help test`, as does the popular command package
        //            used in Pocketbase; so go that route.

        // TODO: PR in nargo to list tests that it _would_ run but don't actually
        //       run them. So that people can see what tests there are without
        //       having to wait and more easily choose which tests they want to
        //       run using the pattern syntax.
        if (exit_code !== 0) {
            throw new NonZeroReturnError(err, new TextDecoder().decode(stderr).trim())
        }

        if (typeof desc === 'string') {
            const cmd_stdout_raw = (await readableStreamToText(stdout)).trim()

            const cmd_stdout = cb ? cb(cmd_stdout_raw) : cmd_stdout_raw

            console.log(
                COMMAND_SUCCESS(cmd_stdout.length === 0 ? EMPTY_FILLER('empty') : cmd_stdout),
            )
        }
    } catch (e: unknown) {
        // XXX: TypeScript has cursed exception type-narrowing in switch-case even
        //      though JavaScript uses non-value exceptions, hilarious. Hey guys
        //      let's have an exception system where you cannot even narrow on
        //      exception types in a switch-case who would ever need that??????
        if (e instanceof Error) {
            console.log(
                COMMAND_ERROR(
                    e.message,
                    cmd[0].join(' '),
                    cmd[1]?.cwd,
                    e.cause ?? EMPTY_FILLER('empty error cause'),
                ),
            )
        }

        // Errors.
        return false
    }

    // No errors.
    return true
}

// Padding character for `padCentre` et al.
const roseChar = '-'

// Single line string only; if left and right padding is odd will preference
//   left side (i.e. right side will receive the extra str pad).
export function padCentre(str: string, padStr: string, max = 80) {
    if (str.length > max) {
        return str
    }

    const spaceStr = ` ${str} `

    return spaceStr
        .padStart(Math.floor(spaceStr.length / 2) + Math.floor(max / 2), padStr)
        .padEnd(max, padStr)
}

export function logHeading(text: string, conspicuous?: boolean) {
    if (conspicuous) {
        console.log(chalk.yellow.bold(`[${text}]`))
        return
    }

    console.log(chalk.yellow(padCentre(text, roseChar)))
}
