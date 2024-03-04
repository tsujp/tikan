export function spawnTest(wd: string) {
    const proc = Bun.spawn(['nargo', 'test', '--silence-warnings', '--show-output'], {
        cwd: wd,
        stdout: 'pipe',
    })

    return proc
}

const wd = process.cwd()
const foo = spawnTest(wd)
const stream = await new Response(foo.stdout).text()

console.log('---------------------------------')

const KIND_LENGTH = 6
const SEPERATOR_LENGTH = 1 // The `:` for clarity if run without this file.
const ENCODING_LENGTH = KIND_LENGTH + SEPERATOR_LENGTH
let idx = 0
let kind = ''
let pyld = ''
for await (const chr of stream) {
    if (chr === '\n') {
        logEncoded(kind.substring(0, KIND_LENGTH), pyld)
        idx = 0
        kind = ''
        pyld = ''
        continue
    }

    if (idx < ENCODING_LENGTH) {
        kind += chr
    } else {
        pyld += chr
    }

    // if (idx === ENCODING_LENGTH) {
    //     console.log('encoding is:', enc)
    // }

    idx++
}

type LOG_ENCODINGS =
    | 'T_NAME'
    | 'T_STEP'
    | 'T_GAME'
    | 'T_MOVE'
    | 'T_COMT'
    | 'T___IN' // Input to a function.
    | 'T__OUT' // Output from a function.

function logName(name: string) {
    console.log(`* ${name}`)
}

function logStep(step: string) {
    console.log(`    (f) ${step}`)
}

function logCommit(payload: any) {
    console.log(`    <--    ${payload}`)
    console.log(`    -->    ${payload}`)
}

function logInput(payload: any) {
    console.log(`    <-     ${payload}`)
}

function logOutput(payload: any) {
    console.log(`     ->    ${payload}`)
}

function logEncoded(tipe: LOG_ENCODINGS, payload: any) {
    switch (tipe) {
        case 'T_NAME': {
            logName(payload)
            break
        }
        case 'T_STEP': {
            logStep(payload)
            break
        }
        case 'T___IN': {
            logInput(payload)
            break
        }
        case 'T__OUT': {
            logOutput(payload)
            break
        }
        case 'T_COMT': {
            logCommit(payload)
            break
        }
        case 'T_GAME': {
            console.log('T_GAME TODO')
            break
        }
        case 'T_MOVE': {
            console.log('T_GAME TODO')
            break
        }
        // Not yet as Nargo prints extra stuff (like the fact it's going to run tests
        //   etc which would trigger this).
        // default: {
        //     console.error(`UNKNOWN ENCODING RECEIVED: '${tipe}'`)
        // }
    }
}

process.on('SIGINT', () => {
    console.log('Cleaning up...')
    // fsEvents.close();
    // server.stop()
    process.exit(0)
})
