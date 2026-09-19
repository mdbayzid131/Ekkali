import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';

class CustomSwipeButton extends StatefulWidget {
  final String text;
  final VoidCallback onSwipeComplete;
  final double height;
  final Color backgroundColor;
  final Color activeColor;
  final Color thumbColor;
  final Color textColor;

  const CustomSwipeButton({
    super.key,
    required this.text,
    required this.onSwipeComplete,
    this.height = 54,
    this.backgroundColor = const Color(0xFF161616),
    this.activeColor = const Color(0xFFFFDCA1),
    this.thumbColor = const Color(0xFFFFDCA1),
    this.textColor = Colors.white,
  });

  @override
  State<CustomSwipeButton> createState() => _CustomSwipeButtonState();
}

class _CustomSwipeButtonState extends State<CustomSwipeButton>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  late AnimationController _animController;
  late Animation<double> _anim;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = Tween<double>(begin: 0.0, end: 0.0).animate(_animController)
      ..addListener(() {
        setState(() {
          _dragValue = _anim.value;
        });
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDragWidth) {
    if (_isCompleted || maxDragWidth <= 0) return;
    setState(() {
      _dragValue += details.delta.dx / maxDragWidth;
      _dragValue = _dragValue.clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isCompleted) return;
    if (_dragValue >= 0.70) {
      _completeSwipe();
    } else {
      _resetSwipe();
    }
  }

  void _completeSwipe() {
    setState(() {
      _isCompleted = true;
    });
    _anim = Tween<double>(begin: _dragValue, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0).then((_) {
      widget.onSwipeComplete();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isCompleted = false;
            _dragValue = 0.0;
          });
        }
      });
    });
  }

  void _resetSwipe() {
    _anim = Tween<double>(begin: _dragValue, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height.h;
    final padding = 4.r;
    final thumbSize = height - (padding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDragWidth =
            (totalWidth - (padding * 2) - thumbSize).clamp(0.0, totalWidth);
        final thumbOffset = _dragValue * maxDragWidth;

        return Container(
          width: totalWidth,
          height: height,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: const Color(0xFF262626),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Filled Progress Bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: thumbOffset + thumbSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.activeColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(thumbSize / 2),
                  ),
                ),
              ),

              // 2. Centered Label Text
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: thumbSize / 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: (1.0 - (_dragValue * 1.5)).clamp(0.0, 1.0),
                        child: Text(
                          widget.text,
                          style: GoogleFonts.inter(
                            color: widget.textColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Opacity(
                        opacity: (1.0 - (_dragValue * 1.5)).clamp(0.0, 1.0),
                        child: Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: const Color(0xFF71717A),
                          size: 18.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Simple Thumb Button
              Positioned(
                left: thumbOffset,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxDragWidth),
                  onHorizontalDragEnd: _onDragEnd,
                  onTap: _completeSwipe,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(11.r),
                    child: SvgPicture.asset(
                      AppIcons.arre_right_icon,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
