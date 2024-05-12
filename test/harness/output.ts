import chalk from 'chalk'
import { log } from '#test/harness'
import { TextLineStream } from '#test/harness/utility'

// This file runs our test suite (you could invoke it yourself if you'd like)
//   and prints our logs first, and then Bun's which Bun itself outputs on
//   stderr by default (we keep Bun's convention).

// NB: All Bun's own test information is in stderr by default.
const { exited, stdout, stderr } = Bun.spawn(
    // TODO: Argument parsing and/or passing?
    ['bun', 'test', '--preload', './test/harness/preload.ts', ...Bun.argv.slice(2)],
    {
        stdout: 'inherit', // Merged to parent.
        stderr: 'pipe', // Stream buffer.
        env: {
            ...process.env,
            // To take advantage of Bun annotating output for us which we can use
            //   to augment test output ourselves given how locked down `bun test`
            //   is currently.
            GITHUB_ACTIONS: 'true',
            FORCE_COLOR: '1',
            NARGO_SILENT: 'true',
        },
    },
)

// Yes, this does mean we collect Bun's stderr output in memory.
let bun_stderr = ''

const OUTPUT: {
    group: string | undefined
    levels: Array<string>
} = {
    group: undefined,
    levels: [],
}

// Log the test file we're in.
function logFile(file_path: string) {
    console.log(chalk.hex('#BBB')(`@ ${OUTPUT.group}`))
}

// Create indent prefix characters.
function indent(times?: number) {
    return `${'-'.repeat(times ?? 0)}>`
}

// Log the describe functions label.
function logDescribe(describe_label: string, nest_level?: number) {
    console.log(`${chalk.bgGrey(indent(nest_level))} ${chalk.bold(describe_label)}`)
}

// Log the test functions label.
function logTest(test_label: string, nest_level?: number) {
    console.log(`${chalk.black.bgYellow(indent(nest_level))} ${chalk.yellow.bold(test_label)}`)
}

const ln_stderr = stderr.pipeThrough(new TextLineStream())
for await (const ln of ln_stderr) {
    // console.log('-------> raw line:', ln)
    const { flag, data } = /^::(?<flag>[a-zA-Z]+)::(?<data>.+)?$/.exec(ln)?.groups || {}
    // console.log('-------> flag:', flag)

    switch (flag) {
        //
        // Group is per file (XXX: And so there can never be nested groups.. right?)
        case 'group':
            OUTPUT.group = data.slice(0, -1)
            break
        case 'endgroup':
            OUTPUT.group = undefined
            break
        //
        // Cannot sequence `describe` so each test flag has the full test path
        //   which we must split and check each time. Not the best but it's the
        //   only viable option currently.
        // Also assuming that we run tests in sequence so we always correctly
        //   move up/down levels in matching pairs.
        case 'test': {
            if (OUTPUT.group) {
                logFile(OUTPUT.group)
                OUTPUT.group = undefined
            }

            // XXX: `test_name` should never be undefined, big problems if it is.
            const levels = data.split(' > ')
            if (levels.length === 0) throw new Error('Missing test name')
            // biome-ignore lint/style/noNonNullAssertion: checking for it above, come on TS do some narrowing please.
            const test_name = levels.pop()!

            for (const [i, lvl] of levels.entries()) {
                if (lvl !== OUTPUT.levels.at(i)) {
                    logDescribe(lvl, i)
                }
            }

            OUTPUT.levels = levels

            logTest(test_name, levels.length)
            break
        }
        case 'endtest':
            // TODO: Could print a footer of test width or set a flag for alternating indentation colour?
            break
        //
        // TODO: Get rid of annoying `::error file=` shit.
        // case 'error file':
        // console.log('hit')
        // break
        default:
            bun_stderr += `${ln}\n`
    }
}

log.heading_err('Test summary')

// Finally output Bun's default stderr (from `bun test`).
process.stderr.write(bun_stderr)

// TODO: Trap CTRL+C and kill everything.
