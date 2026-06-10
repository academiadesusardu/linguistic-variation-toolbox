from __future__ import annotations
from typing import Callable
import numpy as np
import networkx as nx
import pandas as pd

from .all_categories import all_categories
from ._private.simple_levenshtein import simple_levenshtein
from ._private.validate_category import validate_category
from ._private.is_category_reference_in import is_category_reference_in
from ._private.compute_category_statistics import compute_category_statistics
from ._private.print_statistics import print_statistics
from ._private.constants import (
    COMPLETE_PLOT_MODE,
    PROXIMAL_PLOT_MODE,
    FORCE_PLACEMENT_ALGORITHM,
    MDS_PLACEMENT_ALGORITHM,
)
from ._private.plot_box_scatter import plot_box_scatter


class SetOfVariants:
    """A set of variants of the same word."""

    def __init__(
        self,
        variants: list[str],
        categories_or_attributes,
        is_category_reference: list[bool] | None = None,
        *,
        distance_function: Callable[[str, str], int] = simple_levenshtein,
    ) -> None:
        variants = [str(v) for v in variants]
        assert len(set(variants)) == len(variants), (
            "The elements in the variant array are not unique."
        )

        if is_category_reference is None:
            is_category_reference = [False] * len(variants)

        attributes = _compute_attributes(categories_or_attributes, is_category_reference)
        is_ref_flags = [any(a.is_category_reference for a in attrs) for attrs in attributes]

        self._distance_function = distance_function
        self._graph = _build_graph(variants, attributes, is_ref_flags, distance_function)
        self._digraph = _graph_to_digraph(self._graph)
        _mark_proximal_nodes(self._digraph)
        self._check_category_references()

    @property
    def distance_function(self) -> Callable:
        return self._distance_function

    @property
    def variant_table(self) -> pd.DataFrame:
        rows = []
        for node in self._graph.nodes:
            d = self._graph.nodes[node]
            rows.append({
                "Variant": node,
                "Attributes": d["Attributes"],
                "IsCategoryReference": d["IsCategoryReference"],
            })
        return pd.DataFrame(rows)

    @property
    def distance_table(self) -> pd.DataFrame:
        rows = []
        for u, v, data in self._digraph.edges(data=True):
            rows.append({
                "FromVariant": u,
                "ToVariant": v,
                "Weight": data["Weight"],
                "IsProximal": data.get("IsProximal", False),
            })
        return pd.DataFrame(rows)

    def get_number_of_variants(self) -> int:
        return self._graph.number_of_nodes()

    def get_all_variants(self) -> list[str]:
        return list(self._graph.nodes)

    def get_categories_of(self, variant: str) -> list[str]:
        assert variant in self._graph.nodes, "The variant is not in the set."
        attrs = self._graph.nodes[variant]["Attributes"]
        return [a.category for a in attrs]

    def get_variants_in(self, category: str) -> list[str]:
        validate_category(category)
        return [
            n for n in self._graph.nodes
            if category in [a.category for a in self._graph.nodes[n]["Attributes"]]
        ]

    def is_category_reference(self, variant: str) -> bool:
        assert variant in self._graph.nodes, "The variant is not in the set."
        return self._graph.nodes[variant]["IsCategoryReference"]

    def get_category_reference_in(self, category: str) -> list[str]:
        validate_category(category)
        flags = is_category_reference_in(self._graph, category)
        nodes = list(self._graph.nodes)
        return [nodes[i] for i, flag in enumerate(flags) if flag]

    def get_distance_between(
        self, first_variants: list[str], second_variants: list[str]
    ) -> np.ndarray:
        distances = []
        for v1 in first_variants:
            for v2 in second_variants:
                if self._graph.has_edge(v1, v2):
                    distances.append(self._graph.edges[v1, v2]["Weight"])
                elif self._graph.has_edge(v2, v1):
                    distances.append(self._graph.edges[v2, v1]["Weight"])
        return np.array(distances)

    def plot(
        self,
        mode: str = COMPLETE_PLOT_MODE,
        placement_algorithm: str = MDS_PLACEMENT_ALGORITHM,
        center_categories: tuple[str, str] | None = None,
    ):
        """Visualize the variants as a graph. Returns (fig, ax, pos)."""
        _check_option(mode, [COMPLETE_PLOT_MODE, PROXIMAL_PLOT_MODE], "Allowed plot modes are: ")
        _check_option(
            placement_algorithm,
            [FORCE_PLACEMENT_ALGORITHM, MDS_PLACEMENT_ALGORITHM],
            "Allowed placement algorithms are: ",
        )
        from ._private.plot_variants_graph import plot_variants_graph

        if mode == PROXIMAL_PLOT_MODE:
            input_graph = self._digraph
        else:
            input_graph = self._graph

        options = {"mode": mode, "placement_algorithm": placement_algorithm}
        if center_categories is not None:
            options["center_categories"] = center_categories

        return plot_variants_graph(input_graph, options)

    def plot_distances(self, *categories):
        """Boxplot of distances within/between category groups."""
        num_plots = len(categories)
        all_data = []
        all_groups = []
        labels = []

        for k, cats in enumerate(categories, start=1):
            if isinstance(cats, str):
                cats = [cats]
            unique_cats = list(dict.fromkeys(cats))
            num_cats = len(unique_cats)

            if num_cats == 0:
                label = "All"
                data = np.array([d["Weight"] for _, _, d in self._graph.edges(data=True)])
            elif num_cats == 1:
                label = unique_cats[0]
                unique_cats = [unique_cats[0], unique_cats[0]]
                num_cats = 2
                data = self.get_distance_between(
                    self.get_variants_in(unique_cats[0]),
                    self.get_variants_in(unique_cats[0]),
                )
            else:
                label = ", ".join(unique_cats)
                data = np.empty(0)
                for i in range(num_cats - 1):
                    for j in range(i + 1, num_cats):
                        d = self.get_distance_between(
                            self.get_variants_in(unique_cats[i]),
                            self.get_variants_in(unique_cats[j]),
                        )
                        data = np.concatenate([data, d])

            all_data.append(data)
            all_groups.append(np.full(len(data), k, dtype=int))
            labels.append(label)

        combined_data = np.concatenate(all_data)
        combined_groups = np.concatenate(all_groups)
        return plot_box_scatter(combined_data, combined_groups, labels)

    def compute_statistics(self, quiet: bool = False) -> dict:
        """Compute statistics and optionally print them."""
        cats = all_categories()
        stats = {}
        stats["WholeGraph"] = compute_category_statistics(self._graph, None)
        for cat in cats:
            stats[f"Category{cat}"] = compute_category_statistics(self._graph, cat)
        if not quiet:
            print_statistics(stats, 0)
        return stats

    def _check_category_references(self) -> None:
        for cat in all_categories():
            refs = self.get_category_reference_in(cat)
            assert len(refs) <= 1, "There can be only one reference per category"


