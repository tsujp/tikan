type HexDigit =
    | '0'
    | '1'
    | '2'
    | '3'
    | '4'
    | '5'
    | '6'
    | '7'
    | '8'
    | '9'
    | 'a'
    | 'b'
    | 'c'
    | 'd'
    | 'e'
    | 'f'

// XXX: Unfortuntely dprint cannot format this nicely.
//      See: https://github.com/dprint/dprint-plugin-typescript/pull/450
//      See: https://github.com/dprint/dprint-plugin-typescript/issues/432
// dprint-ignore
type OnlyHexDigits<Str, Acc extends string = ''> =
    Str extends `${infer D extends HexDigit}${infer Rest}`
    ? OnlyHexDigits<Rest, `${Acc}${D}`>
    : Acc

export type HexInt = { __tag: 'HexInt'; value: string }

// dprint-ignore
export type HexIntLiteral<
    Hex,
    // OriginalHex = Hex,
    FilteredHex = OnlyHexDigits<Hex>
> =
    Hex extends FilteredHex
    ? Hex
    : never

export function hexxy<T extends string, X = HexIntLiteral<T>>(n: X): HexInt {
    return hexUint64123(n)
}

const foo = hexxy("ff00")

export function hexUint64123(n: string): HexInt {
    return {
        __tag: 'HexInt',
        value: `0x${n}`,
    }
}

export function hexUint64(n: bigint): HexInt {
    return {
        __tag: 'HexInt',
        value: `0x${n.toString(16)}`,
    }
}


// HEX-ARRAY-ABLE

const blah: InputBbs = [
    '0x000000000000ffff',
    '0xffff000000000000',
    '0x4200000000000042',
    '0x2400000000000024',
    '0x8100000000000081',
    '0x0800000000000008',
    '0x1000000000000010',
    '0x00ff00000000ff00bad',
    '0x00',
]

type TupleOf<T, N extends number> = N extends N ? number extends N ? T[] : _TupleOf<T, N, []> : never;
type _TupleOf<T, N extends number, R extends unknown[]> = R['length'] extends N ? R : _TupleOf<T, N, [T, ...R]>;

type IdxOf<T extends any[]> = Exclude<keyof T, keyof any[]>
type OrUndef<T extends any[]> = { [K in IdxOf<T>]: T[K] | undefined }
type ThingOne = OrUndef<TupleOf<string, 9>>

type InputBbs = ThingOne


// type Wat<Digit, Acc extends string = ''> =
//     Digit extends `${infer D extends HexDigit}${infer Rest}`
//     ? OnlyHexDigits<Rest, `${Acc}${D}`>
//     : Acc

// type Wat<Idk> = { [Y in keyof Idk as `foo${string & Y}`]: Y }
// type Wat<Idk extends bigint> = `${Idk}`

// Given how incredibly large a 64-bit unsigned integer is and this _proposal_ for TypeScript being
//   just that... a proposal (https://github.com/microsoft/TypeScript/issues/43505) we'll check
//   the pattern as a string.

// type HasPrefix<Pfx extends string, Str extends string> =
//     Str extends `${Pfx}${string}` ? true : false

type IsLength<Len extends number, Str extends string> =
    Length<Str> extends Len ? Str : never

type Unionise<Str extends string> =
    Str extends `${infer A}${infer B}` ? [A, ...Unionise<B>] : []

type Length<Str extends string> = Unionise<Str>['length']

type BingBing = Length<''> extends 0 ? 'yes' : 'no'

// type Wat<Str extends string, Acc extends string = '', AtStart = true> =
//     AtStart extends true
//     ? Str extends `0x${infer PfxStripped}`
//     ? Wat<PfxStripped, false>
//     : `STRING '${Str}' MUST START WITH '0x' PREFIX`
//     : Str extends `${infer D extends HexDigit}${infer Rest}`
//     ? Wat<Rest, false>
//     : 'bad'

type Wat<Str extends string, Acc extends string = ''> =
    // Maximum limit reached, but is `Str` empty too?
    Str extends `${infer D extends HexDigit}${infer Rest}`
    ? Length<Acc> extends 16
    ? false // Too long.
    : Wat<Rest, `${Acc}${D}`>
    : Acc
//     Length<Acc> extends 16
// /*   */ ? Length<Str> extends 0
// /*       */ ? Acc // Good, maximum parse length reached.
// /*       */ : 'HEX NUMBER TOO LONG, MAXIMUM OF 16 DIGITS'
// /*   */ : Str extends `${infer D extends HexDigit}${infer Rest}`
// /*       */ ? Wat<Rest, `${Acc}${D}`>
// /*       */ : Acc
// //     ? Acc
// //     : Acc

type HexU64<
    T extends string,
    TRest extends string = T extends `0x${infer Rest}` ? Rest : '',
    Filtered = Wat<TRest>
> =
    Length<TRest> extends 0
    ? `HEX NUMBER '${T}' MUST START WITH '0x' PREFIX AND HAVE AT LEAST 1 DIGIT`
    : Filtered extends false
    ? `HEX NUMBER '${T}' TOO LONG, MAXIMUM OF 16 DIGITS`
    : TRest extends Filtered
    ? T
    : `HEX NUMBER '${T}' CONTAINS INVALID HEX DIGITS`

type Foo = HexU64<'0xffffffffffffffff'>
type Bar = HexU64<'0xffffffffffffff00'>
type Bar2 = HexU64<'0xffffffffffffff001'>
type Baz = HexU64<'0xffffffffffffff001234'>
type Baz2 = HexU64<'0xffffffffxfffff00'>
type Blah = HexU64<'ff0xffffffffffff001234'>
type Blah2 = HexU64<'fffffffffffff001234'>


//




// Tikan library types.nr Piece mod (poor man's enum in Noir).
export const Piece = {
    KNIGHT: 0,
    BISHOP: 1,
    ROOK: 2,
    QUEEN: 3,
    KING: 4,
    PAWN: 5,
} as const

// Tikan library game.nr struct.
export type Game = {
    bbs: [HexInt]
    army: boolean
    castle_rights: number
    en_passant: number
    halfmove: number
    fullmove: number
}

// Tikan library turn.nr struct.
export type Turn = {
    piece: typeof Piece
    from: number
    to: number
    promotion_piece: number
}
