import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { TransactionDescription } from 'ethers/lib/utils'

//
// * * * * * * * * * * * * * * * * * * * * * * * BOILERPLATE
// * * * * * * * * * * * * *

// for await (const chunk of Bun.stdin.stream()) {
//     // chunk is Uint8Array
//     // this converts it to text (assumes ASCII encoding)
//     const chunkText = Buffer.from(chunk).toString();
//     console.log(`Chunk: ${chunkText}`);
// }

console.log('args are!!!', Bun.argv)

const BACKEND_THREADS = 8 as const
const wd = process.cwd()
