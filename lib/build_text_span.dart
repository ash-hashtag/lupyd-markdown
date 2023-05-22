import 'package:flutter/material.dart';

List<InlineSpan> buildTextSpanChildren(String text) {
  final children = <InlineSpan>[];
  var lastFilled = 0;

  var i = 0;
  var limit = 1000;
  while (limit > 0) {
    if (text.startsWith("***", i)) {
      var span = TextSpan(text: text.substring(lastFilled, i));
      children.add(span);
      lastFilled = i;
      final index = text.indexOf("***", i + 3);
      if (index != -1) {
        span = TextSpan(
            text: text.substring(i, index),
            style: TextStyle(fontWeight: FontWeight.bold));
        children.add(span);
        i = index + 3;
        lastFilled = i;
      }
    }
    i++;
    if (i >= text.length) {
      break;
    }
    limit--;
  }

  final span = TextSpan(text: text.substring(lastFilled));
  children.add(span);

  print(children.length);

  return children;
}
