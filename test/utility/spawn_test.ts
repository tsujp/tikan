export function spawnTest(cwd: string, file: string) {
    return Bun.spawn(['bun', 'test', file], {
        cwd,
        stdin: 'pipe',
        stdout: 'inherit',
        // Wanted to use IPC but it doesn't work with this pattern of sending
        //   messages after the first re-run for some reason.
    })
}