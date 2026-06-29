import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomButton extends StatefulWidget {
  final String textInfo;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? clr;
  
  const CustomButton({
    super.key,
    required this.textInfo,
    required this.onPressed,
    this.isLoading = false,
    this.clr,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 200,
      decoration: BoxDecoration(
        color: widget.clr ?? Colors.blueAccent,
        borderRadius: BorderRadius.circular(20), //
      ),
      child: TextButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        child: widget.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: Colors.white,
                  size: 20,
                ),
              )
            : Text(
                widget.textInfo,
                style: TextStyle(color: Colors.white, fontSize: 20), //
              ),
      ),
    );
  }
}
