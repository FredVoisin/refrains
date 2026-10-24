# refrains

Experimental Common Lisp tools for the morphological analysis of musical transcriptions and other symbolic sequences: segmentation, motif search, classification, and measures of repetition and difference.

Continuation of [fv-morphologie](https://github.com/FredVoisin/fv-morphologie), without its PWGL legacy, itself an
analysis-oriented branch of the legacy library [Morphologie](https://github.com/openmusic-project/Morphologie) for OpenMusic (Ircam)
and PWGL (Mikael Laurson, Sibelius Academy).


## Documentation

- Documentation: [English](doc/refrains.md),
  [français](doc/refrains.fr.md) (reference version).
- The 54 exported functions, with their arguments and docstrings:
  [English](doc/refrains-functions.md),
  [français](doc/refrains-fonctions.fr.md).
- Changes between versions: [CHANGELOG.md](CHANGELOG.md).
- The PWGL tutorial and bindings are kept in the
  [`pwgl-legacy/`](https://github.com/FredVoisin/fv-morphologie/tree/master/pwgl-legacy) directory of fv-morphologie.

In Lisp, `(doc)` lists the functions, `(doc 'dist-edit)` prints the docstring
of a function, and `(help "distance")` looks for a keyword in the names and
docstrings.

## Loading (Common Lisp)

refrains has no dependency besides ASDF/UIOP, which come with every
modern Common Lisp implementation.

### With Quicklisp

Clone the repository into Quicklisp's `local-projects` directory (or symlink
it there), then quickload it:

```sh
cd ~/quicklisp/local-projects/
git clone https://github.com/FredVoisin/refrains.git
```

```lisp
(ql:quickload :refrains)
(in-package :refrains)
(help)
```

If the system is not found after cloning, run `(ql:register-local-projects)`
once.

The public functions are exported, so they can also be used from another
package, e.g. `(refrains:dist-edit '(a b c) '(a c))`, or with
`(:use :cl :refrains)` in your own `defpackage`.

### With ASDF only

Put (or symlink) the project directory in a place ASDF looks into, such as
`~/common-lisp/`, then:

```lisp
(asdf:load-system :refrains)
```

### In your own system

```lisp
(asdf:defsystem :my-project
  :depends-on (:refrains)
  ...)
```

`graph>dot` needs Graphviz (`neato`) to produce `.png`/`.gif` output.

## Source layout

- `src/`: the implementation, one file per domain: `utils`, `encoding`,
  `filters`, `signature`, `distances`, `marks`, `motifs`, `graphs`, `dot`
  (Graphviz output), `classification`, `information`, `interpolation`, `io`.
- `src/api/`: the public functions, by section of the menu:
  `transcription`, `classification`, `evaluation`, `files`, and `help`
  (the menu, `doc` and `help`).
- `tests/`: one test file per domain.

## Testing

The tests live in `tests/` and use [FiveAM](https://github.com/lispci/fiveam).
FiveAM is used only for testing the code: `refrains` itself does not
depend on it, only the `refrains/tests` system does.

```lisp
(ql:quickload :refrains/tests)  ; fetches FiveAM if needed
(asdf:test-system :refrains)
```

## License

Copyright (C) 1992-2026 Frederic Voisin.

refrains is derived from [fv-morphologie](https://github.com/FredVoisin/fv-morphologie), itself derived from
[Morphologie](https://github.com/openmusic-project/Morphologie), released
under GPL-3.0.

- **Code** (`.lisp` and `.asd` files): GNU General Public License,
  version 3 only (GPL-3.0-only), see [LICENSE](LICENSE).
- **Documentation** (`doc/`): Creative Commons Attribution 4.0 International
  (CC BY 4.0), see [doc/LICENSE](doc/LICENSE).
