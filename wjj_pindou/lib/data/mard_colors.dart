import 'dart:ui';

/// MARD 221色拼豆颜色数据
/// 包含完整的221种颜色，按色系分类
/// 每种颜色包含：色号、HEX值、RGB值、色系名称

class MardColor {
  final String code;       // 色号，如 A1, B2, F6
  final String hex;        // HEX颜色值，如 #FAF4C8
  final int r;             // RGB红色值
  final int g;             // RGB绿色值
  final int b;             // RGB蓝色值
  final String series;     // 色系：A-黄橙, B-绿, C-蓝青, D-蓝紫, E-粉玫, F-红, G-棕, H-灰黑白, M-特殊
  final String seriesName; // 色系名称
  
  const MardColor({
    required this.code,
    required this.hex,
    required this.r,
    required this.g,
    required this.b,
    required this.series,
    required this.seriesName,
  });
  
  /// 获取Flutter Color对象
  Color toColor() => Color.fromRGBO(r, g, b, 1.0);
  
  /// 从HEX字符串解析
  static MardColor fromHex(String code, String hex, String series, String seriesName) {
    final hexValue = hex.replaceFirst('#', '');
    return MardColor(
      code: code,
      hex: hex,
      r: int.parse(hexValue.substring(0, 2), radix: 16),
      g: int.parse(hexValue.substring(2, 4), radix: 16),
      b: int.parse(hexValue.substring(4, 6), radix: 16),
      series: series,
      seriesName: seriesName,
    );
  }
}

/// MARD 221色完整色卡数据
class MardColorPalette {
  static const List<MardColor> allColors = [
    // A系 - 黄橙系 (26色)
    ..._aSeries,
    // B系 - 绿色系 (32色)
    ..._bSeries,
    // C系 - 蓝青系 (29色)
    ..._cSeries,
    // D系 - 蓝紫系 (26色)
    ..._dSeries,
    // E系 - 粉玫系 (24色)
    ..._eSeries,
    // F系 - 红色系 (25色)
    ..._fSeries,
    // G系 - 棕色系 (21色)
    ..._gSeries,
    // H系 - 灰黑白系 (23色)
    ..._hSeries,
    // M系 - 特殊色 (15色)
    ..._mSeries,
  ];
  
  /// 按色系获取颜色
  static List<MardColor> getBySeries(String series) {
    return allColors.where((c) => c.series == series).toList();
  }
  
