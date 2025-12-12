# Flutter demos: AMap tiles + High-performance grid

This repository contains a small Flutter demo app with two independent demos exposed from a simple home page:

- **AMap (Gaode) tile map** using `flutter_map`
- **High-performance grid** using a virtualized `CustomPainter` (only paints visible cells)

## Features

- **Demo Home**: two buttons to enter each demo (`lib/main.dart`)
- **AMap tile map (flutter_map)**:
  - Vector tile layer from AMap
  - Beijing as initial center (`LatLng(39.9087, 116.3976)`)
  - Zoom in/out buttons and a marker
- **High-performance grid**:
  - Virtualized painter: only paints visible rows/cols (+ overscan)
  - Smooth pan/scroll, selection, and in-place cell editing
  - Minimal memory model: stores only edited cell values

## Getting Started

### Prerequisites

- Flutter SDK (3.x)
- Dart SDK (>= 3.0.0)

### Run

```bash
flutter pub get
flutter run
```

To run on web:

```bash
flutter run -d chrome
```

## Code Structure

- `lib/main.dart`: demo entry home page
- `lib/map_page.dart`: AMap tile demo using `flutter_map`
- `lib/grid_demo_page.dart`: grid demo page (wires data model to the grid widget)
- `lib/high_perf_grid.dart`: virtualized painter grid implementation

## AMap Tile Options

You can swap the tile style by changing the `urlTemplate` in `lib/map_page.dart`.

- **Vector Map (Standard)**: style 7

```
https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7
```

- **Vector Map (Navigation)**: style 8

```
https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=8
```

- **Satellite Imagery**: style 6

```
https://webst0{s}.is.autonavi.com/appmaptile?style=6&x={x}&y={y}&z={z}
```

- **Hybrid**: satellite base + road overlay

```
// Satellite base layer
https://webst0{s}.is.autonavi.com/appmaptile?style=6&x={x}&y={y}&z={z}

// Road overlay
https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=8
```

## Coordinate System

AMap tiles are typically used with **GCJ-02** coordinates (China standard), which differs from **WGS84**.

- Beijing center used in this demo: `LatLng(39.9087, 116.3976)` (GCJ-02)

## Grid Demo Controls

- **Pan**: drag to move
- **Scroll**: mouse wheel / trackpad
- **Select cell**: click
- **Edit cell**: double click or press `Enter`
- **Cancel edit**: `Esc`

## Troubleshooting (Web)

- **CORS / tile blocked**: Browsers may block tile requests due to provider policies/CORS.
  - For local development, consider using a CORS proxy
  - For production web, consider using the official AMap Web APIs and comply with AMap terms

## Dependencies

- [flutter_map](https://pub.dev/packages/flutter_map)
- [latlong2](https://pub.dev/packages/latlong2)

## License

No license file is included in this repository. If you plan to distribute or reuse this code, add a license first.
