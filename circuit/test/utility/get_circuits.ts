import { join } from 'path'
import { CircuitDefinition } from '../types'
import { asyncMap } from './misc'

export async function getCircuitDefinitions (
    package_json: string,
    project_root: string,
): Promise<CircuitDefinition> {
    const circuits: string[][] = await import(package_json).then(({ circuits }) =>
        Object.entries(circuits)
    )

    const circuit_paths = circuits.map(([_, dir]) => join(project_root, dir))
    const circuit_jsons = await asyncMap(circuit_paths, async (path: string) => {
        const { package: { name } } = await import(join(path, 'Nargo.toml'))
        const json = join(path, `target/${name}.json`)
        return json
    })

    const circuit_defs = circuits.reduce((acc, [ref_name, _], i) => {
        acc[ref_name] = {
            path: circuit_paths[i],
            circuit: circuit_jsons[i],
        }
        return acc
    }, {} as CircuitDefinition)

    return circuit_defs
}
