unit frmMain;
{********************************************************************}
{*     CAD - ������� ������������ ������ ��������.                  *}
{* ���������� ��������� ����������.                                 *}
{* ���������� ����������� ����������� ���������� �.�.               *}
{* ��� �������� ����������� ������� "X","Y","Z".                    *}
{* �������� � �������� ������� - �� �� ������� + SHIFT              *}
{* + � - : ������������ / ���������.                                *}
{* ������ ����            mail to: s_please@chat.ru                 *}
{********************************************************************}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  OpenGL, ExtCtrls, ComCtrls;

type
  TfrmItem = class(TForm)
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);

  private
    DC: HDC;
    hrc: HGLRC;
    Angle, dist, dist2, dist_inf, ViewAngle: GLfloat;
    AngleX, AngleY, AngleZ: GLfloat;
    Palette: HPalette;

    procedure DrawScene;
    procedure InitializeRC;
    procedure SetDCPixelFormat;

  protected
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMQueryNewPalette(var Msg: TWMQueryNewPalette); message WM_QUERYNEWPALETTE;
    procedure WMPaletteChanged(var Msg: TWMPaletteChanged); message WM_PALETTECHANGED;
  end;

const
 cylRadius=0.25;
 cylHeight=1.5;
 Down=2.7;      // ���������� �� �������
 cylH=0.15;     // ���������� ����������� ������ ������� ���������
 cylHn=0.2;     // ���������� ����������� ������ ������� ��������
 cylRn=0.85;    // ���������� ����������� ������� ������� ��������
 plH=0.15;      // ���������� ����������� ������ ��������

var
  frmItem: TfrmItem;          //�����
  s, x0, y0, path {��� ����������},
  lastpoint, last:GLfloat;
  ObjCylinder1, ObjCylinder2, ObjDisk1, ObjDisk2,  //  ���������� �������
  ObjCylinder3, ObjCone : GLUquadricObj ;          //
  Back, Back2:boolean;
  FirstStep,                //  ����������, ������������
  SecondStep,               //  ����� ������ ����������.
  ThirdStep,                //  �� ������ ����� ������
  FourthStep,               //  �������� ��������
  FifthStep,                //
  SixthStep: boolean;       //

implementation

{$R *.DFM}

{=======================================================================
������������� ��������� �����}
procedure TfrmItem.InitializeRC;
const
  // ������� �������� ����� ���������
  glfLightAmbient : Array[0..3] of GLfloat = (0.1, 0.1, 0.1, 1.0);
  // ������� ��������� ������� ���������
  glfLightDiffuse : Array[0..3] of GLfloat = (1.0003, 1.3003, 1.333, 1.2);
  // ������� ����������� �����
  glfLightSpecular: Array[0..3] of GLfloat = (0.05, 0.05, 0.05, 1.0);
  glfLightSpecular1: Array[0..3] of GLfloat = (1.0, 1.0, 1.0, 1.0);
  // ��������� ������� ��������� �����
  glfLightPosition: Array[0..3] of GLfloat= (0.0, 0.0, -3.0, 0.0);
  glfLightSpotDir: Array[0..2] of GLfloat = (0.0, 0.0, 0.5);
  //���� ������
  glfFogColor: Array[0..3] of GLfloat = (0.4, 0.4, 0.7, 0.5);

begin
  glEnable(GL_NORMALIZE);             // ��������� ������������
  glEnable(GL_DEPTH_TEST);            // ��������� ���� �������

  // ��������� �������� ����� 0
  glLightfv(GL_LIGHT0, GL_AMBIENT, @glfLightAmbient); // ������� ���� ���������
  glLightfv(GL_LIGHT0, GL_DIFFUSE, @glfLightDiffuse); // ��������� �������� ���������
  glLightfv(GL_LIGHT0, GL_SPECULAR,@glfLightSpecular);// ���������� ���� ���������
  // ��������� �������� ����� 1
  glLightfv(GL_LIGHT1, GL_AMBIENT, @glfLightAmbient);  // ������� ���� ���������
  glLightfv(GL_LIGHT1, GL_DIFFUSE, @glfLightDiffuse);  // ��������� �������� ���������
  glLightfv(GL_LIGHT1, GL_SPECULAR,@glfLightSpecular1);// ���������� ���� ���������
  glLightfv(GL_LIGHT1, GL_POSITION,@glfLightPosition);
  glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 700.0);
  glLightf(GL_LIGHT1, GL_QUADRATIC_ATTENUATION, 700.0);
  glLightfv(GL_LIGHT1, GL_SPOT_DIRECTION, @glfLightSpotDir);
  glLightf(GL_LIGHT1, GL_SHININESS, 128.0);
  glLightf(GL_LIGHT0, GL_SHININESS, 128.0);
  glEnable(GL_LIGHTING); // ��������� ������ � �������������
  glEnable(GL_LIGHT0);   // �������� �������� ����� 0
  glEnable(GL_LIGHT1);   // �������� �������� ����� 1

  glHint(GL_LINE_SMOOTH, GL_NICEST);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
end;

