(module
  ;; Non-vital boilerplate
  (memory (export "memory")0)
  (func $bswap64 (export "bswap64") (param $pos i32) (i64.store (local.get $pos) (call $i64.bswap (i64.load (local.get $pos)))))
  (func $bswap32 (export "bswap32") (param $pos i32) (i32.store (local.get $pos) (call $i32.bswap (i32.load (local.get $pos)))))
  (func $bswap64_bytewise (export "bswap64_bytewise") (param $pos i32) (i64.store (local.get $pos) (call $i64.bswap_bytewise (i64.load (local.get $pos)))))

  ;; Implementation
  (func $i32.bswap
    (param $b i32)
    (result i32)

    ;; 2 get, 4 const, 5 bitwise
    (i32.or
      (local.get $b)
      (i32.const 0x00FF00FF)
      (i32.and)
      (i32.rotl (i32.const 8))

      (local.get $b)
      (i32.const 0xFF00FF00)
      (i32.and)
      (i32.rotr (i32.const 8))))


  (func $i64.bswap
    (param $b i64)
    (result i64)

    ;; 1 set, 4 get, 8 const, 10 bitwise
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

  (func $i64.bswap_bytewise
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
    (i64.or)))
