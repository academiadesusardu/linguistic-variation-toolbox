import numpy as np


def compute_edges_weight_threshold(weights) -> float:
    return float(np.median(weights))
