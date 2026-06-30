import 'package:image/image.dart' as img;
import '../data/mard_colors.dart';

/// 像素化转换器 - 将图片转换为拼豆图纸
class PixelConverter {
  /// 抠除图片背景：基于边缘洪水填充的智能分割
  ///
  /// 原理（对应 OpenCV 的 Canny + findContours + 填充思路）：
  ///   从图片四个边缘出发，沿白色像素向外"洪水填充"，所有能通过连续白色
  ///   路径到达边缘的区域即为背景。被非白色像素包围的内部白色不会被触及，
  ///   因此主体内部的白色得以保留。
  ///
  /// 流程：
  /// 1. 读取图片（image 包解码后即为 RGBA，等同于 BGR→RGB 转换）
  /// 2. 定义白色背景容差（R/G/B >= 225）
  /// 3. 从四边边缘所有白色像素出发 BFS 洪水填充
  /// 4. 被标记到的区域 = 背景（alpha=0, RGB 清零）
  /// 5. 未被标记的区域 = 主体（保留原始 RGB, alpha=255）
  /// 6. 形态学闭运算（先膨胀后腐蚀）封闭细缝、去除内部噪点
  /// 7. 保持图片原始尺寸不变
  static img.Image removeBackground(img.Image src) {
    final w = src.width;
    final h = src.height;
    final total = w * h;

    // ---- 步骤 1：定义白色背景容差 ----
    const int tolerance = 30;
    const int threshold = 255 - tolerance; // 225

    // ---- 步骤 2：标记所有"白色"像素 ----
    // isWhite[i] = 该像素接近白色
    final isWhite = List<bool>.filled(total, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        isWhite[y * w + x] = (p.r.toInt() >= threshold &&
                              p.g.toInt() >= threshold &&
                              p.b.toInt() >= threshold);
      }
    }

    // ---- 步骤 3：从四边边缘白色像素出发 BFS 洪水填充 ----
    // 对应 OpenCV: cv2.floodFill(mask, seedPoint=边缘点, newVal=背景标记)
    final visited = List<bool>.filled(total, false);
    final queue = <int>[];
    int head = 0;

    // 上边 & 下边
    for (int x = 0; x < w; x++) {
      final topIdx = x;
      final bottomIdx = (h - 1) * w + x;
      if (isWhite[topIdx] && !visited[topIdx]) {
        visited[topIdx] = true;
        queue.add(topIdx);
      }
      if (isWhite[bottomIdx] && !visited[bottomIdx]) {
        visited[bottomIdx] = true;
        queue.add(bottomIdx);
      }
    }
    // 左边 & 右边（跳过角）
    for (int y = 1; y < h - 1; y++) {
      final leftIdx = y * w;
      final rightIdx = y * w + (w - 1);
      if (isWhite[leftIdx] && !visited[leftIdx]) {
        visited[leftIdx] = true;
        queue.add(leftIdx);
      }
      if (isWhite[rightIdx] && !visited[rightIdx]) {
        visited[rightIdx] = true;
        queue.add(rightIdx);
      }
    }

    // BFS 展开
    while (head < queue.length) {
      final idx = queue[head++];
      final x = idx % w;
      final y = idx ~/ w;

      // 4-邻域
      if (x > 0) {
        final n = idx - 1;
        if (isWhite[n] && !visited[n]) { visited[n] = true; queue.add(n); }
      }
      if (x < w - 1) {
        final n = idx + 1;
        if (isWhite[n] && !visited[n]) { visited[n] = true; queue.add(n); }
      }
      if (y > 0) {
        final n = idx - w;
        if (isWhite[n] && !visited[n]) { visited[n] = true; queue.add(n); }
      }
      if (y < h - 1) {
        final n = idx + w;
        if (isWhite[n] && !visited[n]) { visited[n] = true; queue.add(n); }
      }
    }

    // ---- 步骤 4：形态学闭运算（先膨胀后腐蚀）封闭细缝 ----
    // visited=背景(1), 非visited=前景(0)
    final dilated = _morphDilateBool(visited, w, h, 3);
    final closed = _morphErodeBool(dilated, w, h, 3);

