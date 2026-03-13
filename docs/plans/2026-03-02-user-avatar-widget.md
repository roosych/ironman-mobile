# UserAvatarWidget Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `CircleAvatar + NetworkImage` with a reusable `UserAvatarWidget` that uses `CachedNetworkImage` for persistent disk caching and proper error fallback.

**Architecture:** Create one shared widget in `lib/shared/widgets/`, replace two usages in `home_tab.dart` and `profile_screen.dart`. The widget encapsulates loading/error/empty states. External wrappers (GestureDetector, Stack, Positioned camera icon) are not touched.

**Tech Stack:** Flutter, `cached_network_image: ^3.3.1`, `hugeicons`, `ImageUrlHelper`

---

### Task 1: Create UserAvatarWidget

**Files:**
- Create: `lib/shared/widgets/user_avatar_widget.dart`

**Step 1: Create the widget**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/shared/utils/image_url_helper.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? url;
  final double radius;

  const UserAvatarWidget({
    super.key,
    required this.radius,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    if (!hasUrl) {
      return _placeholder(context);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: ImageUrlHelper.getFullImageUrl(url),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(context),
        errorWidget: (context, url, error) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        size: radius,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
```

**Step 2: Verify file is created correctly**

Убедиться что файл создан в правильном месте и нет синтаксических ошибок.

---

### Task 2: Replace CircleAvatar в home_tab.dart

**Files:**
- Modify: `lib/features/dashboard/presentation/home_tab.dart:337-352`

**Step 1: Добавить import UserAvatarWidget**

Добавить в список импортов (после существующих shared/widgets импортов):
```dart
import 'package:ironman_mobile/shared/widgets/user_avatar_widget.dart';
```

**Step 2: Удалить import image_url_helper**

Строка для удаления:
```dart
import 'package:ironman_mobile/shared/utils/image_url_helper.dart';
```
`ImageUrlHelper` используется только внутри `CircleAvatar` (строка 343), которую мы заменяем. После замены импорт не нужен.

**Step 3: Заменить CircleAvatar (строки 337-352)**

Было:
```dart
child: CircleAvatar(
  radius: 32, // Увеличенный размер
  backgroundColor: (user?.avatarUrl != null && user?.avatarUrl?.isNotEmpty == true)
      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
      : Theme.of(context).colorScheme.surfaceContainerHighest,
  backgroundImage: (user?.avatarUrl != null && user?.avatarUrl?.isNotEmpty == true)
      ? NetworkImage(ImageUrlHelper.getFullImageUrl(user!.avatarUrl!))
      : null,
  child: (user?.avatarUrl == null || user?.avatarUrl?.isEmpty == true)
      ? HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          size: 32,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        )
      : null,
),
```

Стало:
```dart
child: UserAvatarWidget(
  url: user?.avatarUrl,
  radius: 32,
),
```

**Step 4: Убедиться что GestureDetector и onTap нетронуты**

Внешний `GestureDetector` с навигацией на ProfileScreen остаётся без изменений.

---

### Task 3: Replace CircleAvatar в profile_screen.dart

**Files:**
- Modify: `lib/features/dashboard/presentation/profile_screen.dart:108-123`

**Step 1: Добавить import UserAvatarWidget**

Добавить в список импортов:
```dart
import '../../../shared/widgets/user_avatar_widget.dart';
```

**Step 2: Удалить import image_url_helper**

Строка для удаления:
```dart
import '../../../shared/utils/image_url_helper.dart';
```
`ImageUrlHelper` используется только внутри заменяемого `CircleAvatar` (строка 114).

**Step 3: Заменить CircleAvatar (строки 108-123)**

Было:
```dart
CircleAvatar(
  radius: 50,
  backgroundColor: (avatarUrl != null && avatarUrl.isNotEmpty)
      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
      : Theme.of(context).colorScheme.surfaceContainerHighest,
  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
      ? NetworkImage(ImageUrlHelper.getFullImageUrl(avatarUrl))
      : null,
  child: (avatarUrl == null || avatarUrl.isEmpty)
      ? HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          size: 50,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        )
      : null,
),
```

Стало:
```dart
UserAvatarWidget(
  url: avatarUrl,
  radius: 50,
),
```

**Step 4: Убедиться что Stack и Positioned camera icon нетронуты**

`Stack` с `Positioned` камера-иконкой (строки 106-142) остаётся без изменений. `UserAvatarWidget` заменяет только первый child Stack'а.

---

### Task 4: Commit

```bash
git add lib/shared/widgets/user_avatar_widget.dart
git add lib/features/dashboard/presentation/home_tab.dart
git add lib/features/dashboard/presentation/profile_screen.dart
git commit -m "feat: add UserAvatarWidget with CachedNetworkImage for offline avatar support"
```
