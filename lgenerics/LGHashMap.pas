{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Generic hashmap implementations.                                        *
*                                                                           *
*   Copyright(c) 2018-2019 A.Koverdyaev(avk)                                *
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
unit LGHashMap;

{$mode objfpc}{$H+}
{$INLINE ON}
{$MODESWITCH NESTEDPROCVARS}
{$MODESWITCH ADVANCEDRECORDS}

interface

uses

  SysUtils,
  LGUtils,
  {%H-}LGHelpers,
  LGAbstractContainer,
  LGHashTable,
  LGStrConst;

type

  { TGAbstractHashMap: common abstract hashmap ancestor class }
  generic TGAbstractHashMap<TKey, TValue> = class abstract(specialize TGAbstractMap<TKey, TValue>)
  protected
  type
    TAbstractHashMap      = specialize TGAbstractHashMap<TKey, TValue>;
    THashMapClass        = class of TAbstractHashMap;
    THashTable           = specialize TGAbstractHashTable<TKey, TEntry>;
    THashTableClass      = class of THashTable;
    TSearchResult        = THashTable.TSearchResult;

    TKeyEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: THashTable.TEntryEnumerator;
      function  GetCurrent: TKey; override;
    public
      constructor Create(aMap: TAbstractHashMap);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TValueEnumerable = class(TCustomValueEnumerable)
    protected
      FEnum: THashTable.TEntryEnumerator;
      function  GetCurrent: TValue; override;
    public
      constructor Create(aMap: TAbstractHashMap);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TEntryEnumerable = class(TCustomEntryEnumerable)
    protected
      FEnum: THashTable.TEntryEnumerator;
      function  GetCurrent: TEntry; override;
    public
      constructor Create(aMap: TAbstractHashMap);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

  var
    FTable: THashTable;
    function  GetExpandTreshold: SizeInt; inline;
    function  GetCount: SizeInt; override;
    function  GetCapacity: SizeInt; override;
    function  GetFillRatio: Single;
    function  GetLoadFactor: Single;
    procedure SetLoadFactor(aValue: Single); inline;
    function  Find(constref aKey: TKey): PEntry; override;
    //return True if aKey found, otherwise insert (garbage) pair and return False;
    function  FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean; override;
    function  DoExtract(constref aKey: TKey; out v: TValue): Boolean; override;
    function  DoRemoveIf(aTest: TKeyTest): SizeInt; override;
    function  DoRemoveIf(aTest: TOnKeyTest): SizeInt; override;
    function  DoRemoveIf(aTest: TNestKeyTest): SizeInt; override;
    function  DoExtractIf(aTest: TKeyTest): TEntryArray; override;
    function  DoExtractIf(aTest: TOnKeyTest): TEntryArray; override;
    function  DoExtractIf(aTest: TNestKeyTest): TEntryArray; override;
    procedure DoClear; override;
    procedure DoEnsureCapacity(aValue: SizeInt); override;
    procedure DoTrimToFit; override;
    function  GetKeys: IKeyEnumerable; override;
    function  GetValues: IValueEnumerable; override;
    function  GetEntries: IEntryEnumerable; override;
    class function GetTableClass: THashTableClass; virtual; abstract;
    class function GetClass: THashMapClass; virtual; abstract;
  public
    class function DefaultLoadFactor: Single; inline;
    class function MaxLoadFactor: Single; inline;
    class function MinLoadFactor: Single; inline;
    constructor Create;
    constructor Create(const a: array of TEntry);
    constructor Create(e: IEntryEnumerable);
    constructor Create(aCapacity: SizeInt);
    constructor Create(aCapacity: SizeInt; const a: array of TEntry);
    constructor Create(aCapacity: SizeInt; e: IEntryEnumerable);
    constructor Create(aLoadFactor: Double);
    constructor Create(aLoadFactor: Single; const a: array of TEntry);
    constructor Create(aLoadFactor: Single; e: IEntryEnumerable);
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single);
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single; const a: array of TEntry);
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single; e: IEntryEnumerable);
    constructor CreateCopy(aMap: TAbstractHashMap);
    destructor Destroy; override;
    function  Clone: TAbstractHashMap; override;
    property  LoadFactor: Single read GetLoadFactor write SetLoadFactor;
    property  FillRatio: Single read GetFillRatio;
  { The number of entries that can be written without rehashing }
    property  ExpandTreshold: SizeInt read GetExpandTreshold;
  end;

  { TGBaseHashMapLP implements open addressing hashmap with linear probing;
      TKeyEqRel must provide:
        class function HashCode([const[ref]] aValue: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean; }
  generic TGBaseHashMapLP<TKey, TValue, TKeyEqRel> = class(specialize TGAbstractHashMap<TKey, TValue>)
  protected
    class function GetTableClass: THashTableClass; override;
    class function GetClass: THashMapClass; override;
  end;

  { TGHashMapLP implements open addressing hashmap with linear probing;
    it assumes that type TKey implements TKeyEqRel }
  generic TGHashMapLP<TKey, TValue> = class(specialize TGBaseHashMapLP<TKey, TValue, TKey>);

  { TGBaseHashMapLPT implements open addressing hashmap with linear probing and lazy deletion }
  generic TGBaseHashMapLPT<TKey, TValue, TKeyEqRel> = class(specialize TGAbstractHashMap<TKey, TValue>)
  private
    function GetTombstonesCount: SizeInt; inline;
  protected
  type
    TTableLPT = specialize TGOpenAddrLPT<TKey, TEntry, TKeyEqRel>;

    class function GetTableClass: THashTableClass; override;
    class function GetClass: THashMapClass; override;
  public
    procedure ClearTombstones; inline;
    property  TombstonesCount: SizeInt read GetTombstonesCount;
  end;

  { TGHashMapLPT implements open addressing hashmap with linear probing and lazy deletion;
    it assumes that type TKey implements TKeyEqRel }
  generic TGHashMapLPT<TKey, TValue> = class(specialize TGBaseHashMapLPT<TKey, TValue, TKey>);

  { TGBaseHashMapQP implements open addressing hashmap with quadratic probing(c1 = c2 = 1/2)}
  generic TGBaseHashMapQP<TKey, TValue, TKeyEqRel> = class(specialize TGAbstractHashMap<TKey, TValue>)
  private
    function GetTombstonesCount: SizeInt; inline;
  protected
  type
    TTableQP = specialize TGOpenAddrQP<TKey, TEntry, TKeyEqRel>;

    class function GetTableClass: THashTableClass; override;
    class function GetClass: THashMapClass; override;
  public
    procedure ClearTombstones; inline;
    property  TombstonesCount: SizeInt read GetTombstonesCount;
  end;

  { TGHashMapQP implements open addressing hashmap with quadratic probing(c1 = c2 = 1/2);
    it assumes that type TKey implements TKeyEqRel }
  generic TGHashMapQP<TKey, TValue> = class(specialize TGBaseHashMapQP<TKey, TValue, TKey>);

  { TGBaseChainHashMap implements node based hashmap with singly linked list chains }
  generic TGBaseChainHashMap<TKey, TValue, TKeyEqRel> = class(specialize TGAbstractHashMap<TKey, TValue>)
  protected
    class function GetTableClass: THashTableClass; override;
    class function GetClass: THashMapClass; override;
  end;

  { TGChainHashMap implements node based hashmap with singly linked list chains;
    it assumes that type TKey implements TKeyEqRel }
  generic TGChainHashMap<TKey, TValue> = class(specialize TGBaseChainHashMap<TKey, TValue, TKey>)
    function Clone: TGChainHashMap; override;
  end;

  { TGBaseOrderedHashMap implements node based hashmap with predictable iteration order,
    which is the order in which elements were inserted into the map (insertion-order) }
  generic TGBaseOrderedHashMap<TKey, TValue, TKeyEqRel> = class(specialize TGAbstractHashMap<TKey, TValue>)
  private
  type
    TOrdTable = specialize TGOrderedHashTable<TKey, TEntry, TKeyEqRel>;

    function  GetUpdateOnHit: Boolean; inline;
    procedure SetUpdateOnHit(aValue: Boolean); inline;
  protected
    class function GetTableClass: THashTableClass; override;
    class function GetClass: THashMapClass; override;
  public
    function FindFirst(out aEntry: TEntry): Boolean;
    function FindLast(out aEntry: TEntry): Boolean;
    function FindFirstKey(out aKey: TKey): Boolean;
    function FindLastKey(out aKey: TKey): Boolean;
    function FindFirstValue(out aValue: TValue): Boolean;
    function FindLastValue(out aValue: TValue): Boolean;
    function ExtractFirst(out aEntry: TEntry): Boolean;
    function ExtractLast(out aEntry: TEntry): Boolean;
    function RemoveFirst: Boolean;
    function RemoveLast: Boolean;
    property UpdateOnHit: Boolean read GetUpdateOnHit write SetUpdateOnHit;
  end;

  { TGOrderedHashMap implements node based hashmap with predictable iteration order,
    which is the order in which elements were inserted into the map (insertion-order);
    it assumes that type TKey implements TKeyEqRel }
  generic TGOrderedHashMap<TKey, TValue> = class(specialize TGBaseOrderedHashMap<TKey, TValue, TKey>)
    function Clone: TGOrderedHashMap; override;
  end;

  { TGCustomObjectHashMap
      note: for equality comparision of (TValue as TObject) used TObjectHelper from LGHelpers }
  generic TGCustomObjectHashMap<TKey, TValue> = class abstract(specialize TGAbstractHashMap<TKey, TValue>)
  private
    FOwnsKeys: Boolean;
    FOwnsValues: Boolean;
  protected
  type
    TObjectHashMapClass = class of TGCustomObjectHashMap;

    procedure EntryRemoving(p: PEntry);
    procedure SetOwnership(aOwns: TMapObjOwnership); inline;
    function  DoRemove(constref aKey: TKey): Boolean; override;
    function  DoRemoveIf(aTest: TKeyTest): SizeInt; override;
    function  DoRemoveIf(aTest: TOnKeyTest): SizeInt; override;
    function  DoRemoveIf(aTest: TNestKeyTest): SizeInt; override;
    procedure DoClear; override;
    function  DoSetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean; override;
    function  DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean; override;
    class function GetClass: TObjectHashMapClass; reintroduce; virtual; abstract;
  public
    constructor Create(aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(constref a: array of TEntry; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(e: IEntryEnumerable; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aCapacity: SizeInt; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aCapacity: SizeInt; const a: array of TEntry; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aCapacity: SizeInt; e: IEntryEnumerable; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aLoadFactor: Single; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aLoadFactor: Single; const a: array of TEntry; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aLoadFactor: Single; e: IEntryEnumerable; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single; aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single; const a: array of TEntry;
                       aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single; e: IEntryEnumerable;
                       aOwns: TMapObjOwnership = OWNS_BOTH);
    constructor CreateCopy(aMap: TGCustomObjectHashMap);
    property  OwnsKeys: Boolean read FOwnsKeys write FOwnsKeys;
    property  OwnsValues: Boolean read FOwnsValues write FOwnsValues;
  end;

  generic TGObjectHashMapLP<TKey, TValue, TKeyEqRel> = class(specialize TGCustomObjectHashMap<TKey, TValue>)
  protected
    class function GetTableClass: THashTableClass; override;
    class function GetClass: TObjectHashMapClass; override;
  public
    function Clone: TGObjectHashMapLP; override;
  end;

  generic TGObjHashMapLP<TKey, TValue> = class(specialize TGObjectHashMapLP<TKey, TValue, TKey>);

  generic TGObjectHashMapLPT<TKey, TValue, TKeyEqRel> = class(specialize TGCustomObjectHashMap<TKey, TValue>)
  private
    function GetTombstonesCount: SizeInt; inline;
  protected
  type
    TTableLPT = specialize TGOpenAddrLPT<TKey, TEntry, TKeyEqRel>;

    class function GetTableClass: THashTableClass; override;
    class function GetClass: TObjectHashMapClass; override;
  public
    function  Clone: TGObjectHashMapLPT; override;
    procedure ClearTombstones; inline;
    property  TombstonesCount: SizeInt read GetTombstonesCount;
  end;

  generic TGObjHashMapLPT<TKey, TValue> = class(specialize TGObjectHashMapLPT<TKey, TValue, TKey>);

  generic TGObjectHashMapQP<TKey, TValue, TKeyEqRel> = class(specialize TGCustomObjectHashMap<TKey, TValue>)
  private
    function GetTombstonesCount: SizeInt; inline;
  protected
  type
    TTableQP = specialize TGOpenAddrQP<TKey, TEntry, TKeyEqRel>;

    class function GetTableClass: THashTableClass; override;
    class function GetClass: TObjectHashMapClass; override;
  public
    function  Clone: TGObjectHashMapQP; override;
    procedure ClearTombstones; inline;
    property  TombstonesCount: SizeInt read GetTombstonesCount;
  end;

  generic TGObjHashMapQP<TKey, TValue> = class(specialize TGObjectHashMapQP<TKey, TValue, TKey>);

  generic TGObjectChainHashMap<TKey, TValue, TKeyEqRel> = class(specialize TGCustomObjectHashMap<TKey, TValue>)
  protected
    class function GetTableClass: THashTableClass; override;
    class function GetClass: TObjectHashMapClass; override;
  public
    function Clone: TGObjectChainHashMap; override;
  end;

  generic TGObjChainHashMap<TKey, TValue> = class(specialize TGObjectChainHashMap<TKey, TValue, TKey>);

  { TGObjectOrdHashMap }
  generic TGObjectOrdHashMap<TKey, TValue, TKeyEqRel> = class(specialize TGCustomObjectHashMap<TKey, TValue>)
  private
  type
    TOrdTable = specialize TGOrderedHashTable<TKey, TEntry, TKeyEqRel>;

    function  GetUpdateOnHit: Boolean; inline;
    procedure SetUpdateOnHit(aValue: Boolean); inline;
  protected
    class function GetTableClass: THashTableClass; override;
    class function GetClass: TObjectHashMapClass; override;
  public
    function Clone: TGObjectOrdHashMap; override;
    function FindFirst(out aEntry: TEntry): Boolean;
    function FindLast(out aEntry: TEntry): Boolean;
    function FindFirstKey(out aKey: TKey): Boolean;
    function FindLastKey(out aKey: TKey): Boolean;
    function FindFirstValue(out aValue: TValue): Boolean;
    function FindLastValue(out aValue: TValue): Boolean;
    function ExtractFirst(out aEntry: TEntry): Boolean;
    function ExtractLast(out aEntry: TEntry): Boolean;
    function RemoveFirst: Boolean;
    function RemoveLast: Boolean;
    property UpdateOnHit: Boolean read GetUpdateOnHit write SetUpdateOnHit;
  end;

  generic TGObjOrdHashMap<TKey, TValue> = class(specialize TGObjectOrdHashMap<TKey, TValue, TKey>);

  { TGLiteHashMapLP implements open addressing hashmap with linear probing;
      TKeyEqRel must provide:
        class function HashCode([const[ref]] aValue: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean; }
  generic TGLiteHashMapLP<TKey, TValue, TKeyEqRel> = record
  public
  type
    TEntry           = specialize TGMapEntry<TKey, TValue>;
    TEntryArray      = specialize TGArray<TEntry>;
    TKeyArray        = specialize TGArray<TKey>;
    TKeyTest         = specialize TGTest<TKey>;
    TOnKeyTest       = specialize TGOnTest<TKey>;
    TNestKeyTest     = specialize TGNestTest<TKey>;
    IKeyEnumerable   = specialize IGEnumerable<TKey>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;
    IKeyCollection   = specialize IGCollection<TKey>;

  private
  type
    PEntry         = ^TEntry;
    TTableLP       = specialize TGLiteHashTableLP<TKey, TEntry, TKeyEqRel>;
    PLiteHashMapLP = ^TGLiteHashMapLP;

  public
  type
    TKeyEnumerator = record
    private
      FEnum: TTableLP.TEnumerator;
      function  GetCurrent: TKey; inline;
    public
      constructor Create(constref aMap: TGLiteHashMapLP);
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TKey read GetCurrent;
    end;

    TValueEnumerator = record
    private
      FEnum: TTableLP.TEnumerator;
      function  GetCurrent: TValue; inline;
    public
      constructor Create(constref aMap: TGLiteHashMapLP);
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TValue read GetCurrent;
    end;

    TEntryEnumerator = record
    private
      FEnum: TTableLP.TEnumerator;
      function  GetCurrent: TEntry; inline;
    public
      constructor Create(constref aMap: TGLiteHashMapLP);
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TEntry read GetCurrent;
    end;

    TKeys = record
    private
      FMap: PLiteHashMapLP;
    public
      constructor Create(aMap: PLiteHashMapLP);
      function GetEnumerator: TKeyEnumerator; inline;
    end;

    TValues = record
    private
      FMap: PLiteHashMapLP;
    public
      constructor Create(aMap: PLiteHashMapLP);
      function GetEnumerator: TValueEnumerator; inline;
    end;

  private
    FTable: TTableLP;
    function  GetCount: SizeInt; inline;
    function  GetCapacity: SizeInt; inline;
    function  Find(constref aKey: TKey): PEntry; inline;
    function  FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean;
    function  GetExpandTreshold: SizeInt; inline;
    function  GetFillRatio: Single; inline;
    function  GetLoadFactor: Single; inline;
    function  GetValue(const aKey: TKey): TValue; inline;
    procedure SetLoadFactor(aValue: Single); inline;
    function  SetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean;
  public
    function  DefaultLoadFactor: Single; inline;
    function  MaxLoadFactor: Single; inline;
    function  MinLoadFactor: Single; inline;
    function  GetEnumerator: TEntryEnumerator;
    function  ToArray: TEntryArray;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Clear; inline;
    procedure EnsureCapacity(aValue: SizeInt); inline;
  { free unused memory if possible }
    procedure TrimToFit; inline;
  { returns True and aValue mapped to aKey if contains aKey, False otherwise }
    function  TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
  { returns Value mapped to aKey or aDefault }
    function  GetValueDef(constref aKey: TKey; constref aDefault: TValue = Default(TValue)): TValue; inline;
  { returns True and add TEntry(aKey, aValue) only if not contains aKey }
    function  Add(constref aKey: TKey; constref aValue: TValue): Boolean;
  { returns True and add e only if not contains e.Key }
    function  Add(constref e: TEntry): Boolean; inline;
    procedure AddOrSetValue(const aKey: TKey; const aValue: TValue);
  { returns True if e.Key added, False otherwise }
    function  AddOrSetValue(constref e: TEntry): Boolean; inline;
  { will add only entries which keys are absent in map }
    function  AddAll(const a: array of TEntry): SizeInt;
    function  AddAll(e: IEntryEnumerable): SizeInt;
    function  AddAll(constref aMap: TGLiteHashMapLP): SizeInt;
  { returns True and map aNewValue to aKey only if contains aKey, False otherwise }
    function  Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean; inline;
    function  Contains(constref aKey: TKey): Boolean; inline;
    function  NonContains(constref aKey: TKey): Boolean; inline;
    function  ContainsAny(const a: array of TKey): Boolean;
    function  ContainsAny(e: IKeyEnumerable): Boolean;
    function  ContainsAny(constref aMap: TGLiteHashMapLP): Boolean;
    function  ContainsAll(const a: array of TKey): Boolean;
    function  ContainsAll(e: IKeyEnumerable): Boolean;
    function  ContainsAll(constref aMap: TGLiteHashMapLP): Boolean;
  { returns True if entry removed }
    function  Remove(constref aKey: TKey): Boolean; inline;
    function  RemoveAll(const a: array of TKey): SizeInt;
    function  RemoveAll(e: IKeyEnumerable): SizeInt;
    function  RemoveAll(constref aMap: TGLiteHashMapLP): SizeInt;
    function  RemoveIf(aTest: TKeyTest): SizeInt;
    function  RemoveIf(aTest: TOnKeyTest): SizeInt;
    function  RemoveIf(aTest: TNestKeyTest): SizeInt;
    function  Extract(constref aKey: TKey; out v: TValue): Boolean;
    function  ExtractIf(aTest: TKeyTest): TEntryArray;
    function  ExtractIf(aTest: TOnKeyTest): TEntryArray;
    function  ExtractIf(aTest: TNestKeyTest): TEntryArray;
    procedure RetainAll(aCollection: IKeyCollection);
    function  Keys: TKeys;
    function  Values: TValues;
    property  Count: SizeInt read GetCount;
    property  Capacity: SizeInt read GetCapacity;
  { reading will raise ELGMapError if an aKey is not present in map }
    property  Items[const aKey: TKey]: TValue read GetValue write AddOrSetValue; default;
    property  LoadFactor: Single read GetLoadFactor write SetLoadFactor;
    property  FillRatio: Single read GetFillRatio;
  { The number of entries that can be written without rehashing }
    property  ExpandTreshold: SizeInt read GetExpandTreshold;
  end;

  { TGLiteChainHashMap implements node based hashmap with with load factor 1.0;
      TKeyEqRel must provide:
        class function HashCode([const[ref]] aValue: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean; }
  generic TGLiteChainHashMap<TKey, TValue, TKeyEqRel> = record
  public
  type
    TEntry           = specialize TGMapEntry<TKey, TValue>;
    TEntryArray      = specialize TGArray<TEntry>;
    TKeyArray        = specialize TGArray<TKey>;
    TKeyTest         = specialize TGTest<TKey>;
    TOnKeyTest       = specialize TGOnTest<TKey>;
    TNestKeyTest     = specialize TGNestTest<TKey>;
    IKeyEnumerable   = specialize IGEnumerable<TKey>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;
    IKeyCollection   = specialize IGCollection<TKey>;
    PHashMap         = ^TGLiteChainHashMap;

  private
  type
    PEntry = ^TEntry;
    TTable = specialize TGLiteChainHashTable<TKey, TEntry, TKeyEqRel>;
    PNode  = TTable.PNode;

  public
  type
    TKeyEnumerator = record
    private
      FList: PNode;
      FCurrent,
      FLast: SizeInt;
      function  GetCurrent: TKey; inline;
    public
      constructor Create(constref aMap: TGLiteChainHashMap);
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TKey read GetCurrent;
    end;

    TValueEnumerator = record
    private
      FList: PNode;
      FCurrent,
      FLast: SizeInt;
      function  GetCurrent: TValue; inline;
    public
      constructor Create(constref aMap: TGLiteChainHashMap);
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TValue read GetCurrent;
    end;

    TEntryEnumerator = record
    private
      FList: PNode;
      FCurrent,
      FLast: SizeInt;
      function  GetCurrent: TEntry; inline;
    public
      constructor Create(constref aMap: TGLiteChainHashMap);
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TEntry read GetCurrent;
    end;

    TKeys = record
    private
      FMap: PHashMap;
    public
      constructor Create(aMap: PHashMap);
      function GetEnumerator: TKeyEnumerator; inline;
    end;

    TValues = record
    private
      FMap: PHashMap;
    public
      constructor Create(aMap: PHashMap);
      function GetEnumerator: TValueEnumerator; inline;
    end;

  private
    FTable: TTable;
    function  GetCount: SizeInt; inline;
    function  GetCapacity: SizeInt; inline;
    function  Find(constref aKey: TKey): PEntry; inline;
    function  FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean;
    function  GetValue(const aKey: TKey): TValue; inline;
    function  SetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean;
  public
    function  GetEnumerator: TEntryEnumerator;
    function  ToArray: TEntryArray;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Clear; inline;
    procedure EnsureCapacity(aValue: SizeInt); inline;
  { free unused memory if possible }
    procedure TrimToFit; inline;
  { returns True and aValue mapped to aKey if contains aKey, False otherwise }
    function  TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
  { returns Value mapped to aKey or aDefault }
    function  GetValueDef(constref aKey: TKey; constref aDefault: TValue = Default(TValue)): TValue; inline;
  { returns True and add TEntry(aKey, aValue) only if not contains aKey }
    function  Add(constref aKey: TKey; constref aValue: TValue): Boolean;
  { returns True and add e only if not contains e.Key }
    function  Add(constref e: TEntry): Boolean; inline;
    procedure AddOrSetValue(const aKey: TKey; const aValue: TValue);
  { returns True if e.Key added, False otherwise }
    function  AddOrSetValue(constref e: TEntry): Boolean; inline;
  { will add only entries which keys are absent in map }
    function  AddAll(const a: array of TEntry): SizeInt;
    function  AddAll(e: IEntryEnumerable): SizeInt;
    function  AddAll(constref aMap: TGLiteChainHashMap): SizeInt;
  { returns True and map aNewValue to aKey only if contains aKey, False otherwise }
    function  Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean; inline;
    function  Contains(constref aKey: TKey): Boolean; inline;
    function  NonContains(constref aKey: TKey): Boolean; inline;
    function  ContainsAny(const a: array of TKey): Boolean;
    function  ContainsAny(e: IKeyEnumerable): Boolean;
    function  ContainsAny(constref aMap: TGLiteChainHashMap): Boolean;
    function  ContainsAll(const a: array of TKey): Boolean;
    function  ContainsAll(e: IKeyEnumerable): Boolean;
    function  ContainsAll(constref aMap: TGLiteChainHashMap): Boolean;
  { returns True if entry removed }
    function  Remove(constref aKey: TKey): Boolean; inline;
    function  RemoveAll(const a: array of TKey): SizeInt;
    function  RemoveAll(e: IKeyEnumerable): SizeInt;
    function  RemoveAll(constref aMap: TGLiteChainHashMap): SizeInt;
    function  RemoveIf(aTest: TKeyTest): SizeInt;
    function  RemoveIf(aTest: TOnKeyTest): SizeInt;
    function  RemoveIf(aTest: TNestKeyTest): SizeInt;
    function  Extract(constref aKey: TKey; out v: TValue): Boolean;
    function  ExtractIf(aTest: TKeyTest): TEntryArray;
    function  ExtractIf(aTest: TOnKeyTest): TEntryArray;
    function  ExtractIf(aTest: TNestKeyTest): TEntryArray;
    procedure RetainAll(aCollection: IKeyCollection);
    function  Keys: TKeys;
    function  Values: TValues;
    property  Count: SizeInt read GetCount;
    property  Capacity: SizeInt read GetCapacity;
  { reading will raise ELGMapError if an aKey is not present in map }
    property  Items[const aKey: TKey]: TValue read GetValue write AddOrSetValue; default;
  end;

  { TGThreadFGHashMap: fine-grained concurrent map attempt;
      functor TKeyEqRel(TKey equality relation) must provide:
        class function HashCode([const[ref]] aValue: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean; }
  generic TGThreadFGHashMap<TKey, TValue, TKeyEqRel> = class
  public
  type
    TEntry = specialize TGMapEntry<TKey, TValue>;

  private
  type
    PNode = ^TNode;
    TNode = record
      Hash: SizeInt;
      Key: TKey;
      Value: TValue;
      Next: PNode;
    end;

    TSlot = record
    strict private
      FState: SizeUInt;
      class operator Initialize(var aSlot: TSlot);
    public
      Head: PNode;
      procedure Lock; inline;
      procedure Unlock; inline;
    end;

  var
    FSlotList: array of TSlot;
    FCount: SizeInt;
    FLoadFactor: Single;
    FGlobLock: TMultiReadExclusiveWriteSynchronizer;
    function  NewNode(constref aKey: TKey; constref aValue: TValue; aHash: SizeInt): PNode;
    procedure FreeNode(aNode: PNode);
    function  GetCapacity: SizeInt;
    procedure ClearChainList;
    function  LockSlot(constref aKey: TKey; out aHash: SizeInt): SizeInt;
    function  Find(constref aKey: TKey; aSlotIdx: SizeInt; aHash: SizeInt): PNode;
    function  ExtractNode(constref aKey: TKey; aSlotIdx: SizeInt; aHash: SizeInt): PNode;
    procedure CheckNeedExpand;
    procedure Expand;
    function  GetValue(const aKey: TKey): TValue;
  public
  const
    MIN_LOAD_FACTOR: Single     = 0.5;
    MAX_LOAD_FACTOR: Single     = 8.0;
    DEFAULT_LOAD_FACTOR: Single = 1.0;

    constructor Create;
    constructor Create(aCapacity: SizeInt; aLoadFactor: Single = 1.0);
    destructor Destroy; override;
    function  Add(constref aKey: TKey; constref aValue: TValue): Boolean;
    function  Add(constref e: TEntry): Boolean; inline;
    procedure AddOrSetValue(const aKey: TKey; const aValue: TValue);
    procedure AddOrSetValue(constref e: TEntry); inline;
    function  TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
    function  GetValueDef(constref aKey: TKey; constref aDefault: TValue = Default(TValue)): TValue;
    function  Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean;
    function  Contains(constref aKey: TKey): Boolean;
    function  Extract(constref aKey: TKey; out aValue: TValue): Boolean;
    function  Remove(constref aKey: TKey): Boolean; virtual;
  { Count for estimate purpose only }
    property  Count: SizeInt read FCount;
    property  Capacity: SizeInt read GetCapacity;
    property  LoadFactor: Single read FLoadFactor;
  { reading returns Default(TValue) if an aKey is not present in map }
    property  Items[const aKey: TKey]: TValue read GetValue write AddOrSetValue; default;
  end;

  { TGThreadHashMapFG: fine-grained concurrent map attempt;
    it assumes that type TKey implements TKeyEqRel }
  generic TGThreadHashMapFG<TKey, TValue> = class(specialize TGThreadFGHashMap<TKey, TValue, TKey>);

implementation
{$B-}{$COPERATORS ON}

{ TGAbstractHashMap.TKeyEnumerable }

function TGAbstractHashMap.TKeyEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Key;
end;

constructor TGAbstractHashMap.TKeyEnumerable.Create(aMap: TAbstractHashMap);
begin
  inherited Create(aMap);
  FEnum := aMap.FTable.GetEnumerator;
end;

destructor TGAbstractHashMap.TKeyEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractHashMap.TKeyEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractHashMap.TKeyEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGAbstractHashMap.TValueEnumerable }

function TGAbstractHashMap.TValueEnumerable.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Value;
end;

constructor TGAbstractHashMap.TValueEnumerable.Create(aMap: TAbstractHashMap);
begin
  inherited Create(aMap);
  FEnum := aMap.FTable.GetEnumerator;
end;

destructor TGAbstractHashMap.TValueEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractHashMap.TValueEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractHashMap.TValueEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGAbstractHashMap.TEntryEnumerable }

function TGAbstractHashMap.TEntryEnumerable.GetCurrent: TEntry;
begin
  Result := FEnum.Current^;
end;

constructor TGAbstractHashMap.TEntryEnumerable.Create(aMap: TAbstractHashMap);
begin
  inherited Create(aMap);
  FEnum := aMap.FTable.GetEnumerator;
end;

destructor TGAbstractHashMap.TEntryEnumerable.Destroy;
begin
  FEnum.Free;
  inherited;
end;

function TGAbstractHashMap.TEntryEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGAbstractHashMap.TEntryEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGAbstractHashMap }

function TGAbstractHashMap.GetExpandTreshold: SizeInt;
begin
  Result := FTable.ExpandTreshold;
end;

function TGAbstractHashMap.GetCount: SizeInt;
begin
  Result := FTable.Count;
end;

function TGAbstractHashMap.GetCapacity: SizeInt;
begin
  Result := FTable.Capacity;
end;

function TGAbstractHashMap.GetFillRatio: Single;
begin
  Result := FTable.FillRatio;
end;

function TGAbstractHashMap.GetLoadFactor: Single;
begin
  Result := FTable.LoadFactor;
end;

procedure TGAbstractHashMap.SetLoadFactor(aValue: Single);
begin
  FTable.LoadFactor := aValue;
end;

function TGAbstractHashMap.Find(constref aKey: TKey): PEntry;
var
  sr: TSearchResult;
begin
  Result := FTable.Find(aKey, sr);
end;

function TGAbstractHashMap.FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean;
var
  sr: TSearchResult;
begin
  Result := FTable.FindOrAdd(aKey, p, sr);
  if not Result then
    p^.Key := aKey;
end;

function TGAbstractHashMap.DoExtract(constref aKey: TKey; out v: TValue): Boolean;
var
  p: PEntry;
  sr: TSearchResult;
begin
  p := FTable.Find(aKey, sr);
  Result := p <> nil;
  if Result then
    begin
      v := p^.Value;
      FTable.RemoveAt(sr);
    end;
end;

function TGAbstractHashMap.DoRemoveIf(aTest: TKeyTest): SizeInt;
begin
  Result := FTable.RemoveIf(aTest);
end;

function TGAbstractHashMap.DoRemoveIf(aTest: TOnKeyTest): SizeInt;
begin
  Result := FTable.RemoveIf(aTest);
end;

function TGAbstractHashMap.DoRemoveIf(aTest: TNestKeyTest): SizeInt;
begin
  Result := FTable.RemoveIf(aTest);
end;

function TGAbstractHashMap.DoExtractIf(aTest: TKeyTest): TEntryArray;
var
  eh: TExtractHelper;
begin
  eh.Init;
  FTable.RemoveIf(aTest, @eh.OnExtract);
  Result := eh.Final;
end;

function TGAbstractHashMap.DoExtractIf(aTest: TOnKeyTest): TEntryArray;
var
  e: TExtractHelper;
begin
  e.Init;
  FTable.RemoveIf(aTest, @e.OnExtract);
  Result := e.Final;
end;

function TGAbstractHashMap.DoExtractIf(aTest: TNestKeyTest): TEntryArray;
var
  e: TExtractHelper;
begin
  e.Init;
  FTable.RemoveIf(aTest, @e.OnExtract);
  Result := e.Final;
end;

procedure TGAbstractHashMap.DoClear;
begin
  FTable.Clear;
end;

procedure TGAbstractHashMap.DoEnsureCapacity(aValue: SizeInt);
begin
  FTable.EnsureCapacity(aValue);
end;

procedure TGAbstractHashMap.DoTrimToFit;
begin
  FTable.TrimToFit;
end;

function TGAbstractHashMap.GetKeys: IKeyEnumerable;
begin
  Result := TKeyEnumerable.Create(Self);
end;

function TGAbstractHashMap.GetValues: IValueEnumerable;
begin
  Result := TValueEnumerable.Create(Self);
end;

function TGAbstractHashMap.GetEntries: IEntryEnumerable;
begin
  Result := TEntryEnumerable.Create(Self);
end;

class function TGAbstractHashMap.DefaultLoadFactor: Single;
begin
  Result := GetTableClass.DefaultLoadFactor;
end;

class function TGAbstractHashMap.MaxLoadFactor: Single;
begin
  Result := GetTableClass.MaxLoadFactor;
end;

class function TGAbstractHashMap.MinLoadFactor: Single;
begin
  Result := GetTableClass.MinLoadFactor;
end;

constructor TGAbstractHashMap.Create;
begin
  FTable := GetTableClass.Create;
end;

constructor TGAbstractHashMap.Create(const a: array of TEntry);
begin
  FTable := GetTableClass.Create;
  DoAddAll(a);
end;

constructor TGAbstractHashMap.Create(e: IEntryEnumerable);
begin
  FTable := GetTableClass.Create;
  DoAddAll(e);
end;

constructor TGAbstractHashMap.Create(aCapacity: SizeInt);
begin
  FTable := GetTableClass.Create(aCapacity);
end;

constructor TGAbstractHashMap.Create(aCapacity: SizeInt; const a: array of TEntry);
begin
  FTable := GetTableClass.Create(aCapacity);
  DoAddAll(a);
end;

constructor TGAbstractHashMap.Create(aCapacity: SizeInt; e: IEntryEnumerable);
begin
  FTable := GetTableClass.Create(aCapacity);
  DoAddAll(e);
end;

constructor TGAbstractHashMap.Create(aLoadFactor: Double);
begin
  FTable := GetTableClass.Create(aLoadFactor);
end;

constructor TGAbstractHashMap.Create(aLoadFactor: Single; const a: array of TEntry);
begin
  FTable := GetTableClass.Create(aLoadFactor);
  DoAddAll(a);
end;

constructor TGAbstractHashMap.Create(aLoadFactor: Single; e: IEntryEnumerable);
begin
  FTable := GetTableClass.Create(aLoadFactor);
  DoAddAll(e);
end;

constructor TGAbstractHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single);
begin
  FTable := GetTableClass.Create(aCapacity, aLoadFactor);
end;

constructor TGAbstractHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single; const a: array of TEntry);
begin
  FTable := GetTableClass.Create(aCapacity, aLoadFactor);
  DoAddAll(a);
end;

constructor TGAbstractHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single; e: IEntryEnumerable);
begin
  FTable := GetTableClass.Create(aCapacity, aLoadFactor);
  DoAddAll(e);
