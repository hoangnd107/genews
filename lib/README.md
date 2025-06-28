# GeNews Library Structure

This directory contains the main source code for the GeNews application, organized using a feature-based architecture.

## Structure

```
lib/
├── app/                 # Application configuration and setup
│   ├── config/         # App constants, enums, Firebase options
│   ├── themes/         # UI themes and styling
│   ├── routes/         # Navigation routes (if needed)
│   └── app.dart        # Main application widget
├── features/           # Feature-based modules
│   ├── analysis/       # News analysis and summary features
│   ├── bookmarks/      # Bookmarks management
│   ├── main/           # Main screen and navigation
│   ├── news/           # News listing and reading features
│   └── settings/       # App settings and preferences
├── shared/             # Shared components across features
│   ├── services/       # Business logic and data services
│   ├── utils/          # Utility functions and helpers
│   └── widgets/        # Reusable UI components
└── genews.dart         # Main library export file
```

## Feature Structure

Each feature follows a consistent structure:

- `data/` - Data models and repositories
- `providers/` - State management (Provider pattern)
- `views/` - UI screens and pages
- `widgets/` - Feature-specific UI components

## Import Guidelines

Use barrel exports for cleaner imports:

```dart
// Instead of multiple imports
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/providers/news_provider.dart';

// Use feature exports
import 'package:genews/features/news/news.dart';
```

## Best Practices

1. Keep production code in `lib/` and test/debug code in `test/`
2. Use feature-based organization for better maintainability
3. Leverage barrel exports for cleaner imports
4. Follow consistent naming conventions
5. Separate business logic from UI components
