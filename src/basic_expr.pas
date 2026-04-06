program BasicExpr;
{ COR24 BASIC v1 — Expression parser + variable table.
  Single recursive procedure with precedence levels.
  Level 0=primary, 1=unary, 2=term, 3=add, 4=comparison }
const
  FK=128; TP=160; TG=169; VA=192; TI=224;
var
  eb: array[0..127] of integer;
  ep,err,ev: integer;
  vars: array[0..25] of integer;
  tf: integer;

procedure vars_clear;
var i:integer;
begin i:=0; while i<26 do begin vars[i]:=0; i:=i+1 end end;

procedure p_expr(lev: integer);
{ Recursive descent with level parameter.
  lev=0: primary, lev=1: unary, lev=2: term(*,/),
  lev=3: addition(+,-), lev=4: comparison }
var v,op,r:integer; b:boolean;
begin
  if lev=0 then begin { primary }
    v:=0;
    if eb[ep]=TI then begin
      ep:=ep+1; v:=eb[ep]*65536+eb[ep+1]*256+eb[ep+2]; ep:=ep+3
    end
    else if(eb[ep]>=VA)and(eb[ep]<=VA+25)then begin v:=vars[eb[ep]-VA]; ep:=ep+1 end
    else if eb[ep]=176 then begin
      ep:=ep+1; p_expr(4); v:=ev;
      if(err=0)and(eb[ep]=177)then ep:=ep+1 else if err=0 then err:=1
    end
    else if eb[ep]=FK+21 then begin { PEEK }
      ep:=ep+1;
      if eb[ep]=176 then begin ep:=ep+1; p_expr(4); v:=peek(ev);
        if(err=0)and(eb[ep]=177)then ep:=ep+1 else if err=0 then err:=1
      end else err:=1
    end
    else if eb[ep]=FK+23 then begin { ABS }
      ep:=ep+1;
      if eb[ep]=176 then begin ep:=ep+1; p_expr(4); v:=ev;
        if v<0 then v:=0-v;
        if(err=0)and(eb[ep]=177)then ep:=ep+1 else if err=0 then err:=1
      end else err:=1
    end
    else err:=1;
    ev:=v
  end
  else if lev=1 then begin { unary }
    if eb[ep]=TP+1 then begin ep:=ep+1; p_expr(1); ev:=0-ev end
    else if eb[ep]=TP then begin ep:=ep+1; p_expr(1) end
    else p_expr(0)
  end
  else if lev=2 then begin { term: * / }
    p_expr(1); v:=ev;
    while(err=0)and((eb[ep]=TP+2)or(eb[ep]=TP+3))do begin
      op:=eb[ep]; ep:=ep+1; p_expr(1); r:=ev;
      if op=TP+2 then v:=v*r
      else if r<>0 then v:=v div r
      else err:=5
    end;
    ev:=v
  end
  else if lev=3 then begin { addition: + - }
    p_expr(2); v:=ev;
    while(err=0)and((eb[ep]=TP)or(eb[ep]=TP+1))do begin
      op:=eb[ep]; ep:=ep+1; p_expr(2); r:=ev;
      if op=TP then v:=v+r else v:=v-r
    end;
    ev:=v
  end
  else begin { lev=4: comparison }
    p_expr(3); v:=ev;
    while(err=0)and(eb[ep]>=TP+4)and(eb[ep]<=TG)do begin
      op:=eb[ep]; ep:=ep+1; p_expr(3); r:=ev; b:=false;
      if op=TP+4 then b:=(v=r)
      else if op=TP+5 then b:=(v<>r)
      else if op=TP+6 then b:=(v<r)
      else if op=TP+7 then b:=(v<=r)
      else if op=TP+8 then b:=(v>r)
      else if op=TG then b:=(v>=r);
      if b then v:=1 else v:=0
    end;
    ev:=v
  end
end;

function eval:integer;
begin ep:=0;err:=0; p_expr(4); eval:=ev end;

procedure ck(ok:boolean;id:integer);
begin if ok then write('P')else begin write('F');tf:=tf+1 end;writeln(id)end;
procedure si(p,v:integer);
begin eb[p]:=TI;eb[p+1]:=(v div 65536)mod 256;eb[p+2]:=(v div 256)mod 256;eb[p+3]:=v mod 256 end;

begin
  vars_clear; tf:=0;
  si(0,42);eb[4]:=0; ck(eval=42,1);
  si(0,3);eb[4]:=TP;si(5,5);eb[9]:=0; ck(eval=8,2);
  si(0,10);eb[4]:=TP+1;si(5,3);eb[9]:=0; ck(eval=7,3);
  si(0,4);eb[4]:=TP+2;si(5,5);eb[9]:=0; ck(eval=20,4);
  si(0,15);eb[4]:=TP+3;si(5,3);eb[9]:=0; ck(eval=5,5);
  si(0,2);eb[4]:=TP;si(5,3);eb[9]:=TP+2;si(10,4);eb[14]:=0; ck(eval=14,6);
  eb[0]:=TP+1;si(1,5);eb[5]:=0; ck(eval=-5,7);
  vars[0]:=10;eb[0]:=VA;eb[1]:=0; ck(eval=10,8);
  si(0,5);eb[4]:=TP+4;si(5,5);eb[9]:=0; ck(eval=1,9);
  si(0,5);eb[4]:=TP+6;si(5,3);eb[9]:=0; ck(eval=0,10);
  eb[0]:=176;si(1,2);eb[5]:=TP;si(6,3);eb[10]:=177;
  eb[11]:=TP+2;si(12,4);eb[16]:=0; ck(eval=20,11);
  si(0,5);eb[4]:=TP+3;si(5,0);eb[9]:=0;ep:=0;err:=0;p_expr(4);
  ck(err=5,12);
  writeln(tf)
end.
