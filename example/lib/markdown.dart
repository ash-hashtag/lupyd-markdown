import 'package:lupyd_markdown_parser/lupyd_markdown_parser.dart';
import 'package:flutter/material.dart';

Iterable<InlineSpan> parseTextToSpans(String text) {
  final inputPart = PatternMatchPart(text: text, type: []);
  final results = parseText(inputPart, defaultMatchers());
  debugPrint(results.toString());

  final spans = results.map(matchPartToSpan);
  return spans;
}

InlineSpan matchPartToSpan(PatternMatchPart part) {
  FontWeight? fontWeight;
  Color? color;
  TextDecoration? textDecoration;
  FontStyle? fontStyle;
  double? fontSize;
  for (final type in part.type) {
    switch (type) {
      case "quote":
        {
          return WidgetSpan(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 3),
                ),
              ),
              padding: const EdgeInsets.only(left: 4),
              child: Text(part.text),
            ),
          );
        }
      case "bold":
        {
          fontWeight = FontWeight.bold;
          break;
        }
      case "italic":
        {
          fontStyle = FontStyle.italic;
          break;
        }
      case "header":
        {
          fontWeight = FontWeight.w900;
          fontSize = 48;
          break;
        }
      case "hashtag":
        {
          fontWeight = FontWeight.bold;
          color = Colors.grey;
          break;
        }
      case "mention":
        {
          fontWeight = FontWeight.bold;
          color = Colors.black;
          break;
        }

      case "hyperlink":
        {
          final regex = RegExp(r"\[(.+)\]\((.+)\)");
          final match = regex.firstMatch(part.text);
          if (match != null) {
            if (match.groupCount == 2) {
              final word = match.group(0);
              final link = match.group(1);
              if (word != null && link != null) {
                return TextSpan(children: [
                  TextSpan(
                      text: word,
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue)),
                  TextSpan(
                      text: link,
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey)),
                ]);
              }
            }
          }
          break;
        }

      default:
    }
  }

  final style = TextStyle(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    decoration: textDecoration,
  );

  return TextSpan(text: part.text, style: style);
}

String removeEscapeCharacters(String text) {
  String output = "";
  int i = 0;
  while (true) {
    if (text[i] == '\\') {
      if (text.length > i + 1) {
        i++;
      }
    }

    output += text[i];
    i++;

    if (text.length <= i) {
      break;
    }
  }
  return output;
}
