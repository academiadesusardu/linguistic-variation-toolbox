from __future__ import annotations
import numpy as np
import networkx as nx


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


def _print_error(D: np.ndarray, scaled: np.ndarray) -> None:
    n = D.shape[0]
    lower_idx = np.tril_indices(n, k=-1)
    d_lower = D[lower_idx]
    from scipy.spatial.distance import pdist
    reconstructed = pdist(scaled)
    max_rel_err = np.max(np.abs(d_lower - reconstructed)) / np.max(d_lower)
    print(
        f"The max relative error due to selecting the first 2 components of "
        f"multi-dimensional scaling is: {max_rel_err * 100:.4f}%."
    )


def place_variants_in_plot(
    graph: nx.Graph,
    pos: dict[str, tuple[float, float]],
) -> dict[str, tuple[float, float]]:
    """Replace force-layout positions with MDS positions. Returns updated pos dict."""
    nodes = list(graph.nodes)
    num_nodes = len(nodes)
    if num_nodes == 1:
        return pos

    D = nx.to_numpy_array(graph, nodelist=nodes, weight="Weight")
    if np.all(np.tril(D, k=-1) == 0):
        D = D + D.T

    coords = _cmdscale(D)
    if coords.shape[1] >= 2:
        _print_error(D, coords[:, :2])
        return {node: (coords[i, 0], coords[i, 1]) for i, node in enumerate(nodes)}
    else:
        print("Falling back to the 'force' layout algorithm.")
        return pos
