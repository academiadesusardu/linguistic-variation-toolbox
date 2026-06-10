from __future__ import annotations
import numpy as np
import matplotlib.axes


def rotate_graph_plot(
    ax: matplotlib.axes.Axes,
    x_data: np.ndarray,
    y_data: np.ndarray,
    angle: float,
) -> tuple[np.ndarray, np.ndarray]:
    """Rotate node coordinates by `angle` (radians) around their centroid."""
    x_center = x_data.mean()
    y_center = y_data.mean()
    xc = x_data - x_center
    yc = y_data - y_center
    theta = np.arctan2(yc, xc)
    rho = np.hypot(xc, yc)
    new_theta = theta + angle
    new_x = rho * np.cos(new_theta) + x_center
    new_y = rho * np.sin(new_theta) + y_center
    return new_x, new_y
