from __future__ import annotations
import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.cm as cm

from ..all_categories import all_categories
from .constants import (
    FORCE_PLACEMENT_ALGORITHM,
    MDS_PLACEMENT_ALGORITHM,
    PROXIMAL_PLOT_MODE,
)
from .place_variants_in_plot import place_variants_in_plot
from .orient_graph_plot import orient_graph_plot
from .compute_edges_weight_threshold import compute_edges_weight_threshold

_CATEGORY_MARKERS = ["o", "s", "*", "D", "x", "+", (6, 1, 0)]
_CATEGORY_COLORS = [
    "#4daf4a", "#e41a1c", "#377eb8", "#984ea3",
    "#ff7f00", "#ffff33", "#a65628",
]
_PENTAGRAM = (5, 1, 0)


def _get_category_index(category: str) -> int:
    cats = all_categories()
    return cats.index(category)


def _node_spec(graph: nx.Graph):
    """Return per-node (marker, color, size) lists."""
    nodes = list(graph.nodes)
    num_cats = len(all_categories())
    markers, colors, sizes = [], [], []
    for node in nodes:
        attrs = graph.nodes[node]["Attributes"]
        is_ref = graph.nodes[node]["IsCategoryReference"]
        if len(attrs) > 1:
            style_idx = num_cats  # wrap to end of palette
        else:
            style_idx = _get_category_index(attrs[0].category)
        style_idx = min(style_idx, len(_CATEGORY_MARKERS) - 1)
        colors.append(_CATEGORY_COLORS[min(style_idx, len(_CATEGORY_COLORS) - 1)])
        if is_ref:
            markers.append(_PENTAGRAM)
            sizes.append(6 ** 2)
        else:
            markers.append(_CATEGORY_MARKERS[style_idx])
            sizes.append(4 ** 2)
    return markers, colors, sizes


def _color_map(weights) -> np.ndarray:
    n = int(compute_edges_weight_threshold(weights)) if len(weights) else 0
    if n == 0:
        return np.empty((0, 3))
    cmap = cm.get_cmap("gray", n)
    return cmap(np.arange(n))[:, :3]


def _edge_color_and_width(weight: float, colormap: np.ndarray):
    if colormap is None or len(colormap) == 0:
        return None, 1.0
    max_colors = len(colormap)
    idx = max(1, min(int(weight), max_colors)) - 1
    color = colormap[idx]
    width = 1.0 if weight <= 1 else 0.25
    return color, width


def _colorbar_ticks(ax, num_colors: int):
    if num_colors == 0:
        return
    cb = plt.colorbar(
        cm.ScalarMappable(
            norm=mcolors.Normalize(vmin=0.5, vmax=num_colors + 0.5),
            cmap=cm.get_cmap("gray", num_colors),
        ),
        ax=ax,
        location="right",
    )
    ticks = np.linspace(1, num_colors, num_colors)
    cb.set_ticks(ticks)
    labels = [str(i) for i in range(1, num_colors + 1)]
    labels[-1] = f"≥{labels[-1]}"
    cb.set_ticklabels(labels)
    cb.set_label("Edge colour: distance between variants")


def plot_variants_graph(graph: nx.Graph, options: dict):
    """Draw the graph and return (fig, ax, pos)."""
    fig, ax = plt.subplots()
    ax.set_visible(False)
    ax.set_facecolor("none")

    nodes = list(graph.nodes)
    markers, colors, sizes = _node_spec(graph)

    edges = list(graph.edges)
    weights = np.array([
        max(graph.edges[u, v]["Weight"], 0.2)
        for u, v in edges
    ])

    colormap = _color_map(weights) if len(weights) else np.empty((0, 3))
    edge_colors, edge_widths = [], []
    for w in weights:
        c, wd = _edge_color_and_width(w, colormap)
        edge_colors.append(c if c is not None else "black")
        edge_widths.append(wd)

    placement = options.get("placement_algorithm", MDS_PLACEMENT_ALGORITHM)
    if placement == FORCE_PLACEMENT_ALGORITHM:
        # kamada_kawai uses edge weights as *ideal distances*, matching MATLAB's
        # force layout with WeightEffect='direct' (weight = spring natural length).
        pos = nx.kamada_kawai_layout(graph, weight="Weight")
    else:
        pos = nx.spring_layout(graph, weight="Weight", iterations=1, seed=0)

    if placement == MDS_PLACEMENT_ALGORITHM:
        pos = place_variants_in_plot(graph, pos)

    if "center_categories" in options:
        cat1, cat2 = options["center_categories"]
        pos = orient_graph_plot(ax, graph, pos, cat1, cat2)

    # Draw edges
    mode = options.get("mode", "complete")
    if mode == PROXIMAL_PLOT_MODE:
        proximal_edges = [(u, v) for u, v in edges if graph.edges[u, v].get("IsProximal", False)]
        non_proximal_edges = [(u, v) for u, v in edges if not graph.edges[u, v].get("IsProximal", False)]
        proximal_indices = [i for i, (u, v) in enumerate(edges) if graph.edges[u, v].get("IsProximal", False)]
        non_proximal_indices = [i for i, (u, v) in enumerate(edges) if not graph.edges[u, v].get("IsProximal", False)]
        if proximal_edges:
            nx.draw_networkx_edges(
                graph, pos, ax=ax, edgelist=proximal_edges,
                edge_color=[edge_colors[i] for i in proximal_indices],
                width=[edge_widths[i] for i in proximal_indices],
            )
        # non-proximal edges are invisible in proximal mode
    else:
        if edges:
            nx.draw_networkx_edges(
                graph, pos, ax=ax, edgelist=edges,
                edge_color=edge_colors,
                width=edge_widths,
            )

    # Draw nodes grouped by marker type
    by_marker: dict = {}
    for i, node in enumerate(nodes):
        key = (str(markers[i]), colors[i], sizes[i])
        by_marker.setdefault(key, []).append(node)

    for (marker, color, size), node_group in by_marker.items():
        xs = [pos[n][0] for n in node_group]
        ys = [pos[n][1] for n in node_group]
        ax.scatter(xs, ys, marker=eval(marker) if marker.startswith("(") else marker,
                   c=color, s=size, zorder=5)

    # Labels
    nx.draw_networkx_labels(graph, pos, ax=ax, font_weight="bold")

    if len(colormap) > 0:
        _colorbar_ticks(ax, len(colormap))

    ax.set_visible(True)
    return fig, ax, pos
