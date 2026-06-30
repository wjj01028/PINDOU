import 'package:image/image.dart' as img;
import '../data/mard_colors.dart';

/// 像素化转换器 - 将图片转换为拼豆图纸
class PixelConverter {
  /// 抠除图片背景：基于 OpenCV 风格的白底检测 + 形态学处理
  ///
  /// 流程（对应 OpenCV 操作）：
  /// 1. 读取图片（image 包解码后即为 RGBA 格式，等同于已从 BGR 转为 RGB）
  /// 2. 白色背景容差：定义容差范围，接近白色 (255,255,255) 的像素视为背景
  /// 3. 生成二值掩码（对应 cv2.inRange）：背景像素=0，主体像素=255
  /// 4. 形态学操作：先腐蚀后膨胀（开运算）去除噪点、平滑边缘
  /// 5. 将掩码作为 Alpha 通道合并到原图，背景变为透明
  /// 6. 保持图片原始尺寸不变
  static img.Image removeBackground(img.Image src) {
    final w = src.width;
    final h = src.height;
    final total = w * h;

    // ---- 步骤 1 & 2：定义白色背景容差 ----
    // image 包解码后格式为 RGBA，等同于 OpenCV 的 cvtColor(BGR, RGB)
    // 白色在 RGB 中为 (255, 255, 255)，定义容差 threshold
    const int tolerance = 30;
    const int threshold = 255 - tolerance; // 225
    // 当 R、G、B 三个通道值都 >= 225 时，视为接近白色的背景像素

    // ---- 步骤 3：生成二值掩码（对应 cv2.inRange） ----
    // 背景像素 = 0（黑色），主体像素 = 255（白色）
    final mask = List<int>.filled(total, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();

        if (r >= threshold && g >= threshold && b >= threshold) {
          mask[y * w + x] = 0; // 背景
        } else {
          mask[y * w + x] = 255; // 前景（主体）
        }
      }
    }

    // ---- 步骤 4：形态学操作（开运算 = 先腐蚀后膨胀） ----
    // 去除孤立噪点，平滑主体边缘
    const kernelSize = 3;
    final eroded = _morphErode(mask, w, h, kernelSize);
    final opened = _morphDilate(eroded, w, h, kernelSize);

