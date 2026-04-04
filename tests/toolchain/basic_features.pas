program BasicFeatures;
{ Toolchain validation: exercises p24p features that the BASIC
  interpreter requires.  Each section prints PASS/FAIL so we can
  verify the full pipeline: p24p -> pl24r -> pa24r -> pvm.s }

var
  buf: array[0..9] of integer;   { arrays }
  i, j, tmp: integer;

{ --- Procedures --- }

procedure FillBuf(n: integer);
var k: integer;
begin
  k := 0;
  while k < n do
  begin
    buf[k] := k * 10;
    k := k + 1
  end
end;

function SumBuf(n: integer): integer;
var k, s: integer;
begin
  s := 0;
  k := 0;
  while k < n do
  begin
    s := s + buf[k];
    k := k + 1
  end;
  SumBuf := s
end;

function IsUpper(ch: integer): integer;
{ Checks if ch is an uppercase ASCII letter (65..90).
  Uses integer because p24p may not have char type yet. }
begin
  if (ch >= 65) and (ch <= 90) then
    IsUpper := 1
  else
    IsUpper := 0
end;

procedure PrintResult(ok: boolean; tag: integer);
begin
  if ok then
    write('PASS ')
  else
    write('FAIL ');
  writeln(tag)
end;

{ --- Main --- }

begin
  { Test 1: Array fill and sum via procedures }
  FillBuf(5);
  PrintResult(SumBuf(5) = 100, 1);   { 0+10+20+30+40 = 100 }

  { Test 2: Array element access }
  PrintResult(buf[3] = 30, 2);

  { Test 3: Char-range check via function }
  PrintResult(IsUpper(65) = 1, 3);    { 'A' }
  PrintResult(IsUpper(97) = 0, 4);    { 'a' }

  { Test 4: Nested control flow with procedure calls }
  i := 0;
  j := 0;
  while i < 5 do
  begin
    if IsUpper(65 + i) = 1 then
      j := j + 1;
    i := i + 1
  end;
  PrintResult(j = 5, 5);

  { Test 6: Local variables in nested calls }
  buf[0] := 1;
  buf[1] := 2;
  buf[2] := 3;
  PrintResult(SumBuf(3) = 6, 6);

  writeln('DONE')
end.
