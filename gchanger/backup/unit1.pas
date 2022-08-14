unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, ComCtrls, Process, DefaultTranslator, Spin, IniPropStorage,
  ExtDlgs, Menus, FileUtil;

type

  { TMainForm }

  TMainForm = class(TForm)
    ApplyBtn: TBitBtn;
    ComboBox1: TComboBox;
    GetScreenBtn: TBitBtn;
    LoadBtn: TBitBtn;
    DeleteBtn: TBitBtn;
    ExportBtn: TBitBtn;
    ChangeBgBtn: TBitBtn;
    Image1: TImage;
    IniPropStorage1: TIniPropStorage;
    Label2: TLabel;
    ListBox1: TListBox;
    LogMemo: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    Separator1: TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    PopupMenu1: TPopupMenu;
    RestoreBtn: TBitBtn;
    SaveDialog1: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SpinEdit1: TSpinEdit;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StaticText1: TStaticText;
    procedure ApplyBtnClick(Sender: TObject);
    procedure GetScreenBtnClick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure ListBox1SelectionChange(Sender: TObject; User: boolean);
    procedure LoadBtnClick(Sender: TObject);
    procedure ChangeBgBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure LoadThemesList;
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure RestoreBtnClick(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SStartInstall = 'Theme installation is running, please wait...';
  SLoadingImage = 'loading an background image...';
  SApplyTheme = 'Install the selected theme?';
  SChangeBG = 'Replace the background of the selected theme?';
  SNoTheme = 'There is no theme in this directory!';
  SThemeExists = 'The theme already exists. Overwrite it?';
  SThemeDelete = 'Delete the selected theme?';
  SActiveTheme = 'This theme is active now! It cannot be deleted!';
  SThemeRestore = 'Restore default settings?';

implementation

uses
  start_trd;

{$R *.lfm}

{ TMainForm }

//Загрузка списка тем
procedure TMainForm.LoadThemesList;
var
  sr: TSearchRec;
begin
  try
    Screen.Cursor := crHourGlass;
    Application.ProcessMessages;
    ListBox1.Clear;

    if FindFirst('/boot/grub2/themes/' + '*', faDirectory, sr) = 0 then
    begin
      repeat
        // игнорировать служебные папки и дефолтную тему maggy
        if ((sr.Attr and faDirectory) = faDirectory) and (sr.Name <> '.') and
          (sr.Name <> '..') then
          ListBox1.Items.Append(sr.Name);
      until FindNext(sr) <> 0;
    end;
  finally
    FindClose(sr);
    Screen.Cursor := crDefault;
  end;
end;

//PopUP menu
procedure TMainForm.MenuItem1Click(Sender: TObject);
begin
  LoadBtn.Click;
end;

procedure TMainForm.MenuItem2Click(Sender: TObject);
begin
  ExportBtn.Click;
end;

procedure TMainForm.MenuItem3Click(Sender: TObject);
begin
  DeleteBtn.Click;
end;

//Защищаем тему по дефолту
procedure TMainForm.PopupMenu1Popup(Sender: TObject);
begin
  if ListBox1.Items[ListBox1.ItemIndex] = 'maggy' then Abort;
end;

//Restore settings
procedure TMainForm.RestoreBtnClick(Sender: TObject);
var
  S: ansistring;
  FShowLogTRD: TThread;
begin
  if MessageDlg(SThemeRestore, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ComboBox1.Text := '1024x768x32';
    ListBox1.SetFocus;
    ListBox1.ItemIndex := ListBox1.Items.IndexOf('maggy');
    ListBox1.Click;

    //Сохранение Разрешение экрана (1024x768x32)
    if RunCommand('/bin/bash', ['-c', 'sed -i "s/^GRUB_GFXMODE=.*/GRUB_GFXMODE=\"' +
      ComboBox1.Text + '\"/g" /etc/default/grub'], S) then

      //Сохранение Путь к теме
      if RunCommand('/bin/bash',
        ['-c', 'sed -i "s/^GRUB_THEME=.*/GRUB_THEME=\"\/boot\/grub2\/themes\/' +
        ListBox1.Items[ListBox1.ItemIndex] +
        '\/theme.txt\"/g" /etc/default/grub'], S) then

        //Запуск потока чтения лога
      begin
        FShowLogTRD := ShowLogTRD.Create(False);
        FShowLogTRD.Priority := tpNormal;
      end;
  end;
end;

//Считываем параметры из /etc/default/grub
procedure TMainForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  try
    IniPropStorage1.Restore;

    LoadThemesList;

    MainForm.Caption := Application.Title;

    //Тема maggy установлена?
    if DirectoryExists('/boot/grub2/themes/maggy') then RestoreBtn.Enabled := True
    else
      RestoreBtn.Enabled := False;

    //Считываем разрешение экрана
    if RunCommand('/bin/bash',
      ['-c', 'grep "^GRUB_GFXMODE=" /etc/default/grub | cut -d "=" -f2 | tr -d "\""'],
      S) then
      ComboBox1.Text := Trim(S);

    //Считываем GRUB_TIMEOUT
    if RunCommand('/bin/bash',
      ['-c', 'grep "^GRUB_TIMEOUT=" /etc/default/grub | cut -d "=" -f2 | tr -d "\""'],
      S) then
      SpinEdit1.Value := StrToInt(Trim(S));

    //Считываем установленную тему (позиция списка)
    if RunCommand('/bin/bash',
      ['-c', 'grep "^GRUB_THEME=" /etc/default/grub | cut -d "/" -f5'], S) then
      ListBox1.ItemIndex := ListBox1.Items.IndexOf(Trim(S));

    //Промотать список к выделенной позиции
    ListBox1.TopIndex := ListBox1.ItemIndex;

    ListBox1.Click;
  except
  end;
end;

procedure TMainForm.ListBox1DblClick(Sender: TObject);
begin
  if ListBox1.Count <> 0 then ApplyBtn.Click;
end;

//Apply new theme
procedure TMainForm.ApplyBtnClick(Sender: TObject);
var
  S: ansistring;
  FShowLogTRD: TThread;
begin
  if MessageDlg(SApplyTheme, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  //Если разрешение не введено
  if (Pos('auto', Trim(ComboBox1.Text)) = 0) and
    (Pos('x', Trim(ComboBox1.Text)) = 0) then
    GetScreenBtn.Click;

  //Сохранение TimeOut
  if RunCommand('/bin/bash', ['-c', 'sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=\"' +
    SpinEdit1.Text + '\"/g" /etc/default/grub'], S) then

    //Сохранение Разрешение экрана
    if RunCommand('/bin/bash', ['-c', 'sed -i "s/^GRUB_GFXMODE=.*/GRUB_GFXMODE=\"' +
      ComboBox1.Text + '\"/g" /etc/default/grub'], S) then

      //Сохранение Путь к теме
      if RunCommand('/bin/bash',
        ['-c', 'sed -i "s/^GRUB_THEME=.*/GRUB_THEME=\"\/boot\/grub2\/themes\/' +
        ListBox1.Items[ListBox1.ItemIndex] +
        '\/theme.txt\"/g" /etc/default/grub'], S) then

        //Запуск update-grub и потока чтения лога
      begin
        FShowLogTRD := ShowLogTRD.Create(False);
        FShowLogTRD.Priority := tpNormal;
      end;
end;

//Считать разрешение экрана
procedure TMainForm.GetScreenBtnClick(Sender: TObject);
begin
  ComboBox1.Text := IntToStr(Screen.Width) + 'x' + IntToStr(Screen.Height) + ',auto';
end;

//Удалить выбранную тему
procedure TMainForm.DeleteBtnClick(Sender: TObject);
var
  S: ansistring;
begin
  //Дефолтную тему maggy не трогаем
  if ListBox1.Items[ListBox1.ItemIndex] = 'maggy' then exit;

  //Считываем установленную тему
  if RunCommand('/bin/bash', ['-c',
    'grep "^GRUB_THEME=" /etc/default/grub | cut -d "/" -f5'], S) then
    //Если пытаемся удалить активную тему - идём в отказ
    if Trim(S) = ListBox1.Items[ListBox1.ItemIndex] then
    begin
      MessageDlg(SActiveTheme, mtWarning, [mbOK], 0);
      Exit;
    end;

  if MessageDlg(SThemeDelete, mtWarning, [mbYes, mbNo], 0) = mrYes then
    DeleteDirectory('/boot/grub2/themes/' +
      ListBox1.Items[ListBox1.ItemIndex], False)
  else
    Exit;

  LoadThemesList;

  if ListBox1.Count <> 0 then
  begin
    ListBox1.SetFocus;
    ListBox1.Click;
  end
  else
    Image1.Picture.Clear;
end;

//Экспорт выбранной темы в *.tar.gz
procedure TMainForm.ExportBtnClick(Sender: TObject);
var
  S: ansistring;
begin
  SaveDialog1.FileName := ListBox1.Items[ListBox1.ItemIndex] + '.tar.gz';

  if SaveDialog1.Execute then
  begin
    Screen.Cursor := crHourGlass;
    Application.ProcessMessages;

    if RunCommand('/bin/bash', ['-c', 'cd /boot/grub2/themes/' +
      ' && tar -czf "' + SaveDialog1.FileName + '" ' +
      ListBox1.Items[ListBox1.ItemIndex] + ' && chown $(logname).$(logname) "' +
      SaveDialog1.FileName + '"'], S) then
      Screen.Cursor := crDefault;
  end;
end;

//Загрузка background при изменении темы в списке
procedure TMainForm.ListBox1SelectionChange(Sender: TObject; User: boolean);
begin
  if ListBox1.Count <> 0 then
  begin
    Screen.Cursor := crHourGlass;
    Image1.Picture.Clear;
    Panel3.Caption := SLoadingImage;
    Application.ProcessMessages;

    if FileExists('/boot/grub2/themes/' + ListBox1.Items[ListBox1.ItemIndex] +
      '/background.png') then
      Image1.Picture.LoadFromFile('/boot/grub2/themes/' +
        ListBox1.Items[ListBox1.ItemIndex] + '/background.png')
    else
    if FileExists('/boot/grub2/themes/' + ListBox1.Items[ListBox1.ItemIndex] +
      '/background.jpg') then
      Image1.Picture.LoadFromFile('/boot/grub2/themes/' +
        ListBox1.Items[ListBox1.ItemIndex] + '/background.jpg')
    else
    if FileExists('/boot/grub2/themes/' + ListBox1.Items[ListBox1.ItemIndex] +
      '/background.jpeg') then
      Image1.Picture.LoadFromFile('/boot/grub2/themes/' +
        ListBox1.Items[ListBox1.ItemIndex] + '/background.jpeg')
    else
    if ListBox1.Items[ListBox1.ItemIndex] = 'maggy' then
      Image1.Picture.LoadFromFile('/boot/grub2/themes/maggy/grub2-mageia-default.png')
    else
      Image1.Picture.Clear;

    Panel3.Caption := '';
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.LoadBtnClick(Sender: TObject);
begin
  //Проверка наличия theme.txt
  if SelectDirectoryDialog1.Execute then
  begin
    //Дефолтную тему maggy не трогаем
    if ExtractFileName(SelectDirectoryDialog1.FileName) = 'maggy' then exit;

    if not FileExists(SelectDirectoryDialog1.FileName + '/theme.txt') then
    begin
      ShowMessage(SNoTheme);
      Exit;
    end;

    //Если существует - перезаписать?
    if DirectoryExists('/boot/grub2/themes/' + ExtractFileName(
      SelectDirectoryDialog1.FileName)) then
      if MessageDlg(SThemeExists, mtWarning, [mbYes, mbNo], 0) = mrYes then
        DeleteDirectory('/boot/grub2/themes/' +
          ExtractFileName(SelectDirectoryDialog1.FileName), True)
      else
        Exit;

    CopyDirTree(SelectDirectoryDialog1.FileName, '/boot/grub2/themes/' +
      ExtractFileName(SelectDirectoryDialog1.FileName));

    LoadThemesList;
    ListBox1.ItemIndex := ListBox1.Items.IndexOf(
      ExtractFileName(SelectDirectoryDialog1.FileName));
    ListBox1.SetFocus;
    ListBox1.Click;
  end;
end;

//Изменить Background
procedure TMainForm.ChangeBgBtnClick(Sender: TObject);
var
  S: ansistring;
begin
  //Дефолтную тему maggy не трогаем
  if ListBox1.Items[ListBox1.ItemIndex] = 'maggy' then exit;

  if OpenPictureDialog1.Execute then
    if MessageDlg(SChangeBG, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Application.ProcessMessages;

      //Удаляем старый background.(png, jpeg, jpg)
      if not DeleteFile('/boot/grub2/themes/' + ListBox1.Items[ListBox1.ItemIndex] +
        '/background.png') then
        if not DeleteFile('/boot/grub2/themes/' + ListBox1.Items[ListBox1.ItemIndex] +
          '/background.jpeg') then
          DeleteFile('/boot/grub2/themes/' + ListBox1.Items[ListBox1.ItemIndex] +
            '/background.jpg');

      //Перезаписываем background.(png, jpeg, jpg)
      CopyFile(OpenPictureDialog1.FileName, '/boot/grub2/themes/' +
        ListBox1.Items[ListBox1.ItemIndex] + '/background' +
        ExtractFileExt(OpenPictureDialog1.FileName), False);

      //Загружаем новый фон
      Image1.Picture.LoadFromFile('/boot/grub2/themes/' +
        ListBox1.Items[ListBox1.ItemIndex] + '/background' +
        ExtractFileExt(OpenPictureDialog1.FileName));

      //Исправляем имя файла в theme.txt (*.png)
      if RunCommand('/bin/bash',
        ['-c', 'sed -i "s/^desktop-image:.*/desktop-image: \"background' +
        ExtractFileExt(OpenPictureDialog1.FileName) + '\"/g" /boot/grub2/themes/' +
        ListBox1.Items[ListBox1.ItemIndex] + '/theme.txt'], S) then

        ListBox1.SetFocus;
      ListBox1.Click;
    end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  if not DirectoryExists('/root/.config') then MkDir('/root/.config');
  IniPropStorage1.IniFileName := '/root/.config/gchanger.conf';
end;

end.