end;

constructor TGAbstractHashMap.CreateCopy(aMap: TAbstractHashMap);
begin
  inherited Create;
  if aMap.GetClass = GetClass then
    FTable := aMap.FTable.Clone
  else
    begin
      FTable := GetTableClass.Create(aMap.Count);
      DoAddAll(aMap.Entries);
    end;
end;

destructor TGAbstractHashMap.Destroy;
begin
  DoClear;
  FTable.Free;
  inherited;
end;

function TGAbstractHashMap.Clone: TAbstractHashMap;
begin
  Result := GetClass.CreateCopy(Self);
end;

{ TGBaseHashMapLP }

class function TGBaseHashMapLP.GetTableClass: THashTableClass;
begin
  Result := specialize TGOpenAddrLP<TKey, TEntry, TKeyEqRel>;
end;

class function TGBaseHashMapLP.GetClass: THashMapClass;
begin
  Result := TGBaseHashMapLP;
end;

{ TGBaseHashMapLPT }

function TGBaseHashMapLPT.GetTombstonesCount: SizeInt;
begin
  Result := TTableLPT(FTable).TombstonesCount;
end;

class function TGBaseHashMapLPT.GetTableClass: THashTableClass;
begin
  Result := TTableLPT;
end;

class function TGBaseHashMapLPT.GetClass: THashMapClass;
begin
  Result := TGBaseHashMapLPT;
