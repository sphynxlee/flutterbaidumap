import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late BMFMapController _mapController;

  @override
  void initState() {
    super.initState();
    // 百度地图初始化
    BMFMapSDK.setAgreePrivacy(true);
    BMFMapSDK.setApiKeyAndCoordType(
      'qDTXqaahwzKE8igpc8HnOtaH5QuiJ',
      BMF_COORD_TYPE.BD09LL
    );
  }

  @override
  Widget build(BuildContext context) {
    // 北京坐标
    BMFCoordinate beijingCoord = BMFCoordinate(39.915, 116.404);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Baidu Map'),
        backgroundColor: Colors.blue,
      ),
      body: BMFMapWidget(
        onBMFMapCreated: (controller) {
          _mapController = controller;

          // 设置自定义瓦片图层
          BMFURLTileLayer baseLayer = BMFURLTileLayer(
            urlTemplate: 'http://online{s}.map.bdimg.com/tile/?qt=vtile&x={x}&y={y}&z={z}&styles=pl&scaler=1&udt=',
            subdomains: ['0', '1', '2', '3'],
            maximumZ: 18,
            minimumZ: 3,
          );
          _mapController.addTileLayer(baseLayer);

          BMFURLTileLayer labelLayer = BMFURLTileLayer(
            urlTemplate: 'http://online{s}.map.bdimg.com/onlinelabel/?qt=tile&x={x}&y={y}&z={z}',
            subdomains: ['0', '1', '2', '3'],
            maximumZ: 18,
            minimumZ: 3,
          );
          _mapController.addTileLayer(labelLayer);

          // 添加标记点
          BMFMarker marker = BMFMarker(
            position: beijingCoord,
            title: '北京',
            identifier: 'beijing_marker',
          );
          _mapController.addMarker(marker);
        },
        mapOptions: BMFMapOptions(
          center: beijingCoord,
          zoomLevel: 12,
          maxZoomLevel: 18,
          minZoomLevel: 3,
          baseIndoorMapEnabled: false,
          showMapPoi: true,
          mapType: BMFMapType.None, // 使用空白底图，因为我们要使用自定义瓦片
        ),
      ),
    );
  }
}