unit Unit1;
{���������� �������� �. �.
��� ��������� �������}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ExtCtrls, Menus, Types, math, Unit2, Unit3, Unit4;

const size_vertex=20;
      level_height=80;

type TMatrix=array of array of double;
      TBoolArray=array of boolean;
      TSPProblem=class //����� ��� ������� ������ �����������
          SG:TStringGrid;//������ �� �������
          img:Timage;//������ �� ����� ��� ���������
          memo:Tmemo;//������ �� ��������� ����
          Matrix:TMatrix;//������� ����������
          path:string;//������� ����
          n,col,row:integer;//n - ���������� �����
          opt:double;//�������� �������� �������
          editmode,scrolling:boolean;
          x0,y0,x_click,y_click:integer;
          bmp:TBitmap;
          public   //������������ ���������� ������������
           constructor Create(sg_:TStringGrid;img_:TImage;memo_:Tmemo); //�������� ������ ��� ������
           procedure FindOptPath;//��������� ������ ������������ ����
           procedure OpenFile;//������� ����
           procedure SaveFile;//��������� ����
           procedure AddVertex;//�������� �����
           procedure DeleteVertex; //������� �����
          private   //���������� ������ ������
           {overload - ��������������� ������� ��� ������� ������ ����������}
           procedure DrawVertex(i:integer;x,y,prev_x,prev_y,res:double;color:TColor);overload;//�������� �������
           procedure DrawVertex(i:integer;x,y:double);overload;//��������� �������� �������
           procedure DrawGraph;//��������� �����
           procedure ShowGraph;//��������� �����
           procedure SetEditText(Sender: TObject; ACol, ARow: Integer;const Value: string);
           procedure GetEditText(Sender: TObject; ACol, ARow: Integer;var Value: string);
           procedure KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
           procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
           procedure MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
           procedure MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
           function F0:double;//������� ���������� �������� ���������� �������� �������
           procedure RecFindPath(k,marked_count:integer;res,x,y,dx:double;path_:string;marked:TBoolArray);//����������� ��������� ������ ����
      end;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    Image1: TImage;
    Memo1: TMemo;
    StringGrid1: TStringGrid;
    N8: TMenuItem;
    N9: TMenuItem;
    OpenDialog1: TOpenDialog;
    N10: TMenuItem;
    N11: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure N9Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  problem:TSPProblem; //��������� ������

implementation
uses ComObj;

{$R *.dfm}

{ TSPProblem }

{��������� �������}
procedure TSPProblem.AddVertex;
var
  i: Integer;
begin
 if (n < 10) then
 begin
    inc(n);
    SG.ColCount:=n;
    SG.RowCount:=n;
    SetLength(Matrix,n,n); //������������� ������������ ������ n x n
    SG.ColWidths[n-1]:=40;
    for i := 0 to n-1 do
    begin
      SG.Cells[n-1,i]:='0';
      SG.Cells[i,n-1]:='0';
      Matrix[n-1,i]:=0;
      Matrix[i,n-1]:=0;
    end;
    DrawGraph; //������ ���� �� �������
 end;
end;

{����������� ������ - �������� ������ ��� ������, �����}
constructor TSPProblem.Create(sg_: TStringGrid; img_: TImage; memo_: TMemo);
var
  i,j: Integer;
begin
  sg:=sg_;
  img:=img_;
  memo:=memo_;
  n:=5;    //���������� 5�5
  editmode:=false;
  sg.ColCount:=n;
  sg.RowCount:=n;
  SetLength(Matrix,n,n);
  for i := 0 to n-1 do
  begin
    sg.ColWidths[i]:=40;
    for j := 0 to n-1 do
    begin
      Matrix[i,j]:=0;
      SG.Cells[j,i]:='0';
    end;
  end;
  img.Canvas.Brush.Color:=clWhite;
  img.Canvas.FillRect(Rect(0,0,img.Width,img.Height));
  sg.OnSetEditText:=SetEditText;
  sg.OnGetEditText:=GetEditText;
  sg.OnKeyDown:=KeyDown;
  img.OnMouseDown:=MouseDown;
  img.OnMouseup:=MouseUP;
  img.OnMouseMove:=MouseMove;
  scrolling:=false;
  x0:=0;
  y0:=0;
  bmp:=TBitmap.Create;
  bmp.Height:=img.Height*2;
  bmp.Width:=img.Width*10;
  //DrawGraph;
end;

{������� �������}
procedure TSPProblem.DeleteVertex;
begin
  if (n > 3) then
  begin
    dec(n);    //���������
    SG.ColCount:=n;
    SG.RowCount:=n;
    SetLength(Matrix,n,n); //����� ���. ������
    DrawGraph;     //�������
  end;
