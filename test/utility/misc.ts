import { join } from 'path'
import chalk from 'chalk'
import { readableStreamToText } from 'bun'
import { NonZeroReturnError, type AllCircuits } from '../types'

// TODO: waste time typing this (TypeScript) later.
// @ts-ignore
export const asyncMap = (items, fn) => Promise.all(items.map(fn))

// Resolve the root workspace, no other way to do this currently.
// XXX: Will not work with nested workspaces, don't be satanic.
//   - Environment variables from `.env` files are not read when in a
//     subdirectory; honestly it'd be somewhat weird if they were because
//     when do you stop reading them from the parent? What if a git repo isn't
//     instantiated yet?
//   - `exports` from the root workspace package.json are not readable which
//     is the real killer here; they should be.
export async function resolveProjectRootDir(): Promise<string> {

    // No (big) recursive closures please.
    async function iter(cur: string): Promise<string> {
        const nxt = join(cur, '..')
        if (nxt === cur) return Promise.reject('Workspace package.json not found in any parent directory')

        const contents = await Bun.file(join(cur, 'package.json')).json().catch(e => {
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

                    chalked_str += (getValue(expressions[j]) + strs[j + 1])
                }

                if (matched[0] === false) {
                    throw new Error('Template string has no matching end')
                }

                // Yes, yes but nah.
                const colourised = Function('lib', '_str', `return ${expr.replace('>>', 'lib.')}(_str)`)(chalk, chalked_str)

                i = (matched[1] - 1)
                result += colourised
            } else {
                result += (getValue(expr) + strs[i + 1])
            }
        }

        return result
    }
}

// Bespoke hacky template syntax cos why not (experimenting).
// const COMMAND_DESC = template`${'>>cyan.bold'}${0}+${';'}${0} to ${'>>red'}${0} and ${1}${';'} ${2}: |`
export const COMMAND_DESC = template`${'>>cyan'}${0}${';'}${'>>gray'}:${';'} ${1}`

const COMMAND_ERROR = template`${'>>gray'}<${';'}${'>>red.bold'}bad${';'}${'>>gray'}>${';'} ${'>>bold'}${0}${';'}\n\
${3}
${'>>bold'}command${';'}: \`${1}\` in directory ${2}`

const COMMAND_SUCCESS = template`${'>>gray'}<${';'}${'>>green'}ok${';'}${'>>gray'}>${';'} ${0}`

const EMPTY_FILLER = template`${'>>gray'}<${0}>${';'}`

// (A)synchronously executes the given command and logs success or output error.
export async function logCommand(
    cmd: Parameters<typeof Bun.spawnSync>,
    desc: string,
    err: string
) {
    try {
        // const { exitCode, stdout, stderr } = Bun.spawn(...cmd)
        const { exited, stdout, stderr } = Bun.spawn(...cmd)
        const exitCode = await exited
        console.write(COMMAND_DESC(desc))
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
        if (exitCode !== 0) {
            throw new NonZeroReturnError(err, new TextDecoder().decode(stderr).trim())
        } else {
            // const cmdStdout = new TextDecoder().decode(stdout).trim()
            const cmdStdout = (await readableStreamToText(stdout)).trim();

            console.log(COMMAND_SUCCESS(cmdStdout.length === 0 ? EMPTY_FILLER('empty') : cmdStdout))
        }
    } catch (e: unknown) {
        // XXX: TypeScript has cursed exception type-narrowing in switch-case even
        //      though JavaScript uses non-value exceptions, hilarious. Hey guys
        //      let's have an exception system where you cannot even narrow on
        //      exception types in a switch-case who would ever need that??????
        if (e instanceof Error) {
            console.log(COMMAND_ERROR(e.message, cmd[0].join(' '), cmd[1]?.cwd, e.cause ?? EMPTY_FILLER('empty error cause')))
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

    return spaceStr.padStart(Math.floor(spaceStr.length / 2) + Math.floor(max / 2), padStr)
        .padEnd(max, padStr)
}

export function logHeading(text: string) {
    console.log(
        chalk.yellow(padCentre(text, roseChar)),
    )
}

// Reads `noir` key present within `package.json` in given directory and constructs
//   a list of circuit definitions based on their type (bin/lib) and name by
//   reading their related `Nargo.toml` files.
export async function getNoirCircuits(
    root_dir: string,
): Promise<AllCircuits> {
    // TODO: Bun can infer this or something IIRC?
    const pkg_defs: string[][] = await import(join(root_dir, 'package.json')).then(({ noir }) => noir.circuits)

    const res_defs = {
        bin: [],
        lib: []
    }

    for (let k of Object.keys(pkg_defs)) {
        const root = join(root_dir, pkg_defs[k])
        const { package: { name, type } } = await import(join(root, 'Nargo.toml'))

        res_defs[type].push({
            name: k,
            root: join(root_dir, pkg_defs[k]),
            ...(type === 'bin') && { artifact: join(root_dir, pkg_defs[k], `target/${name}.json`) }
        })
    }

    return res_defs
}
