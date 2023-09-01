<p align="center">
    <img src="https://i.ibb.co/SP6bNc2/Logo-Acad-mia-de-su-Sardu-piticu.png" alt="Logo-Acad-mia-de-su-Sardu-piticu" width="120px" border="0">
</p>

# Linguistic Diversity Toolbox [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=academiadesusardu/linguistic-variation-toolbox&project=Linguisticvariationtoolbox.prj)

The Linguistic Diversity Toolbox (LDT) is a
[MATLAB](https://uk.mathworks.com/products/matlab.html) software for the study and
characterization of linguistic diversity through a mathematical and computational
approach. It is developed by [Acadèmia de su Sardu
APS](https://www.academiadesusardu.org/) and released with an Open Source Apache 2.0
license.

## Usage guide

### Installing and running

[You can use this software for free on MATLAB Online](https://matlab.mathworks.com/open/github/v1?repo=academiadesusardu/linguistic-variation-toolbox&project=Linguisticvariationtoolbox.prj). You might have to create a MathWorks.com 
account for this: this is 100% free.

If you want to try it on your own MATLAB installation, on your computer, you can either:
* install the Linguistic Diversity Toolbox through MATLAB's [Add-On Explorer](https://www.mathworks.com/products/matlab/add-on-explorer.html).
* download this code and add the folder ''source'' to the MATLAB path.

The Linguistic Diversity Toolbox requires the following MATLAB toolboxes:
* Statistics and Machine Learning Toolbox.

### Defining categories

The first step to use LDT is to define the categories in your data. For example, let us
imagine we are working on Sardinian and using its two macro-varieties as categories. For
short, we can model _Campidanese_ with the string `"C"` and _Logudorese-Nugorese_ with the
string `"L"`:

```matlab
allCategories(["C", "L"]);
```
The categories can be any number of strings, and you are free to define them in any way
that suits your research. To retrieve the list of categories after we have set them, we 
can run:
```matlab
allCategories()
```

### Defining a set of variants

The Lingustic Diversity Toolbox helps study the properties of sets of _variants_ and the
patterns within. To do this, the toolbox provides an object called `SetOfVariants`.

From a linguistics point of view, to work with these variants you need to have:
* a set of _transcription rules_ to be able to represent the variants as strings. You can
  use phonetic or orthographic transcriptions as suits your research.
* a way of measuring the _distance_ between two transcribed variants.

Continuing with the example of Sardinian, let us assume we are using orthographic transcription
according to the rules in Acadèmia de su Sardu's normative grammar ["Su Sardu
Standard"](https://www.academiadesusardu.org/chi-siamo-3/su-sardu-standard/). To measure
distances between variants, let us assume we are using [Levenshtein's distance](https://blogs.mathworks.com/cleve/2017/08/14/levenshtein-edit-distance-between-strings/):
> The Levenshtein distance between two strings is the number of single character
> deletions, insertions, or substitutions required to transform one string into the other. 
> This is also known as the edit distance.
For example, the Lenvenshtein distance between the strings _cat_ and _catfish_ is 4.
However, for our application we also ignore diacritics and therefore set to 0 the distance
between variants that are written similarly apart from the stress. For example, the
distance between _arrèxini_ e _arrexìni_ is going to be 0. This way of measuring distance
is the default for `SetOfVariants` objects.

One way to create the object is to list the variants of interest, the categories they
belong in, and whether each variant is a reference within its category:
```matlab
variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"];
categories = ["C", "L", "L"];
isCategoryReference = [true, false, true];
set = SetOfVariants(variants, categories, isCategoryReference);
```
For example, the category reference could be the _standard_ variant. If the mapping
between variants, categories, and category references is not this straightforward, we can
use `VariantAttribute` objects. Using `VariantAttribute` objects, the previous code can be
written as follows:
```matlab
variants = ["ocisòrgiu", "ochisorzu", "bochisorzu"];
attributes = { ...
    VariantAttribute("C", true), ...
    VariantAttribute("L", false), ...
    VariantAttribute("L", true)};
set = SetOfVariants(variants, attributes);
```
If we want to specify a custom distance function:
```matlab
set = SetOfVariants(variants, attributes, DistanceFunction=@myCustomDistance);
```

Once the object has been created, we can view some data by accessing its properties
```matlab
set.VariantTable
set.DistanceTable
set.DistanceFunction
```

For a complete documentation on `SetOfVariants` objects, you can type:
```matlab
help SetOfVariants
```

### Represent the data graphically

To represent the set of variants graphically, one can type:
```matlab
set.plot()
```
This will show a representation of the set of variants as a
[graph](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)), 
where every variant corresponds to a _node_ and the distance between two variants is related
to the length of the _arcs_ between their two nodes. We only represent the arcs whose
length is less than the _median_ value, that is the most statistically significant arcs.

<img src="https://i.ibb.co/4T3htKr/no-options.png"
alt="plot-no-options" align="center" border="0">

**Important:** note that this representation does not represent the distances _exactly_, 
but can highlight patterns within the set of variants. We can use these representations to
formulate hypotheses on the data, which can be then proved using the statistics (see
following section in this guide).

There are different options that can be combined for representing the data graphically.
For the full documentation, you can type:
```matlab
help SetOfVariants/plot
```

The option `CenterCategories` expectes two categories as an input. It rotates and centers 
the plot in a way that the category references lay on a line in the middle of the plot.
The center of the segment between the categories is the center of the plot.
```matlab
set.plot(CenterCategories=["C", "L"])
```
<img src="https://i.ibb.co/bmn21jq/center-categories.png"
alt="plot-center-categories" align="center" border="0">

The option `PlacementAlgorithm` changes the way the nodes are placed on the plot. It can
be `mds` (the default) or `force`. By default, the Linguistic Variation Toolbox will use
[multi-dimensional
scaling](https://uk.mathworks.com/help/stats/cmdscale.html?searchHighlight=cmdscale&s_tid=srchtitle_support_results_1_cmdscale)
to represent the distances as accurately as possible, and write to the command line the
maximum relative error in the plot. The `force` algorithm uses an alternative approach 
to represent the graph, which often leads to better readability of the variants in the
plot.
```matlab
set.plot(CenterCategories=["C", "L"], PlacementAlgorithm="force")
```
<img src="https://i.ibb.co/qjC075T/force.png"
alt="plot-force" align="center" border="0">

The option `Mode` toggles between the `complete` plot (default) and `proximal` plot. The
`proximal` plot is a representation where every variant is connected to its closest
variant by an arc with direction. This can be used to highlight other patterns within the
set of variants.
```matlab
set.plot(CenterCategories=["C", "L"], PlacementAlgorithm="force", Mode="proximal")
```
<img src="https://i.ibb.co/sWPVScf/proximal.png"
alt="plot-proximal" align="center" border="0">

### Computing statistics on the data

To study the statistics on sets of variants, one can type:
```matlab
stats = set.computeStatistics()
```
This also accepts the option `Quiet`, which can be `false` (the default) or `true`. When
`Quiet` is `false`, MATLAB will display all the statistics it computed on the command
line. The data is stored in the output `stats` for further analysis.

The following statistics are computed both by category and on the overall set of variants:
* _Diameter_: the maximum distance between two variants.
* _MeanDistance_: the average distance between two variants.
* _RangeDistance_: the difference between the maximum and the minimum distance.
* _MeanDistanceFromBaricentre_: the Linguistic Variation Toolbox computes the
  multi-dimensional scaling of the variants in the graph, which is the representation of
  the variants and their distances as a geometry. It then computes the
  baricentre, i.e. the central point, of the obtained geometry. Then, it computes the
  distances of the variants from this abstract point.

For every variant in the category or in the overall set of variants, the following statistics are
computed:
* _WeightedDegree_: this is a graph-based metric that is equal to the sum of all the
  distances between the current variant and the other variants.
* _MeanDistance_: similar to the previous metric, but divided (i.e. normalized) by the
  number of the other variants. The smallest _MeanDistance_, the more central the variant
  in a graph-theoretical sense.
* _RangeDistance_: difference between the distance of the farthest and the closest variant
  in the set, with respect to the current variant.
* _Closeness_: the inverse of the _WeightedDegree_ metric.
* _DistanceFromBaricentre_: the distance from the current variant to the geometric
  baricentre, an abstract point that represents the geometric centre of the variants but
  that almost never corresponds to any actual variant.

## How to cite

> Acadèmia de su Sardu APS (2023). Linguistic Diversity Toolbox, version **XXXX**.
> [https://github.com/academiadesusardu/linguistic-variation-toolbox].

In the above, substitute **XXXX** with the release number.