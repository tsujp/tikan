export class NonZeroReturnError extends Error {
    constructor(message: string, cause: string) {
        super(message)
        this.name = 'NonZeroReturnError'
        this.cause = cause
    }
}
