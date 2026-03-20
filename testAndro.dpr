program testAndro;

uses
  System.StartUpCopy,
  FMX.Forms,
  circle_di in 'GMF\circle_di.pas',
  Collect in 'GMF\Collect.pas',
  dsolve in 'GMF\dsolve.pas',
  dwgtext in 'GMF\dwgtext.pas',
  EcDot in 'GMF\EcDot.pas',
  EcDot2 in 'GMF\EcDot2.pas',
  ECLot in 'GMF\ECLot.pas',
  ECText in 'GMF\ECText.pas',
  EMath in 'GMF\EMath.pas',
  HatchLot in 'GMF\HatchLot.pas',
  imgutils in 'GMF\imgutils.pas',
  intervals in 'GMF\intervals.pas',
  Lib in 'GMF\Lib.pas',
  LIB2 in 'GMF\LIB2.PAS',
  Lines2 in 'GMF\Lines2.pas',
  Lines3 in 'GMF\Lines3.pas',
  maths_basic in 'GMF\maths_basic.pas',
  Maths_Lines in 'GMF\Maths_Lines.pas',
  maths_versia in 'GMF\maths_versia.pas',
  memStream in 'GMF\memStream.pas',
  mpMarker in 'GMF\mpMarker.pas',
  newBlock in 'GMF\newBlock.pas',
  newClassBuilder in 'GMF\newClassBuilder.pas',
  newConsts in 'GMF\newConsts.pas',
  newExtendedProcs in 'GMF\newExtendedProcs.pas',
  newFontScale in 'GMF\newFontScale.pas',
  newForm0 in 'GMF\newForm0.pas',
  newLayersTable in 'GMF\newLayersTable.pas',
  newpainter in 'GMF\newpainter.pas',
  newProcs in 'GMF\newProcs.pas',
  newProperties in 'GMF\newProperties.pas',
  newResource in 'GMF\newResource.pas',
  newSelector in 'GMF\newSelector.pas',
  newSettings in 'GMF\newSettings.pas',
  newUtil in 'GMF\newUtil.pas',
  ObjBlockList in 'GMF\ObjBlockList.pas',
  polygons in 'GMF\polygons.pas',
  RBitBox in 'GMF\RBitBox.pas',
  RBMPFile in 'GMF\RBMPFile.pas',
  RPrims in 'GMF\RPrims.pas',
  RSBmp in 'GMF\RSBmp.pas',
  Splines in 'GMF\Splines.pas',
  Str31 in 'GMF\Str31.pas',
  Tata3 in 'GMF\Tata3.pas',
  textmanager in 'GMF\textmanager.pas',
  tmppainter in 'GMF\tmppainter.pas',
  TwgColle in 'GMF\TwgColle.pas',
  TwgDraw in 'GMF\TwgDraw.pas',
  Types_dimano in 'GMF\Types_dimano.pas',
  types2 in 'GMF\types2.pas',
  UpdateMessages in 'GMF\UpdateMessages.pas',
  UserObject in 'GMF\UserObject.pas',
  WpArcs in 'GMF\WpArcs.pas',
  WpRects in 'GMF\WpRects.pas',
  WPTForm0 in 'GMF\WPTForm0.pas',
  WPTForm1 in 'GMF\WPTForm1.pas',
  WPTForm2 in 'GMF\WPTForm2.pas',
  WpTwigs in 'GMF\WpTwigs.pas',
  Writer in 'GMF\Writer.pas',
  LConvEncoding in 'GMF\LConvEncoding.pas',
  uExecRegisterClass in 'uExecRegisterClass.pas',
  ogcBasic in 'JSON\ogcBasic.pas',
  ogcdrawercanvas in 'JSON\ogcdrawercanvas.pas',
  ogcMathUtils in 'JSON\ogcMathUtils.pas',
  GMFLTDrawer in 'GMF\GMFLTDrawer.pas',
  DlgLocalOpen in 'DlgLocalOpen.pas' {localOpenForm},
  MainFrm in 'MainFrm.pas' {MainForm},
  MainFrmSkia in 'MainFrmSkia.pas' {MainFormSkia},
  ogcDrawerSkia in 'JSON\ogcDrawerSkia.pas',
  MainFrm1 in 'MainFrm1.pas' {MainForm1},
  objMouse in 'MOUSE\objMouse.pas',
  UndoColNew in 'GMF\UndoColNew.pas',
  UndoItem in 'GMF\UndoItem.pas',
  SelectorObj in 'GMF\SelectorObj.pas',
  UndoStream in 'GMF\UndoStream.pas';

{$R *.res}

begin
  Application.Initialize;
   Application.CreateForm(TMainFormSkia, MainFormSkia);
  //  Application.CreateForm(OpenForm.TFrame1, OpenForm.Frame1);
  Application.Run;
end.

Application.CreateForm(TForm1, Form1);

Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TlocalOpenForm, localOpenForm);

Application.CreateForm(TMainForm, MainForm);

Application.CreateForm(TMainForm1, MainForm1);

Application.CreateForm(TMainForm1, MainForm1);

Application.CreateForm(TMainFormSkia, MainFormSkia);

Application.CreateForm(TMainFormSkia, MainFormSkia);

Application.CreateForm(TMainForm1, MainForm1);

Application.CreateForm(TMainForm1, MainForm1);

