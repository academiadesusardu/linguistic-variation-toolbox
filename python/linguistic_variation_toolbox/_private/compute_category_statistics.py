from __future__ import annotations

import math
import numpy as np
import networkx as nx
import pandas as pd

from .is_category_reference_in import is_category_reference_in


def _cmdscale(D: np.ndarray) -> np.ndarray:
    """Classical metric MDS matching MATLAB's cmdscale()."""
    n = D.shape[0]
    J = np.eye(n) - np.ones((n, n)) / n
    B = -0.5 * J @ (D ** 2) @ J
    eigenvalues, eigenvectors = np.linalg.eigh(B)
    idx = np.argsort(eigenvalues)[::-1]
    eigenvalues = eigenvalues[idx]
    eigenvectors = eigenvectors[:, idx]
    pos = eigenvalues > 1e-10
    return eigenvectors[:, pos] * np.sqrt(eigenvalues[pos])


def _compute_distance_from_baricentre(subgraph: nx.Graph) -> list[float]:
    num_nodes = subgraph.number_of_nodes()
    if num_nodes <= 1:
        return [0.0] * num_nodes
    D = nx.to_numpy_array(subgraph, weight="Weight")
    coords = _cmdscale(D)
    baricentre = coords.mean(axis=0)
    centered = coords - baricentre
    return list(np.linalg.norm(centered, axis=1))


def _compute_weight_range(subgraph: nx.Graph) -> list[float]:
    nodes = list(subgraph.nodes)
    num_nodes = len(nodes)
    if num_nodes <= 1:
        return [float("nan")] * num_nodes
    result = []
    for node in nodes:
        weights = [d["Weight"] for _, _, d in subgraph.edges(node, data=True)]
        if not weights:
            result.append(float("nan"))
        else:
            result.append(max(weights) - min(weights))
    return result


def _compute_variant_stats(subgraph: nx.Graph) -> pd.DataFrame:
    nodes = list(subgraph.nodes)
    weights_arr = [d["Weight"] for _, _, d in subgraph.edges(data=True)]
    max_w = max(weights_arr) if weights_arr else 1.0
    inverse_weights = {(u, v): max_w - d["Weight"] + 1 for u, v, d in subgraph.edges(data=True)}

    nx.set_edge_attributes(subgraph, inverse_weights, "cost")

    num_variants = len(nodes)
    weighted_degree = []
    for node in nodes:
        wd = sum(d["Weight"] for _, _, d in subgraph.edges(node, data=True))
        weighted_degree.append(wd)

    mean_distance = [wd / (num_variants - 1) if num_variants > 1 else float("nan")
                     for wd in weighted_degree]

    range_distance = _compute_weight_range(subgraph)
    distance_from_baricentre = _compute_distance_from_baricentre(subgraph)

    closeness_raw = nx.closeness_centrality(subgraph, distance="cost")
    closeness = [closeness_raw[n] for n in nodes]

    attrs = [subgraph.nodes[n]["Attributes"] for n in nodes]
    is_ref = [subgraph.nodes[n]["IsCategoryReference"] for n in nodes]

    df = pd.DataFrame({
        "Name": nodes,
        "Attributes": attrs,
        "IsCategoryReference": is_ref,
        "WeightedDegree": weighted_degree,
        "MeanDistance": mean_distance,
        "RangeDistance": range_distance,
        "Closeness": closeness,
        "DistanceFromBaricentre": distance_from_baricentre,
    })
    return df.sort_values("WeightedDegree", ascending=True).reset_index(drop=True)


def _compute_general_stats(subgraph: nx.Graph, distance_from_baricentre: list[float]) -> dict:
    distances = [d["Weight"] for _, _, d in subgraph.edges(data=True)]
    stats: dict = {}
    if not distances:
        stats["Diameter"] = 0
        stats["MeanDistance"] = float("nan")
        stats["RangeDistance"] = float("nan")
        stats["MeanDistanceFromBaricentre"] = 0.0
    else:
        stats["Diameter"] = max(distances)
        stats["MeanDistance"] = float(np.mean(distances))
        stats["RangeDistance"] = max(distances) - min(distances)
        stats["MeanDistanceFromBaricentre"] = float(np.mean(distance_from_baricentre))
    stats["NumVariants"] = subgraph.number_of_nodes()
    return stats


def compute_category_statistics(graph: nx.Graph, category: str | None) -> dict:
    """Compute statistics for all variants in a category (or the whole graph if category is None)."""
    if category is not None:
        category_nodes = [
            n for n in graph.nodes
            if any(a.category == category for a in graph.nodes[n]["Attributes"])
        ]
        if not category_nodes:
            return {}
        subgraph = graph.subgraph(category_nodes).copy()
        ref_flags = is_category_reference_in(subgraph, category)
        for node, flag in zip(list(subgraph.nodes), ref_flags):
            subgraph.nodes[node]["IsCategoryReference"] = flag
    else:
        subgraph = graph

    if subgraph.number_of_nodes() == 0:
        return {}

    variant_data = _compute_variant_stats(subgraph)
    stats = _compute_general_stats(subgraph, list(variant_data["DistanceFromBaricentre"]))
    stats["VariantData"] = variant_data
    return stats