    // ---- 步骤 5：将掩码作为 Alpha 通道合并到原图 ----
    // 背景像素 alpha=0（透明），主体像素 alpha=255（不透明）
    final result = img.Image.from(src);
    for (int i = 0; i < total; i++) {
      final x = i % w;
      final y = i ~/ w;
      final p = src.getPixel(x, y);
      result.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), opened[i]);
    }

    return result;
  }

  /// 形态学腐蚀：对掩码执行最小值滤波
  /// 3x3 核内取最小值，前景区域缩小，消除小噪点
  static List<int> _morphErode(List<int> mask, int w, int h, int kernel) {
    final result = List<int>.filled(w * h, 0);
    final half = kernel ~/ 2;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int minVal = 255;
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final nx = x + kx;
            final ny = y + ky;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              if (mask[ny * w + nx] < minVal) {
                minVal = mask[ny * w + nx];
              }
            }
          }
        }
        result[y * w + x] = minVal;
      }
    }
    return result;
  }

  /// 形态学膨胀：对掩码执行最大值滤波
  /// 3x3 核内取最大值，前景区域扩大，恢复主体边缘
  static List<int> _morphDilate(List<int> mask, int w, int h, int kernel) {
    final result = List<int>.filled(w * h, 0);
    final half = kernel ~/ 2;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int maxVal = 0;
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final nx = x + kx;
            final ny = y + ky;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              if (mask[ny * w + nx] > maxVal) {
                maxVal = mask[ny * w + nx];
              }
            }
          }
        }
        result[y * w + x] = maxVal;
      }
    }
    return result;
  }
  
  /// 将图片像素化为指定尺寸的网格
  /// 使用加权RGB距离算法匹配MARD 221色
  static PatternResult convert({
    required img.Image sourceImage,
    required int beadWidth,      // 拼豆宽度（豆子数量）
    int? beadHeight,             // 拼豆高度（可选，自动计算保持比例）
    int maxColors = 50,          // 最大颜色数限制
    bool useDithering = false,   // 是否使用抖动算法
  }) {
    // 计算目标尺寸
    final targetWidth = beadWidth;
    final targetHeight = beadHeight ?? 
        (sourceImage.height * beadWidth / sourceImage.width).round();
    
    // 像素化：缩放图片到目标尺寸
    final pixelated = img.copyResize(
      sourceImage,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average, // 使用平均值插值获得更平滑的效果
    );
    
    // 颜色匹配：将每个像素匹配到最接近的MARD颜色
    final grid = <GridCell>[];
    final colorCounts = <String, int>{};
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = pixelated.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // 检查是否为透明/背景像素（跳过）
        // 1. alpha 低于阈值的透明像素
        // 2. 近白色像素（透明背景混合产物）
        if (pixel.a < 200 || _isBackgroundPixel(r, g, b, pixel.a.toInt())) {
          grid.add(GridCell(
            x: x,
            y: y,
            color: null,
            isEmpty: true,
          ));
          continue;
        }
        
        // 找到最接近的MARD颜色
        final matchedColor = _findClosestColor(r, g, b, maxColors);
        
        grid.add(GridCell(
          x: x,
          y: y,
          color: matchedColor,
          isEmpty: false,
        ));
        
        // 统计颜色使用次数
        if (matchedColor != null) {
          colorCounts[matchedColor.code] = 
              (colorCounts[matchedColor.code] ?? 0) + 1;
        }
      }
    }
    
    // 生成材料清单
    final materialList = colorCounts.entries
        .map((e) => MaterialItem(
          color: MardColorPalette.getByCode(e.key)!,
          count: e.value,
        ))
        .toList();
    
    // 按使用数量排序
    materialList.sort((a, b) => b.count.compareTo(a.count));
    
    return PatternResult(
      width: targetWidth,
      height: targetHeight,
      grid: grid,
      materialList: materialList,
      totalBeads: grid.where((c) => !c.isEmpty).length,
      colorCount: materialList.length,
    );
  }
  
  // ============================================================
  // 颜色查找表 (LUT) — 32级量化，预计算最近 Mard 颜色，O(1) 匹配
  // ============================================================
  static List<MardColor?>? _colorLUT;
  static const int _lutLevels = 32;
  static const double _lutScale = (_lutLevels - 1) / 255.0;
  
  static void _ensureLUT() {
    if (_colorLUT != null) return;
    final all = MardColorPalette.allColors;
    _colorLUT = List.filled(_lutLevels * _lutLevels * _lutLevels, null);
    
    // 计算所有 Mard 颜色的 LUT 索引
    final colorIndices = <int, MardColor>{};
    for (final mc in all) {
      final rq = (mc.r * _lutScale).round();
      final gq = (mc.g * _lutScale).round();
      final bq = (mc.b * _lutScale).round();
      colorIndices[(rq << 10) | (gq << 5) | bq] = mc;
    }
    
    for (int rq = 0; rq < _lutLevels; rq++) {
      final rc = (rq / _lutScale).round();
      for (int gq = 0; gq < _lutLevels; gq++) {
        final gc = (gq / _lutScale).round();
        for (int bq = 0; bq < _lutLevels; bq++) {
          final bc = (bq / _lutScale).round();
          final idx = (rq * _lutLevels + gq) * _lutLevels + bq;
          
          MardColor? best;
          double bestDist = double.infinity;
          
          for (final mc in all) {
            final d = _calculateColorDistance(rc, gc, bc, mc.r, mc.g, mc.b);
            if (d < bestDist) {
              bestDist = d;
              best = mc;
            }
          }
          _colorLUT![idx] = best;
        }
      }
    }
  }
  
  /// 使用加权RGB距离找到最接近的MARD颜色（LUT 优化版）
  static MardColor? _findClosestColor(int r, int g, int b, int maxColors) {
    _ensureLUT();
    final rq = (r * _lutScale).round().clamp(0, _lutLevels - 1);
    final gq = (g * _lutScale).round().clamp(0, _lutLevels - 1);
    final bq = (b * _lutScale).round().clamp(0, _lutLevels - 1);
    final idx = (rq * _lutLevels + gq) * _lutLevels + bq;
    return _colorLUT![idx];
  }
  
  /// 判断是否为背景像素（透明背景下应忽略的颜色）
  /// 关键：只有来自透明混合的低 alpha 近白色才跳过；
  ///       图案内部完全不透明的白色（a>=250）应保留为白色豆子
  static bool _isBackgroundPixel(int r, int g, int b, int a) {
    // 颜色与纯白的距离
    final distToWhite = ((255 - r) * (255 - r) +
                         (255 - g) * (255 - g) +
                         (255 - b) * (255 - b)) ~/ 441;
    
    // 颜色饱和度
    final mean = (r + g + b) ~/ 3;
    final variance = ((r - mean) * (r - mean) +
                      (g - mean) * (g - mean) +
                      (b - mean) * (b - mean)) ~/ 3;
    
    // 条件1: 透明度低的混合背景（半透明近白 + 低饱和）
    // alpha < 250 说明来自透明背景混合，不应保留
    if (a < 250 && distToWhite < 80 && variance < 300) {
      return true;
    }
    
    // 条件2: 极近白色 + 低饱和 —— 仅当 alpha 也不足时才跳过
    // alpha=255 的纯白是图案内部的白色，必须保留！
    if (a < 240 && distToWhite < 15 && variance < 100) {
      return true;
    }
    
    return false;
  }
  
  /// 计算颜色距离（加权RGB）
  /// 使用CIEDE2000的简化版本
  static double _calculateColorDistance(
    int r1, int g1, int b1,
    int r2, int g2, int b2,
  ) {
    // 简化的加权RGB距离
    // 人眼对绿色最敏感，红色次之，蓝色最不敏感
    final deltaR = (r1 - r2) * 0.3;
    final deltaG = (g1 - g2) * 0.59;
    final deltaB = (b1 - b2) * 0.11;
    
    // 计算欧几里得距离
    return deltaR * deltaR + deltaG * deltaG + deltaB * deltaB;
  }
  
  /// 生成预览图像（拼豆效果）
  static img.Image generatePreviewImage(PatternResult result, int beadSize) {
    final previewWidth = result.width * beadSize;
    final previewHeight = result.height * beadSize;
    
    final preview = img.Image(width: previewWidth, height: previewHeight);
    
    // 填充背景为浅灰色
    img.fill(preview, color: img.ColorRgba8(240, 240, 240, 255));
    
    // 绘制每个拼豆
    for (final cell in result.grid) {
      if (cell.isEmpty || cell.color == null) continue;
      
      final startX = cell.x * beadSize;
      final startY = cell.y * beadSize;
      
      // 绘制圆形拼豆
      final mardColor = cell.color!;
      final beadColor = img.ColorRgba8(mardColor.r, mardColor.g, mardColor.b, 255);
      
      // 绘制拼豆形状（圆形+小孔）
      _drawBead(preview, startX, startY, beadSize, beadColor);
    }
    
    return preview;
  }
  
  /// 绘制单个拼豆（圆形带中心孔）
  static void _drawBead(img.Image image, int x, int y, int size, img.Color beadColor) {
    final center = size / 2;
    final radius = size / 2 - 2; // 留一点边距
    
    // 绘制圆形拼豆
    for (int dy = 0; dy < size; dy++) {
      for (int dx = 0; dx < size; dx++) {
        final px = x + dx;
        final py = y + dy;
        
        if (px >= image.width || py >= image.height) continue;
        
        // 计算到中心的距离
        final distX = dx - center;
        final distY = dy - center;
        final dist = distX * distX + distY * distY;
        
        // 如果在圆形范围内，填充颜色
        if (dist <= radius * radius) {
          // 中心孔（小圆圈）
          final holeRadius = size / 6;
          if (dist <= holeRadius * holeRadius) {
            // 孔的颜色（稍微深一点的背景）
            image.setPixel(px, py, img.ColorRgba8(220, 220, 220, 255));
          } else {
            // 拼豆颜色
            image.setPixel(px, py, beadColor);
          }
        }
      }
    }
  }
  
  /// 生成带网格的图纸（用于打印）
  static img.Image generateGridPattern(PatternResult result, int cellSize) {
    final patternWidth = result.width * cellSize;
    final patternHeight = result.height * cellSize;
    
    final pattern = img.Image(width: patternWidth, height: patternHeight);
    img.fill(pattern, color: img.ColorRgba8(255, 255, 255, 255));
    
    // 绘制网格和颜色
    for (final cell in result.grid) {
      final startX = cell.x * cellSize;
      final startY = cell.y * cellSize;
      
      if (cell.isEmpty || cell.color == null) {
        continue;
      }
      
      final mardColor = cell.color!;
      final fillColor = img.ColorRgba8(mardColor.r, mardColor.g, mardColor.b, 255);
      
      // 填充单元格
      for (int dy = 0; dy < cellSize; dy++) {
        for (int dx = 0; dx < cellSize; dx++) {
          final px = startX + dx;
          final py = startY + dy;
          
          if (px >= pattern.width || py >= pattern.height) continue;
          
          // 边缘绘制网格线（黑色）
          if (dx == 0 || dy == 0 || dx == cellSize - 1 || dy == cellSize - 1) {
            pattern.setPixel(px, py, img.ColorRgba8(50, 50, 50, 255));
          } else {
            pattern.setPixel(px, py, fillColor);
          }
        }
      }
    }
    
    return pattern;
  }
  
  // ============================================================
  // 导出/预览图纸
  // ============================================================

  /// 生成带色号的预览网格图（屏幕显示用）
  static img.Image generatePreviewGrid(PatternResult result) {
    const cellSize = 32;          // 预览单元格大小
    const gridLineWidth = 1;
    const fontScale = 2;          // 色号字体

    final gridW = result.width * cellSize;
    final gridH = result.height * cellSize;

    final image = img.Image(width: gridW, height: gridH);
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));

    for (final cell in result.grid) {
      final sx = cell.x * cellSize;
      final sy = cell.y * cellSize;

      if (cell.isEmpty || cell.color == null) {
        for (int dy = 0; dy < cellSize; dy++) {
          for (int dx = 0; dx < cellSize; dx++) {
            final px = sx + dx, py = sy + dy;
            if (px >= image.width || py >= image.height) continue;
            if (dx < gridLineWidth || dy < gridLineWidth ||
                dx >= cellSize - gridLineWidth || dy >= cellSize - gridLineWidth) {
              image.setPixel(px, py, img.ColorRgba8(190, 190, 190, 255));
            } else {
              image.setPixel(px, py, img.ColorRgba8(248, 248, 248, 255));
            }
          }
        }
        continue;
      }

      final mc = cell.color!;
      final fill = img.ColorRgba8(mc.r, mc.g, mc.b, 255);
      for (int dy = 0; dy < cellSize; dy++) {
        for (int dx = 0; dx < cellSize; dx++) {
          final px = sx + dx, py = sy + dy;
          if (px >= image.width || py >= image.height) continue;
          if (dx < gridLineWidth || dy < gridLineWidth ||
              dx >= cellSize - gridLineWidth || dy >= cellSize - gridLineWidth) {
            image.setPixel(px, py, img.ColorRgba8(60, 60, 60, 255));
          } else {
            image.setPixel(px, py, fill);
          }
        }
      }

      // 色号居中
      final code = cell.color!.code;
      final tc = _textColorForBackground(mc.r, mc.g, mc.b);
      final tw = _textWidth(code, fontScale);
      final tx = sx + (cellSize - tw) ~/ 2;
      final ty = sy + (cellSize - 7 * fontScale) ~/ 2;
      _drawText(image, code, tx, ty, tc, fontScale);
    }

    return image;
  }
  
  /// 5x7 位图字体（A-Z, 0-9），每字节5个有效位(bit4=最左)
  static const Map<String, List<int>> _font5x7 = {
    'A': [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
    'B': [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
    'C': [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E],
    'D': [0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E],
    'E': [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F],
    'F': [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10],
    'G': [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0E],
    'H': [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
    'I': [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E],
    'J': [0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C],
    'K': [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11],
    'L': [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
    'M': [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11],
    'N': [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11],
    'O': [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
    'P': [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10],
    'Q': [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D],
    'R': [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
    'S': [0x0E, 0x11, 0x10, 0x0E, 0x01, 0x11, 0x0E],
    'T': [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
    'U': [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
    'V': [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04],
    'W': [0x11, 0x11, 0x11, 0x15, 0x15, 0x1B, 0x11],
    'X': [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11],
    'Y': [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04],
    'Z': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F],
    '0': [0x0E, 0x13, 0x15, 0x15, 0x15, 0x19, 0x0E],
    '1': [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
    '2': [0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F],
    '3': [0x0E, 0x11, 0x01, 0x06, 0x01, 0x11, 0x0E],
    '4': [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02],
    '5': [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
    '6': [0x0E, 0x11, 0x10, 0x1E, 0x11, 0x11, 0x0E],
    '7': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
    '8': [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E],
    '9': [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x11, 0x0E],
  };
  
  /// 在图像上绘制缩放后的单个字符
  static void _drawChar(
    img.Image image,
    String char,
    int x,
    int y,
    img.Color color,
    int scale,
  ) {
    final glyph = _font5x7[char];
    if (glyph == null) return;
    
    for (int row = 0; row < 7; row++) {
      int bits = glyph[row];
      for (int col = 0; col < 5; col++) {
        if ((bits & (0x10 >> col)) != 0) {
          // 绘制 scale×scale 的像素块
          for (int sy = 0; sy < scale; sy++) {
            for (int sx = 0; sx < scale; sx++) {
              final px = x + col * scale + sx;
              final py = y + row * scale + sy;
              if (px < image.width && py < image.height) {
                image.setPixel(px, py, color);
              }
            }
          }
        }
      }
    }
  }
  
  /// 在图像上绘制缩放后的字符串
  static int _drawText(
    img.Image image,
    String text,
    int x,
    int y,
    img.Color color,
    int scale,
  ) {
    int cursorX = x;
    for (int i = 0; i < text.length; i++) {
      _drawChar(image, text[i], cursorX, y, color, scale);
      cursorX += (5 + 1) * scale; // 5px char + 1px spacing
    }
    return cursorX;
  }
  
  /// 计算字符串的像素宽度
  static int _textWidth(String text, int scale) {
    return text.length * (5 + 1) * scale;
  }
  
  /// 判断颜色亮度，返回合适的文字颜色
  static img.Color _textColorForBackground(int r, int g, int b) {
    // 相对亮度公式
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5
        ? img.ColorRgba8(30, 30, 30, 255)  // 深色文字（亮背景）
        : img.ColorRgba8(255, 255, 255, 255); // 白色文字（暗背景）
  }
  
  /// 生成完整导出图纸（网格+色号+底部材料清单）
  /// 输出适配 A4 纸 300 DPI 打印，网格填满幅面，材料列表字体放大
  static img.Image generateExportImage(PatternResult result) {
    // A4 打印尺寸 (300 DPI, 15mm 边距)
    const printDPI = 300.0;
    const marginMM = 15.0;
    final printW = ((210 - marginMM * 2) / 25.4 * printDPI).round(); // ~2126px
    final materialListPerRow = 6; // 材料清单每行卡片数
    const cardTextFont = 3;       // 卡片文字放大 3 倍

    final beadW = result.width;
    final beadH = result.height;
    
    // 网格单元格自适应 A4 宽度
    final cellSize = (printW / beadW).round().clamp(28, 120);
    final gridFont = (cellSize / 15.0).round().clamp(2, 5);
    
    const gridLineWidth = 2;
    final gridW = beadW * cellSize;
    final gridH = beadH * cellSize;

    // 材料清单卡片尺寸（放大）
    const cardPad = 20;
    const cardBdr = 2;
    const cardGapV = 14;
    const cardGapH = 14;
    const swatchW = 40;
    const swatchH = 48;
    const cardW = cardPad * 2 + cardBdr * 2 + swatchW + 14 + 100; // 色块 + 间距 + 文字区
    const cardH = cardPad * 2 + cardBdr * 2 + swatchH;
    
    final gapH = (20.0 / 25.4 * printDPI).round(); // 20mm 间距
    final rows = (result.materialList.length + materialListPerRow - 1) ~/ materialListPerRow;
    final listPadTop = 30;
    final listTitleH = 50;
    final listPadBot = 30;
    final listH = listPadTop + listTitleH + rows * (cardH + cardGapV) + listPadBot;

    final totalH = gridH + gapH + listH;

    final image = img.Image(width: gridW, height: totalH);
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));

    // ======== 网格图纸 ========
    for (final cell in result.grid) {
      final sx = cell.x * cellSize;
      final sy = cell.y * cellSize;

      if (cell.isEmpty || cell.color == null) {
        for (int dy = 0; dy < cellSize; dy++) {
          for (int dx = 0; dx < cellSize; dx++) {
            final px = sx + dx, py = sy + dy;
            if (px >= image.width || py >= image.height) continue;
            if (dx < gridLineWidth || dy < gridLineWidth ||
                dx >= cellSize - gridLineWidth || dy >= cellSize - gridLineWidth) {
              image.setPixel(px, py, img.ColorRgba8(190, 190, 190, 255));
            } else {
              image.setPixel(px, py, img.ColorRgba8(248, 248, 248, 255));
            }
          }
        }
        continue;
      }

      final mc = cell.color!;
      final fill = img.ColorRgba8(mc.r, mc.g, mc.b, 255);
      for (int dy = 0; dy < cellSize; dy++) {
        for (int dx = 0; dx < cellSize; dx++) {
          final px = sx + dx, py = sy + dy;
          if (px >= image.width || py >= image.height) continue;
          if (dx < gridLineWidth || dy < gridLineWidth ||
              dx >= cellSize - gridLineWidth || dy >= cellSize - gridLineWidth) {
            image.setPixel(px, py, img.ColorRgba8(60, 60, 60, 255));
          } else {
            image.setPixel(px, py, fill);
          }
        }
      }

      // 色号居中
      final code = cell.color!.code;
      final tc = _textColorForBackground(mc.r, mc.g, mc.b);
      final tw = _textWidth(code, gridFont);
      final tx = sx + (cellSize - tw) ~/ 2;
      final ty = sy + (cellSize - 7 * gridFont) ~/ 2;
      _drawText(image, code, tx, ty, tc, gridFont);
    }

    // ======== 分隔线 ========
    final sepY = gridH + gapH ~/ 2;
    for (int x = 0; x < gridW; x++) {
      image.setPixel(x, sepY, img.ColorRgba8(200, 200, 200, 255));
    }

    // ======== 材料清单 ========
    final listY0 = gridH + gapH;

    // 清单背景
    for (int y = listY0; y < totalH; y++) {
      for (int x = 0; x < gridW; x++) {
        image.setPixel(x, y, img.ColorRgba8(250, 250, 250, 255));
      }
    }

    // 标题
    _drawText(image, 'Material  List', 16, listY0 + listPadTop,
        img.ColorRgba8(50, 50, 50, 255), 4);

    // 副标题
    final sub = '${result.width}x${result.height} beads  /  ${result.colorCount} colors  /  ${result.totalBeads} pcs';
    _drawText(image, sub, 24, listY0 + listPadTop + 30,
        img.ColorRgba8(140, 140, 140, 255), 2);

    final cardsY0 = listY0 + listPadTop + listTitleH;
    final totalCardWidth = materialListPerRow * cardW + (materialListPerRow - 1) * cardGapH;
    final cardsX0 = (gridW - totalCardWidth) ~/ 2;

    for (int i = 0; i < result.materialList.length; i++) {
      final item = result.materialList[i];
      final col = i % materialListPerRow;
      final rowIdx = i ~/ materialListPerRow;

      final cx = cardsX0 + col * (cardW + cardGapH);
      final cy = cardsY0 + rowIdx * (cardH + cardGapV);

      // 白色背景
      for (int py = cy + cardBdr; py < cy + cardH - cardBdr; py++) {
        for (int px = cx + cardBdr; px < cx + cardW - cardBdr; px++) {
          if (px < image.width && py < image.height) {
            image.setPixel(px, py, img.ColorRgba8(255, 255, 255, 255));
          }
        }
      }
      // 边框（2px 粗）
      for (int t = 0; t < cardBdr; t++) {
        for (int py = cy; py < cy + cardH; py++) {
          if (py < image.height) {
            image.setPixel(cx + t, py, img.ColorRgba8(100, 100, 100, 255));
            if (cx + cardW - 1 - t < image.width) {
              image.setPixel(cx + cardW - 1 - t, py, img.ColorRgba8(100, 100, 100, 255));
            }
          }
        }
        for (int px = cx; px < cx + cardW; px++) {
          if (px < image.width) {
            image.setPixel(px, cy + t, img.ColorRgba8(100, 100, 100, 255));
            if (cy + cardH - 1 - t < image.height) {
              image.setPixel(px, cy + cardH - 1 - t, img.ColorRgba8(100, 100, 100, 255));
            }
          }
        }
      }

      // 色块
      final swX = cx + cardPad;
      final swY = cy + cardPad;
      final swCol = img.ColorRgba8(item.color.r, item.color.g, item.color.b, 255);
      for (int sy = 0; sy < swatchH; sy++) {
        for (int sx = 0; sx < swatchW; sx++) {
          final px = swX + sx, py = swY + sy;
          if (px < image.width && py < image.height) {
            image.setPixel(px, py, swCol);
          }
        }
      }

      // 色号 + 数量（放大字体）
      final tX = swX + swatchW + 14;
      final tY = swY + 6;
      _drawText(image, item.color.code, tX, tY,
          img.ColorRgba8(30, 30, 30, 255), cardTextFont);
      final cntX = tX + _textWidth(item.color.code, cardTextFont) + 12;
      _drawText(image, 'x${item.count}', cntX, tY + 4,
          img.ColorRgba8(140, 140, 140, 255), cardTextFont);
    }

    return image;
  }
}

/// 图纸单元格
class GridCell {
  final int x;
  final int y;
  final MardColor? color;
  final bool isEmpty;
  
  GridCell({
    required this.x,
    required this.y,
    this.color,
    this.isEmpty = false,
  });
}

/// 图纸结果
class PatternResult {
  final int width;              // 宽度（豆子数）
  final int height;             // 高度（豆子数）
  final List<GridCell> grid;    // 网格数据
  final List<MaterialItem> materialList; // 材料清单
  final int totalBeads;         // 总豆子数
  final int colorCount;         // 使用颜色数
  
  PatternResult({
    required this.width,
    required this.height,
    required this.grid,
    required this.materialList,
    required this.totalBeads,
    required this.colorCount,
  });
  
  /// 获取指定位置的单元格
  GridCell? getCell(int x, int y) {
    try {
      return grid.firstWhere((c) => c.x == x && c.y == y);
    } catch (_) {
      return null;
    }
  }
}

/// 材料清单项
class MaterialItem {
  final MardColor color;
  final int count;
  
  MaterialItem({
    required this.color,
    required this.count,
  });
}