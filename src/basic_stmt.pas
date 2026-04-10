program BasicStmt;
{ COR24 BASIC v1 — Statement handlers: PRINT, LET, POKE.
Reads tokens from eb[] via ep. Uses p_expr for expressions.
I/O via write/writechar (p24p runtime). }
const
   FK=128; TP=160; TG=169; VA=192; TI=224; TS=225;
var
   eb: array[0..127] of integer;
   ep, err, ev: integer;
   vars: array[0..25] of integer;
   pi_d: array[0..9] of integer; { digit buffer for print_int }
   tf: integer;

procedure vars_clear;
var i:integer;
begin i:=0; while i<26 do begin vars[i]:=0; i:=i+1 end end;

procedure p_expr(lev:integer);
var v,op,r:integer; b:boolean;
begin
   if lev=0 then begin v:=0;
      if eb[ep]=TI then begin ep:=ep+1;v:=eb[ep]*65536+eb[ep+1]*256+eb[ep+2];ep:=ep+3 end
   else if(eb[ep]>=VA)and(eb[ep]<=VA+25)then begin v:=vars[eb[ep]-VA];ep:=ep+1 end
   else if eb[ep]=176 then begin ep:=ep+1;p_expr(4);v:=ev;
      if(err=0)and(eb[ep]=177)then ep:=ep+1 else if err=0 then err:=1 end
   else if eb[ep]=FK+23 then begin ep:=ep+1;
      if eb[ep]=176 then begin ep:=ep+1;p_expr(4);v:=ev;if v<0 then v:=0-v;
	 if(err=0)and(eb[ep]=177)then ep:=ep+1 else if err=0 then err:=1 end else err:=1 end
   else err:=1; ev:=v end
else if lev=1 then begin
   if eb[ep]=TP+1 then begin ep:=ep+1;p_expr(1);ev:=0-ev end
else if eb[ep]=TP then begin ep:=ep+1;p_expr(1) end
else p_expr(0) end
else if lev=2 then begin p_expr(1);v:=ev;
   while(err=0)and((eb[ep]=TP+2)or(eb[ep]=TP+3))do begin
      op:=eb[ep];ep:=ep+1;p_expr(1);r:=ev;
      if op=TP+2 then v:=v*r else if r<>0 then v:=v div r else err:=5 end;ev:=v end
else if lev=3 then begin p_expr(2);v:=ev;
   while(err=0)and((eb[ep]=TP)or(eb[ep]=TP+1))do begin
      op:=eb[ep];ep:=ep+1;p_expr(2);r:=ev;
      if op=TP then v:=v+r else v:=v-r end;ev:=v end
else begin p_expr(3);v:=ev;
   while(err=0)and(eb[ep]>=TP+4)and(eb[ep]<=TG)do begin
      op:=eb[ep];ep:=ep+1;p_expr(3);r:=ev;b:=false;
      if op=TP+4 then b:=(v=r) else if op=TP+5 then b:=(v<>r)
      else if op=TP+6 then b:=(v<r) else if op=TP+7 then b:=(v<=r)
      else if op=TP+8 then b:=(v>r) else if op=TG then b:=(v>=r);
      if b then v:=1 else v:=0 end;ev:=v end
end;

{ --- I/O primitives --- }

procedure print_int(n: integer);
var i, nd: integer;
begin
   if n < 0 then begin writechar('-'); n := 0 - n end;
   if n = 0 then writechar('0')
   else begin
      nd := 0;
      while n > 0 do begin pi_d[nd] := n mod 10; nd := nd + 1; n := n div 10 end;
      i := nd - 1;
      while i >= 0 do begin writechar(chr(pi_d[i] + 48)); i := i - 1 end
   end
end;

procedure print_str_tok;
{ Print string token at eb[ep]. Expects ep pointing to length byte after TS. }
var n, i: integer;
begin
   n := eb[ep]; ep := ep + 1;
   i := 0;
   while i < n do begin writechar(chr(eb[ep])); ep := ep + 1; i := i + 1 end
end;

{ --- Statement handlers --- }

procedure do_print;
var dn: integer;
begin
   dn := 0;
   if eb[ep] = 0 then begin writeln; dn := 1 end;
   while (err = 0) and (dn = 0) do begin
      if eb[ep] = TS then begin ep := ep + 1; print_str_tok end
   else begin p_expr(4); print_int(ev) end;
      if eb[ep] = 179 then ep := ep + 1 { ; suppress newline }
      else if eb[ep] = 178 then begin ep := ep + 1; writechar(chr(9)) end { , tab }
      else begin writeln; dn := 1 end
   end
end;

procedure do_let;
{ LET var = expr  (LET keyword already consumed by dispatch) }
var vi: integer;
begin
   if (eb[ep] >= VA) and (eb[ep] <= VA+25) then begin
      vi := eb[ep] - VA; ep := ep + 1;
      if eb[ep] = TP+4 then begin ep := ep + 1; p_expr(4); vars[vi] := ev end
   else err := 1
   end
else err := 1
end;

procedure do_poke;
{ POKE addr, val }
var addr: integer;
begin
   p_expr(4); addr := ev;
   if (err = 0) and (eb[ep] = 178) then begin
      ep := ep + 1; p_expr(4);
      if err = 0 then poke(addr, ev)
   end
else err := 1
end;

procedure ck(ok:boolean;id:integer);
begin if ok then write('P')else begin write('F');tf:=tf+1 end;writeln(id)end;
procedure si(p,v:integer);
begin eb[p]:=TI;eb[p+1]:=(v div 65536)mod 256;eb[p+2]:=(v div 256)mod 256;eb[p+3]:=v mod 256 end;

begin
   vars_clear; tf:=0;
   { Test 1: PRINT 42 -> prints "42\n" }
   si(0,42); eb[4]:=0; ep:=0; err:=0; do_print;
   ck(err=0, 1);
   { Test 2: PRINT "HI" -> prints "HI\n" }
   eb[0]:=TS; eb[1]:=2; eb[2]:=72; eb[3]:=73; eb[4]:=0;
   ep:=0; err:=0; do_print;
   ck(err=0, 2);
   { Test 3: LET A=7, then check vars[0]=7 }
   eb[0]:=VA; eb[1]:=TP+4; si(2,7); eb[6]:=0;
   ep:=0; err:=0; do_let;
   ck((err=0) and (vars[0]=7), 3);
   { Test 4: PRINT A -> prints "7\n" }
   eb[0]:=VA; eb[1]:=0; ep:=0; err:=0; do_print;
   ck(err=0, 4);
   { Test 5: PRINT 2+3 -> prints "5\n" }
   si(0,2); eb[4]:=TP; si(5,3); eb[9]:=0;
   ep:=0; err:=0; do_print;
   ck(err=0, 5);
   { Test 6: PRINT "X=";A -> prints "X=7\n" }
   eb[0]:=TS; eb[1]:=2; eb[2]:=88; eb[3]:=61; eb[4]:=179;
   eb[5]:=VA; eb[6]:=0; ep:=0; err:=0; do_print;
   ck(err=0, 6);
   { Test 7: PRINT -5 }
   eb[0]:=TP+1; si(1,5); eb[5]:=0; ep:=0; err:=0; do_print;
   ck(err=0, 7);
   writeln(tf)
end.
