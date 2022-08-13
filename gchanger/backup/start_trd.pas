unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process;

type
  ShowLogTRD = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartTrd;
    procedure StopTrd;

  end;

implementation

uses Unit1;

{ TRD }


procedure ShowLogTRD.Execute;
var
  ExProcess: TProcess;
begin
  try //Старт вывода
    Synchronize(@StartTRD);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add('update-grub');

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);

      //Выводим лог
      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopTRD);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт вывода
procedure ShowLogTRD.StartTRD;
begin
  {MainForm.ChangeBgBtn.Enabled := False;
  MainForm.RestoreBtn.Enabled := False;
  MainForm.ApplyBtn.Enabled := False;}

  MainForm.Panel2.Enabled:=False;
  MainForm.Panel3.Enabled:=False;
  MainForm.LogMemo.Clear;
  MainForm.LogMemo.Append(SStartInstall);
end;

//Стоп вывода
procedure ShowLogTRD.StopTRD;
begin
 { MainForm.ChangeBgBtn.Enabled := True;
  MainForm.RestoreBtn.Enabled := True;
  MainForm.ApplyBtn.Enabled := True;}
  MainForm.Panel2.Enabled:=True;
  MainForm.Panel3.Enabled:=True;
  MainForm.ListBox1.SetFocus;
end;

//Вывод лога
procedure ShowLogTRD.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Result.Count - 1 do
    MainForm.LogMemo.Lines.Append(Result[i]);

  //Промотать список вниз
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;
end;

end.
