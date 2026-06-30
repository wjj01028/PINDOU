import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../services/pixel_converter.dart';
import '../helpers/layout_helper.dart';
import 'pattern_preview_page.dart';
import 'color_palette_page.dart';
import 'crop_page.dart';

/// 主页面 - 图片上传和参数设置
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  int _beadWidth = 29;
  int _maxColors = 25;
  bool _isProcessing = false;
  PatternResult? _result;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _result = null;
        });
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      _showError('请先选择一张图片');
      return;
    }
    final bytes = await _selectedImage!.readAsBytes();
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      // 1. 在原图上抠除背景，生成透明 PNG
      final image = img.decodeImage(bytes);
      if (image == null) {
        _showError('无法解析图片');
        return;
      }
      final maskedImage = PixelConverter.removeBackground(image);
      // 将抠图结果编码为 PNG 字节，确保 Alpha 通道完整序列化
      final maskedBytes = Uint8List.fromList(img.encodePng(maskedImage));

      // 1.1 将透明 PNG 保存到原图同目录，命名 原图名_clear.png
      _saveMaskedImage(maskedBytes);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 2. 进入裁剪页面，显示抠图后的结果
      final cropResult = await Navigator.push<(int, int, int, int)>(
        context,
        MaterialPageRoute(
          builder: (context) => CropPage(imageBytes: maskedBytes),
        ),
      );

      if (cropResult == null || !mounted) return;

      final (cropX, cropY, cropW, cropH) = cropResult;

      setState(() => _isProcessing = true);

      // 3. 从 PNG 字节重新解码，保证 Alpha 通道完整，然后裁剪并生成图纸
      final decoded = img.decodeImage(maskedBytes);
      if (decoded == null) {
        _showError('解码图片失败');
        return;
      }
      final croppedImage = img.copyCrop(
        decoded, x: cropX, y: cropY, width: cropW - cropX, height: cropH - cropY,
      );
      final result = PixelConverter.convert(
        sourceImage: croppedImage,
        beadWidth: _beadWidth,
        maxColors: _maxColors,
      );
      setState(() => _result = result);

      if (_result != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatternPreviewPage(
              result: _result!,
              originalImage: _selectedImage!,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('处理图片失败: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveMaskedImage(Uint8List pngBytes) {
    try {
      final srcPath = _selectedImage?.path;
      if (srcPath == null) return;
      final dir = p.dirname(srcPath);
      final baseName = p.basenameWithoutExtension(srcPath);
      final outPath = p.join(dir, '${baseName}_clear.png');
      File(outPath).writeAsBytesSync(pngBytes);
    } catch (_) {
      // 保存失败不阻塞主流程
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = LayoutHelper.horizontalPadding(context);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: _buildAppBar(),
          body: LayoutHelper.isWide(context)
              ? _buildWideLayout(pad)
              : _buildPhoneLayout(pad),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '正在生成拼豆图纸...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ======== 宽屏布局：左右分栏 ========
  Widget _buildWideLayout(double pad) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：图片选择 + 设置
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildImagePickerSection(),
                    const SizedBox(height: 20),
                    _buildSettingsSection(),
                    const SizedBox(height: 20),
                    _buildProcessButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // 右侧：快速统计（如果有结果）
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  if (_result != null) _buildQuickStats(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== 手机布局：垂直滚动 ========
  Widget _buildPhoneLayout(double pad) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildImagePickerSection(),
            const SizedBox(height: 20),
            _buildSettingsSection(),
            const SizedBox(height: 20),
            _buildProcessButton(),
            // if (_result != null) ...[
            //   const SizedBox(height: 20),
            //   _buildQuickStats(),
            // ],
          ],
        ),
      ),
    );
  }

  // =============================================================
  //           构建方法（均使用 LayoutHelper 动态值）
  // =============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        '拼豆图纸生成器',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: '查看色卡',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ColorPalettePage()),
            );
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF90CAF9), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(LayoutHelper.gap(context)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final colors = [
                const Color(0xFFFFD67D),
                const Color(0xFF9EF780),
                const Color(0xFF41CCFF),
                const Color(0xFFAC7BDE),
                const Color(0xFFFFB7E7),
                const Color(0xFFFC3D46),
                const Color(0xFFC4AEAD),
              ];
              final sz = LayoutHelper.isWide(context) ? 24.0 : 20.0;
              return Container(
                width: sz,
                height: sz,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: colors[i].withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: LayoutHelper.smallGap(context)),
          Text(
            '将你的照片变成拼豆图纸',
            style: TextStyle(
              fontSize: LayoutHelper.titleSize(context),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '使用 MARD 221色拼豆 • 5mm标准豆',
            style: TextStyle(
              fontSize: LayoutHelper.smallSize(context),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              height: LayoutHelper.imagePickerHeight(context),
              decoration: BoxDecoration(
                color: _selectedImage == null
                    ? const Color(0xFFF8F8F8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FutureBuilder<Uint8List>(
                        future: _selectedImage!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(snapshot.data!,
                                fit: BoxFit.contain);
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child:
                                    Text('加载图片失败: ${snapshot.error}'));
                          }
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: LayoutHelper.isWide(context) ? 64 : 48,
                            color: const Color(0xFF1565C0)
                                .withValues(alpha: 0.6)),
                        SizedBox(
                            height: LayoutHelper.smallGap(context)),
                        Text(
                          '点击选择图片',
                          style: TextStyle(
                            fontSize: LayoutHelper.bodySize(context),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '支持 JPG、PNG 格式',
                          style: TextStyle(
                            fontSize: LayoutHelper.smallSize(context),
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: LayoutHelper.smallGap(context)),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: LayoutHelper.isWide(context) ? 24 : 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('相册'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: LayoutHelper.isWide(context) ? 16 : 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: LayoutHelper.smallGap(context)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('拍照'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: LayoutHelper.isWide(context) ? 16 : 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: LayoutHelper.smallGap(context)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final titleSz = LayoutHelper.titleSize(context);
    return Container(
      padding: EdgeInsets.all(LayoutHelper.gap(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: const Color(0xFF1565C0), size: 24),
              const SizedBox(width: 8),
              Text(
                '参数设置',
                style: TextStyle(
                  fontSize: titleSz,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          SizedBox(height: LayoutHelper.smallGap(context)),
          _buildSliderSetting(
            label: '图纸宽度',
            value: _beadWidth.toDouble(),
            min: 10,
            max: 100,
            unit: '豆',
            onChanged: (v) => setState(() => _beadWidth = v.round()),
            description: '推荐：29豆 = 1块标准底板',
          ),
          SizedBox(height: LayoutHelper.smallGap(context)),
          _buildSliderSetting(
            label: '最大颜色数',
            value: _maxColors.toDouble(),
            min: 5,
            max: 50,
            unit: '色',
            onChanged: (v) => setState(() => _maxColors = v.round()),
            description: '颜色越少，制作越简单',
          ),
          SizedBox(height: LayoutHelper.smallGap(context)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '快速预设：',
                style: TextStyle(
                    fontSize: LayoutHelper.smallSize(context),
                    color: Colors.grey),
              ),
              _buildPresetButton('入门', 20, 15),
              _buildPresetButton('标准', 29, 25),
              _buildPresetButton('精细', 50, 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
    required String description,
  }) {
    final bodySz = LayoutHelper.bodySize(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: bodySz, fontWeight: FontWeight.w500)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} $unit',
                style: TextStyle(
                  fontSize: bodySz,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF1565C0),
            inactiveTrackColor: const Color(0xFFE3F2FD),
            thumbColor: const Color(0xFF0D47A1),
            overlayColor:
                const Color(0xFF1565C0).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Text(description,
            style: TextStyle(
                fontSize: LayoutHelper.smallSize(context),
                color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildPresetButton(String label, int width, int colors) {
    final isSelected = _beadWidth == width && _maxColors == colors;
    return GestureDetector(
      onTap: () => setState(() {
        _beadWidth = width;
        _maxColors = colors;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1565C0)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1565C0)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    final h = LayoutHelper.buttonHeight(context);
    return Container(
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _selectedImage != null
              ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
              : [Colors.grey.shade300, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _selectedImage != null
            ? [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _selectedImage != null && !_isProcessing
              ? _processImage
              : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isProcessing
                      ? Icons.hourglass_empty
                      : Icons.auto_fix_high,
                  color: _selectedImage != null
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  _isProcessing ? '处理中...' : '生成拼豆图纸',
                  style: TextStyle(
                    fontSize: LayoutHelper.titleSize(context),
                    fontWeight: FontWeight.bold,
                    color: _selectedImage != null
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_result == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(LayoutHelper.gap(context)),
      decoration: BoxDecoration(
        color: const Color(0xFFBBDEFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              Icons.grid_on, '${_result!.width}×${_result!.height}', '尺寸'),
          _buildStatItem(
              Icons.palette, '${_result!.colorCount}', '颜色'),
          _buildStatItem(
              Icons.circle, '${_result!.totalBeads}', '豆数'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 24),
        const SizedBox(height: 4),
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
}
