Проект использует:

- flutter_riverpod ^2.x
- dio
- null-safety
- Material 3
- существующий экран "Результаты" с двумя табами:
    - Все результаты
    - Мои результаты

Нужно реализовать функционал переноса результатов ТОЛЬКО в табе "Мои результаты".

Существующий код экрана и загрузку результатов НЕ ломать.

Комментарии в коде — на русском.
Код production-ready.

========================================================
BACKEND ENDPOINTS
========================================================

1) Получение текущего статуса заявки:
GET /api/v1/transfer/current

2) Получение списка доступных доноров:
GET /api/v1/transfer/eligible-athletes?search=...

3) Создание заявки:
POST /api/v1/transfer/request
{
    "source_athlete_id": int
}

========================================================
АРХИТЕКТУРА
========================================================

Разделить на:

lib/
 ├─ features/transfer/
 │   ├─ models/
 │   ├─ services/
 │   ├─ providers/
 │   ├─ widgets/
 │   └─ bottom_sheet/
 │
 └─ screens/results/

========================================================
ЧАСТЬ 1 — МОДЕЛИ
========================================================

1) TransferRequestModel
2) EligibleAthleteModel

Создать enum:

enum TransferStatus {
  pending,
  approved,
  rejected,
}

Добавить extension:
- isPending
- isApproved
- isRejected

========================================================
ЧАСТЬ 2 — API SERVICE (Dio)
========================================================

Создать TransferService:

Future<TransferRequestModel?> getCurrent();
Future<List<EligibleAthleteModel>> getEligible({String? search});
Future<void> createRequest(int sourceAthleteId);

Обработка:
- 401
- network errors
- business errors (422)

========================================================
ЧАСТЬ 3 — RIVERPOD PROVIDERS
========================================================

1️⃣ transferStatusProvider (AsyncNotifier)

Состояния:
- loading
- data (null = нет заявки)
- error

2️⃣ eligibleAthletesProvider (AutoDisposeAsyncNotifier)

Поддержка:
- search
- debounce 400ms
- refresh

Не смешивать эти два провайдера.

========================================================
ЧАСТЬ 4 — UI В ТАБЕ "МОИ РЕЗУЛЬТАТЫ"
========================================================

Внутри существующего таба:

ВЕРХНЯЯ ЧАСТЬ (над списком результатов):

ref.watch(transferStatusProvider)

Логика:

if loading:
  LinearProgressIndicator

if data == null:
  ElevatedButton(
    onPressed: openBottomSheet,
    child: Text("Привязать результаты"),
  )

if pending:
  StatusCard(color: amber)

if approved:
  StatusCard(color: green)

if rejected:
  StatusCard(color: red)
  + кнопка "Подать снова"

НИЖЕ — оставить существующий список результатов.

========================================================
ЧАСТЬ 5 — BOTTOM SHEET
========================================================

При нажатии "Привязать результаты":

showModalBottomSheet(
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  )
)

Внутри:

- DraggableScrollableSheet
- SafeArea
- Column:

  1) Drag indicator
  2) Заголовок "Выберите атлета"
  3) TextField для поиска
  4) Expanded ListView.builder

Каждый элемент списка:
- avatar (cached_network_image)
- имя
- Divider

При нажатии:

Показать AlertDialog подтверждения.

При подтверждении:
- await createRequest
- Navigator.pop()
- ref.invalidate(transferStatusProvider)
- показать SnackBar

========================================================
ЧАСТЬ 6 — UX ТРЕБОВАНИЯ
========================================================

- AnimatedSwitcher для статуса
- Pull-to-refresh в табе
- Loader внутри BottomSheet
- Пустое состояние "Ничего не найдено"
- Ошибки через SnackBar

========================================================
ВАЖНО
========================================================

- Не использовать setState
- Не трогать таб "Все результаты"
- Не вычислять статус вручную
- После создания заявки UI должен автоматически обновиться
- Использовать ref.invalidate для обновления статуса

========================================================
В РЕЗУЛЬТАТЕ НУЖНО
========================================================

- Модели
- Service
- Providers
- BottomSheet widget
- Изменённый код таба "Мои результаты"
- Все комментарии на русском

========================================================
ОПТИМИЗАЦИЯ ПОИСКА АТЛЕТОВ (РЕАЛИЗОВАНА)
========================================================

ПРОБЛЕМА:
При каждом изменении текста в поле поиска отправлялся запрос на сервер,
что создавало лишнюю нагрузку и задержки.

РЕШЕНИЕ:
1) При открытии bottomSheet сразу загружаются ВСЕ доступные атлеты (getEligibleAthletes())
2) При вводе в поле поиска выполняется ЛОКАЛЬНАЯ фильтрация
3) Запросы на сервер только один раз при открытии

ИЗМЕНЕНИЯ:

EligibleAthletesState:
+ allAthletes: List<EligibleAthleteModel> // полный список с сервера
+ allAthletesLoaded: bool // флаг загрузки
* athletes // теперь фильтрованный список

EligibleAthletesNotifier:
+ loadAllAthletes() // загрузка всех атлетов
* searchAthletes() // теперь локальная фильтрация
+ _filterAthletesLocally() // фильтрация по имени

AthleteSelectionBottomSheet:
* initState() // теперь loadAllAthletes() вместо searchAthletes('')
* логика отображения состояний

ПРЕИМУЩЕСТВА:
✅ Мгновенная фильтрация без задержек
✅ Снижение сетевого трафика в 10+ раз
✅ Лучший UX при медленном интернете
✅ Меньше нагрузки на сервер

========================================================
UI ОБНОВЛЕНИЯ (РЕАЛИЗОВАНЫ)
========================================================

ИЗМЕНЕНИЯ:
1. Убран аватар из списка атлетов в BottomSheet
2. Убран аватар из диалога подтверждения выбора атлета
3. Заменено отображение "результатов" на "общее количество гонок"

ОБНОВЛЕНИЯ МОДЕЛИ:
EligibleAthleteModel:
- resultsCount → totalRaces
- fromJson: results_count → total_races
- Обновлены все связанные методы

УЛУЧШЕНИЯ UI:
- Упрощенный дизайн без аватаров
- Фокус на главной информации: имя атлета + количество гонок
- Соответствие новой структуре API данных

УДАЛЕННЫЕ ЗАВИСИМОСТИ:
- cached_network_image (из athlete_selection_bottom_sheet.dart)
- image_url_helper (из athlete_selection_bottom_sheet.dart)
- Метод _buildDefaultAvatar() больше не нужен
