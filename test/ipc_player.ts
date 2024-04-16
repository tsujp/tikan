import { Player } from './good_player'
import { IPC_MESSAGES, MSG_DEFINITION } from './ipc_types'

const QUEUE = []

for (const j in QUEUE) {
    const r = await PLAYER[j.method](...j.args)
    j.cb(r)
}

function toParent(kind: string, data?: object) {
    console.log('SENDING TO PARENT:', kind, data)
    process.send({
        kind,
        ...(data && { data }),
    })
}

const { promise: block_promise, resolve: block_resolve } =
    Promise.withResolvers<MSG_DEFINITION['data']>()

process.on('message', (message: IPC_MESSAGES) => {
    switch (message.kind) {
        case 'PLAYER_DEFINITION':
            block_resolve(message.data)
            break
        case 'PLAYER_EXECUTE':
            // console.log('i am', PLAYER.name)
            console.log('RECEIVED:', message)
            QUEUE.push({
                method: message.data.method,
                args: message.data.arg_3,
                cb: toParent.bind('CHILD_EXECUTE_RESULT'),
            })

            // Immediately send back.
            process.send({
                kind: 'CHILD_EXECUTE_RESULT',
                data: 'bing bong 123 yolo',
                id: message.id,
            })
            break
    }
})

// This blocks everything below until it resolves.
const player_definition = await block_promise

const PLAYER = await Player.new(player_definition)

process.send({
    kind: 'CHILD_READY',
})

reportMemory()
setInterval(reportMemory, 5_000)

function reportMemory() {
    const x = performance.now()
    process.send({
        kind: 'CHILD_MEMORY',
        data: {
            rss: process.memoryUsage.rss(),
        },
    })
    const y = performance.now()
    console.log(y - x)
}

// await PLAYER.inst()
