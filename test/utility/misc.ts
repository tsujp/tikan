import { join } from 'path'

// TODO: waste time typing this (TypeScript) later.
// @ts-ignore
export const asyncMap = (items, fn) => Promise.all(items.map(fn))

// Resolve the root workspace, no other way to do this currently.
// XXX: Will not work with nested workspaces, don't be satanic.
//   - Environment variables from `.env` files are not read when in a
//     subdirectory; honestly it'd be somewhat weird if they were because
//     when do you stop reading them from the parent? What if a git repo isn't
//     instantiated yet?
//   - `exports` from the root workspace package.json are not readable which
//     is the real killer here; they should be.
export async function resolveProjectRootDir(): Promise<string> {

    // No (big) recursive closures please.
    async function iter(cur: string): Promise<string> {
        const nxt = join(cur, '..')
        if (nxt === cur) return Promise.reject('Workspace package.json not found in any parent directory')

        const contents = await Bun.file(join(cur, 'package.json')).json().catch(e => {
            // errno -2 is 'no such file or directory' which, if there is an error, is the only error
            //   we want to 'accept'.
            if (e.errno !== -2) {
                console.error(e)
                return Promise.reject('Unexpected error attempting to read file')
            }
        })

        if (contents?.workspaces) {
            return Promise.resolve(cur)
        }

        return iter(nxt)
    }

   return iter(process.cwd())
}