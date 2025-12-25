# PostgreSQL Inspector

A **PowerShell script** for inspecting and monitoring a PostgreSQL database.  
The script connects to a PostgreSQL server and displays **live diagnostic information** in a clear, color-coded format.

---

## Features

- Connects safely to any PostgreSQL database using a URL
- Checks **server version**, **uptime**, **current database/user**
- Monitors **active queries** and **index usage**
- Reports **vacuum/dead tuple statistics** and **database size**
- Displays **WAL statistics** (if permitted)
- Shows **autovacuum and memory settings**
- Color-coded output for easier reading:
  - **Cyan** → Query title
  - **Yellow** → Descriptive commentary
  - **Green** → Success messages
  - **Red** → Errors or warnings
- Runs in a **continuous loop** for live monitoring

---

## Requirements

- **PowerShell** (Windows, macOS, Linux)
- **PostgreSQL `psql` CLI** installed and in PATH
- Access to a PostgreSQL database with read permissions

---

## Installation

1. Clone or download this repository:

```bash
git clone <repository_url>
