<script lang="ts">
    import { type Game, hexUint64, hexxy } from "../types";

    // TODO: Ability to orient the board, i.e. if black wants their pieces at
    //       the bottom instead of playing from the top. Could cheat and use a
    //       CSS transform to flip it or have a switch on `sqr_at` because
    //       the symmetry of the board means LERLEF x ^ 56 is white at the bottom
    //       whereas just x is white at the top. Specifically these two for us
    //       as we use LERLEF.

    // TODO: If I select a piece, how fast is it if I then invoke a circuit to
    //       execute for every single non-fog square to see if that destination
    //       is a valid move? This is so I can show valid moves for pieces when
    //       someone clicks them but without having to reimplement the move
    //       logic in JS. Because if/when it changes in the circuit it'll require
    //       keeping up on the frontend, and any divergence will be misleading
    //       for the end user. If the circuit can do it fast then I'd rather
    //       do it in the circuit. Maybe bitboards -> array and do that, should
    //       be fast af?

    // TODO: Next step right now is to augment the Player circuit to output some
    //       data I can start using on the frontend. Get visualisation for a
    //       basic board working. Remember you cannot see the enemies pieces unless
    //       you illuminate the square they are on. That's the key first thing.

    let game = $state({
        bbs: [
            0xf00000000000fffen, // White board
            0xffff000000000000n, // Black board
            0x4200000000000042n, // Knights
            0x2400000000000024n, // Bishops
            0x8100000000000081n, // Rooks
            0x0800000000000008n, // Queens
            0x1000000000000010n, // Kings
            0x00ff00000000ff00n, // Pawns
            0xfeffff7f0000n, // Fog
        ],
        army: 0, // Current army's turn (Board::Piece enum index)
        castle_rights: 15, // Bitmask castle rights K Q k q, 1 = yes, 0 = no
        en_passant: 0, // En-passant target square index (LERLEF 6-bits)
        halfmove: 0, // Halfmove count
        fullmove: 1, // Fullmove count
    });

    // Return whether bit at idx is set (to 1) or not.
    function check_bit(num: bigint, idx: number): boolean {
        return (num & (1n << BigInt(idx))) > 0n;
    }

    // Square mapping from i'th bitboard index to square i'th index.
    // Tikan uses LERLEF:
    //   - Files A .. H are 0 .. 7      (so a1 is 0; h7 is 7).
    //   - Ranks 1 .. 8 are 0 .. 7      (so d1 is 3; d8 is 59).
    // If changed from LERLEF (not a good idea) this function will need updating
    //   to ensure that squares are still accessed by their index correctly.
    function sqr_at(idx: number): number {
        return idx ^ 56;
    }
</script>

<h1>Fullmoves: {game.fullmove}!</h1>

<button on:click={() => game.fullmove++}>More Fullmove!</button>
<button on:click={() => game.fullmove--}>Less Fullmove!</button>

{#each { length: game.fullmove } as _, i}
    <p>I am {i}</p>
{/each}

<div id="game">
    <div id="board">
        {#each { length: 64 } as _, i}
            <div class="sqr" id="sqr-{i}">
                <span>{sqr_at(i)}</span>
                <!-- Only bother with render checks if NOT in fog, since in this FoW chess
                version nothing can be in the fog. If 2PC version in future this changes. -->
                {#if check_bit(game.bbs[8], i) === false}
                    <!-- {#if game.bbs[0] & (1n << BigInt(i))}
                    <p>Bit {i} is set</p>
                {:else}
                    <p>Bit {i} not set</p>
                {/if} -->
                {:else}
                    <span data-fog="true" />
                {/if}
            </div>
        {/each}
    </div>
</div>

<style>
    #game {
        display: flex;
        /* flex-direction: column; */
        background: green;
        padding: 5px;
    }

    #board {
        display: grid;
        padding: 1px;
        aspect-ratio: 1;
        grid-template-columns: repeat(8, 1fr);
        grid-template-rows: repeat(8, 1fr);
        outline: 2px solid #ddd;
        grid-gap: 1px;
        /* direction: rtl; */
        font-size: 1.2em;
        line-height: 1.2em;
    }

    .sqr {
        width: 20px;
        height: 20px;
        background: red;
    }

    .sqr:has(span[data-fog="true"]) {
        background: gray;
    }
</style>
