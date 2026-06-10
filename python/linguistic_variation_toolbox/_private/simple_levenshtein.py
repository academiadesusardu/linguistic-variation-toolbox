from .levenshtein_core import levenshtein_core

_REPLACEMENT_TABLE = [
    ("àá", "a"),
    ("èé", "e"),
    ("ìíï", "i"),
    ("òó", "o"),
    ("ùú", "u"),
    ("ÀÁ", "A"),
    ("ÈÉ", "E"),
    ("ÌÍ", "I"),
    ("ÒÓ", "O"),
    ("ÙÚ", "U"),
    ("-", ""),
]


def _replace_diacritics(s: str) -> str:
    for chars, replacement in _REPLACEMENT_TABLE:
        for ch in chars:
            s = s.replace(ch, replacement)
    return s


def simple_levenshtein(first: str, second: str) -> int:
    return levenshtein_core(_replace_diacritics(first), _replace_diacritics(second))
