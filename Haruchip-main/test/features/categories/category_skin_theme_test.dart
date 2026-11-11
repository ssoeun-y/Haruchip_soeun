import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haruchip/features/categories/models/category.dart';
import 'package:haruchip/features/categories/widgets/skin_theme_card_container.dart';

void main() {
  group('CategorySkinTheme Model & Presets', () {
    test('CategorySkinTheme default constructor and getters', () {
      const theme = CategorySkinTheme(
        id: 'test_theme',
        name: '테스트 테마',
        backgroundColor: '#FFE8F0',
        patternType: 'dot',
        patternColor: '#FFFFFF',
        patternOpacity: 0.25,
        borderStyle: 'solid',
        borderColor: '#FF85A2',
        borderWidth: 2.0,
        borderRadius: 16.0,
        accentEmoji: '💖',
        textColor: '#111827',
      );

      expect(theme.id, 'test_theme');
      expect(theme.name, '테스트 테마');
      expect(theme.backgroundColor, '#FFE8F0');
      expect(theme.patternTypeEnum, SkinPatternType.dot);
      expect(theme.patternColor, '#FFFFFF');
      expect(theme.patternOpacity, 0.25);
      expect(theme.borderStyleEnum, SkinBorderStyle.solid);
      expect(theme.borderColor, '#FF85A2');
      expect(theme.borderWidth, 2.0);
      expect(theme.borderRadius, 16.0);
      expect(theme.accentEmoji, '💖');
      expect(theme.textColor, '#111827');
    });

    test('CategorySkinTheme JSON serialization and deserialization (round-trip)', () {
      const original = CategorySkinTheme(
        id: 'cyber_pink_2000',
        name: '사이버 핑크 2000',
        backgroundColor: '#FFE8F0',
        patternType: 'pixel_heart',
        patternColor: '#FF69B4',
        patternOpacity: 0.35,
        borderStyle: 'window98_bevel',
        borderColor: '#808080',
        borderWidth: 3.0,
        borderRadius: 0.0,
        accentEmoji: '💻',
        textColor: '#000080',
      );

      final json = original.toJson();
      final recovered = CategorySkinTheme.fromJson(json);

      expect(recovered.id, original.id);
      expect(recovered.name, original.name);
      expect(recovered.backgroundColor, original.backgroundColor);
      expect(recovered.patternType, original.patternType);
      expect(recovered.patternTypeEnum, SkinPatternType.pixelHeart);
      expect(recovered.patternColor, original.patternColor);
      expect(recovered.patternOpacity, original.patternOpacity);
      expect(recovered.borderStyle, original.borderStyle);
      expect(recovered.borderStyleEnum, SkinBorderStyle.window98Bevel);
      expect(recovered.borderColor, original.borderColor);
      expect(recovered.borderWidth, original.borderWidth);
      expect(recovered.borderRadius, original.borderRadius);
      expect(recovered.accentEmoji, original.accentEmoji);
      expect(recovered.textColor, original.textColor);
    });

    test('Y2kSkinPresets contains all 6 curated presets with valid values', () {
      expect(Y2kSkinPresets.all.length, 6);

      // 1. 사이버 핑크 2000
      final pink = Y2kSkinPresets.cyberPink2000;
      expect(pink.name, '사이버 핑크 2000');
      expect(pink.patternTypeEnum, SkinPatternType.dot);
      expect(pink.borderStyleEnum, SkinBorderStyle.solid);

      // 2. 윈도우 픽셀 클래식
      final win = Y2kSkinPresets.windowsPixelClassic;
      expect(win.name, '윈도우 픽셀 클래식');
      expect(win.borderStyleEnum, SkinBorderStyle.window98Bevel);
      expect(win.borderRadius, 0.0); // sharp 90-degree corners

      // 3. 밀크 옐로우 다이어리
      final milk = Y2kSkinPresets.milkYellowDiary;
      expect(milk.name, '밀크 옐로우 다이어리');
      expect(milk.patternTypeEnum, SkinPatternType.grid);
      expect(milk.borderStyleEnum, SkinBorderStyle.dashed);

      // 4. 민트 소다 레트로
      final mint = Y2kSkinPresets.mintSodaRetro;
      expect(mint.name, '민트 소다 레트로');
      expect(mint.patternTypeEnum, SkinPatternType.pixelHeart);
      expect(mint.borderStyleEnum, SkinBorderStyle.retroDouble);

      // 5. 클린 미니멀
      final clean = Y2kSkinPresets.cleanMinimal;
      expect(clean.name, '클린 미니멀');
      expect(clean.borderStyleEnum, SkinBorderStyle.none);

      // 6. 스트라이프 레트로
      final stripe = Y2kSkinPresets.stripeRetro;
      expect(stripe.name, '스트라이프 레트로');
      expect(stripe.patternTypeEnum, SkinPatternType.diagonalStripes);
      expect(stripe.borderStyleEnum, SkinBorderStyle.dotted);
    });

    test('CategoryModel.skinTheme integration via metadata', () {
      final categoryWithoutTheme = CategoryModel(
        id: 'cat-1',
        categoryKey: 'custom',
        name: '일상',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(categoryWithoutTheme.skinTheme, isNull);

      final skinTheme = Y2kSkinPresets.cyberPink2000;
      final categoryWithTheme = categoryWithoutTheme.copyWith(
        metadata: {
          'skinTheme': skinTheme.toJson(),
        },
      );

      expect(categoryWithTheme.skinTheme, isNotNull);
      expect(categoryWithTheme.skinTheme!.id, 'cyber_pink_2000');
      expect(categoryWithTheme.skinTheme!.name, '사이버 핑크 2000');
      expect(categoryWithTheme.skinTheme!.patternTypeEnum, SkinPatternType.dot);

      // Test CategoryModel.fromJson round-trip with metadata skinTheme
      final catJson = categoryWithTheme.toJson();
      final restored = CategoryModel.fromJson(catJson);
      expect(restored.skinTheme, isNotNull);
      expect(restored.skinTheme!.id, 'cyber_pink_2000');
      expect(restored.skinTheme!.backgroundColor, '#FFE8F0');
    });
  });

  group('SkinThemeCardContainer Widget Rendering', () {
    testWidgets('renders child and custom borders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkinThemeCardContainer(
                theme: Y2kSkinPresets.windowsPixelClassic,
                width: 300,
                height: 200,
                child: const Text('Windows 98 Retro'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Windows 98 Retro'), findsOneWidget);
      expect(find.byType(SkinThemeCardContainer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders dot pattern and handles onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkinThemeCardContainer(
                theme: Y2kSkinPresets.cyberPink2000,
                width: 250,
                height: 150,
                onTap: () => tapped = true,
                child: const Text('Cyber Pink'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cyber Pink'), findsOneWidget);
      await tester.tap(find.text('Cyber Pink'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders double border and grid pattern without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkinThemeCardContainer(
                theme: Y2kSkinPresets.mintSodaRetro,
                width: 280,
                height: 180,
                child: const Text('Mint Soda Retro'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mint Soda Retro'), findsOneWidget);
    });
  });
}
