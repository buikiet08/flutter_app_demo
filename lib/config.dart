final String noImgae = 'https://gis.phuwaco.com.vn/portal/home/10.9.1/js/arcgisonline/css/images/no-user-thumb.jpg';

class ArcGISConfig {
  static const String domainBaseUrl = 'https://gis.phuwaco.com.vn';
  static const String portalUrl = '$domainBaseUrl/portal';
  static const String featureServiceUrl = '$domainBaseUrl/server/rest/services/MLCN_PHT/MangLuoiCapNuoc_PHT_V2/FeatureServer';
  static const String dmaUrl = '$domainBaseUrl/server/rest/services/MLCN_PHT/DMA_PHT_V2/FeatureServer/1';
  /// Map layer IDs (FeatureLayer)
  static const Map<String, int> layerIds = {
    'ThuyDai': 1,
    'DongHoTong': 2,
    'MoiNoi': 3,
    'TruHong': 4,
    'VanDieuKhien': 5,
    'VanHeThong': 6,
    'DongHoKhachHang': 7,
    'OngTruyenTai': 8,
    'OngPhanPhoi': 9,
    'OngNganh': 10,
  };

  /// Table IDs
  static const Map<String, int> tableIds = {
    'tblConDuong': 20,
    'tblDonViPhoiHop': 21,
    'tblDSCanBoToDanPho': 22,
    'tblNguoiGiamSat': 23,
    'tblNguoiThucHien': 24,
    'tblPhuongXa': 25,
    'tblQuanHuyen': 26,
    'tblTaiLapMatDuong': 27,
    'tblThongTinSucXa': 28,
    'tblVatLieuXayDung': 29,
    'tblVatTuSuaChuaSuCo': 30,
    'tblDMA': 31,
    'tblDMZ': 32,
    'tblDoanhThu': 33,
    'tblLuuLuongThatThoatTheoDMA': 34,
    'tblLuuLuongThatThoatTheoDMZ': 35,
    'tblTyLeThatThoatTheoDMA': 37,
    'tblTyLeThatThoatTheoDMZ': 38,
    'tblDocumentation': 39,
  };

  /// Lấy URL đầy đủ cho 1 layer
  static String getLayerUrl(int layerId) => '$featureServiceUrl/$layerId';

  /// Lấy URL đầy đủ cho 1 table
  static String getTableUrl(int tableId) => '$featureServiceUrl/$tableId';
}

class AppConfig {
  final String name;
  final String title;
  final String iconPath;
  final String webMapId;

  const AppConfig({
    required this.name,
    required this.title,
    required this.iconPath,
    required this.webMapId,
  });
}

class AppsConfig {
  static const List<AppConfig> apps = [
    AppConfig(
      name: 'DTML',
      title: 'Vận hành điều tiết mạng lưới',
      iconPath: 'assets/images/app/dtml.png',
      webMapId: 'abcd1234-dtml-webmap-id',
    ),
    AppConfig(
      name: 'QLSC',
      title: 'Quản lý sự cố',
      iconPath: 'assets/images/app/qlsc.png',
      webMapId: 'efgh5678-qlsc-webmap-id',
    ),
    AppConfig(
      name: 'QLTS',
      title: 'Quản lý tài sản',
      iconPath: 'assets/images/app/qlts.png',
      webMapId: 'ijkl9012-qlts-webmap-id',
    ),
  ];

  static AppConfig? getAppByName(String name) {
    return apps.firstWhere((app) => app.name == name, orElse: () => throw Exception('App not found'));
  }
}