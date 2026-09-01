import 'package:flutter/material.dart';

import '../../../helpers/networking/api_helper.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../custom_loading/custom_loading.dart';

class CustomButton extends StatelessWidget {
  final double radius;
  final double? width;
  final double height;
  final double? gap;
  final TextStyle? style;
  final String? text;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? child;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final ApiResponse? apiResponse;
  final bool isLoading;
  final bool hasShadow;
  final void Function()? onPressed;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;

  const CustomButton({
    super.key,
    this.radius = 18,
    this.width,
    this.height = 56,
    this.style,
    this.text,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    this.gradient,
    this.apiResponse,
    this.isLoading = false,
    this.hasShadow = true,
    this.onPressed,
    this.child,
    this.borderColor,
    this.borderRadius,
    this.boxShadow,
    this.gap,
  });

  @override
  Widget build(BuildContext context) {
    if (apiResponse?.state == ResponseState.loading || isLoading) {
      return SizedBox(height: height, child: const Center(child: CustomLoading()));
    }

    final resolvedRadius = borderRadius ?? BorderRadius.circular(radius);
    final enabled = onPressed != null;

    return AnimatedOpacity(
      opacity: enabled ? 1 : .66,
      duration: const Duration(milliseconds: 160),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: color,
          gradient: color == null
              ? (gradient ??
                    const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffFF8A08), Color(0xffFF6500)],
                    ))
              : null,
          borderRadius: resolvedRadius,
          border: Border.all(color: borderColor ?? Colors.transparent),
          boxShadow: boxShadow ??
              (hasShadow
                  ? [
                      BoxShadow(
                        color: AppColor.mainAppColor(context).withOpacity(.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: resolvedRadius.resolve(Directionality.of(context)),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    SizedBox(width: gap ?? 8),
                  ],
                  Flexible(
                    child: child ??
                        Text(
                          text ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: style ?? AppTextStyle.buttonStyle(context).copyWith(fontWeight: FontWeight.w800),
                        ),
                  ),
                  if (suffixIcon != null) ...[
                    SizedBox(width: gap ?? 8),
                    suffixIcon!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