end;

procedure TGBaseHashMapLPT.ClearTombstones;
begin
  TTableLPT(FTable).ClearTombstones;
end;

{ TGBaseHashMapQP }

function TGBaseHashMapQP.GetTombstonesCount: SizeInt;
begin
  Result := TTableQP(FTable).TombstonesCount;
end;

class function TGBaseHashMapQP.GetTableClass: THashTableClass;
begin
  Result := TTableQP;
end;

class function TGBaseHashMapQP.GetClass: THashMapClass;
begin
  Result := TGBaseHashMapQP;
end;

procedure TGBaseHashMapQP.ClearTombstones;
begin
  TTableQP(FTable).ClearTombstones;
end;

{ TGBaseChainHashMap }

class function TGBaseChainHashMap.GetTableClass: THashTableClass;
begin
  Result := specialize TGChainHashTable<TKey, TEntry, TKeyEqRel>;
end;

class function TGBaseChainHashMap.GetClass: THashMapClass;
begin
  Result := TGBaseChainHashMap;
end;

{ TGChainHashMap }

function TGChainHashMap.Clone: TGChainHashMap;
begin
  Result := TGChainHashMap(inherited Clone);
end;

{ TGBaseOrderedHashMap }

function TGBaseOrderedHashMap.GetUpdateOnHit: Boolean;
begin
  Result := TOrdTable(FTable).UpdateOnHit;