{=======================================================================
��������� ��������}
procedure TfrmItem.DrawScene;
const
  // ������ ������� ���������
  glfMaterialColor: Array[0..3] of GLfloat = (0.25, 0.25, 0.25, 1.0);
  glfMaterialDif: Array[0..3] of GLfloat = (0.4, 0.40001, 0.4, 1.0);
  glfMaterialSpec: Array[0..3] of GLfloat = (-1.774597, -1.774593, -1.774597, 1.0);
  glfMaterialColor1: Array[0..3] of GLfloat = (0.8, 0.6, 0.0, 1.0);
  glfMColo: Array[0..3] of GLfloat = (0.0034, 0.0506, 0.0009, 1.0);
var
 Inside: boolean;
begin
  // ������� ������ ����� � ������ �������
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  // ������������
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(0.0, 2.0, -8.0);
  glRotatef(AngleX+90.0, 1.0, 0.0, 0.0); // ������� �� ���� X
  glRotatef(AngleY, 0.0, 1.0, 0.0);      // ������� �� ���� Y
  glRotatef(AngleZ+90.0, 0.0, 0.0, 1.0); // ������� �� ���� Z

  // ���������� �������� ��������� - ������� ������� - ����������
  // ���� ��������� � ��������� ��������� ��������� - �������� �� �������
  glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @glfMaterialColor);
  glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, @glfMaterialDif);
  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, @glfMaterialSpec);
  glMaterialf(GL_FRONT, GL_SHININESS, 128.0);
  glMaterialf(GL_FRONT, GL_EMISSION, 200.0);
  glCUllFace(GL_FRONT);
  glCallList(9);                 // ������: ������� � ������ ���������

  if not(SixthStep) then glCallList(15);
  glTranslatef(0.0, 0.0, 1.5*s); // ���c������ ������� ����
  glCullface(GL_FRONT);
  glCallList(10);                // ������� ��������������
  Inside:=true;

  if SixthStep then // ���� ������ ����� ��� ������� �����, �� ��������� ���
  begin
   glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor1);// ���� ����������� ����������
   glTranslatef(0.0, 0.0, dist);
   glCallList(11);// ����������
   glCallList(12);// ������������
   glTranslatef(0.0, 0.0, -dist);
      glTranslatef( dist_inf,0.0, 0.0);
       if dist_inf > 0 then begin
          glTranslatef(0.0, -last, 3.28);
          glTranslatef(0.0, 10*s/3-0.015, 0.0);
          glCallList(13);
          glTranslatef(0.0, -10*s/3+0.015, 0.0);
          glTranslatef(0.0, last, -3.28);

          glTranslatef(0.0, last, 3.2+0.12);
          glTranslatef(0.0, -10*s/3+0.015, 0.0);
          glCallList(14);
          glTranslatef(0.0, 10*s/3-0.015, 0.0);
          glTranslatef(0.0, -last, -(3.2+0.12));
       end;
   glTranslatef(0.0, 0.0, 1);
   glCallList(15);
   glTranslatef(0.0, 0.0, -1);
   glTranslatef(-dist_inf, 0.0, 0.0);
   // �����
   glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
   glTranslatef(0.0, -lastpoint, Down);
   glScalef(1.0, 1.0, 0.25);
   glCallList(2);                //������ ������
   glScalef(1.0, 1.0, 1/0.25);
   glTranslatef(0.0, lastpoint, -Down);

   glTranslatef(0.0, lastpoint, (Down+0.15));
   glScalef(1.0, 1.0, 0.25);
   glCallList(2);                //������ ������
   glScalef(1.0, 1.0, 1/0.25);
   glTranslatef(0.0, -lastpoint, -(Down+0.15));
   if dist_inf=0 then begin SixthStep:=false; FirstStep:=True; Inside:=false; end;
      glFinish;
      glFlush;
      SwapBuffers(DC);
   end;

   if FifthStep then // ���� ������ ����� ��� ������ �����, �� ��������� ���
     begin
     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor1);// ���� ����������� ����������
     glTranslatef(0.0, 0.0, dist);
     glCallList(11);  // ����������
     glCallList(12);  // ������������
     glTranslatef(0.0, 0.0, -dist);

     glTranslatef(0.0, -last, 3.28);
     glTranslatef(0.0, 10*s/3-0.015, 0.0);
     glCallList(13);
     glTranslatef(0.0, -10*s/3+0.015, 0.0);
     glTranslatef(0.0, last, -3.28);

     glTranslatef(0.0, last, 3.2+0.12);
     glTranslatef(0.0, -10*s/3+0.015, 0.0);
     glCallList(14);
     glTranslatef(0.0, 10*s/3-0.015, 0.0);
     glTranslatef(0.0, -last, -(3.2+0.12));

     // �����
     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
     glTranslatef(0.0, -lastpoint, Down);
     glScalef(1.0, 1.0, 0.25);
     glCallList(2);                //������ ������
     glScalef(1.0, 1.0, 1/0.25);
     glTranslatef(0.0, lastpoint, -Down);

     glTranslatef(0.0, lastpoint, (Down+0.15));
     glScalef(1.0, 1.0, 0.25);
     glCallList(2);                //������ ������
     glScalef(1.0, 1.0, 1/0.25);
     glTranslatef(0.0, -lastpoint, -(Down+0.15));
     if dist<4*s then begin
        FifthStep := false;
        SixthStep := True;
     end;
     // ����� ������
     glFinish;
     glFlush;
     SwapBuffers(DC);
  end;

  if FourthStep then//      ���� ������ ����� ��� ���������� �����, �� ��������� ���
   begin
   last:=0.65;
   glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor1);// ���� ����������� ����������
   if dist<path then begin
     glTranslatef(0.0, 0.0, dist);
     glCallList(11);// ����������
     glCallList(12);// ������������
     if not back then begin
      glTranslatef(0.0, -last, 1.78);
      glTranslatef(0.0, 10*s/3-0.015, 0.0);
      glCallList(13);
      glTranslatef(0.0, -10*s/3+0.015, 0.0);
      glTranslatef(0.0, last, -1.78);

      glTranslatef(0.0, last, 1.7+0.12);
      glTranslatef(0.0, -10*s/3+0.015, 0.0);
      glCallList(14);
      glTranslatef(0.0, 10*s/3-0.015, 0.0);
      glTranslatef(0.0, -last, -(1.7+0.12));
     end;
     glTranslatef(0.0, 0.0, -dist);
     end
     else begin
     glTranslatef(0.0, 0.0, path);
     glCallList(11);
     glTranslatef(0.0, 0.0, -path);
     glTranslatef(0.0, 0.0, dist);
     glCallList(12);// �����������
     if not(back) then begin
      glTranslatef(0.0, -last, 1.78);
      glTranslatef(0.0, 10*s/3-0.015, 0.0);
      glCallList(13);
      glTranslatef(0.0, -10*s/3+0.015, 0.0);
      glTranslatef(0.0, last, -1.78);

      glTranslatef(0.0, last, 1.7+0.12);
      glTranslatef(0.0, -10*s/3+0.015, 0.0);
      glCallList(14);
      glTranslatef(0.0, 10*s/3-0.015, 0.0);
      glTranslatef(0.0, -last, -(1.7+0.12));
     end;

     glTranslatef(0.0, 0.0, -dist);
   end;
   // �����
   glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
   glTranslatef(0.0, -lastpoint, Down);
   glScalef(1.0, 1.0, 0.25);
   glCallList(2);//������ ������
   glScalef(1.0, 1.0, 1/0.25);
   glTranslatef(0.0, lastpoint, -Down);

   glTranslatef(0.0, lastpoint, (Down+0.15));
   glScalef(1.0, 1.0, 0.25);
   glCallList(2);//������ ������
   glScalef(1.0, 1.0, 1/0.25);
   glTranslatef(0.0, -lastpoint, -(Down+0.15));

   if back then begin
      glTranslatef(0.0, -last, 3.28);
      glTranslatef(0.0, 10*s/3-0.015, 0.0);
      glCallList(13);
      glTranslatef(0.0, -10*s/3+0.015, 0.0);
      glTranslatef(0.0, last, -3.28);

      glTranslatef(0.0, last, 3.2+0.12);
      glTranslatef(0.0, -10*s/3+0.015, 0.0);
      glCallList(14);
      glTranslatef(0.0, 10*s/3-0.015, 0.0);
      glTranslatef(0.0, -last, -(3.2+0.12));
   end;
   if Back and (dist<path) then begin
      FourthStep:=false;
      FifthStep:=true;
   end;
   // ����� ������
   glFinish;
   glFlush;
   SwapBuffers(DC);
  end;

  if ThirdStep then//      ���� ������ ����� ��� �������� �����, �� ��������� ���
   begin
     last:=0.65;
     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor1);// ���� ����������� ����������
     glTranslatef(0.0, 0.0, dist);
     glCallList(11);// ����������
     glCallList(12);// ������������
     glTranslatef(0.0, 0.0, -dist);

     glTranslatef(0.0, -last, Down);
     glTranslatef(0.0, 10*s/3-0.015, 0.0);
     glCallList(13);
     glTranslatef(0.0, -10*s/3+0.015, 0.0);
     glTranslatef(0.0, last, -Down);

     glTranslatef(0.0, last, Down+0.15);
     glTranslatef(0.0, -10*s/3+0.015, 0.0);
     glCallList(14);
     glTranslatef(0.0, 10*s/3-0.015, 0.0);
     glTranslatef(0.0, -last, -(Down+0.15));

     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
     // ����� ������
     glTranslatef(0.0, -(12*s-dist2), Down);
     glScalef(1.0, 1.0, 0.25);
     glCallList(2);//������ ������
     glScalef(1.0, 1.0, 1/0.25);
     glTranslatef(0.0, 12*s-dist2, -Down);
     // ����� ���������
     glTranslatef(0.0, 12*s-dist2, Down+0.15);
     glScalef(1.0, 1.0, 0.25);
     glCallList(2);//������ ������
     glScalef(1.0, 1.0, 1/0.25);
     glTranslatef(0.0, -(12*s-dist2), -(Down+0.15));
     lastpoint:=12*s-dist2;
     if dist2<0 then begin ThirdStep:=false; FourthStep:=true; end;
      // ����� ������
     glFinish;
     glFlush;
     SwapBuffers(DC);
  end;

  if SecondStep then//      ���� ������ ����� ��� ������� �����, �� ��������� ���
   begin
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor1);// ���� ����������� ����������
    glTranslatef(0.0, 0.0, dist);
    glCallList(11);// ����������
    glCallList(12);// ������������
    glTranslatef(0.0, 0.0, -dist);
    // �����
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
    glTranslatef(0.0, -lastpoint, Down);
    glScalef(1.0, 1.0, 0.25);
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
    glCallList(2);//������ ������
    glScalef(1.0, 1.0, 1/0.25);
    glTranslatef(0.0, 10*s/3-0.015, 0.0);
    glCallList(13);
    glTranslatef(0.0, -10*s/3+0.015, 0.0);
    glTranslatef(0.0, lastpoint, -Down);

    glTranslatef(0.0, lastpoint, (Down+0.15));
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
    glScalef(1.0, 1.0, 0.25);
    glCallList(2);//������ ������
    glScalef(1.0, 1.0, 1/0.25);
    glTranslatef(0.0, -10*s/3+0.015, 0.0);
    glCallList(14);
    glTranslatef(0.0, 10*s/3-0.015, 0.0);
    glTranslatef(0.0, -lastpoint, -(Down+0.15));
    last:=lastpoint;
    if dist>(path-0.15) then begin
       SecondStep:=false;
       ThirdStep:=true;
    end;
    // ����� ������
    glFinish;
    glFlush;
    SwapBuffers(DC);
  end;

  if FirstStep and Inside then
   begin
     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor1);// ���� ����������� ����������
     glTranslatef(0.0, 0.0, 4*s);
     glCallList(11);// ����������
     glCallList(12);// ������������
     glTranslatef(0.0, 0.0, -4*s);

     // ����� ������
     glTranslatef(0.0, -(12*s-dist2), Down);
     glScalef(1.0, 1.0, 0.25);
     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
     glCallList(2);//������ ������
     glScalef(1.0, 1.0, 1/0.25);
     glTranslatef(0.0, 10*s/3-0.015, 0.0);
     glCallList(13);
     glTranslatef(0.0, -10*s/3+0.015, 0.0);
     glTranslatef(0.0, 12*s-dist2, -Down);
     // ����� ���������
     glTranslatef(0.0, 12*s-dist2, Down+0.15);
     glScalef(1.0, 1.0, 0.25);
     glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMaterialColor);
     glCallList(2);//������ ������
     glScalef(1.0, 1.0, 1/0.25);
     glTranslatef(0.0, -10*s/3+0.015, 0.0);
     glCallList(14);
     glTranslatef(0.0, 10*s/3-0.015, 0.0);
     glTranslatef(0.0, -(12*s-dist2), -(Down+0.15));
     lastpoint:=12*s-dist2;
     if dist2>8.5*s then begin
        FirstStep:=false;
        SecondStep:=true;
     end;
     // ����� ������
     glFinish;
     glFlush;
     SwapBuffers(DC);
  end;
