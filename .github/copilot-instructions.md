### Copilot / AI Agent Instructions for Finanzadiaria (local)

Short summary
- Purpose: mobile personal finance app using Flutter + Hive for local persistence.
- Entry: `lib/main.dart` initializes Hive, registers adapters, opens boxes, sets locale (`es_MX`).

Key architecture & responsibilities
- UI: `lib/screens/*` — widgets and dialogs. `SetupScreen` writes initial settings; `HomeScreen` reads and displays provider data.
- State & business logic: `lib/providers/finance_provider.dart` — single source of truth (ChangeNotifier). It reads/writes Hive boxes named `settings`, `transactions`, `categories` and exposes computed helpers like `getAvailableToday()` and `getExpensesByCategoryLast30Days()`.
- Data models: `lib/models/transaction.dart` (typeId=0) and `lib/models/category.dart` (typeId=1). These use Hive codegen (`part '*.g.dart'`) and extend `HiveObject`.

Important conventions and patterns (do not change lightly)
- Hive boxes used: `settings`, `transactions`, `categories`. Code depends on these exact names.
- Adapter typeIds are fixed: `Transaction` typeId=0, `Category` typeId=1 — avoid reassigning IDs.
- `FinanceProvider` persists simple primitives into `settings` (e.g., `dailyIncome`, `payFrequency`, `lastPayDate` stored as milliseconds). Prefer using provider methods (e.g., `saveIncomeConfig`, `updateBalances`) when changing state.
- Date formatting uses `intl` with `initializeDateFormatting('es_MX')` in `main.dart`. UI expects `dd/MM/yyyy` format via `FinanceProvider.dateFormat`.
- User input numeric parsing: code replaces commas with periods (`replaceAll(',', '.')`) before `double.tryParse` — keep that pattern for locale-safe parsing.
- Transactions are HiveObjects; deletion in UI calls `trans.delete()`.

Build / test / dev workflows
- Common commands (run from repo root):
  - Install deps: `flutter pub get`
  - Run on connected device/emulator: `flutter run`
  - Build APK: `flutter build apk`
  - Generate Hive adapters (only needed if models change):
    `flutter pub run build_runner build --delete-conflicting-outputs`
  - Run widget tests: `flutter test` (project has a simple `test/widget_test.dart`).
- iOS builds require macOS Xcode; Android builds work on Windows.

Where to look for common changes
- Add/modify model fields: update `lib/models/*.dart`, then run build_runner to regenerate `*.g.dart` adapters and ensure typeIds unchanged.
- Business logic or computed values: `lib/providers/finance_provider.dart` — most payment/saldo logic lives here.
- UI changes: `lib/screens/home_screen.dart` and `lib/screens/setup_screen.dart`.
- Charts: uses `fl_chart` in `home_screen.dart` — keep `getExpensesByCategoryLast30Days()` and `getDailyExpensesLast7Days()` shapes when modifying chart UI.

Integration points & external deps
- Hive: `hive`, `hive_flutter`, codegen (`hive_generator`). Boxes are opened in `main.dart`.
- Provider: for state management; `ChangeNotifierProvider` is mounted in `main.dart`.
- fl_chart: used for pie/line charts in `home_screen.dart`.
- intl: date formatting, initialized in `main.dart`.

Examples for common agent tasks
- To add a new `Category` field: update `lib/models/category.dart` -> run build_runner -> verify adapters registered in `main.dart` and boxes behave.
- To add a new computed metric: implement function in `FinanceProvider`, update UI in `home_screen.dart` to read provider.<br/>

Safety notes for automated edits
- Do not rename Hive boxes or adapter typeIds.
- Preserve numeric parsing patterns and date locale initialization.
- If changing model fields or typeIds, add migration steps and keep backups of existing boxes (this repo does not include automated migrations).

If anything here is unclear or you'd like examples merged into tests or CI steps, tell me which section to expand.