end;

procedure TGBaseOrderedHashMap.SetUpdateOnHit(aValue: Boolean);
begin
  TOrdTable(FTable).UpdateOnHit := aValue;
end;

class function TGBaseOrderedHashMap.GetTableClass: THashTableClass;
begin
  Result := TOrdTable;
end;

class function TGBaseOrderedHashMap.GetClass: THashMapClass;
begin
  Result := TGBaseOrderedHashMap;
end;

function TGBaseOrderedHashMap.FindFirst(out aEntry: TEntry): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aEntry := TOrdTable(FTable).Head^.Data;
      exit(True);
    end;
  Result := False;
end;

function TGBaseOrderedHashMap.FindLast(out aEntry: TEntry): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aEntry := TOrdTable(FTable).Tail^.Data;
      exit(True);
    end;
  Result := False;
end;

function TGBaseOrderedHashMap.FindFirstKey(out aKey: TKey): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aKey := TOrdTable(FTable).Head^.Data.Key;
      exit(True);
    end;
  Result := False;
end;

function TGBaseOrderedHashMap.FindLastKey(out aKey: TKey): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aKey := TOrdTable(FTable).Tail^.Data.Key;
      exit(True);
    end;
  Result := False;
end;

function TGBaseOrderedHashMap.FindFirstValue(out aValue: TValue): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aValue := TOrdTable(FTable).Head^.Data.Value;
      exit(True);
    end;
  Result := False;
end;

function TGBaseOrderedHashMap.FindLastValue(out aValue: TValue): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aValue := TOrdTable(FTable).Tail^.Data.Value;
      exit(True);
    end;
  Result := False;
end;

function TGBaseOrderedHashMap.ExtractFirst(out aEntry: TEntry): Boolean;
var
  v: TValue;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  aEntry := TOrdTable(FTable).Head^.Data;
  Result := DoExtract(aEntry.Key, v);
end;

function TGBaseOrderedHashMap.ExtractLast(out aEntry: TEntry): Boolean;
var
  v: TValue;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  aEntry := TOrdTable(FTable).Tail^.Data;
  Result := DoExtract(aEntry.Key, v);
end;

function TGBaseOrderedHashMap.RemoveFirst: Boolean;
var
  k: TKey;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  k := TOrdTable(FTable).Head^.Data.Key;
  Result := DoRemove(k);
end;

function TGBaseOrderedHashMap.RemoveLast: Boolean;
var
  k: TKey;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  k := TOrdTable(FTable).Tail^.Data.Key;
  Result := DoRemove(k);
end;

{ TGOrderedHashMap }

function TGOrderedHashMap.Clone: TGOrderedHashMap;
begin
  Result := TGOrderedHashMap(inherited Clone);
end;

{ TGCustomObjectHashMap }

