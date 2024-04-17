// TODO: When building does bun polyfill this so it can be used elsewhere? In the browser or by masochists who like using Node.js raw?
// import { peek } from 'bun'

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// TODO: Is this _guaranteed_ monotonic?
// TODO: Obvious integer limitations, if a generator approach can be monotonic
//       add some stuff and a cheap hash to (reasonably) guarantee a unique ID
//       or implement some cheap/fast UUID/GUID protocol.
function* generateId() {
    let __id = 420

    while (true) yield __id++
}

const id = generateId()

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

type TODO = any

type JobTask = TODO
type JobCb = TODO

type Job = {
    id: number
    invoked: boolean
    // TODO: Type function which takes no args, or at most a single signal arg, and returns a promise.
    task: JobTask
    // TODO: Type tuple of callbacks, one for success, one for error. Error one is optional in which case
    //       a default error will be throw.
    cb: JobCb
}

type NaturalNumber<N extends number> = `-${N}0` extends `${bigint}` ? N : never
// type NaturalNumber<N extends number> = `${bigint}` & `-${N}0` extends never ? never : N;

export class Queue {
    // TODO: Think about iteration and adding/removing jobs while that's going on. How much protection is warranted there and
    //       what's the best datastructure to deal with it. WeakMap, WeakSet, Map, Set, something else custom etc?
    #queue: Array<Job>
    #lock: boolean

    constructor() {
        // Nothing for now.
        this.#queue = []
        this.#lock = false
    }

    size() {
        return this.#queue.length
    }

    add(task: JobTask, cb: JobCb) {
        this.#queue.push({
            id: id.next().value,
            invoked: false,
            task,
            cb,
        })
    }

    async process<N extends number>(count?: NaturalNumber<N>) {
        if (this.#lock === true) {
            return
        }

        let iterations = count ? structuredClone(count) : 1
        iterations = Math.min(this.size(), iterations)

        // XXX: If/when concurrency `this.#lock` steps up/down with concurrent jobs.
        this.#lock = true

        while (iterations) {
            console.log('iterations', iterations)
            const job = this.#queue[0]

            // XXX: There's no concurrency under this implementation so ignore `job.invoked` for now.
            // let task
            // if (job.invoked === false) {
            //   job.invoked = true
            //   task = job.task()
            // }
            // const foo = await task
            // console.log('TASK IS DONE!!!!!!!!!!', foo)
            // End above.

            const task = job.task()
            const result = await task

            console.log('RESULT', result)

            job.cb(result)

            iterations--
            this.#queue.shift()
        }

        this.#lock = false
    }

    async processAll() {
        await this.process(this.size())
    }

    // *[Symbol.iterator]() {
    //   yield 'a';
    //   yield 'b';
    //   yield 'c';
    // }
}
