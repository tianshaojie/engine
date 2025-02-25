// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

bool get isIosSafari =>
    browserEngine == BrowserEngine.webkit &&
    operatingSystem == OperatingSystem.iOs;

/// Some text measurements are sensitive to browser implementations. Position
/// info in the following tests only pass in Chrome, they are slightly different
/// on each browser. So we need to ignore position info on non-Chrome browsers
/// when comparing expectations with actual output.
bool get isBlink => browserEngine == BrowserEngine.blink;

String fontFamilyToAttribute(String fontFamily) {
  fontFamily = canonicalizeFontFamily(fontFamily)!;
  if (browserEngine == BrowserEngine.firefox) {
    return fontFamily.replaceAll('"', '&quot;');
  } else if (browserEngine == BrowserEngine.blink ||
      browserEngine == BrowserEngine.samsung ||
      browserEngine == BrowserEngine.webkit) {
    return fontFamily.replaceAll('"', '');
  }
  return fontFamily;
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  await initializeTestFlutterViewEmbedder();

  test('Builds a text-only canvas paragraph', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'Hello');
    expect(paragraph.spans, hasLength(1));

    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, fontSize: 13)}">'
      'Hello'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );

    // Should break "Hello" into "Hel" and "lo".
    paragraph.layout(const ParagraphConstraints(width: 39.0));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, fontSize: 13)}">'
      'Hel'
      '</span>'
      '<span style="${spanStyle(top: 13, left: 0, fontSize: 13)}">'
      'lo'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );

    final ParagraphSpan span = paragraph.spans.single;
    expect(span, isA<FlatTextSpan>());
    final FlatTextSpan textSpan = span as FlatTextSpan;
    expect(textSpan.textOf(paragraph), 'Hello');
    expect(textSpan.style, styleWithDefaults(fontSize: 13.0));
  });

  test('Correct defaults', () {
    final EngineParagraphStyle style = EngineParagraphStyle();
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'Hello');
    expect(paragraph.spans, hasLength(1));

    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="${paragraphStyle()}">'
      '<span style="${spanStyle(top: 0, left: 0)}">'
      'Hello'
      '</span>'
      '</p>',
    );

    final FlatTextSpan textSpan = paragraph.spans.single as FlatTextSpan;
    expect(textSpan.style, styleWithDefaults());
  });

  test('Sets correct styles for max-lines', () {
    final EngineParagraphStyle style = EngineParagraphStyle(maxLines: 2);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'Hello');

    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="${paragraphStyle()}">'
      '<span style="${spanStyle(top: 0, left: 0)}">'
      'Hello'
      '</span>'
      '</p>',
    );
  });

  test('Sets correct styles for ellipsis', () {
    final EngineParagraphStyle style = EngineParagraphStyle(ellipsis: '...');
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('HelloWorld');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'HelloWorld');

    paragraph.layout(const ParagraphConstraints(width: 100.0));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="${paragraphStyle()}">'
      '<span style="${spanStyle(top: 0, left: 0)}">'
      'Hell...'
      '</span>'
      '</p>',
    );
  });

  test('Builds a single-span paragraph with complex styles', () {
    final EngineParagraphStyle style =
        EngineParagraphStyle(fontSize: 13.0, height: 1.5);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.pushStyle(TextStyle(fontSize: 9.0));
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.pushStyle(TextStyle(fontSize: 40.0));
    builder.pop();
    builder
        .pushStyle(TextStyle(fontStyle: FontStyle.italic, letterSpacing: 2.0));
    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'Hello');
    expect(paragraph.spans, hasLength(1));

    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="${paragraphStyle(lineHeight: 1.5, fontSize: 9)}">'
      '<span style="${spanStyle(top: 0, left: 0, lineHeight: 1.5, fontSize: 9, fontWeight: 'bold', fontStyle: 'italic', letterSpacing: 2)}">'
      'Hello'
      '</span>'
      '</p>',
    );

    final FlatTextSpan span = paragraph.spans.single as FlatTextSpan;
    expect(span.textOf(paragraph), 'Hello');
    expect(
      span.style,
      styleWithDefaults(
        height: 1.5,
        fontSize: 9.0,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        letterSpacing: 2.0,
      ),
    );
  });

  test('Builds a multi-span paragraph', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.addText('Hello');
    builder.pop();
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText(' world');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'Hello world');
    expect(paragraph.spans, hasLength(2));

    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, fontSize: 13, fontWeight: 'bold')}">'
      'Hello'
      '</span>'
      '<span style="${spanStyle(top: 0, left: 65, fontSize: 13, fontStyle: 'italic')}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: 0, left: 78, fontSize: 13, fontStyle: 'italic')}">'
      'world'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );

    // Should break "Hello world" into 2 lines: "Hello" and " world".
    paragraph.layout(const ParagraphConstraints(width: 75.0));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, fontSize: 13, fontWeight: 'bold')}">'
      'Hello'
      '</span>'
      '<span style="${spanStyle(top: 0, left: 65, fontSize: 13, fontStyle: 'italic')}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: 13, left: 0, fontSize: 13, fontStyle: 'italic')}">'
      'world'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );

    final FlatTextSpan hello = paragraph.spans.first as FlatTextSpan;
    expect(hello.textOf(paragraph), 'Hello');
    expect(
      hello.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
      ),
    );

    final FlatTextSpan world = paragraph.spans.last as FlatTextSpan;
    expect(world.textOf(paragraph), ' world');
    expect(
      world.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontStyle: FontStyle.italic,
      ),
    );
  });

  test('Builds a multi-span paragraph with complex styles', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.pushStyle(TextStyle(height: 2.0));
    builder.addText('Hello');
    builder.pop(); // pop TextStyle(height: 2.0).
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText(' world');
    builder.pushStyle(TextStyle(fontWeight: FontWeight.normal));
    builder.addText('!');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'Hello world!');
    expect(paragraph.spans, hasLength(3));

    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, lineHeight: 2, fontSize: 13, fontWeight: 'bold')}">'
      'Hello'
      '</span>'
      '<span style="${spanStyle(top: 6, left: 65, fontSize: 13, fontWeight: 'bold', fontStyle: 'italic')}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: 6, left: 78, fontSize: 13, fontWeight: 'bold', fontStyle: 'italic')}">'
      'world'
      '</span>'
      '<span style="${spanStyle(top: 6, left: 143, fontSize: 13, fontWeight: 'normal', fontStyle: 'italic')}">'
      '!'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );

    final FlatTextSpan hello = paragraph.spans[0] as FlatTextSpan;
    expect(hello.textOf(paragraph), 'Hello');
    expect(
      hello.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
        height: 2.0,
      ),
    );

    final FlatTextSpan world = paragraph.spans[1] as FlatTextSpan;
    expect(world.textOf(paragraph), ' world');
    expect(
      world.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
    );

    final FlatTextSpan bang = paragraph.spans[2] as FlatTextSpan;
    expect(bang.textOf(paragraph), '!');
    expect(
      bang.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.italic,
      ),
    );
  });

  test('Paragraph with new lines generates correct DOM', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('First\nSecond ');
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText('ThirdLongLine');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'First\nSecond ThirdLongLine');
    expect(paragraph.spans, hasLength(2));

    // There's a new line between "First" and "Second", but "Second" and
    // "ThirdLongLine" remain together since constraints are infinite.
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, fontSize: 13)}">'
      'First'
      '</span>'
      '<span style="${spanStyle(top: 13, left: 0, fontSize: 13)}">'
      'Second'
      '</span>'
      '<span style="${spanStyle(top: 13, left: 78, fontSize: 13)}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: 13, left: 91, fontSize: 13, fontStyle: 'italic')}">'
      'ThirdLongLine'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );

    // Should break the paragraph into "First", "Second" and "ThirdLongLine".
    paragraph.layout(const ParagraphConstraints(width: 180.0));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 13)}">'
      '<span style="${spanStyle(top: 0, left: 0, fontSize: 13)}">'
      'First'
      '</span>'
      '<span style="${spanStyle(top: 13, left: 0, fontSize: 13)}">'
      'Second'
      '</span>'
      '<span style="${spanStyle(top: 13, left: 78, fontSize: 13)}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: 26, left: 0, fontSize: 13, fontStyle: 'italic')}">'
      'ThirdLongLine'
      '</span>'
      '</p>',
      ignorePositions: !isBlink,
    );
  });

  test('various font sizes', () {
    // Paragraphs and spans force the Ahem font in test mode. We need to trick
    // them into thinking they are not in test mode, so they use the provided
    // font family.
    debugEmulateFlutterTesterEnvironment = false;
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 12.0, fontFamily: 'first');
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('First ');
    builder.pushStyle(TextStyle(fontSize: 18.0, fontFamily: 'second'));
    builder.addText('Second ');
    builder.pushStyle(TextStyle(fontSize: 10.0, fontFamily: 'third'));
    builder.addText('Third');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'First Second Third');
    expect(paragraph.spans, hasLength(3));

    // The paragraph should take the font size and family from the span with the
    // greatest font size.
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expectOuterHtml(
      paragraph,
      '<p style="${paragraphStyle(fontSize: 18, fontFamily: 'second')}">'
      '<span style="${spanStyle(top: null, left: null, fontSize: 12, fontFamily: 'first')}">'
      'First'
      '</span>'
      '<span style="${spanStyle(top: null, left: null, fontSize: 12, fontFamily: 'first')}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: null, left: null, fontSize: 18, fontFamily: 'second')}">'
      'Second'
      '</span>'
      '<span style="${spanStyle(top: null, left: null, fontSize: 18, fontFamily: 'second')}">'
      ' '
      '</span>'
      '<span style="${spanStyle(top: null, left: null, fontSize: 10, fontFamily: 'third')}">'
      'Third'
      '</span>'
      '</p>',
      // Since we are using unknown font families, we can't predict the text
      // measurements.
      ignorePositions: true,
    );
    debugEmulateFlutterTesterEnvironment = true;
  });
}

