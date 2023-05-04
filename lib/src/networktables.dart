import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:ntcore/src/value.dart';

class NetworkTables {
  late DynamicLibrary _dylib;
  late int _instance;
  final Map<String, int> _entryCache = <String, int>{};

  NetworkTables() {
    var dllName = 'libntcore.so';
    dllName = Platform.isMacOS ? 'libntcore.dylib' : dllName;
    dllName = Platform.isWindows ? 'ntcore.dll' : dllName;

    _dylib = DynamicLibrary.open(dllName);
    _instance = _getDefaultInstance();
  }

  int _getDefaultInstance() =>
      _dylib.lookupFunction<Uint32 Function(), int Function()>(
          'NT_GetDefaultInstance')();

  // TODO: Move [Entry] functions to separate class

  int _getEntry(String name) {
    if (_entryCache.containsKey(name)) return _entryCache[name]!;
    final namePointer = name.toNativeUtf8();
    final func = _dylib.lookupFunction<
        Uint32 Function(Uint32, Pointer<Utf8>, Size),
        int Function(int, Pointer<Utf8>, int)>('NT_GetEntry');
    _entryCache[name] = func(_instance, namePointer, name.length);
    return _entryCache[name]!;
  }

  NTValue _getValue(int entry) {
    final val = calloc<NTValue>();
    final func = _dylib.lookupFunction<Void Function(Uint32, Pointer<NTValue>),
        void Function(int, Pointer<NTValue>)>('NT_GetEntryValue');
    func(entry, val);
    final ret = val.ref;
    malloc.free(val);
    return ret;
  }

  void _setValue(int entry, Pointer<NTValue> value) {
    value.ref
      ..lastChange = 0
      ..serverTime = 0;
    final q = value.ref;
    print(DateTime.now().microsecondsSinceEpoch);
    final func = _dylib.lookupFunction<Int Function(Uint32, Pointer<NTValue>),
        int Function(int, Pointer<NTValue>)>('NT_SetEntryValue');
    print(func(entry, value));
  }

  ValueUnion _getDataFromPath(String name) {
    final entry = _getEntry(name);
    final value = _getValue(entry);
    return value.data;
  }

  void startClient3(String clientName) {
    final namePointer = clientName.toNativeUtf8();
    _dylib.lookupFunction<
        Void Function(Uint32, Pointer<Utf8>),
        void Function(
            int, Pointer<Utf8>)>('NT_StartClient3')(_instance, namePointer);
    malloc.free(namePointer);
  }

  void startClient4(String clientName) {
    final namePointer = clientName.toNativeUtf8();
    _dylib.lookupFunction<
        Void Function(Uint32, Pointer<Utf8>),
        void Function(
            int, Pointer<Utf8>)>('NT_StartClient4')(_instance, namePointer);
    malloc.free(namePointer);
  }

  void setServerTeam(int team, int port) {
    _dylib.lookupFunction<
        Void Function(Uint32, Uint32, Uint32),
        void Function(
            int, int, int)>('NT_SetServerTeam')(_instance, team, port);
  }

  void startDSClient(int port) => _dylib.lookupFunction<
      Void Function(Uint32, Uint32),
      void Function(int, int)>('NT_StartDSClient')(_instance, port);

  void setServer(String serverName, int port) {
    final serverPointer = serverName.toNativeUtf8();
    _dylib.lookupFunction<Void Function(Uint32, Pointer<Utf8>, Uint32),
            void Function(int, Pointer<Utf8>, int)>('NT_SetServer')(
        _instance, serverPointer, port);
    malloc.free(serverPointer);
  }

  void stopClient() =>
      _dylib.lookupFunction<Void Function(Uint32), void Function(int)>(
          'NT_StopClient')(_instance);

  void stopDSClient() =>
      _dylib.lookupFunction<Void Function(Uint32), void Function(int)>(
          'NT_StopDSClient')(_instance);

  bool getBoolean(String name) {
    return _getDataFromPath(name).boolean >= 1 ? true : false;
  }

  List<int> getData(String name) {
    final data = _getDataFromPath(name).raw;
    return data.data.asTypedList(data.size);
  }

  double getDouble(String name) {
    return _getDataFromPath(name).doubleType;
  }

  double getFloat(String name) {
    return _getDataFromPath(name).float;
  }

  int getInteger(String name) {
    return _getDataFromPath(name).integer;
  }

  String getString(String name) {
    final data = _getDataFromPath(name).string;
    return data.data.toDartString(length: data.size);
  }

  List<bool> getBooleanArray(String name) {
    final data = _getDataFromPath(name).booleanArray;
    return data.arr
        .asTypedList(data.size)
        .map((e) => e >= 1 ? true : false)
        .toList();
  }

