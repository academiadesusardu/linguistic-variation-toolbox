<p align="center">
    <img src="https://i.ibb.co/SP6bNc2/Logo-Acad-mia-de-su-Sardu-piticu.png" alt="Logo-Acad-mia-de-su-Sardu-piticu" width="120px" border="0">
</p>

# Linguistic Variation Toolbox [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=academiadesusardu/linguistic-variation-toolbox&project=LinguisticVariationToolbox.prj) ![MATLAB tests](https://github.com/academiadesusardu/linguistic-variation-toolbox/actions/workflows/matlab.yml/badge.svg) ![Python tests](https://github.com/academiadesusardu/linguistic-variation-toolbox/actions/workflows/python.yml/badge.svg)

The Linguistic Variation Toolbox (LVT) is a software for the study and characterization
of linguistic variation through a mathematical and computational approach. It was developed
by [Acadèmia de su Sardu APS](https://www.academiadesusardu.org/) and released with an
Open Source Apache 2.0 license.

LVT is available in two implementations that expose identical functionality:

| | Python | MATLAB |
|---|---|---|
| Source | `python/` | `matlab/` |
| Requires | Python ≥ 3.11 | MATLAB R2022b + Statistics and Machine Learning Toolbox |

---

## Installation

### Python

```bash
pip install -e "python/"
```

### MATLAB

[You can use this software for free on MATLAB Online](https://matlab.mathworks.com/open/github/v1?repo=academiadesusardu/linguistic-variation-toolbox&project=LinguisticVariationToolbox.prj).
You might need to create a free MathWorks account. Once the project is open, add the
source folder to the path:

```matlab
addpath("matlab/source");
```

Alternatively, install the toolbox through MATLAB's
[Add-On Explorer](https://www.mathworks.com/products/matlab/add-on-explorer.html), or
clone this repository and run `addpath("matlab/source")` from your own installation.

---

## Usage guide

### Defining categories

The first step is to define the categories in your data. For example, for Sardinian we can
model _Campidanese_ as `"C"` and _Logudorese-Nugorese_ as `"L"`:

**Python**
```python
from linguistic_variation_toolbox import all_categories
all_categories(["C", "L"])
```

**MATLAB**
```matlab
allCategories(["C", "L"]);
```

The categories can be any number of strings. To retrieve the current list:

**Python** — `all_categories()`  
**MATLAB** — `allCategories()`

### Defining a set of variants

LVT studies the properties of sets of _variants_ and the patterns within them, through the
`SetOfVariants` object.

From a linguistics point of view you need:
* a set of _transcription rules_ to represent the variants as strings (phonetic or
  orthographic).
* a way of measuring the _distance_ between two transcribed variants.

LVT's default distance is the
[Levenshtein distance](https://blogs.mathworks.com/cleve/2017/08/14/levenshtein-edit-distance-between-strings/)
with diacritics stripped before comparison, so _arrèxini_ and _arrexìni_ are treated as
identical. The distance between _cat_ and _catfish_, for instance, is 4.

One way to create a `SetOfVariants` is to list the variants, the categories they belong to,
and whether each variant is a category reference (e.g. the standard form):

**Python**
```python
from linguistic_variation_toolbox import SetOfVariants

variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"]
categories = [["C"], ["L"], ["L"]]
is_category_reference = [True, False, True]
s = SetOfVariants(variants, categories, is_category_reference)
```

**MATLAB**
```matlab
variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"];
categories = {"C", "L", "L"};
isCategoryReference = [true, false, true];
set = SetOfVariants(variants, categories, isCategoryReference);
```

For more complex cases where a variant belongs to multiple categories, use
`VariantAttribute` objects:

**Python**
```python
from linguistic_variation_toolbox import VariantAttribute

attributes = [
    [VariantAttribute("C", True)],
    [VariantAttribute("L", False)],
    [VariantAttribute("L", True)],
]
s = SetOfVariants(variants, attributes)
```

**MATLAB**
```matlab
attributes = { ...
    VariantAttribute("C", true), ...
    VariantAttribute("L", false), ...
    VariantAttribute("L", true)};
set = SetOfVariants(variants, attributes);
```

To specify a custom distance function:

**Python** — `SetOfVariants(variants, categories, distance_function=my_func)`  
**MATLAB** — `SetOfVariants(variants, categories, DistanceFunction=@myFunc)`

Once the object is created, inspect it through its properties:

**Python** — `s.variant_table`, `s.distance_table`, `s.distance_function`  
**MATLAB** — `set.VariantTable`, `set.DistanceTable`, `set.DistanceFunction`

### Loading data from a file

Example datasets are provided in the `data/` directory as JSON files.

**Python**
```python
from linguistic_variation_toolbox import read_data_file
s = read_data_file("data/ochisorzu.json")
```

**MATLAB**
```matlab
set = readDataFile("data/ochisorzu.json");
```

### Representing the data graphically

**Python**
```python
s.plot()
```

**MATLAB**
```matlab
set.plot()
```

This shows a [graph](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)) where
every variant is a node and the colour of the arc between two nodes encodes their distance.
Only arcs shorter than the median distance are drawn, keeping the most statistically
significant connections.

<img src="https://i.ibb.co/4T3htKr/no-options.png"
alt="plot-no-options" align="center" border="0">

**Important:** This representation does not encode distances _exactly_. Use it to
formulate hypotheses, then confirm them with the statistics described below.

#### Placement algorithms

The `placement_algorithm` / `PlacementAlgorithm` option controls node placement:

* `"mds"` (default) — [multi-dimensional scaling](https://en.wikipedia.org/wiki/Multidimensional_scaling): places nodes to minimise the difference between Levenshtein distances and 2D Euclidean distances, and prints the maximum relative error.
* `"force"` — force-directed layout: often produces more readable results when the 2D MDS
  projection error is high.

**Python** — `s.plot(placement_algorithm="force")`  
**MATLAB** — `set.plot(PlacementAlgorithm="force")`

#### Centering on category standards

The `center_categories` / `CenterCategories` option rotates and centres the plot so that
the reference variants of two chosen categories lie on a horizontal line at the centre:

**Python**
```python
s.plot(placement_algorithm="force", center_categories=("C", "L"))
```

**MATLAB**
```matlab
set.plot(PlacementAlgorithm="force", CenterCategories=["C", "L"])
```

<img src="https://i.ibb.co/qjC075T/force.png"
alt="plot-force" align="center" border="0">

#### Proximal plot

The `mode` / `Mode` option switches between `"complete"` (default, all arcs) and
`"proximal"` (each variant connected only to its nearest neighbour by a directed arc):

**Python**
```python
s.plot(placement_algorithm="force", center_categories=("C", "L"), mode="proximal")
```

**MATLAB**
```matlab
set.plot(PlacementAlgorithm="force", CenterCategories=["C", "L"], Mode="proximal")
```

<img src="https://i.ibb.co/sWPVScf/proximal.png"
alt="plot-proximal" align="center" border="0">

### Computing statistics

**Python**
```python
stats = s.compute_statistics()
```

**MATLAB**
```matlab
stats = set.computeStatistics();
```

Pass `quiet=True` / `Quiet=true` to suppress printed output.

The following statistics are computed both per category and across the whole set:

* _Diameter_ — maximum distance between any two variants.
* _MeanDistance_ — average pairwise distance.
* _RangeDistance_ — maximum minus minimum pairwise distance.
* _MeanDistanceFromBaricentre_ — LVT embeds the variants in a geometry via
  multi-dimensional scaling, finds the geometric centre (baricentre) of that embedding,
  then averages the distances of all variants from it.

Per variant:

* _WeightedDegree_ — sum of distances to all other variants.
* _MeanDistance_ — WeightedDegree normalised by the number of other variants; smaller
  means more central.
* _RangeDistance_ — distance to the farthest minus distance to the closest variant.
* _Closeness_ — inverse of the WeightedDegree.
* _DistanceFromBaricentre_ — distance from the variant to the geometric baricentre.

---

## How to cite

> Acadèmia de su Sardu APS (2023). Linguistic Variation Toolbox, version **XXXX**.
> [https://github.com/academiadesusardu/linguistic-variation-toolbox].

Substitute **XXXX** with the release number.
