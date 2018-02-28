unit FMain;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.MultiView,
  FMX.Layouts,
  FMX.ListBox,
  FMX.ScrollBox,
  FMX.Memo,
  Demo;

type
  TFormMain = class(TForm)
    MultiView: TMultiView;
    PanelDetails: TPanel;
    ToolBarMultiView: TToolBar;
    LabelMultiView: TLabel;
    ToolBarOutput: TToolBar;
    LabelOutput: TLabel;
    ButtonMaster: TSpeedButton;
    MemoOutput: TMemo;
    ListBoxDemos: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxDemosChange(Sender: TObject);
  private
    { Private declarations }
    FDemos: TArray<TDemoInfo>;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.fmx}

procedure TFormMain.FormCreate(Sender: TObject);
var
  Demo: TDemoInfo;
  Item: TListBoxItem;
begin
  ReportMemoryLeaksOnShutdown := True;
  {$IF Defined(MSWINDOWS)}
  MultiView.Mode := TMultiViewMode.Panel;
  {$ENDIF}
  FDemos := TDemo.GetDemos;
  for Demo in FDemos do
  begin
    Item := TListBoxItem.Create(Self);
    Item.Text := Demo.Name;
    ListBoxDemos.AddObject(Item);
  end;
end;

procedure TFormMain.ListBoxDemosChange(Sender: TObject);
var
  Index: Integer;
  Demo: TDemo;
begin
  MemoOutput.Lines.Clear;

  Index := ListBoxDemos.ItemIndex;
  if (Index < 0) or (Index >= Length(FDemos)) then
    Exit;

  MultiView.HideMaster;

  Demo := FDemos[Index].Clazz.Create(MemoOutput.Lines);
  try
    Demo.Run;
  finally
    Demo.Free;
  end;
end;

end.