end;

{������ �������}
procedure TSPProblem.DrawVertex(i: integer; x, y, prev_x, prev_y, res:double;color: TColor);
begin   //res - ������� ����� ����������
  bmp.Canvas.Pen.Color:=ClBlack;//������������ ���� ����� ������
  bmp.Canvas.MoveTo(round(prev_x + (size_vertex / 2)), round(prev_y + size_vertex));
  bmp.Canvas.LineTo(round(x + (size_vertex / 2)), round(y));//�������� ���� ������
  bmp.Canvas.Rectangle(Rect(round(x), round(y), round(x + size_vertex),round(y + size_vertex)));//��������� ���������� ������� ������
  bmp.Canvas.Font.Color:=color;
  bmp.Canvas.TextOut(round(x + (size_vertex / 4)),round(y + (size_vertex / 4)), IntToStr(i));//����������� ����� �������
  bmp.Canvas.TextOut(round((prev_x + x)/ 2),round((prev_y + y)/ 2), FloatToStr(res));//����������� ��������� ���������
end;

{������ ����}
procedure TSPProblem.DrawGraph;
var i,j:integer;
  x,y,xp,yp,p,q,x0,y0,h,xm,ym,a,xc,yc,r,alpha:double;
  bmp_gr:TBitmap;
begin
  bmp_gr:=TBitmap.Create;//������������� ������������ ������ ��� �����
  bmp_gr.Height:=form2.image2.Height;
  bmp_gr.Width:=form2.image2.Width;
  bmp_gr.Canvas.Pen.Color:=ClBlack;
  {-----------------�������� ���������------------------}
  x0:=bmp_gr.Width/2;  //�����
  y0:=bmp_gr.Height/2; //������������ ������
  r:=200;//� ������ ��������� �����
  h:=(2*pi)/n;   //������� ���������� ����� ��������� �����
  alpha:=pi/1.25;//��������� ���� ����
  {----------------------������ ����-----------------------}
  for i:=0 to n-1 do  //������ �� ������� i � j
    for j:=0 to n-1 do
    begin
      if((i<>j) and (Matrix[i,j]<>Infinity))  then //���� �� �������������
      begin  //���� ������������� ����� �� ������
        x:=x0+r*cos(i*h)+size_vertex/2;     //���������� ������ 1�
        y:=y0+r*sin(i*h)+size_vertex/2;
        xp:=x0+r*cos(j*h)+size_vertex/2;  //���������� ������ 2�
        yp:=y0+r*sin(j*h)+size_vertex/2;
        xc:=(x+xp)/2;
        yc:=(y+yp)/2;
        p:=xp-x;  //������ ������� � ����
        q:=yp-y;
        a:=sqrt(p*p+q*q)/(2*cos(alpha/2));  //���������� ����� ������� ����������
        //d:=asqrt(p*p+q*q)/2;        //���� � ��������� ����� ���������
        //xm:=q*sqrt(3)/2+xc;ym:=-p*sqrt(3)/2+yc;
        xm:=(q/2)*Cot((pi-alpha)/2)+xc;  //����� ���������� ����
        ym:=-(p/2)*Cot((pi-alpha)/2)+yc;
        bmp_gr.Canvas.Arc(round(xm-a),round(ym-a),round(xm+a),round(ym+a), round(x),round(y),round(xp),round(yp));  //������ ����
        bmp_gr.Canvas.TextOut(round(xc+(q/40)*Cot((pi/2-alpha)/2)-5),round(yc-(p/40)*Cot((pi/2-alpha)/2)-5),FloatToStr(Matrix[i,j]));//������� ����
        //bmp_gr.Canvas.MoveTo(round(x),round(y));
        //bmp_gr.Canvas.LineTo(round(xp),round(yp));
      end;
    end;
  for i:=0 to n-1 do //������ �������
  begin
    x:=x0+r*cos(i*h);
    y:=y0+200*sin(i*h);
    bmp_gr.Canvas.Ellipse(Rect(round(x),round(y),round(x+size_vertex),round(y+size_vertex)));//��������� �������
    bmp_gr.Canvas.TextOut(round(x+(size_vertex/4)),round(y+(size_vertex/4)),IntToStr(i+1))//������� �������
  end;
  form2.image2.Canvas.Draw(0,0,bmp_gr);
end;

{������ �������� ������� �� ������}
procedure TSPProblem.DrawVertex(i: integer; x, y:double);
begin
  bmp.Canvas.Pen.Color:=ClBlack;
  bmp.Canvas.Rectangle(Rect(round(x),round(y),round(x+size_vertex),round(y+size_vertex)));
  bmp.Canvas.TextOut(round(x+(size_vertex/4)),round(y+(size_vertex/4)),IntToStr(i))
