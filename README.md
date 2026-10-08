# DeveloperPR 🚀 — AI-Powered GitHub PR Reviewer & Dashboard

**DeveloperPR** (DevUtil) is a high-performance cross-platform Flutter application that automates **GitHub Pull Request Code Reviews** using **Google Gemini AI**. It analyzes multi-file code diffs in real-time, flags security vulnerabilities, detects architectural risks, assesses test coverage, and aggregates PR reviewer status into a unified developer dashboard.

---

## ✨ Key Features

* 🤖 **Automated AI Code Review**: Powered by Google Gemini AI (2.0 Flash / Gemma), generating structured PR executive summaries, risk levels (`HIGH`, `MEDIUM`, `LOW`), flagged issues with exact line numbers, and actionable refactoring suggestions.
* 🛡️ **Security & Vulnerability Auditing**: Automatically checks code diffs for memory leaks, missing input validation, unhandled exceptions, and unparsed JSON responses.
* 📱 **Seamless End-to-End User Flow**:
  1. 🔑 **Zero-Auth Username Entry**: Enter any public GitHub username without needing OAuth tokens or personal passwords.
  2. 🔍 **Repository Explorer**: Search and filter public repositories with language tags, star count, and open issue counts.
  3. 📑 **PR List Dashboard**: Filter Pull Requests by status (`Open`, `Closed`, `All`) with real-time status indicators.
  4. 📊 **Multi-Tab PR Analysis Workspace**:
     * 📋 **Overview**: PR metadata, title, author, branch details, CI pending/passing badges, total line change counts (`+153 / -367`), and categorized diff breakdown across UI, Logic, & Data layers.
     * 📂 **Files**: Detailed diff tree with additions (`+`), deletions (`-`), status tags (`MODIFIED`, `ADDED`, `REMOVED`), and line-by-line syntax-highlighted patches.
     * 💬 **Reviews**: Real-time reviewer approval statuses (`APPROVED`, `CHANGES_REQUESTED`, `COMMENTED`).
     * 🤖 **AI Review**: Executive Summary, Risk Scoring, Flagged Potential Issues with line numbers, Improvement Suggestions, and Test Adequacy breakdown.
* ⚡ **Resilient Network & AI Engine**: Built with **Dio**, exponential retry interceptors, rate-limit monitors, dynamic model discovery, and a custom fault-tolerant JSON repair parser for LLM streams.
* 🔐 **Privacy-First Key Management**: Zero key leakage on public GitHub repos. Supports local `.gitignore`-shielded run scripts and `--dart-define` key injection.

---

## 📱 Application Walkthrough & User Flow

```text
[ 🔑 Login Screen ] ──────> [ 🔍 Repository Search ] ──────> [ 📑 PR List Dashboard ]
Enter GitHub username        Browse & filter repos            Filter by Open / Closed / All
                                                                     │
                                                                     ▼
[ 🤖 AI Review Tab ] <────── [ 💬 Reviews Tab ] <────── [ 📂 Files Tab ] <────── [ 📋 Overview Tab ]
1-Click AI Code Review        Reviewer Approvals              Syntax-Highlighted Diffs    PR Metadata & Change Breakdown
Risk Scoring & Line Flags     (APPROVED / CHANGES_REQUESTED)  Additions (+) / Deletions (-) Total lines (+153 / -367)
```

---

## 🚀 How to Run the Project

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19+)
- A free Google Gemini API Key from [Google AI Studio](https://aistudio.google.com/app/apikey)

---

### 🟢 Method 1: Shortcut Local Run Scripts (Recommended)

1. Open `run.ps1` (PowerShell) or `run.bat` (CMD) in the project root.
2. Paste your Gemini API key into `GEMINI_KEY`. *(Note: `run.ps1` and `run.bat` are `.gitignore`-shielded and will never be pushed to GitHub!)*
3. Run the short command:

#### PowerShell (Windows):
```powershell
.\run.ps1
```

#### Command Prompt (CMD):
```cmd
run.bat
```

---

### 🔵 Method 2: Direct Flutter Run Command

You can also run directly from the terminal by passing your key securely via `--dart-define`:

#### Web (Chrome):
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY="AIzaSyYourActualGeminiApiKey"
```

#### Android / Desktop:
```bash
flutter run --dart-define=GEMINI_API_KEY="AIzaSyYourActualGeminiApiKey"
```

---

## 🛠️ Tech Stack & Architecture

DeveloperPR is built following **Layered Clean Architecture** principles:

```text
lib/
├── core/                  # Core infrastructure (Network, Dio Client, Theme, Config)
│   ├── config/            # AppConfig & Environment definitions
│   ├── network/           # Dio Client, Auth & Rate-Limit Interceptors
│   └── cache/             # Hive Cache Manager
├── data/                  # Data Layer (Repositories & Remote Data Sources)
│   ├── datasources/       # GitHub API & Gemini AI Remote Data Sources
│   ├── models/            # JSON Serialization & Cache Models
│   └── repositories/      # Repository Implementations
├── domain/                # Business Logic Layer (Entities, Use Cases, Interfaces)
│   ├── entities/          # PR, FileChange, Review & AI Analysis Entities
│   └── usecases/          # Business logic use cases
└── presentation/          # UI Layer (BLoC State Management, Screens, Widgets)
    ├── blocs/             # AuthBloc, PRBloc, AiAnalysisBloc
    ├── screens/           # LoginScreen, PRListScreen, PRDetailScreen
    └── widgets/           # AIReviewTab, FileDiffTile, ReviewerTile, SummaryBreakdown
```

- **Framework**: [Flutter](https://flutter.dev) (Dart 3+)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) & [bloc](https://pub.dev/packages/bloc)
- **HTTP Client**: [Dio](https://pub.dev/packages/dio) with custom interceptors & retries
- **Local Storage / Cache**: [Hive](https://pub.dev/packages/hive) & [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **Functional Utilities**: [fpdart](https://pub.dev/packages/fpdart) (Either / Failure pattern)
- **Markdown Rendering**: [flutter_markdown](https://pub.dev/packages/flutter_markdown)

---

## 📜 License

This project is open-source and available under the [MIT License](LICENSE).