  /// 根据色号获取颜色
  static MardColor? getByCode(String code) {
    try {
      return allColors.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }
  
  /// 获取所有色系列表
  static List<Map<String, dynamic>> getSeriesList() => [
    {'code': 'A', 'name': '黄橙系', 'count': 26},
    {'code': 'B', 'name': '绿色系', 'count': 32},
    {'code': 'C', 'name': '蓝青系', 'count': 29},
    {'code': 'D', 'name': '蓝紫系', 'count': 26},
    {'code': 'E', 'name': '粉玫系', 'count': 24},
    {'code': 'F', 'name': '红色系', 'count': 25},
    {'code': 'G', 'name': '棕色系', 'count': 21},
    {'code': 'H', 'name': '灰黑白系', 'count': 23},
    {'code': 'M', 'name': '特殊色', 'count': 15},
  ];
}

// ==================== A系 - 黄橙系 ====================
const _aSeries = [
  MardColor(code: 'A1', hex: '#FAF4C8', r: 250, g: 244, b: 200, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A2', hex: '#FFFFD5', r: 255, g: 255, b: 213, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A3', hex: '#FEFF8B', r: 254, g: 255, b: 139, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A4', hex: '#FBED56', r: 251, g: 237, b: 86, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A5', hex: '#F4D738', r: 244, g: 215, b: 56, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A6', hex: '#FEAC4C', r: 254, g: 172, b: 76, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A7', hex: '#FE8B4C', r: 254, g: 139, b: 76, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A8', hex: '#FFDA45', r: 255, g: 218, b: 69, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A9', hex: '#FF995B', r: 255, g: 153, b: 91, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A10', hex: '#F77C31', r: 247, g: 124, b: 49, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A11', hex: '#FFDD99', r: 255, g: 221, b: 153, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A12', hex: '#FE9F72', r: 254, g: 159, b: 114, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A13', hex: '#FFC365', r: 255, g: 195, b: 101, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A14', hex: '#FD543D', r: 253, g: 84, b: 61, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A15', hex: '#FFF365', r: 255, g: 243, b: 101, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A16', hex: '#FFFF9F', r: 255, g: 255, b: 159, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A17', hex: '#FFE36E', r: 255, g: 227, b: 110, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A18', hex: '#FEBE7D', r: 254, g: 190, b: 125, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A19', hex: '#FD7C72', r: 253, g: 124, b: 114, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A20', hex: '#FFD568', r: 255, g: 213, b: 104, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A21', hex: '#FFE395', r: 255, g: 227, b: 149, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A22', hex: '#F4F57D', r: 244, g: 245, b: 125, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A23', hex: '#E6C9B7', r: 230, g: 201, b: 183, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A24', hex: '#F7F8A2', r: 247, g: 248, b: 162, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A25', hex: '#FFD67D', r: 255, g: 214, b: 125, series: 'A', seriesName: '黄橙系'),
  MardColor(code: 'A26', hex: '#FFC830', r: 255, g: 200, b: 48, series: 'A', seriesName: '黄橙系'),
];

// ==================== B系 - 绿色系 ====================
const _bSeries = [
  MardColor(code: 'B1', hex: '#E6EE31', r: 230, g: 238, b: 49, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B2', hex: '#63F347', r: 99, g: 243, b: 71, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B3', hex: '#9EF780', r: 158, g: 247, b: 128, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B4', hex: '#5DE035', r: 93, g: 224, b: 53, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B5', hex: '#35E352', r: 53, g: 227, b: 82, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B6', hex: '#65E2A6', r: 101, g: 226, b: 166, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B7', hex: '#3DAF80', r: 61, g: 175, b: 128, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B8', hex: '#1C9C4F', r: 28, g: 156, b: 79, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B9', hex: '#27523A', r: 39, g: 82, b: 58, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B10', hex: '#95D3C2', r: 149, g: 211, b: 194, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B11', hex: '#5D722A', r: 93, g: 114, b: 42, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B12', hex: '#166F41', r: 22, g: 111, b: 65, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B13', hex: '#CAEB7B', r: 202, g: 235, b: 123, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B14', hex: '#ADE946', r: 173, g: 233, b: 70, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B15', hex: '#2E5132', r: 46, g: 81, b: 50, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B16', hex: '#C5ED9C', r: 197, g: 237, b: 156, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B17', hex: '#9BB13A', r: 155, g: 177, b: 58, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B18', hex: '#E6EE49', r: 230, g: 238, b: 73, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B19', hex: '#24B88C', r: 36, g: 184, b: 140, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B20', hex: '#C2F0CC', r: 194, g: 240, b: 204, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B21', hex: '#156A6B', r: 21, g: 106, b: 107, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B22', hex: '#0B3C43', r: 11, g: 60, b: 67, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B23', hex: '#303A21', r: 48, g: 58, b: 33, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B24', hex: '#EEFCA5', r: 238, g: 252, b: 165, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B25', hex: '#4E846D', r: 78, g: 132, b: 109, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B26', hex: '#8D7A35', r: 141, g: 122, b: 53, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B27', hex: '#CCE1AF', r: 204, g: 225, b: 175, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B28', hex: '#9EE5B9', r: 158, g: 229, b: 185, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B29', hex: '#C5E254', r: 197, g: 226, b: 84, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B30', hex: '#E2FCB1', r: 226, g: 252, b: 177, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B31', hex: '#B0E792', r: 176, g: 231, b: 146, series: 'B', seriesName: '绿色系'),
  MardColor(code: 'B32', hex: '#9CAB5A', r: 156, g: 171, b: 90, series: 'B', seriesName: '绿色系'),
];

// ==================== C系 - 蓝青系 ====================
const _cSeries = [
  MardColor(code: 'C1', hex: '#E8FFE7', r: 232, g: 255, b: 231, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C2', hex: '#A9F9FC', r: 169, g: 249, b: 252, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C3', hex: '#A0E2FB', r: 160, g: 226, b: 251, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C4', hex: '#41CCFF', r: 65, g: 204, b: 255, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C5', hex: '#01ACEB', r: 1, g: 172, b: 235, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C6', hex: '#50AAF0', r: 80, g: 170, b: 240, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C7', hex: '#3677D2', r: 54, g: 119, b: 210, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C8', hex: '#0F54C0', r: 15, g: 84, b: 192, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C9', hex: '#324BCA', r: 50, g: 75, b: 202, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C10', hex: '#3EBCE2', r: 62, g: 188, b: 226, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C11', hex: '#28DDDE', r: 40, g: 221, b: 222, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C12', hex: '#1C334D', r: 28, g: 51, b: 77, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C13', hex: '#CDE8FF', r: 205, g: 232, b: 255, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C14', hex: '#D5FDFF', r: 213, g: 253, b: 255, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C15', hex: '#22C4C6', r: 34, g: 196, b: 198, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C16', hex: '#1557A8', r: 21, g: 87, b: 168, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C17', hex: '#04D1F6', r: 4, g: 209, b: 246, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C18', hex: '#1D3344', r: 29, g: 51, b: 68, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C19', hex: '#1887A2', r: 24, g: 135, b: 162, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C20', hex: '#176DAF', r: 23, g: 109, b: 175, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C21', hex: '#BEDDFF', r: 190, g: 221, b: 255, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C22', hex: '#67B4BE', r: 103, g: 180, b: 190, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C23', hex: '#C8E2FF', r: 200, g: 226, b: 255, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C24', hex: '#7CC4FF', r: 124, g: 196, b: 255, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C25', hex: '#A9E5E5', r: 169, g: 229, b: 229, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C26', hex: '#3CAED8', r: 60, g: 174, b: 216, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C27', hex: '#D3DFFA', r: 211, g: 223, b: 250, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C28', hex: '#BBCFED', r: 187, g: 207, b: 237, series: 'C', seriesName: '蓝青系'),
  MardColor(code: 'C29', hex: '#34488E', r: 52, g: 72, b: 142, series: 'C', seriesName: '蓝青系'),
];

// ==================== D系 - 蓝紫系 ====================
const _dSeries = [
  MardColor(code: 'D1', hex: '#AEB4F2', r: 174, g: 180, b: 242, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D2', hex: '#858EDD', r: 133, g: 142, b: 221, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D3', hex: '#2F54AF', r: 47, g: 84, b: 175, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D4', hex: '#182A84', r: 24, g: 42, b: 132, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D5', hex: '#B843C5', r: 184, g: 67, b: 197, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D6', hex: '#AC7BDE', r: 172, g: 123, b: 222, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D7', hex: '#8854B3', r: 136, g: 84, b: 179, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D8', hex: '#E2D3FF', r: 226, g: 211, b: 255, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D9', hex: '#D5B9F8', r: 213, g: 185, b: 248, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D10', hex: '#361851', r: 54, g: 24, b: 81, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D11', hex: '#B9BAE1', r: 185, g: 186, b: 225, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D12', hex: '#DE9AD4', r: 222, g: 154, b: 212, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D13', hex: '#B90095', r: 185, g: 0, b: 149, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D14', hex: '#8B279B', r: 139, g: 39, b: 155, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D15', hex: '#2F1F90', r: 47, g: 31, b: 144, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D16', hex: '#E3E1EE', r: 227, g: 225, b: 238, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D17', hex: '#C4D4F6', r: 196, g: 212, b: 246, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D18', hex: '#A45EC7', r: 164, g: 94, b: 199, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D19', hex: '#D8C3D7', r: 216, g: 195, b: 215, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D20', hex: '#9C32B2', r: 156, g: 50, b: 178, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D21', hex: '#9A009B', r: 154, g: 0, b: 155, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D22', hex: '#333A95', r: 51, g: 58, b: 149, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D23', hex: '#EBDAFC', r: 235, g: 218, b: 252, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D24', hex: '#7786E5', r: 119, g: 134, b: 229, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D25', hex: '#494FC7', r: 73, g: 79, b: 199, series: 'D', seriesName: '蓝紫系'),
  MardColor(code: 'D26', hex: '#DFC2F8', r: 223, g: 194, b: 248, series: 'D', seriesName: '蓝紫系'),
];

// ==================== E系 - 粉玫系 ====================
const _eSeries = [
  MardColor(code: 'E1', hex: '#FDD3CC', r: 253, g: 211, b: 204, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E2', hex: '#FEC0DF', r: 254, g: 192, b: 223, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E3', hex: '#FFB7E7', r: 255, g: 183, b: 231, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E4', hex: '#E8649E', r: 232, g: 100, b: 158, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E5', hex: '#F551A2', r: 245, g: 81, b: 162, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E6', hex: '#F13D74', r: 241, g: 61, b: 116, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E7', hex: '#C63478', r: 198, g: 52, b: 120, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E8', hex: '#FFDBE9', r: 255, g: 219, b: 233, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E9', hex: '#E970CC', r: 233, g: 112, b: 204, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E10', hex: '#D33793', r: 211, g: 55, b: 147, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E11', hex: '#FCDDD2', r: 252, g: 221, b: 210, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E12', hex: '#F78FC3', r: 247, g: 143, b: 195, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E13', hex: '#B5006D', r: 181, g: 0, b: 109, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E14', hex: '#FFD1BA', r: 255, g: 209, b: 186, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E15', hex: '#F8C7C9', r: 248, g: 199, b: 201, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E16', hex: '#FFF3EB', r: 255, g: 243, b: 235, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E17', hex: '#FFE2EA', r: 255, g: 226, b: 234, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E18', hex: '#FFC7DB', r: 255, g: 199, b: 219, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E19', hex: '#FEBAD5', r: 254, g: 186, b: 213, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E20', hex: '#D8C7D1', r: 216, g: 199, b: 209, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E21', hex: '#BD9DA1', r: 189, g: 157, b: 161, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E22', hex: '#B785A1', r: 183, g: 133, b: 161, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E23', hex: '#937A8D', r: 147, g: 122, b: 141, series: 'E', seriesName: '粉玫系'),
  MardColor(code: 'E24', hex: '#E1BCE8', r: 225, g: 188, b: 232, series: 'E', seriesName: '粉玫系'),
];

// ==================== F系 - 红色系 ====================
const _fSeries = [
  MardColor(code: 'F1', hex: '#FD957B', r: 253, g: 149, b: 123, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F2', hex: '#FC3D46', r: 252, g: 61, b: 70, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F3', hex: '#F74941', r: 247, g: 73, b: 65, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F4', hex: '#FC283C', r: 252, g: 40, b: 60, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F5', hex: '#E7002F', r: 231, g: 0, b: 47, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F6', hex: '#943630', r: 148, g: 54, b: 48, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F7', hex: '#972937', r: 151, g: 25, b: 55, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F8', hex: '#BC0028', r: 188, g: 0, b: 40, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F9', hex: '#E2677A', r: 226, g: 103, b: 122, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F10', hex: '#8A4526', r: 138, g: 69, b: 38, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F11', hex: '#5A2121', r: 90, g: 33, b: 33, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F12', hex: '#FD4E6A', r: 253, g: 78, b: 106, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F13', hex: '#F35744', r: 243, g: 87, b: 68, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F14', hex: '#FFA9AD', r: 255, g: 169, b: 173, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F15', hex: '#D30022', r: 211, g: 0, b: 34, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F16', hex: '#FEC2A6', r: 254, g: 194, b: 166, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F17', hex: '#E69C79', r: 230, g: 156, b: 121, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F18', hex: '#D37C62', r: 211, g: 124, b: 98, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F19', hex: '#FFA0B5', r: 255, g: 160, b: 181, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F20', hex: '#8B2323', r: 139, g: 35, b: 35, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F21', hex: '#8B0000', r: 139, g: 0, b: 0, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F22', hex: '#CD5C5C', r: 205, g: 92, b: 92, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F23', hex: '#F08080', r: 240, g: 128, b: 128, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F24', hex: '#FF6347', r: 255, g: 99, b: 71, series: 'F', seriesName: '红色系'),
  MardColor(code: 'F25', hex: '#FF4500', r: 255, g: 69, b: 0, series: 'F', seriesName: '红色系'),
];

// ==================== G系 - 棕色系 ====================
const _gSeries = [
  MardColor(code: 'G1', hex: '#FFE4C4', r: 255, g: 228, b: 196, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G2', hex: '#DEB887', r: 222, g: 184, b: 135, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G3', hex: '#D2691E', r: 210, g: 105, b: 30, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G4', hex: '#CD853F', r: 205, g: 133, b: 63, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G5', hex: '#8B4513', r: 139, g: 69, b: 13, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G6', hex: '#A0522D', r: 160, g: 82, b: 45, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G7', hex: '#6B4423', r: 107, g: 68, b: 35, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G8', hex: '#BC8F8F', r: 188, g: 143, b: 143, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G9', hex: '#F4A460', r: 244, g: 164, b: 96, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G10', hex: '#DAA520', r: 218, g: 165, b: 32, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G11', hex: '#B8860B', r: 184, g: 134, b: 11, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G12', hex: '#808000', r: 128, g: 128, b: 0, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G13', hex: '#6B8E23', r: 107, g: 142, b: 23, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G14', hex: '#556B2F', r: 85, g: 107, b: 47, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G15', hex: '#2F4F4F', r: 47, g: 79, b: 79, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G16', hex: '#8B8682', r: 139, g: 134, b: 130, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G17', hex: '#C4AEAD', r: 196, g: 174, b: 173, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G18', hex: '#A9A9A9', r: 169, g: 169, b: 169, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G19', hex: '#778899', r: 119, g: 136, b: 153, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G20', hex: '#5F5F5F', r: 95, g: 95, b: 95, series: 'G', seriesName: '棕色系'),
  MardColor(code: 'G21', hex: '#704214', r: 112, g: 66, b: 20, series: 'G', seriesName: '棕色系'),
];

// ==================== H系 - 灰黑白系 ====================
const _hSeries = [
  MardColor(code: 'H1', hex: '#FFFFFF', r: 255, g: 255, b: 255, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H2', hex: '#F5F5F5', r: 245, g: 245, b: 245, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H3', hex: '#E0E0E0', r: 224, g: 224, b: 224, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H4', hex: '#D0D0D0', r: 208, g: 208, b: 208, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H5', hex: '#C0C0C0', r: 192, g: 192, b: 192, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H6', hex: '#A0A0A0', r: 160, g: 160, b: 160, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H7', hex: '#909090', r: 144, g: 144, b: 144, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H8', hex: '#808080', r: 128, g: 128, b: 128, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H9', hex: '#707070', r: 112, g: 112, b: 112, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H10', hex: '#606060', r: 96, g: 96, b: 96, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H11', hex: '#505050', r: 80, g: 80, b: 80, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H12', hex: '#404040', r: 64, g: 64, b: 64, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H13', hex: '#303030', r: 48, g: 48, b: 48, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H14', hex: '#202020', r: 32, g: 32, b: 32, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H15', hex: '#101010', r: 16, g: 16, b: 16, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H16', hex: '#000000', r: 0, g: 0, b: 0, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H17', hex: '#F8F8FF', r: 248, g: 248, b: 255, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H18', hex: '#DCDCDC', r: 220, g: 220, b: 220, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H19', hex: '#BEBEBE', r: 190, g: 190, b: 190, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H20', hex: '#ABABAB', r: 171, g: 171, b: 171, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H21', hex: '#696969', r: 105, g: 105, b: 105, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H22', hex: '#4A4A4A', r: 74, g: 74, b: 74, series: 'H', seriesName: '灰黑白系'),
  MardColor(code: 'H23', hex: '#363636', r: 54, g: 54, b: 54, series: 'H', seriesName: '灰黑白系'),
];

// ==================== M系 - 特殊色（荧光/透明等） ====================
const _mSeries = [
  MardColor(code: 'M1', hex: '#FF00FF', r: 255, g: 0, b: 255, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M2', hex: '#FF1493', r: 255, g: 20, b: 147, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M3', hex: '#00FF00', r: 0, g: 255, b: 0, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M4', hex: '#00FFFF', r: 0, g: 255, b: 255, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M5', hex: '#FFFF00', r: 255, g: 255, b: 0, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M6', hex: '#FF6600', r: 255, g: 102, b: 0, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M7', hex: '#FF0066', r: 255, g: 0, b: 102, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M8', hex: '#6600FF', r: 102, g: 0, b: 255, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M9', hex: '#0066FF', r: 0, g: 102, b: 255, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M10', hex: '#66FF00', r: 102, g: 255, b: 0, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M11', hex: '#00FF66', r: 0, g: 255, b: 102, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M12', hex: '#FF66FF', r: 255, g: 102, b: 255, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M13', hex: '#66FFFF', r: 102, g: 255, b: 255, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M14', hex: '#FFFF66', r: 255, g: 255, b: 102, series: 'M', seriesName: '特殊色'),
  MardColor(code: 'M15', hex: '#FF3366', r: 255, g: 51, b: 102, series: 'M', seriesName: '特殊色'),
];

