program BasicStore;
{ COR24 BASIC v1 — Program store. Packed sorted buffer of tokenized lines.
  Each line: [line_hi][line_lo][len][tok0..tokN] where line# = hi*256+lo.
  Lines sorted by line number. Insert/delete shifts subsequent bytes. }
const
  PS=4096; { program store size in bytes }
var
  pg: array[0..4095] of char; { program store }
  pe: integer; { end pointer (next free byte) }
  si_tb: array[0..127] of integer; { insert token buffer (global for store_insert) }
  si_len: integer;
  tf, tp: integer; { test vars }

procedure store_init;
begin pe := 0 end;

function pg_line(p: integer): integer;
{ Read line number at offset p }
begin pg_line := ord(pg[p])*256 + ord(pg[p+1]) end;

function pg_len(p: integer): integer;
{ Read token length at offset p (after 2-byte line number) }
begin pg_len := ord(pg[p+2]) end;

function pg_size(p: integer): integer;
{ Total bytes for entry at p: 2 (line#) + 1 (len) + len (tokens) }
begin pg_size := 3 + ord(pg[p+2]) end;

function store_find(ln: integer): integer;
var p,n,r: integer; done: boolean;
begin
  p := 0; r := -1; done := false;
  while (p < pe) and (not done) do
  begin
    n := pg_line(p);
    if n = ln then begin r := p; done := true end
    else if n > ln then done := true
    else p := p + pg_size(p)
  end;
  store_find := r
end;

function store_find_insert(ln: integer): integer;
var p: integer; done: boolean;
begin
  p := 0; done := false;
  while (p < pe) and (not done) do
  begin
    if pg_line(p) >= ln then done := true
    else p := p + pg_size(p)
  end;
  store_find_insert := p
end;

procedure store_delete(ln: integer);
{ Delete line with number ln. No-op if not found. }
var p, sz, i: integer;
begin
  p := store_find(ln);
  if p >= 0 then
  begin
    sz := pg_size(p);
    i := p;
    while i + sz < pe do
    begin pg[i] := pg[i + sz]; i := i + 1 end;
    pe := pe - sz
  end
end;

procedure store_insert(ln: integer);
var p, sz, i, need: integer;
begin
  store_delete(ln);
  need := 3 + si_len;
  if pe + need <= PS then
  begin
    p := store_find_insert(ln);
    i := pe - 1;
    while i >= p do
    begin pg[i + need] := pg[i]; i := i - 1 end;
    pg[p] := chr(ln div 256);
    pg[p+1] := chr(ln mod 256);
    pg[p+2] := chr(si_len);
    i := 0;
    while i < si_len do
    begin pg[p + 3 + i] := chr(si_tb[i]); i := i + 1 end;
    pe := pe + need
  end
end;

function store_next(p: integer): integer;
{ Advance past current entry. Returns next offset or pe if at end. }
begin store_next := p + pg_size(p) end;

function store_count: integer;
{ Count stored lines }
var p, n: integer;
begin
  p := 0; n := 0;
  while p < pe do begin n := n + 1; p := p + pg_size(p) end;
  store_count := n
end;

procedure ck(ok:boolean;id:integer);
begin if ok then write('P')else begin write('F');tf:=tf+1 end;writeln(id)end;
begin
  store_init; tf:=0;
  si_tb[0]:=129;si_tb[1]:=225;si_tb[2]:=0;si_len:=3;
  store_insert(20);
  ck(store_count=1,1); ck(store_find(20)=0,2);
  ck(pg_line(0)=20,3); ck(pg_len(0)=3,4);
  si_tb[0]:=141;si_tb[1]:=0;si_len:=2;
  store_insert(10);
  ck(store_count=2,5); ck(store_find(10)=0,6);
  tp:=store_find(20); ck(tp=5,7); ck(pg_line(tp)=20,8);
  si_tb[0]:=140;si_tb[1]:=0;si_len:=2;
  store_insert(30);
  ck(store_count=3,9);
  store_delete(20);
  ck(store_count=2,10); ck(store_find(20)=-1,11);
  ck(store_find(10)=0,12); ck(store_find(30)>=0,13);
  si_tb[0]:=128;si_tb[1]:=0;si_len:=2;
  store_insert(10);
  ck(store_count=2,14);
  tp:=store_find(10); ck(ord(pg[tp+3])=128,15);
  tp:=0; tp:=store_next(tp); ck(pg_line(tp)=30,16);
  writeln(tf)
end.