end;

{=======================================================================
��������� �������}
procedure TfrmItem.TimerTimer(Sender: TObject);
begin
  Angle := Angle + 0.5;
  if dist>7*s then back:=true;
  if dist<4*s then back:=false;
  if not(FirstStep) and not(ThirdStep) and not(SixthStep) then
  if Back then dist:=dist-0.07 else dist:=dist+0.07;

  if dist2>8.5*s then back2:=true;
  if dist2<0 then back2:=false;
  if FirstStep or ThirdStep then
  if Back2 then dist2:=dist2-0.1 else dist2:=dist2+0.1;

  if dist_inf>5 then dist_inf:=-dist_inf;
  if SixthStep then dist_inf:=dist_inf+0.5;
  if Angle >= 360.0
     then Angle := 0.0;

  InvalidateRect(Handle, nil, False);
end;

{=======================================================================
������ ������ ����������}
procedure TfrmItem.FormCreate(Sender: TObject);
const
  glfMColo: Array[0..3] of GLfloat = (0.0034, 0.0506, 0.0009, 1.0);
  glfMColor1: Array[0..3] of GLfloat = (0.91, 0.01, 0.01, 1.0);
begin
  ViewAngle:=70.0;
  Angle := 0;
  s:=0.2;
  x0:=3.5*s;
  y0:=-7*s;
  dist:=4*s;
  dist2:=0;
  dist_inf:=0;
  Back:=false;
  AngleX:=0;
  AngleY:=0;
  AngleZ:=0;
  FirstStep:=true;
  SecondStep:=false;
  ThirdStep:=false;
  FourthStep:=false;
  FifthStep:=false;
  SixthStep:=false;
  path:=9*s-2*cylHeight*s;
  DC := GetDC(Handle);
  SetDCPixelFormat;
  hrc := wglCreateContext(DC);
  wglMakeCurrent(DC, hrc);
  InitializeRC;
  Timer.Enabled := True;
  ObjCylinder1 := gluNewQuadric;
  gluQuadricDrawStyle(ObjCylinder1, GLU_FILL);
  ObjCylinder2 := gluNewQuadric;
  gluQuadricDrawStyle(ObjCylinder2, GLU_FILL);
  gluQuadricOrientation(ObjCylinder2,GLU_INSIDE);
  ObjDisk1 := gluNewQuadric;
  gluQuadricDrawStyle(ObjDisk1, GLU_FILL);
  ObjCylinder3 := gluNewQuadric;
  gluQuadricDrawStyle(ObjCylinder3, GLU_FILL);
  ObjDisk2 := gluNewQuadric;
  gluQuadricDrawStyle(ObjDisk2, GLU_FILL);
  ObjCone := gluNewQuadric;
  gluQuadricDrawStyle(ObjCone, GLU_FILL); // ����� ������������

  //
  //                       ������� ���������
  //
  glNewList(1,GL_COMPILE);
   glCUllFace(GL_FRONT);
    // ����� ������ ����
    glBegin(GL_QUADS);
    {down}
     glNormal3f(0.0, 0.0, 1.0);
     glVertex3f(x0, y0, 0.0);
     glVertex3f(x0, y0+14*s, 0.0);
     glVertex3f(x0-7*s, y0+14*s, 0.0);
     glVertex3f(x0-7*s, y0, 0.0);
    {up}
     glNormal3f(0.0, 0.0, -1.0);
     glVertex3f(x0, y0, s);
     glVertex3f(x0-7*s, y0, s);
     glVertex3f(x0-7*s, y0+14*s, s);
     glVertex3f(x0, y0+14*s,s);
    {front}
     glNormal3f(1.0, 0.0, 0.0);
     glVertex3f(x0, y0, 0.0);
     glVertex3f(x0, y0, s);
     glVertex3f(x0, y0+14*s, s);
     glVertex3f(x0, y0+14*s,0.0);
    {back}
     glNormal3f(-1.0, 0.0, 0.0);
     glVertex3f(-x0, y0, 0.0);
     glVertex3f(-x0, y0+14*s,0.0);
     glVertex3f(-x0, y0+14*s, s);
     glVertex3f(-x0, y0, s);
    {left}
     glNormal3f(0.0, -1.0, 0.0);
     glVertex3f(x0, y0, 0.0);
     glVertex3f(-x0, y0,0.0);
     glVertex3f(-x0, y0, s);
     glVertex3f(x0, y0, s);
    {RIGHT}
     glNormal3f(0.0, 1.0, 0.0);
     glVertex3f(x0, y0+14*s, 0.0);
     glVertex3f(x0, y0+14*s, s);
     glVertex3f(-x0, y0+14*s, s);
     glVertex3f(-x0, y0+14*s, 0.0);
    glEnd;
  glEndList;

  //
  //                       ������ ���������
  //
  glNewList(2,GL_COMPILE);
    glCUllFace(GL_FRONT);
    // ����� ������ ����
    glBegin(GL_QUADS);
    {down}
     glNormal3f(0.0, 0.0, 1.0);
     glVertex3f(x0, y0, 20.0*s);
     glVertex3f(x0, y0+14*s, 20.0*s);
     glVertex3f(x0-7*s, y0+14*s, 20.0*s);
     glVertex3f(x0-7*s, y0, 20.0*s);
    {up}
     glNormal3f(0.0, 0.0, -1.0);
     glVertex3f(x0, y0, 20.0*s+s);
     glVertex3f(x0-7*s, y0, 20.0*s+s);
     glVertex3f(x0-7*s, y0+14*s, 20.0*s+s);
     glVertex3f(x0, y0+14*s,20.0*s+s);
    {front}
     glNormal3f(1.0, 0.0, 0.0);
     glVertex3f(x0, y0, 20.0*s);
     glVertex3f(x0, y0, 20.0*s+s);
     glVertex3f(x0, y0+14*s, 20.0*s+s);
     glVertex3f(x0, y0+14*s, 20.0*s);
    {back}
     glNormal3f(-1.0, 0.0, 0.0);
     glVertex3f(-x0, y0, 20.0*s);
     glVertex3f(-x0, y0+14*s, 20.0*s);
     glVertex3f(-x0, y0+14*s, 20.0*s+s);
     glVertex3f(-x0, y0, 20.0*s+s);
    {left}
     glNormal3f(0.0, -1.0, 0.0);
     glVertex3f(x0, y0, 20.0*s);
     glVertex3f(-x0, y0, 20.0*s);
     glVertex3f(-x0, y0, 20.0*s+s);
     glVertex3f(x0, y0, 20.0*s+s);
    {RIGHT}
     glNormal3f(0.0, 1.0, 0.0);
     glVertex3f(x0, y0+14*s, 20.0*s);
     glVertex3f(x0, y0+14*s, 20.0*s+s);
     glVertex3f(-x0, y0+14*s, 20.0*s+s);
     glVertex3f(-x0, y0+14*s, 20.0*s);
    glEnd;
  glEndList;

  //
  //     ��������
  //
  glNewList(3,GL_COMPILE);
    gluCylinder (ObjCylinder1, 0.05, 0.05, 21.0*s, 10, 3);
  glEndList;

  //
  //     �������
  //
  glNewList(4,GL_COMPILE);
    gluCylinder (ObjCylinder2, CylRadius, CylRadius, CylHeight*s, 10, 2);
  glEndList;

  //
  //     ����
  //
  glNewList(5,GL_COMPILE);
    gluDisk (ObjDisk1, 0.0, CylRadius+0.06, 10, 3);
  glEndList;

  //
  //     ��������2
  //
  glNewList(6,GL_COMPILE);
    gluCylinder (ObjCylinder1, 0.025, 0.025, 5.0*s, 10, 3);
  glEndList;
  //
  //     ���� 2
  //
  glNewList(7,GL_COMPILE);
    gluDisk (ObjDisk2, 0.0, CylRadius*1.02, 10, 3);
  glEndList;
  //
  //     �����
  //
  glNewList(8,GL_COMPILE);
    gluCylinder (ObjCone, 0.025, 0.0, s*0.25, 10, 3);
  glEndList;

  //
  //     ������
  //
  glNewList(9,GL_COMPILE);
   glCallList(1);//������ ������
   glCallList(2);//������ ������
   //****************************************
   glPushAttrib(GL_ALL_ATTRIB_BITS);
   glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMColor1);
   glTranslatef(0.0, 1.5, 2.15);
   glScalef(0.5, 0.5, 3.0);
   glCallList(1); //������ ���������
   glScalef(1/0.5, 1/0.5, 1/3.0);
   glTranslatef(0.0, -1.5, -2.15);
   glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMColo);
   glTranslatef(0.0, -1.5, 2.01);
   glScalef(0.5, 0.5, 3.0);
   glCallList(1); //������ ���������
   glScalef(1/0.5, 1/0.5, 1/3.0);
   glTranslatef(0.0, 1.5, -2.01);
   glPopAttrib;

   glCUllFace(GL_BACK);
   glTranslatef(0.0, 1.0, 0.0);
   glCallList(3);//������ ��������
   glTranslatef(0.0, -1.0, 0.0);
   glCallList(6);//������ ��������
   glTranslatef(0.0, -1.0, 0.0);
   glCallList(3);//������ ��������
   glTranslatef(0.0, 1.0, 0.0);

   glScalef(1.0, 1.0, 2.5);
   glTranslatef(0.0, 0.5, 0.0);
   glCallList(6);//������ ��������
   glTranslatef(0.0, -0.5, 0.0);

   glTranslatef(0.0, -0.5, 0.0);
   glCallList(6);//������ ��������
   glTranslatef(0.0, 0.5, 0.0);
   glScalef(1.0, 1.0, 1/2.5);

  glEndList;

