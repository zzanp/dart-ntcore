import 'dart:ffi';

import 'package:ffi/ffi.dart';

class NTValue extends Struct {
  @Int32()
  external int type;
  @Int64()
  external int lastChange;
  @Int64()
  external int serverTime;
  external ValueUnion data;
}

class ValueUnion extends Union {
  @Int()
  external int boolean;
  @Int64()
  external int integer;
  @Float()
  external double float;
  @Double()
  external double doubleType;
  external ValueString string;
  external ValueRaw raw;
  external ArrBoolean booleanArray;
  external ArrDouble doubleArray;
  external ArrFloat floatArray;
  external ArrInt intArray;
  external ArrString stringArray;
}

class ValueString extends Struct {
  external Pointer<Utf8> data;

  @Size()
  external int size;
}

class ValueRaw extends Struct {
  external Pointer<Uint8> data;

  @Size()
  external int size;
}

class ArrBoolean extends Struct {
  external Pointer<Int32> arr;

  @Size()
  external int size;
}

class ArrDouble extends Struct {
  external Pointer<Double> arr;

  @Size()
  external int size;
}

class ArrFloat extends Struct {
  external Pointer<Float> arr;

  @Size()
  external int size;
}

class ArrInt extends Struct {
  external Pointer<Int64> arr;

  @Size()
  external int size;
}

class ArrString extends Struct {
  external Pointer<ValueString> arr;

  @Size()
  external int size;
}
