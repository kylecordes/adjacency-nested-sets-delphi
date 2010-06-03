unit uNester;

{
  TNester

  Copyright 2007 Kyle Cordes

  Released under the MIT License, see license.txt

  This class converts an "Adjacency" hierarchy representation in to a
  "nested set" representation.  Search the web for Joe Celko's nested set
  articles to learn what that means.

  This assumes that notes are identified by ints.

  To use this class:

  * create an instance. instances are single-shot, one use.

  * call "AddNode" 0..N times, once for each node.

  * call Convert.  The processing will occur, and your handler
    will be called once for each node, with the Left and Right values.
}

interface

uses
  Classes, SysUtils, Contnrs;

const
  NULLNODEID = -99999;
  INHERITPARENTTAG = -99999;

type
  // TNode and TNodeHashList are here because of how Object Pascal works.
  // They are NOT intended to be part of the public interface of this module.

  TNode = class
    ID, ParentID: integer;
    Children: TObjectList;
    Left, Right, Depth: integer;
    Tag: integer;
    constructor Create(const AID, AParentID: integer; const ATag: integer = 0);
    destructor Destroy; override;
  end;

  TNodeHashList = class(TBucketList)
  protected
    function GetData(AItem: Integer): TNode;
    procedure SetData(AItem: Integer; const AData: TNode);
    function BucketFor(AItem: Pointer): Integer; override;
  public
    function Add(AItem: Integer; AData: TNode): TNode;
    property Data[AItem: Integer]: TNode read GetData write SetData; default;
    function Exists(AItem: Integer): Boolean;
  end;

  // Only this portion is intended to be used from the outside world.

  ENesterException = class(Exception)
  end;

  TNodeHandler = procedure(const ID, Left, Right, Depth, Tag: integer) of object;

  TNester = class
  private
    FNodeHash: TNodeHashList;
    FNodes: TObjectList;
    FStrict: boolean;
    FRootNodes: TObjectList;
    procedure WireUpNodes;
    procedure Walk(const Node: TNode; var N: integer; const Depth: integer;
      const Tag: integer = INHERITPARENTTAG);
    procedure OutputNodesToHandler(const Handler: TNodeHandler);
  public
    procedure AddNode(const AID, AParentID: integer; const ATag: integer = INHERITPARENTTAG);
    procedure Convert(const Handler: TNodeHandler);
    constructor Create(const StrictMode: boolean = True);
    destructor Destroy; override;
  end;

implementation

{ TNester }

constructor TNester.Create(const StrictMode: boolean);
begin
  FNodeHash := TNodeHashList.Create(bl256);
  FNodes := TObjectList.Create(True);
  FRootNodes := TObjectList.Create(False);
  FStrict := StrictMode;
end;

destructor TNester.Destroy;
begin
  FreeAndNil(FNodeHash);
  FreeAndNil(FRootNodes);
  FreeAndNil(FNodes);  // frees the nodes also
  inherited;
end;

procedure TNester.OutputNodesToHandler(const Handler: TNodeHandler);
var
  I: integer;
  Node: TNode;
begin
  if not Assigned(Handler) then Exit;
  
  for I := 0 to FNodes.Count - 1 do begin
    Node := TNode(FNodes[I]);
    if Node.Left>0 then  // skip orphans    
      Handler(Node.ID, Node.Left, Node.Right, Node.Depth, Node.Tag);
  end;
end;

procedure TNester.AddNode(const AID, AParentID, ATag: integer);
var
  NewNode: TNode;
begin
  NewNode := TNode.Create(AID, AParentID, ATag);
  FNodeHash.Add(AID, NewNode);
  FNodes.Add(NewNode);

  if AParentID = NULLNODEID then
    FRootNodes.Add(NewNode);
end;

procedure TNester.WireUpNodes;
var
  I: integer;
  Node, Parent: TNode;
begin
  for I := 0 to FNodes.Count - 1 do begin
    Node := TNode(FNodes[I]);

    if Node.ParentID = NULLNODEID then
      Continue;

    if not FNodeHash.Exists(Node.ParentID) then begin
      if FStrict then
        raise ENesterException.Create('TNester - parent ID does not exist')
      else
        Continue;  // Skip
    end;

    Parent := FNodeHash[Node.ParentID];
    Parent.Children.Add(Node);
  end;
end;

procedure TNester.Convert(const Handler: TNodeHandler);
var
  StartingN: integer;
  I: integer;
begin
  if FNodes.Count = 0 then
    Exit;

  if FRootNodes.Count = 0 then
    raise ENesterException.Create('TNester requires the hierarchy to have a root');

  if FStrict and (FRootNodes.Count > 1) then
    raise ENesterException.Create('TNester handles hierarchies with a single root');

  WireUpNodes;

  StartingN := 1;
  for I := 0 to FRootNodes.Count - 1 do
    Walk(FRootNodes[I] as TNode, StartingN, 1);  // Recursive Walk

  if FStrict and (StartingN <> (FNodes.Count * 2 + 1)) then
    raise ENesterException.Create('TNester error - there are orphan nodes');

  OutputNodesToHandler(Handler);
end;

// TODO make this inherit tags

procedure TNester.Walk(const Node: TNode; var N: integer; const Depth: integer;
   const Tag: integer);
var
  I: integer;
  Child: TNode;
begin
  if Node=nil then
    Exit;

  if N > 2 * FNodes.Count  then
    raise Exception.Create('TNester error - loop in hierarchy');

  Node.Depth := Depth;
  Node.Left := N;
  Inc(N);

  if Node.Tag = INHERITPARENTTAG then
    Node.Tag := Tag;

  for I := 0 to Node.Children.Count - 1 do begin
    Child := Node.Children[I] as TNode;
    Walk(Child, N, Depth+1, Node.Tag);
  end;

  Node.Right := N;
  Inc(N);
end;

{ TNode }

constructor TNode.Create(const AID, AParentID, ATag: integer);
begin
  ID := AID;
  ParentID := AParentID;
  Tag := ATag;
  Children := TObjectList.Create(False);
end;

destructor TNode.Destroy;
begin
  FreeAndNil(Children);
  inherited;
end;

{ TNodeHashList }

function TNodeHashList.Add(AItem: Integer; AData: TNode): TNode;
begin
  Result := TNode(inherited Add(Pointer(AItem), AData));
end;

function TNodeHashList.BucketFor(AItem: Pointer): Integer;
begin
  // AItem is really an int; for this purpose it is already hashed enough
  // and only needs to be truncated to the right # of bits

  Result := 1;
end;

function TNodeHashList.Exists(AItem: Integer): Boolean;
begin
  Result := inherited Exists(Pointer(AItem));
end;

function TNodeHashList.GetData(AItem: Integer): TNode;
begin
  Result := TNode(inherited Data[Pointer(AItem)]);
end;

procedure TNodeHashList.SetData(AItem: Integer; const AData: TNode);
begin
  inherited Data[Pointer(AItem)] := AData;
end;

end.
