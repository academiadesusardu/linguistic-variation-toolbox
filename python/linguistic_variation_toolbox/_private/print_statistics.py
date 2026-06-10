from __future__ import annotations
import math
import pandas as pd

_MAX_TABLE_ROWS = 20


def _pad(level: int) -> str:
    return "  " * level


def _format_value(v) -> str:
    if isinstance(v, float) and math.isnan(v):
        return "Invalid data"
    return str(v)


def _print_table(df: pd.DataFrame, level: int) -> None:
    if "Attributes" in df.columns:
        df = df.drop(columns=["Attributes"])
    truncated = len(df) > _MAX_TABLE_ROWS
    display_df = df.iloc[:_MAX_TABLE_ROWS] if truncated else df
    lines = display_df.to_string(index=False).splitlines()
    prefix = _pad(level)
    for line in lines:
        print(prefix + line)
    if truncated:
        print(prefix + "...")
        print(prefix + "Table is too long to display here. Only the first lines are shown.")


def print_statistics(stats: dict, indentation_level: int) -> None:
    field_names = list(stats.keys())
    if not field_names:
        return
    width = max(len(k) for k in field_names) + 2
    pad = _pad(indentation_level)

    for key in field_names:
        value = stats[key]
        label = f"{key:{width}}"
        if isinstance(value, dict):
            print(f"{pad}{label}:")
            print_statistics(value, indentation_level + 1)
        elif isinstance(value, pd.DataFrame):
            print(f"{pad}{label}:")
            _print_table(value, indentation_level + 1)
        else:
            print(f"{pad}{label}:  {_format_value(value)}")