procedure TGCustomObjectHashMap.EntryRemoving(p: PEntry);
begin
  if OwnsKeys then
    TObject(p^.Key).Free;
  if OwnsValues then
    TObject(p^.Value).Free;
end;

procedure TGCustomObjectHashMap.SetOwnership(aOwns: TMapObjOwnership);
begin
  OwnsKeys := moOwnsKeys in aOwns;
  OwnsValues := moOwnsValues in aOwns;
end;

function TGCustomObjectHashMap.DoRemove(constref aKey: TKey): Boolean;
var
  v: TValue;
begin
  Result := DoExtract(aKey, v);
  if Result then
    begin
      if OwnsKeys then
        TObject(aKey).Free;
      if OwnsValues then
        TObject(v).Free;
    end;
end;

function TGCustomObjectHashMap.DoRemoveIf(aTest: TKeyTest): SizeInt;
begin
  Result := FTable.RemoveIf(aTest, @EntryRemoving);
end;

function TGCustomObjectHashMap.DoRemoveIf(aTest: TOnKeyTest): SizeInt;
begin
  Result := FTable.RemoveIf(aTest, @EntryRemoving);
end;

function TGCustomObjectHashMap.DoRemoveIf(aTest: TNestKeyTest): SizeInt;
begin
  Result := FTable.RemoveIf(aTest, @EntryRemoving);
end;

procedure TGCustomObjectHashMap.DoClear;
var
  p: PEntry;
begin
  if OwnsKeys or OwnsValues then
    for p in FTable do
      begin
        if OwnsKeys then
          TObject(p^.Key).Free;
        if OwnsValues then
          TObject(p^.Value).Free;
      end;
  inherited;
end;

function TGCustomObjectHashMap.DoSetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    begin
      if OwnsValues and not TObject.Equal(TObject(p^.Value), TObject(aNewValue)) then
        TObject(p^.Value).Free;
      p^.Value := aNewValue;
    end;
end;

function TGCustomObjectHashMap.DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if not Result then
    begin
      if OwnsValues and not TObject.Equal(TObject(p^.Value), TObject(aValue)) then
        TObject(p^.Value).Free;
    end;
  p^.Value := aValue;
end;

constructor TGCustomObjectHashMap.Create(aOwns: TMapObjOwnership);
begin
  inherited Create;
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(constref a: array of TEntry; aOwns: TMapObjOwnership);
begin
  inherited Create(a);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(e: IEntryEnumerable; aOwns: TMapObjOwnership);
begin
  inherited Create(e);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aCapacity: SizeInt; aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aCapacity: SizeInt; const a: array of TEntry;
  aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, a);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aCapacity: SizeInt; e: IEntryEnumerable; aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, e);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aLoadFactor: Single; aOwns: TMapObjOwnership);
begin
  inherited Create(aLoadFactor);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aLoadFactor: Single; const a: array of TEntry;
  aOwns: TMapObjOwnership);
begin
  inherited Create(aLoadFactor, a);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aLoadFactor: Single; e: IEntryEnumerable; aOwns: TMapObjOwnership);
begin
  inherited Create(aLoadFactor, e);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single; aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, aLoadFactor);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single; const a: array of TEntry;
  aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, aLoadFactor, a);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single; e: IEntryEnumerable;
  aOwns: TMapObjOwnership);
begin
  inherited Create(aCapacity, aLoadFactor, e);
  SetOwnership(aOwns);
end;

constructor TGCustomObjectHashMap.CreateCopy(aMap: TGCustomObjectHashMap);
begin
  inherited CreateCopy(aMap);
  OwnsKeys := aMap.OwnsKeys;
  OwnsValues := aMap.OwnsValues;
end;

{ TGObjectHashMapLP }

class function TGObjectHashMapLP.GetTableClass: THashTableClass;
begin
  Result := specialize TGOpenAddrLP<TKey, TEntry, TKeyEqRel>;
end;

class function TGObjectHashMapLP.GetClass: TObjectHashMapClass;
begin
  Result := TGObjectHashMapLP;
end;

function TGObjectHashMapLP.Clone: TGObjectHashMapLP;
begin
  Result := TGObjectHashMapLP.CreateCopy(Self);
end;

{ TGObjectHashMapLPT }

function TGObjectHashMapLPT.GetTombstonesCount: SizeInt;
begin
  Result := TTableLPT(FTable).TombstonesCount;
end;

class function TGObjectHashMapLPT.GetTableClass: THashTableClass;
begin
  Result := TTableLPT;
end;

class function TGObjectHashMapLPT.GetClass: TObjectHashMapClass;
begin
  Result := TGObjectHashMapLPT;
end;

function TGObjectHashMapLPT.Clone: TGObjectHashMapLPT;
begin
  Result := TGObjectHashMapLPT.CreateCopy(Self);
end;

procedure TGObjectHashMapLPT.ClearTombstones;
begin
  TTableLPT(FTable).ClearTombstones;
end;

{ TGObjectHashMapQP }

function TGObjectHashMapQP.GetTombstonesCount: SizeInt;
begin
  Result := TTableQP(FTable).TombstonesCount;
end;

class function TGObjectHashMapQP.GetTableClass: THashTableClass;
begin
  Result := TTableQP;
end;

class function TGObjectHashMapQP.GetClass: TObjectHashMapClass;
begin
  Result := TGObjectHashMapQP;
end;

function TGObjectHashMapQP.Clone: TGObjectHashMapQP;
begin
  Result := TGObjectHashMapQP.CreateCopy(Self);
end;

procedure TGObjectHashMapQP.ClearTombstones;
begin
  TTableQP(FTable).ClearTombstones;
end;

{ TGObjectChainHashMap }

class function TGObjectChainHashMap.GetTableClass: THashTableClass;
begin
  Result := specialize TGChainHashTable<TKey, TEntry, TKeyEqRel>;
end;

class function TGObjectChainHashMap.GetClass: TObjectHashMapClass;
begin
  Result := TGObjectChainHashMap;
end;

function TGObjectChainHashMap.Clone: TGObjectChainHashMap;
begin
  Result := TGObjectChainHashMap.CreateCopy(Self);
end;

{ TGObjectOrdHashMap }

function TGObjectOrdHashMap.GetUpdateOnHit: Boolean;
begin
  Result := TOrdTable(FTable).UpdateOnHit;
end;

procedure TGObjectOrdHashMap.SetUpdateOnHit(aValue: Boolean);
begin
  TOrdTable(FTable).UpdateOnHit := aValue;
end;

class function TGObjectOrdHashMap.GetTableClass: THashTableClass;
begin
  Result := TOrdTable;
end;

class function TGObjectOrdHashMap.GetClass: TObjectHashMapClass;
begin
  Result := TGObjectOrdHashMap;
end;

function TGObjectOrdHashMap.Clone: TGObjectOrdHashMap;
begin
  Result := TGObjectOrdHashMap.CreateCopy(Self);
end;

function TGObjectOrdHashMap.FindFirst(out aEntry: TEntry): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aEntry := TOrdTable(FTable).Head^.Data;
      exit(True);
    end;
  Result := False;
end;

function TGObjectOrdHashMap.FindLast(out aEntry: TEntry): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aEntry := TOrdTable(FTable).Tail^.Data;
      exit(True);
    end;
  Result := False;
end;

function TGObjectOrdHashMap.FindFirstKey(out aKey: TKey): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aKey := TOrdTable(FTable).Head^.Data.Key;
      exit(True);
    end;
  Result := False;
end;

function TGObjectOrdHashMap.FindLastKey(out aKey: TKey): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aKey := TOrdTable(FTable).Tail^.Data.Key;
      exit(True);
    end;
  Result := False;
end;

function TGObjectOrdHashMap.FindFirstValue(out aValue: TValue): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aValue := TOrdTable(FTable).Head^.Data.Value;
      exit(True);
    end;
  Result := False;
end;

function TGObjectOrdHashMap.FindLastValue(out aValue: TValue): Boolean;
begin
  if FTable.Count > 0 then
    begin
      aValue := TOrdTable(FTable).Tail^.Data.Value;
      exit(True);
    end;
  Result := False;
end;

function TGObjectOrdHashMap.ExtractFirst(out aEntry: TEntry): Boolean;
var
  v: TValue;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  aEntry := TOrdTable(FTable).Head^.Data;
  Result := DoExtract(aEntry.Key, v);
end;

function TGObjectOrdHashMap.ExtractLast(out aEntry: TEntry): Boolean;
var
  v: TValue;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  aEntry := TOrdTable(FTable).Tail^.Data;
  Result := DoExtract(aEntry.Key, v);
end;

function TGObjectOrdHashMap.RemoveFirst: Boolean;
var
  k: TKey;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  k := TOrdTable(FTable).Head^.Data.Key;
  Result := DoRemove(k);
end;

function TGObjectOrdHashMap.RemoveLast: Boolean;
var
  k: TKey;
begin
  CheckInIteration;
  if FTable.Count < 1 then
    exit(False);
  k := TOrdTable(FTable).Tail^.Data.Key;
  Result := DoRemove(k);
end;

{ TGLiteHashMapLP.TKeyEnumerator }

function TGLiteHashMapLP.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Key;
end;

constructor TGLiteHashMapLP.TKeyEnumerator.Create(constref aMap: TGLiteHashMapLP);
begin
  FEnum := aMap.FTable.GetEnumerator;
end;

function TGLiteHashMapLP.TKeyEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGLiteHashMapLP.TKeyEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGLiteHashMapLP.TValueEnumerator }

function TGLiteHashMapLP.TValueEnumerator.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Value;
end;

constructor TGLiteHashMapLP.TValueEnumerator.Create(constref aMap: TGLiteHashMapLP);
begin
  FEnum := aMap.FTable.GetEnumerator;
end;

function TGLiteHashMapLP.TValueEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGLiteHashMapLP.TValueEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGLiteHashMapLP.TEntryEnumerator }

function TGLiteHashMapLP.TEntryEnumerator.GetCurrent: TEntry;
begin
  Result := FEnum.Current^;
end;

constructor TGLiteHashMapLP.TEntryEnumerator.Create(constref aMap: TGLiteHashMapLP);
begin
  FEnum := aMap.FTable.GetEnumerator;
end;

function TGLiteHashMapLP.TEntryEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGLiteHashMapLP.TEntryEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGLiteHashMapLP.TKeys }

constructor TGLiteHashMapLP.TKeys.Create(aMap: PLiteHashMapLP);
begin
  FMap := aMap;
end;

function TGLiteHashMapLP.TKeys.GetEnumerator: TKeyEnumerator;
begin
  Result := TKeyEnumerator.Create(FMap^);
end;

{ TGLiteHashMapLP.TValues }

constructor TGLiteHashMapLP.TValues.Create(aMap: PLiteHashMapLP);
begin
  FMap := aMap;
