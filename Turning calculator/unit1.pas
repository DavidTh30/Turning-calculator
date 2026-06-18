unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Spin, hmi_polyline;

type
  Motor = record  //I=input C=Auto_Calculate  O=output P=In_Program
    I_RPM: Integer;
      C_Round_Per_sec:extended;
      C_Round_Per_XXXms:extended;
      O_TurningMotorCounter_ms:extended;
      O_TurningMotorCounter_sec:extended;
    I_GearRatio: extended;
      C_GearRound_Per_sec:extended;
      C_GearRound_Per_XXXms:extended;
      O_TurningGearCounter_ms:extended;
      O_TurningGearCounter_sec:extended;
    P_TurningCounter_ms: longint;
    P_TurningCounter_sec: longint;
    P_TurningCounterReset_sec: extended;
    I_MotorRun:boolean;
    P_Counter_ms:longint;
    P_Timer_Leftover:longint;
    P_Counter_sec:longint;
    I_StopTurningSetpoint: extended;

    I_RampUpGearDelay_ms: longint;
    P_RampUpGearDelay_ms: longint;
    I_OffsetTurningMotorPer_ms: extended;
    P_RampUp:boolean;

  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    FloatSpinEdit1: TFloatSpinEdit;
    FloatSpinEdit2: TFloatSpinEdit;
    HMIPolyline1: THMIPolyline;
    HMIPolyline2: THMIPolyline;
    HMIPolyline3: THMIPolyline;
    Image1: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    SpinEdit3: TSpinEdit;
    procedure Button1Click(Sender: TObject);
    procedure FloatSpinEdit1EditingDone(Sender: TObject);
    procedure FloatSpinEdit2EditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpinEdit1EditingDone(Sender: TObject);
    procedure SpinEdit2EditingDone(Sender: TObject);
    procedure SpinEdit3EditingDone(Sender: TObject);
  private
    procedure OnIdle(Sender: TObject; var Done: boolean);
  public

  end;

var
  Form1: TForm1;
  StartTime, ElapsedTime : Cardinal;
  SetpointLoop_ms:longint;
  Timer_Leftover:longint;
  Motor01:Motor;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.OnIdle(Sender: TObject; var Done: boolean);
