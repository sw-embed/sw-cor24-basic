program Basic;
const
   FK=128;TP=160;TG=169;VA=192;TI=224;TS=225;KW=6;NK=25;PS=16384;
var
   kt:array[0..149]of char;
   lb:array[0..79]of char;
   ll,lp:integer;
   tb:array[0..127]of integer;
   tl,tn:integer;
   pg:array[0..16383]of char;
   pe:integer;
   ep,err,ev:integer;
   vars:array[0..25]of integer;
   pid:array[0..9]of integer;
   gs:array[0..63]of integer;
   um:array[0..1023]of integer;
   fv:array[0..15]of integer;
   fl:array[0..15]of integer;
   fs:array[0..15]of integer;
   fr:array[0..15]of integer;
   gp,fp,col,pok,el,running,mi:integer;
procedure ks(i:integer;a,b,c,d,e,f:char);
var p:integer;
begin p:=i*KW;kt[p]:=a;kt[p+1]:=b;kt[p+2]:=c;kt[p+3]:=d;kt[p+4]:=e;kt[p+5]:=f end;
procedure ik;
begin
   ks(0,'L','E','T',' ',' ',' ');ks(1,'P','R','I','N','T',' ');
   ks(2,'I','N','P','U','T',' ');
   ks(3,'I','F',' ',' ',' ',' ');ks(4,'T','H','E','N',' ',' ');
   ks(5,'G','O','T','O',' ',' ');ks(6,'G','O','S','U','B',' ');
   ks(7,'R','E','T','U','R','N');ks(8,'F','O','R',' ',' ',' ');
   ks(9,'T','O',' ',' ',' ',' ');ks(10,'S','T','E','P',' ',' ');
   ks(11,'N','E','X','T',' ',' ');ks(12,'S','T','O','P',' ',' ');
   ks(13,'E','N','D',' ',' ',' ');ks(14,'R','E','M',' ',' ',' ');
   ks(15,'L','I','S','T',' ',' ');ks(16,'R','U','N',' ',' ',' ');
   ks(17,'N','E','W',' ',' ',' ');
   ks(18,'A','N','D',' ',' ',' ');ks(19,'O','R',' ',' ',' ',' ');
   ks(20,'B','Y','E',' ',' ',' ');ks(21,'P','E','E','K',' ',' ');
   ks(22,'P','O','K','E',' ',' ');ks(23,'A','B','S',' ',' ',' ');
   ks(24,'C','H','R','$',' ',' ')
