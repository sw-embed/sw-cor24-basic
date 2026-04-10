program BasicTokens;
{ COR24 BASIC v1 — Token definitions, keyword table, and detokenizer. }

const
   FIRST_KEYWORD = 128;
   LAST_KEYWORD  = 151;
   TOK_PLUS  = 160;
   TOK_GE    = 169;
   TOK_VAR_A = 192;
   TOK_VAR_Z = 217;
   TOK_INT   = 224;
   TOK_STR   = 225;
   KW_WIDTH  = 8;
   NUM_KW    = 24;

var
   kw_table: array[0..191] of char;

procedure kw_set(idx: integer; s0, s1, s2, s3, s4, s5, s6, s7: char);
var base: integer;
begin
   base := idx * KW_WIDTH;
   kw_table[base]     := s0;
   kw_table[base + 1] := s1;
   kw_table[base + 2] := s2;
   kw_table[base + 3] := s3;
   kw_table[base + 4] := s4;
   kw_table[base + 5] := s5;
   kw_table[base + 6] := s6;
   kw_table[base + 7] := s7
end;

procedure init_keywords;
begin
   kw_set( 0, 'L','E','T',' ',' ',' ',' ',' ');
   kw_set( 1, 'P','R','I','N','T',' ',' ',' ');
   kw_set( 2, 'I','N','P','U','T',' ',' ',' ');
   kw_set( 3, 'I','F',' ',' ',' ',' ',' ',' ');
   kw_set( 4, 'T','H','E','N',' ',' ',' ',' ');
   kw_set( 5, 'G','O','T','O',' ',' ',' ',' ');
   kw_set( 6, 'G','O','S','U','B',' ',' ',' ');
   kw_set( 7, 'R','E','T','U','R','N',' ',' ');
   kw_set( 8, 'F','O','R',' ',' ',' ',' ',' ');
   kw_set( 9, 'T','O',' ',' ',' ',' ',' ',' ');
   kw_set(10, 'S','T','E','P',' ',' ',' ',' ');
   kw_set(11, 'N','E','X','T',' ',' ',' ',' ');
   kw_set(12, 'S','T','O','P',' ',' ',' ',' ');
   kw_set(13, 'E','N','D',' ',' ',' ',' ',' ');
   kw_set(14, 'R','E','M',' ',' ',' ',' ',' ');
   kw_set(15, 'L','I','S','T',' ',' ',' ',' ');
   kw_set(16, 'R','U','N',' ',' ',' ',' ',' ');
   kw_set(17, 'N','E','W',' ',' ',' ',' ',' ');
   kw_set(18, 'S','A','V','E',' ',' ',' ',' ');
   kw_set(19, 'L','O','A','D',' ',' ',' ',' ');
   kw_set(20, 'B','Y','E',' ',' ',' ',' ',' ');
   kw_set(21, 'P','E','E','K',' ',' ',' ',' ');
   kw_set(22, 'P','O','K','E',' ',' ',' ',' ');
   kw_set(23, 'A','B','S',' ',' ',' ',' ',' ')
end;

function kw_len(idx: integer): integer;
var base, len: integer;
begin
   base := idx * KW_WIDTH;
   len := KW_WIDTH;
   while (len > 0) and (kw_table[base + len - 1] = ' ') do
      len := len - 1;
   kw_len := len
end;

function kw_char(idx, pos: integer): char;
begin
   kw_char := kw_table[idx * KW_WIDTH + pos]
end;

function is_keyword(tok: integer): boolean;
begin
   is_keyword := (tok >= FIRST_KEYWORD) and (tok <= LAST_KEYWORD)
end;

function is_operator(tok: integer): boolean;
begin
   is_operator := (tok >= TOK_PLUS) and (tok <= TOK_GE)
end;

function is_variable(tok: integer): boolean;
begin
   is_variable := (tok >= TOK_VAR_A) and (tok <= TOK_VAR_Z)
end;

function var_index(tok: integer): integer;
begin
   var_index := tok - TOK_VAR_A
   end;

function var_token(idx: integer): integer;
begin
   var_token := idx + TOK_VAR_A
   end;

procedure print_keyword(tok: integer);
var idx, len, j: integer;
begin
   idx := tok - FIRST_KEYWORD;
   len := kw_len(idx);
   j := 0;
   while j < len do
   begin
      write(kw_char(idx, j));
      j := j + 1
   end
end;

procedure print_operator(tok: integer);
begin
   if tok = TOK_PLUS   then write('+');
   if tok = TOK_PLUS+1 then write('-');
   if tok = TOK_PLUS+2 then write('*');
   if tok = TOK_PLUS+3 then write('/');
   if tok = TOK_PLUS+4 then write('=');
   if tok = TOK_PLUS+5 then begin write('<'); write('>') end;
   if tok = TOK_PLUS+6 then write('<');
   if tok = TOK_PLUS+7 then begin write('<'); write('=') end;
   if tok = TOK_PLUS+8 then write('>');
   if tok = TOK_GE     then begin write('>'); write('=') end
end;

procedure print_variable(tok: integer);
var ch: char;
begin
   ch := chr(ord('A') + tok - TOK_VAR_A);
   write(ch)
end;

begin
   init_keywords;
   { Keyword table }
   if kw_len(0) = 3 then write('P') else write('F');
   writeln(1);
   if kw_len(1) = 5 then write('P') else write('F');
   writeln(2);
   if is_keyword(128) then write('P') else write('F');
   writeln(3);
   if is_variable(192) then write('P') else write('F');
   writeln(4);
   if var_index(217) = 25 then write('P') else write('F');
      writeln(5);
      { Detokenizer }
      print_keyword(129);
      writeln(0);
      print_operator(167);
      writeln(0)
   end.
