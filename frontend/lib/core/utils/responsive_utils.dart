import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoint'ler
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Cihaz türünü belirle
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }
  
  // Responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(8);
      case DeviceType.tablet:
        return const EdgeInsets.all(12);
      case DeviceType.desktop:
        return const EdgeInsets.all(16);
    }
  }
  
  // Responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseFontSize;
      case DeviceType.tablet:
        return baseFontSize * 1.1;
      case DeviceType.desktop:
        return baseFontSize * 1.2;
    }
  }
  
  // Responsive grid columns
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }
  
  // Responsive card width
  static double getCardWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth - 32; // Full width minus padding
      case DeviceType.tablet:
        return (screenWidth - 48) / 2; // Half width minus padding
      case DeviceType.desktop:
        return (screenWidth - 64) / 3; // Third width minus padding
    }
  }
  
  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSpacing;
      case DeviceType.tablet:
        return baseSpacing * 1.5;
      case DeviceType.desktop:
        return baseSpacing * 2;
    }
  }
  
  // Responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseIconSize;
      case DeviceType.tablet:
        return baseIconSize * 1.2;
      case DeviceType.desktop:
        return baseIconSize * 1.4;
    }
  }
  
  // Responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 48;
      case DeviceType.tablet:
        return 56;
      case DeviceType.desktop:
        return 64;
    }
  }
  
  // Responsive list item height
  static double getResponsiveListItemHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 80;
      case DeviceType.tablet:
        return 100;
      case DeviceType.desktop:
        return 120;
    }
  }
  
  // Responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 800;
      case DeviceType.desktop:
        return 1200;
    }
  }
  
  // Responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 48);
    }
  }
  
  // Responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(vertical: 16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(vertical: 24);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(vertical: 32);
    }
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

// Responsive widget wrapper
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

// Responsive builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}
