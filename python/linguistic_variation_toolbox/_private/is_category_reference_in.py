import networkx as nx


def is_category_reference_in(graph: nx.Graph, category: str) -> list[bool]:
    """Return a boolean list: True if node i is the category reference for `category`."""
    result = []
    for node in graph.nodes:
        attrs = graph.nodes[node]["Attributes"]
        ref = any(
            a.category == category and a.is_category_reference for a in attrs
        )
        result.append(ref)
    return result