//
//     ������� �������������� - 2 ��.
//
  glNewList(10,GL_COMPILE);
    // ������� ������
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glCallList(5);//������ ����
    glScalef(1.25, 1.25, cylH);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(4);//������ �������������
    glScalef(1/1.25, 1/1.25, 1/cylH);
    glTranslatef(0.0, 0.0, cylHeight*cylH*s);
    glCUllFace(GL_BACK);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(5);//������ ����
    glTranslatef(0.0, 0.0, -cylHeight*cylH*s);
    // ������ �������
    glCUllFace(GL_FRONT);
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glTranslatef(0.0, 0.0, cylHeight*cylH*s); //��������� �� ������ ������� ������
    glCallList(4);//������ �������������
    //  ������� ������
    glTranslatef(0.0, 0.0, cylHeight*s);
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glCallList(5);//������ ����
    glScalef(1.25, 1.25, cylH);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(4);//������ �������������
    glScalef(1/1.25, 1/1.25, 1/cylH);
    glTranslatef(0.0, 0.0, cylHeight*cylH*s);
    glCUllFace(GL_BACK);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(5);//������ ����
    glTranslatef(0.0, 0.0, -cylHeight*cylH*s);
    // ������ �������
    glCUllFace(GL_FRONT);
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glTranslatef(0.0, 0.0, cylHeight*cylH*s); //��������� �� ������ ������� ������
    glCallList(4);//������ �������������
    //  ������ ������
    glTranslatef(0.0, 0.0, cylHeight*s);
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glCallList(5);//������ ����
    glScalef(1.25, 1.25, cylH);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(4);//������ �������������
    glScalef(1/1.25, 1/1.25, 1/cylH);
    glTranslatef(0.0, 0.0, cylHeight*cylH*s);
    glCUllFace(GL_BACK);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(5);//������ ����
    glTranslatef(0.0, 0.0, -cylHeight*cylH*s);
    glTranslatef(0.0, 0.0, -2*cylHeight*s);
  glEndList;

  //
  //  �������� ������� � ���������
  //
  glNewList(11, GL_COMPILE);
    glTranslatef(0.0, 0.0, -plH*s*25);
    glCallList(6);
    glTranslatef(0.0, 0.0, plH*s*25);
    // ���������
    glTranslatef(0.0, 0.0, plH*s*3);
    glScalef(0.35, 0.45, plH);
    glCallList(1);//������ ���������
    glScalef(1/0.35, 1/0.45, 1/plH);

    // ���������
    glScalef(1.5, 1.5, 0.75);
    glCUllFace(GL_BACK);
    glTranslatef(0.0, -s*0.88, 0.0);//
    glCallList(6);
    glTranslatef(0.0, s*0.88, 0.0);//
    glTranslatef(0.0, s*0.88, 0.0);//
    glCallList(6);
    glTranslatef(0.0, -s*0.88, 0.0);//
    glCUllFace(GL_FRONT);
    glScalef(1/1.5, 1/1.5, 1/0.75);

    //  �������������
    glTranslatef(0.0, 0.0, plH*s);// ���������� �� ������ ���������
    glScalef(cylRn, cylRn, cylHn);// ������������
    // ������� ������
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);// �������� �����������
    glCallList(4);//������ ������� ���� ��������������
    glTranslatef(0.0, 0.0, cylHeight*s);
    glCUllFace(GL_BACK);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(7);//������ ���� �������� �����
    glScalef(1/cylRn, 1/cylRn, 1/cylHn);
    // �������
    glCUllFace(GL_FRONT);
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glScalef(cylRn*0.8, cylRn*0.8, cylHn*7);
    glCallList(4);//������ �������������
    glScalef(1/(cylRn*0.8), 1/(cylRn*0.8), 1/(cylHn*7));
    //  ������ ������
    glTranslatef(0.0, 0.0, cylHn*7*cylHeight*s);
    gluQuadricOrientation(ObjDisk1,GLU_INSIDE);
    glScalef(cylRn, cylRn, cylHn);
    glCallList(7);//������ ����
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(4);//������ ������ ���� ��������������
    glTranslatef(0.0, 0.0, cylHeight*s);
    glCUllFace(GL_BACK);
    gluQuadricOrientation(ObjDisk1,GLU_OUTSIDE);
    glCallList(7);//������ ����
    glCUllFace(GL_FRONT);
    glScalef(1/cylRn, 1/cylRn, 1/cylHn);
    glTranslatef(0.0, 0.0, -cylHeight*cylHn*s);//

    // ������ ���������
    // ���������� �� ������ ������
    glTranslatef(0.0, 0.0, 7*plH*s);
    glScalef(0.35, 0.45, plH);
    glCallList(1);//������ ���������
    glScalef(1/0.35, 1/0.45, 1/plH);
    // ������
    glScalef(3.5, 3.5, 0.4);
    glTranslatef(0.0, -s*0.71, -1.0);//
    glScalef(1/9.5, 1/9.5, 1/0.4);
    glCUllFace(GL_FRONT);
    glCallList(7);//������ ����
    glScalef(9.5, 9.5, 0.4);
    glCUllFace(GL_BACK);
    glCallList(6);
    glTranslatef(0.0, s*0.71, 0.0);//
    glTranslatef(0.0, s*0.71, 0.0);//
    glScalef(1/9.5, 1/9.5, 1/0.4);
    glCUllFace(GL_FRONT);
    glCallList(7);//������ ����
    glScalef(9.5, 9.5, 0.4);
    glCUllFace(GL_BACK);
    glCallList(6);
    glTranslatef(0.0, -s*0.71, 1.0);//
    glCUllFace(GL_FRONT);
    glScalef(1/3.5, 1/3.5, 1/0.4);
    // ������
    glScalef(1.0, 1.0, 0.5);
    glCullFace(GL_BACK);
    glTranslatef(0.0, 0.15, 0.0);
    glCallList(6);
    glTranslatef(0.0, 0.0, 5.0*s);
    glCallList(8);
    glTranslatef(0.0, 0.0, -5.0*s);
    glTranslatef(0.0, -0.15, 0.0);
    glTranslatef(0.0, -0.15, 0.0);
    glCallList(6);
    glTranslatef(0.0, 0.0, 5.0*s);
    glCallList(8);
    glTranslatef(0.0, 0.0, -5.0*s);
    glTranslatef(0.0, 0.15, 0.0);
    glCullFace(GL_FRONT);
    glScalef(1.0, 1.0, 1/0.5);

  glEndList;

  //
  // ������������
  //
  glNewList(12, GL_COMPILE);
    //  ���������
    glTranslatef(0.0, 0.0, 3*plH*s);
    glScalef(0.25, 0.27, plH);
    glCallList(1);//������ ���������
    glScalef(1/0.25, 1/0.27, 1/plH);
    glTranslatef(0.0, 0.0, -3*plH*s);
    glTranslatef(0.0, 0.0, -7*plH*s);
    // �����
    glCullFace(GL_BACK);
    glTranslatef(0.0, 0.0, -1.5*s);
    glCallList(6);
    glTranslatef(0.0, 0.0, 5.0*s);
    glCallList(8);
    glTranslatef(0.0, 0.0, -5.0*s);
    glTranslatef(0.0, 0.0, 1.5*s);
    glTranslatef(0.0, 0.0, -10*s);
    glTranslatef(0.0, 0.0, -plH*s);
    glTranslatef(0.0, 0.0, -plH*s*3);
  glEndList;
  //
  //  ������ ����� ������
  //
  glNewList(13, GL_COMPILE);
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMColo);
    glTranslatef(0.0, 0.0, 0.9);
    glScalef(0.5, 0.5, 0.5);
    glCallList(1); //������ ���������
    glScalef(1/0.5, 1/0.5, 1/0.5);
    glTranslatef(0.0, 0.0, -0.9);
  glEndList;
  //
  //  ���������
  //
  glNewList(14, GL_COMPILE);
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMColor1);
    glTranslatef(0.0, 0.0, 0.95);
    glScalef(0.5, 0.5, 0.3);
    glCallList(1); //������ ���������
    glScalef(1/0.5, 1/0.5, 1/0.3);
    glTranslatef(0.0, 0.0, -0.95);
  glEndList;

  //
  // ������ ����� ������
  //
  glNewList(15, GL_COMPILE);
    //****************
    glTranslatef(0.0, 0.0, 16*s);
    glScalef(0.5, 0.5, 4);
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glMaterialfv(GL_FRONT, GL_AMBIENT, @glfMColo);
    glCallList(1);//������ ������
    glPopAttrib;
    glScalef(1/0.5, 1/0.5, 1/4);
    glTranslatef(0.0, 0.0, -16*s);
    glCUllFace(GL_FRONT);
    //****************
  glEndList;
