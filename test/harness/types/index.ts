// Hoist exports from `.ts` type files.

export type * from '#test/harness/types/util'
export type * from '#test/harness/types/noir'
export type * from '#test/harness/types/numeric'
export type * from '#test/harness/types/tikan'
export type * from '#test/harness/types/ipc'

// TODO: Clean up the below dumping ground.

// If a function has explicit parameters it's type is returned, if not: never.
type HasParameters<T> = T extends (...args: any[]) => any
    ? Parameters<T>[number] extends never
        ? never
        : T
    : never

// Preserves functions on an object which explicitly type `this`.
type GetThisFunctions<T> = {
    [K in keyof T as T[K] extends ThisParameterType<T[K]> ? never : K]: T[K]
}

type ThisFunctionsWithParameters<T> = {
    [K in keyof T as T[K] extends ThisParameterType<T[K]>
        ? never
        : HasParameters<T[K]> extends never
          ? never
          : K]: T[K]
}

// type LogFor<L extends Logger, M extends keyof GetThisFunctions<L>, P extends Array<unknown> = L[M] extends Logger ? Parameters<L[M]> : never> = (...args: P) => [L[M], ...P]

// Works fine but not using that patterna anymore.
// function LogFor<L extends Logger, M extends keyof ThisFunctionsWithParameters<L>, P extends Array<unknown> = L[M] extends Logger ? Parameters<L[M]> : never>(logger: L, curry_target: M) {
//   return (...args: P) => [logger[curry_target], ...args]
// }
