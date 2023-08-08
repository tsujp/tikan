// Calling Deno.exit() with any status code will prevent `Deno --watch` from
//   re-executing, so for the development task use a thin wrapper.

import { TextLineStream } from 'https://deno.land/std@0.197.0/streams/text_line_stream.ts'

const wd = Deno.cwd()

// * * * * * * * * * * * * * * * * * * * * * * * PRE-CHECK EXECUTION
// * * * * * * * * * * * * *
const precheck_cmd = new Deno.Command('deno', {
   cwd: wd,
   args: ['task', 'test:pre-check'],
   stdout: 'piped',
})

const precheck_proc = precheck_cmd.spawn()

// Decode stdout buffer stream.
const precheck_read = precheck_proc.stdout.pipeThrough(new TextDecoderStream())
   .pipeThrough(new TextLineStream())

// Print each line of stdout buffer stream; blocking lower (in file) execution.
for await (const l of precheck_read) {
   console.log(l)
}

// * * * * * * * * * * * * * * * * * * * * * * * TEST SUITE EXECUTION
// * * * * * * * * * * * * *

// If precheck process exits with success then the test suite can be started.
const precheck_success = await precheck_proc.status.then(({ success }) => success)

if (precheck_success) {
   const test_cmd = new Deno.Command('deno', {
      cwd: wd,
      args: ['task', 'test', '--fail-fast'],
      stdout: 'piped',
   })

   const test_proc = test_cmd.spawn()

   const test_read = test_proc
      .stdout
      .pipeThrough(new TextDecoderStream())
      .pipeThrough(new TextLineStream())

   for await (const l of test_read) {
      console.log(l)
   }

   await test_proc.status
}
