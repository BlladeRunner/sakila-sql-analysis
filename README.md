# Sakila Rentals — SQL Analysis (SQLite + VS Code)

Compact analytics project on the classic **Sakila** dataset (SQLite).
Focus: monthly revenue, top films & categories, staff/store performance, geography,
shipping KPIs, **RFM** scoring and **cohort** retention.

## Dataset & Setup

- **DB**: `sakila.db` (local, **ignored** by Git)
- Helper view created via **bootstrap_sakila.sql** → `v_rental_detail`
- VS Code + **SQLTools** (SQLite driver). Connection uses `${workspaceFolder}/sakila.db`.

### Quick run

1. Ensure `sakila.db` exists locally.
2. Run:
   ```sql
   -- sanity checks
   PRAGMA table_info('v_rental_detail');
   SELECT COUNT(*) FROM v_rental_detail;
   ```

## ▶️ How to run (execute queries)

1. Open the project folder in **VS Code**.
2. Make sure the **SQLTools** connection **Sakila** is active  
   (configured via `.vscode/settings.json` with `database: ${workspaceFolder}/sakila.db`).
3. (One-time) Create the helper view:
   - Open `bootstrap_sakila.sql`
   - Run the file (play icon / **SQLTools: Run Query**).  
     This creates the view `v_rental_detail`.
4. Run analysis queries:
   - Open `queries.sql`
   - Select a block (or a single statement) and press **Run**  
     (hotkey: **Ctrl+Enter** / **Cmd+Enter**) using the active **Sakila** connection.

> Tip: queries are grouped in logical blocks with comments. Execute them one block at a time,
> to get the relevant results (top films, staff performance, RFM, cohorts, etc.).

## 📁 File structure

sakila-sql-analysis/
├─ .vscode/
│ └─ settings.json # SQLTools connection (points to ${workspaceFolder}/sakila.db)
├─ .gitignore # ignores \*.db so the database isn’t pushed to Git
├─ bootstrap_sakila.sql # one-time helper view creator (v_rental_detail)
├─ queries.sql # all analytic queries (run block-by-block)
├─ README.md # this documentation
└─ sakila.db # local SQLite DB (not in Git)