end;

{=======================================================================
��������� �������� ����}
procedure TfrmItem.FormResize(Sender: TObject);
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(ViewAngle, Width / Height, 1.0, 30.0);
  glViewport(0, 0, Width, Height);
  InvalidateRect(Handle, nil, False);
end;

{=======================================================================
������ ������� OnPaint}
procedure TfrmItem.WMPaint(var Msg: TWMPaint);
var
  ps : TPaintStruct;
begin
  BeginPaint(Handle, ps);
  DrawScene;
  EndPaint(Handle, ps);
end;

{=======================================================================
����� ������ ���������}
procedure TfrmItem.FormDestroy(Sender: TObject);
begin
  Timer.Enabled := False;
  wglMakeCurrent(0, 0);
  wglDeleteContext(hrc);
  ReleaseDC(Handle, DC);
  gluDeleteQuadric (ObjCylinder1);
  gluDeleteQuadric (ObjCylinder2);
  gluDeleteQuadric (ObjCylinder3);
  gluDeleteQuadric (ObjDisk1);
  gluDeleteQuadric (ObjDisk2);
  gluDeleteQuadric (ObjCone);
  glDeleteLists (1, 15);
end;

{=======================================================================
��������� ������� �������}
procedure TfrmItem.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if key='+' then ViewAngle:=ViewAngle-5;
 if key='-' then ViewAngle:=ViewAngle+5;
 if ord(key)=27 then Application.Terminate;
 if (key='x') then AngleX:=AngleX-5;
 if (key='X') then AngleX:=AngleX+5;
 if (key='z') then AngleZ:=AngleZ-5;
 if (key='Z') then AngleZ:=AngleZ+5;
 if (key='y') then AngleY:=AngleY-5;
 if (key='Y') then AngleY:=AngleY+5;
 FormResize(nil);
