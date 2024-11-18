// Gimme that poor man's enum, kid.

const ASCII_OFFSET = 97

const phat_codegen = []

phat_codegen.push('mod Sq {')

for (let idx = 0; idx < 64; idx++) {
    // x >> 3 === floor division by 8
    const rank = (idx >> 3) + 1

    // x & 7 === modulo 8
    const file = String.fromCharCode((idx & 7) + ASCII_OFFSET)

    phat_codegen.push(`    global ${file}${rank}: u8= ${idx};`)
}

phat_codegen.push('}')

console.log(phat_codegen.join('\n'))
