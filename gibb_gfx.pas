program gibb_gfx;
{
     Gibb 1.21 ôvervakning till isbrytare Sîderhamns hamn
     (C) Garant Electronic,Jimmy Larsson 1994-96.



     éndringar:
        Inga

     Klart:
	Fîrdrîjt larm med 10sek                           (95-06-16)
        Kolvkylning,Spolluft,Trycklager 35-85 Grader      (95-09-02)
        Avgastemp. 150-400 Grader                         (95-09-02)
        Avgas Translate 200-500!                          (96-02-13)
        LÑgga Till Dig.larm 'Start Luft (Tryck)           (95-09-02)

        Bugg i kolvkylning. Larmade inte vid rÑtt grÑns.  (95-11-19)
        Bugg i ˆvers‰ttning av AD-v‰rden                  (96-02-13)
        Bugg i Trycklager                                 (96-06-01)
        NollstÑll variabler                               (96-06-01)
        Alarmcount bugg fix    (v1.21)                    (96-06-01)
}

uses Graph,dos,crt;
label strt;
type
  ConfigBlockType = record
                       BluGr : Array[1..21] Of real;
                       GrRed : Array[1..21] Of real;
                    end;
const
  Config_block : ConfigBlockType=(
  Blugr : (0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33);
  GrRed: (0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66,0.66));

  card1 = 632;
  card2 = 760;
  dig_card = $1B0;  {1B0?}
  alarm_at = 20;

var ad_values :array[0..31] of real;
    new_value :array[0..31] of real;
    digital :array[0..23] of boolean;
    checked_r :array[0..31] of boolean;
    checked_b :array[0..31] of boolean;
    dig_checked :array[0..31] of boolean;
 main_x,grDriver: Integer;
 grMode: Integer;
 alarmcount: array[0..70] of longint;
 prutt,tmp,tmp2,tst,dsize,ErrCode: Integer;
 Palette: palettetype;
 h,m,s,hund,h2,m2,s2,hund2 : Word;
 buppemupp,pw:string[20];
 ss_timer: longint;
 dpointer :pointer;
 larmed,mess :string;
 mag,mag_larm   :boolean;

function RealToStr(I: real;Decimals,width:byte): String;
var
 S: string[22];
begin
 Str(I:width:decimals, S);
 realToStr := S;
end;

function input(x,y,chrnum,backcol:integer;oldstr:string):string;
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
var
   ch   :char;
   stop :boolean;
   inpstr :string;
begin
     stop:=false;
     ch:=#0;
     outtextxy(x,y,oldstr+'¯');
     inpstr:=oldstr;
     repeat
           if keypressed then ch:=readkey;
           if (ch>'') and (ch<'ˇ') and (length(inpstr)<chrnum) then begin
              inpstr:=inpstr+ch;
              ch:=#0;
              SetFillPattern(fill, backcol);
              bar(x,y,x+8*(chrnum+1),y+8);
              outtextxy(x,y,inpstr+'¯');
           end;
           if ord(ch)=8 then begin
              ch:=#0;
              delete(inpstr,length(inpstr),1);
              SetFillPattern(fill, backcol);
              bar(x,y,x+8*(chrnum+1),y+8);
              outtextxy(x,y,inpstr+'¯');
           end;
     until ord(ch)=13;
     input:=inpstr;
end;

function LeadingZero(w : Word) : String;
var
  s : String;
begin
  Str(w:0,s);
  if Length(s) = 1 then
    s := '0' + s;
  LeadingZero := s;
end;

