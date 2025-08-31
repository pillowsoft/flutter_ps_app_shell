// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SettingsStore on _SettingsStore, Store {
  Computed<Rect>? _$windowPlacementComputed;

  @override
  Rect get windowPlacement =>
      (_$windowPlacementComputed ??= Computed<Rect>(() => super.windowPlacement,
              name: '_SettingsStore.windowPlacement'))
          .value;

  late final _$onboardingSeenAtom =
      Atom(name: '_SettingsStore.onboardingSeen', context: context);

  @override
  bool get onboardingSeen {
    _$onboardingSeenAtom.reportRead();
    return super.onboardingSeen;
  }

  @override
  set onboardingSeen(bool value) {
    _$onboardingSeenAtom.reportWrite(value, super.onboardingSeen, () {
      super.onboardingSeen = value;
    });
  }

  late final _$windowTopAtom =
      Atom(name: '_SettingsStore.windowTop', context: context);

  @override
  double? get windowTop {
    _$windowTopAtom.reportRead();
    return super.windowTop;
  }

  @override
  set windowTop(double? value) {
    _$windowTopAtom.reportWrite(value, super.windowTop, () {
      super.windowTop = value;
    });
  }

  late final _$windowLeftAtom =
      Atom(name: '_SettingsStore.windowLeft', context: context);

  @override
  double? get windowLeft {
    _$windowLeftAtom.reportRead();
    return super.windowLeft;
  }

  @override
  set windowLeft(double? value) {
    _$windowLeftAtom.reportWrite(value, super.windowLeft, () {
      super.windowLeft = value;
    });
  }

  late final _$windowWidthAtom =
      Atom(name: '_SettingsStore.windowWidth', context: context);

  @override
  double? get windowWidth {
    _$windowWidthAtom.reportRead();
    return super.windowWidth;
  }

  @override
  set windowWidth(double? value) {
    _$windowWidthAtom.reportWrite(value, super.windowWidth, () {
      super.windowWidth = value;
    });
  }

  late final _$windowHeightAtom =
      Atom(name: '_SettingsStore.windowHeight', context: context);

  @override
  double? get windowHeight {
    _$windowHeightAtom.reportRead();
    return super.windowHeight;
  }

  @override
  set windowHeight(double? value) {
    _$windowHeightAtom.reportWrite(value, super.windowHeight, () {
      super.windowHeight = value;
    });
  }

  late final _$brightnessAtom =
      Atom(name: '_SettingsStore.brightness', context: context);

  @override
  Brightness get brightness {
    _$brightnessAtom.reportRead();
    return super.brightness;
  }

  @override
  set brightness(Brightness value) {
    _$brightnessAtom.reportWrite(value, super.brightness, () {
      super.brightness = value;
    });
  }

  late final _$themeModeAtom =
      Atom(name: '_SettingsStore.themeMode', context: context);

  @override
  ThemeMode get themeMode {
    _$themeModeAtom.reportRead();
    return super.themeMode;
  }

  @override
  set themeMode(ThemeMode value) {
    _$themeModeAtom.reportWrite(value, super.themeMode, () {
      super.themeMode = value;
    });
  }

  late final _$setOnboardingSeenAsyncAction =
      AsyncAction('_SettingsStore.setOnboardingSeen', context: context);

  @override
  Future<void> setOnboardingSeen(bool value) {
    return _$setOnboardingSeenAsyncAction
        .run(() => super.setOnboardingSeen(value));
  }

  late final _$setWindowTopAsyncAction =
      AsyncAction('_SettingsStore.setWindowTop', context: context);

  @override
  Future<void> setWindowTop(double? value) {
    return _$setWindowTopAsyncAction.run(() => super.setWindowTop(value));
  }

  late final _$setWindowLeftAsyncAction =
      AsyncAction('_SettingsStore.setWindowLeft', context: context);

  @override
  Future<void> setWindowLeft(double? value) {
    return _$setWindowLeftAsyncAction.run(() => super.setWindowLeft(value));
  }

  late final _$setWindowWidthAsyncAction =
      AsyncAction('_SettingsStore.setWindowWidth', context: context);

  @override
  Future<void> setWindowWidth(double? value) {
    return _$setWindowWidthAsyncAction.run(() => super.setWindowWidth(value));
  }

  late final _$setWindowHeightAsyncAction =
      AsyncAction('_SettingsStore.setWindowHeight', context: context);

  @override
  Future<void> setWindowHeight(double? value) {
    return _$setWindowHeightAsyncAction.run(() => super.setWindowHeight(value));
  }

  late final _$setBrightnessAsyncAction =
      AsyncAction('_SettingsStore.setBrightness', context: context);

  @override
  Future<void> setBrightness(Brightness value) {
    return _$setBrightnessAsyncAction.run(() => super.setBrightness(value));
  }

  late final _$setThemeModeAsyncAction =
      AsyncAction('_SettingsStore.setThemeMode', context: context);

  @override
  Future<void> setThemeMode(ThemeMode value) {
    return _$setThemeModeAsyncAction.run(() => super.setThemeMode(value));
  }

  @override
  String toString() {
    return '''
onboardingSeen: ${onboardingSeen},
windowTop: ${windowTop},
windowLeft: ${windowLeft},
windowWidth: ${windowWidth},
windowHeight: ${windowHeight},
brightness: ${brightness},
themeMode: ${themeMode},
windowPlacement: ${windowPlacement}
    ''';
  }
}
