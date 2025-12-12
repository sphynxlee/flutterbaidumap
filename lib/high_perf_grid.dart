import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

typedef CellGetter = String Function(int row, int col);
typedef CellSetter = void Function(int row, int col, String value);

class HighPerfGrid extends StatefulWidget {
  const HighPerfGrid({
    super.key,
    required this.rows,
    required this.cols,
    required this.rowHeight,
    required this.headerHeight,
    required this.colWidths,
    required this.overscanRows,
    required this.overscanCols,
    required this.getCell,
    required this.setCell,
  });

  final int rows;
  final int cols;
  final double rowHeight;
  final double headerHeight;
  final List<double> colWidths;
  final int overscanRows;
  final int overscanCols;
  final CellGetter getCell;
  final CellSetter setCell;

  @override
  State<HighPerfGrid> createState() => _HighPerfGridState();
}

class _HighPerfGridState extends State<HighPerfGrid> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'HighPerfGridFocus');

  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode(debugLabel: 'CellEditorFocus');

  // Scroll offsets in pixels.
  double _scrollX = 0;
  double _scrollY = 0;

  // Selection (body only; row/col are 0-based).
  int? _selRow;
  int? _selCol;

  bool _isEditing = false;

  // Cached column prefix sums for fast x->col mapping.
  late List<double> _colStarts; // length cols+1, last is total width

  // Repaint coalescing: multiple pointer events per frame => 1 setState.
  bool _frameScheduled = false;

  // Frame stats (approx).
  double _lastFrameMs = 0;
  int _paintedCellsLastFrame = 0;

  @override
  void initState() {
    super.initState();
    _rebuildColStarts();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void didUpdateWidget(covariant HighPerfGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.colWidths, widget.colWidths) ||
        oldWidget.cols != widget.cols) {
      _rebuildColStarts();
      _clampScrollToViewport(lastViewportSize: null);
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _focusNode.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;
    // Use the last timing, in milliseconds.
    final FrameTiming t = timings.last;
    final Duration total = t.totalSpan;
    setState(() {
      _lastFrameMs = total.inMicroseconds / 1000.0;
    });
  }

  void _rebuildColStarts() {
    _colStarts = List<double>.filled(widget.cols + 1, 0);
    double acc = 0;
    for (int c = 0; c < widget.cols; c++) {
      _colStarts[c] = acc;
      acc += widget.colWidths[c];
    }
    _colStarts[widget.cols] = acc;
  }

  double get _contentWidth => _colStarts[widget.cols];
  double get _contentHeight => widget.rows * widget.rowHeight;

  void _scheduleRebuild() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _frameScheduled = false;
      });
    });
  }

  void _scrollBy({
    required double dx,
    required double dy,
    required Size viewportSize,
  }) {
    final double bodyHeight = math.max(0, viewportSize.height - widget.headerHeight);
    final double maxX = math.max(0, _contentWidth - viewportSize.width);
    final double maxY = math.max(0, _contentHeight - bodyHeight);
    _scrollX = (_scrollX + dx).clamp(0, maxX);
    _scrollY = (_scrollY + dy).clamp(0, maxY);
  }

  void _clampScrollToViewport({required Size? lastViewportSize}) {
    if (lastViewportSize == null) return;
    final double bodyHeight = math.max(0, lastViewportSize.height - widget.headerHeight);
    final double maxX = math.max(0, _contentWidth - lastViewportSize.width);
    final double maxY = math.max(0, _contentHeight - bodyHeight);
    _scrollX = _scrollX.clamp(0, maxX);
    _scrollY = _scrollY.clamp(0, maxY);
  }

  int _colAtX(double x) {
    // x is in content space (already includes scrollX).
    // cols are few (<= 50), linear scan is fine and avoids allocations.
    for (int c = 0; c < widget.cols; c++) {
      final double start = _colStarts[c];
      final double end = _colStarts[c + 1];
      if (x >= start && x < end) return c;
    }
    return widget.cols - 1;
  }

  int _rowAtY(double y) {
    // y is in content space (already includes scrollY).
    final int r = (y / widget.rowHeight).floor();
    return r.clamp(0, widget.rows - 1);
  }

  Rect _cellRectInViewport({
    required int row,
    required int col,
  }) {
    final double x = _colStarts[col] - _scrollX;
    final double y = widget.headerHeight + (row * widget.rowHeight) - _scrollY;
    return Rect.fromLTWH(x, y, widget.colWidths[col], widget.rowHeight);
  }

  void _selectCellFromLocal({
    required Offset localPos,
  }) {
    // Ignore header clicks for this demo.
    if (localPos.dy < widget.headerHeight) return;
    final double bodyY = localPos.dy - widget.headerHeight;
    final int row = _rowAtY(bodyY + _scrollY);
    final int col = _colAtX(localPos.dx + _scrollX);
    setState(() {
      _selRow = row;
      _selCol = col;
    });
  }

  void _beginEdit() {
    final int? r = _selRow;
    final int? c = _selCol;
    if (r == null || c == null) return;
    final String v = widget.getCell(r, c);
    setState(() {
      _isEditing = true;
      _editController.text = v;
      _editController.selection = TextSelection(baseOffset: 0, extentOffset: v.length);
    });
    // Request focus after the overlay is built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editFocusNode.requestFocus();
    });
  }

  void _commitEdit() {
    final int? r = _selRow;
    final int? c = _selCol;
    if (r == null || c == null) return;
    widget.setCell(r, c, _editController.text);
    setState(() {
      _isEditing = false;
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _clampScrollToViewport(lastViewportSize: viewportSize);

        final ThemeData theme = Theme.of(context);

        final Widget painted = RepaintBoundary(
          child: CustomPaint(
            painter: _GridPainter(
              rows: widget.rows,
              cols: widget.cols,
              rowHeight: widget.rowHeight,
              headerHeight: widget.headerHeight,
              colWidths: widget.colWidths,
              colStarts: _colStarts,
              overscanRows: widget.overscanRows,
              overscanCols: widget.overscanCols,
              scrollX: _scrollX,
              scrollY: _scrollY,
              selectedRow: _selRow,
              selectedCol: _selCol,
              getCell: widget.getCell,
              theme: theme,
              onPaintedCells: (n) => _paintedCellsLastFrame = n,
            ),
            size: Size.infinite,
          ),
        );

        final Widget editorOverlay = (!_isEditing || _selRow == null || _selCol == null)
            ? const SizedBox.shrink()
            : Positioned.fromRect(
                rect: _cellRectInViewport(row: _selRow!, col: _selCol!).deflate(1),
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    focusNode: _editFocusNode,
                    controller: _editController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.2),
                    onSubmitted: (_) => _commitEdit(),
                  ),
                ),
              );

        final Widget statsOverlay = Positioned(
          top: 8,
          right: 8,
          child: _StatsChip(
            scrollX: _scrollX,
            scrollY: _scrollY,
            frameMs: _lastFrameMs,
            paintedCells: _paintedCellsLastFrame,
            viewportSize: viewportSize,
            headerHeight: widget.headerHeight,
            rowHeight: widget.rowHeight,
            contentWidth: _contentWidth,
            contentHeight: _contentHeight,
          ),
        );

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (_isEditing) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _cancelEdit();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }

            if (event.logicalKey == LogicalKeyboardKey.enter) {
              _beginEdit();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              setState(() {
                _selRow = null;
                _selCol = null;
              });
              return KeyEventResult.handled;
            }

            // Basic keyboard panning for convenience.
            const double kStep = 56;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollBy(dx: 0, dy: kStep, viewportSize: viewportSize);
              _scheduleRebuild();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollBy(dx: 0, dy: -kStep, viewportSize: viewportSize);
              _scheduleRebuild();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _scrollBy(dx: kStep, dy: 0, viewportSize: viewportSize);
              _scheduleRebuild();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _scrollBy(dx: -kStep, dy: 0, viewportSize: viewportSize);
              _scheduleRebuild();
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                // Trackpads can deliver both axes; mouse wheels are usually vertical only.
                // Natural scroll feels right on web for most devices: deltaY > 0 means scroll down.
                _scrollBy(dx: signal.scrollDelta.dx, dy: signal.scrollDelta.dy, viewportSize: viewportSize);
                _scheduleRebuild();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                _focusNode.requestFocus();
                _selectCellFromLocal(localPos: d.localPosition);
              },
              onDoubleTap: _beginEdit,
              onPanUpdate: (d) {
                if (_isEditing) return;
                // Dragging pans the grid.
                _scrollBy(dx: -d.delta.dx, dy: -d.delta.dy, viewportSize: viewportSize);
                _scheduleRebuild();
              },
              child: Stack(
                children: [
                  painted,
                  editorOverlay,
                  statsOverlay,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsChip extends StatelessWidget {
  const _StatsChip({
    required this.scrollX,
    required this.scrollY,
    required this.frameMs,
    required this.paintedCells,
    required this.viewportSize,
    required this.headerHeight,
    required this.rowHeight,
    required this.contentWidth,
    required this.contentHeight,
  });

  final double scrollX;
  final double scrollY;
  final double frameMs;
  final int paintedCells;
  final Size viewportSize;
  final double headerHeight;
  final double rowHeight;
  final double contentWidth;
  final double contentHeight;

  @override
  Widget build(BuildContext context) {
    final double bodyHeight = math.max(0, viewportSize.height - headerHeight);
    final int approxVisibleRows = bodyHeight <= 0 ? 0 : (bodyHeight / rowHeight).ceil();
    final String text = 'painted=$paintedCells  '
        'frame=${frameMs.toStringAsFixed(1)}ms  '
        'x=${scrollX.toStringAsFixed(0)}/${contentWidth.toStringAsFixed(0)}  '
        'y=${scrollY.toStringAsFixed(0)}/${contentHeight.toStringAsFixed(0)}  '
        'rows~$approxVisibleRows';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.rows,
    required this.cols,
    required this.rowHeight,
    required this.headerHeight,
    required this.colWidths,
    required this.colStarts,
    required this.overscanRows,
    required this.overscanCols,
    required this.scrollX,
    required this.scrollY,
    required this.selectedRow,
    required this.selectedCol,
    required this.getCell,
    required this.theme,
    required this.onPaintedCells,
  });

  final int rows;
  final int cols;
  final double rowHeight;
  final double headerHeight;
  final List<double> colWidths;
  final List<double> colStarts;
  final int overscanRows;
  final int overscanCols;
  final double scrollX;
  final double scrollY;
  final int? selectedRow;
  final int? selectedCol;
  final CellGetter getCell;
  final ThemeData theme;
  final ValueChanged<int> onPaintedCells;

  final Paint _bg = Paint()..style = PaintingStyle.fill;
  final Paint _gridLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _sel = Paint()..style = PaintingStyle.fill;

  final TextPainter _tp = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double bodyHeight = math.max(0, h - headerHeight);

    // Background.
    _bg.color = theme.colorScheme.surface;
    canvas.drawRect(Offset.zero & size, _bg);

    // Header background.
    _bg.color = theme.colorScheme.surfaceContainerHighest;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, headerHeight), _bg);

    _gridLine.color = theme.dividerColor;

    // Visible cols (including overscan).
    int firstCol = 0;
    while (firstCol < cols - 1 && colStarts[firstCol + 1] <= scrollX) {
      firstCol++;
    }
    int lastCol = firstCol;
    while (lastCol < cols - 1 && colStarts[lastCol] < scrollX + w) {
      lastCol++;
    }
    firstCol = (firstCol - overscanCols).clamp(0, cols - 1);
    lastCol = (lastCol + overscanCols).clamp(0, cols - 1);

    // Visible rows (including overscan).
    int firstRow = (scrollY / rowHeight).floor();
    int lastRow = ((scrollY + bodyHeight) / rowHeight).ceil() - 1;
    firstRow = (firstRow - overscanRows).clamp(0, rows - 1);
    lastRow = (lastRow + overscanRows).clamp(0, rows - 1);

    int painted = 0;

    // Paint header labels.
    for (int c = firstCol; c <= lastCol; c++) {
      final double x = colStarts[c] - scrollX;
      final double cw = colWidths[c];

      // Header cell border.
      canvas.drawRect(Rect.fromLTWH(x, 0, cw, headerHeight), _gridLine);

      _tp.text = TextSpan(
        text: 'Col $c',
        style: theme.textTheme.labelMedium?.copyWith(fontSize: 12),
      );
      _tp.layout(maxWidth: math.max(0, cw - 10));
      _tp.paint(canvas, Offset(x + 6, (headerHeight - _tp.height) / 2));
    }

    // Clip to body region.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, headerHeight, w, bodyHeight));

    // Paint body cells.
    for (int r = firstRow; r <= lastRow; r++) {
      final double y = headerHeight + (r * rowHeight) - scrollY;

      for (int c = firstCol; c <= lastCol; c++) {
        final double x = colStarts[c] - scrollX;
        final double cw = colWidths[c];
        final Rect rect = Rect.fromLTWH(x, y, cw, rowHeight);

        // Row striping.
        _bg.color = (r.isEven)
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerLowest;
        canvas.drawRect(rect, _bg);

        final bool selected = (selectedRow == r && selectedCol == c);
        if (selected) {
          _sel.color = theme.colorScheme.primary.withValues(alpha: 0.18);
          canvas.drawRect(rect, _sel);
        }

        // Cell border.
        canvas.drawRect(rect, _gridLine);

        final String text = getCell(r, c);
        _tp.text = TextSpan(
          text: text,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
        );
        _tp.layout(maxWidth: math.max(0, cw - 10));
        _tp.paint(canvas, Offset(x + 6, y + (rowHeight - _tp.height) / 2));

        painted++;
      }
    }

    canvas.restore();

    onPaintedCells(painted);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.scrollX != scrollX ||
        oldDelegate.scrollY != scrollY ||
        oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol ||
        oldDelegate.rows != rows ||
        oldDelegate.cols != cols ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.headerHeight != headerHeight ||
        !listEquals(oldDelegate.colWidths, colWidths);
  }
}


