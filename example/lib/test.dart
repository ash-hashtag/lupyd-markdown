import 'package:example/markdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const urlRegexRawString =
    r"[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)";

String invisibleString(int length) =>
    String.fromCharCodes(List.filled(length, 8203));

extension on String {
  String repeat(int length) => List.filled(length, this).join();
}

bool isEscaping(String s, int index) {
  var i = 0;
  while (index - i >= 0 && s[index - i] == '\\') {
    i++;
  }
  return i.isOdd;
}

class TextSpanChildrenResult {
  final List<InlineSpan> children;
  final List<GestureRecognizer> gestureRecognizers;

  const TextSpanChildrenResult(
      {this.children = const [], this.gestureRecognizers = const []});

  void dispose() {
    gestureRecognizers.forEach((e) => e.dispose());
  }
}

List<InlineSpan> buildTextSpanChildren(
  String text, {
  bool forController = false,
  void Function(String)? onUserTap,
  void Function(String)? onHashtagtap,
  void Function(String)? onGroupTap,
  void Function(String)? onPostTap,
}) {
  final children = <InlineSpan>[];
  const fadedStyle = TextStyle(color: Colors.grey);
  if (text.isEmpty) {
    return children;
  }
  var lastFilled = 0;

  var i = 0;
  var limit = 1000;

  String replaceBackSlash(String s) {
    final st = List<int>.from(s.codeUnits);
    for (var i = 0; i < st.length; i++) {
      if (st[i] == 92) {
        if (i + 1 < st.length && st[i + 1] == 92) {
          st[i + 1] = 8203;
        } else {
          st[i] = 8203;
        }
      }
    }
    return String.fromCharCodes(st);
    // return s.replaceAll('\\', '\u200B');
  }

  InlineSpan? replaceBackSlashSpanForController(String s, [TextStyle? style]) {
    if (s.isEmpty) {
      return null;
    }
    const backSlashSpan = TextSpan(text: '\\', style: fadedStyle);
    final replaceBackSlashChildren = <InlineSpan>[];
    var lastFilled = 0;
    while (true) {
      final index = s.indexOf('\\', lastFilled);
      if (index == -1) {
        if (lastFilled == 0) {
          return TextSpan(text: s, style: style);
          //   replaceBackSlashChildren.add(TextSpan(text: s, style: style));
          //   break;
        }
        final st = s.substring(lastFilled);
        if (st.isNotEmpty) {
          final span = TextSpan(text: st, style: style);
          replaceBackSlashChildren.add(span);
        }
        break;
      } else {
        final st = s.substring(lastFilled, index);
        // if (st.isEmpty) {
        //   break;
        // }
        final span = TextSpan(text: st, style: style);
        if (index + 1 < s.length) {
          lastFilled = index + 1;
          if (st.isNotEmpty) replaceBackSlashChildren.add(span);
          if (forController) replaceBackSlashChildren.add(backSlashSpan);
          if (s[index + 1] == '\\') {
            replaceBackSlashChildren.add(const TextSpan(text: '\\'));
            lastFilled += 1;
          }
        } else {
          lastFilled = index + 1;
          if (st.isNotEmpty) replaceBackSlashChildren.add(span);
          if (forController) replaceBackSlashChildren.add(backSlashSpan);
        }
      }
    }

    return TextSpan(children: replaceBackSlashChildren);
  }

  InlineSpan? replaceBackSlashSpan(String s, [TextStyle? style]) {
    final st = List<int>.from(s.codeUnits);
    for (var i = 0; i < st.length; i++) {
      if (isEscaping(s, i)) {
        st[i] = 8203;
      }
      if (st[i] == 92) {
        if (i + 1 < st.length && st[i + 1] == 92) {
          st[i + 1] = 8203;
        } else {
          st[i] = 8203;
        }
      }
    }

    final newString = String.fromCharCodes(st);

    if (newString.isEmpty) {
      return null;
    }

    return TextSpan(text: newString, style: style);
  }

  void fillNormalGap() {
    if (forController) {
      final span =
          replaceBackSlashSpanForController(text.substring(lastFilled, i));
      if (span != null) children.add(span);
    } else {
      final _ = replaceBackSlash(text.substring(lastFilled, i));
      if (_.isNotEmpty) {
        final span = replaceBackSlashSpan(_);
        if (span != null) {
          children.add(span);
        }
      }
    }
  }

  void checkForTripleStack(String s, TextStyle style) {
    if (i > 0) {
      if (isEscaping(text, i - 1)) {
        return;
      }
    }
    if (text.startsWith(s, i)) {
      fillNormalGap();
      lastFilled = i;
      final index = text.indexOf(s, i + 3);
      if (index != -1) {
        if (isEscaping(text, index - 1)) {
          return;
        }
        final span = replaceBackSlashSpan(text.substring(i + 3, index), style);
        if (span != null) {
          if (forController) {
            final cover = TextSpan(text: s, style: fadedStyle);
            children.addAll([cover, span, cover]);
          } else {
            children.add(span);
          }
        }
        i = index + 3;
        lastFilled = i;
      }
    }
  }

  void checkForSpoiler() {
    const s = "|||";
    if (i > 0) {
      if (isEscaping(text, i - 1)) {
        return;
      }
      // if (text[i - 1] == '\\') {
      //   return;
      // }
    }
    if (text.startsWith(s, i)) {
      // final _ = text.substring(lastFilled, i).replaceAll('\\', '');
      // if (_.isNotEmpty) {
      //   final span = TextSpan(text: _);
      //   children.add(span);
      // }
      fillNormalGap();
      lastFilled = i;
      final index = text.indexOf(s, i + 3);
      if (index != -1) {
        if (text[index - 1] == '\\') {
          return;
        }
        final spanText = text.substring(i + 3, index);
        final span =
            WidgetSpan(child: SpoilerSpan(text: replaceBackSlash(spanText)));
        if (forController) {
          final cover = TextSpan(text: s, style: fadedStyle);
          children.addAll([cover, TextSpan(text: spanText), cover]);
        } else {
          children.add(span);
        }
        i = index + 3;
        lastFilled = i;
      }
    }
  }

  void checkForQuote() {
    if (i != 0 && text[i - 1] != '\n') {
      return;
    }
    const s = ">| ";
    if (text.startsWith(s, i)) {
      // final _ = text.substring(lastFilled, i).replaceAll('\\', '');
      // if (_.isNotEmpty) {
      //   final span = TextSpan(text: _);
      //   children.add(span);
      // }
      fillNormalGap();
      lastFilled = i;
      final index = text.indexOf('\n', i + 3);
      late final InlineSpan span;
      late final String spanText;
      if (index == -1) {
        spanText = text.substring(i + 3);
        span = WidgetSpan(child: QuoteText(text: spanText));
        lastFilled = text.length;
        i = lastFilled;
      } else {
        spanText = text.substring(i + 3, index);
        span = WidgetSpan(child: QuoteText(text: spanText));
        lastFilled = index;
        i = index;
      }
      if (forController) {
        final cover = TextSpan(text: s, style: fadedStyle);
        children.addAll([cover, TextSpan(text: spanText)]);
      } else {
        children.add(span);
      }
      // children.add(span);
    }
  }

  // void checkForMentions() {
  //   if (i < text.length && text[i] == '@') {
  //     // final _ = text.substring(lastFilled, i).replaceAll('\\', '');
  //     // if (_.isNotEmpty) {
  //     //   final span = TextSpan(text: _);
  //     //   children.add(span);
  //     // }
  //     fillNormalGap();
  //     lastFilled = i;
  //     var j = i + 1;
  //     while (j < text.length) {
  //       if (text[j] == ' ' || text[j] == '\n' || text[j] == '\t') {
  //         final userName = text.substring(i, j);
  //         final span = WidgetSpan(
  //           child: GestureDetector(
  //             onTap: () => debugPrint(":$userName:"),
  //             child: Text(
  //               userName,
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //           ),
  //         );
  //         children.add(span);
  //         lastFilled = j;
  //         i = j;
  //         return;
  //       }
  //       j++;
  //     }
  //     final userName = text.substring(i);
  //     final span = WidgetSpan(
  //       child: GestureDetector(
  //         onTap: () => debugPrint(":$userName:"),
  //         child: Text(userName,
  //             style: const TextStyle(fontWeight: FontWeight.bold)),
  //       ),
  //     );
  //     ;
  //     children.add(span);
  //     lastFilled = text.length;
  //     i = lastFilled;
  //   }
  // }

  // void checkForHashtags() {
  //   if (i < text.length && text[i] == '#') {
  //     fillNormalGap();
  //     lastFilled = i;
  //     var j = i + 1;

  //     const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.blue);
  //     while (j < text.length) {
  //       if (text[j] == ' ' || text[j] == '\n' || text[j] == '\t') {
  //         final hashTag = text.substring(i, j);
  //         late final InlineSpan span;
  //         if (forController) {
  //           span = TextSpan(text: hashTag, style: style);
  //         } else {
  //           span = WidgetSpan(
  //             child: GestureDetector(
  //               onTap: () => debugPrint(":$hashTag:"),
  //               child: Text(hashTag, style: style),
  //             ),
  //           );
  //         }
  //         children.add(span);
  //         lastFilled = j;
  //         i = j;
  //         return;
  //       }
  //       j++;
  //     }
  //     final hashTag = text.substring(i);
  //     late final InlineSpan span;
  //     if (forController) {
  //       span = TextSpan(text: hashTag, style: style);
  //     } else {
  //       span = WidgetSpan(
  //         child: GestureDetector(
  //           onTap: () => debugPrint(":$hashTag:"),
  //           child: Text(hashTag, style: style),
  //         ),
  //       );
  //     }

  //     children.add(span);
  //     lastFilled = text.length;
  //     i = lastFilled;
  //   }
  // }

  void checkForSingleWordSingleLetterStartTags(
      String startChar, TextStyle style,
      {void Function(String)? onTap, RegExp? additionalRegexCheck}) {
    if (i > 0 && isEscaping(text, i - 1)) {
      return;
    }
    if (i < text.length && text[i] == startChar) {
      fillNormalGap();
      lastFilled = i;
      var j = i + 1;

      // const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.blue);
      while (j < text.length) {
        if (text[j] == ' ' || text[j] == '\n' || text[j] == '\t') {
          final tag = text.substring(i, j);
          final innerText = tag.substring(1);
          if (additionalRegexCheck != null &&
              innerText.isNotEmpty &&
              additionalRegexCheck.stringMatch(innerText) != innerText) {
            return;
          }
          late final InlineSpan span;
          if (forController) {
            span = TextSpan(text: tag, style: style);
          } else {
            span = WidgetSpan(
              child: GestureDetector(
                onTap: () => (onTap ?? debugPrint)(tag),
                child: Text(tag, style: style),
              ),
            );
          }
          children.add(span);
          lastFilled = j;
          i = j;
          return;
        }
        j++;
      }
      final tag = text.substring(i);
      final innerText = tag.substring(1);
      if (additionalRegexCheck != null &&
          innerText.isNotEmpty &&
          additionalRegexCheck.stringMatch(innerText) != innerText) {
        return;
      }
      late final InlineSpan span;
      if (forController) {
        span = TextSpan(text: tag, style: style);
      } else {
        span = WidgetSpan(
          child: GestureDetector(
            onTap: () => (onTap ?? debugPrint)(tag),
            child: Text(tag, style: style),
          ),
        );
      }

      children.add(span);
      lastFilled = text.length;
      i = lastFilled;
    }
  }

  while (limit > 0) {
    checkForTripleStack("***", const TextStyle(fontWeight: FontWeight.bold));
    checkForTripleStack("///", const TextStyle(fontStyle: FontStyle.italic));
    checkForTripleStack(
        "___", const TextStyle(decoration: TextDecoration.underline));
    checkForTripleStack(
        "---", const TextStyle(decoration: TextDecoration.lineThrough));
    checkForTripleStack(
        "###", const TextStyle(fontWeight: FontWeight.bold, fontSize: 48));
    checkForSpoiler();
    checkForQuote();
    checkForSingleWordSingleLetterStartTags('#',
        const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
        additionalRegexCheck: RegExp(r"[a-zA-Z]"));
    checkForSingleWordSingleLetterStartTags('@',
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold));
    checkForSingleWordSingleLetterStartTags('\$',
        const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    i++;
    if (i >= text.length) {
      break;
    }
    limit--;
  }

  i = text.length;
  fillNormalGap();
  if (forController) debugPrint(children.toString());

  return children;
}

