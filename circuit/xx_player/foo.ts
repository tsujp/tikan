export function spawnTest(wd: string) {
    const proc = Bun.spawn(['nargo', 'test', '--silence-warnings', '--show-output'], {
        cwd: wd,
        stdout: 'pipe',
        // stderr: 'pipe',
        // stdin: 'pipe',
        // stdout: 'inherit',
        // stderr: 'inherit',
        // ipc(message, childProc) {
        //     // console.log('PARENT RECEIVED', message, childProc.pid)
        //     // log(message)
        //     // console.log('PARENT RECEIVED', message, childProc.pid)
        // }a
    })

    // proc.send(msg)

    return proc
}

const wd = process.cwd()

const foo = spawnTest(wd)

const stream = await new Response(foo.stdout).text()

console.log('---------------------------------')

const ENCODING_LENGTH = 6
let idx = 0
let kind = ''
let pyld = ''
for await (const chr of stream) {
    if (chr === '\n') {
        logEncoded(kind, pyld)
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

type LOG_ENCODINGS = 'T_NAME' | 'T_STEP' | 'T_GAME' | 'T_MOVE' | 'T_COMT'

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


// ---
// let idx = 0
// let tipe = ''
// for await (const chr of stream) {
//    console.write(chr) 

//     if (chr === '\n') {
//         idx = 0
//         tipe = ''
//         continue
//         // TODO: Parse it according to tipe
//     }
    
//     if (idx < 4) {
//         tipe += chr
//         // console.log('tipe is', tipe, 0 + (2 ** parseInt(chr)), typeof tipe)
//     }
    
//     if (idx === 4) {
//         // const encoding = parseInt(tipe.reverse().join(''), 2)
//         const encoding = parseInt(tipe, 2)
//         console.log('encoding is:', encoding)
//     }

//     // console.log('next line is', ln)
//     idx++
//     console.log()
    
//     // console.log(parseInt('0001', 2))
//     // console.log(parseInt('0010', 2))
//     // console.log(parseInt('0100', 2))
//     // console.log(2 ** 0)
//     // console.log(2 ** 1)
// }
// ---

process.on('SIGINT', () => {
    console.log('Cleaning up...')
    // fsEvents.close();
    // server.stop()
    process.exit(0)
})


/*
Could make it prettier by only grabbing stderr, etc

[devshell] circuit/xx_player $ nargo test --show-output --silence-warnings 2> /dev/null
[xx_player] Running 1 test function

T_NAMEwhite compass-rose moves 1 to 0
T_NAMEwhite compass-rose moves 1 to 5
T_NAMEwhite compass-rose moves 1 to 6
T_NAMEwhite compass-rose moves 1 to 7
T_NAMEwhite compass-rose moves 1 to 2
[devshell] circuit/xx_player $ nargo test --show-output --silence-warnings 1> /dev/null
[xx_player] Testing compass_moves__white__1... ok
[xx_player] 1 test passed
*/