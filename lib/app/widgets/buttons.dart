part of 'widgets.dart';

class AppButtonPrimary extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  final String text;
  final double fontSize;
  final Color btnColor;
  final Color textColor;
  final VoidCallback onPressed;

  const AppButtonPrimary({
    super.key,
    required this.width,
    required this.height,
    this.radius = 10,
    this.fontSize = 14,
    this.btnColor = AppColor.green,
    this.textColor = AppColor.white,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          shadowColor: Colors.black,
          backgroundColor: btnColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        onPressed: () => onPressed(),
        child: Text(
          text,
          style: body2.copyWith(
            fontSize: fontSize,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class AppButtonOutlinedIcon extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  final String text;
  final Color textColor;
  final Color outlinedColor;
  final VoidCallback onPressed;
  const AppButtonOutlinedIcon({
    super.key,
    required this.height,
    required this.width,
    this.radius = 10,
    this.outlinedColor = AppColor.blue,
    this.textColor = AppColor.blue,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: outlinedColor,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: body1.copyWith(
                fontSize: 15,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppButtonLinear extends StatelessWidget {
  final double width;
  final double height;
  final Color color1;
  final Color color2;
  final Color backgroundColor;
  final Color shadowColor;
  final String text;
  final double radius;
  final VoidCallback onPressed;
  const AppButtonLinear({
    super.key,
    required this.width,
    required this.height,
    this.radius = 50,
    this.color1 = AppColor.blue,
    this.color2 = AppColor.purple,
    this.backgroundColor = Colors.transparent,
    this.shadowColor = Colors.transparent,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [color1, color2],
        ),
      ),
      child: ElevatedButton(
        onPressed: () => onPressed(),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shadowColor: shadowColor,
        ),
        child: Text(text),
      ),
    );
  }
}