begin
  if (StartTime<=0) then  StartTime := GetTickCount64;
  ElapsedTime := GetTickCount64 - StartTime + Timer_Leftover;
  Done := False;

  if (ElapsedTime>=SetpointLoop_ms) then
  begin
    Timer_Leftover:=ElapsedTime-SetpointLoop_ms;
    StartTime := GetTickCount64;

    IF(Motor01.I_MotorRun) then
    begin
      Motor01.P_TurningCounter_ms:=Motor01.P_TurningCounter_ms+SetpointLoop_ms;
      if (not Motor01.P_RampUp) then Motor01.O_TurningMotorCounter_ms:=Motor01.O_TurningMotorCounter_ms+Motor01.C_Round_Per_XXXms;
      if (not Motor01.P_RampUp) then Motor01.O_TurningGearCounter_ms:=Motor01.O_TurningGearCounter_ms+Motor01.C_GearRound_Per_XXXms;
      Motor01.P_Counter_ms:=Motor01.P_Counter_ms+SetpointLoop_ms+Motor01.P_Timer_Leftover;
      if (Motor01.P_RampUp) then Motor01.P_RampUpGearDelay_ms:=Motor01.P_RampUpGearDelay_ms+SetpointLoop_ms+Motor01.P_Timer_Leftover;
      Motor01.P_Timer_Leftover:=0;

      if (Motor01.P_Counter_ms>=1000) then
      begin
        Motor01.P_Timer_Leftover:=Motor01.P_Counter_ms-1000;
        Motor01.P_Counter_sec:=Motor01.P_Counter_sec+1;
        Motor01.P_TurningCounter_sec:=Motor01.P_TurningCounter_sec+1;
        Motor01.P_Counter_ms:=0;
        if (not Motor01.P_RampUp) then Motor01.O_TurningMotorCounter_sec:=Motor01.O_TurningMotorCounter_sec+Motor01.C_Round_Per_sec;
        if (not Motor01.P_RampUp) then Motor01.O_TurningGearCounter_sec:=Motor01.O_TurningGearCounter_sec+Motor01.C_GearRound_Per_sec;
      end;

      if ((Motor01.P_RampUpGearDelay_ms>=Motor01.I_RampUpGearDelay_ms) and (Motor01.P_RampUp)) then
      begin
        Motor01.P_RampUp:=False;
        Motor01.P_Timer_Leftover:=Motor01.P_RampUpGearDelay_ms-Motor01.I_RampUpGearDelay_ms;
        Motor01.P_Counter_ms:=0;

        Motor01.O_TurningMotorCounter_ms:=Motor01.I_OffsetTurningMotorPer_ms;
        Motor01.O_TurningMotorCounter_sec:=Motor01.O_TurningMotorCounter_sec+Motor01.I_OffsetTurningMotorPer_ms;
        Motor01.O_TurningGearCounter_ms:=Motor01.I_OffsetTurningMotorPer_ms*Motor01.I_GearRatio;
        Motor01.O_TurningGearCounter_sec:=Motor01.O_TurningGearCounter_sec+Motor01.I_OffsetTurningMotorPer_ms*Motor01.I_GearRatio;
      end;

      if (Motor01.P_Counter_sec>=60) then
      begin
        //Motor01.P_Counter_sec:=0;
      end;

      if (Motor01.P_TurningCounter_sec>=Motor01.P_TurningCounterReset_sec) then
      begin
        //Motor01.O_TurnningMotorCounter_ms:=0;
        //Motor01.P_TurnningCounter_sec:=0;
      end;
      if (Motor01.O_TurningGearCounter_ms>=Motor01.I_StopTurningSetpoint) then Motor01.I_MotorRun:=false;

    end;

    IF(not Motor01.I_MotorRun) then
    begin
      Motor01.P_Counter_ms:=0;
      Motor01.P_Timer_Leftover:=0;
      Motor01.P_Counter_sec:=0;
    end;

    //form1.Refresh;
    //Form1.Canvas.TextOut(5,5,ElapsedTime.ToString+' ms');
    //Form1.Canvas.TextOut(5,20,Timer_Leftover.ToString+' ms');
    //
    //Form1.Canvas.TextOut(5,35,'RPM: '+Motor01.I_RPM.ToString);
    //Form1.Canvas.TextOut(5,50,'GearRatio: '+Motor01.I_GearRatio.ToString);
    //if (Motor01.I_MotorRun) then Form1.Canvas.TextOut(5,65,'MotorRun: true');
    //if (not Motor01.I_MotorRun) then Form1.Canvas.TextOut(5,65,'MotorRun: false');
    //Form1.Canvas.TextOut(5,80,'C_Round_Per_sec: '+ Motor01.C_Round_Per_sec.ToString);
    //Form1.Canvas.TextOut(5,95,'C_Round_Per_XXXms: '+ Motor01.C_Round_Per_XXXms.ToString);
    //Form1.Canvas.TextOut(5,110,'C_GearRound_Per_sec: '+ Motor01.C_GearRound_Per_sec.ToString);
    //Form1.Canvas.TextOut(5,125,'C_GearRound_Per_XXXms: '+ Motor01.C_GearRound_Per_XXXms.ToString);
    //Form1.Canvas.TextOut(5,140,'O_TurningMotorCounter_ms: '+ Motor01.O_TurningMotorCounter_ms.ToString);
    //Form1.Canvas.TextOut(5,155,'O_TurningMotorCounter_sec: '+ Motor01.O_TurningMotorCounter_sec.ToString);
    //Form1.Canvas.TextOut(5,170,'P_TurningCounter_sec: '+ Motor01.P_TurningCounter_sec.ToString);
    //Form1.Canvas.TextOut(5,185,'P_TurningCounterReset_sec: '+ Motor01.P_TurningCounterReset_sec.ToString);
    //Form1.Canvas.TextOut(5,200,'P_Counter_ms: '+ Motor01.P_Counter_ms.ToString);
    //Form1.Canvas.TextOut(5,215,'P_Counter_sec: '+ Motor01.P_Counter_sec.ToString);
    //Form1.Canvas.TextOut(5,230,'P_Timer_Leftover: '+ Motor01.P_Timer_Leftover.ToString);
    //Form1.Canvas.TextOut(5,245,'O_TurningGearCounter_ms: '+ Motor01.O_TurningGearCounter_ms.ToString);
    //Form1.Canvas.TextOut(5,260,'O_TurningGearCounter_sec: '+ Motor01.O_TurningGearCounter_sec.ToString);

    Label9.Caption:='SetpointLoop = '+SetpointLoop_ms.ToString+' ms';

    Label4.Caption:='Turning/ms = '+FormatFloat('0.00',Motor01.O_TurningMotorCounter_ms);
    Label3.Caption:='Turning/Sec = '+FormatFloat('0.00',Motor01.O_TurningMotorCounter_sec);

    Label10.Caption:='Turning/ms = '+FormatFloat('0.00',Motor01.O_TurningGearCounter_ms);
    Label11.Caption:='Turning/Sec = '+FormatFloat('0.00',Motor01.O_TurningGearCounter_sec);

    Label13.Caption:='ms = '+FormatFloat('0',Motor01.P_TurningCounter_ms);
    Label14.Caption:='Sec = '+FormatFloat('0',Motor01.P_TurningCounter_sec);

    Label5.Caption:='Motor turn/sec ='+FormatFloat('0.00',Motor01.C_Round_Per_sec);
    Label6.Caption:='Motor turn/'+SetpointLoop_ms.ToString+'ms ='+FormatFloat('0.00',Motor01.C_Round_Per_XXXms);
    Label7.Caption:='Gear turn/sec ='+FormatFloat('0.00',Motor01.C_GearRound_Per_sec);
    Label8.Caption:='Gear turn/'+SetpointLoop_ms.ToString+'ms ='+FormatFloat('0.00',Motor01.C_GearRound_Per_XXXms);

    Label15.Caption:='Cyc: '+ElapsedTime.ToString+' ms';
    Label16.Caption:='Left over: '+Timer_Leftover.ToString+' ms';

    Label19.Caption:='ActualOffset_ms = '+Motor01.P_RampUpGearDelay_ms.ToString+' ms';
  end;
  Application.ProcessMessages;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetpointLoop_ms:=100;
  Timer_Leftover:=0;
  StartTime := GetTickCount64;
  ElapsedTime:=0;

  Motor01.I_RPM:=500;
  Motor01.I_GearRatio:=1/2;
  Motor01.I_MotorRun:=false;

  Motor01.C_Round_Per_sec:=Motor01.I_RPM/60;
  Motor01.C_Round_Per_XXXms:=Motor01.C_Round_Per_sec/(1000/SetpointLoop_ms);
  Motor01.O_TurningMotorCounter_ms:=0;
  Motor01.O_TurningMotorCounter_sec:=0;
  Motor01.C_GearRound_Per_sec:=Motor01.C_Round_Per_sec*Motor01.I_GearRatio;
  Motor01.C_GearRound_Per_XXXms:=Motor01.C_GearRound_Per_sec/(1000/SetpointLoop_ms);
  Motor01.O_TurningGearCounter_ms:=0;
  Motor01.O_TurningGearCounter_sec:=0;
  Motor01.P_TurningCounter_ms:=0;
  Motor01.P_TurningCounter_sec:=0;
  Motor01.P_TurningCounterReset_sec:=60;
  Motor01.P_Counter_ms:=0;
  Motor01.P_Counter_sec:=0;
  Motor01.P_Timer_Leftover:=0;
  Motor01.I_StopTurningSetpoint:=250;
  Motor01.I_RampUpGearDelay_ms:=500;
  Motor01.P_RampUpGearDelay_ms:=0;
  Motor01.I_OffsetTurningMotorPer_ms:=10;
  Motor01.P_RampUp:=True;


  Application.OnIdle := @OnIdle;

