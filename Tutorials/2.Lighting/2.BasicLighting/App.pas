unit App;

{$INCLUDE 'Sample.inc'}

interface

uses
  System.Classes,
  System.UITypes,
  System.SysUtils,
  {$INCLUDE 'OpenGL.inc'}
  Sample.Classes,
  Sample.App;

type
  TBasicLightingApp = class(TApplication)
  private
    FCamera: ICamera;
    FLightingShader: IShader;
    FLampShader: IShader;
    FContainerVAO: IVertexArray;
    FLampVAO: IVertexArray;
    FUniformLightPos: GLint;
    FUniformViewPos: GLint;
    FUniformLightColor: GLint;
    FUniformObjectColor: GLint;
    FUniformLightingModel: GLint;
    FUniformLightingView: GLint;
    FUniformLightingProjection: GLint;
    FUniformLightingNormalMatrix: GLint;
    FUniformLampModel: GLint;
    FUniformLampView: GLint;
    FUniformLampProjection: GLint;
  public
    procedure Initialize; override;
    procedure Update(const ADeltaTimeSec, ATotalTimeSec: Double); override;
    procedure Shutdown; override;
    procedure Resize(const AWidth, AHeight: Integer); override;
  public
    procedure KeyDown(const AKey: Integer; const AShift: TShiftState); override;
    procedure KeyUp(const AKey: Integer; const AShift: TShiftState); override;
    procedure MouseDown(const AButton: TMouseButton; const AShift: TShiftState;
      const AX, AY: Single); override;
    procedure MouseMove(const AShift: TShiftState; const AX, AY: Single); override;
    procedure MouseUp(const AButton: TMouseButton; const AShift: TShiftState;
      const AX, AY: Single); override;
    procedure MouseWheel(const AShift: TShiftState; const AWheelDelta: Integer); override;
  end;

implementation

uses
  Neslib.Stb.Image,
  Neslib.FastMath;

const
  { Each container vertex consists of a 3-element position and a 3-element normal.
    Each group of 4 vertices defines a side of a cube. }
  CONTAINER_VERTICES: array [0..143] of Single = (
    // Positions      // Normals
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,

    -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
     0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
     0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0,  1.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0);

const
  { Each lamp vertex consists of a 3-element position.
    Each group of 4 vertices defines a side of a cube. }
  LAMP_VERTICES: array [0..71] of Single = (
    // Positions
    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5,  0.5, -0.5,
    -0.5,  0.5, -0.5,

    -0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,

    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5,  0.5,

     0.5,  0.5,  0.5,
     0.5,  0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,

    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
    -0.5, -0.5,  0.5,

    -0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5);

const
  { The indices define 2 triangles per cube face, 6 faces total }
  INDICES: array [0..35] of UInt16 = (
     0,  1,  2,   2,  3,  0,
     4,  5,  6,   6,  7,  4,
     8,  9, 10,  10, 11,  8,
    12, 13, 14,  14, 15, 12,
    16, 17, 18,  18, 19, 16,
    20, 21, 22,  22, 23, 20);

const
  LIGHT_POS: TVector3 = (X: 1.2; Y: 1.0; Z: 2.0);

{ TBasicLightingApp }

procedure TBasicLightingApp.Initialize;
var
  VertexLayout: TVertexLayout;
begin
  { Initialize the asset manager }
  TAssets.Initialize;

  { Enable depth testing }
  glEnable(GL_DEPTH_TEST);

  { Create camera }
  FCamera := TCamera.Create(Width, Height, Vector3(0, 0, 3));

  { Build and compile our shader programs }
  FLightingShader := TShader.Create('shaders/basic_lighting.vs', 'shaders/basic_lighting.fs');
  FUniformLightPos := FLightingShader.GetUniformLocation('lightPos');
  FUniformViewPos := FLightingShader.GetUniformLocation('viewPos');
  FUniformLightColor := FLightingShader.GetUniformLocation('lightColor');
  FUniformObjectColor := FLightingShader.GetUniformLocation('objectColor');
  FUniformLightingModel := FLightingShader.GetUniformLocation('model');
  FUniformLightingView := FLightingShader.GetUniformLocation('view');
  FUniformLightingProjection := FLightingShader.GetUniformLocation('projection');
  FUniformLightingNormalMatrix := FLightingShader.GetUniformLocation('normalMatrix');

  FLampShader := TShader.Create('shaders/lamp.vs', 'shaders/lamp.fs');
  FUniformLampModel := FLampShader.GetUniformLocation('model');
  FUniformLampView := FLampShader.GetUniformLocation('view');
  FUniformLampProjection := FLampShader.GetUniformLocation('projection');

  { Define layout of the attributes in the Lighting shader }
  VertexLayout.Start(FLightingShader)
    .Add('position', 3)
    .Add('normal', 3);

  { Create the vertex array for the container. }
  FContainerVAO := TVertexArray.Create(VertexLayout,
    CONTAINER_VERTICES, SizeOf(CONTAINER_VERTICES), INDICES);

  { Define layout of the attributes in the Lamp shader }
  VertexLayout.Start(FLampShader)
    .Add('position', 3);

  { Create the vertex array for the lamp. }
  FLampVAO := TVertexArray.Create(VertexLayout,
    LAMP_VERTICES, SizeOf(LAMP_VERTICES), INDICES);
