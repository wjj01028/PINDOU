import 'package:flutter/material.dart';

/// 设备布局断点
enum DeviceLayout { phone, tablet, desktop }

/// 响应式布局工具
class LayoutHelper {
  /// 根据最大宽度判断设备类型
  static DeviceLayout deviceLayout(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return DeviceLayout.phone;
    if (w < 1200) return DeviceLayout.tablet;
    return DeviceLayout.desktop;
  }

  static bool isPhone(BuildContext context) =>
      deviceLayout(context) == DeviceLayout.phone;

  static bool isTablet(BuildContext context) =>
      deviceLayout(context) == DeviceLayout.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceLayout(context) == DeviceLayout.desktop;

  /// 是否宽屏（Tablet+）
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  // ========== 间距 ==========
  static double gap(BuildContext context) => isWide(context) ? 24.0 : 16.0;

  static double horizontalPadding(BuildContext context) =>
      isWide(context) ? 32.0 : 16.0;

  static double smallGap(BuildContext context) =>
      isWide(context) ? 16.0 : 12.0;

  // ========== 字号 ==========
  static double titleSize(BuildContext context) =>
      isWide(context) ? 22.0 : 18.0;

  static double bodySize(BuildContext context) =>
      isWide(context) ? 16.0 : 14.0;

  static double smallSize(BuildContext context) =>
      isWide(context) ? 13.0 : 11.0;

  // ========== 图片区高度 ==========
  static double imagePickerHeight(BuildContext context) =>
      isWide(context) ? 350.0 : 200.0;

  // ========== 按钮高度 ==========
  static double buttonHeight(BuildContext context) =>
      isWide(context) ? 60.0 : 52.0;

  // ========== 网格列数 ==========
  /// Phone: 2列, Tablet: 3列, Desktop: 4列
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 2;
    if (w < 900) return 3;
    return 4;
  }

  // ========== 宽屏双面板 ==========
  static bool useDualPane(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;
}
