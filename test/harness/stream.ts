// This class is taken from Deno's standard library version 0.224.0, from:
//   https://github.com/denoland/deno_std/blob/0.224.0/streams/text_line_stream.ts
//
// This class has been modified from the original.
//
// Deno's licence:
// Copyright 2018-2024 the Deno authors. All rights reserved. MIT license.
export class TextLineStream extends TransformStream<Uint8Array | string, string> {
    #decoder = new TextDecoder('utf-8')
    #currentLine = ''

    /** Constructs a new instance. */
    constructor() {
        super({
            transform: (chars, controller) => {
                chars = (this.#currentLine +
                    (typeof chars === 'string'
                        ? chars
                        : this.#decoder.decode(chars))) as string

                while (true) {
                    const lfIndex = chars.indexOf('\n')

                    if (lfIndex === -1) break

                    const endIndex = chars[lfIndex - 1] === '\r' ? lfIndex - 1 : lfIndex
                    controller.enqueue(chars.slice(0, endIndex))
                    chars = chars.slice(lfIndex + 1)
                }

                this.#currentLine = chars
            },
            flush: (controller) => {
                if (this.#currentLine === '') return
                const currentLine = this.#currentLine
                controller.enqueue(currentLine)
            },
        })
    }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// This function is taken from Deno's standard library version 0.224.0, from:
//   https://github.com/denoland/deno_std/blob/0.224.0/streams/merge_readable_streams.ts
//
// Deno's licence:
// Copyright 2018-2024 the Deno authors. All rights reserved. MIT license.
export function mergeReadableStreams<T>(...streams: ReadableStream<T>[]): ReadableStream<T> {
    const resolvePromises = streams.map(() => Promise.withResolvers<void>())
    return new ReadableStream<T>({
        start(controller) {
            let mustClose = false
            Promise.all(resolvePromises.map(({ promise }) => promise))
                .then(() => {
                    controller.close()
                })
                .catch((error) => {
                    mustClose = true
                    controller.error(error)
                })
            for (const [index, stream] of streams.entries()) {
                ;(async () => {
                    try {
                        for await (const data of stream) {
                            if (mustClose) {
                                break
                            }
                            controller.enqueue(data)
                        }
                        resolvePromises[index]!.resolve()
                    } catch (error) {
                        resolvePromises[index]!.reject(error)
                    }
                })()
            }
        },
    })
}
