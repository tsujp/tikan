import { BarretenbergBackend, type CompiledCircuit } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { type AsyncWorker, Player, type PlayerArgs, type PlayerMethods } from '#test/harness'
import type { Prettify } from '#test/harness/types'
import { logPerf, proxyCurry } from '#test/harness/utility'

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

const VALID_WHITE_START = 'BBDB'
const VALID_BLACK_START = 'VBXB'
const VALID_START_BOARD = 'BBDBVBXBAA'

const NOTHING_FIELD = '0x0000000000000000000000000000000000000000000000000000000000000000'

// TODO: Length of array from Noir specifically?
const NOTHING_RECURSION = {
    proof: Array(93).fill(NOTHING_FIELD),
    public: Array(26).fill(NOTHING_FIELD),
    vk: Array(114).fill(NOTHING_FIELD),
    vk_hash: NOTHING_FIELD,
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

type PlayerNames = Lowercase<PlayerArgs['name']>
type Players = {
    [K in PlayerNames]: AsyncWorker
}

type MatchArgs = Prettify<{ start: CompiledCircuit } & Players>

export class Match {
    #start_cr: CompiledCircuit
    // TODO: Put the 'WHITE' and 'BLACK' union literal for key here.
    readonly #plyr: Players

    static #internal_construction = false

    private constructor(args: Required<MatchArgs>) {
        if (Match.#internal_construction === false) {
            throw new TypeError('Execute .new() to instantiate')
        }

        this.#start_cr = args.start
        this.#plyr = {
            white: args.white,
            black: args.black,
        }
    }

    static new(args: MatchArgs) {
        Match.#internal_construction = true

        // XXX: Any further validation before instantiation goes here.

        const inst = new Match(args)
        return proxyCurry(inst, 'do', ['white', 'black'], Player)
    }

    // Start of the game is a proof from concerning all piece positions which are
    //   always (all) public initially.
    @logPerf
    async startGame({ board = VALID_START_BOARD, for_aggregation = false } = {}) {
        // TODO: Get max threads from that new Bun API in v1.1

        // This circuit is one-time only so instantiate backend etc and destroy it
        //   after we have the proof.
        // console.log('start cr', this.#start_cr)
        const start_cr = structuredClone(this.#start_cr) // So we 'own' it.
        const start_be = new BarretenbergBackend(start_cr, { threads: 2 })
        const start_nr = new Noir(start_cr, start_be)

        const start_proof = await start_nr.generateProof({
            start_serial: board,
        })

        const start_artifacts = await start_be.generateRecursiveProofArtifacts(
            start_proof,
            start_proof.publicInputs.length,
        )

        // TODO: Cleanup not working? I guess let GC throw it away for now?
        // Cleanup.
        // await start_nr.destroy()
        // await start_be.destroy()

        // TODO: When arithmetic coding public inputs will be 17 instead of 26.

        // Even though the start circuit takes no public input the main game
        //   circuit which aggregates it will expect 26 public inputs.
        //
        //   (1) 10 because `str` in Noir is actually provided as 1 public input
        //       per character and said circuit uses `str<10>`; and
        //   (2) 16 because the proof aggregation object is implicitly a public
        //       input to a `#[recursive]` circuit.

        if (for_aggregation) {
            // XXX: Required or things silently break. Behind a flag for testing.
            start_proof.publicInputs = NOTHING_RECURSION.public
        }

        return {
            proof: start_proof,
            artifacts: start_artifacts,
        }
    }

    // TODO: Make private?
    // You may call `do` yourself for more manual control, otherwise use the methods
    //   provided by the `Proxy` from class instantiation.
    async do<M extends keyof PlayerMethods>(
        player: PlayerNames,
        method: M,
        ...args: Parameters<PlayerMethods[M]>
    ) {
        const result = this.#plyr[player].postMessage({
            kind: 'WORKER_EXEC_REQUEST',
            payload: {
                method,
                args,
            },
        })

        return result
    }
}