end;

procedure TForm1.SpinEdit1EditingDone(Sender: TObject);
begin
  SpinEdit1.Value:=Abs(SpinEdit1.Value);
  Motor01.I_RPM:=SpinEdit1.Value;

  Motor01.C_Round_Per_sec:=Motor01.I_RPM/60;
  Motor01.C_Round_Per_XXXms:=Motor01.C_Round_Per_sec/(1000/SetpointLoop_ms);
  Motor01.O_TurningMotorCounter_ms:=0;
  Motor01.O_TurningMotorCounter_sec:=0;
  Motor01.C_GearRound_Per_sec:=Motor01.C_Round_Per_sec*Motor01.I_GearRatio;
  Motor01.C_GearRound_Per_XXXms:=Motor01.C_GearRound_Per_sec/(1000/SetpointLoop_ms);
end;

procedure TForm1.SpinEdit2EditingDone(Sender: TObject);
begin
  SpinEdit2.Value:=Abs(SpinEdit2.Value);
  Motor01.I_StopTurningSetpoint:=SpinEdit2.Value;
end;

procedure TForm1.SpinEdit3EditingDone(Sender: TObject);
begin
  SpinEdit3.Value:=Abs(SpinEdit3.Value);
  Motor01.I_RampUpGearDelay_ms:=SpinEdit3.Value;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Motor01.I_MotorRun:= not Motor01.I_MotorRun;

  IF(Motor01.I_MotorRun) then
  begin
    Motor01.P_RampUp:=True;
    Motor01.P_RampUpGearDelay_ms:=0;

    Motor01.O_TurningMotorCounter_ms:=0;
    Motor01.P_Counter_ms:=0;
    Motor01.P_Timer_Leftover:=0;

    Motor01.P_Counter_ms:=0;
    Motor01.P_Counter_sec:=0;
    Motor01.P_TurningCounter_ms:=0;
    Motor01.P_TurningCounter_sec:=0;
    Motor01.O_TurningMotorCounter_sec:=0;

    Motor01.P_Counter_sec:=0;

    Motor01.O_TurningGearCounter_ms:=0;
    Motor01.O_TurningGearCounter_sec:=0;

  end;

end;

procedure TForm1.FloatSpinEdit1EditingDone(Sender: TObject);
begin
  FloatSpinEdit1.Value:=Abs(FloatSpinEdit1.Value);
  Motor01.I_GearRatio:=FloatSpinEdit1.Value;

  Motor01.C_Round_Per_sec:=Motor01.I_RPM/60;
  Motor01.C_Round_Per_XXXms:=Motor01.C_Round_Per_sec/(1000/SetpointLoop_ms);
  Motor01.O_TurningMotorCounter_ms:=0;
  Motor01.O_TurningMotorCounter_sec:=0;
  Motor01.C_GearRound_Per_sec:=Motor01.C_Round_Per_sec*Motor01.I_GearRatio;
  Motor01.C_GearRound_Per_XXXms:=Motor01.C_GearRound_Per_sec/(1000/SetpointLoop_ms);
end;

procedure TForm1.FloatSpinEdit2EditingDone(Sender: TObject);
begin
  FloatSpinEdit2.Value:=Abs(FloatSpinEdit2.Value);
  Motor01.I_OffsetTurningMotorPer_ms:=FloatSpinEdit2.Value;
end;

end.

