# Changelog

All notable changes to refrains are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the versions
follow [Semantic Versioning](https://semver.org/).

refrains continues [fv-morphologie](https://github.com/FredVoisin/fv-morphologie):
refrains 0.0.1 starts from fv-morphologie 1.4.0, and the versions below it
(fv-morphologie 1.4.0 to 0.1.0) are those of fv-morphologie.

## [Unreleased]

### Changed

- **`entropy` takes keywords**: `(entropy data &key mode window step test)`
  instead of `(entropy data &optional mode samples test)`. `samples`, the
  number of windows, is replaced by `:window` and `:step`, described as for
  the filters: `(entropy d 'shannon-2 4)` is now `(entropy d :window 1/4)`,
  and a smaller `:step` gives sliding windows.
- **One description of the windows** for all the functions with windows
  (`filt-median`, `filt-extrema`, `filt-mean`, `filt-function`,
  `filt-quantize`, `entropy`): `window`, an integer (positions) or a ratio
  or a float in ]0, 1] (a part of the length); `step`, an integer
  (positions) or a ratio or a float in ]0, 1] (a part of the window).
  `filt-median` and `filt-extrema` accept a part of the length; another
  value is an error everywhere (`filt-median` rounded `3.0` to 3, and
  `filt-function` took `2.5` as 2.5 times the length).

### Added

- `entropy` mode `conditional`: the conditional entropy H(x(t+1) | x(t)),
  in base 2, 0 for a periodic sequence. The mode `cond-sh` is documented
  for what it computes: the entropy of the pairs of successive elements
  divided by 2.
- Distances between sets, exported in the family `dist-`: `dist-set`, with
  `:measure` `jaccard` (by default), `sorensen` or `mountford` (1 - their
  similarity), and `dist-jaccard-bin` for binary vectors of presence,
  with the standard convention: a value other than nil and 0 is present.
  The order and the repetitions of the elements are ignored; with `b` nil,
  the semi-matrix of the distances, as for the other distances. Documented
  in `doc/refrains.fr.md` (with the references to Jaccard, 1901, and to
  Sneath & Sokal, 1973) and `doc/refrains-fonctions.fr.md`.

### Fixed

- The defgeneric of `intersection-card` was misspelled
  `intersectioon-card`.
- `dist-edit` and `edit-dist` looped forever on two empty sequences: nil is
  also a symbol, and the method for symbols called itself. They give 0.
- `entropy` in mode `cond-sh` took `samples` as the length of the windows,
  not as their number as documented and as the Shannon modes do:
  `(entropy d :cond-sh 4)` gave 25 values for 100 elements, it gives 4.
- `entropy` in mode `cond-sh` with a test stricter than `equalp` (`eql`,
  `equal`) stopped on an error: the distinct symbols were taken with
  `equalp`, and an element they did not contain was not found.

### Removed

