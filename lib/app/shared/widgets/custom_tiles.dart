import 'package:flutter/material.dart';

class CustomTiles extends StatefulWidget {
  const CustomTiles(
      {Key? key, required this.label, required this.text, this.onTap})
      : super(key: key);

  final String label;
  final String text;
  final VoidCallback? onTap;

  @override
  State<CustomTiles> createState() => _CustomTilesState();
}

class _CustomTilesState extends State<CustomTiles> {
  late TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              widget.text,
              style: textTheme.titleSmall?.copyWith(fontSize: 16),
            ),
          ],
        ),
        widget.onTap != null
            ? IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.edit,
                  color: Colors.grey,
                ))
            : Container()
      ],
    );
  }
}
