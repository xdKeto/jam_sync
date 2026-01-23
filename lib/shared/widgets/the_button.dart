import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class TheButton extends StatefulWidget {
  final String text;
  final bool isIcon;
  final Color color;
  final Color textColor;
  final Color iconColor;
  final IconData icon;
  final bool border;
  final double horiPadding;
  final double vertPadding;
  final double borderRad;
  final IconData? hoverIcon;
  final bool hoverable;

  const TheButton({
    super.key,
    this.borderRad = 6,
    this.horiPadding = 6,
    this.vertPadding = 8,
    required this.text,
    this.isIcon = false,
    required this.color,
    this.icon = Icons.abc,
    this.textColor = Colors.black,
    this.iconColor = Colors.black,
    this.border = false,
    this.hoverIcon,
    this.hoverable = true,
  });

  @override
  State<TheButton> createState() => _TheButtonState();
}

class _TheButtonState extends State<TheButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horiPadding,
          vertical: widget.vertPadding,
        ),
        decoration: isHovered
            ? AppStyles.buttonBox(widget.color, widget.borderRad)
            : widget.border
            ? AppStyles.buttonBox2(widget.color, widget.borderRad)
            : AppStyles.buttonBox(widget.color, widget.borderRad),
        child: widget.isIcon
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHovered && widget.hoverIcon != null
                        ? widget.hoverIcon
                        : widget.icon,
                    color: isHovered ? Colors.white : widget.iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: AppStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isHovered ? Colors.white : widget.textColor,
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  widget.text,
                  style: AppStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.hoverable
                        ? isHovered
                              ? Colors.white
                              : widget.textColor
                        : widget.textColor,
                  ),
                ),
              ),
      ),
    );
  }
}
