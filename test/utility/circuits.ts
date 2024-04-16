import { basename, join } from 'node:path'
import type { CompiledCircuit } from '@noir-lang/backend_barretenberg'
import type { AllCircuits } from '#test/types'

export async function getCircuitDefinitions(
    root_dir: string,
): Promise<AllCircuits> {
    const { name, workspace } = await import(
        join(root_dir, 'Nargo.toml')
    ).catch((e) => {
        console.error(e)
        return Promise.reject(
            'Missing/malformed Nargo.toml in project root directory',
        )
    })

    if (name !== '__ROOT__') {
        return Promise.reject(
            'Root Nargo.toml has missing/wrong identifier, expect `__ROOT__`',
        )
    }

    if (Array.isArray(workspace?.members) === false) {
        return Promise.reject('Root Nargo.toml missing workspace members array')
    }

    const res_defs = {
        bin: [],
        lib: [],
    }

    for (const k of workspace.members) {
        const root = join(root_dir, k)
        const {
            package: { name, type },
        } = await import(join(root, 'Nargo.toml'))

        res_defs[type].push({
            name: basename(k),
            root: join(root_dir, k),
            ...(type === 'bin' && {
                artifact: join(root_dir, `target/${name}.json`),
            }),
        })
    }

    return res_defs
}

// By default there's A LOT of stuff in the compiled circuit, structured cloning
//   is dying from this so let's get only what type `CompiledCircuit` says it
//   needs.
export async function getCompiledCircuits<T extends string>(
    domain: AllCircuits,
    names: Array<T>,
) {
    // Assertion is fine for now.
    const crcs = {} as { [K in (typeof names)[number]]: CompiledCircuit }

    const to_find = structuredClone(names)
    let idx = -1

    for (const bc of domain.bin) {
        idx = -1
        idx = to_find.findIndex((n) => bc.name === n)

        if (idx > -1) {
            const data = await import(bc.artifact)

            Object.assign(crcs, {
                [to_find[idx]]: {
                    abi: data.abi,
                    bytecode: data.bytecode,
                },
            })

            to_find.splice(idx, 1)
        }
    }

    if (to_find.length > 0) {
        throw new Error(`Could not find circuits: ${to_find.join(', ')}`)
    }

    return crcs
}
