unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,Contnrs,StrUtils, Gauges;

type
  FStormMode = procedure (Code:Integer);Stdcall;
  FLoadMap = function (MapPath:String;a,b:Integer;MapHandle:PCardinal):Integer;stdcall;

  FOpenFileHandle = function (Flag:Integer;FileName:PChar;Empty:Cardinal;pHandle:PCardinal):Integer;stdcall;
  FGetFileSize = function (FileHandle,Empty:Cardinal):Integer;stdcall;
  FGetFileContent = function (FileHandle:Cardinal;pBuffer:Pointer;Len:Cardinal;pSize:PCardinal;Empty:Cardinal):Integer;stdcall;
  FFreeFileHandle = function (FileHandle:Cardinal):Integer;stdcall;
type
  TForm1 = class(TForm)
    btn1: TButton;
    lbledt1: TLabeledEdit;
    grp1: TGroupBox;
    mmo1: TMemo;
    g1: TGauge;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    StromModule:Cardinal;
    FileNameList: TStringList;

    pOpenFileHandle:FOpenFileHandle;
    pGetFileSize:FGetFileSize;
    pGetFileContent:FGetFileContent;
    pFreeFileHandle:FFreeFileHandle;

    pStormMode:FStormMode;
    pLoadMap:FLoadMap;
    Procedure GetDirFile();
    Procedure LoadStorm();
    Procedure FreeStorm();
  public
    DFile:String;
    Procedure Printf(Str:string;Args:array of const);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
procedure EnumFileInQueue(path: PChar; fileExt: string; fileList: TStringList);  
var  
   searchRec: TSearchRec;  
   found: Integer;  
   tmpStr: string;  
   curDir: string;  
   dirs: TQueue;
   pszDir: PChar;
begin  
   dirs := TQueue.Create; //����Ŀ¼����
   dirs.Push(path); //����ʼ����·�����  
   pszDir := dirs.Pop;  
   curDir := StrPas(pszDir); //����  
   {��ʼ����,ֱ������Ϊ��(��û��Ŀ¼��Ҫ����)}  
   while (True) do  
   begin  
      //����������׺,�õ�����'c:/*.*' ��'c:/windows/*.*'������·��
      tmpStr := curDir + '/*.*';  
      //�ڵ�ǰĿ¼���ҵ�һ���ļ�����Ŀ¼  
      found := FindFirst(tmpStr, faAnyFile, searchRec);  
      while found = 0 do //�ҵ���һ���ļ���Ŀ¼��  
      begin  
          //����ҵ����Ǹ�Ŀ¼  
         if (searchRec.Attr and faDirectory) <> 0 then  
         begin  
          {�������Ǹ�Ŀ¼(C:/��D:/)�µ���Ŀ¼ʱ�����'.','..'��"����Ŀ¼" 
          ����Ǳ�ʾ�ϲ�Ŀ¼���²�Ŀ¼�ɡ�����Ҫ���˵��ſ���}  
            if (searchRec.Name <> '.') and (searchRec.Name <> '..') then  
            begin  
               {���ڲ��ҵ�����Ŀ¼ֻ�и�Ŀ¼��������Ҫ�����ϲ�Ŀ¼��·�� 
                searchRec.Name = 'Windows'; 
                tmpStr:='c:/Windows'; 
                �Ӹ��ϵ��һ������� 
               }  
               tmpStr := curDir + '/' + searchRec.Name;  
               {����������Ŀ¼��ӡ����������š� 
                ��ΪTQueue���������ֻ����ָ��,����Ҫ��stringת��ΪPChar 
                ͬʱʹ��StrNew������������һ���ռ�������ݣ������ʹ�Ѿ��� 
                ����е�ָ��ָ�򲻴��ڻ���ȷ������(tmpStr�Ǿֲ�����)��}  
               dirs.Push(StrNew(PChar(tmpStr)));  
            end;  
         end  
         else //����ҵ����Ǹ��ļ�  
         begin  
             {Result��¼�����������ļ���������������CreateThread�����߳� 
              �����ú����ģ���֪����ô�õ��������ֵ�������Ҳ�����ȫ�ֱ���}  
            //���ҵ����ļ��ӵ�Memo�ؼ�  
            if fileExt = '.*' then  
               fileList.Add(curDir + '/' + searchRec.Name)  
            else  
            begin  
               if SameText(RightStr(curDir + '/' + searchRec.Name, Length(fileExt)), fileExt) then
                  fileList.Add(curDir + '/' + searchRec.Name);  
            end;
         end;  
          //������һ���ļ���Ŀ¼  
         found := FindNext(searchRec);  
      end;  
      {��ǰĿ¼�ҵ������������û�����ݣ����ʾȫ���ҵ��ˣ� 
        ������ǻ�����Ŀ¼δ���ң�ȡһ�������������ҡ�}  
      if dirs.Count > 0 then  
      begin  
         pszDir := dirs.Pop;  
         curDir := StrPas(pszDir);  
         StrDispose(pszDir);  
      end  
      else  
         break;  
   end;  
   //�ͷ���Դ  
   dirs.Free;  
   FindClose(searchRec);  
