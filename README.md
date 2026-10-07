# SQL Interview, Visually Explained: practice files

Companion files for the book **SQL Interview, Visually Explained** by Serhio Yakos.

Reading a solution is not the same as writing one. These files let you run every query from the book, change it, and break it on purpose.

## Download

No GitHub account is needed. Press the green **Code** button above and choose **Download ZIP**.

## What is here

| File | What it is |
|---|---|
| `shop_postgres.sql` | Creates and fills every table used in Chapters 1 to 9 and 11. Runs unchanged in PostgreSQL and in DuckDB. |
| `all_solutions.sql` | Every solution in the book, in order, each under a header such as `-- Problem 5.3`. Chapter 10 entries hold the slow and the fast version with the index each one needs. |
| `big_tables.py` | Generates the 200,000 row tables of Chapter 10 with the same random seed as the book and loads them into PostgreSQL. |

## Fastest way to start

1. Install [DuckDB](https://duckdb.org). It is a single program with no server to set up.
2. Create a database file and load the data: run `duckdb shop.duckdb`, then type `.read shop_postgres.sql`.
3. Paste any query from the book. Where PostgreSQL and DuckDB differ, the book uses syntax that works in both.
4. Chapter 10 needs PostgreSQL, because it is about PostgreSQL plans and indexes. `big_tables.py` loads its two large tables there (`pip install numpy pandas psycopg2-binary`, then edit the connection settings in the `pg()` function).
5. With PostgreSQL instead: `psql -d yourdb -f shop_postgres.sql`.

## Online alternative

If you cannot install anything, any free online PostgreSQL playground will do: paste the contents of `shop_postgres.sql` first, then your query. The tables are small enough for every free tier.

## Found a mistake?

Every query was tested on PostgreSQL 16 and DuckDB, but a book is never free of errors. Please open an issue in this repository. Corrections go into these files first and into the next printing after that.

## License

The practice files are free to use, copy and change for learning, teaching and interviews.
