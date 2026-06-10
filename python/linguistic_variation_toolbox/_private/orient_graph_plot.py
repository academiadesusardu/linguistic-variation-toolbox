from __future__ import annotations
import numpy as np
import networkx as nx
import matplotlib.axes

from .rotate_graph_plot import rotate_graph_plot
from .center_graph_plot import center_graph_plot


def _is_category(attrs, category: str) -> bool:
    return any(a.category == category for a in attrs)


def _is_category_reference_of_category(attrs, category: str) -> bool:
    return any(a.category == category and a.is_category_reference for a in attrs)


def _compute_category_baricentre(
    nodes: list[str],
    node_data: dict,
    pos: dict[str, tuple[float, float]],
    category: str,
) -> np.ndarray | None:
    ref_nodes = [n for n in nodes if _is_category_reference_of_category(node_data[n]["Attributes"], category)]
    non_ref_category_nodes = [
        n for n in nodes
        if _is_category(node_data[n]["Attributes"], category)
        and not _is_category_reference_of_category(node_data[n]["Attributes"], category)
    ]
    if not non_ref_category_nodes:
        if ref_nodes:
            return np.array(pos[ref_nodes[0]])
        return None
    xs = [pos[n][0] for n in non_ref_category_nodes]
    ys = [pos[n][1] for n in non_ref_category_nodes]
    return np.array([np.mean(xs), np.mean(ys)])


def _find_reference_coords(
    nodes: list[str],
    node_data: dict,
    pos: dict[str, tuple[float, float]],
    category: str,
) -> np.ndarray | None:
    refs = [n for n in nodes if _is_category_reference_of_category(node_data[n]["Attributes"], category)]
    if len(refs) == 1:
        return np.array(pos[refs[0]])
    return None


def _x_width(ax: matplotlib.axes.Axes) -> float:
    xlim = ax.get_xlim()
    return xlim[1] - xlim[0]


def orient_graph_plot(
    ax: matplotlib.axes.Axes,
    graph: nx.Graph,
    pos: dict[str, tuple[float, float]],
    first_category: str,
    second_category: str,
) -> dict[str, tuple[float, float]]:
    """Orient the graph so the two category references are aligned horizontally."""
    nodes = list(graph.nodes)
    node_data = dict(graph.nodes(data=True))

    x_arr = np.array([pos[n][0] for n in nodes])
    y_arr = np.array([pos[n][1] for n in nodes])

    first_ref = _find_reference_coords(nodes, node_data, pos, first_category)
    second_ref = _find_reference_coords(nodes, node_data, pos, second_category)

    if first_ref is not None and second_ref is None:
        baricentre = _compute_category_baricentre(nodes, node_data, pos, first_category)
        diff = baricentre - first_ref
        theta = np.arctan2(diff[1], diff[0])
        angle = -theta + np.pi
        cx = first_ref[0] + _x_width(ax) / 4
        centre = (cx, first_ref[1])
    elif first_ref is None and second_ref is not None:
        baricentre = _compute_category_baricentre(nodes, node_data, pos, second_category)
        diff = baricentre - second_ref
        theta = np.arctan2(diff[1], diff[0])
        angle = -theta + 0
        cx = second_ref[0] - _x_width(ax) / 4
        centre = (cx, second_ref[1])
    elif first_ref is not None and second_ref is not None:
        diff = second_ref - first_ref
        theta = np.arctan2(diff[1], diff[0])
        angle = -theta
        mid = first_ref + diff / 2
        centre = (mid[0], mid[1])
    else:
        raise ValueError("Invalid specification of references in the plot")

    x_arr, y_arr = rotate_graph_plot(ax, x_arr, y_arr, angle)
    new_pos = {n: (x_arr[i], y_arr[i]) for i, n in enumerate(nodes)}
    center_graph_plot(ax, x_arr, y_arr, centre)
    return new_pos