end;
function kl(i:integer):integer;
var p,n:integer;
begin p:=i*KW;n:=KW;while(n>0)and(kt[p+n-1]=' ')do n:=n-1;kl:=n end;
procedure tokenize;
var c,u:char;k,n,j,b,bl:integer;ok:boolean;
begin tl:=0;lp:=0;tn:=-1;
   while(lp<ll)and((lb[lp]=' ')or(lb[lp]=chr(9)))do lp:=lp+1;
   if(lp<ll)and(lb[lp]>='0')and(lb[lp]<='9')then begin
      n:=0;while(lp<ll)and(lb[lp]>='0')and(lb[lp]<='9')do begin n:=n*10+ord(lb[lp])-48;lp:=lp+1 end;
      tn:=n;while(lp<ll)and((lb[lp]=' ')or(lb[lp]=chr(9)))do lp:=lp+1 end;
   while lp<ll do begin
      while(lp<ll)and((lb[lp]=' ')or(lb[lp]=chr(9)))do lp:=lp+1;
      if lp<ll then begin c:=lb[lp];
	 b:=-1;bl:=0;k:=0;
	 while k<NK do begin n:=kl(k);
	    if(n>bl)and(lp+n<=ll)then begin ok:=true;j:=0;
	       while ok and(j<n)do begin
		  u:=lb[lp+j];if(u>='a')and(u<='z')then u:=chr(ord(u)-32);
		  if u<>kt[k*KW+j]then ok:=false;j:=j+1 end;
	       if ok and(lp+n<ll)then begin u:=lb[lp+n];if(u>='a')and(u<='z')then u:=chr(ord(u)-32);
		  if((u>='A')and(u<='Z'))or((u>='0')and(u<='9'))then ok:=false end;
	       if ok then begin b:=k;bl:=n end end;k:=k+1 end;
	 if b>=0 then begin lp:=lp+bl;
	    tb[tl]:=FK+b;tl:=tl+1;
	    if b=14 then begin tb[tl]:=TS;tl:=tl+1;
	       n:=ll-lp;tb[tl]:=n;tl:=tl+1;
	       while lp<ll do begin tb[tl]:=ord(lb[lp]);tl:=tl+1;lp:=lp+1 end end end
      else if c='"'then begin lp:=lp+1;tb[tl]:=TS;tl:=tl+1;
	 n:=tl;tb[tl]:=0;tl:=tl+1;k:=0;
	 while(lp<ll)and(lb[lp]<>'"')do begin tb[tl]:=ord(lb[lp]);tl:=tl+1;lp:=lp+1;k:=k+1 end;
	 tb[n]:=k;if(lp<ll)and(lb[lp]='"')then lp:=lp+1 end
      else if(c>='0')and(c<='9')then begin
	 n:=0;while(lp<ll)and(lb[lp]>='0')and(lb[lp]<='9')do begin n:=n*10+ord(lb[lp])-48;lp:=lp+1 end;
	 tb[tl]:=TI;tl:=tl+1;
	 tb[tl]:=(n div 65536)mod 256;tl:=tl+1;
	 tb[tl]:=(n div 256)mod 256;tl:=tl+1;
	 tb[tl]:=n mod 256;tl:=tl+1 end
      else begin u:=c;if(u>='a')and(u<='z')then u:=chr(ord(u)-32);
	 if(u>='A')and(u<='Z')then begin tb[tl]:=VA+ord(u)-65;tl:=tl+1;lp:=lp+1 end
      else if(c='<')and(lp+1<ll)and(lb[lp+1]='>')then begin tb[tl]:=TP+5;tl:=tl+1;lp:=lp+2 end
      else if(c='<')and(lp+1<ll)and(lb[lp+1]='=')then begin tb[tl]:=TP+7;tl:=tl+1;lp:=lp+2 end
      else if(c='>')and(lp+1<ll)and(lb[lp+1]='=')then begin tb[tl]:=TG;tl:=tl+1;lp:=lp+2 end
      else begin
	 if c='+'then n:=TP else if c='-'then n:=TP+1 else if c='*'then n:=TP+2
	 else if c='/'then n:=TP+3 else if c='='then n:=TP+4
	 else if c='<'then n:=TP+6 else if c='>'then n:=TP+8
	 else if c='('then n:=176 else if c=')'then n:=177
	 else if c=','then n:=178 else if c=';'then n:=179
	 else n:=-1;
	 if n>=0 then begin tb[tl]:=n;tl:=tl+1 end;
	 lp:=lp+1 end end end end;
   tb[tl]:=0;tl:=tl+1 end;
function store_find(ln:integer):integer;
var p,n,r:integer;d:boolean;
begin p:=0;r:=-1;d:=false;
   while(p<pe)and(not d)do begin n:=ord(pg[p])*256+ord(pg[p+1]);
      if n=ln then begin r:=p;d:=true end else if n>ln then d:=true
      else p:=p+3+ord(pg[p+2]) end;store_find:=r end;
procedure store_ins(ln:integer);
var p,i,need,sz:integer;d:boolean;
begin p:=store_find(ln);if p>=0 then begin sz:=3+ord(pg[p+2]);i:=p;
   while i+sz<pe do begin pg[i]:=pg[i+sz];i:=i+1 end;pe:=pe-sz end;
   need:=3+tl;if pe+need<=PS then begin
      p:=0;d:=false;while(p<pe)and(not d)do begin
	 if ord(pg[p])*256+ord(pg[p+1])>=ln then d:=true else p:=p+3+ord(pg[p+2]) end;
      i:=pe-1;while i>=p do begin pg[i+need]:=pg[i];i:=i-1 end;
      pg[p]:=chr(ln div 256);pg[p+1]:=chr(ln mod 256);pg[p+2]:=chr(tl);
      i:=0;while i<tl do begin pg[p+3+i]:=chr(tb[i]);i:=i+1 end;pe:=pe+need end end;
procedure p_expr(lev:integer);
var v,op,r:integer;b:boolean;
begin
   if lev=0 then begin v:=0;
      if tb[ep]=TI then begin ep:=ep+1;v:=tb[ep]*65536+tb[ep+1]*256+tb[ep+2];ep:=ep+3 end
   else if(tb[ep]>=VA)and(tb[ep]<=VA+25)then begin v:=vars[tb[ep]-VA];ep:=ep+1 end
   else if tb[ep]=176 then begin ep:=ep+1;p_expr(5);v:=ev;
      if(err=0)and(tb[ep]=177)then ep:=ep+1 else if err=0 then err:=1 end
   else if tb[ep]=FK+21 then begin ep:=ep+1;
      if tb[ep]=176 then begin ep:=ep+1;p_expr(5);
	 if(ev>=0)and(ev<1024)then v:=um[ev] else v:=peek(ev);
	 if(err=0)and(tb[ep]=177)then ep:=ep+1 else if err=0 then err:=1
      end else err:=1 end
   else if tb[ep]=FK+23 then begin ep:=ep+1;
      if tb[ep]=176 then begin ep:=ep+1;p_expr(5);v:=ev;
	 if v<0 then v:=0-v;
	 if(err=0)and(tb[ep]=177)then ep:=ep+1 else if err=0 then err:=1
      end else err:=1 end
   else err:=1;ev:=v end
