// XXX:
// ------- Hacky experiment, probably move elsewhere later.
// XXX:

// ---------------------------------------------------------------------------
// ---------------------------------------------- NOTES

// We don't care about concatenated messages thus we will only binary-search
//   until the first binary interval-encoding (TODO: get proper name for that)
//   is found.

// ---------------------------------------------------------------------------
// ---------------------------------------------- ENCODING CONFIG
import BigNumber from 'bignumber.js'
const BN = BigNumber.clone({ DECIMAL_PLACES: 16 })

const BNArray = (arr: number[]) => arr.map((n) => BN(n))

// Symbols we want to encode.
const ALPHABET = BNArray([0, 1, 2])
// const ALPHABET = BNArray([0, 1, 2, 3])

// Probability of each character in `ALPHABET` appearing in a message.
// const PROBABILITY = BNArray([0.2, 0.4, 0.4])
const PROBABILITY = BNArray([0.33, 0.33, 0.33])
// const PROBABILITY = BNArray([0.05, 0.05, 0.5, 0.4])

// A message we want to encode.
// const MESSAGE = BNArray([2, 1, 0])
const MESSAGE = BNArray([2, 1, 0, 0, 0, 1, 1, 2])
// const MESSAGE = BNArray([2, 3, 2, 0])

// ---------------------------------------------------------------------------
// ---------------------------------------------- IMPLEMENTATION

// TODO: This implementation assumes infinite precision, that's not the case
//       practically (except for very small alphabets AND messages), later on
//       implement the precision corrections.

// Need to compute cumulative probability weights so we can calculate the
//   interval bounds without having to brute-force search.
const CUMULATIVE = PROBABILITY.reduce((acc, _, i, arr) => {
    return (i === 0 ? acc[i] = BN(0) : acc[i] = acc[i - 1].plus(arr[i - 1]), acc)
}, new Array<BigNumber>(PROBABILITY.length))

// Sanity.
console.log(`
         Alphabet: ${ALPHABET.join(', ')}
    Probabilities: ${PROBABILITY.join(', ')}
       Cumulative: ${CUMULATIVE.join(', ')}

          Message: ${MESSAGE.join(', ')}
`)

// Half-open interval [a, b) value `a` that corresponds to MESSAGE can be
//   calculated by incrementally summing each character's proportional probability.
let incremental
const [a, b_pre] = MESSAGE.reduce((acc, cur, i, arr) => {
    incremental = BN(1)
    for (let j = 0; j < i; j++) {
        incremental = incremental.times(PROBABILITY[arr[j]])
    }

    return [acc[0].plus(incremental.times(CUMULATIVE[cur])), acc[1].times(PROBABILITY[cur])]
}, [BN(0), BN(1)])

// `b` is `a` plus the product of probabilities of each character in MESSAGE.
const b = a.plus(b_pre)

console.log(`Interval: [${a}, ${b})`)

// Now to find binary exponentiation within that interval.
// XXX: Just convert the interval base `a` to binary?
// console.log(a.toString(2))
// console.log(b.toString(2))
// console.log(BN(0.6875).toString(2))
// console.log(BN(0.68).toString(2))

// 0 <= a < b < 1
function bruteForceCoding (a: BigNumber, b: BigNumber) {
    let result = BN(1)
    let denom = BN(1)

    // Limit of how many binary exponentiation adjustments we make before giving up.
    const limit = 64
    for (let i = 0; i < limit; i++) {
        // Increase denominator (thus increasing precision of adjustments made).
        denom = denom.div(2)

        if (result.lt(a)) {
            // Less than `a`, needs to be greater than or equal to; so add some.
            result = result.plus(denom)
        } else if (result.gte(b)) {
            // Greater than or equal to `b`, needs to be less than; so remove some.
            result = result.minus(denom)
        } else {
            // Neither case so we must be good!
            return result
        }
    }

    throw new Error('Could not determine shortest binary value in interval')
}

const encoded_rational = bruteForceCoding(a, b)
console.log(encoded_rational, encoded_rational.toString(2))

console.log(a.toString(2))
console.log(b.toString(2))

// console.log('shortest', bruteForceCoding(BN(0.68), BN(0.712)))
// console.log(
//     'shortest',
//     bruteForceCoding(BN(0.42), BN(0.425)),
//     bruteForceCoding(BN(0.42), BN(0.425)).toString(2),
// )

// function shortest (a, b) {
//     let res = 1
//     let bit = 1

//     while (bit) {
//         bit /= 2

//         if (res <= a) {
//             res += bit
//         } else if (res >= b) {
//             res -= bit
//         } else {
//             return res
//         }
//     }
// }

// console.log('shortest', shortest(0.68, 0.712))
// console.log('shortest', shortest(0.42, 0.425), shortest(0.42, 0.425).toString(2))
