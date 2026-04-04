program BasicMinimal;
{ Minimal test using only Phase 0 features (no procedures/arrays).
  Validates the pipeline works today: p24p -> pl24r -> pa24r -> pvm.s }
var
  i, sum: integer;
  ch: integer;
begin
  { Test 1: Arithmetic }
  sum := 0;
  i := 1;
  while i <= 10 do
  begin
    sum := sum + i;
    i := i + 1
  end;
  if sum = 55 then
    writeln('PASS 1')
  else
    writeln('FAIL 1');

  { Test 2: Char-range arithmetic (integer stand-in) }
  ch := 66;     { 'B' = 65 + 1 }
  if (ch >= 65) and (ch <= 90) then
    writeln('PASS 2')
  else
    writeln('FAIL 2');

  { Test 3: Nested if/while }
  i := 0;
  sum := 0;
  while i < 20 do
  begin
    if i mod 2 = 0 then
      sum := sum + 1;
    i := i + 1
  end;
  if sum = 10 then
    writeln('PASS 3')
  else
    writeln('FAIL 3');

  writeln('DONE')
end.
