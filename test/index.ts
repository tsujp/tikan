import { join } from 'path'
import { checkTestEnvironment } from './utility/precheck'
// import wallah55 from '@tikan/tests'

import { getCircuitDefinitions } from './utility/get_circuits'

import { resolveProjectRootDir } from './utility/misc'

// console.log(Bun.env)
// const abc = await resolveProjectRoot().then(r => console.log('result:', r))
const abc = await resolveProjectRootDir()
console.log('root is', abc)


console.log('circuit defs', await getCircuitDefinitions(join(abc, 'package.json'), abc))
// console.log(wallah55)

// const wd = process.cwd()
// await checkTestEnvironment(wd, '.')
const daPath = join(process.cwd(), 'circuit/lib')
// console.log(daPath)

// const proc = Bun.spawnSync(['echo', 'hello'], {
//     cwd: daPath,
//     stdout: 'pipe',
// })
// console.log(proc)



// console.log(Bun.version)

// const foo = await Bun.spawn(['nargo', 'test'], {
//     cwd: daPath,
// })

// console.log(foo)