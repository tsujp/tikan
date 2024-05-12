// Very obvious and apparent that this is needed, FUCK SAKE MICRO$OFT DOCUMENT
//   YOUR SHIT OR FUCK OFF!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
export {}

export type SetRequired<BaseType, Keys extends keyof BaseType> = BaseType &
    Omit<BaseType, Keys> &
    Required<Pick<BaseType, Keys>>

declare global {
    var TIKAN_TEST_SETUP: boolean | undefined
    var MESSAGE_ID: number

    // See: https://github.com/microsoft/TypeScript/issues/44253#issuecomment-1097202653
    // Thanks to @jamiebuilds at the above link for fixing this stupidity.
    interface ObjectConstructor {
        hasOwn<BaseType, Key extends keyof BaseType>(
            record: BaseType,
            key: Key,
        ): record is SetRequired<BaseType, Key>
        hasOwn<Key extends PropertyKey>(
            record: object,
            key: Key,
        ): record is { [K in Key]: unknown }
    }
}
