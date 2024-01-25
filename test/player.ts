import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { type InputValue } from '@noir-lang/noirc_abi'
import { getRandomValues } from 'crypto'
import { type Game, type Circuit, type HexInt, type Turn, hexUint64 } from './types'

// https://registry.npmjs.org/@noir-lang/noir_js/0.19.1
// https://registry.npmjs.org/@noir-lang/backend_barretenberg/-/backend_barretenberg-0.19.1.tgz

export type Player = {
    name: string
    // backend: BarretenbergBackend
    // noir: Noir
    getSalt(): HexInt
    setOpponentSalt(salt: HexInt): void
    commitTurn(turn: object): Promise<InputValue>
    // playMove(board: object, move: object, commitment?: Promise<InputValue>): void
    playTurn(board: Game, turn: Turn, commitment?: Promise<InputValue> | string): void
    // startGame(): void
}

// export type Players<Armies extends string> = { [Army in Armies]: Player }[keyof Armies]
// & { [key: string]: Player }[Armies]
export type Players = { white: Player; black: Player;[key: string]: Player }

// A simple player closure.
export async function player(
    player_name: string,
    game_circuit: Circuit,
    backend_threads: number,
    state_commitment: Noir,
): Promise<Player> {
    const name = player_name
    // [GAME] Intermediate proofs, proof artifacts.
    const game_backend = new BarretenbergBackend(game_circuit, {
        threads: backend_threads,
    })

    // [GAME] Circuit execution.
    // const game = new Noir(game_circuit, game_backend)
    const game_noir = new Noir(game_circuit)

    // [STATE COMMITMENT] Circuit execution and witness solving.
    const commit = state_commitment

    let salt: { ours: HexInt | null; theirs: HexInt | null } = {
        ours: null,
        theirs: null,
    }

    function getSalt() {
        const value = new BigUint64Array(1)
        // salt.ours = hexInt(getRandomValues(value)[0].toString(16))
        salt.ours = hexUint64(getRandomValues(value)[0])
        return salt.ours
    }

    function setOpponentSalt(s: HexInt) {
        salt.theirs = s
    }

    // TODO: Types for this from circuit.
    async function commitTurn(game: Game, turn: Turn): Promise<InputValue> {
        const turn_salt = salt.ours?.value

        if (turn_salt == null) {
            throw new Error(`salt for player '${name}' not defined`)
        }

        const { returnValue: commitment } = await state_commitment.execute({
            // TODO: Try and infer JSON structure even though it's not a string literal.
            game,
            turn,
            turn_salt,
        })

        return commitment
    }

    // TODO: Types from the circuit.
    async function playTurn(
        game: Game,
        turn: Turn,
        commitment?: Promise<InputValue> | string,
    ) {
        let turn_commitment = commitment ?? await commitTurn(game, turn)

        if (turn_commitment == null) {
            // TODO: Dump the details etc.
            throw new Error(`could not generate move commitment for ${name}`)
        }

        console.log(`${name}'s move commitment: ${turn_commitment}`)

        // ------------------ Get witness and new board with our move applied.
        process.stdout.write(`executing ${name}'s move (witness, new board-state)... `)
        const { witness, returnValue: new_board } = await game_noir.execute({
            game,
            turn,
            turn_salt: salt.ours?.value,
            turn_commitment,
        })
        console.log('done')

        process.stdout.write(`generating ${name}'s move proof... `)
        const proof = await game_backend.generateFinalProof(witness)
        // const proof = await game.generateFinalProof({
        //    board: board,
        //    move,
        //    move_salt: salt.ours?.value,
        //    move_commitment,
        // })
        console.log('done')

        return proof
    }

    async function acceptTurn(enemy_turn_data: object) {
        // console.log(enemy_turn_data)
        const valid_move = await game_backend.verifyFinalProof(enemy_turn_data)

        return valid_move
    }

    return {
        name,
        // backend,
        // noir,
        getSalt,
        setOpponentSalt,
        commitTurn,
        playTurn,
        acceptTurn,
    }
}

export function exchangeSalts(players: Players) {
    const whiteSalt = players.white.getSalt()
    const blackSalt = players.black.getSalt()

    console.log('white salt', whiteSalt.value)
    console.log('black salt', blackSalt.value)

    players.white.setOpponentSalt(blackSalt)
    players.black.setOpponentSalt(whiteSalt)
}
