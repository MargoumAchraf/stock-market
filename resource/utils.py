import os
from datetime import datetime

import pandas as pd


def load_data(directory_path="./sample-stocks/"):
    historical_data = {}

    file_list = [
        filename for filename in os.listdir(directory_path) if filename.endswith(".csv")
    ]
    for filename in file_list:
        symbol = filename.replace(".csv", "")
        file_path = os.path.join(directory_path, filename)
        historical_data[symbol] = pd.read_csv(file_path, parse_dates=[0])
    return historical_data


def get_historical_data(df, start, end, now=None):
    # "now" = wa9t dyal db3a, machi wa9t tlou3 dyal server
    now = now or datetime.now()
    today = now.date()
    last_entry = df.sort_values(by="Date").iloc[-1]
    delta_today_last_entry = today - last_entry.Date.date()

    query_start_dt = datetime.fromisoformat(start)
    query_end_dt = datetime.fromisoformat(end)
    if query_end_dt < query_start_dt:
        raise ValueError("end_date must come after start_date")
    if query_end_dt.date() > today:
        query_end_dt = now

    shifted = df.Date + delta_today_last_entry
    mask = (shifted >= query_start_dt) & (shifted <= query_end_dt)
    result = df.loc[mask].copy()
    result["datetime"] = shifted[mask]
    return result


if __name__ == "__main__":
    result = load_data()
    print(f"keys: {result.keys()}")
    df = result["AE"]
    print(df.info())