end;

function TGLiteHashMapLP.TValues.GetEnumerator: TValueEnumerator;
begin
  Result := TValueEnumerator.Create(FMap^);
end;

{ TGLiteHashMapLP }

function TGLiteHashMapLP.GetCount: SizeInt;
begin
  Result := FTable.Count;
end;

function TGLiteHashMapLP.GetCapacity: SizeInt;
begin
  Result := FTable.Capacity;
end;

function TGLiteHashMapLP.Find(constref aKey: TKey): PEntry;
var
  Pos: SizeInt;
begin
  Result := FTable.Find(aKey, Pos);
end;

function TGLiteHashMapLP.FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean;
var
  Pos: SizeInt;
begin
  Result := FTable.FindOrAdd(aKey, p, Pos);
  if not Result then
    p^.Key := aKey;
end;

function TGLiteHashMapLP.GetExpandTreshold: SizeInt;
begin
  Result := FTable.ExpandTreshold;
end;

function TGLiteHashMapLP.GetFillRatio: Single;
begin
  Result := FTable.FillRatio;
end;

function TGLiteHashMapLP.GetLoadFactor: Single;
begin
  Result := FTable.LoadFactor;
end;

function TGLiteHashMapLP.GetValue(const aKey: TKey): TValue;
begin
  if not TryGetValue(aKey, Result) then
    raise ELGMapError.Create(SEKeyNotFound);
end;

procedure TGLiteHashMapLP.SetLoadFactor(aValue: Single);
begin
  FTable.LoadFactor := aValue;
end;

function TGLiteHashMapLP.SetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    p^.Value := aNewValue;
end;

function TGLiteHashMapLP.DefaultLoadFactor: Single;
begin
  Result := FTable.DEFAULT_LOAD_FACTOR;
end;

function TGLiteHashMapLP.MaxLoadFactor: Single;
begin
  Result := FTable.MAX_LOAD_FACTOR;
end;

function TGLiteHashMapLP.MinLoadFactor: Single;
begin
  Result := FTable.MIN_LOAD_FACTOR;
end;

function TGLiteHashMapLP.GetEnumerator: TEntryEnumerator;
begin
  Result := TEntryEnumerator.Create(Self);
end;

function TGLiteHashMapLP.ToArray: TEntryArray;
var
  I: SizeInt = 0;
  p: PEntry;
begin
  System.SetLength(Result, Count);
  for p in FTable do
    begin
      Result[I] := p^;
      Inc(I);
    end;
end;

function TGLiteHashMapLP.IsEmpty: Boolean;
begin
  Result := FTable.Count = 0;
end;

function TGLiteHashMapLP.NonEmpty: Boolean;
begin
  Result := FTable.Count <> 0;
end;

procedure TGLiteHashMapLP.Clear;
begin
  FTable.Clear;
end;

procedure TGLiteHashMapLP.EnsureCapacity(aValue: SizeInt);
begin
  FTable.EnsureCapacity(aValue);
end;

procedure TGLiteHashMapLP.TrimToFit;
begin
  FTable.TrimToFit;
end;

function TGLiteHashMapLP.TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    aValue := p^.Value;
end;

function TGLiteHashMapLP.GetValueDef(constref aKey: TKey; constref aDefault: TValue): TValue;
begin
  if not TryGetValue(aKey, Result) then
    Result := aDefault;
end;

function TGLiteHashMapLP.Add(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if Result then
    p^.Value := aValue;
end;

function TGLiteHashMapLP.Add(constref e: TEntry): Boolean;
begin
  Result := Add(e.Key, e.Value);
end;

procedure TGLiteHashMapLP.AddOrSetValue(const aKey: TKey; const aValue: TValue);
var
  p: PEntry;
begin
  FindOrAdd(aKey, p);
  p^.Value := aValue;
end;

function TGLiteHashMapLP.AddOrSetValue(constref e: TEntry): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(e.Key, p);
  p^.Value := e.Value;
end;

function TGLiteHashMapLP.AddAll(const a: array of TEntry): SizeInt;
var
  e: TEntry;
begin
  Result := 0;
  for e in a do
    Result += Ord(Add(e));
end;

function TGLiteHashMapLP.AddAll(e: IEntryEnumerable): SizeInt;
var
  Entry: TEntry;
begin
  Result := 0;
  for Entry in e do
    Result += Ord(Add(Entry));
end;

function TGLiteHashMapLP.AddAll(constref aMap: TGLiteHashMapLP): SizeInt;
var
  e: TEntry;
begin
  if @AMap = @Self then
    exit(0);
  Result := 0;
  for e in aMap do
    Result += Ord(Add(e));
end;

function TGLiteHashMapLP.Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean;
begin
  Result := SetValue(aKey, aNewValue);
end;

function TGLiteHashMapLP.Contains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) <> nil;
end;

function TGLiteHashMapLP.NonContains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) = nil;
end;

function TGLiteHashMapLP.ContainsAny(const a: array of TKey): Boolean;
var
  k: TKey;
begin
  for k in a do
    if Contains(k) then
      exit(True);
  Result := False;
end;

function TGLiteHashMapLP.ContainsAny(e: IKeyEnumerable): Boolean;
var
  k: TKey;
begin
  for k in e do
    if Contains(k) then
      exit(True);
  Result := False;
end;

function TGLiteHashMapLP.ContainsAny(constref aMap: TGLiteHashMapLP): Boolean;
var
  k: TKey;
begin
  if @aMap = @Self then
    exit(True);
  for k in aMap.Keys do
    if Contains(k) then
      exit(True);
  Result := False;
end;

function TGLiteHashMapLP.ContainsAll(const a: array of TKey): Boolean;
var
  k: TKey;
begin
  for k in a do
    if not Contains(k) then
      exit(False);
  Result := True;
end;

function TGLiteHashMapLP.ContainsAll(e: IKeyEnumerable): Boolean;
var
  k: TKey;
begin
  for k in e do
    if not Contains(k) then
      exit(False);
  Result := True;
end;

function TGLiteHashMapLP.ContainsAll(constref aMap: TGLiteHashMapLP): Boolean;
var
  k: TKey;
begin
  if @aMap = @Self then
    exit(True);
  for k in aMap.Keys do
    if not Contains(k) then
      exit(False);
  Result := True;
end;

function TGLiteHashMapLP.Remove(constref aKey: TKey): Boolean;
begin
  Result := FTable.Remove(aKey);
end;

function TGLiteHashMapLP.RemoveAll(const a: array of TKey): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in a do
    Result += Ord(Remove(k));
end;

function TGLiteHashMapLP.RemoveAll(e: IKeyEnumerable): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in e do
    Result += Ord(Remove(k));
end;

function TGLiteHashMapLP.RemoveAll(constref aMap: TGLiteHashMapLP): SizeInt;
var
  k: TKey;
begin
  if @aMap <> @Self then
    begin
      Result := 0;
      for k in aMap.Keys do
        Result += Ord(Remove(k));
    end
  else
    begin
      Result := Count;
      Clear;
    end;
end;

function TGLiteHashMapLP.RemoveIf(aTest: TKeyTest): SizeInt;
begin
  Result := 0;
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      if aTest(Current^.Key) then
        begin
          RemoveCurrent;
          Inc(Result);
        end;
end;

function TGLiteHashMapLP.RemoveIf(aTest: TOnKeyTest): SizeInt;
begin
  Result := 0;
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      if aTest(Current^.Key) then
        begin
          RemoveCurrent;
          Inc(Result);
        end;
end;

function TGLiteHashMapLP.RemoveIf(aTest: TNestKeyTest): SizeInt;
begin
  Result := 0;
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      if aTest(Current^.Key) then
        begin
          RemoveCurrent;
          Inc(Result);
        end;
end;

function TGLiteHashMapLP.Extract(constref aKey: TKey; out v: TValue): Boolean;
var
  p: PEntry;
  Pos: SizeInt;
begin
  p := FTable.Find(aKey, Pos);
  Result := p <> nil;
  if Result then
    begin
      v := p^.Value;
      FTable.RemoveAt(Pos);
    end;
end;

function TGLiteHashMapLP.ExtractIf(aTest: TKeyTest): TEntryArray;
var
  I: SizeInt = 0;
  e: TEntry;
begin
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      begin
        e := Current^;
        if aTest(e.Key) then
          begin
            RemoveCurrent;
            if I = System.Length(Result) then
              System.SetLength(Result, I shl 1);
            Result[I] := e;
            Inc(I);
          end;
      end;
  System.SetLength(Result, I);
end;

function TGLiteHashMapLP.ExtractIf(aTest: TOnKeyTest): TEntryArray;
var
  I: SizeInt = 0;
  e: TEntry;
begin
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      begin
        e := Current^;
        if aTest(e.Key) then
          begin
            RemoveCurrent;
            if I = System.Length(Result) then
              System.SetLength(Result, I shl 1);
            Result[I] := e;
            Inc(I);
          end;
      end;
  System.SetLength(Result, I);
end;

function TGLiteHashMapLP.ExtractIf(aTest: TNestKeyTest): TEntryArray;
var
  I: SizeInt = 0;
  e: TEntry;
begin
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      begin
        e := Current^;
        if aTest(e.Key) then
          begin
            RemoveCurrent;
            if I = System.Length(Result) then
              System.SetLength(Result, I shl 1);
            Result[I] := e;
            Inc(I);
          end;
      end;
  System.SetLength(Result, I);
end;

procedure TGLiteHashMapLP.RetainAll(aCollection: IKeyCollection);
begin
  with FTable.GetRemovableEnumerator do
    while MoveNext do
      if aCollection.NonContains(Current^.Key) then
        RemoveCurrent;
end;

function TGLiteHashMapLP.Keys: TKeys;
begin
  Result := TKeys.Create(@Self);
end;

function TGLiteHashMapLP.Values: TValues;
begin
  Result := TValues.Create(@Self);
end;

{ TGLiteChainHashMap.TKeyEnumerator }

function TGLiteChainHashMap.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := FList[FCurrent].Data.Key;
end;

constructor TGLiteChainHashMap.TKeyEnumerator.Create(constref aMap: TGLiteChainHashMap);
begin
  FList := aMap.FTable.NodeList;
  FLast := Pred(aMap.FTable.Count);
  FCurrent := NULL_INDEX;
end;

function TGLiteChainHashMap.TKeyEnumerator.MoveNext: Boolean;
begin
  Result := FCurrent < FLast;
  FCurrent += Ord(Result);
end;

procedure TGLiteChainHashMap.TKeyEnumerator.Reset;
begin
  FCurrent := NULL_INDEX;
end;

{ TGLiteChainHashMap.TValueEnumerator }

