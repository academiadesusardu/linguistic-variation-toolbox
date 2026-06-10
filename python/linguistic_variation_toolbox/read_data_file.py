from __future__ import annotations
import json
from pathlib import Path

from .variant_attribute import VariantAttribute
from .set_of_variants import SetOfVariants


def read_data_file(input_file: str | Path) -> SetOfVariants:
    """Read an example JSON data file and return a SetOfVariants."""
    with open(input_file, encoding="utf-8") as f:
        content = json.load(f)

    if isinstance(content, dict):
        return _struct_to_set_of_variants(content)
    return _struct_to_set_of_variants(content)


def _struct_to_set_of_variants(data) -> SetOfVariants:
    if isinstance(data, dict):
        records = [data]
    else:
        records = data

    if records and "Attributes" in records[0]:
        variants = [r["Variant"] for r in records]
        attributes = [_parse_attributes(r["Attributes"]) for r in records]
        return SetOfVariants(variants, attributes)
    else:
        variants = [r["Variant"] for r in records]
        categories = [[str(c) for c in r["Categories"]] for r in records]
        is_ref = [bool(r["IsCategoryReference"]) for r in records]
        return SetOfVariants(variants, categories, is_ref)


def _parse_attributes(attr_data) -> list[VariantAttribute]:
    if isinstance(attr_data, dict):
        attr_data = [attr_data]
    return [
        VariantAttribute(str(a["Category"]), bool(a["IsCategoryReference"]))
        for a in attr_data
    ]
