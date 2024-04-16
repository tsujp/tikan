type Prettify<T> = {
    [K in keyof T]: T[K]
} & {}
// type Constructor<T = any> = new (...args: any[]) => T
// type Class<T = any> = InstanceType<Constructor<T>>
type ExtractInstanceType<T> = T extends new (
    ...args: any[]
) => infer R
    ? R
    : T extends { prototype: infer P }
      ? P
      : any
// type ExtractMethodNames<T> = {
//     [K in keyof T]: T[K] extends (...args: any[]) => any ? K : never
// }[keyof T]
// type ExtractMethods<T> = Pick<T, ExtractMethodNames<T>>
type PickMethods<T> = {
    [K in keyof T as T[K] extends (...args: any[]) => any ? K : never]: T[K]
}
// type PickMethodsAndForgetNameOf<T> = {
//     [K in keyof T & {} as T[K] extends (...args: any[]) => any ? K : never]: T[K]
// }

// export type evaluate<t> = { [k in keyof t]: t[k] } & unknown

// TODO: Move this to a utility file or something (later).
// FUTURE JORDAN: This works perfectly now.
// TODO: Add types so the proxied object has methods with the given layers.
// TODO: Then put this in the `Game.new` method so it's done by default when
//       constructing a new `Game`.
// TODO: Then implement the whole `do` async messaging thing for playing a turn.
// TODO: Perhaps make the environment printout smaller etc.
// function proxyCurry<T, M extends keyof PickMethods<T>>(
export function proxyCurry<
    const S extends object,
    const M extends keyof PickMethods<S>,
    const P extends Array<string>,
    const T extends object,
>(source: S, method: M, add_props: P, target: T) {
    if (add_props.length === 0) {
        throw new TypeError(
            `Expected 1 or more additional props, received ${add_props.length}`,
        )
    }

    // TODO: Get this from Object.assign() instead of type asserting it, if possible.
    // Constructing the return type explicitly, this seems extremely hard to do
    //   by inferring actual runtime logic via Object.assign() since Object.assign()
    //   seems to lose 'scope' (for lack of a better word) ONLY IN TYPESCRIPT
    //   when the loop ends.
    type TargetMethods = PickMethods<ExtractInstanceType<T>>
    type ProxyCurried = {
        [Prop in P[number]]: {
            [Method in keyof TargetMethods]: TargetMethods[Method]
        }
    }

    // Annoying narrowing since typing a class with a private constructor is really hard.
    const own_props =
        Object.hasOwn(target, 'prototype') &&
        Object.getOwnPropertyNames(target.prototype).filter((prop) => prop !== 'constructor')

    // OPT: Better if this was a type error at not a runtime error.
    // TODO: Might be able to get instance type methods of target and check if extends an array above length 0 to enable
    //       having compile-time warnings?
    if (own_props === false || own_props.length === 0) {
        throw new TypeError(`No prototype or instance methods found for target '${target}'`)
    }

    for (const p of add_props) {
        Object.assign(source, {
            [p]: own_props.reduce(
                (acc, method_name) => {
                    acc[method_name] = source[method].bind(source, p, method_name)
                    return acc
                },
                {} as { [key: (typeof own_props)[number]]: (...args: unknown[]) => unknown },
            ),
        })
    }

    return source as S & ProxyCurried

    // const lyrs = structuredClone(layers)
    // const max = lyrs.length - 1

    // console.log(Object.getPrototypeOf(target)?.constructor?.name)

    // TODO: Type this shit later.
    // [K in L]: 'foo'
    // K: 'bar'
    // [J in L[0][number]]: 'bar'
    // }
    // [K in L[0][number] as K extends string ? K : never]: 'foo'
    // [K in Extract<L[0][number], any>]: 'foo'
    // }

    // function proxify<P extends T = T>(__target: P, idx = 0, curried: string[] = []) {
    // function proxify(__target: typeof target, idx = 0, curried: string[] = []) {
    //     // type Foo = (typeof layers)[0][number]

    //     return new Proxy(__target, {
    //         get(orig, prop, prxy) {
    //             // Get normal existing method (if any). Not dealing with symbols
    //             //   so passthrough those and existing methods.
    //             const fn = Reflect.get(orig, prop)
    //             if (fn || typeof prop === 'symbol') {
    //                 return fn
    //             }

    //             const lyr = lyrs.at(idx)

    //             // Only curry values we specified (note: already returned with real function if such exists).
    //             // if (lyrs?.at(idx)?.includes(prop) === false) {
    //             if (lyr == null || lyr.includes(prop) === false) {
    //                 const klass = Object.getPrototypeOf(orig)?.constructor?.name
    //                 throw new TypeError(
    //                     `Property '${prop}' on ${klass} is undefined (neither function '${klass}.${prop}()' nor attribute '${klass}.${prop}')`,
    //                 )
    //             }

    //             // Done, curry with property keys thus far.
    //             if (idx === max) {
    //                 // const xx = orig[method]
    //                 // return xx.bind(this === prxy ? orig : this, ...curried, prop)
    //                 // return orig[method].bind(orig, ...curried, prop)
    //             }

    //             // type Merge<T, K> = Omit<T, keyof K> & K

    //             // Not done, proxy the next layer.
    //             // return proxify(this === prxy ? orig : this, idx + 1, curried.concat(prop))
    //             return proxify(__target, idx + 1, curried.concat(prop))
    //         },
    //     })
    // }

    // return proxify(target)
}
