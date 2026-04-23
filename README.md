# ⛽ Fuel Station Fraud Analytics Dashboard

> End-to-end fraud detection pipeline — identified **27.5% fraud rate** & **16,200L under-dispensing** across 50 fuel stations using Python, PostgreSQL & Power BI

---

## 📌 Overview

Fuel stations across India lose significant revenue due to **sensor-based fraud** — where pumps dispense less fuel than what customers pay for. This project builds a complete analytics pipeline to:

- Detect fraud patterns using transaction & sensor data
- Understand how fraud impacts customer retention
- Identify high-risk stations and cities
- Validate 3 business hypotheses through data

---

## 🖥️ Dashboard Preview

### Page 1 — Overview
![Overview Dashboard](images/overview.png)

### Page 2 — Fraud & Stations Deep Dive
![Fraud Deep Dive Dashboard](images/deep_dive.png)

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| Python (Pandas, NumPy, Matplotlib) | Data simulation & EDA |
| PostgreSQL | Data storage & SQL analysis |
| Power BI + DAX | Interactive dashboard |

---

## 📂 Project Structure

```
fuel-analytics-fraud-detection/
│
├── data/                         # Raw datasets
│   ├── transactions.csv          # 1,00,000 transactions
│   ├── customers.csv             # 5,000 customers
│   ├── stations.csv              # 50 fuel stations
│   └── sensor_data.csv           # Sensor readings
│
├── notebooks/
│   └── fuel_station_analytics.ipynb   # Full pipeline notebook
│
├── sql/
│   └── fuel_station_analysis_queries.sql  # 10+ analysis queries
│
├── dashboard/
│   └── fuel_dashboard.pbix       # Power BI dashboard file
│
├── images/                       # Dashboard screenshots
│   ├── overview.png
│   └── deep_dive.png
│
├── requirements.txt
└── README.md
```

---

## 📊 Dataset

| Table | Rows | Description |
|-------|------|-------------|
| transactions | 1,00,000 | Fuel transactions with fraud flags |
| customers | 5,000 | Customer type & signup info |
| stations | 50 | Station details across 3 cities |
| sensor_data | 1,00,000 | Expected vs actual fuel dispensed |

**Cities covered:** Delhi • Mumbai • Bangalore

> 📝 All data is synthetically simulated using Python with realistic distributions and fraud patterns.

---

## 🔬 Hypotheses Tested

| # | Hypothesis | Result |
|---|-----------|--------|
| H1 | Fraud transactions reduce customer repeat visits | ✅ Proved — Fraud: 18% vs Clean: 36% repeat rate |
| H2 | Higher wait time leads to lower customer retention | ✅ Proved — Low: 34% → Medium: 33% → High: 30% |
| H3 | Frequent customers have higher repeat rate | ✅ Proved — Frequent: 48% vs Occasional: 24% |

---

## 🔍 Key Findings

- 🔴 **Delhi** has the highest fraud rate at **51.2%** — double that of Mumbai (16.2%)
- 🚨 **9 stations** identified with **96%+ fraud rate**
- ⛽ **16,200 liters** of fuel physically under-dispensed across flagged transactions
- 📉 Fraud transactions lead to **50% lower repeat visits** (18% vs 36%)
- ⏱️ Peak hours (8–11 AM, 5–8 PM) show highest wait times and lowest retention

---

## ⚙️ How to Run

**1. Clone the repo**
```bash
git clone https://github.com/aditya-datahub/fuel-analytics-fraud-detection.git
cd fuel-analytics-fraud-detection
```

**2. Install dependencies**
```bash
pip install -r requirements.txt
```

**3. Run the notebook**
```bash
jupyter notebook notebooks/fuel_station_analytics.ipynb
```

> Running the notebook will automatically generate processed files:
> `sensor_fraud_mixed.csv`, `sensor_fraud_all.csv`, `stations_summary.csv`

**4. Open Power BI Dashboard**

Open `dashboard/fuel_dashboard.pbix` in Power BI Desktop.

---

## 📈 Dashboard Highlights

**Page 1 — Overview**
- 6 KPI cards (Revenue, Fraud Rate, Repeat Rate, Wait Time, etc.)
- Fraud Rate by City (horizontal bar)
- Fraud & Repeat Rate by Customer Type
- Repeat Rate by Fraud Flag (donut)
- Wait Time & Repeat Rate by Hour (dual-axis line)
- Revenue by Customer Type (donut)

**Page 2 — Fraud & Stations Deep Dive**
- 6 KPIs (Total Under-Dispensed, Max Gap, High Risk Stations, etc.)
- Sensor-Detected Under-Dispensing table (top 50 transactions)
- Top Stations by Fraud Rate & Revenue Loss
- Under-Dispensing by City (bar chart)

---

## 📋 Requirements

```
pandas
numpy
matplotlib
psycopg2-binary
```

---

## 👤 Author

**Aditya Sharma**
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://linkedin.com/in/your-profile)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black)](https://github.com/aditya-datahub)

---

## 📄 License

This project is licensed under the MIT License.
