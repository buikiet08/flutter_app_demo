# Tính năng Snapping System

## Tổng quan
Tính năng Snapping System thay thế phương thức `addMarkerAtPoint` cũ, cung cấp trải nghiệm tốt hơn cho mobile với khả năng snap tự động vào các layer trên map.

## Các tính năng chính

### 1. Crosshair Interface
- Icon tool hiển thị ở trung tâm màn hình
- Crosshair lines để định vị chính xác
- Màu sắc thay đổi khi phát hiện snap (xanh lá khi snap, xanh dương bình thường)

### 2. Snapping Logic
- Tự động phát hiện layer gần nhất trong phạm vi snap distance
- Hỗ trợ snap vào Point, Polyline, và Polygon geometries
- Cài đặt khoảng cách snap từ 10-50 pixels

### 3. Layer Configuration
- Cho phép bật/tắt snap cho từng layer riêng biệt:
  - Van điều khiển
  - Đồng hồ khách hàng
  - Ống phân phối
  - Ống ngánh
- Setting dialog để cấu hình layers và snap distance

### 4. Tool-based Symbols
Mỗi tool có symbol và màu sắc riêng:
- **Flag**: Triangle màu đỏ (size 18px)
- **Stop**: Square màu cam
- **Remove Circle**: Circle màu tím
- **Flash Auto**: Diamond màu vàng
- **Key Rounded**: Cross màu xanh lá

## Workflow sử dụng

### 1. Kích hoạt Tool
```dart
// User nhấn tool button trong bottom app bar
// Tự động trigger snapping mode
```

### 2. Snapping Mode
```dart
// Controller bắt đầu snapping mode
controller.startSnappingMode();

// Bắt đầu detect snap mỗi 300ms
_startSnapDetection();
```

### 3. User Interaction
- User kéo/zoom map để định vị
- Crosshair luôn ở trung tâm màn hình
- System tự động detect snap candidates
- Visual feedback khi tìm thấy snap point

### 4. Xác nhận điểm
```dart
// User nhấn button "Xác nhận"
controller.confirmSnapPoint();

// Lưu marker với thông tin:
// - Vị trí snap point
// - Tool type
// - Layer được snap (nếu có)
// - Timestamp
```

## Implementation Details

### Providers mới
```dart
// Snapping state
final isSnappingModeProvider = StateProvider<bool>((ref) => false);
final snapPointProvider = StateProvider<ArcGISPoint?>((ref) => null);
final snapCandidateProvider = StateProvider<Feature?>((ref) => null);

// Configuration
final snapDistanceProvider = StateProvider<double>((ref) => 20.0);
final enabledSnapLayersProvider = StateProvider<Set<String>>((ref) => {});
```

### Widget mới
- `SnappingOverlay`: Full-screen overlay với crosshair và controls
- `SnapSettingsDialog`: Dialog cấu hình snap settings

### Controller methods mới
- `startSnappingMode()`: Bắt đầu snapping mode
- `stopSnappingMode()`: Kết thúc snapping mode
- `confirmSnapPoint()`: Xác nhận và lưu điểm snap
- `_performSnapDetection()`: Logic detect snap liên tục
- `_findSnapCandidate()`: Tìm kiếm snap candidate

## Performance Optimizations

### 1. Debounced Detection
- Snap detection chạy mỗi 300ms thay vì real-time
- Tránh quá tải system

### 2. Layer Filtering
- Chỉ check snap trên layers được enable
- Giảm số lượng identify calls

### 3. Distance Optimization
- Configurable snap distance (10-50px)
- Early exit nếu không có feature trong range

## UI/UX Improvements

### 1. Visual Feedback
- Icon thay đổi màu khi snap
- "SNAP" indicator khi detect được feature
- Instructions text để hướng dẫn user

### 2. Mobile-friendly Controls
- Large touch targets
- Clear cancel/confirm buttons
- Semi-transparent overlay

### 3. Settings Integration
- Easy access settings button
- Checkbox list cho layers
- Slider cho snap distance

## Error Handling

### 1. Graceful Degradation
```dart
try {
  // Snap detection logic
} catch (e) {
  print("Error in snap detection: $e");
  // Continue without snap
}
```

### 2. Cleanup
```dart
void dispose() {
  _stopSnapDetection(); // Stop timers
  // Clear providers
}
```

## Migration từ addMarkerAtPoint

### Trước đây:
```dart
// Click vào map -> Add marker ngay lập tức
await addMarkerAtPoint(mapPoint);
```

### Bây giờ:
```dart
// Click tool -> Vào snapping mode
startSnappingMode();
// User position -> Confirm -> Save marker với snap logic
```

## Lợi ích của Snapping System

1. **Độ chính xác cao**: Snap tự động vào features thay vì click tự do
2. **Mobile-friendly**: Crosshair dễ sử dụng hơn trên mobile
3. **Tùy chọn linh hoạt**: Configure layers và distance
4. **Visual feedback**: Clear indication khi snap
5. **Tool differentiation**: Mỗi tool có symbol riêng
6. **Undo/Redo**: Có thể cancel trước khi confirm

## Cấu trúc file mới

```
lib/features/home/
├── widgets/
│   ├── snapping_overlay.dart      # New: Snapping UI overlay
│   ├── map_view.dart             # Existing
│   └── login_dialog.dart         # Existing
├── home_controller.dart          # Updated: Added snapping logic
├── home_page.dart               # Updated: Added SnappingOverlay
└── home_provider.dart           # Existing

lib/core/providers/
└── global_providers.dart        # Updated: Added snapping providers
```
