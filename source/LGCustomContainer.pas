{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Common abstact container classes.                                       *
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
unit LGCustomContainer;

{$MODE OBJFPC}{$H+}
{$INLINE ON}
{$MODESWITCH ADVANCEDRECORDS}
{$MODESWITCH NESTEDPROCVARS}

interface

uses

  SysUtils,
  math,
  LGUtils,
  {%H-}LGHelpers,
  LGArrayHelpers,
  LGStrConst;

type

  { TGEnumerable }

  generic TGEnumerable<T> = class abstract(TObject, specialize IGEnumerable<T>, IObjInstance)
  public
  type
    TCustomEnumerable = specialize TGEnumerable<T>;
    TCustomEnumerator = specialize TGCustomEnumerator<T>;
    IEnumerable       = specialize IGEnumerable<T>;
    TOptional         = specialize TGOptional<T>;
    TArray            = specialize TGArray<T>;
    TCompare          = specialize TGCompare<T>;
    TOnCompare        = specialize TGOnCompare<T>;
    TNestCompare      = specialize TGNestCompare<T>;
    TTest             = specialize TGTest<T>;
    TOnTest           = specialize TGOnTest<T>;
    TNestTest         = specialize TGNestTest<T>;
    TMapFunc          = specialize TGMapFunc<T, T>;
    TOnMap            = specialize TGOnMap<T, T>;
    TNestMap          = specialize TGNestMap<T, T>;
    TFoldFunc         = specialize TGFoldFunc<T, T>;
    TOnFold           = specialize TGOnFold<T, T>;
    TNestFold         = specialize TGNestFold<T, T>;
    TDefaults         = specialize TGDefaults<T>;
    TItem             = T;

  protected
  type
    PItem = ^T;

    function  _GetRef: TObject; inline;
  public
    function GetEnumerator: TCustomEnumerator;  virtual; abstract;
  { enumerates elements in reverse order }
    function Reverse: IEnumerable; virtual;
    function ToArray: TArray; virtual;
    function Any: Boolean;
    function None: Boolean;
    function Total: SizeInt;
    function FindFirst(out aValue: T): Boolean;
    function First: TOptional;
    function FindLast(out aValue: T): Boolean;
    function Last: TOptional;
    function FindMin(out aValue: T; c: TCompare): Boolean;
    function FindMin(out aValue: T; c: TOnCompare): Boolean;
    function FindMin(out aValue: T; c: TNestCompare): Boolean;
    function Min(c: TCompare): TOptional;
    function Min(c: TOnCompare): TOptional;
    function Min(c: TNestCompare): TOptional;
    function FindMax(out aValue: T; c: TCompare): Boolean;
    function FindMax(out aValue: T; c: TOnCompare): Boolean;
    function FindMax(out aValue: T; c: TNestCompare): Boolean;
    function Max(c: TCompare): TOptional;
    function Max(c: TOnCompare): TOptional;
    function Max(c: TNestCompare): TOptional;
    function Skip(aCount: SizeInt): IEnumerable; inline;
    function Limit(aCount: SizeInt): IEnumerable; inline;
    function Sorted(c: TCompare): IEnumerable;
    function Sorted(c: TOnCompare): IEnumerable;
    function Sorted(c: TNestCompare): IEnumerable;
    function Select(aTest: TTest): IEnumerable; inline;
    function Select(aTest: TOnTest): IEnumerable; inline;
    function Select(aTest: TNestTest): IEnumerable; inline;
    function Any(aTest: TTest): Boolean;
    function Any(aTest: TOnTest): Boolean;
    function Any(aTest: TNestTest): Boolean;
    function None(aTest: TTest): Boolean; inline;
    function None(aTest: TOnTest): Boolean; inline;
    function None(aTest: TNestTest): Boolean; inline;
    function All(aTest: TTest): Boolean;
    function All(aTest: TOnTest): Boolean;
    function All(aTest: TNestTest): Boolean;
    function Total(aTest: TTest): SizeInt;
    function Total(aTest: TOnTest): SizeInt;
    function Total(aTest: TNestTest): SizeInt;
    function Distinct(c: TCompare): IEnumerable;
    function Distinct(c: TOnCompare): IEnumerable;
    function Distinct(c: TNestCompare): IEnumerable;
    function Map(aMap: TMapFunc): IEnumerable; inline;
    function Map(aMap: TOnMap): IEnumerable; inline;
    function Map(aMap: TNestMap): IEnumerable; inline;
  { left-associative linear fold }
    function Fold(aFold: TFoldFunc; constref v0: T): T;
    function Fold(aFold: TFoldFunc): TOptional;
    function Fold(aFold: TOnFold; constref v0: T): T;
    function Fold(aFold: TOnFold): TOptional;
    function Fold(aFold: TNestFold; constref v0: T): T;
    function Fold(aFold: TNestFold): TOptional;
  end;

{$I LGEnumsH.inc}

  { TGCustomContainer }

  generic TGCustomContainer<T> = class abstract(specialize TGEnumerable<T>, specialize IGContainer<T>)
  public
  type
    TCustomContainer = specialize TGCustomContainer<T>;

  protected
  type
    //to supress unnecessary refcounting
    TFake = {$IFNDEF FPC_REQUIRES_PROPER_ALIGNMENT}array[0..Pred(SizeOf(T))] of Byte{$ELSE}T{$ENDIF};
    TFakeArray = array of TFake;

    TContainerEnumerator = class(specialize TGCustomEnumerator<T>)
    strict protected
      FOwner: TCustomContainer;
    public
      constructor Create(c: TCustomContainer);
      destructor Destroy; override;
    end;

    TContainerEnumerable = class(specialize TGAutoEnumerable<T>)
    strict protected
      FOwner: TCustomContainer;
    public
      constructor Create(c: TCustomContainer);
      destructor Destroy; override;
    end;

  strict private
    FIterationCount: LongInt;
    function  GetInIteration: Boolean; inline;
  protected
    procedure CapacityExceedError(aValue: SizeInt); inline;
    procedure AccessEmptyError; inline;
    procedure IndexOutOfBoundError(aIndex: SizeInt); inline;
    procedure CheckInIteration; inline;
    procedure BeginIteration; inline;
    procedure EndIteration; inline;
    function  GetCount: SizeInt; virtual; abstract;
    function  GetCapacity: SizeInt; virtual; abstract;
    function  DoGetEnumerator: TCustomEnumerator;  virtual; abstract;
    procedure DoClear; virtual; abstract;
    procedure DoTrimToFit; virtual; abstract;
    procedure DoEnsureCapacity(aValue: SizeInt); virtual; abstract;
    procedure CopyItems(aBuffer: PItem); virtual;
    property  InIteration: Boolean read GetInIteration;
  public
    function  GetEnumerator: TCustomEnumerator; override;
    function  ToArray: TArray; override;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Clear;
    procedure TrimToFit;
    procedure EnsureCapacity(aValue: SizeInt);
    property  Count: SizeInt read GetCount;
    property  Capacity: SizeInt read GetCapacity;
  end;

{$I LGDynBuffersH.inc}

  { TGCustomCollection: collection abstract ancestor class}
  generic TGCustomCollection<T> = class abstract(specialize TGCustomContainer<T>, specialize IGCollection<T>)
  public
  type
    TCustomCollection = specialize TGCustomCollection<T>;
    ICollection       = specialize IGCollection<T>;

  protected
    function  DoAdd(constref aValue: T): Boolean; virtual; abstract;
    function  DoExtract(constref aValue: T): Boolean; virtual; abstract;
    function  DoRemoveIf(aTest: TTest): SizeInt; virtual; abstract;
    function  DoRemoveIf(aTest: TOnTest): SizeInt; virtual; abstract;
    function  DoRemoveIf(aTest: TNestTest): SizeInt; virtual; abstract;
    function  DoExtractIf(aTest: TTest): TArray; virtual; abstract;
    function  DoExtractIf(aTest: TOnTest): TArray; virtual; abstract;
    function  DoExtractIf(aTest: TNestTest): TArray; virtual; abstract;

    function  DoRemove(constref aValue: T): Boolean; virtual;
    function  DoAddAll(constref a: array of T): SizeInt; virtual; overload;
    function  DoAddAll(e: IEnumerable): SizeInt; virtual; abstract; overload;
    function  DoRemoveAll(constref a: array of T): SizeInt;
    function  DoRemoveAll(e: IEnumerable): SizeInt; virtual;
  public
  { returns True if element added }
    function  Add(constref aValue: T): Boolean;
  { returns count of added elements }
    function  AddAll(constref a: array of T): SizeInt;
  { returns count of added elements }
    function  AddAll(e: IEnumerable): SizeInt;
    function  Contains(constref aValue: T): Boolean; virtual; abstract;
    function  NonContains(constref aValue: T): Boolean;
    function  ContainsAny(constref a: array of T): Boolean;
    function  ContainsAny(e: IEnumerable): Boolean;
    function  ContainsAll(constref a: array of T): Boolean;
    function  ContainsAll(e: IEnumerable): Boolean;
  { returns True if element removed }
    function  Remove(constref aValue: T): Boolean;
  { returns count of removed elements }
    function  RemoveAll(constref a: array of T): SizeInt;
  { returns count of removed elements }
    function  RemoveAll(e: IEnumerable): SizeInt;
  { returns count of removed elements }
    function  RemoveIf(aTest: TTest): SizeInt;
    function  RemoveIf(aTest: TOnTest): SizeInt;
    function  RemoveIf(aTest: TNestTest): SizeInt;
  { returns True if element extracted }
    function  Extract(constref aValue: T): Boolean;
    function  ExtractIf(aTest: TTest): TArray;
    function  ExtractIf(aTest: TOnTest): TArray;
    function  ExtractIf(aTest: TNestTest): TArray;
  { will contain only those elements that are simultaneously contained in self and aCollection }
    procedure RetainAll(aCollection: ICollection);
    function  Clone: TCustomCollection; virtual; abstract;
  end;

  { TGThreadCollection }

  generic TGThreadCollection<T> = class
  public
  type
    ICollection = specialize IGCollection<T>;

  private
    FCollection: ICollection;
    FLock: TRTLCriticalSection;
    procedure Lock; inline;
  public
    constructor Create(aCollection: ICollection);
    destructor Destroy; override;
    function  LockCollection: ICollection;
    procedure Unlock; inline;
    procedure Clear;
    function  Contains(constref aValue: T): Boolean;
    function  NonContains(constref aValue: T): Boolean;
    function  Add(constref aValue: T): Boolean;
    function  Remove(constref aValue: T): Boolean;
  end;

  { TGCustomSet: set abstract ancestor class }
  generic TGCustomSet<T> = class abstract(specialize TGCustomCollection<T>)
  public
  type
    TCustomSet = specialize TGCustomSet<T>;

  protected
  type
    TEntry = record
      Key: T;
    end;
    PEntry = ^TEntry;

    TExtractHelper = object
    private
      FCurrIndex: SizeInt;
      FExtracted: TArray;
    public
      procedure OnExtract(p: PEntry);
      procedure Init;
      function  Final: TArray;
    end;

    function  DoAddAll(e: IEnumerable): SizeInt; override; overload;
    procedure DoSymmetricSubtract(aSet: TCustomSet);
  public
    function  IsSuperset(aSet: TCustomSet): Boolean;
    function  IsSubset(aSet: TCustomSet): Boolean; inline;
    function  IsEqual(aSet: TCustomSet): Boolean;
    function  Intersecting(aSet: TCustomSet): Boolean; inline;
    procedure Intersect(aSet: TCustomSet);
    procedure Join(aSet: TCustomSet);
    procedure Subtract(aSet: TCustomSet);
    procedure SymmetricSubtract(aSet: TCustomSet);
  end;

  generic TGMultisetEntry<T> = record
    Key: T;
    Count: SizeInt; //multiplicity(count of occurrences)
  end;

  { TGCustomMultiSet: multiSet abstract ancestor class  }
  generic TGCustomMultiSet<T> = class abstract(specialize TGCustomCollection<T>)
  public
  type
    TEntry           = specialize TGMultisetEntry<T>;
    TCustomMultiSet  = specialize TGCustomMultiSet<T>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;

  protected
  type
    PEntry = ^TEntry;

    TExtractHelper = object
    private
      FCurrIndex: SizeInt;
      FExtracted: TArray;
    public
      procedure OnExtract(p: PEntry);
      procedure Init;
      function  Final: TArray;
    end;

    TIntersectHelper = object
      FSet,
      FOtherSet: TCustomMultiSet;
      function OnIntersect(p: PEntry): Boolean;
    end;

  var
    FCount: SizeInt;
    function  FindEntry(constref aKey: T): PEntry; virtual; abstract;
    //return True if aKey found, otherwise insert entry with garbage item and return False;
    function  FindOrAdd(constref aKey: T; out p: PEntry): Boolean; virtual; abstract;
    //returns True only if e removed
    function  DoSubEntry(constref e: TEntry): Boolean; virtual; abstract;
    //returns True only if e removed
    function  DoSymmSubEntry(constref e: TEntry): Boolean; virtual; abstract;
    function  GetEntryCount: SizeInt; virtual; abstract;
    function  DoDoubleEntryCounters: SizeInt; virtual; abstract;
    function  GetDistinct: IEnumerable; virtual; abstract;  // distinct keys
    function  GetEntries: IEntryEnumerable; virtual; abstract;
    procedure DoIntersect(aSet: TCustomMultiSet); virtual; abstract;

    function  GetCount: SizeInt; override;
    procedure DoJoinEntry(constref e: TEntry);
    procedure DoAddEntry(constref e: TEntry);
    function  GetKeyCount(const aKey: T): SizeInt;
    procedure SetKeyCount(const aKey: T; aValue: SizeInt);
    procedure DoArithAdd(aSet: TCustomMultiSet);
    procedure DoArithSubtract(aSet: TCustomMultiSet);
    procedure DoSymmSubtract(aSet: TCustomMultiSet);

    function  DoAdd(constref aKey: T): Boolean; override;
    function  DoAddAll(e: IEnumerable): SizeInt; override; overload;
    function  DoRemoveAll(e: IEnumerable): SizeInt; override;
    property  ElemCount: SizeInt read FCount;
  public
    function  Contains(constref aKey: T): Boolean; override;
  { returns True if multiplicity of an any key in self is greater then or equal to
    the multiplicity of that key in aSet }
    function  IsSuperMultiSet(aSet: TCustomMultiSet): Boolean;
  { returns True if multiplicity of an any key in aSet is greater then or equal to
    the multiplicity of that key in self }
    function  IsSubMultiSet(aSet: TCustomMultiSet): Boolean;
  { returns True if the multiplicity of an any key in self is equal to the multiplicity of that key in aSet }
    function  IsEqual(aSet: TCustomMultiSet): Boolean;
    function  Intersecting(aSet: TCustomMultiSet): Boolean;
  { will contain only those keys that are simultaneously contained in self and in aSet;
    the multiplicity of a key becomes equal to the MINIMUM of the multiplicities of a key in self and aSet }
    procedure Intersect(aSet: TCustomMultiSet);
  { will contain all keys that are contained in self and in aSet;
    the multiplicity of a key will become equal to the MAXIMUM of the multiplicities of
    a key in self and aSet }
    procedure Join(aSet: TCustomMultiSet);
  { will contain all keys that are contained in self or in aSet;
    the multiplicity of a key will become equal to the SUM of the multiplicities of a key in self and aSet }
    procedure ArithmeticAdd(aSet: TCustomMultiSet);
  { will contain only those keys whose multiplicity is greater then or equal to the multiplicity
    of that key in aSet; the multiplicity of a key will become equal to the difference of multiplicities
    of a key in self and aSet }
    procedure ArithmeticSubtract(aSet: TCustomMultiSet);
  { will contain only those keys whose multiplicity is not equal to the multiplicity
    of that key in aSet; the multiplicity of a key will become equal to absolute value of difference
    of the multiplicities of a key in self and aSet }
    procedure SymmetricSubtract(aSet: TCustomMultiSet);
  { enumerates underlying set - distinct keys only }
    function  Distinct: IEnumerable;
    function  Entries: IEntryEnumerable;
  { returs number of distinct keys }
    property  EntryCount: SizeInt read GetEntryCount; //dimension, Count - cardinality
  { will always return 0 if an element not in the multiset;
    will raise EArgumentOutOfRangeException if one try to set negative multiplicity of a key }
    property  Counts[const aKey: T]: SizeInt read GetKeyCount write SetKeyCount; default;
  end;

  { TCustomIterable }

  TCustomIterable = class
  private
    FIterationCount: LongInt;
    function  GetInIteration: Boolean; inline;
  protected
    procedure CapacityExceedError(aValue: SizeInt); inline;
    procedure CheckInIteration; inline;
    procedure BeginIteration; inline;
    procedure EndIteration; inline;
    property  InIteration: Boolean read GetInIteration;
  end;

  TMapObjectOwns   = (moOwnsKeys, moOwnsValues);
  TMapObjOwnership = set of TMapObjectOwns;

  const
    OWNS_BOTH = [moOwnsKeys, moOwnsValues];

  type
  { TGCustomMap: map abstract ancestor class  }
  generic TGCustomMap<TKey, TValue> = class abstract(TCustomIterable, specialize IGMap<TKey, TValue>)
  {must be  generic TGCustomMap<TKey, TValue> = class abstract(
              specialize TGContainer<specialize TGMapEntry<TKey, TValue>>), but :( ... }
  public
  type
    TCustomMap       = specialize TGCustomMap<TKey, TValue>;
    TEntry           = specialize TGMapEntry<TKey, TValue>;
    IKeyEnumerable   = specialize IGEnumerable<TKey>;
    IValueEnumerable = specialize IGEnumerable<TValue>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;
    TEntryArray      = specialize TGArray<TEntry>;
    TKeyArray        = specialize TGArray<TKey>;
    TKeyTest         = specialize TGTest<TKey>;
    TOnKeyTest       = specialize TGOnTest<TKey>;
    TNestKeyTest     = specialize TGNestTest<TKey>;
    TKeyOptional     = specialize TGOptional<TKey>;
    TValueOptional   = specialize TGOptional<TValue>;
    TKeyCollection   = specialize TGCustomCollection<TKey>;
    IKeyCollection   = specialize IGCollection<TKey>;

  protected
  type
    PEntry          = ^TEntry;

    TExtractHelper = object
    private
      FCurrIndex: SizeInt;
      FExtracted: TEntryArray;
    public
      procedure OnExtract(p: PEntry);
      procedure Init;
      function  Final: TEntryArray;
    end;

    TCustomKeyEnumerable = class(specialize TGAutoEnumerable<TKey>)
    protected
      FOwner: TCustomMap;
    public
      constructor Create(aMap: TCustomMap);
      destructor Destroy; override;
    end;

    TCustomValueEnumerable = class(specialize TGAutoEnumerable<TValue>)
    protected
      FOwner: TCustomMap;
    public
      constructor Create(aMap: TCustomMap);
      destructor Destroy; override;
    end;

    TCustomEntryEnumerable = class(specialize TGAutoEnumerable<TEntry>)
    protected
      FOwner: TCustomMap;
    public
      constructor Create(aMap: TCustomMap);
      destructor Destroy; override;
    end;

    function  _GetRef: TObject;
    function  GetCount: SizeInt;  virtual; abstract;
    function  GetCapacity: SizeInt; virtual; abstract;
    function  Find(constref aKey: TKey): PEntry; virtual; abstract;
    //returns True if aKey found, otherwise inserts (garbage) entry and returns False;
    function  FindOrAdd(constref aKey: TKey; out p: PEntry): Boolean; virtual; abstract;
    function  DoExtract(constref aKey: TKey; out v: TValue): Boolean; virtual; abstract;
    function  DoRemoveIf(aTest: TKeyTest): SizeInt; virtual; abstract;
    function  DoRemoveIf(aTest: TOnKeyTest): SizeInt; virtual; abstract;
    function  DoRemoveIf(aTest: TNestKeyTest): SizeInt; virtual; abstract;
    function  DoExtractIf(aTest: TKeyTest): TEntryArray; virtual; abstract;
    function  DoExtractIf(aTest: TOnKeyTest): TEntryArray; virtual; abstract;
    function  DoExtractIf(aTest: TNestKeyTest): TEntryArray; virtual; abstract;

    function  DoRemove(constref aKey: TKey): Boolean; virtual;
    procedure DoClear; virtual; abstract;
    procedure DoEnsureCapacity(aValue: SizeInt); virtual; abstract;
    procedure DoTrimToFit; virtual; abstract;
    function  GetKeys: IKeyEnumerable; virtual; abstract;
    function  GetValues: IValueEnumerable; virtual; abstract;
    function  GetEntries: IEntryEnumerable; virtual; abstract;

    function  GetValue(const aKey: TKey): TValue; inline;
    function  DoSetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean; virtual;
    function  DoAdd(constref aKey: TKey; constref aValue: TValue): Boolean;
    function  DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean; virtual;
    function  DoAddAll(constref a: array of TEntry): SizeInt;
    function  DoAddAll(e: IEntryEnumerable): SizeInt;
    function  DoRemoveAll(constref a: array of TKey): SizeInt;
    function  DoRemoveAll(e: IKeyEnumerable): SizeInt;
  public
    function  ToArray: TEntryArray;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Clear;
    procedure EnsureCapacity(aValue: SizeInt);
  { free unused memory if possible }
    procedure TrimToFit;
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
    function  AddOrSetValue(constref e: TEntry): Boolean;
  { will add only entries which keys are absent in map }
    function  AddAll(constref a: array of TEntry): SizeInt;
    function  AddAll(e: IEntryEnumerable): SizeInt;
  { returns True and map aNewValue to aKey only if contains aKey, False otherwise }
    function  Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean;
    function  Contains(constref aKey: TKey): Boolean; inline;
    function  ContainsAny(constref a: array of TKey): Boolean;
    function  ContainsAny(e: IKeyEnumerable): Boolean;
    function  ContainsAll(constref a: array of TKey): Boolean;
    function  ContainsAll(e: IKeyEnumerable): Boolean;
    function  Remove(constref aKey: TKey): Boolean;
    function  RemoveAll(constref a: array of TKey): SizeInt;
    function  RemoveAll(e: IKeyEnumerable): SizeInt;
    function  RemoveIf(aTest: TKeyTest): SizeInt;
    function  RemoveIf(aTest: TOnKeyTest): SizeInt;
    function  RemoveIf(aTest: TNestKeyTest): SizeInt;
    function  Extract(constref aKey: TKey; out v: TValue): Boolean;
    function  ExtractIf(aTest: TKeyTest): TEntryArray;
    function  ExtractIf(aTest: TOnKeyTest): TEntryArray;
    function  ExtractIf(aTest: TNestKeyTest): TEntryArray;
    procedure RetainAll({%H-}c: IKeyCollection);
    function  Clone: TCustomMap; virtual; abstract;
    function  Keys: IKeyEnumerable;
    function  Values: IValueEnumerable;
    function  Entries: IEntryEnumerable;
    property  Count: SizeInt read GetCount;
    property  Capacity: SizeInt read GetCapacity;
  { reading will raise ELGMapError if an aKey is not present in map }
    property  Items[const aKey: TKey]: TValue read GetValue write AddOrSetValue; default;
  end;

  { TGCustomMultiMap: multimap abstract ancestor class }
  generic TGCustomMultiMap<TKey, TValue> = class abstract(TCustomIterable)
  {must be  generic TGCustomMultiMap<TKey, TValue> = class abstract(
              specialize TGContainer<specialize TGMapEntry<TKey, TValue>>), but :( ... }
  public
  type
    TCustomMultiMap  = specialize TGCustomMultiMap<TKey, TValue>;
    TEntry           = specialize TGMapEntry<TKey, TValue>;
    IKeyEnumerable   = specialize IGEnumerable<TKey>;
    IValueEnumerable = specialize IGEnumerable<TValue>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;
    TValueArray      = specialize TGArray<TKey>;

  protected
  type
    TCustomValueEnumerator = specialize TGCustomEnumerator<TValue>;

    TCustomValueSet = class
    protected
      function GetCount: SizeInt; virtual; abstract;
    public
      function  GetEnumerator: TCustomValueEnumerator; virtual; abstract;
      function  ToArray: TValueArray;
      function  Contains(constref aValue: TValue): Boolean; virtual; abstract;
      function  Add(constref aValue: TValue): Boolean; virtual; abstract;
      function  Remove(constref aValue: TValue): Boolean; virtual; abstract;
      property  Count: SizeInt read GetCount;
    end;

    TMMEntry = record
      Key: TKey;
      Values: TCustomValueSet;
    end;
    PMMEntry = ^TMMEntry;

    TCustomKeyEnumerable = class(specialize TGAutoEnumerable<TKey>)
    protected
      FOwner: TCustomMultiMap;
    public
      constructor Create(aMap: TCustomMultiMap);
      destructor Destroy; override;
    end;

    TCustomValueEnumerable = class(specialize TGAutoEnumerable<TValue>)
    protected
      FOwner: TCustomMultiMap;
    public
      constructor Create(aMap: TCustomMultiMap);
      destructor Destroy; override;
    end;

    TCustomEntryEnumerable = class(specialize TGAutoEnumerable<TEntry>)
    protected
      FOwner: TCustomMultiMap;
    public
      constructor Create(aMap: TCustomMultiMap);
      destructor Destroy; override;
    end;

    TCustomValueCursor = class(specialize TGEnumCursor<TValue>)
    protected
      FOwner: TCustomMultiMap;
    public
      constructor Create(e: TCustomEnumerator; aMap: TCustomMultiMap);
      destructor Destroy; override;
    end;

  var
    FCount: SizeInt;
    function  GetKeyCount: SizeInt; virtual; abstract;
    function  GetCapacity: SizeInt; virtual; abstract;
    function  GetUniqueKeyValues: Boolean; virtual; abstract;
    procedure DoClear; virtual; abstract;
    procedure DoEnsureCapacity(aValue: SizeInt); virtual; abstract;
    procedure DoTrimToFit; virtual; abstract;
    function  Find(constref aKey: TKey): PMMEntry; virtual; abstract;
    function  FindOrAdd(constref aKey: TKey): PMMEntry; virtual; abstract;
    function  DoRemoveKey(constref aKey: TKey): SizeInt; virtual; abstract;
    function  GetKeys: IKeyEnumerable; virtual; abstract;
    function  GetValues: IValueEnumerable; virtual; abstract;
    function  GetEntries: IEntryEnumerable; virtual; abstract;

    function  DoAdd(constref aKey: TKey; constref aValue: TValue): Boolean;
    function  DoAddAll(constref a: array of TEntry): SizeInt;
    function  DoAddAll(e: IEntryEnumerable): SizeInt;
    function  DoAddValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
    function  DoAddValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
    function  DoRemove(constref aKey: TKey; constref aValue: TValue): Boolean;
    function  DoRemoveAll(constref a: array of TEntry): SizeInt;
    function  DoRemoveAll(e: IEntryEnumerable): SizeInt;
    function  DoRemoveValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
    function  DoRemoveValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
    function  DoRemoveKeys(constref a: array of TKey): SizeInt;
    function  DoRemoveKeys(e: IKeyEnumerable): SizeInt;
  public
    function  IsEmpty: Boolean;
    function  NonEmpty: Boolean;
    procedure Clear;
    procedure EnsureCapacity(aValue: SizeInt);
    procedure TrimToFit;

    function  Contains(constref aKey: TKey): Boolean; inline;
    function  ContainsValue(constref aKey: TKey; constref aValue: TValue): Boolean;
  { returns True and add TEntry(aKey, aValue) only if value-collection of an aKey does not contains aValue }
    function  Add(constref aKey: TKey; constref aValue: TValue): Boolean;
  { returns True and add e only if value-collection of an e.Key does not contains e.Value }
    function  Add(constref e: TEntry): Boolean;
  { returns count of added values }
    function  AddAll(constref a: array of TEntry): SizeInt;
    function  AddAll(e: IEntryEnumerable): SizeInt;
    function  AddValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
    function  AddValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
  { returns True if aKey exists and mapped to aValue; aValue will be removed(and aKey if no more mapped values) }
    function  Remove(constref aKey: TKey; constref aValue: TValue): Boolean;
    function  Remove(constref e: TEntry): Boolean;
    function  RemoveAll(constref a: array of TEntry): SizeInt;
    function  RemoveAll(e: IEntryEnumerable): SizeInt;
    function  RemoveValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
    function  RemoveValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
  { if aKey exists then removes if with mapped values; returns count of removed values }
    function  RemoveKey(constref aKey: TKey): SizeInt;
  { returns count of removed values }
    function  RemoveKeys(constref a: array of TKey): SizeInt;
  { returns count of removed values }
    function  RemoveKeys(e: IKeyEnumerable): SizeInt;
  { returns copy of values mapped to aKey(empty if aKey is missing) }
    function  CopyValues(const aKey: TKey): TValueArray;
  { enumerates values mapped to aKey(empty if aKey is missing) }
    function  ViewValues(const aKey: TKey): IValueEnumerable;
    function  Keys: IKeyEnumerable;
    function  Values: IValueEnumerable;
    function  Entries: IEntryEnumerable;
  { returns count of values mapped to aKey (similar as multiset)}
    function  ValueCount(constref aKey: TKey): SizeInt;
    property  UniqueKeyValues: Boolean read GetUniqueKeyValues;
    property  Count: SizeInt read FCount;
    property  KeyCount: SizeInt read GetKeyCount;
    property  Capacity: SizeInt read GetCapacity;
    property  Items[const aKey: TKey]: IValueEnumerable read ViewValues; default;
  end;

  { TGCustomTable2D: abstract ancestor class }
  generic TGCustomTable2D<TRow, TCol, TValue> = class abstract
  public
  type
    TCellData = record
      Row:    TRow;
      Column: TCol;
      Value:  TValue;
    end;

    TColData = record
      Row:   TRow;
      Value: TValue;
    end;

    TRowData = record
      Column: TCol;
      Value:  TValue;
    end;

    TCustomTable2D      = TGCustomTable2D;
    TValueArray         = array of TValue;
    IValueEnumerable    = specialize IGEnumerable<TValue>;
    IColEnumerable      = specialize IGEnumerable<TCol>;
    IRowEnumerable      = specialize IGEnumerable<TRow>;
    IRowDataEnumerable  = specialize IGEnumerable<TRowData>;
    IColDataEnumerable  = specialize IGEnumerable<TColData>;
    ICellDataEnumerable = specialize IGEnumerable<TCellData>;
    TRowDataEnumerator  = class abstract(specialize TGCustomEnumerator<TRowData>);

{$PUSH}{$INTERFACES CORBA}
    IRowMap = interface
      function  GetCount: SizeInt;
      function  GetEnumerator: TRowDataEnumerator;
      function  IsEmpty: Boolean;
      function  Contains(constref aCol: TCol): Boolean;
      function  TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean;
      function  GetValueOrDefault(const aCol: TCol): TValue;
    { returns True if not contains aCol was added, False otherwise }
      function  Add(constref aCol: TCol; constref aValue: TValue): Boolean;
      procedure AddOrSetValue(const aCol: TCol; const aValue: TValue);
      function  Remove(constref aCol: TCol): Boolean;
      property  Count: SizeInt read GetCount;
      property  Cells[const aCol: TCol]: TValue read GetValueOrDefault write AddOrSetValue; default;
    end;
{$POP}

   IRowMapEnumerable = specialize IGEnumerable<IRowMap>;

  protected
  type
    TCustomRowMap = class(IRowMap)
    protected
      function  GetCount: SizeInt; virtual; abstract;
    public
      function  GetEnumerator: TRowDataEnumerator; virtual; abstract;
      function  IsEmpty: Boolean;
      function  Contains(constref aCol: TCol): Boolean; virtual; abstract;
      function  TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean; virtual; abstract;
      function  GetValueOrDefault(const aCol: TCol): TValue; inline;
    { returns True if not contains aCol was added, False otherwise }
      function  Add(constref aCol: TCol; constref aValue: TValue): Boolean; virtual; abstract;
      procedure AddOrSetValue(const aCol: TCol; const aValue: TValue); virtual; abstract;
      function  Remove(constref aCol: TCol): Boolean; virtual; abstract;
      property  Count: SizeInt read GetCount;
      property  Cells[const aCol: TCol]: TValue read GetValueOrDefault write AddOrSetValue; default;
    end;

    TRowEntry = record
      Key: TRow;
      Columns: TCustomRowMap;
    end;
    PRowEntry = ^TRowEntry;

    TCustomValueEnumerable    = class abstract(specialize TGAutoEnumerable<TValue>);
    TCustomRowDataEnumerable  = class abstract(specialize TGAutoEnumerable<TRowData>);
    TCustomColDataEnumerable  = class abstract(specialize TGAutoEnumerable<TColData>);
    TCustomCellDataEnumerable = class abstract(specialize TGAutoEnumerable<TCellData>);

  var
    FCellCount: SizeInt;
    function  GetRowCount: SizeInt; virtual; abstract;
    function  DoFindRow(constref aRow: TRow): PRowEntry; virtual; abstract;
  { returns True if row found, False otherwise }
    function  DoFindOrAddRow(constref aRow: TRow; out p: PRowEntry): Boolean; virtual; abstract;
    function  DoRemoveRow(constref aRow: TRow): SizeInt; virtual; abstract;
    function  GetColumn(const aCol: TCol): IColDataEnumerable; virtual; abstract;
    function  GetCellData: ICellDataEnumerable; virtual; abstract;
    function  GetColCount(const aRow: TRow): SizeInt;
  { aRow will be added if it is missed }
    function  GetRow(const aRow: TRow): IRowMap;
  public
    function  IsEmpty: Boolean;
    function  NonEmpty: Boolean;
    procedure Clear; virtual; abstract;
    procedure TrimToFit; virtual; abstract;
    procedure EnsureRowCapacity(aValue: SizeInt); virtual; abstract;
    function  ContainsRow(constref aRow: TRow): Boolean; inline;
    function  FindRow(constref aRow: TRow; out aMap: IRowMap): Boolean;
  { returns True if row found, False otherwise }
    function  FindOrAddRow(constref aRow: TRow; out aMap: IRowMap): Boolean;
  { if not contains aRow then add aRow and returns True, False otherwise }
    function  AddRow(constref aRow: TRow): Boolean; inline;
  { returns count of columns in removed row }
    function  RemoveRow(constref aRow: TRow): SizeInt; inline;
    function  ContainsCell(constref aRow: TRow; constref aCol: TCol): Boolean;
  { will raise exception if cell is missing }
    function  GetCell(constref aRow: TRow; constref aCol: TCol): TValue;
    function  TryGetCell(constref aRow: TRow; constref aCol: TCol; out aValue: TValue): Boolean;
    function  TryGetCellDef(constref aRow: TRow; constref aCol: TCol; aDef: TValue = Default(TValue)): TValue;
              inline;
    function  GetCellOrDefault(const aRow: TRow; const aCol: TCol): TValue;
    procedure AddOrSetCell(const aRow: TRow; const aCol: TCol; const aValue: TValue);
    function  AddCell(constref aRow: TRow; constref aCol: TCol; constref aValue: TValue): Boolean;
    function  AddCell(constref e: TCellData): Boolean; inline;
    function  AddAll(constref a: array of TCellData): SizeInt;
    function  RemoveCell(const aRow: TRow; const aCol: TCol): Boolean;

    function  RowEnum: IRowEnumerable; virtual; abstract;
    function  RowMapEnum: IRowMapEnumerable; virtual; abstract;
    property  RowCount: SizeInt read GetRowCount;
    property  ColCount[const aRow: TRow]: SizeInt read GetColCount;
    property  CellCount: SizeInt read FCellCount;
    property  Rows[const aRow: TRow]: IRowMap read GetRow;
    property  Columns[const aCol: TCol]: IColDataEnumerable read GetColumn;
    property  CellData: ICellDataEnumerable read GetCellData;
    property  Cells[const aRow: TRow; const aCol: TCol]: TValue read GetCellOrDefault write AddOrSetCell; default;
  end;

implementation
{$B-}{$COPERATORS ON}

{ TGEnumerable }

function TGEnumerable._GetRef: TObject;
begin
  Result := Self;
end;

function TGEnumerable.Reverse: IEnumerable;
begin
  Result := specialize TGArrayReverse<T>.Create(ToArray);
end;

function TGEnumerable.ToArray: TArray;
var
  I, Len: SizeInt;
begin
  Len := ARRAY_INITIAL_SIZE;
  SetLength(Result, ARRAY_INITIAL_SIZE);
  I := 0;
  with GetEnumerator do
    try
      while MoveNext do
        begin
          if I = Len then
            begin
              Len += Len;
              SetLength(Result, Len);
            end;
          Result[I] := Current;
          Inc(I);
        end;
    finally
      Free;
    end;
  SetLength(Result, I);
end;

function TGEnumerable.Any: Boolean;
begin
  with GetEnumerator do
    try
      Result :=  MoveNext;
    finally
      Free;
    end;
end;

function TGEnumerable.None: Boolean;
begin
  Result := not Any;
end;

function TGEnumerable.Total: SizeInt;
begin
  Result := 0;
  with GetEnumerator do
    try
      while MoveNext do
        Inc(Result);
    finally
      Free;
    end;
end;

function TGEnumerable.FindFirst(out aValue: T): Boolean;
var
  e: TCustomEnumerator;
begin
  e := GetEnumerator;
  try
    Result := e.MoveNext;
    if Result then
      aValue := e.Current;
  finally
    e.Free;
  end;
end;

function TGEnumerable.First: TOptional;
var
  v: T;
begin
  if FindFirst(v) then
    Result.Assign(v);
end;

function TGEnumerable.FindLast(out aValue: T): Boolean;
var
  e: TCustomEnumerator;
begin
  e := GetEnumerator;
  try
    Result := e.MoveNext;
    if Result then
      begin
        while e.MoveNext do;
        aValue := e.Current;
      end;
  finally
    e.Free;
  end;
end;

function TGEnumerable.Last: TOptional;
var
  v: T;
begin
  if FindLast(v) then
    Result.Assign(v);
end;

function TGEnumerable.FindMin(out aValue: T; c: TCompare): Boolean;
var
  v: T;
begin
  with GetEnumerator do
    try
      Result := MoveNext;
      if Result then
        begin
          aValue := Current;
          while MoveNext do
            begin
              v := Current;
              if c(v, aValue) < 0 then
                aValue := v;
            end;
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.FindMin(out aValue: T; c: TOnCompare): Boolean;
var
  v: T;
begin
  with GetEnumerator do
    try
      Result := MoveNext;
      if Result then
        begin
          aValue := Current;
          while MoveNext do
            begin
              v := Current;
              if c(v, aValue) < 0 then
                aValue := v;
            end;
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.FindMin(out aValue: T; c: TNestCompare): Boolean;
var
  v: T;
begin
  with GetEnumerator do
    try
      Result := MoveNext;
      if Result then
        begin
          aValue := Current;
          while MoveNext do
            begin
              v := Current;
              if c(v, aValue) < 0 then
                aValue := v;
            end;
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.Min(c: TCompare): TOptional;
var
  v: T;
begin
  if FindMin(v, c) then
    Result.Assign(v);
end;

function TGEnumerable.Min(c: TOnCompare): TOptional;
var
  v: T;
begin
  if FindMin(v, c) then
    Result.Assign(v);
end;

function TGEnumerable.Min(c: TNestCompare): TOptional;
var
  v: T;
begin
  if FindMin(v, c) then
    Result.Assign(v);
end;

function TGEnumerable.FindMax(out aValue: T; c: TCompare): Boolean;
var
  v: T;
begin
  with GetEnumerator do
    try
      Result := MoveNext;
      if Result then
        begin
          aValue := Current;
          while MoveNext do
            begin
              v := Current;
              if c(aValue, v) < 0 then
                aValue := v;
            end;
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.FindMax(out aValue: T; c: TOnCompare): Boolean;
var
  v: T;
begin
  with GetEnumerator do
    try
      Result := MoveNext;
      if Result then
        begin
          aValue := Current;
          while MoveNext do
            begin
              v := Current;
              if c(aValue, v) < 0 then
                aValue := v;
            end;
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.FindMax(out aValue: T; c: TNestCompare): Boolean;
var
  v: T;
begin
  with GetEnumerator do
    try
      Result := MoveNext;
      if Result then
        begin
          aValue := Current;
          while MoveNext do
            begin
              v := Current;
              if c(aValue, v) < 0 then
                aValue := v;
            end;
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.Max(c: TCompare): TOptional;
var
  v: T;
begin
  if FindMax(v, c) then
    Result.Assign(v);
end;

function TGEnumerable.Max(c: TOnCompare): TOptional;
var
  v: T;
begin
  if FindMax(v, c) then
    Result.Assign(v);
end;

function TGEnumerable.Max(c: TNestCompare): TOptional;
var
  v: T;
begin
  if FindMax(v, c) then
    Result.Assign(v);
end;

function TGEnumerable.Skip(aCount: SizeInt): IEnumerable;
begin
  Result := specialize TGSkipEnumerable<T>.Create(GetEnumerator, aCount);
end;

function TGEnumerable.Limit(aCount: SizeInt): IEnumerable;
begin
  Result := specialize TGLimitEnumerable<T>.Create(GetEnumerator, aCount);
end;

function TGEnumerable.Sorted(c: TCompare): IEnumerable;
var
  a: TArray;
begin
  a := ToArray;
  specialize TGRegularArrayHelper<T>.Sort(a, c);
  Result := specialize TGArrayCursor<T>.Create(a);
end;

function TGEnumerable.Sorted(c: TOnCompare): IEnumerable;
var
  a: TArray;
begin
  a := ToArray;
  specialize TGDelegatedArrayHelper<T>.Sort(a, c);
  Result := specialize TGArrayCursor<T>.Create(a);
end;

function TGEnumerable.Sorted(c: TNestCompare): IEnumerable;
var
  a: TArray;
begin
  a := ToArray;
  specialize TGNestedArrayHelper<T>.Sort(a, c);
  Result := specialize TGArrayCursor<T>.Create(a);
end;

function TGEnumerable.Select(aTest: TTest): IEnumerable;
begin
  Result := specialize TGEnumRegularFilter<T>.Create(GetEnumerator, aTest);
end;

function TGEnumerable.Select(aTest: TOnTest): IEnumerable;
begin
  Result := specialize TGEnumDelegatedFilter<T>.Create(GetEnumerator, aTest);
end;

function TGEnumerable.Select(aTest: TNestTest): IEnumerable;
begin
  Result := specialize TGEnumNestedFilter<T>.Create(GetEnumerator, aTest);
end;

function TGEnumerable.Any(aTest: TTest): Boolean;
begin
  with GetEnumerator do
    try
      while MoveNext do
        if aTest(Current) then
          exit(True);
    finally
      Free;
    end;
  Result := False;
end;

function TGEnumerable.Any(aTest: TOnTest): Boolean;
begin
  with GetEnumerator do
    try
      while MoveNext do
        if aTest(Current) then
          exit(True);
    finally
      Free;
    end;
  Result := False;
end;

function TGEnumerable.Any(aTest: TNestTest): Boolean;
begin
  with GetEnumerator do
    try
      while MoveNext do
        if aTest(Current) then
          exit(True);
    finally
      Free;
    end;
  Result := False;
end;

function TGEnumerable.None(aTest: TTest): Boolean;
begin
  Result := not Any(aTest);
end;

function TGEnumerable.None(aTest: TOnTest): Boolean;
begin
  Result := not Any(aTest);
end;

function TGEnumerable.None(aTest: TNestTest): Boolean;
begin
  Result := not Any(aTest);
end;

function TGEnumerable.All(aTest: TTest): Boolean;
begin
  with GetEnumerator do
    try
      while MoveNext do
        if not aTest(Current) then
          exit(False);
    finally
      Free;
    end;
  Result := True;
end;

function TGEnumerable.All(aTest: TOnTest): Boolean;
begin
  with GetEnumerator do
    try
      while MoveNext do
        if not aTest(Current) then
          exit(False);
    finally
      Free;
    end;
  Result := True;
end;

function TGEnumerable.All(aTest: TNestTest): Boolean;
begin
  with GetEnumerator do
    try
      while MoveNext do
        if not aTest(Current) then
          exit(False);
    finally
      Free;
    end;
  Result := True;
end;

function TGEnumerable.Total(aTest: TTest): SizeInt;
begin
  Result := 0;
  with GetEnumerator do
    try
      while MoveNext do
        Result += Ord(aTest(Current));
    finally
      Free;
    end;
end;

function TGEnumerable.Total(aTest: TOnTest): SizeInt;
begin
  Result := 0;
  with GetEnumerator do
    try
      while MoveNext do
        Result += Ord(aTest(Current));
    finally
      Free;
    end;
end;

function TGEnumerable.Total(aTest: TNestTest): SizeInt;
begin
  Result := 0;
  with GetEnumerator do
    try
      while MoveNext do
        Result += Ord(aTest(Current));
    finally
      Free;
    end;
end;

function TGEnumerable.Distinct(c: TCompare): IEnumerable;
begin
  Result := specialize TGArrayCursor<T>.Create(
    specialize TGRegularArrayHelper<T>.SelectDistinct(ToArray, c));
end;

function TGEnumerable.Distinct(c: TOnCompare): IEnumerable;
begin
  Result := specialize TGArrayCursor<T>.Create(
    specialize TGDelegatedArrayHelper<T>.SelectDistinct(ToArray, c));
end;

function TGEnumerable.Distinct(c: TNestCompare): IEnumerable;
begin
  Result := specialize TGArrayCursor<T>.Create(
    specialize TGNestedArrayHelper<T>.SelectDistinct(ToArray, c));
end;

function TGEnumerable.Map(aMap: TMapFunc): IEnumerable;
begin
  Result := specialize TGEnumRegularMap<T>.Create(GetEnumerator, aMap);
end;

function TGEnumerable.Map(aMap: TOnMap): IEnumerable;
begin
  Result := specialize TGEnumDelegatedMap<T>.Create(GetEnumerator, aMap);
end;

function TGEnumerable.Map(aMap: TNestMap): IEnumerable;
begin
  Result := specialize TGEnumNestedMap<T>.Create(GetEnumerator, aMap);
end;

function TGEnumerable.Fold(aFold: TFoldFunc; constref v0: T): T;
begin
  Result := v0;
  with GetEnumerator do
    try
      while MoveNext do
        Result := aFold(Current, Result);
    finally
      Free;
    end;
end;

function TGEnumerable.Fold(aFold: TFoldFunc): TOptional;
var
  v: T;
begin
  with GetEnumerator do
    try
      if MoveNext then
        begin
          v := Current;
          while MoveNext do
            v := aFold(Current, v);
          Result.Assign(v);
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.Fold(aFold: TOnFold; constref v0: T): T;
begin
  Result := v0;
  with GetEnumerator do
    try
      while MoveNext do
        Result := aFold(Current, Result);
    finally
      Free;
    end;
end;

function TGEnumerable.Fold(aFold: TOnFold): TOptional;
var
  v: T;
begin
  with GetEnumerator do
    try
      if MoveNext then
        begin
          v := Current;
          while MoveNext do
            v := aFold(Current, v);
          Result.Assign(v);
        end;
    finally
      Free;
    end;
end;

function TGEnumerable.Fold(aFold: TNestFold; constref v0: T): T;
begin
  Result := v0;
  with GetEnumerator do
    try
      while MoveNext do
        Result := aFold(Current, Result);
    finally
      Free;
    end;
end;

function TGEnumerable.Fold(aFold: TNestFold): TOptional;
var
  v: T;
begin
  with GetEnumerator do
    try
      if MoveNext then
        begin
          v := Current;
          while MoveNext do
            v := aFold(Current, v);
          Result.Assign(v);
        end;
    finally
      Free;
    end;
end;

{$I LGEnumsImpl.inc}

{ TGCustomContainer.TGContainerEnumerator }

constructor TGCustomContainer.TContainerEnumerator.Create(c: TCustomContainer);
begin
  FOwner := c;
end;

destructor TGCustomContainer.TContainerEnumerator.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomContainer.TContainerEnumerable }

constructor TGCustomContainer.TContainerEnumerable.Create(c: TCustomContainer);
begin
  inherited Create;
  FOwner := c;
end;

destructor TGCustomContainer.TContainerEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomContainer }

function TGCustomContainer.GetInIteration: Boolean;
begin
  Result := Boolean(LongBool(FIterationCount));
end;

procedure TGCustomContainer.CapacityExceedError(aValue: SizeInt);
begin
  raise ELGCapacityExceed.CreateFmt(SEClassCapacityExceedFmt, [ClassName, aValue]);
end;

procedure TGCustomContainer.AccessEmptyError;
begin
  raise ELGAccessEmpty.CreateFmt(SEClassAccessEmptyFmt, [ClassName]);
end;

procedure TGCustomContainer.IndexOutOfBoundError(aIndex: SizeInt);
begin
  raise ELGListError.CreateFmt(SEClassIdxOutOfBoundsFmt, [ClassName, aIndex]);
end;

procedure TGCustomContainer.CheckInIteration;
begin
  if InIteration then
    raise ELGUpdateLock.CreateFmt(SECantUpdDuringIterFmt, [ClassName]);
end;

procedure TGCustomContainer.BeginIteration;
begin
  InterlockedIncrement(FIterationCount);
end;

procedure TGCustomContainer.EndIteration;
begin
  InterlockedDecrement(FIterationCount);
end;

procedure TGCustomContainer.CopyItems(aBuffer: PItem);
begin
  with GetEnumerator do
    try
      while MoveNext do
        begin
          aBuffer^ := Current;
          Inc(aBuffer);
        end;
    finally
      Free;
    end;
end;

function TGCustomContainer.GetEnumerator: TCustomEnumerator;
begin
  BeginIteration;
  Result := DoGetEnumerator;
end;

function TGCustomContainer.ToArray: TArray;
var
  c: SizeInt;
begin
  c := Count;
  System.SetLength(Result, c);
  if c > 0 then
    CopyItems(@Result[0]);
end;

function TGCustomContainer.IsEmpty: Boolean;
begin
  Result := GetCount = 0;
end;

function TGCustomContainer.NonEmpty: Boolean;
begin
  Result := GetCount <> 0;
end;

procedure TGCustomContainer.Clear;
begin
  CheckInIteration;
  DoClear;
end;

procedure TGCustomContainer.TrimToFit;
begin
  CheckInIteration;
  DoTrimToFit;
end;

procedure TGCustomContainer.EnsureCapacity(aValue: SizeInt);
begin
  CheckInIteration;
  DoEnsureCapacity(aValue);
end;

{$I LGDynBuffersImpl.inc}

{ TGCustomCollection }

function TGCustomCollection.DoRemove(constref aValue: T): Boolean;
begin
  Result := DoExtract(aValue);
end;

function TGCustomCollection.DoAddAll(constref a: array of T): SizeInt;
var
  v: T;
begin
  Result := 0;
  for v in a do
    Result += Ord(DoAdd(v));
end;

function TGCustomCollection.DoRemoveAll(constref a: array of T): SizeInt;
var
  v: T;
begin
  Result := 0;
  for v in a do
    Result += Ord(DoRemove(v));
end;

function TGCustomCollection.DoRemoveAll(e: IEnumerable): SizeInt;
var
  o: TObject;
  v: T;
begin
  o := e._GetRef;
  if o <> Self then
    begin
      Result := 0;
      for v in e do
        Result += Ord(DoRemove(v));
    end
  else
    begin
      Result := Count;
      DoClear;
    end;
end;

function TGCustomCollection.Add(constref aValue: T): Boolean;
begin
  CheckInIteration;
  Result := DoAdd(aValue);
end;

function TGCustomCollection.AddAll(constref a: array of T): SizeInt;
begin
  CheckInIteration;
  Result := DoAddAll(a);
end;

function TGCustomCollection.AddAll(e: IEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoAddAll(e);
end;

function TGCustomCollection.NonContains(constref aValue: T): Boolean;
begin
  Result := not Contains(aValue);
end;

function TGCustomCollection.ContainsAny(constref a: array of T): Boolean;
var
  v: T;
begin
  for v in a do
    if Contains(v) then
      exit(True);
  Result := False;
end;

function TGCustomCollection.ContainsAny(e: IEnumerable): Boolean;
var
  v: T;
begin
  if e._GetRef <> Self then
    begin
      for v in e do
        if Contains(v) then
          exit(True);
      Result := False;
    end
  else
    Result := not IsEmpty;
end;

function TGCustomCollection.ContainsAll(constref a: array of T): Boolean;
var
  v: T;
begin
  for v in a do
    if NonContains(v) then
      exit(False);
  Result := True;
end;

function TGCustomCollection.ContainsAll(e: IEnumerable): Boolean;
var
  v: T;
begin
  if e._GetRef <> Self then
    for v in e do
      if NonContains(v) then
        exit(False);
  Result := True;
end;

function TGCustomCollection.Remove(constref aValue: T): Boolean;
begin
  CheckInIteration;
  Result := DoRemove(aValue);
end;

function TGCustomCollection.RemoveAll(constref a: array of T): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveAll(a);
end;

function TGCustomCollection.RemoveAll(e: IEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveAll(e);
end;

function TGCustomCollection.RemoveIf(aTest: TTest): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveIf(aTest);
end;

function TGCustomCollection.RemoveIf(aTest: TOnTest): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveIf(aTest);
end;

function TGCustomCollection.RemoveIf(aTest: TNestTest): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveIf(aTest);
end;

function TGCustomCollection.Extract(constref aValue: T): Boolean;
begin
  CheckInIteration;
  Result := DoExtract(aValue);
end;

function TGCustomCollection.ExtractIf(aTest: TTest): TArray;
begin
  CheckInIteration;
  Result := DoExtractIf(aTest);
end;

function TGCustomCollection.ExtractIf(aTest: TOnTest): TArray;
begin
  CheckInIteration;
  Result := DoExtractIf(aTest);
end;

function TGCustomCollection.ExtractIf(aTest: TNestTest): TArray;
begin
  CheckInIteration;
  Result := DoExtractIf(aTest);
end;

procedure TGCustomCollection.RetainAll(aCollection: ICollection);
begin
  if aCollection._GetRef <> Self then
    begin
      CheckInIteration;
      DoRemoveIf(@aCollection.NonContains);
    end;
end;

{ TGThreadCollection }

procedure TGThreadCollection.Lock;
begin
  System.EnterCriticalSection(FLock);
end;

constructor TGThreadCollection.Create(aCollection: ICollection);
begin
  System.InitCriticalSection(FLock);
  FCollection := aCollection;
end;

destructor TGThreadCollection.Destroy;
begin
  Lock;
  try
    FCollection._GetRef.Free;
    inherited;
  finally
    UnLock;
    System.DoneCriticalSection(FLock);
  end;
end;

function TGThreadCollection.LockCollection: ICollection;
begin
  Result := FCollection;
  Lock;
end;

procedure TGThreadCollection.Unlock;
begin
  System.LeaveCriticalSection(FLock);
end;

procedure TGThreadCollection.Clear;
begin
  Lock;
  try
    FCollection.Clear;
  finally
    UnLock;
  end;
end;

function TGThreadCollection.Contains(constref aValue: T): Boolean;
begin
  Lock;
  try
    Result := FCollection.Contains(aValue);
  finally
    UnLock;
  end;
end;

function TGThreadCollection.NonContains(constref aValue: T): Boolean;
begin
  Lock;
  try
    Result := FCollection.NonContains(aValue);
  finally
    UnLock;
  end;
end;

function TGThreadCollection.Add(constref aValue: T): Boolean;
begin
  Lock;
  try
    Result := FCollection.Add(aValue);
  finally
    UnLock;
  end;
end;

function TGThreadCollection.Remove(constref aValue: T): Boolean;
begin
  Lock;
  try
    Result := FCollection.Remove(aValue);
  finally
    UnLock;
  end;
end;

{ TGCustomSet.TExtractHelper }

procedure TGCustomSet.TExtractHelper.OnExtract(p: PEntry);
var
  c: SizeInt;
begin
  c := System.Length(FExtracted);
  if FCurrIndex = c then
    System.SetLength(FExtracted, c shl 1);
  FExtracted[FCurrIndex] := p^.Key;
  Inc(FCurrIndex);
end;

procedure TGCustomSet.TExtractHelper.Init;
begin
  FCurrIndex := 0;
  System.SetLength(FExtracted, ARRAY_INITIAL_SIZE);
end;

function TGCustomSet.TExtractHelper.Final: TArray;
begin
  System.SetLength(FExtracted, FCurrIndex);
  Result := FExtracted;
end;

{ TGCustomSet }

function TGCustomSet.DoAddAll(e: IEnumerable): SizeInt;
var
  v: T;
begin
  if e._GetRef <> Self then
    begin
      Result := 0;
      for v in e do
        Result += Ord(DoAdd(v));
    end
  else
    Result := 0;
end;

procedure TGCustomSet.DoSymmetricSubtract(aSet: TCustomSet);
var
  v: T;
begin
  for v in aSet do
    if not DoRemove(v) then
      DoAdd(v);
end;

function TGCustomSet.IsSuperset(aSet: TCustomSet): Boolean;
begin
  if aSet <> Self then
    begin
      if Count >= aSet.Count then
        Result := ContainsAll(aSet)
      else
        Result := False;
    end
  else
    Result := True;
end;

function TGCustomSet.IsSubset(aSet: TCustomSet): Boolean;
begin
  Result := aSet.IsSuperset(Self);
end;

function TGCustomSet.IsEqual(aSet: TCustomSet): Boolean;
begin
  if aSet <> Self then
    Result := (Count = aSet.Count) and ContainsAll(aSet)
  else
    Result := True;
end;

function TGCustomSet.Intersecting(aSet: TCustomSet): Boolean;
begin
  Result := ContainsAny(aSet);
end;

procedure TGCustomSet.Intersect(aSet: TCustomSet);
begin
  RetainAll(aSet);
end;

procedure TGCustomSet.Join(aSet: TCustomSet);
begin
  AddAll(aSet);
end;

procedure TGCustomSet.Subtract(aSet: TCustomSet);
begin
  RemoveAll(aSet);
end;

procedure TGCustomSet.SymmetricSubtract(aSet: TCustomSet);
begin
  CheckInIteration;
  DoSymmetricSubtract(aSet);
end;

{ TGCustomMultiSet.TExtractor }

procedure TGCustomMultiSet.TExtractHelper.OnExtract(p: PEntry);
var
  I, LastKey: SizeInt;
  Key: T;
begin
  LastKey := Pred(FCurrIndex + p^.Count);
  Key := p^.Key;
  if LastKey >= System.Length(FExtracted) then
      System.SetLength(FExtracted, RoundUpTwoPower(Succ(LastKey)));
  for I := FCurrIndex to LastKey do
    FExtracted[I] := Key;
  FCurrIndex := Succ(LastKey);
end;

procedure TGCustomMultiSet.TExtractHelper.Init;
begin
  FCurrIndex := 0;
  System.SetLength(FExtracted, ARRAY_INITIAL_SIZE);
end;

function TGCustomMultiSet.TExtractHelper.Final: TArray;
begin
  System.SetLength(FExtracted, FCurrIndex);
  Result := FExtracted;
end;

{ TGCustomMultiSet.TIntersectHelper }

function TGCustomMultiSet.TIntersectHelper.OnIntersect(p: PEntry): Boolean;
var
  c, SetCount: SizeInt;
begin
  SetCount := FOtherSet[p^.Key];
  c := p^.Count;
  if SetCount > 0 then
    begin
      Result := False;
      if SetCount < c then
        begin
          FSet.FCount -= c - SetCount;
          p^.Count := SetCount;
        end;
    end
  else
    Result := True;
end;

{ TGCustomMultiSet }

function TGCustomMultiSet.GetCount: SizeInt;
begin
  Result := FCount;
end;

procedure TGCustomMultiSet.DoJoinEntry(constref e: TEntry);
var
  p: PEntry;
begin
{$PUSH}{$Q+}
  if not FindOrAdd(e.Key, p) then
    begin
      p^.Count := e.Count;
      FCount += e.Count;
    end
  else
    if e.Count > p^.Count then
      begin
        FCount += e.Count - p^.Count;
        p^.Count += e.Count - p^.Count;
      end;
{$POP}
end;

procedure TGCustomMultiSet.DoAddEntry(constref e: TEntry);
var
  p: PEntry;
begin
{$PUSH}{$Q+}
  FCount += e.Count;
{$POP}
  if not FindOrAdd(e.Key, p) then
    p^.Count := e.Count
  else
    p^.Count += e.Count;
end;

function TGCustomMultiSet.GetKeyCount(const aKey: T): SizeInt;
var
  p: PEntry;
begin
  p := FindEntry(aKey);
  if p <> nil then
    Result := p^.Count
  else
    Result := 0;
end;

procedure TGCustomMultiSet.SetKeyCount(const aKey: T; aValue: SizeInt);
var
  p: PEntry;
  e: TEntry;
begin
  if aValue < 0 then
    raise EArgumentException.CreateFmt(SECantAcceptNegValueFmt, [ClassName, 'TEntry.Count']);
  CheckInIteration;
  p := FindEntry(aKey);
  if aValue > 0 then
    begin
{$PUSH}{$Q+}
      if FindOrAdd(aKey, p) then
        begin
          FCount += aValue - p^.Count;
          p^.Count := aValue;
        end
      else
        begin
          FCount += aValue;
          p^.Count := aValue;
        end;
{$POP}
    end
  else
    begin  // aValue = 0;
      e.Key := aKey;
      e.Count := High(SizeInt);
      DoSubEntry(e);
    end;
end;

procedure TGCustomMultiSet.DoArithAdd(aSet: TCustomMultiSet);
var
  e: TEntry;
begin
  if aSet <> Self then
    for e in aSet.Entries do
      DoAddEntry(e)
  else
    DoDoubleEntryCounters;
end;

procedure TGCustomMultiSet.DoArithSubtract(aSet: TCustomMultiSet);
var
  e: TEntry;
begin
  if aSet <> Self then
    for e in aSet.Entries do
      DoSubEntry(e)
  else
    Clear;
end;

procedure TGCustomMultiSet.DoSymmSubtract(aSet: TCustomMultiSet);
var
  e: TEntry;
begin
  if aSet <> Self then
    for e in aSet.Entries do
      DoSymmSubEntry(e)
  else
    Clear;
end;

function TGCustomMultiSet.DoAdd(constref aKey: T): Boolean;
var
  p: PEntry;
begin
{$PUSH}{$Q+}
  Inc(FCount);
{$POP}
  if FindOrAdd(aKey, p) then
    Inc(p^.Count);
  Result := True;
end;
function TGCustomMultiSet.DoAddAll(e: IEnumerable): SizeInt;
var
  v: T;
  o: TObject;
begin
  o := e._GetRef;
  if o is TCustomMultiSet then
    begin
      Result := ElemCount;
      DoArithAdd(TCustomMultiSet(o));
      Result := ElemCount - Result;
    end
  else
    begin
      Result := 0;
      for v in e do
        Result += Ord(DoAdd(v));
    end;
end;

function TGCustomMultiSet.DoRemoveAll(e: IEnumerable): SizeInt;
var
  o: TObject;
  v: T;
begin
  o := e._GetRef;
  if o is TCustomMultiSet then
    begin
      Result := ElemCount;
      DoArithSubtract(TCustomMultiSet(o));
      Result -= ElemCount;
    end
  else
    begin
      Result := 0;
      for v in e do
        Result += Ord(DoRemove(v));
    end;
end;

function TGCustomMultiSet.Contains(constref aKey: T): Boolean;
begin
  Result := FindEntry(aKey) <> nil;
end;

function TGCustomMultiSet.IsSuperMultiSet(aSet: TCustomMultiSet): Boolean;
var
  e: TEntry;
begin
  if aSet._GetRef <> Self then
    begin
      if (Count >= aSet.Count) and (EntryCount >= aSet.EntryCount) then
        begin
          for e in aSet.Entries do
            if GetKeyCount(e.Key) < e.Count then
              exit(False);
          Result := True;
        end
      else
        Result := False;
    end
  else
    Result := True;
end;

function TGCustomMultiSet.IsSubMultiSet(aSet: TCustomMultiSet): Boolean;
var
  e: TEntry;
begin
  if aSet._GetRef <> Self then
    begin
      if (aSet.Count >= Count) and (aSet.EntryCount >= EntryCount) then
        begin
          for e in Entries do
            if aSet[e.Key] < e.Count then
              exit(False);
          Result := True;
        end
      else
        Result := False;
    end
  else
    Result := True;
end;

function TGCustomMultiSet.IsEqual(aSet: TCustomMultiSet): Boolean;
var
  e: TEntry;
begin
  if aSet._GetRef <> Self then
    begin
      if (aSet.Count = Count) and (aSet.EntryCount = EntryCount) then
        begin
          for e in Entries do
            if aSet[e.Key] <> e.Count then
              exit(False);
          Result := True;
        end
      else
        Result := False;
    end
  else
    Result := True;
end;

function TGCustomMultiSet.Intersecting(aSet: TCustomMultiSet): Boolean;
begin
  Result := ContainsAny(aSet.Distinct);
end;

procedure TGCustomMultiSet.Intersect(aSet: TCustomMultiSet);
begin
  if aSet <> Self then
    begin
      CheckInIteration;
      DoIntersect(aSet);
    end;
end;

procedure TGCustomMultiSet.Join(aSet: TCustomMultiSet);
var
  e: TEntry;
begin
  if aSet._GetRef <> Self then
    begin
      CheckInIteration;
      for e in aSet.Entries do
        DoJoinEntry(e);
    end;
end;

procedure TGCustomMultiSet.ArithmeticAdd(aSet: TCustomMultiSet);
begin
  CheckInIteration;
  DoArithAdd(aSet);
end;

procedure TGCustomMultiSet.ArithmeticSubtract(aSet: TCustomMultiSet);
begin
  CheckInIteration;
  DoArithSubtract(aSet);
end;

procedure TGCustomMultiSet.SymmetricSubtract(aSet: TCustomMultiSet);
begin
  CheckInIteration;
  DoSymmSubtract(aSet);
end;

function TGCustomMultiSet.Distinct: IEnumerable;
begin
  BeginIteration;
  Result := GetDistinct;
end;

function TGCustomMultiSet.Entries: IEntryEnumerable;
begin
  BeginIteration;
  Result := GetEntries;
end;

{ TCustomIterable }

function TCustomIterable.GetInIteration: Boolean;
begin
  Result := Boolean(LongBool(FIterationCount));
end;

procedure TCustomIterable.CapacityExceedError(aValue: SizeInt);
begin
  raise ELGCapacityExceed.CreateFmt(SEClassCapacityExceedFmt, [ClassName, aValue]);
end;

procedure TCustomIterable.CheckInIteration;
begin
  if InIteration then
    raise ELGUpdateLock.CreateFmt(SECantUpdDuringIterFmt, [ClassName]);
end;

procedure TCustomIterable.BeginIteration;
begin
  InterlockedIncrement(FIterationCount);
end;

procedure TCustomIterable.EndIteration;
begin
  InterlockedDecrement(FIterationCount);
end;

{ TGCustomMap.TExtractHelper }

procedure TGCustomMap.TExtractHelper.OnExtract(p: PEntry);
var
  c: SizeInt;
begin
  c := System.Length(FExtracted);
  if FCurrIndex = c then
    System.SetLength(FExtracted, c shl 1);
  FExtracted[FCurrIndex] := p^;
  Inc(FCurrIndex);
end;

procedure TGCustomMap.TExtractHelper.Init;
begin
  FCurrIndex := 0;
  System.SetLength(FExtracted, ARRAY_INITIAL_SIZE);
end;

function TGCustomMap.TExtractHelper.Final: TEntryArray;
begin
  System.SetLength(FExtracted, FCurrIndex);
  Result := FExtracted;
end;

{ TGCustomMap.TCustomKeyEnumerable }

constructor TGCustomMap.TCustomKeyEnumerable.Create(aMap: TCustomMap);
begin
  inherited Create;
  FOwner := aMap;
end;

destructor TGCustomMap.TCustomKeyEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMap.TCustomValueEnumerable }

constructor TGCustomMap.TCustomValueEnumerable.Create(aMap: TCustomMap);
begin
  inherited Create;
  FOwner := aMap;
end;

destructor TGCustomMap.TCustomValueEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMap.TCustomEntryEnumerable }

constructor TGCustomMap.TCustomEntryEnumerable.Create(aMap: TCustomMap);
begin
  inherited Create;
  FOwner := aMap;
end;

destructor TGCustomMap.TCustomEntryEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMap }

