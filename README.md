# `bswap-wasm`

> bswap in WASM by using rotates

## Usage

`bswap` is a useful instruction for converting words of various sizes between
Big Endian and Little Endian. Unfortunately, even  though most modern processors
have specialised instructions for `bswap`, this instruction didn't make it into
the WebAssembly instruction set.

The most common way to implement `bswap` is a series of shifts and or's,
essentially masking out single bytes and shifting them around, pivoting at the
middle:

```
01 02 03 04 05 06 07 08  Initial
-----------------------
__ __ __ __ __ __ __ 01  Shift right 7 bytes
__ __ __ __ __ __ 02 __  Shift right 5 bytes, mask 2nd byte
__ __ __ __ __ 03 __ __  Shift right 3 bytes, mask 3nd byte
__ __ __ __ 04 __ __ __  Shift right 1 byte, mask 4nd byte
__ __ __ 05 __ __ __ __  Mask 4nd byte, shift left 1 byte
__ __ 06 __ __ __ __ __  Mask 3nd byte, shift left 3 byte
__ 07 __ __ __ __ __ __  Mask 2nd byte, shift left 5 byte
08 __ __ __ __ __ __ __  Shift left 7 bytes
-----------------------
08 07 06 05 04 03 02 01 Result by or'ing all intermediates
```

```wat
(func $i64.bswap
  (param $b i64)
  (result i64)

  ;; 8 get, 14 const, 8 shifts, 6 ands, 7 ors = 43 ops

  (i64.shr_u (local.get $b) (i64.const 56))
  (i64.and (i64.shr_u (local.get $b) (i64.const 40)) (i64.const 0x0000FF00))
  (i64.or)
  (i64.and (i64.shr_u (local.get $b) (i64.const 24)) (i64.const 0x00FF0000))
  (i64.or)
  (i64.and (i64.shr_u (local.get $b) (i64.const  8)) (i64.const 0xFF000000))
  (i64.or)
  (i64.shl (i64.and (local.get $b) (i64.const 0xFF000000)) (i64.const 8))
  (i64.or)
  (i64.shl (i64.and (local.get $b) (i64.const 0x00FF0000)) (i64.const 24))
  (i64.or)
  (i64.shl (i64.and (local.get $b) (i64.const 0x0000FF00)) (i64.const 40))
  (i64.or)
  (i64.shl (local.get $b) (i64.const 56))
  (i64.or))
```

The technique in this module uses the native `rotl` and `rotr` instructions,
which allow you to rotate bytes around the word boundary.

Let's start with the simple case of `i32` (4 bytes). Here the direction of
rotation does not matter as the technique is symmetric around the middle:

```
01 02 03 04
-----------
__ 02 __ 04  Mask odd bytes
04 __ 02 __  Rotate 1 byte

01 __ 03 __  Mask even bytes
__ 03 __ 01  Rotate 1 byte
-----------
04 03 02 01  Or everything
```

```wat
(func $i32.bswap
  (param $b i32)
  (result i32)

  ;; 2 get, 4 const, 5 bitwise = 11 ops

  (i32.or
    (local.get $b)
    (i32.const 0x00FF00FF)
    (i32.and)
    (i32.rotl (i32.const 8))

    (local.get $b)
    (i32.const 0xFF00FF00)
    (i32.and)
    (i32.rotr (i32.const 8))))
```

For the `i64` (8 bytes) things get a bit more complicated as we need to swap in
two steps, but we are basically applying the technique above recursively:

```
01 02 03 04 05 06 07 08
-----------------------
01 02 __ __ 05 06 __ __  Mask odd byte pairs
__ __ 05 06 __ __ 01 02  Rotate left 2 bytes

__ __ 03 04 __ __ 07 08  Mask even byte pairs
07 08 __ __ 03 04 __ __  Rotate right 2 bytes

07 08 05 06 03 04 01 02  or and store

__ 08 __ 06 __ 04 __ 02  Mask odd bytes
08 __ 06 __ 04 __ 02 __  Rotate left 1 byte

07 __ 05 __ 03 __ 01 __  Mask even bytes
__ 07 __ 05 __ 03 __ 01  Rotate right 1 byte
-----------------------
08 07 06 05 04 03 02 01  Or everything
```

```wat
(func $i64.bswap
  (param $b i64)
  (result i64)

  ;; 1 set, 4 get, 8 const, 10 bitwise = 23 ops
  (i64.or
    (local.get $b)
    (i64.const 0xFFFF0000FFFF0000)
    (i64.and)
    (i64.rotl (i64.const 16))

    (local.get $b)
    (i64.const 0x0000FFFF0000FFFF)
    (i64.and)
    (i64.rotr (i64.const 16)))

  (local.set $b)

  (i64.or
    (local.get $b)
    (i64.const 0x00FF00FF00FF00FF)
    (i64.and)
    (i64.rotl (i64.const 8))

    (local.get $b)
    (i64.const 0xFF00FF00FF00FF00)
    (i64.and)
    (i64.rotr (i64.const 8))))
```

I don't know that the above is the most optimal it can be, but it was fun to
think about nevertheless.

This repository is not directly useable, but once we figure out a nice way
to link WAT modules it might be.

## License

[ISC](LICENSE)