end;

procedure TBasicLightingApp.KeyDown(const AKey: Integer; const AShift: TShiftState);
begin
  if (AKey = vkEscape) then
    { Terminate app when Esc key is pressed }
    Terminate
  else
    FCamera.ProcessKeyDown(AKey);
end;

procedure TBasicLightingApp.KeyUp(const AKey: Integer; const AShift: TShiftState);
begin
  FCamera.ProcessKeyUp(AKey);
end;

procedure TBasicLightingApp.MouseDown(const AButton: TMouseButton;
  const AShift: TShiftState; const AX, AY: Single);
begin
  FCamera.ProcessMouseDown(AX, AY);
end;

procedure TBasicLightingApp.MouseMove(const AShift: TShiftState; const AX, AY: Single);
begin
  FCamera.ProcessMouseMove(AX, AY);
end;

procedure TBasicLightingApp.MouseUp(const AButton: TMouseButton;
  const AShift: TShiftState; const AX, AY: Single);
begin
  FCamera.ProcessMouseUp;
end;

procedure TBasicLightingApp.MouseWheel(const AShift: TShiftState;
  const AWheelDelta: Integer);
begin
  FCamera.ProcessMouseWheel(AWheelDelta);
end;

procedure TBasicLightingApp.Resize(const AWidth, AHeight: Integer);
begin
  inherited;
  if Assigned(FCamera) then
    FCamera.ViewResized(AWidth, AHeight);
end;

procedure TBasicLightingApp.Shutdown;
begin
  { Nothing to do }
end;

procedure TBasicLightingApp.Update(const ADeltaTimeSec, ATotalTimeSec: Double);
var
  Model, View, Projection, Translate, Scale: TMatrix4;
  NormalMatrix: TMatrix3;
begin
  FCamera.HandleInput(ADeltaTimeSec);

  { Define the viewport dimensions }
  glViewport(0, 0, Width, Height);

  { Clear the color and depth buffer }
  glClearColor(0.1, 0.1, 0.1, 1.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  { Use corresponding shader when setting uniforms/drawing objects }
  FLightingShader.Use;
  glUniform3f(FUniformObjectColor, 1.0, 0.5, 0.31);
  glUniform3f(FUniformLightColor, 1.0, 1.0, 1.0);
  glUniform3f(FUniformLightPos, LIGHT_POS.X, LIGHT_POS.Y, LIGHT_POS.Z);
  glUniform3f(FUniformViewPos, FCamera.Position.X, FCamera.Position.Y, FCamera.Position.Z);

  { Create camera transformation }
  View := FCamera.GetViewMatrix;
  Projection.InitPerspectiveFovRH(Radians(FCamera.Zoom), Width / Height, 0.1, 100.0);

  { Pass matrices to shader }
  glUniformMatrix4fv(FUniformLightingView, 1, GL_FALSE, @View);
  glUniformMatrix4fv(FUniformLightingProjection, 1, GL_FALSE, @Projection);

  { Create Model matrix and calculate Normal Matrix }
  Model.Init;
  NormalMatrix.Init(Model);
  NormalMatrix := NormalMatrix.Inverse.Transpose;

  { Draw the container }
  glUniformMatrix4fv(FUniformLightingModel, 1, GL_FALSE, @Model);
  glUniformMatrix3fv(FUniformLightingNormalMatrix, 1, GL_FALSE, @NormalMatrix);
  FContainerVAO.Render;

  { Also draw the lamp object }
  FLampShader.Use;
  glUniformMatrix4fv(FUniformLampView, 1, GL_FALSE, @View);
  glUniformMatrix4fv(FUniformLampProjection, 1, GL_FALSE, @Projection);

  Translate.InitTranslation(LIGHT_POS);
  Scale.InitScaling(0.2); { Make it a smaller cube }
  Model := Scale * Translate;
  glUniformMatrix4fv(FUniformLampModel, 1, GL_FALSE, @Model);
  FLampVAO.Render;
end;

end.
