import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_icon.dart';

/// Colonne d'un [BcDataTable]. `sortKey` active le tri au clic sur l'en-tête
/// (envoyé tel quel au backend DRF via `ordering`) ; null = colonne non triable.
class BcColumn {
  final String label;
  final int flex;
  final String? sortKey;

  const BcColumn(this.label, {this.flex = 1, this.sortKey});
}

/// Tableau de données du back-office admin : recherche, tri par colonne,
/// filtres (chips libres) et pagination — piloté par le parent (état de
/// recherche/tri/page vit dans l'écran appelant, qui recharge depuis l'API).
class BcDataTable<T> extends StatefulWidget {
  final String title;
  final List<BcColumn> columns;
  final List<T> rows;
  final List<Widget> Function(T row) cellsBuilder;
  final bool loading;
  final String emptyLabel;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final String? sortKey;
  final bool sortAscending;
  final ValueChanged<String>? onSortChanged;
  final List<Widget>? filters;
  final int page;
  final int pageCount;
  final int totalCount;
  final ValueChanged<int>? onPageChanged;

  const BcDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    required this.cellsBuilder,
    this.loading = false,
    this.emptyLabel = 'Aucun résultat.',
    this.searchHint,
    this.onSearchChanged,
    this.sortKey,
    this.sortAscending = true,
    this.onSortChanged,
    this.filters,
    this.page = 1,
    this.pageCount = 1,
    this.totalCount = 0,
    this.onPageChanged,
  });

  @override
  State<BcDataTable<T>> createState() => _BcDataTableState<T>();
}

class _BcDataTableState<T> extends State<BcDataTable<T>> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchInput(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => widget.onSearchChanged?.call(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (widget.onSearchChanged != null)
                SizedBox(
                  width: 240,
                  height: 38,
                  child: TextField(
                    onChanged: _onSearchInput,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.searchHint ?? 'Rechercher…',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.sub,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(11),
                        child: BcIcon('search', size: 14, color: AppColors.sub),
                      ),
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.filters != null && widget.filters!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: widget.filters!),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _table(),
          ),
          const SizedBox(height: 14),
          _pagination(),
        ],
      ),
    );
  }

  Widget _table() {
    if (widget.loading) {
      return const SizedBox(
        height: 160,
        width: 640,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.rows.isEmpty) {
      return SizedBox(
        height: 120,
        width: 640,
        child: Center(
          child: Text(
            widget.emptyLabel,
            style: const TextStyle(color: AppColors.sub, fontSize: 12.5),
          ),
        ),
      );
    }
    return SizedBox(
      width: 640,
      child: Table(
        columnWidths: {
          for (var i = 0; i < widget.columns.length; i++)
            i: FlexColumnWidth(widget.columns[i].flex.toDouble()),
        },
        children: [_headerRow(), for (final row in widget.rows) _dataRow(row)],
      ),
    );
  }

  TableRow _headerRow() {
    const style = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppColors.sub,
      letterSpacing: 0.4,
    );
    return TableRow(
      children: [
        for (final column in widget.columns)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: InkWell(
              onTap: column.sortKey == null
                  ? null
                  : () => widget.onSortChanged?.call(column.sortKey!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(column.label.toUpperCase(), style: style),
                  if (column.sortKey != null &&
                      widget.sortKey == column.sortKey) ...[
                    const SizedBox(width: 3),
                    Transform.rotate(
                      angle: widget.sortAscending ? 0 : math.pi,
                      child: const BcIcon(
                        'chevron',
                        size: 10,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  TableRow _dataRow(T row) {
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        child: child,
      ),
    );
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      children: [for (final content in widget.cellsBuilder(row)) cell(content)],
    );
  }

  Widget _pagination() {
    final countLabel =
        '${widget.totalCount} résultat${widget.totalCount > 1 ? 's' : ''}';
    if (widget.onPageChanged == null || widget.pageCount <= 1) {
      return Text(
        countLabel,
        style: const TextStyle(fontSize: 11.5, color: AppColors.sub),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          countLabel,
          style: const TextStyle(fontSize: 11.5, color: AppColors.sub),
        ),
        Row(
          children: [
            _pageButton(
              enabled: widget.page > 1,
              rotate: math.pi / 2,
              onTap: () => widget.onPageChanged!(widget.page - 1),
            ),
            const SizedBox(width: 10),
            Text(
              'Page ${widget.page} / ${widget.pageCount}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            _pageButton(
              enabled: widget.page < widget.pageCount,
              rotate: -math.pi / 2,
              onTap: () => widget.onPageChanged!(widget.page + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pageButton({
    required bool enabled,
    required double rotate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Transform.rotate(
          angle: rotate,
          child: BcIcon(
            'chevron',
            size: 13,
            color: enabled ? AppColors.ink : AppColors.line,
          ),
        ),
      ),
    );
  }
}