end;

{*** ������ ���� ������� ��� OpenGL �������� ***}
{=======================================================================
������ ������ �������}
procedure TfrmItem.SetDCPixelFormat;
var
  hHeap: THandle;
  nColors, i: Integer;
  lpPalette: PLogPalette;
  byRedMask, byGreenMask, byBlueMask: Byte;
  nPixelFormat: Integer;
  pfd: TPixelFormatDescriptor;

begin
  FillChar(pfd, SizeOf(pfd), 0);

  with pfd do begin
    nSize     := sizeof(pfd);
    nVersion  := 1;
    dwFlags   := PFD_DRAW_TO_WINDOW or
                 PFD_SUPPORT_OPENGL or
                 PFD_DOUBLEBUFFER;
    iPixelType:= PFD_TYPE_RGBA;
    cColorBits:= 24;
    cDepthBits:= 32;
    iLayerType:= PFD_MAIN_PLANE;
  end;

  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);

  DescribePixelFormat(DC, nPixelFormat, sizeof(TPixelFormatDescriptor), pfd);

  if ((pfd.dwFlags and PFD_NEED_PALETTE) <> 0) then begin
    nColors   := 1 shl pfd.cColorBits;
    hHeap     := GetProcessHeap;
    lpPalette := HeapAlloc(hHeap, 0, sizeof(TLogPalette) + (nColors * sizeof(TPaletteEntry)));

    // ����������� ��������� ������ ������ � ����� ��������� �������
    lpPalette^.palVersion := $300;
    lpPalette^.palNumEntries := nColors;

    byRedMask   := (1 shl pfd.cRedBits) - 1;
    byGreenMask := (1 shl pfd.cGreenBits) - 1;
    byBlueMask  := (1 shl pfd.cBlueBits) - 1;

    // ��������� ������� �������
    for i := 0 to nColors - 1 do begin
      lpPalette^.palPalEntry[i].peRed   := (((i shr pfd.cRedShift)   and byRedMask)   * 255) DIV byRedMask;
      lpPalette^.palPalEntry[i].peGreen := (((i shr pfd.cGreenShift) and byGreenMask) * 255) DIV byGreenMask;
      lpPalette^.palPalEntry[i].peBlue  := (((i shr pfd.cBlueShift)  and byBlueMask)  * 255) DIV byBlueMask;
      lpPalette^.palPalEntry[i].peFlags := 0;
    end;

    // ������� �������
    Palette := CreatePalette(lpPalette^);
    HeapFree(hHeap, 0, lpPalette);

    // ������������� �� � ��������� ����������
    if (Palette <> 0) then begin
      SelectPalette(DC, Palette, False);
      RealizePalette(DC);
    end;
  end;

end;

{=======================================================================
message WM_QUERYNEWPALETTE}
procedure TfrmItem.WMQueryNewPalette(var Msg : TWMQueryNewPalette);
begin
  if (Palette <> 0) then begin
    Msg.Result := RealizePalette(DC);

  if (Msg.Result <> GDI_ERROR) then
    InvalidateRect(Handle, nil, False);
  end;
end;

{=======================================================================
message WM_PALETTECHANGED}
procedure TfrmItem.WMPaletteChanged(var Msg : TWMPaletteChanged);
begin
  if ((Palette <> 0) and (THandle(TMessage(Msg).wParam) <> Handle))
  then begin
    if (RealizePalette(DC) <> GDI_ERROR) then
      UpdateColors(DC);
    Msg.Result := 0;
  end;
end;

end.

