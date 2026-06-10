from __future__ import annotations

_stored_categories: list[str] | None = None


def all_categories(categories: list[str] | None = None) -> list[str] | None:
    """Get or set the global list of linguistic categories.

    Call with no argument to get; call with a list to set.
    The list must have more than one element.
    """
    global _stored_categories
    if categories is None:
        assert _stored_categories is not None, (
            "You should first set the categories by calling 'all_categories' with an input"
        )
        return _stored_categories
    categories = list(categories)
    assert len(categories) > 1, (
        "Input should be a list of strings with more than one element."
    )
    _stored_categories = sorted(set(str(c) for c in categories))
    return None
