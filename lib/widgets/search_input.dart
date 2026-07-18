import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../theme/theme.dart';

/// Search Input variant: pill container, leading search icon, trailing
/// clear (X) or loading spinner.
///
/// The clear/loading icon swaps based on a controlled `isSearching` boolean
/// param rather than being hardcoded.
class SearchInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String placeholder;
  final bool isSearching;

  const SearchInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.onClear,
    this.placeholder = 'Search for books...',
    this.isSearching = false,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(covariant SearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    final backgroundColor =
        colors.isDark ? colors.background.tertiary : colors.background.secondary;
    final borderColor = _isFocused ? colors.text.primary : const Color(0x00000000);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(Ionicons.search, size: 18, color: colors.icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: AppTypography.bodyBase.toTextStyle(color: colors.text.primary),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: AppTypography.bodyBase.toTextStyle(color: colors.text.tertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.isSearching) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.icon),
            ),
          ] else if (widget.value.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: widget.onClear,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                label: 'Clear search',
                button: true,
                child: Icon(Ionicons.close_circle, size: 18, color: colors.icon),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