- Dead code: the functions that neither the exported functions nor the tests
  use (`insert-tree`, `graphtodot`, `list-mod`, the matrix functions, the old
  helpers of Prim's algorithm...).
- The LispWorks variants (`#+Lispworks`) of `graph2dot`, `shell-command`,
  `e-shannon`, `kind-of-entropie-conditionnelle` and `dendrogram>dot`: only
  portable Common Lisp remains. The entropies sum with `reduce` instead of
  `apply`, which is bounded by `call-arguments-limit`.
- The internal relays inherited from OpenMusic and PWGL, which only passed
  their arguments on: `tree-minlen`, `tree-leaves`, `graph2matrix`,
  `minimum-spanning-tree`, `find-pos`, `randsort` (`randswap` takes a part
  of the length), and `tree-deg`, `tree-path`, `tree-dist`, whose methods
  are now those of `graph-degree`, `graph-path` and `dist-graph`;
  `rep-strct` and `find-self` are now the bodies of `motif-structure` and
  `motif-list`. No exported function changes.
- `edit-dist1`, `edit-dist2` and `editing-dist` are merged into
  `edit-distance` (with `:inex`, 0 by default; its loop is compiled with
  and without `inex`, as fast as before), and `edit-dist-ldl1` and
  `edit-dist-ldl2` into `multi-edit-dist`.
- `windowed-e-shannon` and `windowed-entropie-cond`, identical but for the
  measure applied to each window, are merged into `windowed`.
- `windowed`, `shannon-entropy` and `entropie-conditionnelle`: `entropy`
  calls the measures directly; `quantize-windows` becomes `window-bounds`,
  next to `window-size` and `window-step`, shared by all the functions with
  windows.

## [0.2.1] - 2026-10-24

### Added

- Example: the neural networks of neuromuse as graphs
  (`doc/exemples/neuromuse.md`, `doc/lisp/neuromuse-graphs.lisp`): the
  skeleton, the strongest paths and the pruning of an MLP trained on XOR, the
  resemblance of its hidden neurons (Ward), the topology of a self-organizing
  map trained on the song of a chaffinch, and its sequences of winning
  neurons compared by edit distance, the DTW considered in neuromuse.
- Example: comparing neural networks (`doc/exemples/neuromuse-comparaison.md`,
  `doc/lisp/neuromuse-comparaison.lisp`): six MLPs and three self-organizing
  maps of neuromuse learning the same thing from different draws, compared
  before and after learning by what does not depend on the numbering of
  their neurons (geometry of the hidden layer, roles of the neurons with
  `histogram`, topology of the maps, segmentation of the song with
  `dist-hamming`).
- Example: quantizing an F0 (`doc/exemples/hindehu.md`,
  `doc/lisp/hindehu.lisp`, `doc/data/hindehu-f0.txt`, `doc/data/hindehu.mp3`):
  the fundamental frequency of an extract of *Hìndèhú* of the Aka (voice and
  *mòbéké*), detected with YIN, quantized by `filt-quantize`
  (whole, sliding window), then by notes (`class-num` on the notes,
  `histogram` on a quarter-tone grid): five levels of a scale that is not
  tempered, about a quarter tone above the tempered one; transcribed for
  LilyPond by `seq>ly`, to the quarter tone (with the score), and in the ABC
  notation by `seq>abc`, a quarter tone lower.

- `filt-quantize (seq levels &key mode thres window step segments out)`
  quantizes a sequence of numbers on its own centres of attraction
  (`class-num`): each value is replaced by the centre of its class. By the
  time spent (`:1d-centroids`, by default), or by the salient points of a
  method of `exsample` (`:minmax`: each turn counts once, fixed centres); on
  the whole sequence, on a sliding window (`:window`, a number of positions
  or a part of the length), or on each run between `nil`s (`:segments t`).
- `seq>ly (seq &key out title rhythm unit)` writes a sequence of MIDI notes
  for LilyPond, rounded to the quarter tone (`ih`: 74.5 is `dih''`), for
  scales that are not tempered; without rhythm, or with tied lengths in
  sixteenths; `:out` as for `seq>abc`, and a path of type svg, pdf or png
  also makes the score with `lilypond`.
- `seq>abc (seq &key out title rhythm unit)` writes a sequence of MIDI notes
  (rounded to the semitone; a list of notes is a chord, `nil` a rest) in the
  ABC music notation, without rhythm by default, or with lengths in
  sixteenths (`:rhythm t`); `:out` as for `seq>plot`, but `nil` returns the
  text.
- `class-num` takes, instead of a number of classes, the list of their
  initial centres, even approximate ones: the dynamic clouds start from them,
  whatever the mode, deterministically (without `:iter`); equal centres
  (`equalp`) count once. The extrema given by `exsample` are, for example, a
  good start to quantize a curve.
- `class-num` takes `:sort`: with numbers, `t` numbers the classes by
  increasing centre (class 0 the lowest), and gives the centres in this
  order; `nil` (by default) keeps the order of first appearance.
- `exsample` takes the method `:angles`: the angular points, where the slope
  on the left and the slope on the right differ by at least `thres` (by more
  than 0 when `thres` is 0), whatever their signs: the breakpoints of a
  polygonal line (as in the BPF of PWGL), which `:minmax` and `:minflexmax`
  do not give when the slope changes without changing its sign. Type -1
  where the slope increases, 1 where it decreases.
- `seq>plot` draws a sequence of events `(time value ...)`, or a list of
  numbers (each at its rank, a `nil` being a missing value), with characters
  to see its shape in the listener or in a terminal, or in an SVG image,
  without any dependency: the time in x, proportionally, a dimension of the
  events in y, between its minimum and its maximum. `:out` chooses the
  output (`nil`, the listener, by default; a stream; or the path of the SVG
  file), `:start` and `:duration` the window, `:low` and `:high` the
  bottom and the top (zoom in y), `:width` and `:height` the size of the plot, `:mode` (`:line` or `:points`) the drawing in SVG, and
  `:labels` whether the extrema and the times of the window are written.
  With characters, each column marks all the events of its time span, so
  that no extremum is lost.
- `graph>dot` takes `:overlap`: `t` (by default) lets the nodes overlap, as
  before; `nil` makes neato move them apart (graph attribute
  `overlap=false`), useful when the lengths are short compared with the
  names of the nodes, such as distances from 0 to 1; a string is the value
  of the Graphviz `overlap` attribute (`"scale"`, `"prism"`…).
- `graph>dot` takes `:invert`: `t` draws white on black instead of black on
  white (`nil` by default).
- `dendrogram>dot (dendrogram &key out width step invert)`: draws a
  dendrogram of `graph-dendrogram`, or a list of them, in dot with the
  position of each point, for `neato -n2`: the leaves on the left, each
  fusion at the abscissa of its distance, and a scale of the distances.
- `graph-dendrogram` takes `:linkage :ward` (Ward, 1963): the fusion that
  increases the least the within-group inertia, computed with Lance and
  Williams' formula; the height of a fusion is the square root of twice
  this increase (the distance itself for two objects). The documentation
  explains its links with `class-num` (Diday's dynamic clouds) and the
  French school of data analysis (Benzécri, Diday), with references.
- Documentation: two minimum spanning trees of the functions, by their names
  and by the vocabulary of their docstrings, computed with refrains by
  `doc/lisp/refrains-trees.lisp` (which uses `:overlap nil` and
  `:invert t`), with their dendrograms (`graph-dendrogram` and
  `dendrogram>dot`), and the figure
  of the operations, in white on black; what to do
  when the system "refrains" is not found.
- Documentation: the examples (section 5, "FV-examples", now "Examples")
  have one file each, in `doc/exemples/` (reference) and `doc/examples/`,
  listed with a short description in `doc/exemples.md` and
  `doc/examples.md`; the function trees are the first example in Common
  Lisp: its script moves to `doc/lisp/refrains-trees.lisp` (it writes its
  images in `doc/pictures/`), and its commented code, which is its
  documentation, is embedded in the page of the example. `doc/README.md`
  presents the files of the documentation. The data of the examples are in `doc/data/`
  (CC BY 4.0, except a public-domain text), and the examples link to them;
  the two protected texts of the example of the delineations stay in
  fv-morphologie. Every Lisp file of
  `doc/lisp/` is under CC BY 4.0, like the documentation (`doc/lisp/README.md`),
  which a test checks (`doc-lisp-license`).
  In the vocabulary of the docstrings, the trees remove a list of the
  grammatical words of English (articles, pronouns, auxiliaries,
  conjunctions, prepositions) instead of the words found in more than 10
  docstrings, which also removed words such as *distance* or *graph*, and
  a list of the words of the style of the docstrings (*argument*,
  *keyword*, *default*, *returns*...). The documentation links from its beginning to the list of the
  functions and to the examples.

### Changed

- `graph>dot` and `dendrogram>dot` take their output as the key `:out`,
  as `seq>plot`, instead of a required argument: `nil` (by default) or `t`
  prints in the listener, a stream is written into, a path writes the file.
  `(graph>dot graph "g.png")` becomes `(graph>dot graph :out "g.png")`.
- `graph>dendrogram` is renamed `graph-dendrogram`: it computes a
  classification (an analysis), as `graph-span` or `graph-part` do, while
  `>` is kept for the changes of representation without analysis
  (`graph>dot`, `dendrogram>dot`, `graph>matrix`, `num>base`...).
- `graph>dot` and `dendrogram>dot` are in the section 4 of the menu
  (reading and writing files), since they write files, and `graph>matrix`
  in the section 1.3 (delineate), in `help`, in the documentation and in the
  function tables.
- `filt-noise` is in the section 1.2 (filter), with the other `filt-`
  functions, instead of 1.1 (transcode), where the PWGL box `randomize` was.
- `graph-leaves` returns the leaves sorted as by `graph-nodes` (numbers
  first, then by name): `(A C D)` instead of `(D C A)`.
- `graph-degree` is in the section 3.1 (enumerate), with `graph-nodes` and
  `graph-leaves`; `graph-length` stays in 3.3, renamed "quantify:
  information, diversity": for a minimum spanning tree, it measures the
  diversity of the objects. Its docstring is rewritten (it said the graph
  must have no cycles, but it sums all the edges).
- `graph-part` is in the section 2.3 (differentiate: classify), after
  `class-sym`, instead of 2.1 (segment): it partitions a set of objects
  into groups (single linkage), as `class-sym` does for sequences of
  symbols. The docstring of `class-sym` referred to `class-graph`, which
  does not exist: it refers to `graph-part`.
- The docstring of `class-num` is reworded (it said "into s space"); it
  names the algorithm of both modes, Diday's dynamic clouds (*nuées
  dynamiques*), from random initial centres (`:centroids`) or from initial
  centres taken between the largest differences (`:1d-centroids`).
- The docstring of `mark-structure` is reworded (it spoke of an "output
  menu", as in PWGL).
- `graph-path` is in the section 3.1 (enumerate: find), after
  `graph-degree`, instead of 1.3 (delineate): it does not build a graph,
  it finds paths in a graph, as `graph-nodes`, `graph-leaves` and
  `graph-degree` describe its nodes. Section 1.3 keeps the functions that
  build or represent a graph (`graph-span`, `graph-dendrogram`,
  `graph>matrix`).
- `date-string` and `date+time-string` are merged into
  `date-string (&optional time u)`: the date of the universal time `u` (now
  by default), such as `"22 Oct 2026"`, or with `time` true the date and
  time, such as `"22 Oct 2026 14:05:09"`; `(date+time-string)` is
  `(date-string t)`.
- The dot files of `graph>dot` and `dendrogram>dot` are dated with
  `date-string`, such as `22 Oct 2026 14:05:09` (it was
  `2026 october twenty-second at 14h5`).

### Fixed

- `(dist-graph v1 nil graph)` gave the number of nodes of the paths from
  `v1` to the other nodes (`(2 3 3)`), not their lengths: it gives the
  distances of `v1` to all the nodes, in the order of `graph-nodes`, 0 to
  `v1` itself (`(0 1 3 2)`). The docstring and the documentation describe
  it, with a list of nodes as `v2`.

### Removed

- `date-string` is no longer exported: no function of refrains used it or
  `date+time-string`, which had been exported only because the tests used
  them. The package exports 52 functions.
- The internal functions `date` and `time-string`, replaced by
  `date-string`.

## [0.2.0] - 2026-10-24

### Changed

- The functions are renamed consistently, without aliases for the former
  names (fv-morphologie keeps them). The names follow two conventions:
  `family-object` (`filt-`, `graph-`, `dist-`, `mark-`, `motif-`, `class-`)
  and `source>target` for conversions; whole words rather than truncations;
  as far as possible an etymology common to French and English. The family
  `graph-` is kept for the functions on trees as well: the word is common to
  French and English, and graph theory applies to trees.

  | 0.0.1 | 0.2.0 |
  |---|---|
  | `str->symb` | `str>sym` |
  | `filt-local-rep` | `filt-repeat` |
  | `filt-fct` | `filt-function` |
  | `graph-extrem` | `graph-leaves` |
  | `dist-euclidian` | `dist-euclidean` |
  | `dist-citybloc` | `dist-cityblock` |
  | `motif-find` | `motif-position` |
  | `elt-info` | `self-info` |

- The arguments are named consistently: `window` (not `wind`) in
  `filt-mean` and `filt-function`; `:sub :ins :del :uncom` for the costs of
  the edit distance in `motif-position`, `motif-list` and `class-sym`
  (`:change`, `:insert`, `:delete` before, as in `dist-edit` already);
  `:mark-test` and `:seg-test` (`:mark-t` and `:seg-t` before) in
  `mark-list`.
- The internal function `self-info` is renamed `self-information`.

### Added

- `filt-extrema (seq window &optional mode)`: maximum (`:max`,
  dilation) or minimum (`:min`, erosion) over a window centred on each
  value, and their compositions `:open` (removes the narrow peaks) and
  `:close` (fills the narrow hollows):
  `(filt-extrema '(1 5 2 8 3 3 9 1 0 4) 3)` gives `(5 5 8 8 8 9 9 9 4 4)`.
- `morph-seq (seq1 seq2 &key test random)` (menu 1.4, Interpolate): the
  sequences from `seq1` to `seq2` changing one element at a time along an
  edit path of minimal cost, the same at each call (at random with
  `:random t`); the elements are compared with `equalp` by default, and two
  strings give strings.
- `graph>dendrogram (mat-dist &key linkage)`: the dendrogram of the agglomerative
  hierarchical classification of a semi-matrix of distances. Returns the
  list of the fusions `(distance group-a group-b)` and the dendrogram as a
  nested tree `(distance tree-a tree-b)`. `:linkage` is `:single` (by
  default, from the minimum spanning tree, for any graph), `:complete` or
  `:average` (UPGMA; both need a complete semi-matrix). Experimental.
- Documentation: to group the adjacent lists that intersect, use
  `motif-group` with the test `(lambda (a b) (intersection a b))`.

### Removed

- `dist-euclid`, `concaten` and `split-string` are no longer exported: they
  were the same functions as `dist-euclidean`, `list>sym` and `separate`
  (on a string). The package exports 53 functions.
- The internal function `regroup-if-intersection`, used by no function: it
  compared all the pairs of lists, not only adjacent ones, and did not
  regroup again after a fusion.

## [0.0.1] - 2026-10-24

### Changed

- fv-morphologie becomes refrains: the system, the package and the
  documentation files are named `refrains` (`(asdf:load-system :refrains)`,
  `(in-package :refrains)`, `doc/refrains.md`, `doc/refrains.fr.md`).

### Removed

- `pwgl-legacy/` (the PWGL boxes, their documentation and the tutorial):
  they stay in the fv-morphologie repository. The figure used by the
  documentation is in `doc/pictures/`.

## [fv-morphologie 1.4.0] - 2026-10-24

### Added

- `separate` takes `:keep`: with `t`, the marks are kept, each one
  beginning the segment that follows it, as in `mark-structure`
  (`(separate '(a b x c d x e) :marks '(x) :keep t)` gives
  `((A B) (X C D) (X E))`); the blanks of a string are always removed.
  `split-string` takes it as an optional argument.

### Changed

- `split` is renamed `separate`, and its optional `marks` becomes the
  key `:marks`: `(split seq marks)` is `(separate seq :marks marks)`.

### Removed

- `split`: use `separate`.

## [fv-morphologie 1.3.0] - 2026-10-24

### Changed

- `exsample` merges `int-signature` and the former `exsample`:
  `(exsample seq method thres &key diff duration out)`. The option becomes
  two keys: `:diff`, the difference (`:absolute`, `:relative` or a
  function) with `:major-extrema` and `:landmarks`; `:duration`, a number of
  positions, the minimal plateau with `:minflexmax` and D with `:landmarks`.
  `:out` gives the output: `:values` (default), `:positions`, `:all`,
  `:resampled`, or `:signature`, the points that `int-signature` returned.
  `(int-signature seq mode thres)` is `(exsample seq mode thres :out
  :signature)`, and `(exsample seq method mode thres)` is
  `(exsample seq method thres :out mode)`. A key that the method does not use
  is an error.
- `:major-extrema` takes `:relative` and `:absolute` as `:landmarks` does.

### Removed

- `int-signature`: use `exsample` with `:out :signature`.

### Fixed

- `exsample` looked the points up in the list one by one, in quadratic time
  (2.1 s for 50,000 values with `:resampled`): it is linear (12 ms).

## [fv-morphologie 1.2.0] - 2026-10-24

### Fixed

- `int-signature :landmarks` removed the pairs of landmarks in quadratic
  time (1.8 s for 200,000 values; 0.18 s now). A negative distance D, or one
  which is not a number, is an error.

### Changed

- `int-signature :landmarks` removes the pair of smallest difference first
  (the left-most of equal differences), instead of the left-most pair: a peak
  is no longer removed for a smaller variation next to it. `(0 6 4 5 0)` with
  `thres` 3 gives `((1 1 6))`, not `((3 1 5))`. The documentation gives this
  order.

## [fv-morphologie 1.1.1] - 2026-10-24

### Fixed

- `int-signature` and `exsample` with a negative threshold never ended
  (`:minmax`, `:minflexmax`, `:major-extrema`), or took it as 0
  (`:landmarks`): a negative threshold is an error. `:major-extrema` with a
  distance function which is not 0 between equal values never ended either.

### Changed

- The documentation of `:major-extrema` gives how Fink & Gandhi's algorithm
  treats the ends of the sequence and equal extrema.

## [fv-morphologie 1.1.0] - 2026-10-23

### Changed

- `int-signature` and `exsample`, methods `:minmax` and `:minflexmax`,
  rewritten. With a threshold, a variation smaller than `thres` no longer
  gives a minimum and a maximum (each small dip of a slow drift did, and the
  first wiggle of a plateau stayed an extremum): the minima and maxima are
  the important extrema of `:major-extrema`. The results with `thres` 0 are
  unchanged for `:minmax`.
- `:minflexmax`: a plateau is a stretch of at least `option` positions where
  the sequence varies by less than `thres`; it gives an inflexion where it
  begins and where it ends (one inflexion at its first position before),
  valued as in the sequence (the mean of its turns before). `option` is this
  duration, a number of positions (it was a number of turns, and a
  non-integer was scaled by the range and the length); `:minmax` does not
  use it.

### Removed

- The internal functions of the old method (`primitives`,
  `flat-primitives`, `primitives-thres`, `primitives-raw`,
  `primitives-nothres`, `primitive-value`, `primitive-sign`, `mfm`,
  `notzerop`, `sign`), and `next-sign`; `derivee` gives the signs of the
  successive differences.

## [fv-morphologie 1.0.0] - 2026-10-22

The first stable release: from this version on, the public interface (the
54 functions exported by the package `fv-morphologie`, their arguments and
their documented results) changes only with a new major version.

### Changed

- The sources are organized in `src/`, one file per domain (`utils`,
  `encoding`, `filters`, `signature`, `distances`, `marks`, `motifs`,
  `graphs`, `dot`, `classification`, `information`, `interpolation`, `io`),
  and `src/api/`, the public functions by section of the menu
  (`transcription`, `classification`, `evaluation`, `files`, `help`). The
  tests are organized the same way. The code itself is unchanged: the
  functions give the same results as in 0.2.0.

## [fv-morphologie 0.2.0] - 2026-10-22

The first release as a Common Lisp library loadable with ASDF and Quicklisp,
with a test suite (FiveAM) run on SBCL and ECL.

### Security

- Text is read with `*read-eval*` false: the reader macro `#.` in a text file
  read by `read-text` is no longer evaluated (it ran its code).

### Changed

These changes alter results which were documented or relied upon:

- `read-text`: in lines mode, each line is a list, even a line of one word
  (one number per line gives `((1) (2) (3))`, it gave `(1 2 3)`); a word
  which cannot be read is kept as a string; `:rem-test` also applies in lines
  mode; in `:charcode` mode, newlines and blanks separate the segments, and
  letters of any alphabet are letters. The modes `:ascii-7b` and `:ascii-8b`
  are removed; an unknown mode is an error.
- `split-string` always returns a list (`"hello"` gives `("hello")`).
- `filt-median`: centred window, odd windows only (an even window is
  enlarged), edges repeated; `filt-mean` and `filt-fct`: centred windows
  shrinking symmetrically at the edges; `filt-fct`'s default step is 1.
- `filt-lowpass` with `gamma` (double exponential smoothing) follows Holt's
  formulas (the signs were wrong).
- `mountford-similarity` is normalized to `M / (1 + M)`, from 0 to 1.
- `graph-span` uses Kruskal's algorithm: the tree is deterministic, its edges
  sorted by length; a graph which is not connected gives a spanning forest.
- `graph-path` and `dist-graph` give the shortest path by distance
  (Dijkstra); `dist-graph` gives `nil` when there is no path.
- Graph nodes are compared with `equal`: strings are case-sensitive.
- `int-signature`: `thres` is an absolute amplitude for every method; a flat
  extremum is given once, at its first position.
- `class-num` with one-dimensional data gives numbers as centres; `class-sym`
  numbers its classes in order of first appearance.
- `histogram`: `equalp` by default (it was `eq`); equal counts in order of
  first appearance.
- `write-list :coll` writes a Max coll file (`index, data;`), symbols in
  lower case.
- Unknown modes or outputs are errors instead of silent `nil` results, in
  `class-num`, `entropy`, `exsample`, `filt-local-rep`, `filt-noise`,
  `graph-part`, `int-signature`, `mark-structure`, `motif-list`,
  `read-text`; `lmin`, `lmax`, `fmax`, `fmin`, `mean` and `normalize` signal
  explicit errors on empty lists or zero sums.

### Added

- `int-signature` methods `:major-extrema` (Fink & Gandhi important extrema)
  and `:landmarks` (Perng, Parker & Leung landmarks, with an absolute,
  relative or custom criterion); they silently gave the `:minflexmax` result.
- `motif-structure` keywords `:lengths`, `:test`, `:diss`, `:l-var`,
  `:criteria`, `:distance`.
- `graph-part` optional number of parts.
- `filt-noise` mode `:relative`, and a function mode `(lambda (x l) ...)`
  applied to each element.
- `motif-find` on strings.
- `graph>matrix` is exported and documented; `help` works (it printed every
  similarity score); `doc` and `help` know all the exported functions.
- `graph>dot` writes any format of `neato` (svg, pdf...), and works on ECL.

### Fixed

- k-means (`class-num :centroids`) could return a single class (17% of the
  runs on a simple example); `class-num :iter` frequencies summed to more
  than 1; `class-num` with mode `nil` returned `nil`; `:1d-centroids`
  returned 2 classes whatever the number asked.
- `class-sym` and `graph-part` with a number of parts give exactly that
  number of classes or parts.
- `dist-multi-edit` with fewer weights than dimensions crashed; the weights
  are normalized after being completed.
- `graph>dot`: lengths were rounded on 3 characters, labels such as `1/3`
  were invalid DOT, node names had package prefixes, `Mrecord` lost its case.
- Edit distance `uncom` (`inex`) uses `test` to decide whether an element
  exists in the other sequence.
- Reading a UTF-8 file whole added NUL characters (spaces on ECL) at the end.
- Many other functions accept any kind of element (strings, lists) where
  they failed, and no longer divide by zero on empty data: see the commits.

### Performance

- Edit distance in quadratic time (it was cubic), bounded when a tolerance
  is given: `motif-structure` on 240 elements, 352 s → 0.3 s; `motif-list`
  on 120 elements, 32 s → 0.2 s (exact) and 34 s → 4 s (with a tolerance).
- `graph-span` on 320 objects in 0.06 s; `graph-path` on long trees and
  `filt-local-rep :linear` on long lists in linear time.

### Removed

- The modes `:important-extrema` and `:mdpp` of `signature` (broken attempts,
  replaced by `:major-extrema` and `:landmarks`), and unused internal
  functions.

## [fv-morphologie 0.1.0]

The PWGL / OpenMusic library adapted to Common Lisp, before this changelog.

[0.2.0]: https://github.com/FredVoisin/refrains/releases/tag/v0.2.0
[fv-morphologie 1.4.0]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v1.4.0
[fv-morphologie 1.3.0]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v1.3.0
[fv-morphologie 1.2.0]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v1.2.0
[fv-morphologie 1.1.1]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v1.1.1
[fv-morphologie 1.1.0]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v1.1.0
[fv-morphologie 1.0.0]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v1.0.0
[fv-morphologie 0.2.0]: https://github.com/FredVoisin/fv-morphologie/releases/tag/v0.2.0
