# AMap Flutter Integration

This project demonstrates how to integrate AMap (Gaode Maps) into a Flutter application, providing a cross-platform mapping solution that works well in China.

## Features

- Display vector map tiles from AMap
- Center the map on Beijing with appropriate zoom level
- Interactive zoom controls
- Location marker for points of interest
- Compatible with both web and mobile platforms

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- An IDE (VS Code, Android Studio, etc.)

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/amap_demo.git
   cd amap_demo
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Implementation Details

This project uses the `flutter_map` package to display AMap tiles. The implementation includes:

- **Map Configuration**: Set up with appropriate initial coordinates (Beijing), zoom levels, and map options
- **Tile Layer**: Configured to use AMap's vector map tiles
- **Markers**: Implementation of location markers for points of interest
- **Zoom Controls**: Custom UI controls for zooming in and out

## Code Structure

- `lib/main.dart` - Application entry point
- `lib/map_page.dart` - Main map implementation with AMap integration

## AMap Tile Options

The application supports various AMap tile styles:

- **Vector Map (Standard)**: Style 7
  ```
  https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7
  ```

- **Vector Map (Navigation)**: Style 8
  ```
  https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=8
  ```

- **Satellite Imagery**: Style 6
  ```
  https://webst0{s}.is.autonavi.com/appmaptile?style=6&x={x}&y={y}&z={z}
  ```

- **Hybrid (Satellite with Roads)**: Combine satellite with road network
  ```
  // Satellite base layer
  https://webst0{s}.is.autonavi.com/appmaptile?style=6&x={x}&y={y}&z={z}

  // Road overlay
  https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=8
  ```

## Coordinate System

AMap uses the GCJ-02 coordinate system, which is the standard for maps in China. This is different from the WGS84 system used internationally. When working with coordinates:

- Beijing center: `LatLng(39.9087, 116.3976)` (in GCJ-02)
- If you need to convert from WGS84 to GCJ-02, additional conversion libraries may be required

## Troubleshooting

### Common Issues

- **Tile Loading Errors**: If tiles fail to load, check your internet connection and ensure there are no CORS issues if running on web
- **Blank Map**: Verify that the correct URL template and subdomains are being used
- **Incorrect Positioning**: Ensure coordinates are in the GCJ-02 system used by AMap

### Web Platform Considerations

When deploying to web platforms, you may encounter CORS (Cross-Origin Resource Sharing) issues. Consider:

1. Using a CORS proxy for development purposes
2. Setting appropriate headers in your web server configuration
3. Using the official AMap JavaScript API for production web applications

## Dependencies

- [flutter_map](https://pub.dev/packages/flutter_map): Provides the map widget and tile layer functionality
- [latlong2](https://pub.dev/packages/latlong2): Handles geographic coordinates

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- AMap for providing the map tile services
- The flutter_map package maintainers for their excellent mapping solution

---

*Note: This project is for demonstration purposes only. For production use, consider obtaining an official API key from AMap and following their terms of service.*
