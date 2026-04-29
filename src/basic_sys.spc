.module basic_sys
.export _user_inkey

; Return one buffered UART byte, or -1 when no byte is available.
.proc _user_inkey 0
    sys 9
    ret 0
.end
.endmodule
