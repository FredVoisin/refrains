# Changelog

All notable changes to refrains are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the versions
follow [Semantic Versioning](https://semver.org/).

refrains continues [fv-morphologie](https://github.com/FredVoisin/fv-morphologie):
refrains 0.0.1 starts from fv-morphologie 1.4.0, and the versions below it
(fv-morphologie 1.4.0 to 0.1.0) are those of fv-morphologie.

## [0.2.1] - 2026-10-24

### Added

- `graph>dot` takes `:overlap`: `t` (by default) lets the nodes overlap, as
  before; `nil` makes neato move them apart (graph attribute
  `overlap=false`), useful when the lengths are short compared with the
  names of the nodes, such as distances from 0 to 1; a string is the value
  of the Graphviz `overlap` attribute (`"scale"`, `"prism"`…).
- `graph>dot` takes `:invert`: `t` draws white on black instead of black on
  white (`nil` by default).
- `dendrogram>dot (dendrogram out &key width step invert)`: draws a
  dendrogram of `graph>dendrogram`, or a list of them, in dot with the
  position of each point, for `neato -n2`: the leaves on the left, each
  fusion at the abscissa of its distance, and a scale of the distances.
- Documentation: two minimum spanning trees of the functions, by their names
  and by the vocabulary of their docstrings, computed with refrains by
  `doc/pictures/refrains-trees.lisp` (which uses `:overlap nil` and
  `:invert t`), with their dendrograms (`graph>dendrogram` and
  `dendrogram>dot`), and the figure
  of the operations, in white on black; what to do
  when the system "refrains" is not found.

### Changed

- `date-string` and `date+time-string` are merged into
  `date-string (&optional time u)`: the date of the universal time `u` (now
  by default), such as `"22 Oct 2026"`, or with `time` true the date and
  time, such as `"22 Oct 2026 14:05:09"`; `(date+time-string)` is
  `(date-string t)`.
- The dot files of `graph>dot` and `dendrogram>dot` are dated with
  `date-string`, such as `22 Oct 2026 14:05:09` (it was
  `2026 october twenty-second at 14h5`).

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
