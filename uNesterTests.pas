unit uNesterTests;

interface

uses
  TestFramework, uNester, SysUtils, Classes;

type
  TestTNodeHashList = class(TTestCase)
  strict private
    List: TNodeHashList;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGettingOneBack;
    procedure TestGettingSeveralBack;
  end;

  TestTNester = class(TTestCase)
  strict private
    N: TNester;
    TestResult: string;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  private
    procedure HandlerForNestTesting(const ID, Left, Right, Depth, Tag: integer);
    procedure HandlerForTagTesting(const ID, Left, Right, Depth, Tag: integer);
  published
    procedure TestEmpty;
    procedure TestSingleNode;
    procedure TestParentChild;
    procedure TestMoreComplexTree;
    procedure TestOrphanIsDetected;
    procedure TestFailsWithBadParent;
    procedure TestFailsWithNoRoot;
    procedure TestFailsWithTwoRoots;
    procedure TestToleratesTwoRoots;
    procedure TestToleratesLoop;
    procedure TestToleratesBadParent;
    procedure TestInheritsTags;
  end;

implementation

procedure TestTNester.SetUp;
begin
  N := TNester.Create;
  TestResult := '';
end;

procedure TestTNester.TearDown;
begin
  FreeAndNil(N);
end;

procedure TestTNester.HandlerForNestTesting(const ID, Left, Right, Depth, Tag: integer);
begin
  TestResult := TestResult + Format('%d,%d,%d;', [Left, ID, Right]);
end;

procedure TestTNester.HandlerForTagTesting(const ID, Left, Right, Depth,
  Tag: integer);
begin
  TestResult := TestResult + Format('%d(%d);', [ID, Tag]);
end;

procedure TestTNester.TestEmpty;
begin
  // Dont put in anything
  N.Convert(HandlerForNestTesting);
  CheckEquals('', TestResult);
end;

procedure TestTNester.TestSingleNode;
begin
  N.AddNode(1, NULLNODEID);
  N.Convert(HandlerForNestTesting);
  CheckEquals('1,1,2;', TestResult);
end;

procedure TestTNester.TestParentChild;
begin
  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 1);
  N.Convert(HandlerForNestTesting);
  CheckEquals('1,1,4;2,2,3;', TestResult);
end;

procedure TestTNester.TestMoreComplexTree;
begin
  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 1);
  N.AddNode(3, 1);
  N.AddNode(4, 1);
  N.AddNode(5, 2);
  N.AddNode(6, 2);
  N.AddNode(7, 6);
  N.Convert(HandlerForNestTesting);
  CheckEquals('1,1,14;2,2,9;10,3,11;12,4,13;3,5,4;5,6,8;6,7,7;', TestResult);
end;

procedure TestTNester.TestOrphanIsDetected;
begin
  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 1);

  N.AddNode(3, 4);
  N.AddNode(4, 3);

  ExpectedException := ENesterException;
  N.Convert(HandlerForNestTesting);
end;

procedure TestTNester.TestFailsWithBadParent;
begin
  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 34);
  ExpectedException := ENesterException;

  N.Convert(HandlerForNestTesting);
end;

procedure TestTNester.TestFailsWithNoRoot;
begin
  N.AddNode(1, 0);
  N.AddNode(2, 1);
  N.AddNode(3, 2);
  N.AddNode(4, 3);

  ExpectedException := ENesterException;
  N.Convert(HandlerForNestTesting);
end;

procedure TestTNester.TestFailsWithTwoRoots;
begin
  ExpectedException := ENesterException;
  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 1);
  N.AddNode(3, NULLNODEID);
  N.AddNode(4, 3);
  N.Convert(HandlerForNestTesting);
end;

procedure TestTNester.TestToleratesBadParent;
begin
  FreeAndNil(N);
  N := TNester.Create(False);
  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 34);
  N.Convert(HandlerForNestTesting);
end;

procedure TestTNester.TestToleratesLoop;
begin
  FreeAndNil(N);
  N := TNester.Create(False);

  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 1);

  N.AddNode(3, 4);
  N.AddNode(4, 3);

  N.Convert(HandlerForNestTesting);
  CheckEquals('1,1,4;2,2,3;', TestResult);
end;

procedure TestTNester.TestToleratesTwoRoots;
begin
  FreeAndNil(N);
  N := TNester.Create(False);

  N.AddNode(1, NULLNODEID);
  N.AddNode(2, 1);
  N.AddNode(3, NULLNODEID);
  N.AddNode(4, 3);
  N.Convert(HandlerForNestTesting);
  CheckEquals('1,1,4;2,2,3;5,3,8;6,4,7;', TestResult);
end;

{ TestTNodeHashList }

procedure TestTNodeHashList.SetUp;
begin
  inherited;
  List := TNodeHashList.Create;
end;

procedure TestTNodeHashList.TearDown;
begin
  inherited;
  FreeAndNil(List);
end;

procedure TestTNodeHashList.TestGettingOneBack;
var
  A: TNode;
begin
  A := TNode.Create(1, 5);
  List.Add(1, A);
  CheckEquals(A.ID, List[1].ID);
end;

procedure TestTNodeHashList.TestGettingSeveralBack;
begin
  List.Add(1, TNode.Create(1, 5));
  List.Add(2, TNode.Create(2, 5));
  List.Add(56, TNode.Create(56, 5));
  CheckEquals(1, List[1].ID);
  CheckEquals(2, List[2].ID);
  CheckEquals(56, List[56].ID);
end;

procedure TestTNester.TestInheritsTags;
begin
{                        1
                       /  \ \
                      2   3  4
                     / \
                   5    6
                       /
                      7
}

  N.AddNode(1, NULLNODEID, 45);
  N.AddNode(2, 1, 68);
  N.AddNode(3, 1);
  N.AddNode(4, 1);
  N.AddNode(5, 2);
  N.AddNode(6, 2);
  N.AddNode(7, 6);
  N.Convert(HandlerForTagTesting);
  CheckEquals('1(45);2(68);3(45);4(45);5(68);6(68);7(68);', TestResult);
end;

initialization
  RegisterTest(TestTNodeHashList.Suite);
  RegisterTest(TestTNester.Suite);
end.

