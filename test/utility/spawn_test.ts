import { template } from './misc'

export function spawnTest(cwd: string, file: string, msg: any) {
    const proc = Bun.spawn(['bun', 'test', file], {
        cwd,
        // stdin: 'pipe',
        stdout: 'inherit',
        // stderr: 'inherit',
        ipc(message, childProc) {
            // console.log('PARENT RECEIVED', message, childProc.pid)
            log(message)
            // console.log('PARENT RECEIVED', message, childProc.pid)
        }
    })

    proc.send(msg)

    return proc
}

// Returns object with first underscore-delimited value in payload tag under key
//   `kind` and the rest of the tag (if any, none = empty string) under key `rest`.
// const NARROW_TAG_RE = /^(?<kind>[^_]+)_?(?<rest>.*)$/
function narrowTag(tag: string) {
    // OPT: Better regex or use `split` or something.
    return tag.match(/^(?<kind>[^_]+)_?(?<rest>.*)$/)?.groups ?? null
}

// const VALID_BLACK_START = [{ idx: 21, lights: true }, { idx: 23, lights: true }] as const

// const VALID_START_BOARD = {
//     halfmove: 0,
//     turn: 0,
//     commits: [
//         { x: '0x0', y: '0x0' },
//         { x: '0x0', y: '0x0' },
//     ],
//     players: [
//         VALID_WHITE_START,
//         VALID_BLACK_START,
//     ]
// } as const

// Pretty-print boardstate layout looks like:
// trn=1    hlf=1                { idx=3  lit=1 }    { idx=0  lit=0 }     { idx=21  lit=1 }    { idx=23  lit=1 }
// 0x17b0e63c113f17ee96ddd2c7bb151300e5e273d7e3458254bdda7802b342fe11  x  0x17b0e63c113f17ee96ddd2c7bb151300e5e273d7e3458254bdda7802b342fe11
// 02895eb00e5c01849ef70a102c9d4b2d09dda3ce77b5ac62547c96c30972834423  y  0x2895eb00e5c01849ef70a102c9d4b2d09dda3ce77b5ac62547c96c3097283443

const BIG_GAP = ' '.repeat(3)
const SMALL_GAP = ' '.repeat(2)
const PRE_PAD = ' '.repeat(7) // Max width of our ` IN <- ` and `OUT -> ` lead.

// Move these templates elsewhere.
const DATA_DIRECTION = template`${0}${'>>bold.underline'}${1}${';'} ${2} `

const KV_PAIR = template`${'>>italic'}${0}${';'}${'>>gray'}=${';'}${'>>bold'}${1}${';'}`

const SERIALISE_BOARD_STATE = template`foobar${KV_PAIR}`

const BRACES = template`${'>>dim'}{${';'}${0}${'>>dim'}}${';'}`

// TODO: Move this function elsewhere.
// TODO: Board state TS type.
function serialiseBoardState(state: {}) {
    const turn = KV_PAIR('trn', state.turn)
    const halfmove = KV_PAIR('hlf', state.halfmove)

    console.write(`${turn}${SMALL_GAP}${halfmove}`)

    const commit_lines = []

    // For each player (2 players).
    for (let i = 0; i < 2; i++) {
        const pieces_line = []
        for (let j = 0; j < state.players[i].length; j++) {
            const piece = state.players[i][j]
            pieces_line.push(BRACES(`${KV_PAIR('sqr', piece.idx)} ${KV_PAIR('lit', piece.lights)}`))
        }
        const line = pieces_line.join(SMALL_GAP)
        console.write(`${BIG_GAP}/${BIG_GAP}${line}`) // Pieces.
        
       const x = state.commits[i].x 
       const y = state.commits[i].y

    //    console.log(`${PRE_PAD}${KV_PAIR('x', x)}`)
    //    console.log(`${PRE_PAD}${KV_PAIR('y', y)}`)

        // console.log(`${PRE_PAD}${KV_PAIR('x', x)}, ${KV_PAIR('y', y)}`)
        commit_lines.push(BRACES(`${KV_PAIR('x', x)} ${KV_PAIR('y', y)}`))
    }
    console.log()
    console.log(`${PRE_PAD}${commit_lines.join(`${BIG_GAP}/${BIG_GAP}`)}`)
}

function serialiseCommitState(state: {}) {
    console.log(BRACES(`${KV_PAIR(`x`, state.x)} ${KV_PAIR('y', state.y)}`))
}

function log(payload: {}) {
    // const pyld = payload.kind.match(/^(?<kind>.+)_?(?<rest>.+)$/)
    // console.log('PYLD IS:', pyld)
    // const data_playload = payload.kind.match(/^DATA_(?<direction>IN|OUT)/)
    // console.log('DATA PAYLOAD REGEX:', data_playload)

    // const tag = narrowTag(payload.tag)
    // console.log('KIND IS', tag)

    // switch (tag.kind) {
    //     case 'DATA': {
    //         const annotation = tag.rest === 'IN'? ` ${tag.rest} <- ` : `${tag.rest} -> `
    //         console.log(annotation)

    //         break
    //     }
    //     case null: {
    //         console.error('UNRECOGNISED PAYLOAD TAG:', payload.tag)
    //     }
    // }
    
    // console.log('TAG IS', payload.tag, tag)

    // switch (tag.kind) {
    //     case 'DATA': {
    //         const tag_l2 = narrowTag(tag.rest)
    //         const annotation = tag_l2.kind === 'IN'
    //             ? DATA_DIRECTION(' ', 'IN', '<-')
    //             : DATA_DIRECTION(null, 'OUT', '->')
    //         // console.log('NEXT TAG', annotation, tag_l2)
    //         switch (tag_l2.rest) {
    //             case 'BOARD': {
    //                 serialiseBoardState(payload.data)
    //                 break
    //             }
    //             case 'COMMIT': {
    //                 serialiseCommitState(payload.data)
    //                 break
    //             }
    //         }
    //     }
    // }

    // console.log('PAYLOAD:', payload)

    let annotation = undefined
    switch (payload.tag) {
        case 'MSG': {
            console.log(payload.msg)
            break
        }
        case 'DATA_IN':
            annotation = DATA_DIRECTION(' ', 'IN', '<-')
        case 'DATA_OUT': {
            annotation ??= DATA_DIRECTION(null, 'OUT', '->')
            console.write(annotation)

            // TODO: Print move.

            if (payload.data.hasOwnProperty('cur_board')) {
                // It's a board.
                // console.log(payload.data)
                serialiseBoardState(payload.data.cur_board)
            }

            if (payload.data.hasOwnProperty('halfmove')) {
                serialiseBoardState(payload.data)
            }
            
            if (payload.data.hasOwnProperty('x')) {
                // It's a commitment.
                serialiseCommitState(payload.data)
            }

            // serialiseState(payload.data)
            // const out_tag = narrowTag(tag.rest)
            // console.log('OUT TAG IS', out_tag)
            // switch (out_tag)
            break
        }
        case null: {
            console.error('UNRECOGNISED PAYLOAD TAG:', payload.tag)
        }
    }
}