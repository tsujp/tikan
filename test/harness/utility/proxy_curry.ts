// XXX: This implementation constructs methods at invocation time. Use of `Proxy`
//      would construct the first layers at invocation time and the rest as called
//      at runtime. Types with `Proxy` and even `Object.assign()` are very hard
//      so for now the return type is manually asserted. SO THE TYPES HERE ARE

import type { ExtractInstanceType, PickMethods } from '#test/harness/types'

//      NOT DERIVED FROM THE IMPLEMENTATION. CHANGING EITHER REQUIRES UPDATING!
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

    // TypeScript appears to lose `Object.assign` inference in loops; so we do
    //   this manually.
    type TargetMethods = PickMethods<ExtractInstanceType<T>>
    type ProxyCurried = {
        [Prop in P[number]]: {
            [Method in keyof TargetMethods]: TargetMethods[Method]
        }
    }

    // Annoying narrowing since typing a class with a private constructor is
    //   really hard.
    const own_props =
        Object.hasOwn(target, 'prototype') &&
        Object.getOwnPropertyNames(target.prototype).filter((prop) => prop !== 'constructor')

    // OPT: Better if this was a type error and not a runtime error.
    // TODO: Might be able to get instance type methods of target and check
    //       if extends an array above length 0 to enable having compile-time
    //       warnings?
    if (own_props === false || own_props.length === 0) {
        throw new TypeError(`No prototype or instance methods found for target '${target}'`)
    }

    for (const p of add_props) {
        Object.assign(source, {
            [p]: own_props.reduce(
                (acc, method_name) => {
                    // Sign TS, S[M] does index it and is a method.
                    // @ts-ignore TS2339
                    acc[method_name] = source[method].bind(source, p, method_name)
                    return acc
                },
                {} as { [key: (typeof own_props)[number]]: (...args: unknown[]) => unknown },
            ),
        })
    }

    return source as S & ProxyCurried
}
