import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const WjjPindouApp());
}

class WjjPindouApp extends StatelessWidget {
  const WjjPindouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '拼豆图纸生成器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 蓝色主题配色
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // 蓝色作为主色调
          brightness: Brightness.light,
        ),
        
        // 自定义字体和样式
        fontFamily: null, // 使用系统默认字体，保证兼容性
        
        // AppBar 主题
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1565C0),
              width: 2,
            ),
          ),
        ),
        
        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        // 圆角配置
        useMaterial3: true,
      ),
      
      home: const HomePage(),
    );
  }
}