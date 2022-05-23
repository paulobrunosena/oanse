import 'package:flutter/material.dart';

class BackgroundImage extends StatefulWidget {
  const BackgroundImage({
    Key? key,
  }) : super(key: key);

  @override
  State<BackgroundImage> createState() => _BackgroundImageState();
}

class _BackgroundImageState extends State<BackgroundImage> {
  late DecorationImage bground;

  @override
  void initState() {
    super.initState();
    bground = const DecorationImage(
      image: AssetImage('images/login_bg.jpg'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.black, Colors.black12],
        begin: Alignment.bottomCenter,
        end: Alignment.center,
      ).createShader(bounds),
      blendMode: BlendMode.darken,
      child: Container(
        decoration: BoxDecoration(
          image: bground,
        ),
      ),
    );
  }
}
