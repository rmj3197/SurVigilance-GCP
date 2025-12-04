import pandas as pd
import glob
import re
import datetime


def get_datetime_from_filename(filename):
    match = re.search(r"report-(\d{8})-(\d{2})-(\d{2})", filename)

    if match:
        date_part = match.group(1)
        hour_part = match.group(2)
        min_part = match.group(3)

        dt_string = f"{date_part} {hour_part}:{min_part}"

        return datetime.datetime.strptime(dt_string, "%Y%m%d %H:%M")
    return None


REGIONS = [
    "asia-east2",
    "europe-west8",
    "southamerica-east1",
    "us-central1",
    "africa-south1",
]

all_dataframes = []

for region in REGIONS:
    pattern = f"Data Files/report-*-{region}*.xlsx"
    files = glob.glob(pattern)

    print(f"Region: {region}. Found {len(files)} files")

    for file in files:
        df = pd.read_excel(file)
        df["region"] = region
        dt = get_datetime_from_filename(file)
        if dt:
            df["datetime"] = dt
            df["date"] = dt.date()
            df["time"] = dt.time()
        all_dataframes.append(df)

combined_dataframes = pd.concat(all_dataframes).reset_index(drop = True)[['full_test_name','region','date','time','result']].dropna()

def summarize_tests(group):
    failed_tests = group[group["result"] == "FAILED"]
    if failed_tests.empty:
        return ""
    else:
        failed_test_names = failed_tests["full_test_name"].unique()
        return "\n".join(failed_test_names)


summary = (
    combined_dataframes.groupby(["time", "region"])
    .apply(summarize_tests)
    .sort_index()
)

result_table = summary.unstack(level="region")
result_table = result_table.fillna("")
result_table.to_excel("result_table.xlsx")