  List<double> getDoubleArray(String name) {
    final data = _getDataFromPath(name).doubleArray;
    return data.arr.asTypedList(data.size);
  }

  List<double> getFloatArray(String name) {
    final data = _getDataFromPath(name).floatArray;
    return data.arr.asTypedList(data.size);
  }

  List<int> getIntegerArray(String name) {
    final data = _getDataFromPath(name).intArray;
    return data.arr.asTypedList(data.size);
  }

  List<String> getStringArray(String name) {
    final ret = <String>[];
    final data = _getDataFromPath(name).stringArray;
    for (var i = 0; i < data.size; i++) {
      final el = data.arr.elementAt(i).ref;
      ret.add(el.data.toDartString(length: el.size));
    }
    return ret;
  }

  void setBoolean(String name, bool value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    val.ref
      ..type = 0x01
      ..data.boolean = value ? 1 : 0;
    _setValue(entry, val);
    malloc.free(val);
  }

  void setDouble(String name, double value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    val.ref
      ..type = 0x02
      ..data.doubleType = value;
    _setValue(entry, val);
    malloc.free(val);
  }

  void setFloat(String name, double value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    val.ref
      ..type = 0x200
      ..data.float = value;
    _setValue(entry, val);
    malloc.free(val);
  }

  void setInteger(String name, int value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    val.ref
      ..type = 0x100
      ..data.integer = value;
    _setValue(entry, val);
    malloc.free(val);
  }

  void setString(String name, String value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    final stringValue = calloc<ValueString>();
    stringValue.ref
      ..data = value.toNativeUtf8()
      ..size = value.length;
    val.ref
      ..type = 0x04
      ..data.string = stringValue.ref;
    _setValue(entry, val);
    malloc.free(stringValue);
    malloc.free(val);
  }

  void setBooleanArray(String name, List<bool> value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    final arrayValue = malloc.allocate<Int32>(sizeOf<Int32>() * value.length);
    for (var i = 0; i < value.length; i++) {
      arrayValue.elementAt(i).value = value[i] ? 1 : 0;
    }
    final bval = calloc<ArrBoolean>()
      ..ref.arr = arrayValue
      ..ref.size = value.length;
    val.ref
      ..type = 0x10
      ..data.booleanArray = bval.ref;
    _setValue(entry, val);
    malloc.free(bval);
    malloc.free(arrayValue);
    malloc.free(val);
  }

  void setDoubleArray(String name, List<double> value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    final arrayValue = malloc.allocate<Double>(sizeOf<Double>() * value.length);
    for (var i = 0; i < value.length; i++) {
      arrayValue.elementAt(i).value = value[i];
    }
    final dval = calloc<ArrDouble>()
      ..ref.arr = arrayValue
      ..ref.size = value.length;
    val.ref
      ..type = 0x20
      ..data.doubleArray = dval.ref;
    _setValue(entry, val);
    malloc.free(dval);
    malloc.free(arrayValue);
    malloc.free(val);
  }

  void setFloatArray(String name, List<double> value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    final arrayValue = malloc.allocate<Float>(sizeOf<Float>() * value.length);
    for (var i = 0; i < value.length; i++) {
      arrayValue.elementAt(i).value = value[i];
    }
    final fval = calloc<ArrFloat>()
      ..ref.arr = arrayValue
      ..ref.size = value.length;
    val.ref
      ..type = 0x800
      ..data.floatArray = fval.ref;
    _setValue(entry, val);
    malloc.free(fval);
    malloc.free(arrayValue);
    malloc.free(val);
  }

  void setIntegerArray(String name, List<int> value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    final arrayValue = malloc.allocate<Int64>(sizeOf<Int64>() * value.length);
    for (var i = 0; i < value.length; i++) {
      arrayValue.elementAt(i).value = value[i];
    }
    final ival = calloc<ArrInt>()
      ..ref.arr = arrayValue
      ..ref.size = value.length;
    val.ref
      ..type = 0x400
      ..data.intArray = ival.ref;
    _setValue(entry, val);
    malloc.free(ival);
    malloc.free(arrayValue);
    malloc.free(val);
  }

  void setStringArray(String name, List<String> value) {
    final entry = _getEntry(name);
    final val = calloc<NTValue>();
    final arrayValue =
        malloc.allocate<ValueString>(sizeOf<ValueString>() * value.length);
    for (var i = 0; i < value.length; i++) {
      arrayValue.elementAt(i).ref
        ..data = value[i].toNativeUtf8()
        ..size = value.length;
    }
    final sval = calloc<ArrString>()
      ..ref.arr = arrayValue
      ..ref.size = value.length;
    val.ref
      ..type = 0x40
      ..data.stringArray = sval.ref;
    _setValue(entry, val);
    malloc.free(sval);
    malloc.free(arrayValue);
    malloc.free(val);
  }
}
