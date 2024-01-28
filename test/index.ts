import { join } from 'path'
import { checkTestEnvironment } from './utility/precheck'

import { getNoirArtifactDefinitions } from './utility/get_circuits'

import { resolveProjectRootDir } from './utility/misc'

const root_dir = await resolveProjectRootDir()
const noir_defs = await getNoirArtifactDefinitions(root_dir)

console.log(noir_defs)

// const wd = process.cwd()
// await checkTestEnvironment(wd, '.')
const daPath = join(process.cwd(), 'circuit/lib')
console.log('da path', daPath)

// const proc = Bun.spawnSync(['echo', 'hello'], {
//     cwd: daPath,
//     stdout: 'pipe',
// })
// console.log(proc)


// Doing `nargo test` from the javascript file.

// console.log(Bun.version)

// const foo = await Bun.spawn(['nargo', 'test'], {
//     cwd: daPath,
// })

// console.log(foo)
