// TODO: Maybe waste 42069 hours adding TypeScript types later, or.. maybe don't.

// This won't work correctly if you have a non `async` function return a `Promise`
//   and the extra effort to make that so for this test suite is not worth it.
export function logPerf<T>(target: T, key: string, descriptor: TypedPropertyDescriptor<T>) {
    // console.log('target', target)
    // console.log('key', key)
    // console.log('descriptor', descriptor)

    const name = target.constructor.name
    const orig = descriptor.value

    // Bun's PerformanceObserver follows Node.js' implementation, not the WebWorker
    //   one. Calling `performance.mark('foo')` creates a mark of name `foo`. Then
    //   calling `performance.measure('foo time', 'foo')` creates a measurement of
    //   the time difference between the prior mark `foo` and now, and titles that
    //   measurement `foo time`.
    //
    // So:
    //   - `performance.mark(key)` := a mark named after function being called.
    //   - `performance.measure(key, key)` := measured time between prior mark
    //                                        of function name and now, with this
    //                                        measurement named after the function.

    if (orig[Symbol.toStringTag] === 'AsyncFunction') {
        descriptor.value = async function (...args) {
            // console.log(`start: ${key}`)
            performance.mark(key)
            const result = await orig.apply(this, args)
            performance.measure(`${name}.${key}`, key)
            // console.log(`end: ${key}`)
            return result
        }
    } else {
        descriptor.value = function (...args) {
            // console.log(`start: ${key}`)
            performance.mark(key)
            const result = orig.apply(this, args)
            performance.measure(`${name}.${key}`, key)
            // console.log(`end: ${key}`)
            return result
        }
    }

    return descriptor
}
