unit ogcMapIndex;

interface

uses Classes, SysUtils, ogcBasic, ogcGeometry;

// Индексы карты TogsMapSpace. Хранение (TogsMapSpace.Geometry) не сортируется -
// порядок отрисовки и захвата задают индексы (как IndexLarge/TPloIndex в GMF).
//
// TogsPloIndex - индекс по площади (аналог TPloIndex старого GMF):
//   элементы - указатели на примитивы Geometry (индекс ими не владеет);
//   ключ = площадь по убыванию (большие площади снизу), затем ogsID (порядок
//   добавления), затем адрес объекта -> ключ однозначен (Duplicates = False),
//   Search находит ровно тот примитив.
//   Площадь линейных = -1, точечных (точки, вставки блоков, тексты) = -3:
//   прямой обход дает порядок отрисовки площадные -> линии -> точки,
//   обратный - порядок захвата (сверху, от мелких площадей).
//   Площадь в ключе - закэшированное значение примитива (Calculate([calcSquare])):
//   при изменении примитива порядок RemovePrim -> пересчет -> InsertPrim.
//   Если площадь пересчитали в обход этого порядка, IndexOf/RemovePrim
//   находят примитив линейным поиском по указателю.

type

  { TogsPloIndex }

  TogsPloIndex = class(TogsSortedCollection)
  private
   function GetPrim(Index: Integer): TogsGeometry;
  public
   constructor Create;
   destructor Destroy; override;
  // площадь-ключ примитива: площадные - площадь, линейные -1, остальные -3
   class function PloOf(G: TogsGeometry): Double; static;
  //
   function InsertPrim(G: TogsGeometry): Integer;
   function RemovePrim(G: TogsGeometry): Boolean;
   function IndexOf(Item_: Pointer): Integer; override;
  // полная перестройка по элементам коллекции (после массовой загрузки)
   procedure Rebuild(Collection: TogsGeometryCollection);
  // очистка без уничтожения примитивов
   procedure Clear; override;
  //
   property Prim[Index: Integer]: TogsGeometry read GetPrim; default;
  end;

implementation

function ComparePlo(Item1, Item2: Pointer): Integer;
var P1, P2: Double;
    ID1, ID2: Int64;
begin
// площадь по убыванию
 P1 := TogsPloIndex.PloOf(TogsGeometry(Item1));
 P2 := TogsPloIndex.PloOf(TogsGeometry(Item2));
 if P1 > P2 then exit(-1);
 if P1 < P2 then exit(1);
// при равной площади - порядок добавления
 ID1 := TogsGeometry(Item1).ogsID;
 ID2 := TogsGeometry(Item2).ogsID;
 if ID1 < ID2 then exit(-1);
 if ID1 > ID2 then exit(1);
// однозначность для объектов без ogsID
 if NativeUInt(Item1) < NativeUInt(Item2) then exit(-1);
 if NativeUInt(Item1) > NativeUInt(Item2) then exit(1);
 Result := 0;
end;

{ TogsPloIndex }

constructor TogsPloIndex.Create;
begin
 inherited Create(ComparePlo, False, 1);
end;

destructor TogsPloIndex.Destroy;
begin
// примитивами владеет Geometry карты
 DeleteAll;
 inherited Destroy;
end;

class function TogsPloIndex.PloOf(G: TogsGeometry): Double;
begin
// TPoly_Single - наследник TogsLineString, проверяется раньше линий;
// площадь, еще не вычисленная (-1), считается нулевой
 if (G is TogsPolygon) or (G is TogsMultiPolygon) or (G is TPoly_Single) then begin
  Result := G.Square;
  if Result < 0 then Result := 0;
 end else
 if (G is TogsLineString) or (G is TogsMultiLineString) then Result := -1 else
  Result := -3;
end;

function TogsPloIndex.GetPrim(Index: Integer): TogsGeometry;
begin
 Result := TogsGeometry(fList[Index]);
end;

function TogsPloIndex.InsertPrim(G: TogsGeometry): Integer;
begin
 Result := -1;
 if G = nil then exit;
// повторная вставка того же примитива не выполняется (Duplicates = False)
 Result := Add(G);
end;

function TogsPloIndex.IndexOf(Item_: Pointer): Integer;
begin
 Result := inherited IndexOf(Item_);
// ключ изменился в обход RemovePrim -> поиск по указателю
 if Result = -1 then Result := fList.IndexOf(Item_);
end;

function TogsPloIndex.RemovePrim(G: TogsGeometry): Boolean;
var Index: Integer;
begin
 Index := IndexOf(G);
 Result := Index >= 0;
 if Result then Delete(Index);
end;

procedure TogsPloIndex.Rebuild(Collection: TogsGeometryCollection);
var I: Integer;
begin
 DeleteAll;
 if Collection = nil then exit;
 fList.Capacity := Collection.Count;
 for I := 0 to Collection.Count - 1 do fList.Add(Collection.Item[I]);
 fList.Sort(ComparePlo);
end;

procedure TogsPloIndex.Clear;
begin
 DeleteAll;
end;

end.