else if lev=1 then begin
   if tb[ep]=TP+1 then begin ep:=ep+1;p_expr(1);ev:=0-ev end
else if tb[ep]=TP then begin ep:=ep+1;p_expr(1) end
else p_expr(0) end
else if lev=2 then begin p_expr(1);v:=ev;
   while(err=0)and((tb[ep]=TP+2)or(tb[ep]=TP+3))do begin
      op:=tb[ep];ep:=ep+1;p_expr(1);r:=ev;
      if op=TP+2 then v:=v*r else if r<>0 then v:=v div r else err:=5 end;ev:=v end
else if lev=3 then begin p_expr(2);v:=ev;
   while(err=0)and((tb[ep]=TP)or(tb[ep]=TP+1))do begin
      op:=tb[ep];ep:=ep+1;p_expr(2);r:=ev;
      if op=TP then v:=v+r else v:=v-r end;ev:=v end
else if lev=4 then begin p_expr(3);v:=ev;
   while(err=0)and(tb[ep]>=TP+4)and(tb[ep]<=TG)do begin
      op:=tb[ep];ep:=ep+1;p_expr(3);r:=ev;b:=false;
      if op=TP+4 then b:=(v=r) else if op=TP+5 then b:=(v<>r)
      else if op=TP+6 then b:=(v<r) else if op=TP+7 then b:=(v<=r)
      else if op=TP+8 then b:=(v>r) else if op=TG then b:=(v>=r);
      if b then v:=1 else v:=0 end;ev:=v end
else begin p_expr(4);v:=ev;
   while(err=0)and((tb[ep]=FK+18)or(tb[ep]=FK+19))do begin
      op:=tb[ep];ep:=ep+1;p_expr(4);r:=ev;
      if op=FK+18 then begin if(v<>0)and(r<>0)then v:=1 else v:=0 end
      else begin if(v<>0)or(r<>0)then v:=1 else v:=0 end end;ev:=v end
end;
procedure pc(c:char);
begin writechar(c);col:=col+1 end;
procedure pn;
begin writeln;col:=0 end;
procedure pt;
var k:integer;
begin if col>=70 then pn else begin k:=14-(col-(col div 14)*14);
   while k>0 do begin pc(' ');k:=k-1 end end end;
procedure print_int(n:integer);
var i,nd:integer;
begin if n<0 then begin pc('-');n:=0-n end;
   if n=0 then pc('0')
   else begin nd:=0;while n>0 do begin pid[nd]:=n mod 10;nd:=nd+1;n:=n div 10 end;
      i:=nd-1;while i>=0 do begin pc(chr(pid[i]+48));i:=i-1 end end end;
procedure read_line;
var c:integer;
begin ll:=0;readln(c);
   while(c<>10)and(c<>13)and(c<>4)and(c<>29)and(c>=0)and(ll<80)do
   begin lb[ll]:=chr(c);ll:=ll+1;readln(c) end;
   if(c=4)or(c=29)or(c<0)then begin pn;running:=0;ll:=0 end end;
procedure pi;
var i,n,s:integer;
begin
   i:=0;while(i<ll)and((lb[i]=' ')or(lb[i]=chr(9)))do i:=i+1;
   s:=1;
   if(i<ll)and(lb[i]='-')then begin s:=-1;i:=i+1 end
else if(i<ll)and(lb[i]='+')then i:=i+1;
   n:=0;pok:=0;
   while(i<ll)and(lb[i]>='0')and(lb[i]<='9')do
   begin n:=n*10+ord(lb[i])-48;i:=i+1;pok:=1 end;
   ev:=n*s end;
