import 'package:flutter/material.dart';

class MarkdownTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(children: buildTextSpanChildren(text), style: style);
  }
}

class LupydMarkDown extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const LupydMarkDown({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
        TextSpan(children: buildTextSpanChildren(text), style: style));
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
      final textColor = Theme.of(context).primaryTextTheme.bodySmall?.color;
      style = widget.style.copyWith(backgroundColor: textColor);
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

List<InlineSpan> buildTextSpanChildren(String text) {
  final children = <InlineSpan>[];

  return children;
}
