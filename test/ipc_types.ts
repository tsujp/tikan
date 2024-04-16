import { CompiledCircuit } from '@noir-lang/backend_barretenberg'

export type MSG_CHILD_MEMORY = { kind: 'CHILD_MEMORY'; data: { rss: number } }

export type MSG_CHILD_READY = { kind: 'CHILD_READY'; data: null }

export type MSG_DEFINITION = {
    kind: 'PLAYER_DEFINITION'
    data: {
        name: string
        secret: bigint
        util: CompiledCircuit
        game: CompiledCircuit
        threads: number
    }
}

export type IPC_MESSAGES = MSG_DEFINITION | MSG_CHILD_READY | MSG_CHILD_MEMORY
