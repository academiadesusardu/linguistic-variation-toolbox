def levenshtein_core(s: str, t: str) -> int:
    """Levenshtein edit distance between two strings."""
    m, n = len(s), len(t)
    x = list(range(n + 1))
    y = [0] * (n + 1)
    for i in range(m):
        y[0] = i + 1
        for j in range(n):
            c = 0 if s[i] == t[j] else 1
            y[j + 1] = min(y[j] + 1, x[j + 1] + 1, x[j] + c)
        x, y = y, x
    return x[n]