procedure translate;
begin
     {avg. kylvatten}
     ad_values[0]:=trunc(((((((ad_values[0]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[1]:=trunc(((((((ad_values[1]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[2]:=trunc(((((((ad_values[2]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[3]:=trunc(((((((ad_values[3]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[4]:=trunc(((((((ad_values[4]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[5]:=trunc(((((((ad_values[5]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     {kolvkyln}
     ad_values[6]:=trunc(((((((ad_values[6]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[7]:=trunc(((((((ad_values[7]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[8]:=trunc(((((((ad_values[8]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[9]:=trunc(((((((ad_values[9]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[10]:=trunc(((((((ad_values[10]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[11]:=trunc(((((((ad_values[11]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     {avgas}
     ad_values[12]:=trunc(((((((ad_values[12]/2089)-(5.46/2089))*5.46)-1)/5.46)*300)+200);
     ad_values[13]:=trunc(((((((ad_values[13]/2089)-(5.46/2089))*5.46)-1)/5.46)*300)+200);
     ad_values[14]:=trunc(((((((ad_values[14]/2089)-(5.46/2089))*5.46)-1)/5.46)*300)+200);
     ad_values[15]:=trunc(((((((ad_values[15]/2089)-(5.46/2089))*5.46)-1)/5.46)*300)+200);
     ad_values[16]:=trunc(((((((ad_values[16]/2089)-(5.46/2089))*5.46)-1)/5.46)*300)+200);
     ad_values[17]:=trunc(((((((ad_values[17]/2089)-(5.46/2089))*5.46)-1)/5.46)*300)+200);
     {spolluft}
     ad_values[18]:=trunc(((((((ad_values[18]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);
     ad_values[19]:=trunc(((((((ad_values[19]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);

     {ad_values[19]:=((((((ad_values[19]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40;
     {trycklager}
     ad_values[20]:=trunc(((((((ad_values[20]/2411)-(6.3/2411))*6.3)-1)/6.3)*50)+40);

  {   ad_values[0]:=32;      }
  {   ad_values[1]:=32;
     ad_values[2]:=32;
     ad_values[3]:=32;
     ad_values[4]:=32;
     ad_values[5]:=32;
     ad_values[6]:=32;
     ad_values[7]:=32;
     ad_values[8]:=32;
     ad_values[9]:=32;
     ad_values[10]:=32;
     ad_values[11]:=32;  }
{     ad_values[12]:=32;
     ad_values[13]:=32;
     ad_values[14]:=32;
     ad_values[15]:=32;
     ad_values[16]:=32;
     ad_values[17]:=32;
  {   ad_values[20]:=32;

{     ad_values[21]:=ad_values[21]/4096;
     ad_values[22]:=ad_values[22]/4096;
     ad_values[23]:=ad_values[23]/4096;
     ad_values[24]:=ad_values[24]/4096;
     ad_values[25]:=ad_values[25]/4096;
     ad_values[26]:=ad_values[26]/4096;
     ad_values[27]:=ad_values[27]/4096;
     ad_values[28]:=ad_values[28]/4096;
     ad_values[29]:=ad_values[29]/4096;
     ad_values[30]:=ad_values[30]/4096;
     ad_values[31]:=ad_values[31]/4096; }
end;

procedure Print_it;
const
  days : array [0..6] of String[9] =
    ('Sunday','Monday','Tuesday',
     'Wednesday','Thursday','Friday',
     'Saturday');
var
  y, m, d, dow : Word;
  l1,l2,l3,l4,l5:string[80];
  tid,dato:string;
  h3,m3,s3,hund3 :Word;
  lpt :text;

begin
   {  Assign(lpt, 'PRN');
     Rewrite(lpt);

     GetTime(h3,m3,s3,hund3);
     tid:=LeadingZero(h3)+':'+LeadingZero(m3);

     GetDate(y,m,d,dow);
     dato:=realtostr(y,0,2)+'-'+realtostr(m,0,2)+'-'+realtostr(d,0,2);

     l1:='----------------------------------------------------';
     l2:='-- Datum: '+dato+' Tid: '+tid;
     l3:='-- ---> '+mess;
     l4:='--';
     l5:='- Gibb 1.1 - Felrapport. (C) Jimmy Larsson 1994-95 -';

     writeln(lpt,l1);
     writeln(lpt,l2);
     writeln(lpt,l3);
     writeln(lpt,l4);
     writeln(lpt,l5);
     writeln(lpt);
     close(lpt);       }
end;

procedure read_cards;
var lowb :byte;
    temp,hib,d :real; {real}
    x,q,y,bertil :integer;

begin

     for q:=0 to 15 do begin                     { Card Numero 1 }
             hib:=0;
             lowb:=0;
             port[card1]:=q;                         { Channel Number }
             port[card1+3]:=0;
             for x:= 1 to 5 do begin
                 d:=port[card1+4]; { Conversion Loop }
                 delay(1);
             end;
             for x:= 1 to 9 do begin
                 d:=port[card1+5]; { Conversion Loop 2 }
                 delay(1);
             end;
             temp:=port[card1+2];                   { Read High-Byte }
             x:=trunc(temp);
             hib:=(temp/16 - (x div 16)) * 16; { Take out low nibble }
             lowb:=port[card1+1];                   { Read Low-Byte }
             ad_values[q]:=trunc(hib)*256 + lowb;           { Add'em }
     end;
     for q:=16 to 21 do begin                     { Card Numero 2 }
             hib:=0;
             lowb:=0;
             port[card2]:=q;                         { Channel Number }
             port[card2+3]:=0;
             for x:= 1 to 5 do begin
                 d:=port[card2+4]; { Conversion Loop }
                 delay(1);
             end;
             for x:= 1 to 9 do begin
                 d:=port[card2+5]; { Conversion Loop 2 }
                 delay(1);
             end;
             temp:=port[card2+2];                   { Read High-Byte }
             x:=trunc(temp);
             hib:=(temp/16 - (x div 16)) * 16; { Take out low nibble }
             lowb:=port[card2+1];                   { Read Low-Byte }
             ad_values[q]:=trunc(hib)*256 + lowb;           { Add'em }
     end;

     tmp:=port[dig_card];

     for x:=0 to 6 do digital[x]:=TRUE;
     for x:=8 to 16 do digital[x]:=TRUE;

     tst:=tmp and 1;
     if tst>0 then digital[0]:=FALSE;
     tst:=tmp and 2;
     if tst>0 then digital[1]:=FALSE;
     tst:=tmp and 4;
     if tst>0 then digital[2]:=FALSE;
     tst:=tmp and 8;
     if tst>0 then digital[3]:=FALSE;
     tst:=tmp and 16;
     if tst>0 then digital[4]:=FALSE;
     tst:=tmp and 32;
     if tst>0 then digital[5]:=FALSE;
     tst:=tmp and 64;
     if tst>0 then digital[6]:=FALSE;
     tst:=tmp and 128;
     if tst>0 then digital[8]:=FALSE;


{         for y:= 1 to x do q:=q*2;          {maybe one minus <--------}
{         if tmp/(q-1) > 1 then digital[x-1]:=true;
     end;
}
     tmp2:=port[dig_card+1];
     tst:=tmp2 and 1;
     if tst>0 then digital[9]:=FALSE;
     tst:=tmp2 and 2;
     if tst>0 then digital[10]:=FALSE;
     tst:=tmp2 and 4;
     if tst>0 then digital[11]:=FALSE;
     tst:=tmp2 and 8;
     if tst>0 then digital[12]:=FALSE;
     tst:=tmp2 and 16;
     if tst>0 then digital[13]:=FALSE;
     tst:=tmp2 and 32;
     if tst>0 then digital[14]:=FALSE;
     tst:=tmp2 and 64;
     if tst>0 then digital[15]:=FALSE;
     tst:=tmp2 and 128;
     if tst>0 then digital[16]:=FALSE;

 {    tmp:=port[dig_card+1];
     for x := 8 to 1 do begin
         for y:= 1 to x do q:=q*2;          {maybe one minus <--------}
{         if tmp/(q-1) > 1 then digital[x+7]:=true;
     end;   }

     translate;
end;

procedure get_time;
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
begin
  GetTime(h,m,s,hund);
  if (h<>h2) or (m<>m2){ or (s<>s2)} then begin
     SetFillPattern(fill, 2);
     setcolor(9);
     bar(590,10,632,16);
     outtextxy(590,10,LeadingZero(h)+':'+LeadingZero(m){+':'+LeadingZero(s)(*+'.'+LeadingZero(hund)*)});
     h2:=h;m2:=m;s2:=s;
  end
  else begin
     h2:=h;m2:=m;s2:=s;
  end;
end;

procedure y_meter(meter_len,x,y:integer;value,red,blu:real;backcol:byte);
const meter_wid = 16;
      {meter_y   = 90;
      meter_xspace = 7;
      meter_yspace = 60;
      meters_row   = 11;
      meter_xoffs  = 20; }

      fill : FillPatternType = ($ff, $ff, $ff,
             $ff, $ff, $ff, $ff, $ff);
var act_len,meter_blu,meter_gr,meter_red:integer;

begin
     if value>1 then value:=1;
     if value <0 then value:=0;
     {if num > meters_row then begin
        y_place:=meter_y+meter_yspace;
        x_place:=meter_xoffs+((num-meters_row-1)*meter_xspace);
     end
     else begin
          y_place:=meter_y;
          x_place:=meter_xoffs+(num-1)*meter_xspace;
     end;
     if num > 2*meters_row then begin
        y_place:=meter_y+meter_yspace+meter_yspace;
        x_place:=meter_xoffs+((num-meters_row*2-1)*meter_xspace);
     end;
     if num > 3*meters_row then begin
        y_place:=meter_yspace+meter_y+meter_yspace+meter_yspace;
        x_place:=meter_xoffs+((num-meters_row*3-1)*meter_xspace);
     end; }
     meter_red:=0;
     meter_gr:=0;
     act_len:=trunc(meter_len*value); { Value is between 0 and 1 }
     meter_blu:=act_len;
     if act_len>trunc(meter_len*blu) then begin
        meter_blu:=trunc(meter_len*blu);
        meter_gr:=act_len-meter_blu;
     end;
     if act_len>trunc(meter_len*red) then begin
        meter_gr:=trunc(meter_len*red)-meter_blu;
        meter_red:=act_len-meter_gr-meter_blu;
     end;
     setfillpattern(fill, backcol);
     bar(x,y-meter_len-1,x+meter_wid,y+meter_len-(meter_len+meter_blu+meter_red+meter_gr));
     SetFillPattern(fill, 14);
     bar(x,y,meter_wid+x,y-meter_blu);
     if meter_gr>0 then begin
        setfillpattern(fill,13);
        bar(x,y-meter_blu,x+meter_wid,y-meter_blu-meter_gr);
     end;
     if meter_red>0 then begin
        SetFillPattern(fill, 12);
        bar(x,y-meter_gr-1-meter_blu,meter_wid+x,y-meter_gr-meter_red-1-meter_blu);
     end;
end;


procedure x_meter(meter_len,x,y:integer;value,red,blu:real;backcol:byte);
const meter_wid = 4;
      {meter_y   = 90;
      meter_xspace = 7;
      meter_yspace = 60;
      meters_row   = 11;
      meter_xoffs  = 20; }

      fill : FillPatternType = ($ff, $ff, $ff,
             $ff, $ff, $ff, $ff, $ff);
var act_len,meter_blu,meter_gr,meter_red:integer;

begin
     if value>1 then value:=1;
     if value <0 then value:=0;
     {if num > meters_row then begin
        y_place:=meter_y+meter_yspace;
        x_place:=meter_xoffs+((num-meters_row-1)*meter_xspace);
     end
     else begin
          y_place:=meter_y;
          x_place:=meter_xoffs+(num-1)*meter_xspace;
     end;
     if num > 2*meters_row then begin
        y_place:=meter_y+meter_yspace+meter_yspace;
        x_place:=meter_xoffs+((num-meters_row*2-1)*meter_xspace);
     end;
     if num > 3*meters_row then begin
        y_place:=meter_yspace+meter_y+meter_yspace+meter_yspace;
        x_place:=meter_xoffs+((num-meters_row*3-1)*meter_xspace);
     end; }
     meter_red:=0;
     meter_gr:=0;
     act_len:=trunc(meter_len*value); { Value is between 0 and 1 }
      meter_blu:=act_len;
     if act_len>trunc(meter_len*blu) then begin
        meter_blu:=trunc(meter_len*blu);
        meter_gr:=act_len-meter_blu;
     end;
     if act_len>trunc(meter_len*red) then begin
        meter_gr:=trunc(meter_len*red)-meter_blu;
        meter_red:=act_len-meter_gr-meter_blu;
     end;
     setfillpattern(fill, backcol);
     bar(x+meter_len+1,y-1,x+meter_len-(meter_len-meter_blu-meter_red-meter_gr),y+meter_wid+1);
     SetFillPattern(fill, 14);
     bar(x,y,x+meter_blu,y+meter_wid);
     if meter_gr>0 then begin
        setfillpattern(fill,13);
        bar(x+meter_blu,y,x+meter_blu+meter_gr,y+meter_wid);
     end;
     if meter_red>0 then begin
        SetFillPattern(fill, 12);
        bar(x+meter_gr+1+meter_blu,y,x+meter_gr+meter_red+1+meter_blu,y+meter_wid);
     end;
end;

procedure d_rect(x1,y1,x2,y2:integer);
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
begin
     setcolor(3);
     line(x1,y1,x2,y1);
     line(x1,y1,x1,y2);
     setcolor(1);
     line(x2,y1,x2,y2);
     line(x1,y2,x2,y2);
     SetFillPattern(fill, 2);
     bar(x1+1,y1+1,x2-1,y2-1);
end;

procedure inv_d_rect(x1,y1,x2,y2:integer);
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
begin
     setcolor(1);
     line(x1,y1,x2,y1);
     line(x1,y1,x1,y2);
     setcolor(3);
     line(x2,y1,x2,y2);
     line(x1,y2,x2,y2);
     SetFillPattern(fill, 5);
     bar(x1+1,y1+1,x2-1,y2-1);
end;

procedure save_cfg;

var
    ExeFile    : file;
    HeaderSize : word;
begin
    assign(ExeFile, paramstr(0));
    reset(ExeFile, 1);
    seek(ExeFile, 8);
    blockread(ExeFile, HeaderSize, sizeof(HeaderSize));
    seek(ExeFile, longint(16)*(seg(config_Block)-PrefixSeg+HeaderSize)+ofs(config_Block)-256);
    blockwrite(ExeFile, Config_Block, sizeof(config_Block));
    close(ExeFile);
end;

procedure init_gfx;
var
   x :integer;
begin
     SetLineStyle(solidLn, 0, 2);
     setbkcolor(2);
     d_rect(0,0,getmaxx,getmaxy);
     SetLineStyle(solidLn, 0, normWidth);
{kylv.temp}
     d_rect(40,40,220,170);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(84,50+x*10,88,50+x*10);
     end;
     {text}
     outtextxy(69,96,'65');
     outtextxy(69,146,'40');
     outtextxy(69,46,'90');
{kolv.kyln.}
     d_rect(230,40,410,170);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(274,50+x*10,278,50+x*10);
     end;
     {text}
     outtextxy(259,96,'60');
     outtextxy(259,146,'35');
     outtextxy(259,46,'85');
{avgas.temp}
     d_rect(420,40,600,170);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(464,50+x*10,468,50+x*10);
     end;
     {text}
     outtextxy(441,96,'300');
     outtextxy(441,146,'150');
     outtextxy(441,46,'450');
{spol-luft-temp}
     d_rect(40,190,140,320);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(74,200+x*10,78,200+x*10);
     end;
     {text}
     outtextxy(59,246,'60');
     outtextxy(59,296,'35');
     outtextxy(59,196,'85');
{trycklager-temp}
     d_rect(150,190,220,320);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(175,200+x*10,179,200+x*10);
     end;
     {text}
     outtextxy(161,246,'60');
     outtextxy(161,296,'35');
     outtextxy(161,196,'85');
{SMO-fîre-filter}
{     d_rect(40,340,120,470);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(74,350+x*10,78,350+x*10);
     end;
     {text         }
{     outtextxy(43,396,'1.75');
     outtextxy(51,446,'0.0');
     outtextxy(51,346,'2.5');
{SMO-efter-filter}
{     d_rect(130,340,210,470);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(164,350+x*10,168,350+x*10);
     end;
     {text         }
{     outtextxy(133,396,'1.75');
     outtextxy(141,446,'0.0');
     outtextxy(141,346,'2.5');
{Frisk vatten
     d_rect(310,190,390,320);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(344,200+x*10,348,200+x*10);
     end; }
     {text
     outtextxy(321,246,'.9');
     outtextxy(321,296,'.4');
     outtextxy(313,196,'1.4');}

     SetTextStyle(0, HorizDir, 1);
     SetTextJustify(LeftText, TopText);
     setcolor(7);
     outtextxy(10,5,'Gibb 1.21 av Jimmy Larsson 1996. (C)1994-96 Garant Electronic.');
     outtextxy(10,460,larmed);
     outtextxy(42,31,'Avg. Kylvattentemp');
     outtextxy(232,31,'Kolvkylning');
     outtextxy(422,31,'Avgastemp');
     outtextxy(42,181,'Spollufttemp');
     outtextxy(152,181,'Trycklagertemp');
     {outtextxy(42,331,'SMO Fîre');
     outtextxy(132,331,'SMO Efter');   }

     setcolor(15);
     outtextxy(350,350,'------- On/Off -------');
     outtextxy(350,360,'Diff. Avgastemp   = ');
     outtextxy(350,370,'FÑrskvatten ExpTk = ');
     outtextxy(350,380,'Hylsolja ExpTk    = ');
     outtextxy(350,390,'Kamewa ExpTk      = ');
     outtextxy(350,400,'LÑnsgrop          = ');
     outtextxy(350,410,'BrÑnnoljenivÜ     = ');

     outtextxy(50,350,'------- Tryck -------');
     outtextxy(50,360,'SMO Fîre Filter  = ');
     outtextxy(50,370,'SMO Efter Filter = ');
     outtextxy(50,380,'BrÑnnolja        = ');
     outtextxy(50,390,'FÑrskvatten      = ');
     outtextxy(50,400,'Sjîvatten        = ');
     outtextxy(50,410,'Spolluft         = ');
     outtextxy(50,420,'Kamewa           = ');
     outtextxy(50,430,'Startluft        = ');

     {outtextxy(282,181,'BRO');
     outtextxy(312,181,'FW');  }
     setcolor(7);
     outtextxy(45,160,'[F1] fîr mer info');
     outtextxy(235,160,'[F2] fîr mer info');
     outtextxy(425,160,'[F3] fîr mer info');
     outtextxy(45,310,'[F4]');
     outtextxy(155,310,'[F5]');
 {    outtextxy(45,460,'[F6]');
     outtextxy(135,460,'[F7]');


{     outtextxy(123,36,'Kylvattentemp');}
{     inv_d_rect(38,69,96,110);
{     inv_d_rect(250,50,320,110);}
{     setcolor(12);
     outtextxy(41,75,'Hîg:93¯');
     outtextxy(253,55,'Hîg:4.5b');
     setcolor(14);
     outtextxy(41,97,'LÜg:60¯');
     outtextxy(253,75,'LÜg:1.2b');
     setcolor(13);
     outtextxy(41,86,'Nom:85¯');
     outtextxy(253,65,'Nom:2.4b');
     setcolor(7);
 {    outtextxy(175,55,'1:');
     outtextxy(175,64,'2:');
     outtextxy(175,73,'3:');
     outtextxy(175,82,'4:');
     outtextxy(175,91,'5:');
     outtextxy(175,100,'6:');
  }
end;

procedure start_gfx;
var
   x :integer;
   Driver, Mode: Integer;
   DriverF: file;
   DriverP: Pointer;
begin
 port[dig_card+3]:=$00;    {sÑtt port 1 = input}
 port[dig_card+7]:=$FF;    {sÑtt port 2 = output (siren) }
 Driver := Detect;
 Mode:=2;
 Assign(DriverF, 'C:\GIBB\EGAVGA.BGI');
 Reset(DriverF, 1);
 dsize:=filesize(driverF);
 GetMem(DriverP, dSize);
 BlockRead(DriverF, DriverP^, dsize);
 close(driverF);
 dpointer:=driverP;
 if RegisterBGIdriver(DriverP) < 0 then
 begin
      writeln('Kunde inte registrera grafik... ');
      halt;
 end;
 InitGraph(Driver, Mode,' ');
 ErrCode := GraphResult;
 if not(ErrCode = grOk) then
 begin
      writeln('Kunde inte initialisera grafik... ');
      halt;
 end;
 with palette do begin
      size:=16;
      colors[0]:=0;
      colors[1]:=1;
      colors[2]:=2;
      colors[3]:=3;
      colors[4]:=4;
      colors[5]:=5;
      colors[6]:=6;
      colors[7]:=7;
      colors[8]:=8;
      colors[9]:=9;
      colors[10]:=10;
      colors[11]:=11;
      colors[12]:=12;
      colors[13]:=13;
      colors[14]:=14;
      colors[15]:=15;
      setallpalette(palette);
 end;
     SetRGBPalette(0, 0, 0, 0);
     SetRGBPalette(1, 15, 0, 15);
     SetRGBPalette(2, 32, 0, 32);
     SetRGBPalette(3, 63, 0, 63);
     SetRGBPalette(4, 63, 63, 0);
     SetRGBPalette(5, 0, 0, 0);
     SetRGBPalette(6, 0, 63, 0);
     SetRGBPalette(7, 0, 63, 10);
     SetRGBPalette(8, 0, 50, 50);
     SetRGBPalette(9, 63, 63, 63);
     SetRGBPalette(10, 0, 0, 63);
     SetRGBPalette(11, 45, 45, 45);
     SetRGBPalette(12, 50, 0, 0);
     SetRGBPalette(13, 0, 50, 0);
     SetRGBPalette(14, 0, 0, 63);
     SetRGBPalette(15, 63, 63, 63);
end;

{procedure change_pass;
var
   pwstr :string[20];
begin
     d_rect(20,100,620,170);
     setcolor(3);
     outtextxy(40,110,'éndra slutlîsen.');
     if config_block.menupw<>'' then begin
        setcolor(3);
        outtextxy(40,125,'Ange nuvarande lîsen:');
        setcolor(4);
        pwstr:=input(225,125,20,2,'');
        if pwstr=config_block.menupw then begin
           setcolor(3);
           outtextxy(40,140,'Ange NYTT lîsen:');
           setcolor(4);
           pwstr:=input(170,140,20,2,'');
           config_block.menupw:=pwstr;
        end
        else begin
             setcolor(9);
             outtextxy(40,140,'Fel lîsen. ètervÑnder...');
             delay(2000);
        end;
     end
     else begin
          setcolor(3);
          outtextxy(40,140,'Ange NYTT lîsen:');
          setcolor(4);
          pwstr:=input(170,140,20,2,'');
          config_block.menupw:=pwstr;
     end;
end;   }

procedure blank_screen;
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
var
   ch:char;
   dot :array[1..20,1..2] of integer;
begin
 setfillpattern(fill, 5);
 bar(0,0,getmaxx,getmaxy);
 Randomize;
 repeat
       delay(1);
       dot[20,1]:=dot[19,1];
       dot[20,2]:=dot[19,2];
       dot[19,1]:=dot[18,1];
       dot[19,2]:=dot[18,2];
       dot[18,1]:=dot[17,1];
       dot[18,2]:=dot[17,2];
       dot[17,1]:=dot[16,1];
       dot[17,2]:=dot[16,2];
       dot[16,1]:=dot[15,1];
       dot[16,2]:=dot[15,2];
       dot[15,1]:=dot[14,1];
       dot[15,2]:=dot[14,2];
       dot[14,1]:=dot[13,1];
       dot[14,2]:=dot[13,2];
       dot[13,1]:=dot[12,1];
       dot[13,2]:=dot[12,2];
       dot[12,1]:=dot[11,1];
       dot[12,2]:=dot[11,2];
       dot[11,1]:=dot[10,1];
       dot[11,2]:=dot[10,2];
       dot[10,1]:=dot[9,1];
       dot[10,2]:=dot[9,2];
       dot[9,1]:=dot[8,1];
       dot[9,2]:=dot[8,2];
       dot[8,1]:=dot[7,1];
       dot[8,2]:=dot[7,2];
       dot[7,1]:=dot[6,1];
       dot[7,2]:=dot[6,2];
       dot[6,1]:=dot[5,1];
       dot[6,2]:=dot[5,2];
       dot[5,1]:=dot[4,1];
       dot[5,2]:=dot[4,2];
       dot[4,1]:=dot[3,1];
       dot[4,2]:=dot[3,2];
       dot[3,1]:=dot[2,1];
       dot[3,2]:=dot[2,2];
       dot[2,1]:=dot[1,1];
       dot[2,2]:=dot[1,2];
       dot[1,1]:=random(640);
       dot[1,2]:=random(480);
       putpixel(dot[1,1],dot[1,2],15);
       putpixel(dot[20,1],dot[20,2],5);
 until keypressed;
 while keypressed do ch:=readkey;
 ss_timer:=0;
 init_gfx;
end;

procedure draw_meters;
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
begin
        { Kylvatten temp. 1 till 6. Mellan 40 och 90¯ }
{1}     y_meter(100,100,150,(ad_values[0]-40)/50,config_block.grred[1],config_block.blugr[1],2);
{2}     y_meter(100,120,150,(ad_values[1]-40)/50,config_block.grred[1],config_block.blugr[1],2);
{3}     y_meter(100,140,150,(ad_values[2]-40)/50,config_block.grred[1],config_block.blugr[1],2);
{4}     y_meter(100,160,150,(ad_values[3]-40)/50,config_block.grred[1],config_block.blugr[1],2);
{5}     y_meter(100,180,150,(ad_values[4]-40)/50,config_block.grred[1],config_block.blugr[1],2);
{6}     y_meter(100,200,150,(ad_values[5]-40)/50,config_block.grred[1],config_block.blugr[1],2);

        { Kolvkylning temp. 1 till 6. Mellan 35 och 85¯ }
{1}     y_meter(100,290,150,(ad_values[6]-35)/50,config_block.grred[2],config_block.blugr[2],2);
{2}     y_meter(100,310,150,(ad_values[7]-35)/50,config_block.grred[2],config_block.blugr[2],2);
{3}     y_meter(100,330,150,(ad_values[8]-35)/50,config_block.grred[2],config_block.blugr[2],2);
{4}     y_meter(100,350,150,(ad_values[9]-35)/50,config_block.grred[2],config_block.blugr[2],2);
{5}     y_meter(100,370,150,(ad_values[10]-35)/50,config_block.grred[2],config_block.blugr[2],2);
{6}     y_meter(100,390,150,(ad_values[11]-35)/50,config_block.grred[2],config_block.blugr[2],2);

        { Avgas temp. 1 till 6. Mellan 200 och 500¯ }
{1}     y_meter(100,480,150,(ad_values[12]-150)/300,config_block.grred[3],config_block.blugr[3],2);
{2}     y_meter(100,500,150,(ad_values[13]-150)/300,config_block.grred[3],config_block.blugr[3],2);
{3}     y_meter(100,520,150,(ad_values[14]-150)/300,config_block.grred[3],config_block.blugr[3],2);
{4}     y_meter(100,540,150,(ad_values[15]-150)/300,config_block.grred[3],config_block.blugr[3],2);
{5}     y_meter(100,560,150,(ad_values[16]-150)/300,config_block.grred[3],config_block.blugr[3],2);
{6}     y_meter(100,580,150,(ad_values[17]-150)/300,config_block.grred[3],config_block.blugr[3],2);

        { Spol-luft temp. 35 till 85 grader }
        y_meter(100,90,300,(ad_values[18]-35)/50,config_block.grred[4],config_block.blugr[4],2);
        y_meter(100,110,300,(ad_values[19]-35)/50,config_block.grred[4],config_block.blugr[4],2);

        { Trycklager temp. 35 - 85 grader}
        y_meter(100,185,300,(ad_values[20]-35)/50,config_block.grred[5],config_block.blugr[5],2);

        { Smîrj-olje tryck. fîre filter 0 till 2,5 bar. }
        {y_meter(100,90,450,ad_values[21],config_block.grred[6],config_block.blugr[6],2);

        { SMO efter filter 0 till 2,5 bar }
        {y_meter(100,180,450,ad_values[22],config_block.grred[7],config_block.blugr[7],2);

        { Frisk vatten tryck. 0.4 till 1.4 bar }
        {y_meter(100,360,300,ad_values[21],config_block.grred[7],config_block.blugr[7],2);

{     x_meter(50,120,55,ad_values[0]/4096,0.83,0.4,2);
     x_meter(50,120,64,ad_values[0]/4096,0.83,0.4,2);
     x_meter(50,120,73,ad_values[0]/4096,0.83,0.4,2);
     x_meter(50,120,82,ad_values[0]/4096,0.83,0.4,2);
     x_meter(50,120,91,ad_values[0]/4096,0.83,0.4,2);
     x_meter(50,120,100,ad_values[0]/4096,0.83,0.4,2);
     outtextxy(45,55,Realtostr(ad_values[0]*(100/4095)-(100/4095),1)+'¯');
     bar(195,55,245,108);
     outtextxy(195,55,realtostr(abs(ad_values[0]*(5/4095)-(5/4095)),2)+' b');
     outtextxy(195,64,realtostr(abs(ad_values[0]*(5/4095)-(5/4095)),2)+' b');
     outtextxy(195,73,realtostr(abs(ad_values[0]*(5/4095)-(5/4095)),2)+' b');
     outtextxy(195,82,realtostr(abs(ad_values[0]*(5/4095)-(5/4095)),2)+' b');
     outtextxy(195,91,realtostr(abs(ad_values[0]*(5/4095)-(5/4095)),2)+' b');
     outtextxy(195,100,realtostr(abs(ad_values[0]*(5/4095)-(5/4095)),2)+' b');
}
end;

procedure siren_on;
begin
     port[dig_card+4]:=255;
end;

procedure siren_off;
begin
     port[dig_card+4]:=0;
end;

procedure draw_dig;
const
     fill : FillPatternType = ($ff, $ff, $ff,
            $ff, $ff, $ff, $ff, $ff);
var  x:integer;
     okstr:string;

begin
     setfillpattern(fill, 2);
{tryck}
     for x:= 0 to 6 do begin
         bar(200,(x*10)+360,250,(x*10)+370);
         setcolor(15);
         if digital[x]=TRUE then okstr:='OK ' else okstr:='FEL';
         outtextxy(200,(x*10)+360,okstr);
     end;
{Startluft}
         bar(200,70+360,250,70+370);
         setcolor(15);
         if digital[13]=TRUE then okstr:='OK ' else okstr:='FEL';
         outtextxy(200,70+360,okstr);
{on/off}
     for x:= 0 to 5 do begin
         bar(505,(x*10)+360,550,(x*10)+370);
         setcolor(15);
         if digital[x+7]=TRUE then okstr:='OK ' else okstr:='FEL';
         outtextxy(505,(x*10)+360,okstr);
     end;

end;

procedure alarm_square(num:integer);
var       ch:char;
          x:integer;
          test :string;
begin
          inv_d_rect(150,180,540,248);
          setcolor(15);
          outtextxy(190,200,mess);
          outtextxy(190,220,'Tryck en tangent fîr att bekrÑfta...');
{---->    str(ad_values[num-1],test);
          outtextxy(190,240,test);   <- wrajta ut vÑrdet vid larm }
          Print_it;
          siren_on;
          repeat
                for x:= 1 to 200 do begin
                    if keypressed then break;
                    sound(500+x);
                    delay(2);
                end;
                for x:= 200 to 1 do begin
                    if keypressed then break;
                    sound(500+x);
                    delay(2);
                end;
          until keypressed;
          nosound;
          siren_off;
          ch:=readkey;
          checked_r[num-1]:=TRUE;
          checked_b[num-1]:=TRUE;
          if mag=FALSE then begin
             init_gfx;
             draw_meters;
             draw_dig;
          end else begin
              mag_larm:=TRUE;
          end;
end;

procedure dig_alm(num:integer);
var       ch:char;
          x:integer;
begin
          inv_d_rect(150,180,540,248);
          setcolor(15);
          outtextxy(190,200,mess);
          outtextxy(190,220,'Tryck en tangent fîr att bekrÑfta...');
          Print_it;
          siren_on;
          repeat
                for x:= 1 to 200 do begin
                    if keypressed then break;
                    sound(500+x);
                    delay(2);
                end;
                for x:= 200 to 1 do begin
                    if keypressed then break;
                    sound(500+x);
                    delay(2);
                end;
          until keypressed;
          nosound;
          siren_off;
          ch:=readkey;
          dig_checked[num]:=TRUE;
          if mag=FALSE then begin
             init_gfx;
             draw_meters;
             draw_dig;
          end else begin
              mag_larm:=TRUE;
          end;
end;

procedure alarm(num :integer);
begin
          larmed:='Larmstatus: LARM PèTRéFFAT!!!  [F10] Fîr att ÜterstÑlla larmsystemet';
          if (num>0) and (num<7) and (checked_r[num-1]=FALSE) and (checked_b[num-1]=FALSE) then begin
             mess := 'Larm pÜ AvgÜende Kylvattentemperatur '+realtostr(num,0,1);
             alarm_square(num);
          end;
          if (num>6) and (num<13) and (checked_r[num-1]=FALSE) and (checked_b[num-1]=FALSE) then begin
             mess := 'Larm pÜ Kolvkylningstemperatur '+realtostr(num-6,0,1);
             alarm_square(num);
          end;
          if (num>12) and (num<19) and (checked_r[num-1]=FALSE) and (checked_b[num-1]=FALSE) then begin
             mess := 'Larm pÜ Avgastemperatur '+realtostr(num-12,0,1);
             alarm_square(num);
          end;
          if (num>18) and (num<21) and (checked_r[num-1]=FALSE) and (checked_b[num-1]=FALSE) then begin
             mess := 'Larm pÜ Spolluftstemperatur '+realtostr(num-18,0,1);
             alarm_square(num);
          end;
          if (num=21) and (checked_r[num-1]=FALSE) and (checked_b[num-1]=FALSE) then begin
             mess := 'Larm pÜ Trycklagertemperatur';
             alarm_square(num);
          end;
          if (num=40) and (dig_checked[0]=FALSE) then begin
             mess:='Larm pÜ SMO tryck fîre filter';
             dig_alm(0);
          end;
          if (num=41) and (dig_checked[1]=FALSE) then begin
             mess:='Larm pÜ SMO tryck efter filter';
             dig_alm(1);
          end;
          if (num=42) and (dig_checked[2]=FALSE) then begin
             mess:='Larm pÜ BrÑnnolje tryck';
             dig_alm(2);
          end;
          if (num=43) and (dig_checked[3]=FALSE) then begin
             mess:='Larm pÜ FÑrskvatten tryck';
             dig_alm(3);
          end;
          if (num=44) and (dig_checked[4]=FALSE) then begin
             mess:='Larm pÜ Sjîvatten tryck';
             dig_alm(4);
          end;
          if (num=45) and (dig_checked[5]=FALSE) then begin
             mess:='Larm pÜ Spolluft tryck';
             dig_alm(5);
          end;
          if (num=46) and (dig_checked[6]=FALSE) then begin
             mess:='Larm pÜ Kamewa tryck';
             dig_alm(6);
          end;
          if (num=47) and (dig_checked[7]=FALSE) then begin
             mess:='Larm pÜ Avgas Diff. (ôver 35 Grader)';
             dig_alm(7);
          end;
          if (num=48) and (dig_checked[8]=FALSE) then begin
             mess:='Larm pÜ FÑrskvatten Expantionstank';
             dig_alm(8);
          end;
          if (num=49) and (dig_checked[9]=FALSE) then begin
             mess:='Larm pÜ Hylsolje Expantionstank';
             dig_alm(9);
          end;
          if (num=50) and (dig_checked[10]=FALSE) then begin
             mess:='Larm pÜ Kamewa Expantionstank';
             dig_alm(10);
          end;
          if (num=51) and (dig_checked[11]=FALSE) then begin
             mess:='Larm pÜ LÑnsgrop';
             dig_alm(11);
          end;
          if (num=52) and (dig_checked[12]=FALSE) then begin
             mess:='Larm pÜ BrÑnnoljenivÜ';
             dig_alm(12);
          end;
          if (num=53) and (dig_checked[13]=FALSE) then begin
             mess:='Larm pÜ Startluft tryck';
             dig_alm(13);
          end;
end;

procedure check_alarm;
var alm_num,x,y :integer;
begin
     digital[7]:=TRUE;
     for x:= 1 to 6 do begin        { Avgas Diff.}
         for y := 1 to 6 do begin
            if ad_values[11+x] > ad_values[11+y]+50 then digital[7]:=false;
            if ad_values[11+x] < ad_values[11+y]-50 then digital[7]:=false;
         end;
     end;
     for x := 0 to 5 do begin       { Kylvatten }
         if (ad_values[x]>(50*config_block.grred[1])+40) or (ad_values[x]<(50*config_block.blugr[1])+40) then begin
            if (checked_b[x] = FALSE)and(checked_r[x] = FALSE) then alarmcount[x]:=alarmcount[x]+1;
            if alarmcount[x]>alarm_at then begin
               alarm(x+1);
               alarmcount[x]:=0;
            end;
         end else begin
            alarmcount[x]:=0;
            checked_b[x]:=FALSE;
            checked_r[x]:=FALSE;
         end;
     end;
     for x := 6 to 11 do begin      { Kolvkylning }
         {test}
         if (ad_values[x] > (50*config_block.grred[2])+35) or (ad_values[x] < (50*config_block.blugr[2])+35) then begin
            if (checked_b[x] = FALSE) and (checked_r[x] = FALSE) then begin
               alarmcount[x]:=alarmcount[x]+1;
             {  inv_d_rect(240,240,480,255);
               setcolor(15);
               outtextxy(245,244,realtostr(x,0,2)+' Count:'+realtostr(alarmcount[7],0,2));
               delay(100);  }
            end;
            if alarmcount[x]>alarm_at then begin
               alm_num:=x;
               alarm(alm_num+1);
               alarmcount[x]:=0;
            end;
         end else begin
            alarmcount[x]:=0;        {   ej denna }
            checked_b[x]:=FALSE;
            checked_r[x]:=FALSE;
         end;
     end;
     for x := 12 to 17 do begin      { Avgas. }
         if (ad_values[x]>(300*config_block.grred[3])+150) or (ad_values[x]<(300*config_block.blugr[3])+150) then begin
            if (checked_b[x] = FALSE)and(checked_r[x] = FALSE) then alarmcount[x]:=alarmcount[x]+1;
            if alarmcount[x]>alarm_at then begin
               alarm(x+1);
               alarmcount[x]:=0;
         end;
         end else begin
            alarmcount[x]:=0;
            checked_b[x]:=FALSE;
            checked_r[x]:=FALSE;
         end;
{         if ad_values[x]>500*config_block.grred[x+1] then alarm(x+1) else checked_r[x]:=FALSE;
         if ad_values[x]<500*config_block.blugr[x+1] then alarm(x+1) else checked_b[x]:=FALSE;
}    end;
     for x := 18 to 19 do begin    { Spolluft }
         if (ad_values[x]>(50*config_block.grred[4])+35) or (ad_values[x]<(50*config_block.blugr[4])+35) then begin
         if (checked_b[x] = FALSE)and(checked_r[x] = FALSE) then alarmcount[x]:=alarmcount[x]+1;
            if alarmcount[x]>alarm_at then begin
               alarm(x+1);
               alarmcount[x]:=0;
         end;
         end else begin
            alarmcount[x]:=0;
            checked_b[x]:=FALSE;
            checked_r[x]:=FALSE;
         end;
{         if ad_values[x]>90*config_block.grred[x+1] then alarm(x+1) else checked_r[x]:=FALSE;
         if ad_values[x]<90*config_block.blugr[x+1] then alarm(x+1) else checked_b[x]:=FALSE;
}    end;                        { Trycklager }
     if (ad_values[20]>(50*config_block.grred[5])+35) or (ad_values[20]<(50*config_block.blugr[5])+35) then begin
         if (checked_b[20] = FALSE)and(checked_r[20] = FALSE) then alarmcount[20]:=alarmcount[20]+1;
         if alarmcount[20]>alarm_at then begin
            alarm(21);
            alarmcount[20]:=0;
         end;
     end else begin
        alarmcount[20]:=0;
        checked_b[20]:=FALSE;
        checked_r[20]:=FALSE;
     end;
{     if ad_values[20]>90*config_block.grred[21] then alarm(21) else checked_r[x]:=FALSE;
     if ad_values[20]<90*config_block.blugr[21] then alarm(21) else checked_b[x]:=FALSE;
}    for x:= 0 to 13 do begin
         if digital[x]=FALSE then begin
            if dig_checked[x] = FALSE then alarmcount[x+40]:=alarmcount[x+40]+1;
            if alarmcount[x+40]>alarm_at then begin
               alarm(x+40);
               alarmcount[x+40]:=0;
         end;
         end else begin
             alarmcount[x+40]:=0;
             dig_checked[x]:=FALSE;
         end;
     end;
end;

procedure mag_kylvatten;
label Gfx;
var ch:char;
    x,i,code: integer;
    newval:string;
begin
     mag:=TRUE;

Gfx:
     mag_larm:=FALSE;
     d_rect(0,0,getmaxx,getmaxy);
     d_rect(62,42,225,360);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(84,50+x*30,88,50+x*30);
     end;
     inv_d_rect(240,220,280,235);
     inv_d_rect(240,240,280,255);
     d_rect(240,270,252,280);
     d_rect(240,285,252,295);
     setcolor(15);
     outtextxy(243,272,'A');
     outtextxy(243,287,'B');
     outtextxy(255,272,'éndra îvre grÑnsvÑrde');
     outtextxy(255,287,'éndra undre grÑnsvÑrde');
     outtextxy(285,224,'ôvre GrÑns');
     outtextxy(285,244,'Undre GrÑns');
     outtextxy(245,224,realtostr((config_block.grred[1]*50)+40,0,2)+'¯');
     outtextxy(245,244,realtostr((config_block.blugr[1]*50)+40,0,2)+'¯');
     for x:= 1 to 6 do begin
         inv_d_rect(240,42+x*20,280,57+x*20);
         setcolor(15);
         outtextxy(285,46+x*20,'Cyl: '+realtostr(x,0,1));
     end;
     setcolor(15);
     outtextxy(69,197,'65');
     outtextxy(69,347,'40');
     outtextxy(69,47,'90');
     setcolor(7);
     outtextxy(10,10,'AvgÜende Kylvatten Temperaturer... [Esc] ètervÑnder');
      repeat
            for x:= 1 to 6 do begin
                inv_d_rect(240,42+x*20,280,57+x*20);
                setcolor(15);
                outtextxy(245,46+x*20,realtostr(ad_values[x-1],0,4));
            end;
            read_cards;
            check_alarm;
            if mag_larm=TRUE then Goto Gfx;

            y_meter(300,100,350,(ad_values[0]-40)/50,config_block.grred[1],config_block.blugr[1],2);
            y_meter(300,120,350,(ad_values[1]-40)/50,config_block.grred[1],config_block.blugr[1],2);
            y_meter(300,140,350,(ad_values[2]-40)/50,config_block.grred[1],config_block.blugr[1],2);
            y_meter(300,160,350,(ad_values[3]-40)/50,config_block.grred[1],config_block.blugr[1],2);
            y_meter(300,180,350,(ad_values[4]-40)/50,config_block.grred[1],config_block.blugr[1],2);
            y_meter(300,200,350,(ad_values[5]-40)/50,config_block.grred[1],config_block.blugr[1],2);
            if keypressed then ch:=readkey;
            if UpCase(ch) = 'A' then begin
               inv_d_rect(240,220,280,235);
               repeat
                     setcolor(15);
                     newval:=input(245,224,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,220,280,235);
               until (I<91) and (I>39);
               config_block.grred[1]:=(I-40)/50;
               inv_d_rect(240,220,280,235);
               setcolor(15);
               outtextxy(245,224,realtostr((config_block.grred[1]*50)+40,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
            if UpCase(ch) = 'B' then begin
               inv_d_rect(240,240,280,255);
               repeat
                     setcolor(15);
                     newval:=input(245,244,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,240,280,255);
               until (I<91) and (I>39);
               config_block.blugr[1]:=(I-40)/50;
               inv_d_rect(240,240,280,255);
               setcolor(15);
               outtextxy(245,244,realtostr((config_block.blugr[1]*50)+40,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
      until ch = #27;
      mag:=FALSE;
      init_gfx;
end;

procedure mag_kolvkyln;
label Gfx;
var ch:char;
    x,i,code: integer;
    newval:string;
begin
     mag:=TRUE;

Gfx:
     mag_larm:=FALSE;
     d_rect(0,0,getmaxx,getmaxy);
     d_rect(62,42,225,360);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(84,50+x*30,88,50+x*30);
     end;
     inv_d_rect(240,220,280,235);
     inv_d_rect(240,240,280,255);
     d_rect(240,270,252,280);
     d_rect(240,285,252,295);
     setcolor(15);
     outtextxy(243,272,'A');
     outtextxy(243,287,'B');
     outtextxy(255,272,'éndra îvre grÑnsvÑrde');
     outtextxy(255,287,'éndra undre grÑnsvÑrde');
     outtextxy(285,224,'ôvre GrÑns');
     outtextxy(285,244,'Undre GrÑns');
     outtextxy(245,224,realtostr((config_block.grred[2]*50)+35,0,2)+'¯');
     outtextxy(245,244,realtostr((config_block.blugr[2]*50)+35,0,2)+'¯');
     for x:= 1 to 6 do begin
         inv_d_rect(240,42+x*20,280,57+x*20);
         setcolor(15);
         outtextxy(285,46+x*20,'Cyl: '+realtostr(x,0,1));
     end;
     setcolor(15);
     outtextxy(69,197,'60');
     outtextxy(69,347,'35');
     outtextxy(69,47,'85');
     setcolor(7);
     outtextxy(10,10,'Kolvkylnings Temperaturer... [Esc] ètervÑnder');
      repeat
            for x:= 1 to 6 do begin
                inv_d_rect(240,42+x*20,280,57+x*20);
                setcolor(15);
                outtextxy(245,46+x*20,realtostr(ad_values[x+5],0,4));
            end;
            read_cards;
            check_alarm;
            if mag_larm=TRUE then Goto Gfx;
            y_meter(300,100,350,(ad_values[6]-35)/50,config_block.grred[2],config_block.blugr[2],2);
            y_meter(300,120,350,(ad_values[7]-35)/50,config_block.grred[2],config_block.blugr[2],2);
            y_meter(300,140,350,(ad_values[8]-35)/50,config_block.grred[2],config_block.blugr[2],2);
            y_meter(300,160,350,(ad_values[9]-35)/50,config_block.grred[2],config_block.blugr[2],2);
            y_meter(300,180,350,(ad_values[10]-35)/50,config_block.grred[2],config_block.blugr[2],2);
            y_meter(300,200,350,(ad_values[11]-35)/50,config_block.grred[2],config_block.blugr[2],2);
            if keypressed then ch:=readkey;
            if UpCase(ch) = 'A' then begin
               inv_d_rect(240,220,280,235);
               repeat
                     setcolor(15);
                     newval:=input(245,224,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,220,280,235);
               until (I<91) and (I>34);
               config_block.grred[2]:=(I-35)/50;
               inv_d_rect(240,220,280,235);
               setcolor(15);
               outtextxy(245,224,realtostr((config_block.grred[2]*50)+35,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
            if UpCase(ch) = 'B' then begin
               inv_d_rect(240,240,280,255);
               repeat
                     setcolor(15);
                     newval:=input(245,244,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,240,280,255);
               until (I<91) and (I>34);
               config_block.blugr[2]:=(I-35)/50;
               inv_d_rect(240,240,280,255);
               setcolor(15);
               outtextxy(245,244,realtostr((config_block.blugr[2]*50)+35,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
      until ch = #27;
      mag:=FALSE;
      init_gfx;
end;

procedure mag_avgas;
label Gfx;
var ch:char;
    x,i,code: integer;
    newval:string;
begin
     mag:=TRUE;

Gfx:
     mag_larm:=FALSE;
     d_rect(0,0,getmaxx,getmaxy);
     d_rect(56,42,225,360);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(84,50+x*30,88,50+x*30);
     end;
     inv_d_rect(240,220,280,235);
     inv_d_rect(240,240,280,255);
     d_rect(240,270,252,280);
     d_rect(240,285,252,295);
     setcolor(15);
     outtextxy(243,272,'A');
     outtextxy(243,287,'B');
     outtextxy(255,272,'éndra îvre grÑnsvÑrde');
     outtextxy(255,287,'éndra undre grÑnsvÑrde');
     outtextxy(285,224,'ôvre GrÑns');
     outtextxy(285,244,'Undre GrÑns');
     outtextxy(245,224,realtostr((config_block.grred[3]*300)+150,0,2)+'¯');
     outtextxy(245,244,realtostr((config_block.blugr[3]*300)+150,0,2)+'¯');
     for x:= 1 to 6 do begin
         inv_d_rect(240,42+x*20,280,57+x*20);
         setcolor(15);
         outtextxy(285,46+x*20,'Cyl: '+realtostr(x,0,1));
     end;
     setcolor(15);
     outtextxy(61,197,'300');
     outtextxy(61,347,'150');
     outtextxy(61,47,'450');
     setcolor(7);
     outtextxy(10,10,'Avgas Temperaturer... [Esc] ètervÑnder');
      repeat
            for x:= 1 to 6 do begin
                inv_d_rect(240,42+x*20,280,57+x*20);
                setcolor(15);
                outtextxy(245,46+x*20,realtostr(ad_values[x+11],0,4));
            end;
            read_cards;
            check_alarm;
            if mag_larm=TRUE then Goto Gfx;
            y_meter(300,100,350,(ad_values[12]-150)/300,config_block.grred[3],config_block.blugr[3],2);
            y_meter(300,120,350,(ad_values[13]-150)/300,config_block.grred[3],config_block.blugr[3],2);
            y_meter(300,140,350,(ad_values[14]-150)/300,config_block.grred[3],config_block.blugr[3],2);
            y_meter(300,160,350,(ad_values[15]-150)/300,config_block.grred[3],config_block.blugr[3],2);
            y_meter(300,180,350,(ad_values[16]-150)/300,config_block.grred[3],config_block.blugr[3],2);
            y_meter(300,200,350,(ad_values[17]-150)/300,config_block.grred[3],config_block.blugr[3],2);
            if keypressed then ch:=readkey;
            if UpCase(ch) = 'A' then begin
               inv_d_rect(240,220,280,235);
               repeat
                     setcolor(15);
                     newval:=input(245,224,3,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,220,280,235);
               until (I<451) and (I>149);
               config_block.grred[3]:=(I-150)/300;
               inv_d_rect(240,220,280,235);
               setcolor(15);
               outtextxy(245,224,realtostr((config_block.grred[3]*300)+150,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
            if UpCase(ch) = 'B' then begin
               inv_d_rect(240,240,280,255);
               repeat
                     setcolor(15);
                     newval:=input(245,244,3,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,240,280,255);
               until (I<451) and (I>149);
               config_block.blugr[3]:=(I-150)/300;
               inv_d_rect(240,240,280,255);
               setcolor(15);
               outtextxy(245,244,realtostr((config_block.blugr[3]*300)+150,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
      until ch = #27;
      mag:=FALSE;
      init_gfx;
end;

procedure mag_spolluft;
label Gfx;
var ch:char;
    x,i,code: integer;
    newval:string;
begin
     mag:=TRUE;

Gfx:
     mag_larm:=FALSE;
     d_rect(0,0,getmaxx,getmaxy);
     d_rect(142,42,225,360);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(164,50+x*30,168,50+x*30);
     end;
     inv_d_rect(240,220,280,235);
     inv_d_rect(240,240,280,255);
     d_rect(240,270,252,280);
     d_rect(240,285,252,295);
     setcolor(15);
     outtextxy(243,272,'A');
     outtextxy(243,287,'B');
     outtextxy(255,272,'éndra îvre grÑnsvÑrde');
     outtextxy(255,287,'éndra undre grÑnsvÑrde');
     outtextxy(285,224,'ôvre GrÑns');
     outtextxy(285,244,'Undre GrÑns');
     outtextxy(245,224,realtostr((config_block.grred[4]*50)+35,0,2)+'¯');
     outtextxy(245,244,realtostr((config_block.blugr[4]*50)+35,0,2)+'¯');
     for x:= 1 to 2 do begin
         inv_d_rect(240,42+x*20,280,57+x*20);
         setcolor(15);
         outtextxy(285,46+x*20,'Insug: '+realtostr(x,0,1));
     end;
     setcolor(15);
     outtextxy(149,197,'60');
     outtextxy(149,347,'35');
     outtextxy(149,47,'85');
     setcolor(7);
     outtextxy(10,10,'Spollufts Temperaturer... [Esc] ètervÑnder');
      repeat
            for x:= 1 to 2 do begin
                inv_d_rect(240,42+x*20,280,57+x*20);
                setcolor(15);
                outtextxy(245,46+x*20,realtostr(ad_values[x+17],0,4));
            end;
            read_cards;
            check_alarm;
            if mag_larm=TRUE then Goto Gfx;
            y_meter(300,180,350,(ad_values[18]-35)/50,config_block.grred[4],config_block.blugr[4],2);
            y_meter(300,200,350,(ad_values[19]-35)/50,config_block.grred[4],config_block.blugr[4],2);
            if keypressed then ch:=readkey;
            if UpCase(ch) = 'A' then begin
               inv_d_rect(240,220,280,235);
               repeat
                     setcolor(15);
                     newval:=input(245,224,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,220,280,235);
               until (I<91) and (I>34);
               config_block.grred[4]:=(I-35)/50;
               inv_d_rect(240,220,280,235);
               setcolor(15);
               outtextxy(245,224,realtostr((config_block.grred[4]*50)+35,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
            if UpCase(ch) = 'B' then begin
               inv_d_rect(240,240,280,255);
               repeat
                     setcolor(15);
                     newval:=input(245,244,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,240,280,255);
               until (I<91) and (I>34);
               config_block.blugr[4]:=(I-35)/50;
               inv_d_rect(240,240,280,255);
               setcolor(15);
               outtextxy(245,244,realtostr((config_block.blugr[4]*50)+35,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
      until ch = #27;
      mag:=FALSE;
      init_gfx;
end;

procedure mag_Trycklager;
label Gfx;
var ch:char;
    x,i,code: integer;
    newval:string;
begin
     mag:=TRUE;

Gfx:
     mag_larm:=FALSE;
     d_rect(0,0,getmaxx,getmaxy);
     d_rect(162,42,225,360);
     setcolor(15);
     for x:= 0 to 10 do begin
         line(184,50+x*30,188,50+x*30);
     end;
     inv_d_rect(240,220,280,235);
     inv_d_rect(240,240,280,255);
     d_rect(240,270,252,280);
     d_rect(240,285,252,295);
     setcolor(15);
     outtextxy(243,272,'A');
     outtextxy(243,287,'B');
     outtextxy(255,272,'éndra îvre grÑnsvÑrde');
     outtextxy(255,287,'éndra undre grÑnsvÑrde');
     outtextxy(285,224,'ôvre GrÑns');
     outtextxy(285,244,'Undre GrÑns');
     outtextxy(245,224,realtostr((config_block.grred[5]*50)+35,0,2)+'¯');
     outtextxy(245,244,realtostr((config_block.blugr[5]*50)+35,0,2)+'¯');
     inv_d_rect(240,42+1*20,280,57+1*20);
     setcolor(15);
     outtextxy(169,197,'60');
     outtextxy(169,347,'35');
     outtextxy(169,47,'85');
     setcolor(7);
     outtextxy(10,10,'Trycklager Temperatur... [Esc] ètervÑnder');
      repeat
                inv_d_rect(240,42+1*20,280,57+1*20);
                setcolor(15);
                outtextxy(245,46+1*20,realtostr(ad_values[20],0,4));

            read_cards;
            check_alarm;
            if mag_larm=TRUE then Goto Gfx;
            y_meter(300,200,350,(ad_values[20]-35)/50,config_block.grred[5],config_block.blugr[5],2);
            if keypressed then ch:=readkey;
            if UpCase(ch) = 'A' then begin
               inv_d_rect(240,220,280,235);
               repeat
                     setcolor(15);
                     newval:=input(245,224,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,220,280,235);
               until (I<91) and (I>34);
               config_block.grred[5]:=(I-35)/50;
               inv_d_rect(240,220,280,235);
               setcolor(15);
               outtextxy(245,224,realtostr((config_block.grred[5]*50)+35,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
            if UpCase(ch) = 'B' then begin
               inv_d_rect(240,240,280,255);
               repeat
                     setcolor(15);
                     newval:=input(245,244,2,5,'');
                     Val(newval, I, Code);
                     inv_d_rect(240,240,280,255);
               until (I<91) and (I>34);
               config_block.blugr[5]:=(I-35)/50;
               inv_d_rect(240,240,280,255);
               setcolor(15);
               outtextxy(245,244,realtostr((config_block.blugr[5]*50)+35,0,2)+'¯');
               ch:=#0;
               save_cfg;
            end;
      until ch = #27;
      mag:=FALSE;
      init_gfx;
end;

Procedure key_loop;
var
     ch :char;
     x: integer;
     bupp,bupp2: string[5];
begin
     while keypressed do ch:=readkey;
     ch:=#0;
repeat
{     outtextxy(580,420,realtostr(tmp2,0,4));      Visa Digital vÑrden pÜ skÑrmen
     outtextxy(580,400,realtostr(tmp,0,4));   }
     get_time;
     read_cards;
     draw_meters;
     draw_dig;
     check_alarm;
     { TEst }

     if keypressed then begin
        ch:=upcase(readkey);
        {ss_timer:=50; }
     end;

     if ch = #59 then begin
        mag_kylvatten;
        ch:=#0;
     end;
     if ch = #60 then begin
        mag_kolvkyln;
        ch:=#0;
     end;
     if ch = #61 then begin
        mag_avgas;
        ch:=#0;
     end;
     if ch = #62 then begin
        mag_spolluft;
        ch:=#0;
     end;
     if ch = #63 then begin
        mag_trycklager;
        ch:=#0;
     end;
     if ch = #68 then begin
        for x := 0 to 31 do begin
            checked_b[x]:=false;
            checked_r[x]:=false;
            dig_checked[x]:=false;
        end;
        larmed:='Larmstatus: Inget Larm Rapporterat...';
        init_gfx;
        ch:=#0;
     end;
     {if ss_timer=240 then blank_screen;}

     {if ss_timer>0 then ss_timer:=ss_timer-1;}
until ch = #255
end;


BEGIN
   for main_x:=0 to 31 do begin
       checked_r[main_x]:=false;
       checked_b[main_x]:=false;
       dig_checked[main_x]:=false;
   end;
   for main_x:=0 to 70 do alarmcount[main_x]:=0;
   ss_timer:=0;
   port[$1b0+2]:=0;
   port[$1B0+2]:=0;
   start_gfx;
   larmed:='Larmstatus: Inget Larm Rapporterat...';
strt:
   init_gfx;
   key_loop;
{   if config_block.menupw <>'' then begin
      d_rect(20,100,620,130);
      setcolor(3);
      outtextxy(40,110,'Ange lîsen:');
      setcolor(4);
      pw:=input(135,110,20,2,'');
      if pw<>config_block.menupw then begin
         d_rect(20,100,620,130);
         setcolor(9);
         outtextxy(40,110,'Fel lîsen ÜtervÑnder...');
         delay(2000);
         goto strt;
      end;
   end;  }
      closegraph;
      freemem(dpointer, dsize);
      restorecrtmode;
      textcolor(white);
      textbackground(0);
      clrscr;
      writeln('Gibb 1.21 Av Jimmy Larsson 1996 (C)1994-96 Garant Electronic.');
      textcolor(lightgray);
END.
