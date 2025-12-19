# Troubleshooting Guide - designAR

## Общи проблеми и решения

### 1. Проектът не се компилира

#### Проблем: "UIBezierPath not found" или подобни грешки
**Решение:**
- Проверете дали всички файлове използват правилните macOS frameworks
- `UIBezierPath` трябва да е `NSBezierPath`
- `UIColor` трябва да е `NSColor`

#### Проблем: "Cannot find type DrawingPath"
**Решение:**
- Уверете се, че `DrawingTool.swift` е добавен към проекта
- В Xcode: File > Add Files to "designAR"
- Проверете че файлът е в target membership

#### Проблем: Build failed with exit code 65
**Решение:**
```bash
# Изчистете derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/designAR-*

# Рестартирайте Xcode
# Отворете проекта отново
```

### 2. Xcode проблеми

#### Проблем: "Active developer directory error"
**Решение:**
```bash
# Проверете Xcode инсталацията
xcode-select -p

# Ако не е инсталиран, инсталирайте от App Store
# След това:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

#### Проблем: Missing scheme
**Решение:**
1. В Xcode отидете Product > Scheme > Manage Schemes
2. Уверете се че "designAR" scheme е налично
3. Ако не е, създайте ново scheme

### 3. Runtime грешки

#### Проблем: "App crashes on launch"
**Решение:**
- Проверете Console.app за crash logs
- Уверете се че entitlements са правилно настроени
- Проверете signing settings

#### Проблем: "Cannot import images"
**Решение:**
- Проверете `designAR.entitlements` съдържа:
```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

#### Проблем: "Export fails"
**Решение:**
- Уверете се че имате write permissions
- Проверете че директорията съществува
- Проверете disk space

### 4. File Permission грешки

#### Проблем: "Operation not permitted"
**Решение:**
1. System Settings > Privacy & Security
2. Files and Folders
3. Дайте достъп на Xcode и designAR

### 5. Build успешен но App не стартира

#### Проблем: App icon bounces и изчезва
**Решение:**
```bash
# Проверете crash log
open ~/Library/Logs/DiagnosticReports/

# Или в Console.app филтрирайте за "designAR"
```

**Често срещани причини:**
- Missing framework
- Entitlements проблем
- Code signing проблем

### 6. Specific Code грешки

#### SwiftUI Preview грешки
**Решение:**
- Презаредете preview: Option + Cmd + P
- Restart Xcode
- Clean build folder: Cmd + Shift + K

#### Memory грешки при трасиране
**Решение:**
- Намалете resolution на изображението
- Увеличете simplification параметъра
- Увеличете threshold стойността

## Стъпки за пълен reset

Ако нищо не работи:

```bash
# 1. Затворете Xcode

# 2. Изчистете всички build artifacts
cd ~/Desktop/designAR
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/designAR-*

# 3. Изтрийте cached data
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# 4. Рестартирайте Mac (optional но препоръчително)

# 5. Отворете отново Xcode
open designAR.xcodeproj

# 6. Clean + Build
# Product > Clean Build Folder (Cmd+Shift+K)
# Product > Build (Cmd+B)
```

## Чести въпроси

### Q: Защо приложението е толкова голямо?
A: Debug builds съдържат debug symbols. Release build ще е значително по-малък.

### Q: Трасирането е бавно
A: Това е нормално за сложни изображения. Използвайте по-висок threshold и simplification.

### Q: OBJ файлът не се импортира в Rhino
A: Проверете че файлът не е празен и има валидна геометрия.

### Q: Как да променя deployment target?
A: В Xcode:
1. Select project в Navigator
2. Select target "designAR"
3. General > Deployment Info
4. Променете "Minimum Deployments"

## Контакти за поддръжка

Ако продължавате да имате проблеми:

1. Съберете следната информация:
   - macOS версия: `sw_vers`
   - Xcode версия: `xcodebuild -version`
   - Error messages от Xcode
   - Console logs

2. Проверете дали проблемът е известен
3. Създайте подробен доклад за грешката

## Известни ограничения

- **macOS 14.0+ required** - Приложението използва нови SwiftUI APIs
- **Xcode 15.0+ required** - За Swift 5.9 features
- **Apple Silicon recommended** - Оптимизирано за M1/M2/M3
- **Memory intensive** - Auto-trace използва много памет за големи изображения

---

**Последна актуализация: 16.12.2025**