function TGCustomMap._GetRef: TObject;
begin
  Result := Self;
end;

function TGCustomMap.DoRemove(constref aKey: TKey): Boolean;
var
  v: TValue;
begin
  Result := DoExtract(aKey, v);
end;

function TGCustomMap.GetValue(const aKey: TKey): TValue;
begin
  if not TryGetValue(aKey, Result) then
    raise ELGMapError.Create(SEKeyNotFound);
end;

function TGCustomMap.DoSetValue(constref aKey: TKey; constref aNewValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    p^.Value := aNewValue;
end;

function TGCustomMap.DoAdd(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  if Result then
    p^.Value := aValue;
end;

function TGCustomMap.DoAddOrSetValue(const aKey: TKey; const aValue: TValue): Boolean;
var
  p: PEntry;
begin
  Result := not FindOrAdd(aKey, p);
  p^.Value := aValue;
end;

function TGCustomMap.DoAddAll(constref a: array of TEntry): SizeInt;
var
  e: TEntry;
begin
  Result := 0;
  for e in a do
    Result += Ord(DoAdd(e.Key, e.Value));
end;

function TGCustomMap.DoAddAll(e: IEntryEnumerable): SizeInt;
var
  Entry: TEntry;
begin
  Result := 0;
  if e._GetRef <> Self then
    for Entry in e do
      Result += Ord(DoAdd(Entry.Key, Entry.Value));
end;

function TGCustomMap.DoRemoveAll(constref a: array of TKey): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in a do
    Result += Ord(DoRemove(k));
end;

function TGCustomMap.DoRemoveAll(e: IKeyEnumerable): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in e do
    Result += Ord(DoRemove(k));
end;

function TGCustomMap.ToArray: TEntryArray;
var
  I: Integer = 0;
  e: TEntry;
begin
  System.SetLength(Result, Count);
  for e in Entries do
    begin
      Result[I] := e;
      Inc(I);
    end;
end;

function TGCustomMap.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TGCustomMap.NonEmpty: Boolean;
begin
  Result := Count <> 0;
end;

procedure TGCustomMap.Clear;
begin
  CheckInIteration;
  DoClear;
end;

procedure TGCustomMap.EnsureCapacity(aValue: SizeInt);
begin
  CheckInIteration;
  DoEnsureCapacity(aValue);
end;

procedure TGCustomMap.TrimToFit;
begin
  CheckInIteration;
  DoTrimToFit;
end;

function TGCustomMap.TryGetValue(constref aKey: TKey; out aValue: TValue): Boolean;
var
  p: PEntry;
begin
  p := Find(aKey);
  Result := p <> nil;
  if Result then
    aValue := p^.Value;
end;

function TGCustomMap.GetValueDef(constref aKey: TKey; constref aDefault: TValue): TValue;
begin
  if not TryGetValue(aKey, Result) then
    Result := aDefault;
end;

function TGCustomMap.Add(constref aKey: TKey; constref aValue: TValue): Boolean;
begin
  CheckInIteration;
  Result := DoAdd(aKey, aValue);
end;

function TGCustomMap.Add(constref e: TEntry): Boolean;
begin
  Result := Add(e.Key, e.Value);
end;

procedure TGCustomMap.AddOrSetValue(const aKey: TKey; const aValue: TValue);
begin
  CheckInIteration;
  DoAddOrSetValue(aKey, aValue);
end;

function TGCustomMap.AddOrSetValue(constref e: TEntry): Boolean;
begin
  CheckInIteration;
  Result := DoAddOrSetValue(e.Key, e.Value);
end;

function TGCustomMap.AddAll(constref a: array of TEntry): SizeInt;
begin
  CheckInIteration;
  Result := DoAddAll(a);
end;

function TGCustomMap.AddAll(e: IEntryEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoAddAll(e);
end;

function TGCustomMap.Replace(constref aKey: TKey; constref aNewValue: TValue): Boolean;
begin
  CheckInIteration;
  Result := DoSetValue(aKey, aNewValue);
end;

function TGCustomMap.Contains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) <> nil;
end;

function TGCustomMap.ContainsAny(constref a: array of TKey): Boolean;
var
  k: TKey;
begin
  for k in a do
  if Contains(k) then
    exit(True);
  Result := False;
end;

function TGCustomMap.ContainsAny(e: IKeyEnumerable): Boolean;
var
  k: TKey;
begin
  for k in e do
  if Contains(k) then
    exit(True);
  Result := False;
end;

function TGCustomMap.ContainsAll(constref a: array of TKey): Boolean;
var
  k: TKey;
begin
  for k in a do
  if not Contains(k) then
    exit(False);
  Result := True;
end;

function TGCustomMap.ContainsAll(e: IKeyEnumerable): Boolean;
var
  k: TKey;
begin
  for k in e do
  if not Contains(k) then
    exit(False);
  Result := True;
end;

function TGCustomMap.Remove(constref aKey: TKey): Boolean;
begin
  CheckInIteration;
  Result := DoRemove(aKey);
end;

function TGCustomMap.RemoveAll(constref a: array of TKey): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveAll(a);
end;

function TGCustomMap.RemoveAll(e: IKeyEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveAll(e);
end;

function TGCustomMap.RemoveIf(aTest: TKeyTest): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveIf(aTest);
end;

function TGCustomMap.RemoveIf(aTest: TOnKeyTest): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveIf(aTest);
end;

function TGCustomMap.RemoveIf(aTest: TNestKeyTest): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveIf(aTest);
end;

function TGCustomMap.Extract(constref aKey: TKey; out v: TValue): Boolean;
begin
  CheckInIteration;
  Result := DoExtract(aKey, v);
end;

function TGCustomMap.ExtractIf(aTest: TKeyTest): TEntryArray;
begin
  CheckInIteration;
  Result := DoExtractIf(aTest);
end;

function TGCustomMap.ExtractIf(aTest: TOnKeyTest): TEntryArray;
begin
  CheckInIteration;
  Result := DoExtractIf(aTest);
end;

function TGCustomMap.ExtractIf(aTest: TNestKeyTest): TEntryArray;
begin
  CheckInIteration;
  Result := DoExtractIf(aTest);
end;

procedure TGCustomMap.RetainAll(c: IKeyCollection);
begin
  CheckInIteration;
  DoRemoveIf(@c.NonContains);
end;


function TGCustomMap.Keys: IKeyEnumerable;
begin
  BeginIteration;
  Result := GetKeys;
end;

function TGCustomMap.Values: IValueEnumerable;
begin
  BeginIteration;
  Result := GetValues;
end;

function TGCustomMap.Entries: IEntryEnumerable;
begin
  BeginIteration;
  Result := GetEntries;
end;

{ TGCustomMultiMap.TCustomValueSet }

function TGCustomMultiMap.TCustomValueSet.ToArray: TValueArray;
var
  I, Len: SizeInt;
begin
  Len := ARRAY_INITIAL_SIZE;
  SetLength(Result, ARRAY_INITIAL_SIZE);
  I := 0;
  with GetEnumerator do
    try
      while MoveNext do
        begin
          if I = Len then
            begin
              Len += Len;
              SetLength(Result, Len);
            end;
          Result[I] := Current;
          Inc(I);
        end;
    finally
      Free;
    end;
  SetLength(Result, I);
end;

{ TGCustomMultiMap.TCustomKeyEnumerable }

constructor TGCustomMultiMap.TCustomKeyEnumerable.Create(aMap: TCustomMultiMap);
begin
  inherited Create;
  FOwner := aMap;
end;

destructor TGCustomMultiMap.TCustomKeyEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMultiMap.TCustomValueEnumerable }

constructor TGCustomMultiMap.TCustomValueEnumerable.Create(aMap: TCustomMultiMap);
begin
  inherited Create;
  FOwner := aMap;
end;

destructor TGCustomMultiMap.TCustomValueEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMultiMap.TCustomEntryEnumerable }

constructor TGCustomMultiMap.TCustomEntryEnumerable.Create(aMap: TCustomMultiMap);
begin
  inherited Create;
  FOwner := aMap;
end;

destructor TGCustomMultiMap.TCustomEntryEnumerable.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMultiMap.TCustomValueCursor }

