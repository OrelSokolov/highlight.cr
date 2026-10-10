(module
  ;; Сумма массива
  (memory (export "memory") 1)
  (table $tbl 2 funcref)
  (global $counter (mut i32) (i32.const 0))

  (type $binop (func (param i32 i32) (result i32)))

  (func $add (type $binop) (param $a i32) (param $b i32) (result i32)
    (i32.add (local.get $a) (local.get $b)))

  (func $sum (export "sum") (param $ptr i32) (param $len i32) (result i32)
    (local $i i32) (local $acc i32)
    (block $exit
      (loop $loop
        (br_if $exit (i32.ge_u (local.get $i) (local.get $len)))
        (local.set $acc
          (i32.add (local.get $acc)
            (i32.load (i32.add (local.get $ptr) (i32.mul (local.get $i) (i32.const 4)))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop)))
    (global.set $counter (i32.add (global.get $counter) (i32.const 1)))
    (local.get $acc))

  (elem (i32.const 0) $add)
  (data (i32.const 16) "готово\00")
)
