const wasm = require('./bswap.js')()

const slice = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7])

console.log(slice)
wasm.realloc(slice.byteLength)

wasm.memory.set(slice)
wasm.exports.bswap32(0)
console.log(wasm.memory.subarray(0, slice.byteLength))

wasm.memory.set(slice)
wasm.exports.bswap64(0)
console.log(wasm.memory.subarray(0, slice.byteLength))

wasm.memory.set(slice)
wasm.exports.bswap64_bytewise(0)
console.log(wasm.memory.subarray(0, slice.byteLength))