constructor TGCustomMultiMap.TCustomValueCursor.Create(e: TCustomEnumerator; aMap: TCustomMultiMap);
begin
  inherited Create(e);
  FOwner := aMap;
end;

destructor TGCustomMultiMap.TCustomValueCursor.Destroy;
begin
  FOwner.EndIteration;
  inherited;
end;

{ TGCustomMultiMap }

function TGCustomMultiMap.DoAdd(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  p: PMMEntry;
begin
  p := FindOrAdd(aKey);
  Result := p^.Values.Add(aValue);
  FCount += Ord(Result);
end;

function TGCustomMultiMap.DoAddAll(constref a: array of TEntry): SizeInt;
var
  e: TEntry;
begin
  Result := 0;
  for e in a do
    Result += Ord(DoAdd(e.Key, e.Value));
end;

function TGCustomMultiMap.DoAddAll(e: IEntryEnumerable): SizeInt;
var
  Entry: TEntry;
begin
  Result := 0;
  for Entry in e do
    Result += Ord(DoAdd(Entry.Key, Entry.Value));
end;

function TGCustomMultiMap.DoAddValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
var
  p: PMMEntry;
  v: TValue;
begin
  Result := 0;
  if System.Length(a) > 0 then
    begin
      p := FindOrAdd(aKey);
      for v in a do
        Result += Ord(p^.Values.Add(v));
      FCount += Result;
    end;
end;

function TGCustomMultiMap.DoAddValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
var
  p: PMMEntry = nil;
  v: TValue;
begin
  Result := 0;
  for v in e do
    begin
      if p = nil then
        p := FindOrAdd(aKey);
      Result += Ord(p^.Values.Add(v));
    end;
  FCount += Result;
end;

function TGCustomMultiMap.DoRemove(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  p: PMMEntry;
begin
  p := Find(aKey);
  if p <> nil then
    begin
      Result := p^.Values.Remove(aValue);
      FCount -= Ord(Result);
      if p^.Values.Count = 0 then
        DoRemoveKey(aKey);
    end
  else
    Result := False;
end;

function TGCustomMultiMap.DoRemoveAll(constref a: array of TEntry): SizeInt;
var
  e: TEntry;
begin
  Result := 0;
  for e in a do
    Result += Ord(DoRemove(e.Key, e.Value));
end;

function TGCustomMultiMap.DoRemoveAll(e: IEntryEnumerable): SizeInt;
var
  Entry: TEntry;
begin
  Result := 0;
  for Entry in e do
    Result += Ord(DoRemove(Entry.Key, Entry.Value));
end;

function TGCustomMultiMap.DoRemoveValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
var
  p: PMMEntry;
  v: TValue;
begin
  p := Find(aKey);
  Result := 0;
  if p <> nil then
    begin
      for v in a do
        Result += Ord( p^.Values.Remove(v));
      FCount -= Result;
      if p^.Values.Count = 0 then
        DoRemoveKey(aKey);
    end;
end;

function TGCustomMultiMap.DoRemoveValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
var
  p: PMMEntry;
  v: TValue;
begin
  p := Find(aKey);
  Result := 0;
  if p <> nil then
    begin
      for v in e do
        Result += Ord( p^.Values.Remove(v));
      FCount -= Result;
      if p^.Values.Count = 0 then
        DoRemoveKey(aKey);
    end;
end;

function TGCustomMultiMap.DoRemoveKeys(constref a: array of TKey): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in a do
    Result += DoRemoveKey(k);
  FCount -= Result;
end;

function TGCustomMultiMap.DoRemoveKeys(e: IKeyEnumerable): SizeInt;
var
  k: TKey;
begin
  Result := 0;
  for k in e do
    Result += DoRemoveKey(k);
  FCount -= Result;
end;

function TGCustomMultiMap.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TGCustomMultiMap.NonEmpty: Boolean;
begin
  Result := Count <> 0;
end;

procedure TGCustomMultiMap.Clear;
begin
  CheckInIteration;
  DoClear;
  FCount := 0;
end;

procedure TGCustomMultiMap.EnsureCapacity(aValue: SizeInt);
begin
  CheckInIteration;
  DoEnsureCapacity(aValue);
end;

procedure TGCustomMultiMap.TrimToFit;
begin
  CheckInIteration;
  DoTrimToFit;
end;

function TGCustomMultiMap.Contains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) <> nil;
end;

function TGCustomMultiMap.ContainsValue(constref aKey: TKey; constref aValue: TValue): Boolean;
var
  p: PMMEntry;
begin
  p := Find(aKey);
  if p <> nil then
    Result := p^.Values.Contains(aValue)
  else
    Result := False;
end;

function TGCustomMultiMap.Add(constref aKey: TKey; constref aValue: TValue): Boolean;
begin
  CheckInIteration;
  Result := DoAdd(aKey, aValue);
end;

function TGCustomMultiMap.Add(constref e: TEntry): Boolean;
begin
  Result := Add(e.Key, e.Value);
end;

function TGCustomMultiMap.AddAll(constref a: array of TEntry): SizeInt;
begin
  CheckInIteration;
  Result := DoAddAll(a);
end;

function TGCustomMultiMap.AddAll(e: IEntryEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoAddAll(e);
end;

function TGCustomMultiMap.AddValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
begin
  CheckInIteration;
  Result := DoAddValues(aKey, a);
end;

function TGCustomMultiMap.AddValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoAddValues(aKey, e);
end;

function TGCustomMultiMap.Remove(constref aKey: TKey; constref aValue: TValue): Boolean;
begin
  CheckInIteration;
  Result := DoRemove(aKey, aValue);
end;

function TGCustomMultiMap.Remove(constref e: TEntry): Boolean;
begin
  Result := Remove(e.Key, e.Value);
end;

function TGCustomMultiMap.RemoveAll(constref a: array of TEntry): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveAll(a);
end;

function TGCustomMultiMap.RemoveAll(e: IEntryEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveAll(e);
end;

function TGCustomMultiMap.RemoveValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveValues(aKey, a);
end;

function TGCustomMultiMap.RemoveValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveValues(aKey, e);
end;

function TGCustomMultiMap.RemoveKey(constref aKey: TKey): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveKey(aKey);
  FCount -= Result;
end;

function TGCustomMultiMap.RemoveKeys(constref a: array of TKey): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveKeys(a);
end;

function TGCustomMultiMap.RemoveKeys(e: IKeyEnumerable): SizeInt;
begin
  CheckInIteration;
  Result := DoRemoveKeys(e);
end;

function TGCustomMultiMap.CopyValues(const aKey: TKey): TValueArray;
var
  p: PMMEntry;
begin
  p := Find(aKey);
  if p <> nil then
    Result := p^.Values.ToArray
  else
    Result := nil;
end;

function TGCustomMultiMap.ViewValues(const aKey: TKey): IValueEnumerable;
var
  p: PMMEntry;
begin
  p := Find(aKey);
  if p <> nil then
    begin
      BeginIteration;
      Result := TCustomValueCursor.Create(p^.Values.GetEnumerator, Self);
    end
  else
    Result := specialize TGArrayCursor<TValue>.Create(nil);
end;

function TGCustomMultiMap.Keys: IKeyEnumerable;
begin
  BeginIteration;
  Result := GetKeys;
end;

function TGCustomMultiMap.Values: IValueEnumerable;
begin
  BeginIteration;
  Result := GetValues;
end;

function TGCustomMultiMap.Entries: IEntryEnumerable;
begin
  BeginIteration;
  Result := GetEntries;
end;

function TGCustomMultiMap.ValueCount(constref aKey: TKey): SizeInt;
var
  p: PMMEntry;
begin
  p := Find(aKey);
  if p <> nil then
    Result := p^.Values.Count
  else
    Result := 0;
end;

{ TGCustomTable2D.TCustomRowMap }

function TGCustomTable2D.TCustomRowMap.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TGCustomTable2D.TCustomRowMap.GetValueOrDefault(const aCol: TCol): TValue;
begin
  if not TryGetValue(aCol, Result) then
    Result := Default(TValue);
end;

{ TGCustomTable2D }

function TGCustomTable2D.GetColCount(const aRow: TRow): SizeInt;
var
  p: PRowEntry;
begin
  p := DoFindRow(aRow);
  if p <> nil then
    Result := p^.Columns.Count
  else
    Result := 0;
end;

function TGCustomTable2D.GetRow(const aRow: TRow): IRowMap;
var
  p: PRowEntry;
begin
  DoFindOrAddRow(aRow, p);
  Result := p^.Columns;
end;

function TGCustomTable2D.IsEmpty: Boolean;
begin
  Result := CellCount = 0;
end;

function TGCustomTable2D.NonEmpty: Boolean;
begin
  Result := CellCount <> 0;
end;

function TGCustomTable2D.ContainsRow(constref aRow: TRow): Boolean;
begin
  Result := DoFindRow(aRow) <> nil;
end;

function TGCustomTable2D.FindRow(constref aRow: TRow; out aMap: IRowMap): Boolean;
var
  p: PRowEntry;
begin
  p := DoFindRow(aRow);
  Result := p <> nil;
  if Result then
    aMap := p^.Columns;
end;

function TGCustomTable2D.FindOrAddRow(constref aRow: TRow; out aMap: IRowMap): Boolean;
var
  p: PRowEntry;
begin
  Result := DoFindOrAddRow(aRow, p);
  aMap := p^.Columns;
end;

function TGCustomTable2D.AddRow(constref aRow: TRow): Boolean;
var
  p: PRowEntry;
begin
  Result := not DoFindOrAddRow(aRow, p);
end;

function TGCustomTable2D.RemoveRow(constref aRow: TRow): SizeInt;
begin
  Result := DoRemoveRow(aRow);
end;

function TGCustomTable2D.ContainsCell(constref aRow: TRow; constref aCol: TCol): Boolean;
var
  p: PRowEntry;
begin
  p := DoFindRow(aRow);
  if p <> nil then
    Result := p^.Columns.Contains(aCol)
  else
    Result := False;
end;

function TGCustomTable2D.GetCell(constref aRow: TRow; constref aCol: TCol): TValue;
begin
  if not TryGetCell(aRow, aCol, Result) then
    raise ELGTableError.CreateFmt(SECellNotFoundFmt, [ClassName]);
end;

function TGCustomTable2D.TryGetCell(constref aRow: TRow; constref aCol: TCol; out aValue: TValue): Boolean;
var
  p: PRowEntry;
begin
  p := DoFindRow(aRow);
  if p <> nil then
    Result := p^.Columns.TryGetValue(aCol, aValue)
  else
    Result := False;
end;

function TGCustomTable2D.GetCellOrDefault(const aRow: TRow; const aCol: TCol): TValue;
begin
  if not TryGetCell(aRow, aCol, Result) then
    Result := Default(TValue);
end;

function TGCustomTable2D.TryGetCellDef(constref aRow: TRow; constref aCol: TCol; aDef: TValue): TValue;
begin
  if not TryGetCell(aRow, aCol, Result) then
    Result := aDef;
end;

procedure TGCustomTable2D.AddOrSetCell(const aRow: TRow; const aCol: TCol; const aValue: TValue);
var
  p: PRowEntry;
begin
  DoFindOrAddRow(aRow, p);
  p^.Columns[aCol] := aValue;
end;

function TGCustomTable2D.AddCell(constref aRow: TRow; constref aCol: TCol; constref aValue: TValue): Boolean;
begin
  Result := not ContainsCell(aRow, aCol);
  if Result then
    AddOrSetCell(aRow, aCol, aValue);
end;

function TGCustomTable2D.AddCell(constref e: TCellData): Boolean;
begin
  Result := AddCell(e.Row, e.Column, e.Value);
end;

function TGCustomTable2D.AddAll(constref a: array of TCellData): SizeInt;
var
  e: TCellData;
begin
  Result := 0;
  for e in a do
    Result += Ord(AddCell(e));
end;

function TGCustomTable2D.RemoveCell(const aRow: TRow; const aCol: TCol): Boolean;
var
  p: PRowEntry;
begin
  p := DoFindRow(aRow);
  if p <> nil then
    begin
      Result := p^.Columns.Remove(aCol);
      if Result and p^.Columns.IsEmpty then
        DoRemoveRow(aRow);
    end
  else
    Result := False;
end;

end.