function TGLiteChainHashMap.TValueEnumerator.GetCurrent: TValue;
begin
  Result := FList[FCurrent].Data.Value;
end;

constructor TGLiteChainHashMap.TValueEnumerator.Create(constref aMap: TGLiteChainHashMap);
begin
  FList := aMap.FTable.NodeList;
  FLast := Pred(aMap.FTable.Count);
  FCurrent := NULL_INDEX;
end;

function TGLiteChainHashMap.TValueEnumerator.MoveNext: Boolean;
begin
  Result := FCurrent < FLast;
  FCurrent += Ord(Result);
end;

procedure TGLiteChainHashMap.TValueEnumerator.Reset;
begin
  FCurrent := NULL_INDEX;
end;

{ TGLiteChainHashMap.TEntryEnumerator }

function TGLiteChainHashMap.TEntryEnumerator.GetCurrent: TEntry;
begin
  Result := FList[FCurrent].Data;
end;

constructor TGLiteChainHashMap.TEntryEnumerator.Create(constref aMap: TGLiteChainHashMap);
begin
  FList := aMap.FTable.NodeList;
  FLast := Pred(aMap.FTable.Count);
  FCurrent := NULL_INDEX;
end;

function TGLiteChainHashMap.TEntryEnumerator.MoveNext: Boolean;
begin
  Result := FCurrent < FLast;
  FCurrent += Ord(Result);
end;

procedure TGLiteChainHashMap.TEntryEnumerator.Reset;
begin
  FCurrent := NULL_INDEX;
end;

{ TGLiteChainHashMap.TKeys }

constructor TGLiteChainHashMap.TKeys.Create(aMap: PHashMap);
begin
  FMap := aMap;
end;

function TGLiteChainHashMap.TKeys.GetEnumerator: TKeyEnumerator;
begin
  Result := TKeyEnumerator.Create(FMap^);
end;

{ TGLiteChainHashMap.TValues }

constructor TGLiteChainHashMap.TValues.Create(aMap: PHashMap);
begin
  FMap := aMap;
end;

function TGLiteChainHashMap.TValues.GetEnumerator: TValueEnumerator;
begin
  Result := TValueEnumerator.Create(FMap^);
end;

{ TGLiteChainHashMap }

function TGLiteChainHashMap.GetCount: SizeInt;
begin
  Result := FTable.Count;
end;

function TGLiteChainHashMap.GetCapacity: SizeInt;
begin
  Result := FTable.Capacity;
end;

function TGLiteChainHashMap.Find(constref aKey: TKey): PEntry;
var
  Pos: SizeInt;
begin
  Result := FTable.Find(aKey, Pos);
end;

function TGLiteChainHashMap.FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean;
var
  Pos: SizeInt;
begin
  Result := FTable.FindOrAdd(aKey, p, Pos);
  if not Result then
    p^.Key := aKey;
end;

function TGLiteChainHashMap.GetValue(const aKey: TKey): TValue;
begin
  if not TryGetValue(aKey, Result) then
    raise ELGMapError.Create(SEKeyNotFound);
end;

function TGLiteChainHashMap.SetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    p^.Value := aNewValue;
end;

function TGLiteChainHashMap.GetEnumerator: TEntryEnumerator;
begin
  Result := TEntryEnumerator.Create(Self);
end;

function TGLiteChainHashMap.ToArray: TEntryArray;
var
  I, J: SizeInt;
  List: PNode;
begin
  System.SetLength(Result, Count);
  List := FTable.NodeList;
  J := 0;
  for I := 0 to Pred(Count) do
    begin
      Result[J] := List[I].Data;
      Inc(J);
    end;
end;

function TGLiteChainHashMap.IsEmpty: Boolean;
begin
  Result := FTable.Count = 0;
end;

function TGLiteChainHashMap.NonEmpty: Boolean;
begin
  Result := FTable.Count <> 0;
end;

procedure TGLiteChainHashMap.Clear;
begin
  FTable.Clear;
end;

procedure TGLiteChainHashMap.EnsureCapacity(aValue: SizeInt);
begin
  FTable.EnsureCapacity(aValue);
end;

procedure TGLiteChainHashMap.TrimToFit;
begin
  FTable.TrimToFit;
end;

function TGLiteChainHashMap.TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    aValue := p^.Value;
end;

function TGLiteChainHashMap.GetValueDef(constref aKey: TKey; constref aDefault: TValue): TValue;
begin
  if not TryGetValue(aKey, Result) then
    Result := aDefault;
end;

function TGLiteChainHashMap.Add(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if Result then
    p^.Value := aValue;
end;

function TGLiteChainHashMap.Add(constref e: TEntry): Boolean;
begin
  Result := Add(e.Key, e.Value);
end;

procedure TGLiteChainHashMap.AddOrSetValue(const aKey: TKey; const aValue: TValue);
var
  p: PEntry;
begin
  FindOrAdd(aKey, p);
  p^.Value := aValue;
end;

function TGLiteChainHashMap.AddOrSetValue(constref e: TEntry): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(e.Key, p);
  p^.Value := e.Value;
end;

function TGLiteChainHashMap.AddAll(const a: array of TEntry): SizeInt;
var
  e: TEntry;
begin
  Result := 0;
  for e in a do
    Result += Ord(Add(e));
end;

function TGLiteChainHashMap.AddAll(e: IEntryEnumerable): SizeInt;
var
  Entry: TEntry;
begin
  Result := 0;
  for Entry in e do
    Result += Ord(Add(Entry));
end;

function TGLiteChainHashMap.AddAll(constref aMap: TGLiteChainHashMap): SizeInt;
var
  e: TEntry;
begin
  if @AMap = @Self then
    exit(0);
  Result := 0;
  for e in aMap do
    Result += Ord(Add(e));
end;

function TGLiteChainHashMap.Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean;
begin
  Result := SetValue(aKey, aNewValue);
end;

function TGLiteChainHashMap.Contains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) <> nil;
end;

function TGLiteChainHashMap.NonContains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) = nil;
end;

function TGLiteChainHashMap.ContainsAny(const a: array of TKey): Boolean;
var
  k: TKey;
begin
  for k in a do
    if Contains(k) then
      exit(True);
  Result := False;
end;

function TGLiteChainHashMap.ContainsAny(e: IKeyEnumerable): Boolean;
var
  k: TKey;
begin
  for k in e do
    if Contains(k) then
      exit(True);
  Result := False;
end;

function TGLiteChainHashMap.ContainsAny(constref aMap: TGLiteChainHashMap): Boolean;
var
  k: TKey;
begin
  if @aMap = @Self then
    exit(True);
  for k in aMap.Keys do
    if Contains(k) then
      exit(True);
  Result := False;
end;

function TGLiteChainHashMap.ContainsAll(const a: array of TKey): Boolean;
var
  k: TKey;
begin
  for k in a do
    if not Contains(k) then
      exit(False);
  Result := True;
end;

function TGLiteChainHashMap.ContainsAll(e: IKeyEnumerable): Boolean;
var
  k: TKey;
begin
  for k in e do
    if not Contains(k) then
      exit(False);
  Result := True;
end;

function TGLiteChainHashMap.ContainsAll(constref aMap: TGLiteChainHashMap): Boolean;
var
  k: TKey;
begin
  if @aMap = @Self then
    exit(True);
  for k in aMap.Keys do
    if not Contains(k) then
      exit(False);
  Result := True;
end;

function TGLiteChainHashMap.Remove(constref aKey: TKey): Boolean;
begin
  Result := FTable.Remove(aKey);
end;

function TGLiteChainHashMap.RemoveAll(const a: array of TKey): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in a do
    Result += Ord(Remove(k));
end;

function TGLiteChainHashMap.RemoveAll(e: IKeyEnumerable): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in e do
    Result += Ord(Remove(k));
end;

function TGLiteChainHashMap.RemoveAll(constref aMap: TGLiteChainHashMap): SizeInt;
var
  k: TKey;
begin
  if @aMap <> @Self then
    begin
      Result := 0;
      for k in aMap.Keys do
        Result += Ord(Remove(k));
    end
  else
    begin
      Result := Count;
      Clear;
    end;
end;

function TGLiteChainHashMap.RemoveIf(aTest: TKeyTest): SizeInt;
var
  List: PNode;
  I: SizeInt = 0;
begin
  List := FTable.NodeList;
  Result := 0;
  while I < FTable.Count do
    if aTest(List[I].Data.Key) then
      begin
        FTable.RemoveIndex(I);
        Inc(Result);
      end
    else
      Inc(I);
end;

function TGLiteChainHashMap.RemoveIf(aTest: TOnKeyTest): SizeInt;
var
  List: PNode;
  I: SizeInt = 0;
begin
  List := FTable.NodeList;
  Result := 0;
  while I < FTable.Count do
    if aTest(List[I].Data.Key) then
      begin
        FTable.RemoveIndex(I);
        Inc(Result);
      end
    else
      Inc(I);
end;

function TGLiteChainHashMap.RemoveIf(aTest: TNestKeyTest): SizeInt;
var
  List: PNode;
  I: SizeInt = 0;
begin
  List := FTable.NodeList;
  Result := 0;
  while I < FTable.Count do
    if aTest(List[I].Data.Key) then
      begin
        FTable.RemoveIndex(I);
        Inc(Result);
      end
    else
      Inc(I);
end;

function TGLiteChainHashMap.Extract(constref aKey: TKey; out v: TValue): Boolean;
var
  p: PEntry;
  Pos: SizeInt;
begin
  p := FTable.Find(aKey, Pos);
  Result := p <> nil;
  if Result then
    begin
      v := p^.Value;
      FTable.RemoveIndex(Pos);
    end;
end;

function TGLiteChainHashMap.ExtractIf(aTest: TKeyTest): TEntryArray;
var
  List: PNode;
  I: SizeInt = 0;
  J: SizeInt = 0;
begin
  List := FTable.NodeList;
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  while I < FTable.Count do
    if aTest(List[I].Data.Key) then
      begin
        if J = System.Length(Result) then
          System.SetLength(Result, J shl 1);
        Result[J] := List[I].Data;
        FTable.RemoveIndex(I);
        Inc(J);
      end
    else
      Inc(I);
  System.SetLength(Result, J);
end;

function TGLiteChainHashMap.ExtractIf(aTest: TOnKeyTest): TEntryArray;
var
  List: PNode;
  I: SizeInt = 0;
  J: SizeInt = 0;
begin
  List := FTable.NodeList;
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  while I < FTable.Count do
    if aTest(List[I].Data.Key) then
      begin
        if J = System.Length(Result) then
          System.SetLength(Result, J shl 1);
        Result[J] := List[I].Data;
        FTable.RemoveIndex(I);
        Inc(J);
      end
    else
      Inc(I);
  System.SetLength(Result, J);