end;

{���� ��������� ������� ����}
function TSPProblem.F0: double;
var sum:double;
  i,next,next1: Integer;
begin
  sum:=0;
  path:=path+'1-';  //��� ������
  for i := 0 to n-1 do
  begin
    next:=(i+1) mod n;
    sum:=sum + Matrix[i,next];
    next1:=(next+1);
    path:=path+IntToStr(next1)+'-';  //������ � �������
  end;
  path:=copy(path,0,length(path)-1);
  result:=sum;  //�������� ������� ����
end;

{����������� ����}
procedure TSPProblem.FindOptPath;
var marked:TBoolArray; //������ ���������� ������
    i:integer;
begin
  x0:=(img.Width div 2)-(bmp.width div 2);
  y0:=0;
  img.Canvas.Brush.Color:=clWhite;
  img.Canvas.FillRect(Rect(0,0,img.Width,img.Height));
  memo.Text:='';
  opt:=f0;//��������� ������� ������� (����� �������)
  SetLength(marked,n-1);//������������� ������� ���������� ������
  for i := 0 to n-2 do
    marked[i]:=false;
  //FillChar(marked,n-1,0);
  DrawVertex(1,bmp.Width/2,10); //��������� �������� �������
  memo.Text:=memo.Text+'� �������� �������� ������� ����� ����: '+path; //�������� � memo �������� �������
  memo.Text:=memo.Text+#13#10+'���������� �������� ����: '+FloatTostr(opt);
  {{----------------�������� 410---------------------------}
  RecFindPath(0,0,0,bmp.Width/2,10,410,'1-',marked);//����������� ����� ������������ ����
  img.Canvas.Draw(x0,y0,bmp);//����������� �� ������������ ������
  memo.Text:=memo.Text+#13#10+'����������� ����: '+path+#13#10+'����������� ����������: '+FloatTostr(opt);
end;

{��� ��������� ������}
procedure TSPProblem.GetEditText(Sender: TObject; ACol, ARow: Integer;var Value: string);
begin
  editmode:=true;
  col:=ACol;
  row:=ARow;
end;

procedure TSPProblem.KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key=Vk_return) then  //enter
  begin
    editmode:=false;
    SG.Cells[Col, Row]:=FloatTostr(Matrix[Row,Col]);
    DrawGraph;
  end;
end;

procedure TSPProblem.MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  scrolling:=true; //������ �� ������
  x_click:=x;        //�������� ����������
  y_click:=y;
end;

procedure TSPProblem.MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
  var dx,dy:integer;
begin
  if (scrolling) then //��� ���������
  begin
    dx:=x-x_click;
    dy:=y-y_click;
    x_click:=x;y_click:=y;
    x0:=x0+dx;
    y0:=y0+dy;
    img.Canvas.FillRect(Rect(0,0,img.Width,img.Height));
    img.Canvas.Draw(x0,y0,bmp);
    //form1.label1.caption:=x0.ToString+' '+y0.ToString;
  end;
end;

procedure TSPProblem.MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  scrolling:=false;
end;

{�������� �����}
procedure TSPProblem.OpenFile;
var OD:TOpenDialog;
  filename:string;
  F:File of double;
  i,j: Integer;
  p:double;
begin
  OD:=TOpenDialog.Create(nil);
  OD.InitialDir:=extractfilepath(Application.ExeName);
  {------------��� txt/dat------------}
  OD.Filter:='�������(*.txt)|*.txt';
  //OD.Filter:='�������(*.dat)|*.dat';
  if Not(OD.Execute) then
    Exit;
  filename:=OD.FileName;
  AssignFile(F,Filename);
  Reset(F);
  read(F,p);
  n:=round(p);
  SG.ColCount:=n;
  SG.RowCount:=n;
  SetLength(Matrix,n,n);
  for i := 0 to n-1 do
  begin
    for j := 0 to n-1 do
    begin
      read(F,Matrix[i,j]);
      SG.Cells[j,i]:=FloatToStr(Matrix[i,j]);
    end;
  end;
  Close(F);
end;

{����������� ����� ����}
procedure TSPProblem.RecFindPath(k, marked_count: integer; res, x, y, dx: double; path_: string; marked: TBoolArray);
var f,x_new,y_new,new_res:double;
  clr:TColor;
  p,i,j:integer;
  right_path:boolean; //���������� ����
  new_marked:TBoolArray;//������ ���������� ������
