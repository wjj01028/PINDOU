import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../helpers/layout_helper.dart';

/// 裁剪页面图片控件的背景色
/// 用于在透明 PNG 区域显示醒目背景，方便区分主体与透明区
const Color kCropImageBackgroundColor = Color(0xFFFFD600);

/// 裁剪范围选择页面
class CropPage extends StatefulWidget {
  final Uint8List imageBytes;
  const CropPage({super.key, required this.imageBytes});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  int _imageWidth = 1;
  int _imageHeight = 1;

  double _cropLeft = 0, _cropTop = 0, _cropRight = 0, _cropBottom = 0;
  double? _dragStartX, _dragStartY;
  double? _dragStartLeft, _dragStartTop, _dragStartRight, _dragStartBottom;
  String? _dragHandle;
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    setState(() {
      _imageWidth = image.width;
      _imageHeight = image.height;
    });
  }

  void _onPanStart(DragStartDetails details, Size renderSize) {
    if (_imageWidth == 1) return;
    final scaleX = _imageWidth / renderSize.width;
    final scaleY = _imageHeight / renderSize.height;
    final px = details.localPosition.dx * scaleX;
    final py = details.localPosition.dy * scaleY;

    if (_hasSelection) {
      const hitDist = 20.0;
      _dragHandle = _hitTest(px, py, hitDist * scaleX);
      if (_dragHandle != null) {
        _dragStartX = px;
        _dragStartY = py;
        _dragStartLeft = _cropLeft;
        _dragStartTop = _cropTop;
        _dragStartRight = _cropRight;
        _dragStartBottom = _cropBottom;
        return;
      }
    }
    _dragHandle = 'se';
    _dragStartX = px;
    _dragStartY = py;
    _cropLeft = _cropRight = px;
    _cropTop = _cropBottom = py;
    _hasSelection = false;
    setState(() {});
  }

  String? _hitTest(double px, double py, double d) {
    if ((px - _cropLeft).abs() < d && (py - _cropTop).abs() < d) return 'nw';
    if ((px - _cropRight).abs() < d && (py - _cropTop).abs() < d) return 'ne';
    if ((px - _cropLeft).abs() < d && (py - _cropBottom).abs() < d) return 'sw';
    if ((px - _cropRight).abs() < d && (py - _cropBottom).abs() < d) return 'se';
    if (py >= _cropTop - d && py <= _cropBottom + d) {
      if (px >= _cropLeft && px <= _cropRight) return 'move';
      if ((px - _cropLeft).abs() < d && py > _cropTop && py < _cropBottom) return 'w';
      if ((px - _cropRight).abs() < d && py > _cropTop && py < _cropBottom) return 'e';
    }
    if (px >= _cropLeft - d && px <= _cropRight + d) {
      if ((py - _cropTop).abs() < d && px > _cropLeft && px < _cropRight) return 'n';
      if ((py - _cropBottom).abs() < d && px > _cropLeft && px < _cropRight) return 's';
    }
    return null;
  }

  void _onPanUpdate(DragUpdateDetails details, Size renderSize) {
    if (_dragHandle == null) return;
    final scaleX = _imageWidth / renderSize.width;
    final scaleY = _imageHeight / renderSize.height;
    final px = details.localPosition.dx * scaleX;
    final py = details.localPosition.dy * scaleY;

    double nl = _cropLeft, nt = _cropTop, nr = _cropRight, nb = _cropBottom;
    switch (_dragHandle) {
      case 'nw': nl = px.clamp(0, _cropRight - 10); nt = py.clamp(0, _cropBottom - 10); break;
      case 'ne': nr = px.clamp(_cropLeft + 10, _imageWidth.toDouble()); nt = py.clamp(0, _cropBottom - 10); break;
      case 'sw': nl = px.clamp(0, _cropRight - 10); nb = py.clamp(_cropTop + 10, _imageHeight.toDouble()); break;
      case 'se': nr = px.clamp(_cropLeft + 10, _imageWidth.toDouble()); nb = py.clamp(_cropTop + 10, _imageHeight.toDouble()); break;
      case 'n': nt = py.clamp(0, _cropBottom - 10); break;
      case 's': nb = py.clamp(_cropTop + 10, _imageHeight.toDouble()); break;
      case 'w': nl = px.clamp(0, _cropRight - 10); break;
      case 'e': nr = px.clamp(_cropLeft + 10, _imageWidth.toDouble()); break;
      case 'move':
        final dx = px - _dragStartX!, dy = py - _dragStartY!;
        final w = _dragStartRight! - _dragStartLeft!, h = _dragStartBottom! - _dragStartTop!;
        nl = (_dragStartLeft! + dx).clamp(0, _imageWidth - w);
        nt = (_dragStartTop! + dy).clamp(0, _imageHeight - h);
        nr = nl + w;
        nb = nt + h;
        break;
    }
    setState(() { _cropLeft = nl; _cropTop = nt; _cropRight = nr; _cropBottom = nb; });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragHandle = null;
    if (!_hasSelection && (_cropRight - _cropLeft).abs() > 10 && (_cropBottom - _cropTop).abs() > 10) {
      _hasSelection = true;
    }
    setState(() {});
  }

  (int, int, int, int) _getCropRect() {
    return (
      _cropLeft.round().clamp(0, _imageWidth - 1),
      _cropTop.round().clamp(0, _imageHeight - 1),
      _cropRight.round().clamp(2, _imageWidth),
      _cropBottom.round().clamp(2, _imageHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btnSz = LayoutHelper.bodySize(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('选择生成范围'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasSelection)
            IconButton(
                icon: const Icon(Icons.clear),
                tooltip: '清除选区',
                onPressed: () => setState(() {
                      _hasSelection = false;
                      _cropLeft = _cropRight = _cropTop = _cropBottom = 0;
                    })),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = LayoutHelper.isWide(context)
            ? constraints.maxHeight - 120
            : constraints.maxHeight - 100;

        double renderW, renderH;
        if (_imageWidth / _imageHeight > availW / availH) {
          renderW = availW;
          renderH = availW * _imageHeight / _imageWidth;
        } else {
          renderH = availH;
          renderW = availH * _imageWidth / _imageHeight;
        }
        final scaleX = renderW / _imageWidth;
        final scaleY = renderH / _imageHeight;

        return Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanStart: (d) => _onPanStart(d, Size(renderW, renderH)),
                onPanUpdate: (d) => _onPanUpdate(d, Size(renderW, renderH)),
                onPanEnd: _onPanEnd,
                child: Center(
                  child: SizedBox(
                    width: renderW,
                    height: renderH,
                    child: Stack(
                      children: [
                        Container(color: kCropImageBackgroundColor),
                        Image.memory(widget.imageBytes, width: renderW, height: renderH, fit: BoxFit.fill),
                        if (_hasSelection) ...[
                          // 四周暗色遮罩
                          Positioned(left: 0, top: 0, width: renderW, height: _cropTop * scaleY,
                              child: Container(color: Colors.black.withValues(alpha: 0.5))),
                          Positioned(left: 0, top: _cropBottom * scaleY, width: renderW, height: renderH - _cropBottom * scaleY,
                              child: Container(color: Colors.black.withValues(alpha: 0.5))),
                          Positioned(left: 0, top: _cropTop * scaleY, width: _cropLeft * scaleX, height: (_cropBottom - _cropTop) * scaleY,
                              child: Container(color: Colors.black.withValues(alpha: 0.5))),
                          Positioned(left: _cropRight * scaleX, top: _cropTop * scaleY, width: renderW - _cropRight * scaleX,
                              height: (_cropBottom - _cropTop) * scaleY,
                              child: Container(color: Colors.black.withValues(alpha: 0.5))),
                        ],
                        if (_hasSelection || _cropRight - _cropLeft > 0)
                          Positioned(
                            left: _cropLeft * scaleX,
                            top: _cropTop * scaleY,
                            width: (_cropRight - _cropLeft) * scaleX,
                            height: (_cropBottom - _cropTop) * scaleY,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF42A5F5), width: 2)),
                                child: Stack(children: [
                                  _corner(0, 0),
                                  _corner((_cropRight - _cropLeft) * scaleX, 0),
                                  _corner(0, (_cropBottom - _cropTop) * scaleY),
                                  _corner((_cropRight - _cropLeft) * scaleX, (_cropBottom - _cropTop) * scaleY),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 底部操作栏
            Container(
              color: Colors.grey.shade900,
              padding: EdgeInsets.symmetric(
                  horizontal: LayoutHelper.horizontalPadding(context),
                  vertical: LayoutHelper.isWide(context) ? 16 : 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: EdgeInsets.symmetric(vertical: LayoutHelper.isWide(context) ? 18 : 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('取消', style: TextStyle(fontSize: btnSz)),
                      ),
                    ),
                    SizedBox(width: LayoutHelper.smallGap(context)),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _hasSelection ? () => Navigator.pop(context, _getCropRect()) : null,
                        icon: const Icon(Icons.check),
                        label: Text(
                          _hasSelection
                              ? '确认 (${(_cropRight - _cropLeft).round()}×${(_cropBottom - _cropTop).round()}px)'
                              : '请在图片上拖拽框选范围',
                          style: TextStyle(fontSize: btnSz),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade700,
                          disabledForegroundColor: Colors.grey.shade400,
                          padding: EdgeInsets.symmetric(vertical: LayoutHelper.isWide(context) ? 18 : 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _corner(double left, double top) {
    return Positioned(
      left: left - 8,
      top: top - 8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFF42A5F5),
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
