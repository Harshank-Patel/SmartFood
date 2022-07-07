import 'package:flutter/material.dart';
import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

class Header extends StatelessWidget {
  const Header(this.heading);
  final String heading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          heading,
          style: const TextStyle(fontSize: 24, color: Colors.black54),
        ),
      );
}

class Paragraph extends StatelessWidget {
  const Paragraph(this.content);
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          style: const TextStyle(fontSize: 18),
        ),
      );
}

class IconAndDetail extends StatelessWidget {
  const IconAndDetail(this.icon, this.detail);
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(fontSize: 18),
            )
          ],
        ),
      );
}

class StyledButton extends StatelessWidget {
  const StyledButton({required this.child, required this.onPressed});
  final Widget child;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: ElevatedButton.styleFrom(
          primary: const Color.fromRGBO(210, 210, 210, 1.0),
          onPrimary: const Color.fromRGBO(100, 100, 100, 1.0),
        ),
        onPressed: onPressed,
        child: child,
      );
}

class MyElevatedButton extends StatelessWidget {
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double height;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final Widget child;

  const MyElevatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.borderRadius,
    this.width,
    this.height = 44.0,
    this.gradient = const LinearGradient(colors: [
      Color.fromRGBO(118, 232, 163, 1.0),
      Color.fromRGBO(70, 223, 120, 1.0),
    ]),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          primary: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: child,
      ),
    );
  }
}

class CustomColor {
  static MaterialColor generateMaterialColor(Color color) {
    return MaterialColor(color.value, {
      50: tintColor(color, 0.9),
      100: tintColor(color, 0.8),
      200: tintColor(color, 0.6),
      300: tintColor(color, 0.4),
      400: tintColor(color, 0.2),
      500: color,
      600: shadeColor(color, 0.1),
      700: shadeColor(color, 0.2),
      800: shadeColor(color, 0.3),
      900: shadeColor(color, 0.4),
    });
  }

  static int tintValue(int value, double factor) =>
      max(0, min((value + ((255 - value) * factor)).round(), 255));

  static Color tintColor(Color color, double factor) => Color.fromRGBO(
      tintValue(color.red, factor),
      tintValue(color.green, factor),
      tintValue(color.blue, factor),
      1);

  static int shadeValue(int value, double factor) =>
      max(0, min(value - (value * factor).round(), 255));

  static Color shadeColor(Color color, double factor) => Color.fromRGBO(
      shadeValue(color.red, factor),
      shadeValue(color.green, factor),
      shadeValue(color.blue, factor),
      1);
}

class RecipeCard extends StatelessWidget {
  RecipeCard({
    Key? key,
    required this.title,
    required this.usedIng,
    required this.missIng,
    required this.imageURL,
    required this.desc,
    required this.url,
  }) : super(key: key);

  String title;
  String imageURL;
  String desc;
  String url;
  List<String> usedIng;
  List<String> missIng;

  void _launchURL() async {
    print(url);
    if (!await launch(url)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () async {
          debugPrint("Used: ${usedIng}");
          debugPrint("Miss: ${missIng}");

          // Redirect to URL
          _launchURL();
        },
        child: SizedBox(
          child: DecoratedBox(
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 195, 195, 195),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(
                      image: NetworkImage(imageURL),
                    ),
                  ),
                  // Image.network(imageURL),
                  const SizedBox(height: 15),
                  Flexible(child: SingleChildScrollView(child: Text(desc))),
                  // Text(desc),
                ],
              ),
            ),
          ),
        ));
  }
}
