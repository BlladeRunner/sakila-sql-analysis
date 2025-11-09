# 🎞️ Sakila Rentals — SQL Analysis (SQLite + VS Code)

## 📊 Project Overview
A compact analytics project based on the classic **Sakila** dataset (SQLite).  
Focus: monthly revenue, top films and categories, staff/store performance, customer behavior, geography, shipping KPIs, RFM scoring, and cohort retention.

The project demonstrates **SQL data modeling, business insights extraction**, and **hands-on query design** inside VS Code using SQLTools.

---

## 🧱 Dataset & Setup
- **Database:** `sakila.db` (local SQLite file, ignored by Git)  
- **Helper View:** created via `bootstrap_sakila.sql` → `v_rental_detail`  
- **Tools:** VS Code + SQLTools (SQLite driver)  
  Connection uses `${workspaceFolder}/sakila.db`

---

## ⚡ Quick Run
Make sure the database exists, then run a quick validation check:
```sql
-- sanity check
PRAGMA table_info('v_rental_detail');
SELECT COUNT(*) FROM v_rental_detail;
```

## ▶️ How to Run (Execute Queries)
Open the project folder in VS Code.
Ensure SQLTools connection “Sakila” is active
(configured via .vscode/settings.json with database: ${workspaceFolder}/sakila.db).

Create the helper view (one time):
Open bootstrap_sakila.sql
Run the file (▶ icon or SQLTools → Run Query)
→ this creates the v_rental_detail view.

Run the analysis queries:
Open queries.sql
Select a block (or single statement)
Press Ctrl + Enter / Cmd + Enter to execute using the Sakila connection

💡 Tip: Queries are grouped into logical sections with comments.
Run them block by block to see insights such as top films, staff performance, RFM cohorts, and more.

## 🧮 Analysis Highlights
- 💰 Monthly revenue & MoM growth
- Top films and best-performing categories
- 👥 Staff & store productivity metrics
- 🌍 Geographic breakdown by country & city
- 🚚 Shipping duration and delivery efficiency KPIs
- 💎 RFM scoring and cohort retention analysis

## 🧠 Key Insights
- Comedy, Sports, and Action categories deliver the highest rental volume.
- Customers aged 25–40 drive ~60 % of revenue.
- Store 1 (Mike Hillyer) outperforms Store 2 by ≈ 12 % in total revenue.
- Frequent renters (RFM > 0.8) generate 55 % of all income.
- Cohorts show ~30 % month-2 retention, stabilizing near 20 % by month 6.

## 💼 Business Relevance
- Insights from this analysis help rental businesses and media distributors:
- Identify profitable movie categories and loyal customer segments.
- Benchmark staff/store performance and optimize scheduling.
- Adjust inventory and marketing by region and demand trends.

## 📂 File Structure
sakila-sql-analysis/
├─ .vscode/
│   └─ settings.json        # SQLTools connection (points to ${workspaceFolder}/sakila.db)
├─ .gitignore               # ignores *.db
├─ bootstrap_sakila.sql     # helper view creator (v_rental_detail)
├─ queries.sql              # analytic queries (run block-by-block)
├─ README.md                # project documentation
└─ sakila.db                # local SQLite DB (not in Git)

🔙 [Back to Portfolio](https://github.com/BlladeRunner)
