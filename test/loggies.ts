import type { ExecThis } from '#test/exec_v2'
import {
    COMMAND_DESC,
    COMMAND_ERROR,
    COMMAND_SUCCESS,
    EMPTY_FILLER,
    padCentre,
} from '#test/harness/utility'
import chalk from 'chalk'

const ROSE_CHAR = '-' as const

export const SilenceLogParam = Symbol()
type SilenceLog = typeof SilenceLogParam

// -------------------------------------------------- TYPES
// Acceptable log-function signatures.
type LogFn_Basic = (...args: any[]) => void
type LogFn_Context = (this: any, ...args: any[]) => void

type LogFunctions = LogFn_Basic | LogFn_Context

// Extra logging functions are defined on an object we need to be able to index.
type Log_Extra = {
    [key: string]: LogFunctions
}

// Base logging function is given as an arrow function directly.
type Log_Base = LogFn_Basic

// Quick and dirty, the alternative is a 10 hour trip in TS fuckery.
declare const _tag: unique symbol
type LoggerTag = {
    readonly [_tag]: 'valid_log_fn'
}

// XXX: This does let through `any` i.e. `some_func_object.arguments` but hey,
//      fuck spending any more time narrowing that down unless this is becoming
//      a library.
// Classic structural typing.
export type Logger = (Log_Base & LoggerTag) | (Log_Base & Log_Extra & LoggerTag)

type AugmentLogger<B extends Log_Base, E extends Log_Extra> = B &
    LoggerTag & {
        [K in keyof E]: E[K] & LoggerTag
    }

// --------------------------------------------------- IMPLEMENTATION
export function MakeLogger<B extends Log_Base, E extends Log_Extra>(base: B, extra?: E) {
    return Object.assign(base, extra) as AugmentLogger<B, E>
}

// --------------------------------------------------- DEFAULTS

// Effectively `unless` from Ruby.
function shouldLog(param: unknown | SilenceLog) {
    return param !== SilenceLogParam
}

const TTY_COLUMNS = process.stdout.columns

const DEFAULT_LOGGER = MakeLogger(
    (text?: string) => {
        console.log('DEFAULT:', text)
    },
    {
        basic: (text?: string) => {
            console.log('LOG BASIC:', text)
        },

        command: function (
            this: ExecThis,
            annotation?: string | SilenceLog,
            // biome-ignore lint/suspicious/noConfusingVoidType: you're wrong, it's a return type Biome.
            error?: string | SilenceLog | ((stderr: string) => unknown | void),
            // success?: string | SilenceLog,
            success?:
                | string
                | SilenceLog
                // biome-ignore lint/suspicious/noConfusingVoidType: you're wrong, it's a return type Biome.
                | ((stdout: string, stderr?: string) => unknown | void),
        ) {
            if (shouldLog(annotation)) console.write(COMMAND_DESC(annotation))

            // Success.
            if (this.exit_code === 0) {
                const _s =
                    typeof success === 'function' ? success(this.stdout, this.stderr) : success
                if (shouldLog(_s))
                    console.log(
                        COMMAND_SUCCESS(
                            _s ??
                                (this.stdout.length === 0
                                    ? EMPTY_FILLER('empty')
                                    : this.stdout),
                        ),
                    )
                return
            }

            // Error.
            if (shouldLog(error)) {
                const _e = typeof error === 'function' ? error(this.stderr) : error
                console.log(
                    COMMAND_ERROR(
                        _e ?? EMPTY_FILLER('empty message'),
                        this.cmd,
                        this.wd,
                        this.stderr ?? EMPTY_FILLER('empty cause'),
                    ),
                )
                return
            }
        },

        heading: (text?: string, conspicuous?: boolean) => {
            if (conspicuous) {
                console.log(chalk.yellow.bold(`[${text}]`))
                return
            }

            console.log(chalk.yellow(padCentre(text ?? '', ROSE_CHAR)))
        },

        // TODO: Removes colour when 1> /dev/null, fix later maybe.
        // Quick patch, Bun output header needs to be on stderr.
        heading_err: (text?: string, conspicuous?: boolean) => {
            if (conspicuous) {
                process.stderr.write(chalk.yellow.bold(`[${text}]\n`))
                return
            }

            process.stderr.write(`${chalk.yellow(padCentre(text ?? '', ROSE_CHAR))}\n`)
        },
    },
)

// Not the best but whatever.
let incomplete_line = false
function test_log(with_newline: boolean, ...args: any[]) {
    if (typeof args.at(0) !== 'object' && incomplete_line === false) {
        process.stderr.write('::log::')
    }

    // This sucks but is fine for now.
    for (const [i, a] of args.entries()) {
        switch (typeof a) {
            case 'object':
                // i === 0 ? process.stderr.write('\r') : process.stderr.write('\n')
                // process.stderr.write('\n')
                if (i > 0) process.stderr.write('\n')

                for (const obj_ln of Bun.inspect(a, { colors: true }).split('\n')) {
                    process.stderr.write(`::log::${obj_ln}\n`)
                }

                // Still more to come.
                if (i !== args.length - 1) {
                    process.stderr.write('::log::')
                }
                break
            default:
                process.stderr.write(i > 0 || incomplete_line ? ` ${a}` : a)
        }
    }

    if (with_newline) {
        incomplete_line = false
        process.stderr.write('\n')
    } else {
        incomplete_line = true
    }
}

const TEST_LOGGER = MakeLogger(
    (...args: any[]) => {
        // console.log('DEFAULT:', text)
        test_log(true, ...args)
    },
    {
        write: (...args: any[]) => {
            test_log(false, ...args)
        },
    },
)

// --------------------------------------------------- EXPORTS

export const testLog = TEST_LOGGER
export const log = DEFAULT_LOGGER
export type DefaultLogger = typeof DEFAULT_LOGGER
