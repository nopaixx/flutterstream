import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final bool enabled;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with TickerProviderStateMixin {
  bool _isObscured = true;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _borderColorAnimation = ColorTween(
      begin: AppTheme.mediumGrey,
      end: AppTheme.primaryViolet,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColorAnimation.value ?? AppTheme.mediumGrey,
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword ? _isObscured : false,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              enabled: widget.enabled,
              onTap: _handleFocus,
              onTapOutside: (_) => _handleUnfocus(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),

                // Prefix icon
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                  padding: const EdgeInsets.only(left: 20, right: 16),
                  child: widget.prefixIcon,
                )
                    : null,

                // Suffix icon for password visibility
                suffixIcon: widget.isPassword
                    ? Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isObscured
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        key: ValueKey(_isObscured),
                        color: _isFocused
                            ? AppTheme.primaryViolet
                            : AppTheme.textGrey,
                        size: 22,
                      ),
                    ),
                  ),
                )
                    : null,

                // Error style
                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleFocus() {
    setState(() => _isFocused = true);
    _animationController.forward();
  }

  void _handleUnfocus() {
    setState(() => _isFocused = false);
    _animationController.reverse();
  }
}

// Variante moderna para campos de búsqueda
class SearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearchTap;
  final Function(String)? onChanged;

  const SearchTextField({
    Key? key,
    required this.controller,
    this.hintText = 'Buscar contenido...',
    this.onSearchTap,
    this.onChanged,
  }) : super(key: key);

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused
              ? AppTheme.primaryViolet.withOpacity(0.5)
              : AppTheme.mediumGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onTap: () => setState(() => _isFocused = true),
        onTapOutside: (_) => setState(() => _isFocused = false),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused
                  ? AppTheme.primaryViolet
                  : AppTheme.textGrey,
              size: 20,
            ),
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                widget.controller.clear();
                if (widget.onChanged != null) {
                  widget.onChanged!('');
                }
              },
              child: Icon(
                Icons.clear_rounded,
                color: AppTheme.textGrey,
                size: 18,
              ),
            ),
          )
              : null,
        ),
      ),
    );
  }
}

// Extension para gradients (si no existe ya)
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
    );
  }
}