def _check_option(value: str, allowed: list[str], base_msg: str) -> None:
    assert value in allowed, base_msg + ", ".join(allowed)


def _compute_attributes(categories_or_attributes, is_category_reference: list[bool]):
    from .variant_attribute import VariantAttribute

    result = []
    for k, element in enumerate(categories_or_attributes):
        if isinstance(element, (str,)):
            element = [element]
        if not element:
            result.append([])
            continue
        first = element[0] if not isinstance(element, list) else element[0]
        if isinstance(first, VariantAttribute):
            result.append(list(element))
        else:
            attrs = []
            for cat in element:
                attrs.append(VariantAttribute(str(cat), bool(is_category_reference[k])))
            result.append(attrs)
    return result


def _build_graph(
    variants: list[str],
    attributes,
    is_ref_flags: list[bool],
    distance_function: Callable,
) -> nx.Graph:
    G = nx.Graph()
    for i, v in enumerate(variants):
        G.add_node(v, Attributes=attributes[i], IsCategoryReference=is_ref_flags[i])

    for i in range(len(variants)):
        for j in range(i + 1, len(variants)):
            w = distance_function(variants[i], variants[j])
            G.add_edge(variants[i], variants[j], Weight=w)
    return G


def _graph_to_digraph(graph: nx.Graph) -> nx.DiGraph:
    DG = nx.DiGraph()
    for node, data in graph.nodes(data=True):
        DG.add_node(node, **data)
    for u, v, data in graph.edges(data=True):
        DG.add_edge(u, v, **data)
        DG.add_edge(v, u, **data)
    return DG


def _mark_proximal_nodes(digraph: nx.DiGraph) -> None:
    nx.set_edge_attributes(digraph, False, "IsProximal")
    for node in digraph.nodes:
        out_edges = list(digraph.out_edges(node, data=True))
        if not out_edges:
            continue
        min_w = min(d["Weight"] for _, _, d in out_edges)
        for u, v, data in out_edges:
            if data["Weight"] == min_w:
                digraph.edges[u, v]["IsProximal"] = True
