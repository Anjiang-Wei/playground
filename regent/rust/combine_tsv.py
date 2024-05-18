import pandas as pd
from glob import glob
import ast
from itertools import chain

# List all your TSV files
app = "blinks"
tsv_files = glob(f'{app}/tsv/*.tsv')
tsv_files = list(filter(lambda x: not "_util.tsv" in x, tsv_files))

# Initialize an empty list to store dataframes
dataframes = []

# Function to standardize column names
def standardize_columns(df):
    df.columns = df.columns.str.strip()  # Remove any leading/trailing whitespace
    return df

# Function to extract integers from the list format
def extract_integers(cell):
    if pd.isna(cell) or cell == '':
        return []
    try:
        cell_list = ast.literal_eval(cell)
        return [item[2] for item in cell_list]
    except (ValueError, SyntaxError):
        return []

# Function to compute the union of lists
def union_lists(series):
    return list(set(chain.from_iterable(series)))

# Function to find the maximum common substring
def max_common_substring(series):
    strings = series.dropna().unique()  # Remove NaN values and get unique strings
    if len(strings) == 0:
        return ''
    common_substr = strings[0]
    for s in strings[1:]:
        common_substr = ''.join(x[0] for x in zip(common_substr, s) if x[0] == x[1])
        if not common_substr:
            break
    return common_substr

# Function to check consistency and return a single value
def check_consistency(series):
    unique_values = series.dropna().unique()
    if len(unique_values) == 1:
        return unique_values[0]
    elif len(unique_values) == 0:
        return ''
    else:
        assert False, unique_values

# Loop through each file and read it into a dataframe
for file in tsv_files:
    df = pd.read_csv(file, sep='\t')
    df = standardize_columns(df)
    dataframes.append(df)

# Concatenate all dataframes, aligning columns
combined_df = pd.concat(dataframes, ignore_index=True, sort=False)

# Filter out rows where 'title' contains 'ProfTask' or 'Region'
combined_df = combined_df[~combined_df['title'].str.contains('ProfTask|Region:', na=False)]

# Filter to retain only the specified columns
columns_to_retain = ['prof_uid', 'op_id', 'title', 'ready', 'start', 'end', 'in', 'out', 'initiation']
combined_df = combined_df[columns_to_retain]

# Convert 'start', 'end', and 'ready' columns to numeric
combined_df['start'] = pd.to_numeric(combined_df['start'], errors='coerce')
combined_df['end'] = pd.to_numeric(combined_df['end'], errors='coerce')

# Initialize 'ready' column as empty if it doesn't exist
if 'ready' not in combined_df.columns:
    combined_df['ready'] = pd.NA
else:
    combined_df['ready'] = pd.to_numeric(combined_df['ready'], errors='coerce')

# Convert 'in' and 'out' columns to lists of integers
combined_df['in'] = combined_df['in'].apply(extract_integers)
combined_df['out'] = combined_df['out'].apply(extract_integers)

# Group by 'prof_uid' and aggregate
grouped = combined_df.groupby('prof_uid').agg({
    'op_id': check_consistency,  # Ensure op_id is consistent within the group
    'title': max_common_substring,  # Find maximum common substring of title
    'ready': 'min',
    'start': 'min',
    'end': 'max',
    'in': union_lists,
    'out': union_lists,
    'initiation': check_consistency  # Ensure initiation is consistent within the group
}).reset_index()

# Filter out groups where op_id or initiation values were not consistent
grouped = grouped.dropna(subset=['op_id', 'initiation'])

# Compute 'wait' and 'execution' columns
grouped['wait'] = grouped['start'] - grouped['ready']
grouped['execution'] = grouped['end'] - grouped['start']

# Convert 'in' and 'out' columns back to strings
grouped['in'] = grouped['in'].apply(lambda x: ', '.join(map(str, x)))
grouped['out'] = grouped['out'].apply(lambda x: ', '.join(map(str, x)))

# Reorder columns
final_columns = ['prof_uid', 'wait', 'execution', 'op_id', 'title', 'ready', 'start', 'end', 'in', 'out', 'initiation']
grouped = grouped[final_columns]

# Save the combined dataframe to a new TSV file
grouped.to_csv(f'{app}_combined.tsv', sep='\t', index=False)
