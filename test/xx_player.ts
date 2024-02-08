import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { type InputValue } from '@noir-lang/noirc_abi'
import { getRandomValues } from 'crypto'
import { type Game, type Circuit, type HexInt, type Turn, hexUint64 } from './types'

export type Player = {
    name: string
    getSalt(): HexInt
    setOpponentSalt(salt: HexInt): void
    commitTurn(turn: object): Promise<InputValue>
    playMove(board: any, move: any, commitment?: Promise<InputValue> | string): void
}

export type Players = { white: Player; black: Player;[key: string]: Player }

// A simple player closure.
export async function player(
    player_name: string,
    game_circuit: Circuit,
    backend_threads: number,
    commitment: Noir,
): Promise<Player> {
    const name = player_name
    // [GAME] Intermediate proofs, proof artifacts.
    const game_backend = new BarretenbergBackend(game_circuit, {
        threads: backend_threads,
    })

    // [GAME] Circuit execution.
    const game_noir = new Noir(game_circuit, game_backend)
    // const game_noir = new Noir(game_circuit)

    // [STATE COMMITMENT] Circuit execution and witness solving.
    const commit = commitment

    let salt: { ours: HexInt | null; theirs: HexInt | null } = {
        ours: null,
        theirs: null,
    }

    // [START PROOF] Create start proof for seed of the remaining recursive proofs.
    // console.log(player_name, 'start_commitment:', start_commitment)

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

        const { returnValue: commitment } = await commit.execute({
            // TODO: Try and infer JSON structure even though it's not a string literal.
            game,
            turn,
            turn_salt,
        })

        return commitment
    }

    // TODO: Types from the circuit.
    async function playMove(
        board: any,
        move: any,
        commitment?: Promise<InputValue> | string,
    ) {
        // let turn_commitment = commitment ?? await commitTurn(game, turn)

        // if (turn_commitment == null) {
        //     // TODO: Dump the details etc.
        //     throw new Error(`could not generate move commitment for ${name}`)
        // }

        // console.log(`${name}'s move commitment: ${turn_commitment}`)

        // ------------------ Get witness and new board with our move applied.
        process.stdout.write(`[${player_name}] executing game circuit with move... `)

        const { returnValue: rv_commit } = await commit.execute({
            input: {
                state: {
                    _is_some: true,
                    _value: {
                        board,
                        move,
                    }
                }
            }
        }, (name, inputs) => new Promise((resolve, reject) => {
            switch (name) {
                case 'assert_message': {
                    const payload = JSON.parse(String.fromCharCode(...inputs[1]))
                    switch (payload.kind) {
                        case 'string': {
                            const msg = String.fromCharCode(...inputs[0])
                            console.error('ASSERT FAIL:', msg)
                            resolve([]) // No return value for assertion messages (they stdout to us).
                        }
                    }
                }
                case 'print': {
                    // console.log('inputs', inputs)
                    // console.log('inputs', String.fromCharCode(...inputs[1]))
                    const payload = JSON.parse(String.fromCharCode(...inputs[2]))
                    switch (payload.kind) {
                        case 'array': {
                            if (inputs[1].length !== payload.length) {
                                console.error('MISMATCH PAYLOAD LENGTH')
                            }
                            switch (payload.type.kind) {
                                case 'field': {
                                    console.log(inputs[1])
                                    resolve([]) // No return value for assertion messages (they stdout to us).
                                }
                            }
                        }
                    }
                }
            }

            reject('NAH MATE I CANNAE DO IT')
        }))

        console.log('commitment:', rv_commit.state_commitment._value)

        const data = await game_noir.generateFinalProof({
            board,
            move,
            state_commitment: rv_commit.state_commitment._value
        })
        console.log('done')
        console.log('data:', data)


        // const verified = await bootstrap_backend.verifyIntermediateProof({
        //     proof,
        //     publicInputs,
        // })
        // expect(verified).toBeTrue()

        // process.stdout.write(`generating ${name}'s move proof... `)
        // const proof = await game_backend.generateFinalProof(witness)
        // const proof = await game.generateFinalProof({
        //    board: board,
        //    move,
        //    move_salt: salt.ours?.value,
        //    move_commitment,
        // })
        // console.log('done')

        // return proof
        return
    }

    async function acceptTurn(enemy_turn_data: object) {
        // console.log(enemy_turn_data)
        const valid_move = await game_backend.verifyFinalProof(enemy_turn_data)

        return valid_move
    }


    async function protoAttemptOne(
        game: Game,
        turn: Turn
    ) {
        // COMMITMENT
        // Playing a turn involves comitting your move against the public board state, do that
        //   first.
        const turn_salt = salt.ours?.value
        if (turn_salt == null) {
            throw new Error(`salt for player '${name}' not defined`)
        }
        console.log('[commit] salt:', turn_salt)
        // console.log('[commit] commit to:', game, turn, turn_salt)
        const fake_turn = structuredClone(turn)
        fake_turn.bbs[0] = '0x42'
        const { returnValue: turn_commitment } = await state_commitment.execute({
            game,
            // turn,
            turn: fake_turn,
            turn_salt,
        })
        console.log('[commit] commitment:', turn_commitment)


        // EXECUTION / GAME
        process.stdout.write(`[game] executing move... `)
        const { witness, returnValue: new_board } = await game_noir.execute({
            game,
            turn,
            turn_salt,
            turn_commitment,
        }, (name, inputs) => new Promise((resolve, reject) => {
            switch (name) {
                case 'assert_message': {
                    const payload = JSON.parse(String.fromCharCode(...inputs[1]))
                    switch (payload.kind) {
                        case 'string': {
                            const msg = String.fromCharCode(...inputs[0])
                            console.error('ASSERT FAIL:', msg)
                            resolve([]) // No return value for assertion messages (they stdout to us).
                        }
                    }
                }
            }

            reject('NAH MATE I CANNAE DO IT')
        }))
        console.log('done')
        console.log('[game] new public state:', new_board)

        return

        // TEMP: Just have the circuit execute for now, while we figure out the protocol then
        //       try it with proofs too.
        // console.log('CIRCUIT EXECUTE', new_board)
        // return
    }

    return {
        name,
        // backend,
        // noir,
        getSalt,
        setOpponentSalt,
        commitTurn,
        playMove,
        acceptTurn,
        protoAttemptOne
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