begin
  if(marked_count = n - 1) then//���� �������� ����������� �������
  begin
    f:=res + Matrix[k,0];
    x_new:=x;
    y_new:=level_height+y;
    clr:=ClGreen;
    if(f < opt) then //���� �������� �������������� ���� ������ ��������
    begin
      opt:=f;
      path:=path_+'1';
      memo.Text:=memo.Text+#13#10+'����� ������� ����: '+path;
      memo.Text:=memo.Text+#13#10+'���������� �������� ����: '+FloatToStr(opt)+#13#10;
    end
    else
    begin
      memo.Text:=memo.Text+#13#10+'���������� ����: ('+path_+'1) ����� '+FloatToStr(f)+'>='+FloatToStr(opt)+#13#10;
      clr:=ClRed; //��� ������ �������� �������
    end;
    DrawVertex(1,x_new,y_new,x,y,f,clr);
  end
  else //���������� ������������� �����
  begin
    p:=0;
    for i := 1 to n-1 do
    begin
      new_res:=res+Matrix[k,i];//������������ � ��������� ��������
      right_path:=new_res < Opt;//�������� �� ������������� ��������� ����
      clr:=clBlack;
      x_new:=(x-dx*(n-marked_count-2)/2)+p*dx;
      y_new:=level_height+y;
      if(not(right_path) and not(marked[i-1])) then//���� �������� ��������� ���� ������ ��������, �� ���������� ������� � �������� �����
      begin
        memo.Text:=memo.Text+#13#10+'���������� ��������� ���� ('+path_+IntToStr(i+1)+') ����� '+FloatToStr(new_res)+'>='+FloatToStr(opt)+#13#10;
        clr:=ClRed; //�������� �������
        DrawVertex(i+1,x_new,y_new,x,y,new_res,clr);//��������� ������� ������ ��������� ����
        inc(p);
      end;
      if(right_path and not(marked[i-1]))then//���� ���� ���� ����������, ������������ ���������� �� �����
      begin
        SetLength(new_marked,n-1);
        for j := 0 to n-2 do
          new_marked[j]:=marked[j];
        new_marked[i-1]:=true;
        DrawVertex(i+1,x_new,y_new,x,y,new_res,clr);
        RecFindPath(i,marked_count+1,new_res,x_new,y_new,dx/3,path_+IntToStr(i+1)+'-',new_marked);//���������� ����� ������������ ����
        p:=p+1;
      end;
    end;
  end;
end;

procedure TSPProblem.SaveFile;
var SD:TSaveDialog;
  filename:string;
  F:File of double;
  i,j: Integer;
  p:double;
begin
  SD:=TSaveDialog.Create(nil);
  SD.InitialDir:=extractfilepath(Application.ExeName);
  {------------��� txt/dat------------}
  SD.Filter:='�������(*.txt)|*.txt';
  //SD.Filter:='�������(*.dat)|*.dat'; ������� ������
  if Not(SD.Execute) then
    Exit;
  filename:=SD.FileName;
  AssignFile(F,Filename+'.txt');
  ReWrite(F);
  p:=n;
  Write(F, p);
  for i := 0 to n-1 do
  begin
    for j := 0 to n-1 do
    begin
      write(F,Matrix[i,j]);
    end;
  end;
  Close(F);
end;

procedure TSPProblem.SetEditText(Sender: TObject; ACol, ARow: Integer;const Value: string);
begin
  if(editmode) then
  begin
    if(SG.Cells[ACol, ARow]='00') then //������ 00 ��� inf
    begin
        Matrix[ARow,ACol]:=infinity;
    end
    else
      TryStrToFloat(SG.Cells[ACol, ARow],Matrix[ARow,ACol]);
    //SG.Cells[ACol, ARow]:=Matrix[ARow,ACol].ToString;
    //Exit;
  end
  else
    SG.Cells[ACol, ARow]:=FloatToStr(Matrix[ARow,ACol]);
   //editmode:=false;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  problem:=TSPProblem.Create(stringgrid1,image1,memo1);
//form2.Image2.Refresh;
end;

{-----�������������� ������-------}
procedure TForm1.N2Click(Sender: TObject);
begin
  problem.OpenFile;
end;

procedure TForm1.N3Click(Sender: TObject);
begin
  problem.SaveFile;
end;

procedure TForm1.N4Click(Sender: TObject);
begin
  close;
end;

procedure TForm1.N8Click(Sender: TObject);
begin
  problem.AddVertex;
end;

procedure TForm1.N9Click(Sender: TObject);
begin
  problem.DeleteVertex;
end;

procedure TForm1.N7Click(Sender: TObject);
begin
  problem.FindOptPath;
end;

procedure TForm1.N10Click(Sender: TObject);
begin
  problem.ShowGraph;
end;

procedure TSPProblem.ShowGraph;
begin
  Form2.Show;
  DrawGraph;
end;

procedure TForm1.N6Click(Sender: TObject);
begin
  Form3.ShowModal;
end;

procedure TForm1.N11Click(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

end.
