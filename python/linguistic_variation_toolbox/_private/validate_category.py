from ..all_categories import all_categories


def validate_category(category: str) -> None:
    assert category in all_categories(), (
        "The input category is not among those defined in 'all_categories'."
    )
