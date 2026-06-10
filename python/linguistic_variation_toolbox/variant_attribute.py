from __future__ import annotations
from ._private.validate_category import validate_category


class VariantAttribute:
    """Attribute for a given variant: its category and whether it is the reference."""

    def __init__(self, category: str, is_category_reference: bool) -> None:
        validate_category(category)
        self._category = str(category)
        self._is_category_reference = bool(is_category_reference)

    @property
    def category(self) -> str:
        return self._category

    @property
    def is_category_reference(self) -> bool:
        return self._is_category_reference

    def __repr__(self) -> str:
        return (
            f"VariantAttribute(category={self._category!r}, "
            f"is_category_reference={self._is_category_reference})"
        )