procedure do_print;
var dn,nl,n,i:integer;
begin dn:=0;nl:=1;
   if tb[ep]=0 then begin pn;dn:=1;nl:=0 end;
   while(err=0)and(dn=0)do begin
      if tb[ep]=TS then begin ep:=ep+1;n:=tb[ep];ep:=ep+1;i:=0;
	 while i<n do begin pc(chr(tb[ep]));ep:=ep+1;i:=i+1 end end
   else if tb[ep]=FK+24 then begin ep:=ep+1;
      if tb[ep]=176 then begin ep:=ep+1;p_expr(5);
	 if(err=0)and(tb[ep]=177)then begin ep:=ep+1;pc(chr(ev)) end
	 else if err=0 then err:=1
      end else err:=1 end
   else begin p_expr(5);if err=0 then print_int(ev) end;
      if err<>0 then dn:=1
      else if tb[ep]=179 then begin ep:=ep+1;
	 if tb[ep]=0 then begin nl:=0;dn:=1 end end
   else if tb[ep]=178 then begin ep:=ep+1;pt;
      if tb[ep]=0 then begin nl:=0;dn:=1 end end
   else dn:=1 end;
   if(err=0)and(nl=1)then pn end;
procedure do_let;
var vi:integer;
begin if(tb[ep]>=VA)and(tb[ep]<=VA+25)then begin vi:=tb[ep]-VA;ep:=ep+1;
   if tb[ep]=TP+4 then begin ep:=ep+1;p_expr(5);vars[vi]:=ev end else err:=1
end else err:=1 end;
procedure do_list;
var p,n,ln,j,tk,k,kn,i,lc:integer;rem:boolean;
begin p:=0;
   while p<pe do begin
      ln:=ord(pg[p])*256+ord(pg[p+1]);n:=ord(pg[p+2]);
      print_int(ln);pc(' ');rem:=false;lc:=0;j:=0;
      while j<n do begin tk:=ord(pg[p+3+j]);
	 if(tk>=FK)and(tk<FK+NK)then begin k:=tk-FK;kn:=kl(k);
	    if lc=1 then pc(' ');
	    i:=0;while i<kn do begin pc(kt[k*KW+i]);i:=i+1 end;
	    if k=14 then rem:=true;
	    lc:=1;j:=j+1 end
      else if tk=TS then begin j:=j+1;kn:=ord(pg[p+3+j]);j:=j+1;
	 if(lc=1)and(not rem)then pc(' ');
	 if not rem then pc('"');
	 i:=0;while i<kn do begin pc(chr(ord(pg[p+3+j])));j:=j+1;i:=i+1 end;
	 if not rem then pc('"');rem:=false;lc:=0 end
      else if tk=TI then begin j:=j+1;
	 if lc=1 then pc(' ');
	 ln:=ord(pg[p+3+j])*65536+ord(pg[p+3+j+1])*256+ord(pg[p+3+j+2]);
	 print_int(ln);j:=j+3;lc:=1 end
      else if(tk>=VA)and(tk<=VA+25)then begin
	 if lc=1 then pc(' ');
	 pc(chr(65+tk-VA));j:=j+1;lc:=1 end
      else if tk=176 then begin pc('(');j:=j+1;lc:=0 end
      else if tk=177 then begin pc(')');j:=j+1;lc:=0 end
      else if tk=178 then begin pc(',');j:=j+1;lc:=0 end
      else if tk=179 then begin pc(';');j:=j+1;lc:=0 end
      else if tk=TP then begin pc('+');j:=j+1;lc:=0 end
      else if tk=TP+1 then begin pc('-');j:=j+1;lc:=0 end
      else if tk=TP+2 then begin pc('*');j:=j+1;lc:=0 end
      else if tk=TP+3 then begin pc('/');j:=j+1;lc:=0 end
      else if tk=TP+4 then begin pc('=');j:=j+1;lc:=0 end
      else if tk=TP+5 then begin pc('<');pc('>');j:=j+1;lc:=0 end
      else if tk=TP+6 then begin pc('<');j:=j+1;lc:=0 end
      else if tk=TP+7 then begin pc('<');pc('=');j:=j+1;lc:=0 end
      else if tk=TP+8 then begin pc('>');j:=j+1;lc:=0 end
      else if tk=TG then begin pc('>');pc('=');j:=j+1;lc:=0 end
      else j:=j+1
      end;pn;p:=p+3+n end end;
