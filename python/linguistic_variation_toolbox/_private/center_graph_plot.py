from __future__ import annotations
import numpy as np
import matplotlib.axes


def center_graph_plot(
    ax: matplotlib.axes.Axes,
    x_data: np.ndarray,
    y_data: np.ndarray,
    center: tuple[float, float],
) -> None:
    """Set axis limits centered on `center` with 1.4x padding."""
    cx, cy = center
    max_x_diff = np.max(np.abs(x_data - cx))
    max_y_diff = np.max(np.abs(y_data - cy))
    final_x = max_x_diff * 1.4
    final_y = max_y_diff * 1.4
    if final_y > 0:
        ax.set_ylim(cy - final_y, cy + final_y)
    if final_x > 0:
        ax.set_xlim(cx - final_x, cx + final_x)
