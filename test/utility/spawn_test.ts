export function spawnTest(cwd: string, file: string, msg: any) {
    const proc = Bun.spawn(['bun', 'test', file], {
        cwd,
        // stdin: 'pipe',
        stdout: 'inherit',
        // stderr: 'inherit',
        ipc(message, childProc) {
            // console.log('PARENT RECEIVED', message, childProc.pid)
        }
    })

    proc.send(msg)

    return proc
}