end;

function TGLiteChainHashMap.ExtractIf(aTest: TNestKeyTest): TEntryArray;
var
  List: PNode;
  I: SizeInt = 0;
  J: SizeInt = 0;
begin
  List := FTable.NodeList;
  System.SetLength(Result, ARRAY_INITIAL_SIZE);
  while I < FTable.Count do
    if aTest(List[I].Data.Key) then
      begin
        if J = System.Length(Result) then
          System.SetLength(Result, J shl 1);
        Result[J] := List[I].Data;
        FTable.RemoveIndex(I);
        Inc(J);
      end
    else
      Inc(I);
  System.SetLength(Result, J);
end;

procedure TGLiteChainHashMap.RetainAll(aCollection: IKeyCollection);
var
  List: PNode;
  I: SizeInt = 0;
begin
  List := FTable.NodeList;
  while I < FTable.Count do
    if aCollection.NonContains(List[I].Data.Key) then
      FTable.RemoveIndex(I)
    else
      Inc(I);
end;

function TGLiteChainHashMap.Keys: TKeys;
begin
  Result := TKeys.Create(@Self);
end;

function TGLiteChainHashMap.Values: TValues;
begin
  Result := TValues.Create(@Self);
end;

{ TGThreadFGHashMap.TSlot }

class operator TGThreadFGHashMap.TSlot.Initialize(var aSlot: TSlot);
begin
  aSlot.FState := 0;
  aSlot.Head := nil;
end;

procedure TGThreadFGHashMap.TSlot.Lock;
begin
{$IFDEF CPU64}
  while Boolean(InterlockedExchange64(FState, SizeUInt(1))) do
{$ELSE CPU64}
  while Boolean(InterlockedExchange(FState, SizeUInt(1))) do
{$ENDIF CPU64}
    ThreadSwitch;
end;

procedure TGThreadFGHashMap.TSlot.Unlock;
begin
{$IFDEF CPU64}
  InterlockedExchange64(FState, SizeUInt(0));
{$ELSE CPU64}
  InterlockedExchange(FState, SizeUInt(0));
{$ENDIF CPU64}
end;

{ TGThreadFGHashMap }

function TGThreadFGHashMap.NewNode(constref aKey: TKey; constref aValue: TValue; aHash: SizeInt): PNode;
begin
  New(Result);
  Result^.Hash := aHash;
  Result^.Key := aKey;
  Result^.Value := aValue;
{$IFDEF CPU64}
  InterlockedIncrement64(FCount);
{$ELSE CPU64}
  InterlockedIncrement(FCount);
{$ENDIF CPU64}
end;

procedure TGThreadFGHashMap.FreeNode(aNode: PNode);
begin
  if aNode <> nil then
    begin
      aNode^ := Default(TNode);
      Dispose(aNode);
    {$IFDEF CPU64}
      InterlockedDecrement64(FCount);
    {$ELSE CPU64}
      InterlockedDecrement(FCount);
    {$ENDIF CPU64}
    end;
end;

function TGThreadFGHashMap.GetCapacity: SizeInt;
begin
  FGlobLock.BeginRead;
  try
    Result := System.Length(FSlotList);
  finally
    FGlobLock.EndRead;
  end;
end;

procedure TGThreadFGHashMap.ClearChainList;
var
  Node, Next: PNode;
  I: SizeInt;
begin
  for I := 0 to System.High(FSlotList) do
    begin
      Node := FSlotList[I].Head;
      while Node <> nil do
        begin
          Next := Node^.Next;
          Node^ := Default(TNode);
          Dispose(Node);
          Node := Next;
        end;
    end;
  FSlotList := nil;
end;

function TGThreadFGHashMap.LockSlot(constref aKey: TKey; out aHash: SizeInt): SizeInt;
begin
  aHash := TKeyEqRel.HashCode(aKey);
  FGlobLock.BeginRead;
  try
    Result := aHash and System.High(FSlotList);
    FSlotList[Result].Lock;
  finally
    FGlobLock.EndRead;
  end;
end;

function TGThreadFGHashMap.Find(constref aKey: TKey; aSlotIdx: SizeInt; aHash: SizeInt): PNode;
var
  Node: PNode;
begin
  Node := FSlotList[aSlotIdx].Head;
  while Node <> nil do
    begin
      if (Node^.Hash = aHash) and TKeyEqRel.Equal(Node^.Key, aKey) then
        exit(Node);
      Node := Node^.Next;
    end;
  Result := nil;
end;

function TGThreadFGHashMap.ExtractNode(constref aKey: TKey; aSlotIdx: SizeInt; aHash: SizeInt): PNode;
var
  Node: PNode;
  Prev: PNode = nil;
begin
  Node := FSlotList[aSlotIdx].Head;
  while Node <> nil do
    begin
      if (Node^.Hash = aHash) and TKeyEqRel.Equal(Node^.Key, aKey) then
        begin
          if Prev <> nil then
            Prev^.Next := Node^.Next
          else
            FSlotList[aSlotIdx].Head := Node^.Next;
          exit(Node);
        end;
      Prev := Node;
      Node := Node^.Next;
    end;
  Result := nil;
end;

procedure TGThreadFGHashMap.CheckNeedExpand;
begin
  if Count > Succ(Trunc(System.Length(FSlotList) * FLoadFactor)) then
    begin
      FGlobLock.BeginWrite;
      try
        if Count > Succ(Trunc(System.Length(FSlotList) * FLoadFactor)) then
          Expand;
      finally
        FGlobLock.EndWrite;
      end;
    end;
end;

procedure TGThreadFGHashMap.Expand;
var
  I, Len, Mask: SizeInt;
  Node, Next: PNode;
  Head: PNode = nil;
begin
  Len := System.Length(FSlotList);
  for I := 0 to Pred(Len) do
    FSlotList[I].Lock;
  try
    for I := 0 to Pred(Len) do
      begin
        Node := FSlotList[I].Head;
        while Node <> nil do
          begin
            Next := Node^.Next;
            Node^.Next := Head;
            Head := Node;
            Node := Next;
          end;
        FSlotList[I].Head := nil;
      end;
     Mask := Pred(Len * 2);
     System.SetLength(FSlotList, Succ(Mask));
     Node := Head;
     while Node <> nil do
       begin
         I := Node^.Hash and Mask;
         Next := Node^.Next;
         Node^.Next := FSlotList[I].Head;
         FSlotList[I].Head := Node;
         Node := Next;
       end;
  finally
    for I := Pred(Len) downto 0 do
      FSlotList[I].Unlock;
  end;
end;

function TGThreadFGHashMap.GetValue(const aKey: TKey): TValue;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  Result := Default(TValue);
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := Find(aKey, SlotIdx, Hash);
    if Node <> nil then
      Result := Node^.Value;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

constructor TGThreadFGHashMap.Create;
begin
  FLoadFactor := DEFAULT_LOAD_FACTOR;
  System.SetLength(FSlotList, DEFAULT_CONTAINER_CAPACITY);
  FGlobLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

constructor TGThreadFGHashMap.Create(aCapacity: SizeInt; aLoadFactor: Single);
var
  RealCap: SizeInt;
begin
  if aLoadFactor < MIN_LOAD_FACTOR then
    aLoadFactor := MIN_LOAD_FACTOR
  else
    if aLoadFactor > MAX_LOAD_FACTOR then
      aLoadFactor := MAX_LOAD_FACTOR;
  FLoadFactor := aLoadFactor;
  if aCapacity < DEFAULT_CONTAINER_CAPACITY then
    aCapacity := DEFAULT_CONTAINER_CAPACITY;
  RealCap := RoundUpTwoPower(aCapacity);
  System.SetLength(FSlotList, RealCap);
  FGlobLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TGThreadFGHashMap.Destroy;
begin
  FGlobLock.BeginWrite;
  try
    ClearChainList;
    inherited;
  finally
    FGlobLock.EndWrite;
    FGlobLock.Free;
  end;
end;

function TGThreadFGHashMap.Add(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := Find(aKey, SlotIdx, Hash);
    Result := Node = nil;
    if Result then
      begin
        Node := NewNode(aKey, aValue, Hash);
        Node^.Next := FSlotList[SlotIdx].Head;
        FSlotList[SlotIdx].Head := Node;
      end;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
  if Result then
    CheckNeedExpand;
end;

function TGThreadFGHashMap.Add(constref e: TEntry): Boolean;
begin
  Result := Add(e.Key, e.Value);
end;

procedure TGThreadFGHashMap.AddOrSetValue(const aKey: TKey; const aValue: TValue);
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
  Added: Boolean = False;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := Find(aKey, SlotIdx, Hash);
    if Node = nil then
      begin
        Node := NewNode(aKey, aValue, Hash);
        Node^.Next := FSlotList[SlotIdx].Head;
        FSlotList[SlotIdx].Head := Node;
        Added := True;
      end
    else
      Node^.Value := aValue;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
  if Added then
    CheckNeedExpand;
end;

procedure TGThreadFGHashMap.AddOrSetValue(constref e: TEntry);
begin
  AddOrSetValue(e.Key, e.Value);
end;

function TGThreadFGHashMap.TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := Find(aKey, SlotIdx, Hash);
    Result := Node <> nil;
    if Result then
      aValue := Node^.Value;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

function TGThreadFGHashMap.GetValueDef(constref aKey: TKey; constref aDefault: TValue): TValue;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  Result := aDefault;
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := Find(aKey, SlotIdx, Hash);
    if Node <> nil then
      Result := Node^.Value;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

function TGThreadFGHashMap.Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := Find(aKey, SlotIdx, Hash);
    Result := Node <> nil;
    if Result then
      Node^.Value := aNewValue;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

function TGThreadFGHashMap.Contains(constref aKey: TKey): Boolean;
var
  SlotIdx, Hash: SizeInt;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Result := Find(aKey, SlotIdx, Hash) <> nil;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

function TGThreadFGHashMap.Extract(constref aKey: TKey; out aValue: TValue): Boolean;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := ExtractNode(aKey, SlotIdx, Hash);
    Result := Node <> nil;
    if Result then
      begin
        aValue := Node^.Value;
        FreeNode(Node);
      end;
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

function TGThreadFGHashMap.Remove(constref aKey: TKey): Boolean;
var
  SlotIdx, Hash: SizeInt;
  Node: PNode;
begin
  SlotIdx := LockSlot(aKey, Hash);
  try
    Node := ExtractNode(aKey, SlotIdx, Hash);
    Result := Node <> nil;
    if Result then
      FreeNode(Node);
  finally
    FSlotList[SlotIdx].Unlock;
  end;
end;

end.

