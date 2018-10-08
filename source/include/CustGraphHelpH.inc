{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*                                                                           *
*   Copyright(c) 2018 A.Koverdyaev(avk)                                     *
*                                                                           *
*   This code is free software; you can redistribute it and/or modify it    *
*   under the terms of the Apache License, Version 2.0;                     *
*   You may obtain a copy of the License at                                 *
*     http://www.apache.org/licenses/LICENSE-2.0.                           *
*                                                                           *
*  Unless required by applicable law or agreed to in writing, software      *
*  distributed under the License is distributed on an "AS IS" BASIS,        *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
*  See the License for the specific language governing permissions and      *
*  limitations under the License.                                           *
*                                                                           *
*****************************************************************************}

type
  TDisjointSetUnion = record
  private
    FList: array of SizeInt;
    function  GetSize: SizeInt; inline;
    procedure SetSize(aValue: SizeInt);
  public
    procedure Clear; inline;
    procedure Reset;
  { values related to the same subset will have the same Tag }
    function  Tag(aValue: SizeInt): SizeInt;
    function  InSameSet(L, R: SizeInt): Boolean; inline;
    function  InDiffSets(L, R: SizeInt): Boolean; inline;
  { returns True and merges L and R, if L and R related to the different subsets, False otherwise }
    function  Join(L, R: SizeInt): Boolean;
    property  Size: SizeInt read GetSize write SetSize;
  end;

  TIntValue = record
    Value: SizeInt;
    constructor Create(aValue: SizeInt);
    property Key: SizeInt read Value write Value;
  end;

  TIntHashSet = record
  private
  type
    TTable = specialize TGLiteIntHashTable<SizeInt, TIntValue>;
    PEntry = TTable.PEntry;

  public
  type
    TEnumerator = record
    private
      FEnum: TTable.TEnumerator;
      function  GetCurrent: SizeInt; inline;
    public
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: SizeInt read GetCurrent;
    end;

  private
    FTable: TTable;
    function  GetCount: SizeInt; inline;
  public
    function  GetEnumerator: TEnumerator; inline;
    function  ToArray: TIntArray;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure MakeEmpty; inline;
    procedure Clear; inline;
    procedure EnsureCapacity(aValue: SizeInt); inline;
    function  Contains(aValue: SizeInt): Boolean; inline;
    function  Add(aValue: SizeInt): Boolean;
    function  AddAll(constref a: array of SizeInt): SizeInt;
    function  AddAll(constref s: TIntHashSet): SizeInt;
    function  Remove(aValue: SizeInt): Boolean; inline;
    property  Count: SizeInt read GetCount;
  end;

  TIntPair = packed record
  private
    FLess,
    FGreater: SizeInt;
  public
    class function HashCode(constref aValue: TIntPair): SizeInt; static; inline;
    class function Equal(constref L, R: TIntPair): Boolean; static; inline;
    constructor Create(L, R: SizeInt);
    function Key: TIntPair; inline;
    property Left: SizeInt read FLess;
    property Right: SizeInt read FGreater;
  end;

  PIntPair = ^TIntPair;

  TIntPairSet = record
  private
  type
    TTable = specialize TGLiteHashTableLP<TIntPair, TIntPair, TIntPair>;
  var
    FTable: TTable;
    function GetCount: SizeInt; inline;
  public
    procedure Clear; inline;
    function  Contains(L, R: SizeInt): Boolean; inline;
    function  Add(L, R: SizeInt): Boolean;
    function  Remove(L, R: SizeInt): Boolean; inline;
    property  Count: SizeInt read GetCount;
  end;

  TINode = record
    Index,
    Data: SizeInt;
    class operator = (constref L, R: TINode): Boolean; inline;
    class operator <>(constref L, R: TINode): Boolean; inline;
    class operator > (constref L, R: TINode): Boolean; inline;
    class operator < (constref L, R: TINode): Boolean; inline;
    class operator >=(constref L, R: TINode): Boolean; inline;
    class operator <=(constref L, R: TINode): Boolean; inline;
    constructor Create(aIndex, aData: SizeInt);
  end;

  generic TGBinHeapMin<T> = record // for internal use only
  private
  type
    THeap = array of T;

  var
    FHeap: THeap;
    FHandle2Index: TIntArray;
    FIndex2Handle: TIntArray;
    FCount: SizeInt;
    function  GetCapacity: SizeInt; inline;
    procedure FloatUp(aIndex: SizeInt);
    procedure SiftDown(aIndex: SizeInt);
  public
    constructor Create(aSize: SizeInt);
    procedure MakeEmpty; inline;
    function  TryDequeue(out aValue: T): Boolean;
    procedure Enqueue(aHandle: SizeInt; constref aValue: T);
    procedure Update(aHandle: SizeInt; constref aNewValue: T);
    function  Peek(aHandle: SizeInt): T; inline;
    property  Count: SizeInt read FCount;
    property  Capacity: SizeInt read GetCapacity;
  end;

  generic TGPairHeapMin<T> = record // for internal use only
  private
  type
    PNode = ^TNode;
    TNode = record
      Prev,
      Child,
      Sibling: PNode;
      Data: T;
      function AddChild(aNode: PNode): PNode; inline;
    end;

    TNodeList = array of TNode;

  var
    FNodeList: TNodeList;
    FRoot: PNode;
    FCount: SizeInt;
    function  GetCapacity: SizeInt; inline;
    function  NewNode(constref aValue: T; aHandle: SizeInt): PNode;
    function  DequeueItem: T;
    procedure RootMerge(aNode: PNode); inline;
    procedure ExtractNode(aNode: PNode);
    class function  NodeMerge(L, R: PNode): PNode; static;
    class function  TwoPassMerge(aNode: PNode): PNode; static;
    class procedure CutNode(aNode: PNode); static; inline;
  public
  type
    PItem = ^T;
    constructor Create(aSize: SizeInt);
    procedure MakeEmpty; inline;
    function  TryDequeue(out aValue: T): Boolean; inline;
    function  Dequeue: T; inline;
    procedure Enqueue(aHandle: SizeInt; constref aValue: T); inline;
    procedure Update(aHandle: SizeInt; constref aNewValue: T);
    procedure Remove(aHandle: SizeInt); inline;
    function  Peek(aHandle: SizeInt): T; inline;
    function  HeadPtr(aHandle: SizeInt): PItem; inline;
    property  Count: SizeInt read FCount;
    property  Capacity: SizeInt read GetCapacity;
  end;

  generic TGPairHeapMax<T> = record // for internal use only
  private
  type
    PNode = ^TNode;
    TNode = record
      Prev,
      Child,
      Sibling: PNode;
      Data: T;
      function AddChild(aNode: PNode): PNode; inline;
    end;

    TNodeList = array of TNode;

  var
    FNodeList: TNodeList;
    FRoot: PNode;
    FCount: SizeInt;
    function  GetCapacity: SizeInt; inline;
    function  NewNode(constref aValue: T; aHandle: SizeInt): PNode; inline;
    function  DequeueItem: T;
    procedure RootMerge(aNode: PNode); inline;
    class function  NodeMerge(L, R: PNode): PNode; static;
    class function  TwoPassMerge(aNode: PNode): PNode; static;
    class procedure CutNode(aNode: PNode); static; inline;
  public
  type
    PItem = ^T;
    constructor Create(aSize: SizeInt);
    procedure MakeEmpty; inline;
    function  TryDequeue(out aValue: T): Boolean; inline;
    function  Dequeue: T; inline;
    procedure Enqueue(aHandle: SizeInt; constref aValue: T); inline;
    procedure Update(aHandle: SizeInt; constref aNewValue: T);
    function  Peek(aHandle: SizeInt): T; inline;
    function  HeadPtr(aHandle: SizeInt): PItem; inline;
    property  Count: SizeInt read FCount;
    property  Capacity: SizeInt read GetCapacity;
  end;

  TINodePqMin = specialize TGPairHeapMin<TINode>;
  TINodePqMax = specialize TGPairHeapMax<TINode>;

  { TGJoinableHashList for internal use only; TEntry must provide
      property Key: SizeInt and numeric field Weight }
  generic TGJoinableHashList<TEntry> = record
  private
  type
    TTable = specialize TGLiteIntHashTable<SizeInt, TEntry>;
  public
  type
    TEnumerator = TTable.TEnumerator;
    PEntry      = ^TEntry;

  private
    FTable: TTable;
    function  GetCount: SizeInt; inline;
  public
    function  GetEnumerator: TEnumerator; inline;
    procedure EnsureCapacity(aValue: SizeInt); inline;
    procedure Add(constref aValue: TEntry);
    procedure AddAll(constref aList: TGJoinableHashList);
    procedure Remove(aValue: SizeInt); inline;
    property  Count: SizeInt read GetCount;
  end;

  generic TGSimpleWeight<T> = record
    Weight: T;
    constructor Create(aValue: T);
  end;

  TSimpleStack = record
  private
    Items: TIntArray;
    Top: SizeInt;
    function  GetCapacity: SizeInt; inline;
  public
    constructor Create(aSize: SizeInt);
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Push(aValue: SizeInt); inline;
    function  Pop: SizeInt; inline;
    function  TryPop(out aValue: SizeInt): Boolean; inline;
    function  Peek: SizeInt; inline;
    function  TryPeek(out aValue: SizeInt): Boolean; inline;
    property  Capacity: SizeInt read GetCapacity;
  end;
  PSimpleStack = ^TSimpleStack;

  TCostItem = record
    Index: SizeInt;
    Cost: TCost;
    class operator = (constref L, R: TCostItem): Boolean; inline;
    class operator <>(constref L, R: TCostItem): Boolean; inline;
    class operator > (constref L, R: TCostItem): Boolean; inline;
    class operator < (constref L, R: TCostItem): Boolean; inline;
    class operator >=(constref L, R: TCostItem): Boolean; inline;
    class operator <=(constref L, R: TCostItem): Boolean; inline;
    constructor Create(aIndex: SizeInt; aCost: TCost);
    property Key: SizeInt read Index;
  end;

  generic TGWeightPathHelper<TVertex, TWeight, TEdgeData, TEqRel> = class
  public
  type
    TWeightArray  = array of TWeight;

  strict private
  class var
    CFInfWeight,
    CFNegInfWeight,
    CFZeroWeight: TWeight;
    class constructor Init;
    class function CreateAndFill(aValue: TWeight; aSize: SizeInt): TWeightArray; static;
    class function wMax(L, R: TWeight): TWeight; static;
    class function ExtractCycle(aRoot, aLen: SizeInt; constref aTree: TIntArray): TIntArray; static;
  public
  type
    TWeightEdge = record
      Source,
      Destination: SizeInt;
      Weight:  TWeight;
      class operator = (constref L, R: TWeightEdge): Boolean; inline;
      class operator <>(constref L, R: TWeightEdge): Boolean; inline;
      class operator > (constref L, R: TWeightEdge): Boolean; inline;
      class operator < (constref L, R: TWeightEdge): Boolean; inline;
      class operator >=(constref L, R: TWeightEdge): Boolean; inline;
      class operator <=(constref L, R: TWeightEdge): Boolean; inline;
      constructor Create(s, d: SizeInt; w: TWeight);
    end;

    TWeightItem = record
      Index: SizeInt;
      Weight: TWeight;
      class operator = (constref L, R: TWeightItem): Boolean; inline;
      class operator <>(constref L, R: TWeightItem): Boolean; inline;
      class operator > (constref L, R: TWeightItem): Boolean; inline;
      class operator < (constref L, R: TWeightItem): Boolean; inline;
      class operator >=(constref L, R: TWeightItem): Boolean; inline;
      class operator <=(constref L, R: TWeightItem): Boolean; inline;
      constructor Create(aIndex: SizeInt; w: TWeight);
      property Key: SizeInt read Index;
    end;

    TRankItem = record
      Index: SizeInt;
      Rank,
      Weight: TWeight;
      class operator = (constref L, R: TRankItem): Boolean; inline;
      class operator <>(constref L, R: TRankItem): Boolean; inline;
      class operator > (constref L, R: TRankItem): Boolean; inline;
      class operator < (constref L, R: TRankItem): Boolean; inline;
      class operator >=(constref L, R: TRankItem): Boolean; inline;
      class operator <=(constref L, R: TRankItem): Boolean; inline;
      constructor Create(aIndex: SizeInt; aRank, aWeight: TWeight);
    end;

    TGraph     = specialize TGCustomGraph<TVertex, TEdgeData, TEqRel>;
    TEstimate  = function(constref aSrc, aDst: TVertex): TWeight;
    TPairHeap  = specialize TGPairHeapMin<TWeightItem>;
    TBinHeap   = specialize TGBinHeapMin<TWeightItem>;
    TAStarHeap = specialize TGBinHeapMin<TRankItem>;
    //TAStarHeap   = specialize TGPairHeapMin<TRankItem>;
    TEdgeArray = array of TWeightEdge;

  { Dijkstra's algorithm: single-source shortest paths problem for non-negative weights  }
    class function  DijkstraSssp(g: TGraph; aSrc: SizeInt): TWeightArray;
    class function  DijkstraSssp(g: TGraph; aSrc: SizeInt; out aPathTree: TIntArray): TWeightArray; static;
  { Dijkstra's pathfinding algorithm }
    class function  DijkstraPath(g: TGraph; aSrc, aDst: SizeInt): TWeight; static;
    class function  DijkstraPath(g: TGraph; aSrc, aDst: SizeInt; out aWeight: TWeight): TIntArray; static;
  { A* pathfinding algorithm }
    class function  AStar(g: TGraph; aSrc, aDst: SizeInt; out aWeight: TWeight; aEst: TEstimate): TIntArray; static;
  { modification of Bellman-Ford-Moore algorithm(aka SPFA), faster on random graps;
    en.wikipedia.org/wiki/Shortest_Path_Faster_Algorithm }
    class function  SpfaBase(g: TGraph; aSrc: SizeInt; out aTree: TIntArray; out aWeights: TWeightArray): SizeInt;
                    static;
    class function  Spfa2Base(g: TGraph; aSrc: SizeInt; out aTree: TIntArray; out aWeights: TWeightArray): SizeInt;
                    static;
  { modification of Bellman-Ford-Moore algorithm with Tarjan subtree disassembly,
    faster negative cycle detection;
    B.V.Cherkassky and A.V.Goldberg: Negative-cycle detection algorithms. }
    class function  BfmtBase(g: TGraph; aSrc: SizeInt; out aParents: TIntArray; out aWeights: TWeightArray): SizeInt;
                    static;
  { negative cycle detection }
    class function  NegDetect(g: TGraph; aSrc: SizeInt): TIntArray; static;
  { BFMT single-source shortest paths problem }
    class function  BfmtSssp(g: TGraph; aSrc: SizeInt; out aWeights: TWeightArray): Boolean; static;
    class function  BfmtSssp(g: TGraph; aSrc: SizeInt; out aPaths: TIntArray; out aWeights: TWeightArray): Boolean;
                    static;
  { BFMT pathfinding }
    class function  BfmtPath(g: TGraph; aSrc, aDst: SizeInt; out aPath: TIntArray; out aWeight: TWeight): Boolean;
                    static;
  { fills array with InfWeight }
    class function  CreateWeightArray(aLen: SizeInt): TWeightArray; static; inline;
  { fills array with NegInfWeight }
    class function  CreateWeightArrayNI(aLen: SizeInt): TWeightArray; static; inline;
  { fills array with ZeroWeight }
    class function  CreateWeightArrayZ(aLen: SizeInt): TWeightArray; static; inline;

    class property InfWeight: TWeight read CFInfWeight;
    class property NegInfWeight: TWeight read CFNegInfWeight;
    class property ZeroWeight: TWeight read CFZeroWeight;
  end;

  { TGCustomDotWriter basic writer into Graphviz dot format }
  generic TGCustomDotWriter<TVertex, TEdgeData, TEqRel> = class abstract
  public
  type
    TWriteDirection = (wdTopToBottom, wdLeftToWrite);
    TGraph = specialize TGCustomGraph<TVertex, TEdgeData, TEqRel>;
    TOnStartWrite = function(aGraph: TGraph): utf8string of object;
    TOnWriteVertex = function(aGraph: TGraph; aIndex: SizeInt): utf8string of object;
    TOnWriteEdge = function(aGraph: TGraph; constref aEdge: TGraph.TEdge): utf8string of object;

  protected
  const
    DIRECTS: array[TWriteDirection] of utf8string = ('rankdir=TB', 'rankdir=LR');
  var
    FGraphMark,
    FEdgeMark: utf8string;
    FDirection: TWriteDirection;
    FOnStartWrite: TOnStartWrite;
    FOnWriteVertex: TOnWriteVertex;
    FOnWriteEdge: TOnWriteEdge;
    function Graph2Dot(aGraph: TGraph): utf8string; virtual; abstract;
    function DefaultWriteEdge({%H-}aGraph: TGraph; constref aEdge: TGraph.TEdge): utf8string; virtual;
  public
    procedure SaveToDot(aGraph: TGraph; const aFileName: string);
    property Direction: TWriteDirection read FDirection write FDirection;
    property OnStartWrite: TOnStartWrite read FOnStartWrite write FOnStartWrite;
    property OnWriteVertex: TOnWriteVertex read FOnWriteVertex write FOnWriteVertex;
    property OnWriteEdge: TOnWriteEdge read FOnWriteEdge write FOnWriteEdge;
  end;

