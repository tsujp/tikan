import type {
    CircuitExecution,
    ExtractInstanceType,
    PickMethods,
    Prettify,
    ProofArtifacts,
} from '#test/harness/types'
import { logPerf } from '#test/harness/utility'
import {
    BarretenbergBackend,
    type CompiledCircuit,
    type ProofData,
} from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'

export type PlayerCircuits = {
    game: CompiledCircuit
    utility: CompiledCircuit
}

export type PlayerArgs = Prettify<
    {
        name: 'WHITE' | 'BLACK'
        secret: bigint
        threads?: number
    } & PlayerCircuits
>

export type PlayerMethods = Prettify<PickMethods<ExtractInstanceType<typeof Player>>>

export class Player {
    #util_nr: Noir // TODO: Commitments, etc.
    #game_nr: Noir
    #game_be: BarretenbergBackend
    #secret: string // Hex string, e.g. `0x123`.
    readonly #name: string

    static #internal_construction = false

    private constructor(args: Required<PlayerArgs>) {
        if (Player.#internal_construction === false) {
            throw new TypeError('Execute .new() to instantiate')
        }

        // TODO: Implement this in JS instead, so that another instantiation (this)
        //       isn't required.
        // Utility helpers (like creating a commitment).
        this.#util_nr = new Noir(args.utility)

        // Actual game.
        this.#game_be = new BarretenbergBackend(args.game, { threads: args.threads })
        this.#game_nr = new Noir(args.game, this.#game_be)

        this.#secret = `0x${args.secret.toString(16)}`
        this.#name = args.name
    }

    @logPerf
    static async new(args: PlayerArgs) {
        Player.#internal_construction = true

        // Other validations (later on if required) go here.

        // TODO: Stringify player secret and check length is within 254 bits which
        //       is the maximum Field size for default backend (confirm it is
        //       254 bits and not 255).

        const inst = new Player({
            ...args,
            threads: args.threads ?? 8,
        })

        await inst.#game_be.instantiate()
        return inst
    }

    get name() {
        return this.#name
    }

    @logPerf
    async getRecursiveArtifacts(proof: ProofData) {
        return this.#game_be.generateRecursiveProofArtifacts(proof, proof.publicInputs.length)
    }

    @logPerf
    async moveExecute(
        proof: ProofData,
        board_serial: string,
        move_serial: string,
        proof_artifacts?: ProofArtifacts,
    ) {
        const artifacts = proof_artifacts ?? (await this.getRecursiveArtifacts(proof))

        return this.#game_nr.execute({
            proof: artifacts.proofAsFields,
            public: proof.publicInputs,
            vk: artifacts.vkAsFields,
            vk_hash: artifacts.vkHash,
            cur_state_serial: board_serial,
            cur_move_serial: move_serial,
            secret: this.#secret,
        })
    }

    @logPerf
    async moveProve(witness: CircuitExecution['witness']) {
        return this.#game_be.generateProof(witness)
    }

    @logPerf
    async verifyProof(proof: ProofData) {
        return this.#game_nr.verifyProof(proof)
    }

    // Encompasses all aspects of playing a turn:
    //   1. Commit to move (TODO).
    //   2. Execute move (as we need to aggregate state).
    //   3. Prove move with witness from (2).
    async playTurn(
        proof: ProofData,
        board_serial: string,
        move_serial: string,
        proof_artifacts?: ProofArtifacts,
    ) {
        console.log('PLAY TURN INVOKED')
        const move_execute = await this.moveExecute(
            proof,
            board_serial,
            move_serial,
            proof_artifacts,
        )
        const move_proof = await this.moveProve(move_execute.witness)
        console.log('got move proof', move_proof)

        return {
            exc: move_execute,
            prf: move_proof,
        }
    }
}
