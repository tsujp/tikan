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
    // state_commitment: Noir,
    start_circuit: Circuit,
    start_commitment: InputValue, // Field.
    start_salt: string,
): Promise<Player> {
    const name = player_name
    // [GAME] Intermediate proofs, proof artifacts.
    const game_backend = new BarretenbergBackend(game_circuit, {
        threads: backend_threads,
    })

    // [GAME] Circuit execution.
    // const game_noir = new Noir(game_circuit, game_backend)
    const game_noir = new Noir(game_circuit)

    // [STATE COMMITMENT] Circuit execution and witness solving.
    // const commit = state_commitment
    const commit = undefined

    let salt: { ours: HexInt | null; theirs: HexInt | null } = {
        ours: null,
        theirs: null,
    }

    // [START PROOF] Create start proof for seed of the remaining recursive proofs.
    console.log(player_name, 'start_commitment:', start_commitment)
    const start_backend = new BarretenbergBackend(start_circuit, { threads: backend_threads })
    const start_nr = new Noir(start_circuit, start_backend)
    const { witness: start_witness } = await start_nr.execute({
        player: player_name === 'white' ? 0 : 1,
        start_commitment,
        salt: start_salt,
    })
    const start_intmd_proof = await start_backend.generateIntermediateProof(start_witness)
    // These artifacts are given to the xx_player circuit.
    const what = await start_backend.generateIntermediateProofArtifacts(start_intmd_proof, start_intmd_proof.publicInputs.length)
    // console.log('for player', player_name, what) // UNCOMMENT TO SHOW START AGGREGATION OBJECT

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
        process.stdout.write(`executing ${name}'s move... `)
        const fucked_pub = start_intmd_proof.publicInputs
        fucked_pub[3] = 5
        const the_fuck = await game_noir.execute({
            verification_key: what.vkAsFields,
            proof: what.proofAsFields,
            public_inputs: fucked_pub,
            key_hash: what.vkHash,
            board,
            move,
        })
        console.log('the fuck', the_fuck)

        const da_int_proof_wit = await game_backend.generateIntermediateProof(the_fuck.witness)
        console.log('int proof witness', da_int_proof_wit)
        const da_int_proof_arti = await game_backend.generateIntermediateProofArtifacts(
            da_int_proof_wit, da_int_proof_wit.publicInputs.length
        )
        console.log('da int proof artifacts', da_int_proof_arti)
        return da_int_proof_arti


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
