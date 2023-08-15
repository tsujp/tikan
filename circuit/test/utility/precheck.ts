import chalk from 'chalk'

const roseChar = '-'

class NonZeroReturnError extends Error {
   constructor (message: string, cause: string) {
      super(message)
      this.name = 'NonZeroReturnError'
      this.cause = cause
   }
}

// Single line string only; if left and right padding is odd will preference
//   left side (i.e. right side will receive the extra str pad).
export function padCentre (str: string, padStr: string, max = 80) {
   if (str.length > max) {
      return str
   }

   const spaceStr = ` ${str} `

   return spaceStr
      .padStart(Math.floor(spaceStr.length / 2) + Math.floor(max / 2), padStr)
      .padEnd(max, padStr)
}

// Prints pre-formatted test environment item for sanity preamble.
function logItem (item: string, str: string) {
   return console.log(`${chalk.cyan(item)}${chalk.gray(':')} ${chalk.reset(str)}`)
}

function logItemError (item: string, str: string) {
   // Not console.error because this test harness is mostly to facilitate sanely
   //   orchestrating Nargo for integration and end-to-end tests and not for
   //   perfect logging etc. Outputting to console.error (stderr) will require
   //   explicit buffer synchronisation which is way too much for _orchestrating
   //   nargo_.
   return console.log(
      `${chalk.red('[ERROR]')} ${chalk.cyan(item)}${chalk.gray(':')} ${
         chalk.reset(str)
      }`,
   )
}

function logCommand (
   cmdDef: Parameters<typeof Bun.spawnSync>,
   item: string,
   errMsg: string,
) {
   try {
      const { exitCode, stdout, stderr } = Bun.spawnSync(...cmdDef)

      if (exitCode !== 0) {
         throw new NonZeroReturnError(
            errMsg,
            new TextDecoder().decode(stderr).trim(),
         )
      } else {
         logItem(item, new TextDecoder().decode(stdout).trim())
      }
   } catch (e: unknown) {
      // XXX: TypeScript has cursed exception type-narrowing in switch-case even
      //      though JavaScript uses non-value exceptions, hilarious. Hey guys
      //      let's have an exception system where you cannot even narrow on
      //      exception types in a switch-case who would ever need that??????
      if (e instanceof Error) {
         logItemError(item, e.stack ?? '<NO STACK TRACE>')
         if (e.cause) {
            console.log(`\n${e.cause}`)
         }
      }

      // Errors.
      return false
   }

   // No errors.
   return true
}

// Block while printing chosen Nargo information; this is extremely important
//   being that Nargo comprises the system under test and having to guess
//   what version (e.g. multiple installs) is being used sucks, so print it.
export function checkTestEnvironment (wd: string) {
   console.log(chalk.yellow(padCentre('Check test environment', roseChar)))

   logItem('cwd', wd)

   // This executes immediately and fills prechecks with true/false values.
   const prechecks = [
      logCommand(
         [['command', '-v', 'nargo'], { cwd: wd }],
         'nargo executable',
         'Nargo executable not found in $PATH',
      ),
      logCommand(
         [['nargo', '--version'], { cwd: wd }],
         'nargo ver',
         'could not determine Nargo version',
      ),
   ]

   const precheckSuccess = prechecks.every((res) => res === true)

   console.log(chalk.yellow(roseChar.repeat(80)))

   if (precheckSuccess === false) {
      console.log(chalk.red('PRE-CHECKS FAILED!'))
   }

   return precheckSuccess
}
