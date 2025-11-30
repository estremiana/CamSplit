# StackedAvatarsWidget Usage Examples

## Basic Usage

```dart
StackedAvatarsWidget(
  members: groupMembers,
)
```

## Visual Examples

### 1-3 Members (No indicator)
```
Members: 1  →  [Avatar1]
Members: 2  →  [Avatar1][Avatar2]
Members: 3  →  [Avatar1][Avatar2][Avatar3]
```

### 4+ Members (With +N indicator)
```
Members: 4   →  [Avatar1][Avatar2][Avatar3][+1]
Members: 7   →  [Avatar1][Avatar2][Avatar3][+4]
Members: 10  →  [Avatar1][Avatar2][Avatar3][+7]
Members: 25  →  [Avatar1][Avatar2][Avatar3][+22]
```

## Customization Options

```dart
StackedAvatarsWidget(
  members: groupMembers,
  maxVisible: 3,                    // Show up to 3 avatars before "+N"
  size: 32.0,                       // Avatar size (32x32)
  spacing: 24.0,                    // Overlap spacing (8px overlap)
  borderColor: Colors.white,        // Border around avatars
  borderWidth: 2.0,                 // Border thickness
  moreIndicatorColor: Colors.grey[300],      // "+N" background
  moreIndicatorTextColor: Colors.grey[700],  // "+N" text color
  moreIndicatorFontSize: 12.0,      // "+N" font size
)
```

## Different Sizes

### Small (24px)
```dart
StackedAvatarsWidget(
  members: groupMembers,
  size: 24.0,
  spacing: 18.0,
  moreIndicatorFontSize: 10.0,
)
```

### Medium (32px) - Default
```dart
StackedAvatarsWidget(
  members: groupMembers,
  size: 32.0,
  spacing: 24.0,
  moreIndicatorFontSize: 12.0,
)
```

### Large (48px)
```dart
StackedAvatarsWidget(
  members: groupMembers,
  size: 48.0,
  spacing: 36.0,
  moreIndicatorFontSize: 14.0,
)
```

## Features

- ✅ Automatically shows "+N" for members beyond maxVisible
- ✅ Handles empty member lists gracefully
- ✅ Consistent styling across the app
- ✅ Fully customizable colors, sizes, and spacing
- ✅ Uses existing CustomImageWidget for avatar display
- ✅ Proper border and clipping for circular avatars
