// Deno includes its own testing libraries.
//
// Docs:
//   - https://deno.land/manual/basics/testing
//   - https://deno.land/api?s=Deno.test
//   - https://deno.land/std/testing/bdd.ts
//   - https://deno.land/std@/testing/asserts.ts

import { assertEquals, assertExists, assertStrictEquals, assertThrows } from '@deno/asserts'
import { afterEach, beforeEach, describe, it } from '@deno/bdd'

const moveTests = describe('Movieieieieieeiasdasdasd')

const whiteTests = describe({
   name: 'white123112',
   suite: moveTests,
   beforeEach (this: { foo: string }) {
      this.foo = 'bar'
   },
})

it(whiteTests, 'bingBong', function () {
   const { foo } = this
   assertEquals(foo, 'bar')
})
