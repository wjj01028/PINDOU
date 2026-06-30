import 'package:flutter/material.dart';
import '../services/pixel_converter.dart';
import '../data/mard_colors.dart';
import '../helpers/layout_helper.dart';

/// 材料清单页面
class MaterialListPage extends StatefulWidget {
  final PatternResult result;

  const MaterialListPage({super.key, required this.result});

  @override
  State<MaterialListPage> createState() => _MaterialListPageState();
}

class _MaterialListPageState extends State<MaterialListPage> {
  String _selectedSeries = '全部';
  bool _showDetails = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('材料清单',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showDetails ? Icons.view_list : Icons.view_agenda),
            tooltip: '切换视图',
            onPressed: () => setState(() => _showDetails = !_showDetails),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildSeriesFilter(),
          Expanded(child: _buildMaterialList()),
          _buildBottomTip(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final pad = LayoutHelper.gap(context);
    return Container(
      margin: EdgeInsets.all(pad),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('所需材料汇总',
                      style: TextStyle(
                          fontSize: LayoutHelper.titleSize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.result.colorCount}种颜色 · ${widget.result.totalBeads}颗豆子',
                    style: TextStyle(
                        fontSize: LayoutHelper.smallSize(context),
                        color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: 32),
                    SizedBox(height: 4),
                    Text('采购清单',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: widget.result.materialList.take(15).map((item) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.color.toColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.all(2),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesFilter() {
    final seriesList = MardColorPalette.getSeriesList();
    final usedSeries = <String>{};
    for (final item in widget.result.materialList) {
      usedSeries.add(item.color.series);
    }

    final pad = LayoutHelper.gap(context);
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: pad),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('全部', usedSeries.length),
          const SizedBox(width: 8),
          ...seriesList.where((s) => usedSeries.contains(s['code'])).map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                '${s['code']} ${s['name']}',
                widget.result.materialList
                    .where((m) => m.color.series == s['code'])
                    .length,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedSeries == label;
    return FilterChip(
      label: Row(children: [
        Text(label),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey.shade600)),
        ),
      ]),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedSeries = label),
      selectedColor: const Color(0xFF1565C0),
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF1565C0)
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildMaterialList() {
    final filteredList = _selectedSeries == '全部'
        ? widget.result.materialList
        : widget.result.materialList
            .where((m) =>
                '${m.color.series} ${m.color.seriesName}' ==
                _selectedSeries)
            .toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text('没有找到相关颜色'));
    }

    final columns = LayoutHelper.gridColumns(context);
    final pad = LayoutHelper.gap(context);

    return GridView.builder(
      padding: EdgeInsets.all(pad),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredList.length,
      itemBuilder: (context, index) =>
          _buildMaterialCard(filteredList[index]),
    );
  }

  Widget _buildMaterialCard(MaterialItem item) {
    final bodySz = LayoutHelper.bodySize(context);
    return GestureDetector(
      onTap: () => _showColorDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: item.color.toColor(),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.color.code,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.color.code,
                        style: TextStyle(
                            fontSize: bodySz,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D47A1))),
                    if (_showDetails)
                      Text(item.color.seriesName,
                          style: TextStyle(
                              fontSize: LayoutHelper.smallSize(context),
                              color: Colors.grey.shade500)),
                    Text('${item.count}颗',
                        style: TextStyle(
                            fontSize: LayoutHelper.smallSize(context),
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorDetail(MaterialItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: item.color.toColor(),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.color.code,
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color:
                                item.color.r + item.color.g + item.color.b >
                                        380
                                    ? Colors.black87
                                    : Colors.white)),
                    Text(item.color.seriesName,
                        style: TextStyle(
                            fontSize: 16,
                            color:
                                item.color.r + item.color.g + item.color.b >
                                        380
                                    ? Colors.black54
                                    : Colors.white
                                        .withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _detail('色号', item.color.code),
                    _detail('HEX', item.color.hex),
                    _detail('数量', '${item.count}颗'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _detail('R', '${item.color.r}'),
                    _detail('G', '${item.color.g}'),
                    _detail('B', '${item.color.b}'),
                  ],
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
    );
  }

  Widget _detail(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1))),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }

  Widget _buildBottomTip() {
    return Container(
      padding: EdgeInsets.all(LayoutHelper.gap(context)),
      decoration: BoxDecoration(
        color: const Color(0xFFBBDEFB),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(children: [
          Icon(Icons.info_outline,
              color: const Color(0xFF0D47A1), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '建议：高频消耗色（如H1白色、H16黑色）建议多备一些',
              style: TextStyle(
                  fontSize: LayoutHelper.smallSize(context),
                  color: Colors.grey.shade700),
            ),
          ),
        ]),
      ),
    );
  }
}