class MarkupText extends StatefulWidget {
  final TextEditingController controller;
  const MarkupText({super.key, required this.controller});

  @override
  State<MarkupText> createState() => _MarkupTextState();
}

class _MarkupTextState extends State<MarkupText> {
  late var text = widget.controller.text;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  void listener() => setState(() => text = widget.controller.text);

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: TextSpan(
            children: parseTextToSpans(text).toList(),
            style: TextStyle(color: Colors.black)));
    // return RichText(
    //     text: TextSpan(
    //         children: buildTextSpanChildren(text),
    //         style: TextStyle(color: Colors.black)));
  }
}

class SpoilerSpan extends StatefulWidget {
  final String text;
  final TextStyle style;
  const SpoilerSpan(
      {super.key, required this.text, this.style = const TextStyle()});

  @override
  State<SpoilerSpan> createState() => _SpoilerSpanState();
}

class _SpoilerSpanState extends State<SpoilerSpan> {
  var isHidden = true;

  @override
  Widget build(BuildContext context) {
    late final TextStyle style;
    if (isHidden) {
      final textColor = Colors.black;
      style =
          widget.style.copyWith(backgroundColor: textColor, color: textColor);
    } else {
      style = widget.style;
    }
    return GestureDetector(
        onTap: onTap, child: Text(widget.text, style: style));
  }

  void onTap() {
    setState(() => isHidden = !isHidden);
  }
}

class QuoteText extends StatelessWidget {
  final String text;
  const QuoteText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(width: 3))),
      padding: EdgeInsets.only(left: 4),
      child: Text(text),
    );
  }
}

class MarkupEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final children = buildTextSpanChildren(text, forController: true);
    return TextSpan(children: children, style: style);
  }
}
