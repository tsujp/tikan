export type Prettify<T> = {
    [K in keyof T]: T[K]
} & {}

export type ExtractInstanceType<T> = T extends new (
    ...args: any[]
) => infer R
    ? R
    : T extends { prototype: infer P }
      ? P
      : any

export type PickMethods<T> = {
    [K in keyof T as T[K] extends (...args: any[]) => any ? K : never]: T[K]
}
