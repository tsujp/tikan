import type { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import type { Noir } from '@noir-lang/noir_js'
import type { CompiledCircuit } from '@noir-lang/types'

// TODO: This even 'needed' anymore?
type RequiredCircuits = 'player' // TODO: 'aggregate' circuit.

type EachCircuit<ValueStructure> = { [CircuitName in RequiredCircuits]: ValueStructure }

// TODO: Have this generic from T passed to `Circuits` type instead of a complete `RequiredCircuits`.
export type Circuits = EachCircuit<CompiledCircuit>

export type CircuitDefinition = { [key: string]: { path: string; circuit: string } }

export type NoirArtifactDefinitions = {
    circuits: {
        [key: string]: { path: string; circuit: string }
    }
    libraries: {
        [key: string]: { path: string }
    }
}

export type AllCircuits = {
    bin: { name: string; root: string; artifact: string }[]
    lib: { name: string; root: string }[]
}

export type ProofArtifacts = Awaited<
    ReturnType<BarretenbergBackend['generateRecursiveProofArtifacts']>
>

export type CircuitExecution = Awaited<ReturnType<Noir['execute']>>
