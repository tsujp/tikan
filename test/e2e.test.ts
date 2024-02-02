import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { TransactionDescription } from 'ethers/lib/utils'

describe('pre-test checks', () => {
    test('check environment and compile circuits', () => {
        expect(true).toBeTrue()
    })
})
