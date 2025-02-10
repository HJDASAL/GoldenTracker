import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../styles/index.dart';

const double kMobileBreakpoint = 450.0;
const double kTabletBreakpoint = 850.0;

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({
    super.key,
    required this.child,
    this.colorSchemes = const {},
    this.initialColorScheme = 'light',
    this.onChangeColorScheme,
  });

  final Widget child;
  final String initialColorScheme;
  final Map<String, ColorScheme> colorSchemes;
  final void Function(ColorScheme)? onChangeColorScheme;

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();

  static LayoutProvider of(BuildContext context) {
    final LayoutProvider? inheritedContext =
        context.dependOnInheritedWidgetOfExactType<LayoutProvider>();

    assert(
      inheritedContext != null,
      'No LayoutProvider found in context',
    );

    return inheritedContext!;
  }

  static Layout layoutOf(BuildContext context) {
    final LayoutProvider? inheritedContext =
        context.dependOnInheritedWidgetOfExactType<LayoutProvider>();

    assert(
      inheritedContext != null,
      'No LayoutContextProvider found in context',
    );

    return inheritedContext!.layout;
  }
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  late Layout _layout;
  late final Map<String, ColorScheme> _colorSchemes;

  @override
  void initState() {
    super.initState();

    _colorSchemes = widget.colorSchemes.isEmpty
        ? {'light': kLightTheme}
        : widget.colorSchemes;

    _layout = Layout(
      deviceType: DeviceType.mobile,
      orientation: Orientation.portrait,
      platform: Platform.of(context),
      gestureDevice: GestureDevice.unknown,
      colorSchemeName: widget.initialColorScheme,
      size: Size(kTabletBreakpoint, kMobileBreakpoint),
    );
  }

  void _updateGestureDevice(PointerEvent event) {
    GestureDevice detectedDevice;

    if (event.kind == PointerDeviceKind.mouse) {
      detectedDevice = GestureDevice.mouse;
    } else if (event.kind == PointerDeviceKind.touch) {
      detectedDevice = GestureDevice.touch;
    } else if (event.kind == PointerDeviceKind.stylus) {
      detectedDevice = GestureDevice.stylus;
    } else {
      detectedDevice = GestureDevice.unknown;
    }

    if (detectedDevice != _layout.gestureDevice) {
      setState(() {
        _layout = _layout.copyWith(gestureDevice: detectedDevice);
      });
    }
  }

  void _updateLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final constraints = mediaQuery.size;

    DeviceType deviceType;
    if (constraints.width < kMobileBreakpoint) {
      deviceType = DeviceType.mobile;
    } else if (constraints.width < kTabletBreakpoint) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.desktop;
    }

    setState(() {
      _layout = _layout.copyWith(
        deviceType: deviceType,
        orientation: mediaQuery.orientation,
        size: mediaQuery.size,
      );
    });
  }

  void _updateColorScheme(String schemeKey) {
    if (_colorSchemes.containsKey(schemeKey)) {
      widget.onChangeColorScheme?.call(_colorSchemes[schemeKey]!);
      _layout = _layout.copyWith(colorSchemeName: schemeKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateLayout(context);

    return Listener(
      onPointerDown: _updateGestureDevice,
      onPointerHover: _updateGestureDevice,
      onPointerSignal: _updateGestureDevice,
      child: LayoutProvider(
        changeColorScheme: _updateColorScheme,
        layout: _layout,
        child: widget.child,
      ),
    );
  }
}

class LayoutProvider extends InheritedWidget {
  final Layout layout;
  final void Function(String) changeColorScheme;

  const LayoutProvider({
    super.key,
    required super.child,
    required this.layout,
    required this.changeColorScheme,
  });

  static LayoutProvider of(BuildContext context) {
    final LayoutProvider? result =
        context.dependOnInheritedWidgetOfExactType<LayoutProvider>();
    assert(result != null, 'No LayoutProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(LayoutProvider oldWidget) {
    return layout != oldWidget.layout;
  }
}

class Layout {
  const Layout({
    required this.deviceType,
    required this.orientation,
    required this.platform,
    required this.gestureDevice,
    required this.colorSchemeName,
    required this.size,
  });

  final DeviceType deviceType;
  final Orientation orientation;
  final Platform platform;
  final GestureDevice gestureDevice;
  final String colorSchemeName;
  final Size size;

  Layout copyWith({
    DeviceType? deviceType,
    Orientation? orientation,
    Platform? platform,
    GestureDevice? gestureDevice,
    String? colorSchemeName,
    Size? size,
  }) {
    return Layout(
      deviceType: deviceType ?? this.deviceType,
      orientation: orientation ?? this.orientation,
      platform: platform ?? this.platform,
      gestureDevice: gestureDevice ?? this.gestureDevice,
      colorSchemeName: colorSchemeName ?? this.colorSchemeName,
      size: size ?? this.size,
    );
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop;

  static DeviceType of(BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;
    if (screenWidth < kMobileBreakpoint) {
      return DeviceType.mobile;
    } else if (screenWidth < kTabletBreakpoint) {
      return DeviceType.tablet;
    }

    return DeviceType.desktop;
  }
}

enum Platform {
  android,
  iOS,
  windows,
  macOS,
  linux,
  web,
  unknown;

  static Platform of(BuildContext context) {
    if (kIsWeb) {
      return Platform.web;
    }

    TargetPlatform current = Theme.of(context).platform;
    switch (current) {
      case TargetPlatform.android:
        return Platform.android;
      case TargetPlatform.iOS:
        return Platform.iOS;
      case TargetPlatform.windows:
        return Platform.windows;
      case TargetPlatform.macOS:
        return Platform.macOS;
      case TargetPlatform.linux:
        return Platform.linux;
      default:
        return Platform.unknown;
    }
  }

  bool get isAndroid => this == Platform.android;
  bool get isIOS => this == Platform.iOS;
  bool get isWindows => this == Platform.windows;
  bool get isMacOS => this == Platform.macOS;
  bool get isLinux => this == Platform.linux;
  bool get isWeb => this == Platform.web;
}

enum GestureDevice {
  mouse,
  touch,
  stylus,
  unknown;
}

class GestureDeviceProvider extends InheritedWidget {
  final GestureDevice gestureDevice;

  const GestureDeviceProvider({
    super.key,
    required this.gestureDevice,
    required super.child,
  });

  static GestureDevice of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<GestureDeviceProvider>()
            ?.gestureDevice ??
        GestureDevice.unknown;
  }

  @override
  bool updateShouldNotify(GestureDeviceProvider oldWidget) =>
      gestureDevice != oldWidget.gestureDevice;
}
