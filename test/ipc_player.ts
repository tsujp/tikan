import { Player } from '#test/good_player'
import type { IPC_MESSAGES, MSG_DEFINITION } from '#test/ipc_types'
import { Queue } from '#test/utility/basic_queue'

// TODO: Rename this file to `player_process.ts` or something.

const QUEUE = new Queue()

function toParent(kind: string, id, data?: object) {
    console.log('SENDING TO PARENT:', kind, data)
    process.send({
        kind,
        id,
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
            QUEUE.add(
                () => PLAYER[message.data.method](...message.data.args),
                (x) => {
                    console.log('callback invoked', x)
                    toParent('CHILD_EXECUTE_RESULT', message.id, x)
                },
            )
            QUEUE.process()
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
