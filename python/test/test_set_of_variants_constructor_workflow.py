"""Workflow tests for SetOfVariants — mirrors TestSetOfVariantsConstructorWorkflow.m"""
import matplotlib
matplotlib.use("Agg")

import numpy as np
import pytest
from pathlib import Path

from linguistic_variation_toolbox import all_categories, read_data_file, SetOfVariants
import matplotlib.pyplot as plt

DATA_DIR = Path(__file__).parent.parent.parent / "data"


@pytest.fixture(autouse=True)
def set_categories():
    all_categories(["L", "C"])


def test_force_layout_respects_weights():
    # Variants with very different pairwise Levenshtein distances:
    #   "a"  <-> "ab"       = 1  (one insertion)
    #   "a"  <-> "abcdefgh" = 7  (seven insertions)
    #   "ab" <-> "abcdefgh" = 6
    # The force layout must place closer variants nearer in 2D.
    # The original bug (spring_layout) used weights as spring *constants*, pulling
    # high-distance pairs *closer* together — the opposite of correct behaviour.
    variants = ["a", "ab", "abcdefgh"]
    categories = [["C"], ["C"], ["L"]]
    is_ref = [True, False, True]
    s = SetOfVariants(variants, categories, is_ref)

    fig, ax, pos = s.plot(placement_algorithm="force")
    plt.close(fig)

    def dist2d(u, v):
        return np.hypot(pos[u][0] - pos[v][0], pos[u][1] - pos[v][1])

    assert dist2d("a", "ab") < dist2d("a", "abcdefgh"), (
        "Force layout must place 'a'↔'ab' (distance 1) closer than 'a'↔'abcdefgh' (distance 7)"
    )


@pytest.mark.parametrize("data_file", [
    DATA_DIR / "ochisorzu.json",
    DATA_DIR / "gennàrgiu.json",
    DATA_DIR / "bentùrgiu.json",
    DATA_DIR / "simple.json",
], ids=["Ochisorzu", "Gennargiu", "Benturgiu", "Simple"])
def test_creation_successful(data_file):
    read_data_file(data_file)
