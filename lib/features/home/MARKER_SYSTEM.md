# Marker System Documentation

## Tổng quan
Hệ thống marker cho phép người dùng thêm các icon/marker lên map khi click vào map. Các marker chỉ được thêm khi có tool được active.

## Cách sử dụng

### 1. Kích hoạt Tool Mode
- Click vào nút Settings (⚙️) để bật/tắt tool mode
- Khi tool mode được bật, bottom navigation sẽ thay đổi thành toolbar với các tool khác nhau

### 2. Chọn Tool và Thêm Marker
- Chọn một trong các tool có sẵn (flag, stop, remove_circle, flash_auto, key_rounded)
- Click vào bất kỳ vị trí nào trên map
- Một marker màu đỏ sẽ xuất hiện tại vị trí click
- Thông báo sẽ hiển thị tool nào đã được sử dụng

### 3. Quản lý Markers
- **Xóa tất cả markers**: Click nút Clear All (🗑️)
- **Xóa marker cuối**: Click nút Undo (↶)

## Cấu trúc kỹ thuật

### GraphicsOverlay
```dart
// GraphicsOverlay để quản lý markers trên map
late GraphicsOverlay markersOverlay;
```

### Thêm Marker
```dart
Future<void> addMarkerAtPoint(ArcGISPoint point) async {
  final symbol = SimpleMarkerSymbol(
    style: SimpleMarkerSymbolStyle.circle,
    color: const Color.fromARGB(255, 255, 0, 0), // Màu đỏ
    size: 15.0,
  );
  
  final graphic = Graphic(
    geometry: point,
    symbol: symbol,
  );
  
  markersOverlay.graphics.add(graphic);
}
```

### Logic Click Handler
```dart
// Kiểm tra xem có tool nào được active không
final isToolActive = ref.watch(activeToolProvider) == true;
final activeToolButton = ref.watch(activeToolButtonProvider);

if (isToolActive && activeToolButton != null) {
  // Thêm marker tại vị trí click
  final mapPoint = await mapViewController.screenToLocation(screen: screenPoint);
  if (mapPoint != null) {
    await addMarkerAtPoint(mapPoint);
  }
  return; // Không thực hiện identify feature
}
```

## Tính năng chính

### ✅ Implemented Features
- ✅ Thêm marker khi click vào map (chỉ khi tool active)
- ✅ GraphicsOverlay để quản lý markers
- ✅ Symbols tùy chỉnh cho markers
- ✅ Xóa tất cả markers
- ✅ Xóa marker cuối cùng
- ✅ Thông báo tool được sử dụng
- ✅ Không can thiệp vào logic identify feature khi tool không active

### 🔄 Có thể mở rộng
- Các loại symbol khác nhau cho từng tool
- Lưu trữ metadata cho mỗi marker
- Export/Import markers
- Marker clustering
- Custom marker icons từ assets
- Marker editing/moving

### Tùy chỉnh Symbol
Bạn có thể thay đổi kiểu marker bằng cách:

```dart
// Marker hình tròn
final symbol = SimpleMarkerSymbol(
  style: SimpleMarkerSymbolStyle.circle,
  color: const Color.fromARGB(255, 255, 0, 0),
  size: 15.0,
);

// Marker hình vuông
final symbol = SimpleMarkerSymbol(
  style: SimpleMarkerSymbolStyle.square,
  color: const Color.fromARGB(255, 0, 255, 0),
  size: 15.0,
);

// Marker từ file ảnh
final symbol = PictureMarkerSymbol.withImage(
  await ArcGISImage.fromAsset('assets/custom_pin.png')
);
symbol.width = 24;
symbol.height = 24;
```

## Workflow
1. User bật tool mode
2. User chọn tool từ bottom toolbar  
3. User click vào map
4. System chuyển đổi screen coordinates thành map coordinates
5. System tạo marker tại vị trí đó
6. Marker được thêm vào GraphicsOverlay
7. User có thể xóa markers nếu cần

Hệ thống này cung cấp một cách trực quan và dễ sử dụng để thêm markers lên map trong ứng dụng ArcGIS.