    // ---- 步骤 5：将掩码作为 Alpha 通道合并到原图 ----
    // 关键：必须显式创建 RGBA 格式图片（numChannels=4），否则 JPEG 等无 Alpha
    // 格式的源图会导致 setPixelRgba 的 alpha 被丢弃，背景显示为黑色
    // 背景像素（closed[i]=true）：RGBA (0,0,0,0) 完全透明
    // 主体像素（closed[i]=false）：保留原始 RGB，alpha=255
    final result = img.Image(width: w, height: h, numChannels: 4);
    for (int i = 0; i < total; i++) {
      final x = i % w;
      final y = i ~/ w;
      if (closed[i]) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        final p = src.getPixel(x, y);
        result.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }

    return result;
  }

  /// 形态学膨胀（bool 版）：对 true 区域执行最大值扩散
  static List<bool> _morphDilateBool(List<bool> mask, int w, int h, int kernel) {
    final result = List<bool>.filled(w * h, false);
    final half = kernel ~/ 2;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        bool found = false;
        outer:
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final nx = x + kx, ny = y + ky;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              if (mask[ny * w + nx]) { found = true; break outer; }
            }
          }
        }
        result[y * w + x] = found;
      }
    }
    return result;
  }

  /// 形态学腐蚀（bool 版）：对 true 区域执行最小值收缩
  static List<bool> _morphErodeBool(List<bool> mask, int w, int h, int kernel) {
    final result = List<bool>.filled(w * h, false);
    final half = kernel ~/ 2;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        bool all = true;
        outer:
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final nx = x + kx, ny = y + ky;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              if (!mask[ny * w + nx]) { all = false; break outer; }
            }
          }
        }
        result[y * w + x] = all;
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
    
    // 从源图区域采样：每个输出单元格取源图中对应区域的加权平均色
    // 逐像素采样可避免单点采样遗漏细线（如1px宽边框），同时正确处理 Alpha 通道
    final double cellW = sourceImage.width / targetWidth;
    final double cellH = sourceImage.height / targetHeight;
    
    // 颜色匹配：将每个像素匹配到最接近的MARD颜色
    final grid = <GridCell>[];
    final colorCounts = <String, int>{};
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        // 该输出单元格对应的源图区域范围
        final int srcX0 = (x * cellW).round().clamp(0, sourceImage.width - 1);
        final int srcY0 = (y * cellH).round().clamp(0, sourceImage.height - 1);
        final int srcX1 = ((x + 1) * cellW).round().clamp(srcX0, sourceImage.width);
        final int srcY1 = ((y + 1) * cellH).round().clamp(srcY0, sourceImage.height);
        
        // 对该区域内所有不透明像素取加权平均色
        int sumR = 0, sumG = 0, sumB = 0, count = 0;
        double weightedR = 0, weightedG = 0, weightedB = 0;
        double totalWeight = 0;
        
        for (int sy = srcY0; sy < srcY1; sy++) {
          for (int sx = srcX0; sx < srcX1; sx++) {
            final sp = sourceImage.getPixel(sx, sy);
            if (sp.a < 200) continue;
            final w = sp.a / 255.0;
            weightedR += sp.r * w;
            weightedG += sp.g * w;
            weightedB += sp.b * w;
            totalWeight += w;
            sumR += sp.r.toInt();
            sumG += sp.g.toInt();
            sumB += sp.b.toInt();
            count++;
          }
        }
        
        // 区域内全部透明：跳过
        if (count == 0) {
          grid.add(GridCell(x: x, y: y, color: null, isEmpty: true));
          continue;
        }
        
        // 使用 alpha 加权平均（若权重不足则回退到简单平均）
        final int avgR, avgG, avgB;
        if (totalWeight > 0.01) {
          avgR = (weightedR / totalWeight).round().clamp(0, 255);
          avgG = (weightedG / totalWeight).round().clamp(0, 255);
          avgB = (weightedB / totalWeight).round().clamp(0, 255);
        } else {
          avgR = (sumR ~/ count).clamp(0, 255);
          avgG = (sumG ~/ count).clamp(0, 255);
          avgB = (sumB ~/ count).clamp(0, 255);
        }
        
        // 找到最接近的MARD颜色
        final matchedColor = _findClosestColor(avgR, avgG, avgB, maxColors);
        
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
    
    // 颜色合并：将相似颜色合并为同一色号，统一边框等近似色
    _mergeSimilarColors(grid, colorCounts, maxColors);
    
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
  
  /// 计算颜色距离（加权RGB）
  /// 使用CIEDE2000的简化版本
  static double _colorDistanceRGB(int r1, int g1, int b1, int r2, int g2, int b2) {
    final  dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
    return (dr * dr + dg * dg + db * db).toDouble();
  }
  
  /// 合并相似颜色：将网格中色距极近的颜色统一为同一 Mard 色号
  /// 优先保留使用次数更多的颜色，将相近的低频颜色替换为高频颜色
  static void _mergeSimilarColors(
    List<GridCell> grid,
    Map<String, int> colorCounts,
    int maxColors,
  ) {
    const double mergeThreshold = 900.0; // RGB 欧氏距离平方阈值（约30）
    
    // 收集使用的颜色及其频次
    final entries = colorCounts.entries
        .map((e) => (code: e.key, count: e.value, mc: MardColorPalette.getByCode(e.key)!))
        .toList();
    if (entries.length <= maxColors) return;
    
    // 按使用次数降序排序
    entries.sort((a, b) => b.count.compareTo(a.count));
    
    // 保留颜色列表（code -> 是否保留）
    final kept = <String, String>{}; // 原始 code -> 合并后 code
    final keptColors = <(int, int, int)>[];
    final keptCodes = <String>[];
    
    for (final e in entries) {
      // 检查是否与已保留的颜色过于相似
      String? mergeInto;
      for (int i = 0; i < keptColors.length; i++) {
        final (kr, kg, kb) = keptColors[i];
        final d = _colorDistanceRGB(e.mc.r, e.mc.g, e.mc.b, kr, kg, kb);
        if (d < mergeThreshold) {
          mergeInto = keptCodes[i];
          break;
        }
      }
      
      if (mergeInto != null) {
        kept[e.code] = mergeInto;
      } else {
        kept[e.code] = e.code;
        keptColors.add((e.mc.r, e.mc.g, e.mc.b));
        keptCodes.add(e.code);
      }
    }
    
    // 应用颜色替换到网格
    for (final cell in grid) {
      if (cell.isEmpty || cell.color == null) continue;
      final merged = kept[cell.color!.code];
      if (merged != null && merged != cell.color!.code) {
        cell.color = MardColorPalette.getByCode(merged);
      }
    }
    
    // 重建颜色统计
    colorCounts.clear();
    for (final cell in grid) {
      if (cell.isEmpty || cell.color == null) continue;
      colorCounts[cell.color!.code] = (colorCounts[cell.color!.code] ?? 0) + 1;
    }
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
    const baseFontScale = 2;      // 2位色号基准字体

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

      // 色号居中：3位及以上的型号字体缩小 30%
      final code = cell.color!.code;
      final fontScale = code.length <= 2 ? baseFontScale : (baseFontScale * 0.7).round().clamp(1, 10);
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

      // 色号居中：3位及以上的型号字体缩小 30%
      final code = cell.color!.code;
      final effGridFont = code.length <= 2 ? gridFont : (gridFont * 0.7).round().clamp(1, 10);
      final tc = _textColorForBackground(mc.r, mc.g, mc.b);
      final tw = _textWidth(code, effGridFont);
      final tx = sx + (cellSize - tw) ~/ 2;
      final ty = sy + (cellSize - 7 * effGridFont) ~/ 2;
      _drawText(image, code, tx, ty, tc, effGridFont);
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
  MardColor? color;
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