// biome-ignore lint/style/noVar: This is a TypeScript declaration, not a JavaScript one.
declare var self: Worker

import { Player } from '#test/harness'
import type {
    MSG_PLAYER_DEFINITION,
    ParentMessage,
    RawWorkerMessage,
} from '#test/harness/types'

const { promise: block_promise, resolve: block_resolve } =
    Promise.withResolvers<MSG_PLAYER_DEFINITION>()

function reportMemory() {
    const x = performance.now()
    toParent({
        id: null,
        kind: 'WORKER_MEMORY',
        payload: {
            rss: process.memoryUsage.rss(),
        },
    })
    const y = performance.now()
    console.log(y - x)
}

function toParent(message: RawWorkerMessage) {
    postMessage({
        origin: 'WORKER',
        ...message,
    })
}

let PLAYER: Player
block_promise.then(async (message) => {
    PLAYER = await Player.new(message.payload)
    toParent({
        id: message.id,
        kind: 'WORKER_READY',
        payload: null,
    })
    // setInterval(reportMemory, 5_000)
})

function messageHandler(message: ParentMessage) {
    switch (message.data.kind) {
        case 'PLAYER_DEFINITION':
            block_resolve(message.data)
            break
        case 'WORKER_EXEC_REQUEST':
            // TODO: A way to ignore only error 2556?
            // @ts-ignore TS2556
            PLAYER[message.data.payload.method](...message.data.payload.args).then((res) => {
                // TODO: Read an env var, if FULL_DEBUG or something then and only then print this?
                // console.log('callback invoked', res)

                toParent({
                    id: message.data.id,
                    kind: 'WORKER_EXEC_RESULT',
                    payload: res,
                })
            })
            break
    }
}

self.onmessage = messageHandler
