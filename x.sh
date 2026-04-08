PV24T=../sw-cor24-pcode/target/release/pv24t; timeout 10 $PV24T build/basic.p24 -i "$(cat examples/hello.bas)" -n 10000000; echo
      "exit=$?"
