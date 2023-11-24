import { BroadcastChannel } from 'worker_threads'
// import { watch } from "fs"
// import { randomUUID } from "crypto"

const GAMESTATE_CHANNEL = 'send_gamestate' as const
const channel = new BroadcastChannel(GAMESTATE_CHANNEL)

// Quick and dirty new data protocol; as Saul Goodman says "[...] just the right
//   amount of dirty".
// OR instead of doing that just POST to us since we're running a server anyway.
// const fsEvents = watch(import.meta.dir, (event, filename) => {
//   console.log(`fs -> ${event} in ${filename}`);
//   channel.postMessage({ foo: 'bar' })
// });

function gsStream (signal: AbortSignal) {
    return new ReadableStream({
        type: 'direct',
        async pull (controller) {
            console.log('/sse -> new client connection')
            if (signal.aborted) {
                console.log('client immediately aborted connection')
                controller.close()
            }

            const bus = new BroadcastChannel(GAMESTATE_CHANNEL)

            bus.onmessage = (ev) => {
                const payload = JSON.stringify(ev.data)
                console.log('new event message to push', payload)
                controller.write(`data:${payload}\n\n`)
                controller.flush()
            }

            // TODO: Is `close` also a possible event?
            signal.addEventListener('abort', () => {
                console.log('client closed connection')
                bus.close()
                controller.close()
            })

            // Never resolves, .'. holds connection open for SSE events.
            return new Promise(() => {})
        },
        async cancel () {
            console.log('closed?')
        },
    })
}

async function ingest (req: Request): Promise<Response> {
    // Galaxy brained decoding (do not copy this).
    const formData = await req.formData()
    const id = formData.get('run_id')?.toString().split(' ')
    const tag = formData.get('tag')?.toString().split(' ')
    const bbs = formData.get('bbs')?.toString().split(' ')

    if (id == null || tag == null || bbs == null) {
        // So it can be seen from the test view
        console.log('Received garbage:', formData)
        return new Response('!!!!!!! BAD DATA !!!!!!!!', { status: 400 })
    }

    // console.log(bbs)
    channel.postMessage({ run_id: id[0], tag: tag[0], bbs })

    return new Response(undefined, { status: 200 })
}

function sse (req: Request): Response {
    return new Response(gsStream(req.signal), {
        status: 200,
        headers: { 'content-type': 'text/event-stream', Connection: 'keep-alive' },
    })
}

const server = Bun.serve({
    port: 3069,
    fetch (req) {
        const url = new URL(req.url)
        if (url.pathname === '/') {
            return new Response(Bun.file('index.html'))
        }
        if (url.pathname === '/sse') {
            return sse(req)
        }
        if (url.pathname === '/data') {
            return ingest(req)
        }
        return new Response('Big problems')
    },
})

console.log(`Server listening at http://${server.hostname}:${server.port}`)

process.on('SIGINT', () => {
    console.log('Cleaning up...')
    // fsEvents.close();
    server.stop()
    channel.close()
    process.exit(0)
})
