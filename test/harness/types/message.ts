import type { PlayerArgs, PlayerMethods } from '#test/harness'
import type { Prettify } from '#test/harness/types'

type __MessageBase = {
    kind: string
    payload: object | null | boolean
}

type FromParent = {
    origin: 'PARENT'
}

type FromWorker = {
    origin: 'WORKER'
}

type MSG<
    O extends FromParent | FromWorker,
    M extends __MessageBase,
    T extends 'IMMEDIATE' | 'QUEUED' = 'QUEUED',
> = Prettify<M & O & (T extends 'QUEUED' ? { id: number } : { id: null })>

// ----------------------------------------------------------------------------
// ------------------------------------ PARENT to WORKER

export type MSG_PLAYER_DEFINITION = MSG<
    FromParent,
    {
        kind: 'PLAYER_DEFINITION'
        payload: PlayerArgs
    }
>

type MSG_WORKER_EXECUTE_REQUEST<M extends keyof PlayerMethods = keyof PlayerMethods> = MSG<
    FromParent,
    {
        kind: 'WORKER_EXEC_REQUEST'
        payload: {
            method: M
            args: Parameters<PlayerMethods[M]>
        }
    }
>

// ----------------------------------------------------------------------------
// ------------------------------------ WORKER to PARENT

export type MSG_WORKER_MEMORY = MSG<
    FromWorker,
    { kind: 'WORKER_MEMORY'; payload: { rss: number } },
    'IMMEDIATE'
>

export type MSG_WORKER_READY = MSG<FromWorker, { kind: 'WORKER_READY'; payload: null }>

type MSG_WORKER_EXECUTE_RESULT = MSG<
    FromWorker,
    {
        kind: 'WORKER_EXEC_RESULT'
        payload: {
            [K in keyof PlayerMethods]: Awaited<ReturnType<PlayerMethods[K]>>
        }[keyof PlayerMethods]
    }
>

// ----------------------------------------------------------------------------
// ------------------------------------ Unions and export

type ALL_MESSAGES =
    | MSG_PLAYER_DEFINITION
    | MSG_WORKER_READY
    | MSG_WORKER_MEMORY
    | MSG_WORKER_EXECUTE_REQUEST
    | MSG_WORKER_EXECUTE_RESULT

type PARENT_MESSAGES = Extract<WW_MESSAGES, FromParent>
type WORKER_MESSAGES = Extract<WW_MESSAGES, FromWorker>

type WithoutKeys<T, K extends string> = T extends object ? Omit<T, K> : never

export type RawParentMessage = Prettify<WithoutKeys<WW_PARENT_MESSAGES, 'id' | 'origin'>>
export type ParentMessage = MessageEvent<WW_PARENT_MESSAGES>

export type RawWorkerMessage = Prettify<WithoutKeys<WW_WORKER_MESSAGES, 'origin'>>
export type WorkerMessage = MessageEvent<WW_WORKER_MESSAGES>
// export type QueuedWorkerMessage = MessageEvent<Extract<IPC_WORKER_MESSAGES, { id: number }>>

export type WW_MESSAGES = ALL_MESSAGES
export type WW_PARENT_MESSAGES = PARENT_MESSAGES
export type WW_WORKER_MESSAGES = WORKER_MESSAGES
