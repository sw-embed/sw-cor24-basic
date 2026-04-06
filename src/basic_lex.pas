program BasicLex;
const FK=128;LK=151;TP=160;TG=169;VA=192;TI=224;TS=225;KW=8;NK=24;MT=128;
var kt:array[0..191] of char; lb:array[0..79] of char; ll,lp:integer;
  tb:array[0..127] of integer; tl,tn:integer;
procedure ks(i:integer;a,b,c,d,e,f,g,h:char);
var p:integer;
begin p:=i*KW;kt[p]:=a;kt[p+1]:=b;kt[p+2]:=c;kt[p+3]:=d;kt[p+4]:=e;kt[p+5]:=f;kt[p+6]:=g;kt[p+7]:=h end;
procedure ik;
begin
ks(0,'L','E','T',' ',' ',' ',' ',' ');ks(1,'P','R','I','N','T',' ',' ',' ');
ks(2,'I','N','P','U','T',' ',' ',' ');ks(3,'I','F',' ',' ',' ',' ',' ',' ');
ks(4,'T','H','E','N',' ',' ',' ',' ');ks(5,'G','O','T','O',' ',' ',' ',' ');
ks(6,'G','O','S','U','B',' ',' ',' ');ks(7,'R','E','T','U','R','N',' ',' ');
ks(8,'F','O','R',' ',' ',' ',' ',' ');ks(9,'T','O',' ',' ',' ',' ',' ',' ');
ks(10,'S','T','E','P',' ',' ',' ',' ');ks(11,'N','E','X','T',' ',' ',' ',' ');
ks(12,'S','T','O','P',' ',' ',' ',' ');ks(13,'E','N','D',' ',' ',' ',' ',' ');
ks(14,'R','E','M',' ',' ',' ',' ',' ');ks(15,'L','I','S','T',' ',' ',' ',' ');
ks(16,'R','U','N',' ',' ',' ',' ',' ');ks(17,'N','E','W',' ',' ',' ',' ',' ');
ks(18,'S','A','V','E',' ',' ',' ',' ');ks(19,'L','O','A','D',' ',' ',' ',' ');
ks(20,'B','Y','E',' ',' ',' ',' ',' ');ks(21,'P','E','E','K',' ',' ',' ',' ');
ks(22,'P','O','K','E',' ',' ',' ',' ');ks(23,'A','B','S',' ',' ',' ',' ',' ')
end;
function kl(i:integer):integer;
var p,n:integer;
begin p:=i*KW;n:=KW;while(n>0)and(kt[p+n-1]=' ')do n:=n-1;kl:=n end;
function uc(c:char):char;
begin if(c>='a')and(c<='z')then uc:=chr(ord(c)-32) else uc:=c end;
function dg(c:char):boolean; begin dg:=(c>='0')and(c<='9') end;
function lt(c:char):boolean; var u:char; begin u:=uc(c);lt:=(u>='A')and(u<='Z') end;
procedure em(v:integer); begin if tl<MT then begin tb[tl]:=v;tl:=tl+1 end end;
procedure ss; begin while(lp<ll)and((lb[lp]=' ')or(lb[lp]=chr(9)))do lp:=lp+1 end;
function pi:integer; var n:integer;
begin n:=0;while(lp<ll)and dg(lb[lp])do begin n:=n*10+ord(lb[lp])-48;lp:=lp+1 end;pi:=n end;
function tk:integer;
var b,bl,i,n,j:integer;ok:boolean;u:char;
begin b:=-1;bl:=0;i:=0;
while i<NK do begin n:=kl(i);
if(n>bl)and(lp+n<=ll)then begin ok:=true;j:=0;
while ok and(j<n)do begin u:=uc(lb[lp+j]);if u<>kt[i*KW+j]then ok:=false;j:=j+1 end;
if ok and(lp+n<ll)then begin u:=uc(lb[lp+n]);if lt(u)or dg(u)then ok:=false end;
if ok then begin b:=i;bl:=n end end;i:=i+1 end;
if b>=0 then lp:=lp+bl;tk:=b end;
procedure tokenize;
var c:char;k,n:integer;
begin tl:=0;lp:=0;tn:=-1;ss;
if(lp<ll)and dg(lb[lp])then begin tn:=pi;ss end;
while lp<ll do begin ss;if lp<ll then begin c:=lb[lp];k:=tk;
if k>=0 then begin em(FK+k);
if k=14 then begin em(TS);n:=ll-lp;em(n);while lp<ll do begin em(ord(lb[lp]));lp:=lp+1 end end
end
else if c='"'then begin lp:=lp+1;em(TS);n:=tl;em(0);k:=0;
while(lp<ll)and(lb[lp]<>'"')do begin em(ord(lb[lp]));lp:=lp+1;k:=k+1 end;
tb[n]:=k;if(lp<ll)and(lb[lp]='"')then lp:=lp+1 end
else if dg(c)then begin n:=pi;em(TI);em((n div 65536)mod 256);em((n div 256)mod 256);em(n mod 256)end
else if lt(c)then begin em(VA+ord(uc(c))-65);lp:=lp+1 end
else if(c='<')and(lp+1<ll)and(lb[lp+1]='>')then begin em(TP+5);lp:=lp+2 end
else if(c='<')and(lp+1<ll)and(lb[lp+1]='=')then begin em(TP+7);lp:=lp+2 end
else if(c='>')and(lp+1<ll)and(lb[lp+1]='=')then begin em(TG);lp:=lp+2 end
else if c='+'then begin em(TP);lp:=lp+1 end
else if c='-'then begin em(TP+1);lp:=lp+1 end
else if c='*'then begin em(TP+2);lp:=lp+1 end
else if c='/'then begin em(TP+3);lp:=lp+1 end
else if c='='then begin em(TP+4);lp:=lp+1 end
else if c='<'then begin em(TP+6);lp:=lp+1 end
else if c='>'then begin em(TP+8);lp:=lp+1 end
else if c='('then begin em(176);lp:=lp+1 end
else if c=')'then begin em(177);lp:=lp+1 end
else if c=','then begin em(178);lp:=lp+1 end
else if c=';'then begin em(179);lp:=lp+1 end
else lp:=lp+1 end end;em(0) end;
begin ik;
lb[0]:='P';lb[1]:='R';lb[2]:='I';lb[3]:='N';lb[4]:='T';ll:=5;tokenize;
if(tb[0]=129)and(tb[1]=0)then writeln(1)else writeln(0);
lb[0]:='1';lb[1]:='0';lb[2]:=' ';lb[3]:='E';lb[4]:='N';lb[5]:='D';ll:=6;tokenize;
if(tn=10)and(tb[0]=141)then writeln(1)else writeln(0);
lb[0]:='A';lb[1]:='=';lb[2]:='5';ll:=3;tokenize;
if(tb[0]=192)and(tb[1]=164)and(tb[2]=224)then writeln(1)else writeln(0)
end.
