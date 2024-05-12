// TODO: Argument parsing and/or passing?
import { Circuits, Players, log } from '#test/harness'

const circuits = await Circuits(['xx_player', 'xx_start', 'xx_util'])

const players = await Players({
    circuits: {
        utility: circuits.xx_util,
        game: circuits.xx_player,
    },
    threads: 8,
    player: new URL('./worker.ts', import.meta.url).href,
    // White, black.
    secrets: [420n, 69n],
})

log.heading('Test logs')

// Not the best but with global namespace type declarations this is fine.
globalThis.TIKAN_WHITE = players[0]
globalThis.TIKAN_BLACK = players[1]
globalThis.TIKAN_START = circuits.xx_start
