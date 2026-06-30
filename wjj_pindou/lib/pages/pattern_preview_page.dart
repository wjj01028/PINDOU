import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import '../services/pixel_converter.dart';
import '../helpers/layout_helper.dart';
import 'material_list_page.dart';

import 'package:path_provider/path_provider.dart';

/// 图纸预览页面
class PatternPreviewPage extends StatefulWidget {
  final PatternResult result;
  final XFile originalImage;

  const PatternPreviewPage({
    super.key,
    required this.result,
    required this.originalImage,
  });

  @override
  State<PatternPreviewPage> createState() => _PatternPreviewPageState();
}

class _PatternPreviewPageState extends State<PatternPreviewPage> {
  Uint8List? _previewBytes;
  Uint8List? _gridBytes;
  Uint8List? _exportBytes;

  bool _showGrid = true;
  bool _fullscreen = false;

  final TransformationController _transformCtrl =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _generateImages();
    _generateExportBytes();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _generateImages() {
    // 拼豆效果
    final preview =
        PixelConverter.generatePreviewImage(widget.result, 24);
    _previewBytes = Uint8List.fromList(img.encodePng(preview));

    // 带色号网格
    final grid = PixelConverter.generatePreviewGrid(widget.result);
    _gridBytes = Uint8List.fromList(img.encodePng(grid));
  }

  void _generateExportBytes() {
    final exportImage =
        PixelConverter.generateExportImage(widget.result);
    _exportBytes = Uint8List.fromList(img.encodePng(exportImage));
  }

  Future<void> _shareImage() async {
    try {
      final bytes = _exportBytes!;
      final fileName =
          'pindou_${widget.result.width}x${widget.result.height}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file =
          XFile.fromData(bytes, name: fileName, mimeType: 'image/png');
      await Share.shareXFiles(
        [file],
        text:
            '拼豆图纸 ${widget.result.width}×${widget.result.height} - ${widget.result.totalBeads}豆 / ${widget.result.colorCount}色',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('分享失败: $e')));
    }
  }

  Future<void> _saveImage() async {
    try {
      final bytes = _exportBytes!;
      final fileName =
          'pindou_${widget.result.width}x${widget.result.height}_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请使用分享功能下载图片'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图纸已保存到: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _fullscreen ? Colors.black : const Color(0xFFF5F5F5),
      appBar: _fullscreen
          ? null
          : AppBar(
              title: const Text('图纸预览',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareImage,
                    tooltip: '分享'),
                IconButton(
                    icon: const Icon(Icons.save_alt),
                    onPressed: _saveImage,
                    tooltip: '保存'),
              ],
            ),
      body: Column(
        children: [
          if (!_fullscreen) ...[
            _buildStatsCard(),
            _buildToggleRow(),
          ],
          Expanded(child: _buildZoomablePreview()),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
              '尺寸',
              '${widget.result.width}×${widget.result.height}',
              Icons.grid_on),
          _buildStat(
              '颜色', '${widget.result.colorCount}色', Icons.palette),
          _buildStat(
              '豆数', '${widget.result.totalBeads}', Icons.circle),
          _buildStat('底板',
              '${(widget.result.width / 29).ceil()}块', Icons.dashboard),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MaterialListPage(result: widget.result)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list_alt,
                      size: 20,
                      color: Colors.white),
                  const SizedBox(width: 4),
                  Text('清单',
                      style: TextStyle(
                          fontSize: LayoutHelper.bodySize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon,
            size: LayoutHelper.isWide(context) ? 26 : 22,
            color: const Color(0xFF0D47A1)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: LayoutHelper.bodySize(context),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1))),
        Text(label,
            style: TextStyle(
                fontSize: LayoutHelper.smallSize(context),
                color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildToggleRow() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: LayoutHelper.horizontalPadding(context)),
      child: Row(
        children: [
          _buildToggleBtn('拼豆效果', false),
          const SizedBox(width: 8),
          _buildToggleBtn('色号网格', true),
          const Spacer(),
          IconButton(
            icon: Icon(
                _fullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                size: 22),
            tooltip: _fullscreen ? '退出全屏' : '全屏查看',
            onPressed: () =>
                setState(() => _fullscreen = !_fullscreen),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map, size: 22),
            tooltip: '重置缩放',
            onPressed: _resetZoom,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isGrid) {
    final active = _showGrid == isGrid;
    final sz = LayoutHelper.bodySize(context);
    return ElevatedButton(
      onPressed: () => setState(() => _showGrid = isGrid),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            active ? const Color(0xFF1565C0) : Colors.grey.shade200,
        foregroundColor: active ? Colors.white : Colors.grey.shade700,
        padding: EdgeInsets.symmetric(
            horizontal: LayoutHelper.isWide(context) ? 32 : 20,
            vertical: LayoutHelper.isWide(context) ? 12 : 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: TextStyle(fontSize: sz)),
    );
  }

  Widget _buildZoomablePreview() {
    final bytes = _showGrid ? _gridBytes : _previewBytes;
    if (bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.3,
          maxScale: 10.0,
          panEnabled: true,
          scaleEnabled: true,
          constrained: false,
          child: Center(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
        if (_fullscreen)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: _buildFloatingToolbar(),
          ),
      ],
    );
  }

  Widget _buildFloatingToolbar() {
    return Row(
      children: [
        _buildMiniBtn(Icons.photo_library_outlined,
            () => setState(() => _showGrid = !_showGrid),
            _showGrid ? '效果' : '网格'),
        const SizedBox(width: 4),
        _buildMiniBtn(Icons.zoom_out_map, _resetZoom, '1:1'),
        const SizedBox(width: 4),
        _buildMiniBtn(Icons.fullscreen_exit,
            () => setState(() => _fullscreen = false), '退出'),
      ],
    );
  }

  Widget _buildMiniBtn(IconData icon, VoidCallback onTap, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

}

