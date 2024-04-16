import { beforeAll, afterAll } from 'bun:test'

// Do not move.
globalThis.TIKAN_TEST_SETUP = true
globalThis.MESSAGE_ID = 0

//
// * * * * * * * * * * * * * * * * * * * * * * * CONFIGURATION CONSTS
// * * * * * * * * * * * * *
const MEGABYTES = 1_048_576
const BACKEND_THREADS = 8 as const

//
// * * * * * * * * * * * * * * * * * * * * * * * HOISTS
// * * * * * * * * * * * * *

// Used for a drop dead simple message queue.
// TODO: Type.
const QUEUE = []

//
// * * * * * * * * * * * * * * * * * * * * * * * CIRCUIT COMPILATION
// * * * * * * * * * * * * *
import type { CompiledCircuit } from '@noir-lang/backend_barretenberg'
import type { IPC_MESSAGES, MSG_DEFINITION } from '#test/ipc_types'
import type { AllCircuits } from '#test/types'
import { getCircuitDefinitions, getCompiledCircuits } from '#test/utility/circuits'
import { getProjectRoot, logHeading } from '#test/utility/misc'
import { checkTestEnvironment } from '#test/utility/precheck'

// Still need to resolve the root dir in-case we change our mind later regarding
//   this bunfig.toml trick I am currently using. And because you can pass
//   more arguments to bun in a subfolder to get it to run tests anyway.
const root_dir = await getProjectRoot()
const CIRCUIT_DEFS = await getCircuitDefinitions(root_dir)
const { checks, args } = await checkTestEnvironment(root_dir, CIRCUIT_DEFS)
if (checks === false) {
    process.exit(1)
}
logHeading('Tests')

//
// * * * * * * * * * * * * * * * * * * * * * * * CIRCUIT ARTIFACTS
// * * * * * * * * * * * * *
const CIRCUITS = await getCompiledCircuits(CIRCUIT_DEFS, ['xx_player', 'xx_start', 'xx_util'])

//
// * * * * * * * * * * * * * * * * * * * * * * * PERFORMANCE MEASUREMENT
// * * * * * * * * * * * * *
import { PerformanceObserver } from 'node:perf_hooks'
import { Player } from '#test/good_player'

function perfObserver(list, observer) {
    for (const entry of list.getEntries()) {
        // if (entry.entryType === 'mark') {
        //     console.log(`${entry.name}'s at: ${entry.startTime}`)
        // }
        if (entry.entryType === 'measure') {
            console.log(`[${entry.name}]: ${entry.duration.toFixed(1)}ms`)
        }
    }

    return observer
}
const observer = new PerformanceObserver(perfObserver)
observer.observe({ entryTypes: ['mark', 'measure'] })

//
// * * * * * * * * * * * * * * * * * * * * * * * PLAYER HANDLER
// * * * * * * * * * * * * *
function printMemory(mem: number) {
    console.log((mem / MEGABYTES).toFixed(1))
}

// TODO: Type constrain it has to be specifically the player definition message.
async function spawnPlayer(initial_msg: MSG_DEFINITION) {
    const { promise, resolve } = Promise.withResolvers()

    const proc = Bun.spawn(['bun', './test/ipc_player.ts'], {
        cwd: root_dir,
        stdout: 'inherit',
        ipc(message: IPC_MESSAGES, childProc) {
            // console.log(
            //     'PARENT RECIEVED FROM',
            //     childProc.pid,
            //     'MESSAGE:',
            //     message,
            // )

            switch (message.kind) {
                // NO-QUEUE MESSAGES.
                case 'CHILD_MEMORY':
                    printMemory(message.data.rss)
                    break
                case 'CHILD_READY':
                    resolve()
                    break
                // QUEUE MESSAGES.
                case 'CHILD_EXECUTE_RESULT':
                    console.log('CHILD EXECUTE RESULT', message)

                    resolveQueue(message)

                    break
            }
        },
    })

    proc.send(initial_msg)

    await promise

    return proc
}

//
// * * * * * * * * * * * * * * * * * * * * * * * PLAYER CONFIG/INSTANTIATION
// * * * * * * * * * * * * *
const PLAYER_CIRCUITS = {
    util: CIRCUITS.xx_util,
    game: CIRCUITS.xx_player,
    threads: BACKEND_THREADS,
}

const white = spawnPlayer({
    kind: 'PLAYER_DEFINITION',
    data: {
        name: 'white',
        secret: 420n,
        ...PLAYER_CIRCUITS,
    },
})
const black = spawnPlayer({
    kind: 'PLAYER_DEFINITION',
    data: {
        name: 'black',
        secret: 69n,
        ...PLAYER_CIRCUITS,
    },
})

const players = await Promise.all([white, black])

//
// * * * * * * * * * * * * * * * * * * * * * * * MESSAGE PASSING
// * * * * * * * * * * * * *
function resolveQueue(message) {
    // Queue is resolved in-order only.
    // for (const m o}

    // Mark message as ready.
    if (message) {
        const idx = QUEUE.findIndex((m) => m.id === message.id)

        if (idx === -1) {
            console.error('SOMETHING VERY WRONG HAS HAPPENED')
        }

        QUEUE[idx].ready = true
        QUEUE[idx].cb.bind(message.data)
    }

    // Clear messages out of queue; contiguous `ready` messages only with a
    //   starting index of 0.
    let contig = false // Safe default.
    let idx = 0
    for (idx; idx < QUEUE.length; idx++) {
        contig = QUEUE[idx].ready === true
        if (contig === false) break

        QUEUE[idx].cb() // Resolve.
    }

    // Remove resolved messages.
    QUEUE.shift(idx)
}

// TODO: Can type `args` from `player` and `method`.
export async function sendAndAwait(player: number, method: string, ...args: unknown[]) {
    console.log('SEND AND AWAIT:', player, method, ...args)

    globalThis.MESSAGE_ID += 1

    // Step 1.  Send message via IPC to desired player.
    //
    // XXX: Currently specifically execution messages. Expand to others.
    players[player].send({
        kind: 'PLAYER_EXECUTE',
        data: {
            method,
            args,
        },
        id: globalThis.MESSAGE_ID,
    })

    // Step 2.  Register a callback (a simple empty promise) in the return message
    //          queue which will resolve when we receive a response with an `id`
    //          that matches the one we sent.
    const { promise, resolve } = Promise.withResolvers<IPC_MESSAGES>()

    QUEUE.push({
        id: globalThis.MESSAGE_ID,
        ready: false,
        cb: resolve,
    })

    // Wait for message response.
    const reply = await promise
    console.log('RECEIVED REPLY: reply')
    return reply
}

// TODO: Infer `TIKAN_${NAME}` by looping players.name.
globalThis.TIKAN_WHITE = players[0]
globalThis.TIKAN_BLACK = players[1]
globalThis.TIKAN_START = CIRCUITS.xx_start

afterAll(async () => {
    console.write('Cleaning up...')

    const kill_players = players.map((p) => {
        p.kill()
        return p.exited
    })

    await Promise.all(kill_players)

    console.log('done')
})