const String defaultFontFamily = 'Ahem';
const num defaultFontSize = 14;

String paragraphStyle({
  String fontFamily = defaultFontFamily,
  num fontSize = defaultFontSize,
  num? lineHeight,
}) {
  return <String>[
    if (lineHeight != null) 'line-height: $lineHeight;',
    'font-size: ${fontSize}px;',
    'font-family: ${fontFamilyToAttribute(fontFamily)};',
    'position: absolute;',
    'white-space: pre;',
  ].join(' ');
}

String spanStyle({
  required num? top,
  required num? left,
  String fontFamily = defaultFontFamily,
  num fontSize = defaultFontSize,
  String? fontWeight,
  String? fontStyle,
  num? lineHeight,
  num? letterSpacing,
}) {
  return <String>[
    'color: rgb(255, 0, 0);',
    if (lineHeight != null) 'line-height: $lineHeight;',
    'font-size: ${fontSize}px;',
    if (fontWeight != null) 'font-weight: $fontWeight;',
    if (fontStyle != null) 'font-style: $fontStyle;',
    'font-family: ${fontFamilyToAttribute(fontFamily)};',
    if (letterSpacing != null) 'letter-spacing: ${letterSpacing}px;',
    'position: absolute;',
    if (top != null) 'top: ${top}px;',
    if (left != null) 'left: ${left}px;',
  ].join(' ');
}

TextStyle styleWithDefaults({
  Color color = const Color(0xFFFF0000),
  String fontFamily = FlutterViewEmbedder.defaultFontFamily,
  double fontSize = FlutterViewEmbedder.defaultFontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    height: height,
    letterSpacing: letterSpacing,
  );
}

void expectOuterHtml(CanvasParagraph paragraph, String expected, {required bool ignorePositions}) {
  String outerHtml = paragraph.toDomElement().outerHtml!;
  if (ignorePositions) {
    outerHtml = removePositionInfo(outerHtml);
    expected = removePositionInfo(expected);
  }

  expect(outerHtml, expected);
}

/// Removes "top" and "left" CSS styles from the given html string.
///
/// This is needed when the positioning information in the html output is
/// unknown and could be different depending on browser and environment.
String removePositionInfo(String outerHtml) {
  return outerHtml
      .replaceAll(RegExp(r'\s*top:\s*[\d\.]+px\s*;\s*'), '')
      .replaceAll(RegExp(r'\s*left:\s*[\d\.]+px\s*;\s*'), '');
}
