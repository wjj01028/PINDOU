import 'package:flutter/material.dart';
import '../data/mard_colors.dart';
import '../helpers/layout_helper.dart';

/// 色卡浏览页面
class ColorPalettePage extends StatefulWidget {
  const ColorPalettePage({super.key});

  @override
  State<ColorPalettePage> createState() => _ColorPalettePageState();
}

class _ColorPalettePageState extends State<ColorPalettePage> {
  String _selectedSeries = 'A';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('MARD 221色卡',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索颜色',
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSeriesNav(),
          _buildSeriesInfo(),
          Expanded(child: _buildColorGrid()),
        ],
      ),
    );
  }

  Widget _buildSeriesNav() {
    final seriesList = MardColorPalette.getSeriesList();
    final bodySz = LayoutHelper.bodySize(context);

    return Container(
      height: LayoutHelper.isWide(context) ? 56 : 44,
      margin: EdgeInsets.symmetric(
          horizontal: LayoutHelper.gap(context),
          vertical: LayoutHelper.isWide(context) ? 12 : 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seriesList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = seriesList[index];
          final isSelected = _selectedSeries == s['code'];
          return GestureDetector(
            onTap: () => setState(() => _selectedSeries = s['code']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s['code'],
                      style: TextStyle(
                          fontSize: bodySz - 2,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0D47A1))),
                  Text('${s['count']}色',
                      style: TextStyle(
                          fontSize: LayoutHelper.smallSize(context) - 2,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey.shade600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeriesInfo() {
    final series = MardColorPalette.getSeriesList()
        .firstWhere((s) => s['code'] == _selectedSeries);
    final pad = LayoutHelper.gap(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: pad),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getSeriesPreviewColor(_selectedSeries),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${series['code']}系 · ${series['name']}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1))),
                Text('共 ${series['count']} 种颜色',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ]),
          Icon(Icons.palette_outlined,
              color: const Color(0xFF0D47A1), size: 32),
        ],
      ),
    );
  }

  Color _getSeriesPreviewColor(String series) {
    final colors = MardColorPalette.getBySeries(series);
    if (colors.isEmpty) return Colors.white;
    return colors.first.toColor();
  }

  Widget _buildColorGrid() {
    final colors = MardColorPalette.getBySeries(_selectedSeries);
    final columns = LayoutHelper.gridColumns(context);
    final pad = LayoutHelper.gap(context);

    return GridView.builder(
      padding: EdgeInsets.all(pad),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) => _buildColorCard(colors[index]),
    );
  }

  Widget _buildColorCard(MardColor color) {
    final textColor =
        color.r + color.g + color.b > 380 ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: () => _showColorDetail(color),
      child: Container(
        decoration: BoxDecoration(
          color: color.toColor(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.toColor().withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Text(color.code,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(color.hex,
                  style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.8))),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorDetail(MardColor color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: LayoutHelper.isWide(context) ? 400 : 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: color.toColor(),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Center(
                  child: Text(color.code,
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: color.r + color.g + color.b > 380
                              ? Colors.black87
                              : Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text('${color.code} · ${color.seriesName}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBDEFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _info('HEX', color.hex),
                        _info('RGB',
                            '${color.r}, ${color.g}, ${color.b}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('关闭'),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1))),
      ],
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索颜色'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入色号，如 A1、B2...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final color =
                  MardColorPalette.getByCode(value.toUpperCase());
              if (color != null) {
                Navigator.pop(context);
                setState(() => _selectedSeries = color.series);
                _showColorDetail(color);
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
