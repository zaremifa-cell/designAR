# AI Vision Technology - designAR

## 🧠 Професионално AI трасиране

Новата версия на designAR използва **Apple Vision Framework** за интелигентно разпознаване на архитектурни елементи.

## 🔬 Технологии

### 1. Vision Framework
```swift
import Vision

// Contour Detection
VNDetectContoursRequest - Открива контури на обекти
VNDetectRectanglesRequest - Открива правоъгълници (прозорци, врати, стени)
```

**Предимства:**
- ✅ ML-базирано - учи се от данни
- ✅ По-точно от класически edge detection
- ✅ Разпознава геометрични форми
- ✅ Native Apple технология - оптимизирано за M-series чипове

### 2. Hough Line Transform
Имплементиран custom алгоритъм за откриване на прави линии:

```swift
// Hough Transform Parameters
- Angle Resolution: 1 degree
- Distance Resolution: 1 pixel
- Threshold: 20 votes минимум
```

**Какво прави:**
- Открива прави линии във всички ъгли
- Merge-ва близки паралелни линии
- Филтрира шум и къси линии

### 3. Line Optimization

**Smart Merging:**
```swift
- Distance threshold: 20 pixels
- Angle similarity: 0.1 radians (~6 degrees)
- Minimum line length: 10 pixels
- Confidence filtering: >0.5
```

## 📊 Как работи трасирането

### Pipeline:

```
Input Image
    ↓
[Step 1: Contour Detection (20%)]
├─ Vision Framework
├─ Contrast adjustment: 1.5x
└─ Output: Smooth contours
    ↓
[Step 2: Line Detection (40%)]
├─ Edge Detection (CIEdges)
├─ Hough Transform
└─ Output: Straight lines
    ↓
[Step 3: Shape Recognition (60%)]
├─ Rectangle Detection
├─ Geometric analysis
└─ Output: Architectural features
    ↓
[Step 4: Optimization (80%)]
├─ Line merging
├─ Noise filtering
└─ Output: Clean geometry
    ↓
[Step 5: Path Generation (100%)]
├─ Convert to DrawingPaths
└─ Output: Ready for 3D
```

## 🎯 Detected Features

### DetectedLine
```swift
struct DetectedLine {
    var start: CGPoint      // Начална точка
    var end: CGPoint        // Крайна точка
    var confidence: Float   // 0.0-1.0 (колко сигурно е)
    var angle: CGFloat      // Ъгъл на линията
    var length: CGFloat     // Дължина
}
```

### ArchitecturalFeature
```swift
enum FeatureType {
    case wall       // Стена
    case window     // Прозорец
    case door       // Врата
    case roof       // Покрив
    case floor      // Под
    case unknown    // Неразпознато
}
```

## 🔧 Настройки

### Edge Detection Threshold
- **Low (0.1-0.3):** Открива повече детайли, но и повече шум
- **Medium (0.4-0.6):** Балансирано (препоръчано)
- **High (0.7-1.0):** Само силни ръбове, минимален шум

### Detection Methods

**AI Vision (Recommended):**
- Uses Vision Framework
- Intelligent shape recognition
- Better for architectural photos
- Slower but more accurate

**Classic Edge Detection:**
- Uses CoreImage filters
- Fast processing
- Good for simple sketches
- Less accurate on complex images

## 💡 Best Practices

### За най-добри резултати:

1. **Качество на снимката:**
   - Висока резолюция (>1920x1080)
   - Добро осветление
   - Минимални сенки
   - Ясни контури

2. **Тип изображения:**
   ✅ Архитектурни фасади
   ✅ Технически чертежи
   ✅ Скани на скици
   ✅ CAD screenshots

   ⚠️ По-трудни:
   - Текстурирани повърхности
   - Много сенки
   - Размити снимки
   - Сложни орнаменти

3. **Настройки:**
   - Започни с AI Vision
   - Threshold 0.5 default
   - Ако има много шум → увеличи threshold
   - Ако липсват детайли → намали threshold

## 🚀 Performance

### Скорост на обработка:
- **Small images** (640x480): ~1-2 секунди
- **Medium images** (1920x1080): ~3-5 секунди
- **Large images** (4K): ~8-12 секунди

### Оптимизации:
- ✅ Multi-threading (DispatchQueue)
- ✅ Stride sampling (всеки 2-ри pixel)
- ✅ Progress tracking
- ✅ Memory efficient

### Hardware:
- **Apple Silicon (M1/M2/M3):** Optimal
- **Intel Macs:** Работи, но по-бавно
- **RAM:** Минимум 8GB препоръчителни

## 🔮 Бъдещи подобрения

### Phase 2: Custom ML Model
```
Goal: Train собствен Core ML model
Data: 1000+ архитектурни чертежи
Result: 90%+ accuracy за:
  - Walls
  - Windows
  - Doors
  - Structural elements
```

### Phase 3: Perspective Correction
```swift
// Auto-detect vanishing points
func detectPerspective(lines: [DetectedLine]) -> [CGPoint]

// Correct perspective distortion
func correctPerspective(image: NSImage, vanishingPoints: [CGPoint]) -> NSImage
```

### Phase 4: 3D Depth Estimation
```
From single image:
1. Detect horizon line
2. Find vanishing points
3. Calculate depth per line
4. Generate true 3D geometry
```

## 📖 API Reference

### VisionTracer Class

```swift
class VisionTracer: ObservableObject {
    // Progress tracking
    @Published var isProcessing: Bool
    @Published var progress: Double

    // Results
    @Published var detectedLines: [DetectedLine]
    @Published var detectedCorners: [CGPoint]

    // Main function
    func traceImage(_ image: NSImage,
                   completion: @escaping ([DrawingPath]) -> Void)
}
```

### Usage Example:

```swift
let tracer = VisionTracer()

tracer.traceImage(myImage) { paths in
    // paths ready for 3D generation
    viewModel.paths.append(contentsOf: paths)
}

// Monitor progress
Text("\(Int(tracer.progress * 100))%")
```

## 🎓 Technical Details

### Coordinate System:
```
(0,0) ─────────→ X (width)
  │
  │
  ↓
  Y (height)

Vision Framework uses normalized coordinates (0-1)
We convert to pixel coordinates for drawing
```

### Color Spaces:
- Input: Any (auto-converted)
- Processing: RGB
- Edge Detection: Grayscale
- Output: RGB + Alpha

### Thread Safety:
- Main thread: UI updates only
- Background thread: Image processing
- Thread-safe: @Published properties with DispatchQueue.main.async

---

**Created:** 16.12.2025
**Author:** designAR Team
**Version:** 2.0 (AI-powered)
