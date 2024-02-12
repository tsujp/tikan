export function spawnTest(cwd: string, file: string, msg: any) {
    const proc = Bun.spawn(['bun', 'test', file], {
        cwd,
        // stdin: 'pipe',
        stdout: 'inherit',
        // stderr: 'inherit',
        ipc(message, childProc) {
            // console.log('PARENT RECEIVED', message, childProc.pid)
        }
        // Wanted to use IPC but it doesn't work with this pattern of sending
        //   messages after the first re-run for some reason.
    })

    proc.send(msg)

    return proc
}
