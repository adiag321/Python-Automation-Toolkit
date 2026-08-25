# Python Automation & Utility Toolkit

A curated collection of practical Python automation scripts, AI-powered utilities, web scrapers, and developer tools designed to streamline daily workflows, boost productivity, and automate repetitive tasks.

[![Python Version](https://img.shields.io/badge/Python-3.9%2B-blue.svg?logo=python&logoColor=white)](https://www.python.org/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-Yes-green.svg)](https://github.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg)](https://github.com/)

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Project Directory Structure](#-project-directory-structure)
- [Tool Catalog & Features](#-tool-catalog--features)
  - [I & LLM Utilities](#-ai--llm-utilities)
  - [Finance & Market Intelligence](#-finance--market-intelligence)
  - [Developer & Git Automation](#-developer--git-automation)
  - [Media & Web Scraping](#-media--web-scraping)
  - [System & OS Management](#-system--os-management)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Variables & Configuration](#environment-variables--configuration)
- [Usage Guide](#-usage-guide)
- [Security & Best Practices](#-security--best-practices)
- [Contributing](#-contributing)
- [License](#-license)

---

## Overview

This repository acts as a centralized monorepo containing standalone utilities, modular automation scripts, and workflow boosters. Each tool is self-contained with its own logic, making it easy to run individually or integrate into larger automated pipelines and cron jobs.

---

## Project Directory Structure

```text
python-automation-toolkit/
│
├── Add Stock Earning Call to Google Cal/   # Scrapes earnings dates and syncs to Google Calendar
├── Chrome_Bookmark_downloader/            # Extracts and downloads resources from Chrome bookmarks
├── Clean_my_Mac/                          # System cleanup script for caches, logs, and temp files
├── Fetch Stock Analyst Ratings/           # Financial scraper for equity ratings & consensus targets
├── Fetching Reddit Information/           # Reddit API extractor for subreddits, posts, and sentiments
├── GitHub Activity Generator/             # Utility for simulating Git commit histories
├── Readme Generator/                      # Automated README.md generator for code repositories
├── Youtube Video Summarizer Using LLM/    # AI-powered YouTube transcript summarizer
├── Youtube_playlist_Downloader/           # High-resolution playlist and video media downloader
│
├── Fetch GitHub Repo Details.py           # GitHub REST API client for fetching repository metadata
├── Hack_Git.py                            # Git automation and commit timestamp modifier
├── fetch_folder_name.py                   # Filesystem directory structure analyzer
├── folder_names.txt                       # Directory inventory snapshot
├── requirements.txt                       # Global dependencies list
└── README.md                              # Repository documentation
```

---

## Tool Catalog & Features

### AI & LLM Utilities

| Tool | Description | Key Libraries |
| :--- | :--- | :--- |
| **`Youtube Video Summarizer Using LLM`** | Extracts YouTube captions/transcripts and leverages LLMs (OpenAI / Claude / Gemini / LangChain) to generate structured summaries, key takeaways, and action items. | `youtube-transcript-api`, `langchain`, `openai` |
| **`Readme Generator`** | Analyzes project source files and automatically writes formatted, comprehensive `README.md` files using generative AI. | `openai`, `pathlib`, `jinja2` |

---

### Finance & Market Intelligence

| Tool | Description | Key Libraries |
| :--- | :--- | :--- |
| **`Add Stock Earning Call to Google Cal`** | Monitors upcoming quarterly earnings calls for watchlisted tickers and automatically creates scheduled Google Calendar events with dial-in / webcast details. | `google-api-python-client`, `yfinance`, `beautifulsoup4` |
| **`Fetch Stock Analyst Ratings`** | Scrapes consensus price targets, upgrades/downgrades, and Wall Street analyst recommendations for target equities. | `requests`, `pandas`, `yfinance`, `bs4` |

---

### Developer & Git Automation

| Tool | Description | Key Libraries |
| :--- | :--- | :--- |
| **`Fetch GitHub Repo Details.py`** | Queries the GitHub REST API to pull repository statistics, stargazers, forks, open issues, commit velocity, and language breakdowns. | `requests`, `rich` |
| **`GitHub Activity Generator`** | Script designed to backdate contributions and simulate realistic commit activity patterns across designated date ranges. | `GitPython`, `datetime` |
| **`Hack_Git.py`** | Fast CLI script for automating git commits, author date modifications, and batch push operations. | `subprocess`, `os` |
| **`fetch_folder_name.py`** | Inspects project directory trees and exports clean directory hierarchy logs into `folder_names.txt`. | `os`, `pathlib` |

---

### Media & Web Scraping

| Tool | Description | Key Libraries |
| :--- | :--- | :--- |
| **`Youtube_playlist_Downloader`** | Multi-threaded downloader for YouTube playlists and standalone videos with audio/video stream selection. | `yt-dlp`, `pytube` |
| **`Chrome_Bookmark_downloader`** | Parses exported Google Chrome HTML/JSON bookmark files and downloads media/articles for offline archival. | `beautifulsoup4`, `requests` |
| **`Fetching Reddit Information`** | Connects to the Reddit API (PRAW) to scrape top submissions, comments, and sentiment from specified subreddits. | `praw`, `pandas` |

---

### System & OS Management

| Tool | Description | Key Libraries |
| :--- | :--- | :--- |
| **`Clean_my_Mac`** | Lightweight macOS maintenance utility that clears system logs, user cache folders, Xcode derived data, and trash. | `shutil`, `os`, `subprocess` |

---

## Getting Started

### Prerequisites

* **Python:** Version `3.9` or higher installed on your system.
* **Git:** Installed and configured.
* **API Credentials** (Optional, based on tools used):
  * OpenAI / Anthropic / Google Gemini API Key
  * Google Cloud Console OAuth 2.0 Credentials (for Calendar sync)
  * Reddit Developer App Credentials (`client_id`, `client_secret`)
  * GitHub Personal Access Token (`GH_TOKEN`)

---

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/python-automation-toolkit.git
   cd python-automation-toolkit
   ```

2. **Create and activate a virtual environment:**
   ```bash
   # macOS / Linux
   python3 -m venv venv
   source venv/bin/activate

   # Windows
   python -m venv venv
   venv\Scripts\activate
   ```

3. **Install required packages:**
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

---

### Environment Variables & Configuration

Create a `.env` file in the root directory (or in specific tool subfolders as required):

```env
# AI / LLM Configuration
OPENAI_API_KEY="your-openai-api-key"
ANTHROPIC_API_KEY="your-anthropic-api-key"

# Reddit API Credentials
REDDIT_CLIENT_ID="your-reddit-client-id"
REDDIT_CLIENT_SECRET="your-reddit-client-secret"
REDDIT_USER_AGENT="PythonAutomationToolkit/1.0"

# GitHub Token
GITHUB_TOKEN="your-github-personal-access-token"

# Google Calendar API (Path to client credentials json)
GOOGLE_APPLICATION_CREDENTIALS="credentials.json"
```

> **Important:** Never commit your `.env` or `credentials.json` files to Git. Ensure they are listed in `.gitignore`.

---

## Usage Guide

Each subfolder contains its own execution entry point. You can run them directly from your terminal:

### 1. YouTube Video Summarizer
```bash
cd "Youtube Video Summarizer Using LLM"
python main.py --url "https://www.youtube.com/watch?v=VIDEO_ID"
```

### 2. Stock Earnings to Google Calendar
```bash
cd "Add Stock Earning Call to Google Cal"
python sync_earnings.py --tickers AAPL,NVDA,MSFT,GOOGL
```

### 3. macOS System Cleaner
```bash
cd "Clean_my_Mac"
python clean_mac.py --dry-run   # Preview files to be removed
python clean_mac.py --execute   # Clean caches and temporary files
```

### 4. Fetch GitHub Repo Details
```bash
python "Fetch GitHub Repo Details.py" --repo "owner/repository-name"
```

---

## Security & Best Practices

- **Secrets Management:** Keep all API keys, OAuth tokens, and private secrets inside `.env` or local keychains.
- **Rate Limiting:** Web scrapers (`Reddit`, `Stock Ratings`, `YouTube`) include built-in delays and exponential backoffs to prevent IP blocking.
- **Safe Deletion:** The `Clean_my_Mac` script skips critical system directories and prompts for confirmation before purging data.

---

## Contributing

Contributions, feature requests, and improvements are always welcome!

1. **Fork** the repository.
2. **Create** your feature branch (`git checkout -b feature/NewAwesomeTool`).
3. **Commit** your changes (`git commit -m "Add NewAwesomeTool"`).
4. **Push** to the branch (`git push origin feature/NewAwesomeTool`).
5. **Open** a Pull Request.

---

## License

This project is licensed under the [MIT License](LICENSE) — you are free to use, modify, and distribute it for personal and commercial projects.
