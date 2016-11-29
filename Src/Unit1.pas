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
   dirs := TQueue.Create; //创建目录队列
   dirs.Push(path); //将起始搜索路径入队  
   pszDir := dirs.Pop;  
   curDir := StrPas(pszDir); //出队  
   {开始遍历,直至队列为空(即没有目录需要遍历)}  
   while (True) do  
   begin  
      //加上搜索后缀,得到类似'c:/*.*' 、'c:/windows/*.*'的搜索路径
      tmpStr := curDir + '/*.*';  
      //在当前目录查找第一个文件、子目录  
      found := FindFirst(tmpStr, faAnyFile, searchRec);  
      while found = 0 do //找到了一个文件或目录后  
      begin  
          //如果找到的是个目录  
         if (searchRec.Attr and faDirectory) <> 0 then  
         begin  
          {在搜索非根目录(C:/、D:/)下的子目录时会出现'.','..'的"虚拟目录" 
          大概是表示上层目录和下层目录吧。。。要过滤掉才可以}  
            if (searchRec.Name <> '.') and (searchRec.Name <> '..') then  
            begin  
               {由于查找到的子目录只有个目录名，所以要添上上层目录的路径 
                searchRec.Name = 'Windows'; 
                tmpStr:='c:/Windows'; 
                加个断点就一清二楚了 
               }  
               tmpStr := curDir + '/' + searchRec.Name;  
               {将搜索到的目录入队。让它先晾着。 
                因为TQueue里面的数据只能是指针,所以要把string转换为PChar 
                同时使用StrNew函数重新申请一个空间存入数据，否则会使已经进 
                入队列的指针指向不存在或不正确的数据(tmpStr是局部变量)。}  
               dirs.Push(StrNew(PChar(tmpStr)));  
            end;  
         end  
         else //如果找到的是个文件  
         begin  
             {Result记录着搜索到的文件数。可是我是用CreateThread创建线程 
              来调用函数的，不知道怎么得到这个返回值。。。我不想用全局变量}  
            //把找到的文件加到Memo控件  
            if fileExt = '.*' then  
               fileList.Add(curDir + '/' + searchRec.Name)  
            else  
            begin  
               if SameText(RightStr(curDir + '/' + searchRec.Name, Length(fileExt)), fileExt) then
                  fileList.Add(curDir + '/' + searchRec.Name);  
            end;
         end;  
          //查找下一个文件或目录  
         found := FindNext(searchRec);  
      end;  
      {当前目录找到后，如果队列中没有数据，则表示全部找到了； 
        否则就是还有子目录未查找，取一个出来继续查找。}  
      if dirs.Count > 0 then  
      begin  
         pszDir := dirs.Pop;  
         curDir := StrPas(pszDir);  
         StrDispose(pszDir);  
      end  
      else  
         break;  
   end;  
   //释放资源  
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
                                Printf('发现感染地图[%s] - [%d]',[FileNameList[i],n]);
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