end;

procedure TForm1.btn1Click(Sender: TObject);
var
  i,n:Integer;
  MapHandle,Handle,Size,OutSize:Cardinal;
  pBuffer:array of byte;
begin
  DFile:=lbledt1.Text;
  if DirectoryExists(DFile) then
    begin
      GetDirFile;
      Printf('Count = %d',[FileNameList.Count]);
      g1.MaxValue:=FileNameList.Count - 1;
      for i := 0 to FileNameList.Count - 1 do
        begin
          g1.Progress:=i;
         // Printf('FileName:%s',[FileNameList[i]]);
          if FileExists(FileNameList[i]) then
            begin
              LoadStorm;
              pStormMode($409);
              if pLoadMap(PChar(FileNameList[i]),0,0,@MapHandle) = 1 then
                begin
                  Handle:=0;
                  pOpenFileHandle(MapHandle,'scripts\war3map.j',0,@Handle);
                  if Handle = 0 then
                    pOpenFileHandle(MapHandle,'war3map.j',0,@Handle);
                  if Handle <> 0 then
                    begin
                      //Printf('Handle:%d',[Handle]);
                      Size:=pGetFileSize(Handle,0);
                      if Size > 0 then
                        begin
                          //Printf('Size:%d',[Size]);
                          SetLength(pBuffer,Size + 100);

                          ZeroMemory(pBuffer,Size + 100);
                          OutSize:=0;
                          if pGetFileContent(Handle,@pBuffer[0],Size,@OutSize,0) = 1 then
                            begin
                             // Printf('Text:%s',[PChar(pBuffer)]);
                              try
                               n:=Pos('loli.bat',PChar(pBuffer));
                               if n > 0 then
                                Printf('���ָ�Ⱦ��ͼ[%s] - [%d]',[FileNameList[i],n]);
                              except
                                Printf('Error',[]);
                              end;
                            end;
                          pFreeFileHandle(Handle);
                          SetLength(pBuffer,0);
                        end;
                    end;
                end;
              FreeStorm();
            end;
          Application.ProcessMessages;
        end;
    end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FileNameList:= TStringList.Create;

end;

procedure TForm1.FreeStorm;
begin
  FreeLibrary(StromModule);
end;

procedure TForm1.GetDirFile;
begin
   FileNameList.Clear;
   FileNameList := TStringList.Create;
   EnumFileInQueue(PChar(DFile), '.w3x', FileNameList);
end;

procedure TForm1.LoadStorm;
begin
   StromModule:=LoadLibrary('Storm.dll');
  if StromModule <> 0 then
    begin
      pOpenFileHandle:=Getprocaddress(StromModule,PChar(268));
      pGetFileSize:=Getprocaddress(StromModule,PChar(265));
      pGetFileContent:=Getprocaddress(StromModule,PChar(269));
      pFreeFileHandle:=Getprocaddress(StromModule,PChar(253));
      pStormMode:= Getprocaddress(StromModule,PChar(272));
      pLoadMap:= Getprocaddress(StromModule,PChar(266));

      PCardinal(StromModule + $4C2E4)^:=0;
    end;
end;

procedure TForm1.Printf(Str: string; Args: array of const);
begin
  mmo1.Lines.Add(TimeToStr(Now) + ' ' + Format(Str,Args));
end;

end.
