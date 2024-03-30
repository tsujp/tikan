import { BarretenbergBackend, ProofData } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { type InputValue } from '@noir-lang/noirc_abi'
import { getRandomValues } from 'crypto'
import { type Circuit, type Game, type HexInt, type Turn, hexUint64 } from './types'

export type Player = {
    name: string
    getSalt(): HexInt
    setOpponentSalt(salt: HexInt): void
    commitTurn(turn: object): Promise<InputValue>
    executeMove(
        board: any,
        move: any,
        commitment?: Promise<InputValue> | string,
    ): Promise<ProofData>
    playMove(
        board: any,
        move: any,
        commitment?: Promise<InputValue> | string,
    ): Promise<ProofData>
}

export type Players = { white: Player; black: Player; [key: string]: Player }

// A simple player closure.
export async function player (
    player_name: string,
    game_circuit: Circuit,
    aggregate_circuit: Circuit,
    backend_threads: number,
    commitment: Noir,
) {
    const name = player_name
    // [GAME] Intermediate proofs, proof artifacts.
    const game_backend = new BarretenbergBackend(game_circuit, {
        threads: backend_threads,
    })

    // [GAME] Circuit execution.
    const game_noir = new Noir(game_circuit, game_backend)
    // const game_noir = new Noir(game_circuit)

    // FOO: .
    const aggregate_backend = new BarretenbergBackend(aggregate_circuit, {
        threads: backend_threads,
    })
    const aggregate_noir = new Noir(aggregate_circuit, aggregate_backend)
    // ---/

    // [STATE COMMITMENT] Circuit execution and witness solving.
    const commit = commitment

    let salt: { ours: HexInt | null; theirs: HexInt | null } = {
        ours: null,
        theirs: null,
    }

    // [START PROOF] Create start proof for seed of the remaining recursive proofs.
    // console.log(player_name, 'start_commitment:', start_commitment)

    function getSalt () {
        const value = new BigUint64Array(1)
        // salt.ours = hexInt(getRandomValues(value)[0].toString(16))
        salt.ours = hexUint64(getRandomValues(value)[0])
        return salt.ours
    }

    function setOpponentSalt (s: HexInt) {
        salt.theirs = s
    }

    // TODO: Types for this from circuit.
    async function commitTurn (game: Game, turn: Turn): Promise<InputValue> {
        const turn_salt = salt.ours?.value

        if (turn_salt == null) {
            throw new Error(`salt for player '${name}' not defined`)
        }

        const { returnValue: commitment } = await commit.execute({
            // TODO: Try and infer JSON structure even though it's not a string literal.
            game,
            turn,
            turn_salt,
        })

        return commitment
    }

    // TODO: Types from the circuit.
    async function executeMove (
        board: any,
        move: any,
        // So we can purposefully pass a garbage commitment to test that it SHOULD fail.
        commitment?: Promise<InputValue> | string,
    ) {
        // process.send({ tag: 'MSG', msg: `${player_name} commits to move...`, data: null })

        // const { returnValue: rv_commit } = await commit.execute({
        const move_commit = await commit.execute({
            // TODO: Make these functions to abstract away Noir's `Option`.
            input: {
                state: {
                    _is_some: true,
                    _value: {
                        cur_board: board,
                        move,
                    },
                },
            },
        })

        const game_execd = await game_noir.execute({
            cur_board: board,
            // TODO: Same for getting value return from a circuit execution that involves Noir `Option`.
            pst_board: move_commit.returnValue.state_commitment._value[1], // XXX: Why is it 1 when tuple is at 0?
            move: move,
            state_commitment: move_commit.returnValue.state_commitment._value[0],
        })

        return game_execd
    }

    // TODO: Types.
    async function proveMove (witness: any) {
        const proof = await game_backend.generateProof(witness)
        return proof
    }

    async function proofStuff (board: any, move: any) {
        const pst_exec = await commit.execute({
            input: {
                state: {
                    _is_some: true,
                    _value: {
                        cur_board: board,
                        move,
                    },
                },
            },
        })

        console.log(pst_exec.returnValue.state_commitment._value)

        const blah = await game_noir.generateProof({
            cur_board: board,
            pst_board: pst_exec.returnValue.state_commitment._value[1],
            move: move,
            state_commitment: pst_exec.returnValue.state_commitment._value[0],
            // public: ,
            // proof: ,
            // vk: ,
            // vk_hash: ,
        })

        return blah
    }

    async function aggregateProof (proof: ProofData) {
        // Do not trust artifacts sent by other player, generate them ourselves.
        const artifacts = await game_backend.generateRecursiveProofArtifacts(
            proof,
            proof.publicInputs.length,
        )

        // Attempt to aggregate their proof to the game state.
        const aggregate_proof = await aggregate_noir.generateProof({
            public: proof.publicInputs,
            proof: artifacts.proofAsFields,
            vk: artifacts.vkAsFields,
            vk_hash: artifacts.vkHash,
        })

        return aggregate_proof

        // console.log('aggregate proof:', aggregate_proof)

        // const verify_aggregate = await aggregate_noir.verifyProof(aggregate_proof)
        // console.log('verified?', verify_aggregate)
    }

    async function verifyAggregateProof (aggregate_proof: ProofData) {
        const is_valid = await aggregate_noir.verifyProof(aggregate_proof)
        return is_valid
    }

    return {
        name,
        // backend,
        // noir,
        getSalt,
        setOpponentSalt,
        commitTurn,
        executeMove,
        proveMove,
        aggregateProof,
        verifyAggregateProof,
        proofStuff,
    }
}

export function exchangeSalts (players: Players) {
    const whiteSalt = players.white.getSalt()
    const blackSalt = players.black.getSalt()

    console.log('white salt', whiteSalt.value)
    console.log('black salt', blackSalt.value)

    players.white.setOpponentSalt(blackSalt)
    players.black.setOpponentSalt(whiteSalt)
}
