import 'package:flutter/material.dart';

import 'high_perf_grid.dart';

class GridDemoPage extends StatefulWidget {
  const GridDemoPage({super.key});

  @override
  State<GridDemoPage> createState() => _GridDemoPageState();
}

class _GridDemoPageState extends State<GridDemoPage> {
  static const int _rows = 200000;
  static const int _cols = 50;

  /// Stores only edited values to keep memory usage small.
  /// Key is (row<<16)|col for quick lookup.
  final Map<int, String> _overrides = <int, String>{};

  late final List<double> _colWidths = List<double>.generate(
    _cols,
    (i) => (i % 5 == 0) ? 160 : 120,
  );

  String _getCell(int row, int col) {
    final int k = (row << 16) ^ col;
    final String? v = _overrides[k];
    if (v != null) return v;
    // Default generated data (no allocation of a huge backing store).
    return 'R$row C$col';
  }

  void _setCell(int row, int col, String value) {
    final int k = (row << 16) ^ col;
    if (value.isEmpty) {
      _overrides.remove(k);
    } else {
      _overrides[k] = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High-performance grid demo'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              'CustomPainter virtualized grid: only visible cells are painted. '
              'Drag to pan, use trackpad/mouse wheel, click to select, double click or Enter to edit, Esc to cancel.',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: HighPerfGrid(
                    rows: _rows,
                    cols: _cols,
                    rowHeight: 28,
                    headerHeight: 32,
                    colWidths: _colWidths,
                    overscanRows: 6,
                    overscanCols: 2,
                    getCell: _getCell,
                    setCell: _setCell,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


