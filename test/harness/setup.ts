import {
    AsyncWorker,
    assertEnvironment,
    type PlayerArgs,
    type PlayerCircuits,
} from '#test/harness'
import type { Prettify } from '#test/harness/types'
import {
    resolveAvailableCircuits,
    getCompiledCircuits,
    getProjectRoot,
    spinner,
} from '#test/harness/utility'

// For clarity by naming the type explicitly.
type PlayerWorkerHref = string

type PlayerSecret = PlayerArgs['secret']

// Maybe overengineered but hey at least we get errors if we change PlayerArgs now!
type PlayerSetup = Prettify<
    // Without properties of type `CompiledCircuit`, and properties keyed `secret` or `name`.
    Omit<PlayerArgs, 'secret' | 'name' | keyof PlayerCircuits> & {
        // Add back secrets as a tagged tuple.
        secrets: [WHITE: PlayerSecret, BLACK: PlayerSecret]
    } & {
        // Add back `CompiledCircuit`s under key `circuits`.
        circuits: PlayerCircuits
    }
>

type SetupBase = {
    player: PlayerWorkerHref
}

type SetupConfig = Prettify<PlayerSetup & SetupBase>

async function setupCircuits(circuits: Array<string>) {
    const root_dir = await getProjectRoot()

    const available_circuits = await resolveAvailableCircuits(root_dir)

    await assertEnvironment(root_dir, available_circuits)

    // TODO: Can infer type from this regarding the given circuits. Just their names that is.
    const found_circuits = await getCompiledCircuits(available_circuits, circuits)

    return found_circuits
}

async function setupPlayers(config: SetupConfig) {
    const workerUrl = config.player

    const spinterval = spinner('init players')

    const __players = config.secrets.map(async (secret, i) => {
        const worker = new AsyncWorker(workerUrl)

        await worker.postMessage({
            kind: 'PLAYER_DEFINITION',
            payload: {
                name: i === 0 ? 'WHITE' : 'BLACK',
                threads: config.threads,
                secret,
                ...config.circuits,
            },
        })

        return worker
    })

    const all_players = Promise.all(__players)
    await all_players

    spinterval('loaded')

    return all_players
}

export const Circuits = setupCircuits
export const Players = setupPlayers
