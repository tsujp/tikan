export function testInvokeGuard() {
    if (globalThis.TIKAN_TEST_SETUP == null) {
        console.error('Execute `bun test` from root repository directory only')
        process.exit(1)
        // throw new Error(
        //     'Execute `bun test` from repository root directory only',
        // )
    }
}
