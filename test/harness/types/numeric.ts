// This is more of a guard than an actual type since we cannot recursively
//   narrow to a type that constrains any further assignment; we can only
//   _check_ at one point in time, at a time.
// export type OnlyHexInt<HI> = HI extends ''
//    ? HI
//    : HI extends `${HexDigit}${infer Rest}`
//       ? OnlyHexInt<Rest>
//       : never

// export type OnlyHexInt55<HI, Acc extends string = ''> =
//    HI extends `${infer X extends HexDigit}${infer Rest}`
//       ? OnlyHexInt55<Rest, `${Acc}${X}`>
//       : `${Acc}`

type HexDigit = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 'a' | 'b' | 'c' | 'd' | 'e' | 'f'

// XXX: Unfortuntely dprint cannot format this nicely.
//      See: https://github.com/dprint/dprint-plugin-typescript/pull/450
//      See: https://github.com/dprint/dprint-plugin-typescript/issues/432
// dprint-ignore
type OnlyHexDigits<Str, Acc extends string = ''> = Str extends `${infer D extends
    HexDigit}${infer Rest}`
    ? OnlyHexDigits<Rest, `${Acc}${D}`>
    : Acc

export type HexInt = { __tag: 'HexInt'; value: string }

// dprint-ignore
export type HexIntLiteral<
    Hex,
    // OriginalHex = Hex,
    FilteredHex = OnlyHexDigits<Hex>,
> = Hex extends FilteredHex ? Hex : never

// export function hexInt<Hex extends string> (n: Hex & HexIntLiteral<Hex>) {
// export function hexInt<Hex extends string> (n: HexIntLiteral<Hex>): HexInt {
//    // return n as HexIntLiteral<Hex>
//    return {
//       __tag: 'HexInt',
//       value: n,
//    }
// }

export function hexUint64(n: bigint): HexInt {
    return {
        __tag: 'HexInt',
        value: `0x${n.toString(16)}`,
    }
}
