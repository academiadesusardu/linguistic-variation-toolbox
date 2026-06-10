from __future__ import annotations
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.axes


def plot_box_scatter(
    data: np.ndarray,
    group: np.ndarray,
    x_tick_labels: list[str],
) -> matplotlib.axes.Axes:
    """Boxplot with overlaid scatter (jitter). Matches MATLAB plotBoxScatter."""
    ax = plt.gca()
    num_groups = len(np.unique(group))
    box_width = 0.5
    rng = np.random.default_rng(0)

    for group_index in range(1, num_groups + 1):
        current_data = data[group == group_index]
        x_random = rng.random(current_data.shape) - box_width
        x_position = group_index + x_random / 4
        ax.scatter(
            x_position,
            current_data,
            c="red",
            alpha=0.1,
            edgecolors="none",
            marker="o",
        )

    positions = list(range(1, num_groups + 1))
    bp = ax.boxplot(
        [data[group == g] for g in range(1, num_groups + 1)],
        positions=positions,
        notch=False,
        widths=box_width,
        sym="",
        patch_artist=False,
    )
    for element in ["boxes", "whiskers", "fliers", "means", "medians", "caps"]:
        for line in bp.get(element, []):
            line.set_color("black")
            line.set_linestyle("-")

    ax.set_xticks(positions)
    ax.set_xticklabels(x_tick_labels)
    return ax
