import type { WW_WORKER_MESSAGES, RawParentMessage, WorkerMessage } from '#test/harness/types'

// ----------------------------------------------------------------------------
// ------------------------------------ Helper

function* generateId(thread_number: number) {
    // 1000 messages should be enough for a test run... if not... more zeroes!
    let __id = thread_number * 1000

    while (true) yield __id++
}

// Create manually resoveable Promise; as a function so we can infer types
//   from a single location.
function promiseWithResolvers() {
    // XXX: Remember TypeScript automatically expands unions, so accessing the
    //      `payload` property here is accessing it on all members of the given
    //      union and returning that as a union.
    return Promise.withResolvers<WW_WORKER_MESSAGES['payload']>()
}

// ----------------------------------------------------------------------------
// ------------------------------------ Types

type Resolver = ReturnType<typeof promiseWithResolvers>['resolve']

type QueueMessage = {
    id: number
    resolver: Resolver
}

// ----------------------------------------------------------------------------
// ------------------------------------ Implementation

// XXX: Class is _NOT_ generic, intimately tied to `IPC_MESSAGES` type.
//
// This class executes in the calling JavaScript thread and orchestrates communication
//   with a `Worker` (WebWorker) executing in a _different_ thread such that we
//   can await execution of certain RPC methods we ask the `Worker` to perform.
export class AsyncWorker {
    // TODO: Type.
    #QUEUE: Array<QueueMessage> = []
    #ID: Generator<number>
    #WORKER: Worker

    constructor(...args: ConstructorParameters<typeof Worker>) {
        // `this` is the `AsyncWorker`.
        const _w = new Worker(...args)
        this.#ID = generateId(_w.threadId)

        // When `CHILD_READY` event is received the worker's message handler is
        //   changed to `#messageBroker`.
        _w.onmessage = (message: WorkerMessage) => {
            if (message.data.kind === 'WORKER_READY') {
                // `this` is STILL the `AsyncWorker` (good).
                this.#resolveMessage(message)

                // Satanic bind correction required due to how `this` works.
                // XXX: Without the following the message handler context becomes
                //      the `Worker` (bad) instead of `AsyncWorker` (good).
                _w.onmessage = this.#messageBroker.bind(this)
                return
            }

            throw new Error('Out of order message during setup (worker not ready yet!)')
        }

        this.#WORKER = _w
    }

    //
    // Convenience.
    #nextId(this: AsyncWorker) {
        const id = this.#ID.next()

        if (id.done === true) {
            throw new Error('Generator ran out of values')
        }

        return id.value
    }

    //
    // Decide what to do with messages.
    #messageBroker(message: WorkerMessage) {
        // TODO: Can we make TS require exhaustive switch checks pls?

        // XXX: LOL TypeScript cannot narrow based on a switch-case! FUCKING PATHETIC.
        switch (message.data.kind) {
            // ------ IMMEDIATE MESSAGES.
            case 'WORKER_MEMORY':
                // Megabytes.
                console.log((message.data.payload.rss / 1_048_576).toFixed(1))
                break
            // ------ QUEUED MESSAGES.
            case 'WORKER_EXEC_RESULT':
                // So we have to assert manually, my god.
                this.#resolveMessage(message)
                break
        }
    }

    //
    // Resolve the Promise associated with a message.
    #resolveMessage(message: WorkerMessage) {
        // XXX: Not possible for a `message` to be null/undefined.
        const idx = this.#QUEUE.findIndex((m) => m.id === message.data.id)

        if (idx === -1) {
            throw new Error('Could not find message id in queue', { cause: message })
        }

        if (message.data.payload === undefined) {
            throw new Error('Message payload is undefined', { cause: message })
        }

        this.#QUEUE[idx].resolver(message.data.payload)

        // this.#QUEUE.shift()
        this.#QUEUE.splice(idx, 1)
    }

    //
    // Associate a resolveable Promise with a message id.
    #registerAwaitedMessage(id: number, resolver: Resolver) {
        this.#QUEUE.push({
            id,
            resolver,
        })
    }

    //
    // Orchestrated postMessage to `Worker`.
    async postMessage(message: RawParentMessage) {
        // Increment thread-local id and create manually resolveable Promise.
        const id = this.#nextId()
        const { promise, resolve } = promiseWithResolvers()

        // Send message to worker.
        this.#WORKER.postMessage({
            id,
            origin: 'PARENT',
            ...message,
        })

        // Associate `id` with the message we just sent; the response from the
        //   `Worker` will contain the same `id` so we know it concerns our
        //   message. We can then fulfil (or reject) the promise using the
        //   resolver we provide.
        this.#registerAwaitedMessage(id, resolve)

        // Wait for message response, extract response value, and return it.
        const reply = await promise

        return reply
    }
}
