import 'package:flutter/material.dart';

class TeacherAssignmentText extends StatelessWidget {
  const TeacherAssignmentText({
    required this.teacher,
    this.substituteTeacher = '',
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    super.key,
  });

  final String teacher;
  final String substituteTeacher;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final regular = teacher.trim();
    final substitute = substituteTeacher.trim();
    if (substitute.isEmpty || substitute == regular) {
      return Text(
        regular,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
    }
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: regular,
            style: base.copyWith(
              color: const Color(0xffD94B55),
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xffD94B55),
            ),
          ),
          TextSpan(text: '  →  ', style: base),
          TextSpan(
            text: substitute,
            style: base.copyWith(
              color: const Color(0xff168A58),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
