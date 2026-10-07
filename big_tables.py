"""Large tables for chapter 10. Deterministic, built with numpy, loaded into PostgreSQL with COPY."""
import io
import numpy as np
import pandas as pd
import psycopg2

N_CUST, N_ORD = 20000, 200000

def build():
    rng = np.random.default_rng(10)
    countries = np.array(["BR", "DE", "UK", "US", "FR", "PL", "ES", "IT"])
    cust = pd.DataFrame({
        "customer_id": np.arange(1, N_CUST + 1),
        "email": [f"User{i}@Mail.example" for i in range(1, N_CUST + 1)],
        "country": countries[rng.integers(0, len(countries), N_CUST)],
    })
    start = np.datetime64("2024-01-01T00:00")
    minutes = rng.integers(0, 366 * 24 * 60, N_ORD)
    created = start + minutes.astype("timedelta64[m]")
    status = np.where(rng.random(N_ORD) < 0.03, "pending", np.where(rng.random(N_ORD) < 0.1, "cancelled", "completed"))
    orders = pd.DataFrame({
        "order_id": np.arange(1, N_ORD + 1),
        "customer_id": rng.integers(1, N_CUST + 1, N_ORD),
        "created_at": pd.to_datetime(created),
        "status": status,
        "amount": rng.integers(5, 400, N_ORD),
    })
    orders["order_date"] = orders.created_at.dt.date
    return cust, orders

def pg():
    con = psycopg2.connect(host="localhost", dbname="shop", user="postgres", password="pg")
    con.autocommit = True
    return con

def load_pg(cust, orders):
    con = pg(); cur = con.cursor()
    cur.execute("DROP TABLE IF EXISTS big_orders; DROP TABLE IF EXISTS big_customers;")
    cur.execute("CREATE TABLE big_customers (customer_id INT, email TEXT, country TEXT)")
    cur.execute("CREATE TABLE big_orders (order_id INT, customer_id INT, created_at TIMESTAMP, status TEXT, amount INT, order_date DATE)")
    for name, df in (("big_customers", cust), ("big_orders", orders)):
        buf = io.StringIO(); df.to_csv(buf, index=False, header=False); buf.seek(0)
        cur.copy_expert(f"COPY {name} FROM STDIN WITH CSV", buf)
    cur.execute("ALTER TABLE big_customers ADD PRIMARY KEY (customer_id)")
    cur.execute("ALTER TABLE big_orders ADD PRIMARY KEY (order_id)")
    cur.execute("VACUUM ANALYZE big_customers")
    cur.execute("VACUUM ANALYZE big_orders")
    return con

def explain(con, sql, analyze=False):
    cur = con.cursor()
    opts = "ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF" if analyze else "COSTS OFF"
    cur.execute(f"EXPLAIN ({opts}) " + sql)
    return [r[0] for r in cur.fetchall()]

if __name__ == "__main__":
    c, o = build(); con = load_pg(c, o)
    print(explain(con, "SELECT count(*) FROM big_orders WHERE created_at >= '2024-06-01' AND created_at < '2024-06-02'"))
