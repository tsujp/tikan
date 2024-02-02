import chalk from 'chalk'
import { parseArgs } from 'util'

const { tokens } = parseArgs({
    args: Bun.argv,
    options: {},
    strict: false,
    // $0 executable, $1 file are what this API calls positionals. Needed otherwise
    //   invocations under UNIX-like API won't work.
    allowPositionals: true,
    tokens: true,
})

export const behaviour = {
    prior_single: null,
    // Lib.
    l: {
        do: false,
        payload: '',
    },
    // Bin.
    b: {
        do: false,
        payload: '',
    },
    // Global only, if required make them per `l` or `b` later.
    // Show output.
    o: {
        do: false,
        payload: '--show-output'
    },
    // Silence warnings.
    s: {
        do: false,
        payload: '--silence-warnings'
    },
    nargo: []
}

function errorRepeatedOption(opt: string) {
    console.error(`${chalk.reset.redBright.bold('error:')} repeated option '${chalk.yellow(opt)}', only specify options once`)
    process.exit(1)
}

// First 2 elements are positionals: executable and script, we don't care about that.
const s_idx = tokens.slice(2).some((tkn, idx, arr) => {
    // console.log(tkn)
    // TODO: Arguments after 'option-terminator' can go to `bun test`.

    switch (tkn.kind) {
        case 'option': {
            switch (tkn.name) {
                case 'l':
                case 'b':
                    behaviour.prior_single ??= tkn.name
                case 'lib':
                case 'bin': {
                    const test_patterns = arr[idx + 1]
                    const tkn_name = tkn.name.charAt(0)

                    // TODO: TypeScript's incessant whining bullshit.

                    if (behaviour[tkn_name].do === true) {
                        errorRepeatedOption(tkn.rawName)
                    }

                    behaviour[tkn_name].do = true

                    // TODO: This should be in it's own case, set a flag here so that
                    //       case can read stuff. You'd know you're at the next
                    //       argument by checking tkn.index because if you pass
                    //       -lbs or -lb then there are 3 or 2, respectively, options
                    //       at the same index. Whereas `-lb -s` has 2 options at the
                    //       same index and `-s` at index + 1.
                    // Next argument is not a positional, so no string pattern to
                    //   capture for nargo tests.
                    if (test_patterns?.kind !== 'positional') {
                        break
                    }

                    behaviour[tkn_name].payload = test_patterns.value

                    if (behaviour.prior_single !== null) {
                        behaviour[behaviour.prior_single].payload = test_patterns.value
                        behaviour.prior_single = null
                    }

                    break
                }
                case 'o':
                    if (behaviour[tkn.name] === true) errorRepeatedOption(tkn.rawName)
                    behaviour[tkn.name].do = true
                    break
                case 's':
                    if (behaviour[tkn.name] === true) errorRepeatedOption(tkn.rawName)
                    behaviour[tkn.name].do = true
                    break
                default: {
                    console.error(`${chalk.reset.redBright.bold('error:')} unexpected option '${chalk.yellow(tkn.rawName)}'`)
                    process.exit(1)
                }
            }
            break
        }
    }

    return tkn.kind === 'option-terminator'
})
