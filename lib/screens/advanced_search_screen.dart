import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/ui.dart';

/// The set of fields a completed advanced search was run with — every
/// non-null field was ANDed together server-side, see
/// [BiblioSource.advancedSearch].
class AdvancedSearchQuery {
  final String? title;
  final String? author;
  final String? isbn;
  final String? issn;
  final String? publisher;
  final String? seriesTitle;
  final String? publicationYear;
  final String? itemType;

  const AdvancedSearchQuery({
    this.title,
    this.author,
    this.isbn,
    this.issn,
    this.publisher,
    this.seriesTitle,
    this.publicationYear,
    this.itemType,
  });

  bool get isEmpty =>
      title == null &&
      author == null &&
      isbn == null &&
      issn == null &&
      publisher == null &&
      seriesTitle == null &&
      publicationYear == null &&
      itemType == null;
}

/// A form for combining multiple fields (title AND author AND ISBN...)
/// into one search — unlike OPAC's main search bar, which only searches
/// one field (or every field as keyword) at a time. Pops with an
/// [AdvancedSearchQuery] for [OpacScreen] to run and display using its
/// existing results list, or `null` if the user backs out.
class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _issnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _seriesController = TextEditingController();
  final _yearController = TextEditingController();

  static const Map<String, String?> _itemTypes = {
    'All types': null,
    'Books': 'BK',
    'eBooks': 'EBK',
    'Computer Files': 'CF',
    'Thesis': 'THESIS',
  };

  String _selectedTypeLabel = 'All types';

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _issnController.dispose();
    _publisherController.dispose();
    _seriesController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String? _valueOrNull(TextEditingController c) {
    final trimmed = c.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _submit() {
    final query = AdvancedSearchQuery(
      title: _valueOrNull(_titleController),
      author: _valueOrNull(_authorController),
      isbn: _valueOrNull(_isbnController),
      issn: _valueOrNull(_issnController),
      publisher: _valueOrNull(_publisherController),
      seriesTitle: _valueOrNull(_seriesController),
      publicationYear: _valueOrNull(_yearController),
      itemType: _itemTypes[_selectedTypeLabel],
    );
    if (query.isEmpty) return;
    Navigator.of(context).pop(query);
  }

  void _clear() {
    for (final c in [
      _titleController,
      _authorController,
      _isbnController,
      _issnController,
      _publisherController,
      _seriesController,
      _yearController,
    ]) {
      c.clear();
    }
    setState(() => _selectedTypeLabel = 'All types');
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Scaffold(
      backgroundColor: colors.background.primary,
      appBar: AppBar(
        backgroundColor: colors.background.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Heading(level: 5, text: 'Advanced Search'),
      ),
      body: ScreenContainer(
        scroll: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Fill in as many fields as you like — results must match all of them.',
              variant: 'bodySmall',
              tone: 'secondary',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Title', controller: _titleController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Author', controller: _authorController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'ISBN',
              controller: _isbnController,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'ISSN', controller: _issnController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Publisher', controller: _publisherController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Series', controller: _seriesController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Publication Year',
              controller: _yearController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdownField(
              label: 'Item Type',
              value: _selectedTypeLabel,
              options: _itemTypes.keys.toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedTypeLabel = value);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(label: 'Clear', variant: 'secondary', onPressed: _clear),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(label: 'Search', onPressed: _submit),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