procedure dispatch;
var t,rd,vi,n,i:integer;
begin ep:=0;err:=0;rd:=1;
   while(rd=1)and(err=0)do begin rd:=0;t:=tb[ep];
      if t=0 then begin end
   else if t=FK then begin ep:=ep+1;do_let end
   else if t=FK+1 then begin ep:=ep+1;do_print end
   else if t=FK+2 then begin ep:=ep+1;
      if tb[ep]=TS then begin ep:=ep+1;n:=tb[ep];ep:=ep+1;i:=0;
	 while i<n do begin pc(chr(tb[ep]));ep:=ep+1;i:=i+1 end;
	 if(tb[ep]=179)or(tb[ep]=178)then ep:=ep+1 end
   else begin pc('?');pc(' ') end;
      if(tb[ep]>=VA)and(tb[ep]<=VA+25)then begin vi:=tb[ep]-VA;ep:=ep+1;
	 read_line;pi;
	 while(pok=0)and(running=1)do begin pc('?');pc('R');pc('E');pc('D');pc('O');pc(' ');read_line;pi end;
	 vars[vi]:=ev end else err:=1 end
   else if t=FK+3 then begin ep:=ep+1;p_expr(5);
      if(err=0)and(tb[ep]=FK+4)then begin ep:=ep+1;if ev<>0 then rd:=1 end
   else if err=0 then err:=1 end
   else if t=FK+5 then begin ep:=ep+1;p_expr(5);
      if err=0 then begin lp:=store_find(ev);if lp<0 then err:=3 else tl:=lp end end
   else if t=FK+6 then begin ep:=ep+1;p_expr(5);
      if(err=0)and(gp>=64)then err:=6 else if err=0 then begin gs[gp]:=tl;gp:=gp+1;
	 lp:=store_find(ev);if lp<0 then err:=3 else tl:=lp end end
   else if t=FK+7 then if gp=0 then err:=7 else begin gp:=gp-1;tl:=gs[gp] end
   else if t=FK+8 then begin ep:=ep+1;
      if(tb[ep]>=VA)and(tb[ep]<=VA+25)then begin vi:=tb[ep]-VA;ep:=ep+1;
	 if tb[ep]=TP+4 then begin ep:=ep+1;p_expr(5);vars[vi]:=ev;
	    if(err=0)and(tb[ep]=FK+9)then begin ep:=ep+1;p_expr(5);
	       if err=0 then begin if fp>=16 then err:=8 else begin
		  fl[fp]:=ev;
		  if tb[ep]=FK+10 then begin ep:=ep+1;p_expr(5);fs[fp]:=ev end else fs[fp]:=1;
		  fv[fp]:=vi;fr[fp]:=tl;fp:=fp+1 end end end
	 else if err=0 then err:=1 end else err:=1 end else err:=1 end
   else if t=FK+11 then if fp=0 then err:=9 else begin
      vi:=fp-1;vars[fv[vi]]:=vars[fv[vi]]+fs[vi];
      if((fs[vi]>=0)and(vars[fv[vi]]<=fl[vi]))or((fs[vi]<0)and(vars[fv[vi]]>=fl[vi]))
	 then tl:=fr[vi] else fp:=fp-1 end
   else if(t=FK+12)or(t=FK+13)then mi:=0
   else if t=FK+14 then begin end
   else if t=FK+16 then begin mi:=1;tl:=0;gp:=0;fp:=0 end
   else if t=FK+15 then do_list
   else if t=FK+17 then pe:=0
   else if t=FK+20 then running:=0
   else if t=FK+22 then begin ep:=ep+1;p_expr(5);
      if err=0 then begin n:=ev;
	 if tb[ep]=178 then begin ep:=ep+1;p_expr(5);
	    if err=0 then begin
	       if(n>=0)and(n<1024)then um[n]:=ev else poke(n,ev)
	    end end else err:=1 end end
   else if(t>=VA)and(t<=VA+25)then do_let
   else err:=2 end;
   if err<>0 then begin write('?ERR ');print_int(err);
      if el>0 then begin write(' IN ');print_int(el) end;pn end end;
begin
   ik;pe:=0;running:=1;mi:=0;gp:=0;fp:=0;col:=0;el:=0;ep:=0;while ep<26 do begin vars[ep]:=0;ep:=ep+1 end;
   write('COR24 BASIC V1');pn;write('READY');pn;
   tl:=0;
   while running=1 do begin
      if mi=1 then begin
	 if tl<pe then begin
	    el:=ord(pg[tl])*256+ord(pg[tl+1]);ll:=ord(pg[tl+2]);lp:=0;
	    while lp<ll do begin tb[lp]:=ord(pg[tl+3+lp]);lp:=lp+1 end;
	    tl:=tl+3+ll;dispatch;if err<>0 then mi:=0
	 end else mi:=0
      end else begin el:=0;writechar('>');read_line;
	 if ll>0 then begin tokenize;
	    if tn>=0 then store_ins(tn) else dispatch end end end
end.
