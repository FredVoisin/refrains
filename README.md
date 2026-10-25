# refrains

Experimental Common Lisp tools for the morphological analysis of musical transcriptions and other symbolic sequences: segmentation, motif search, classification, and measures of repetition and difference.

Continuation of [fv-morphologie](https://github.com/FredVoisin/fv-morphologie), itself an
analysis-oriented branch of the legacy library [Morphologie](https://github.com/openmusic-project/Morphologie) for OpenMusic (Ircam)
and PWGL (Mikael Laurson, Sibelius Academy).


## Documentation

- The files of the documentation are presented in [doc/README.md](doc/README.md).
- Documentation: [English](doc/refrains.md),
  [français](doc/refrains.fr.md) (reference version).
- The 53 exported functions, with their arguments and docstrings:
  [English](doc/refrains-functions.md),
  [français](doc/refrains-fonctions.fr.md).
- Examples of use: [English](doc/examples.md),
  [français](doc/exemples.md).
- Changes between versions: [CHANGELOG.md](CHANGELOG.md).

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

To keep the clone elsewhere, symlink it with an absolute path (a relative
target such as `ln -s refrains` makes a link that points to itself):

```sh
ln -s /path/to/refrains ~/quicklisp/local-projects/refrains
```

```lisp
(ql:quickload :refrains)
(in-package :refrains)
(help)
```

### If the system "refrains" is not found

`System "refrains" not found` means that ASDF cannot find `refrains.asd`:

1. Check the link: `ls -l ~/quicklisp/local-projects/refrains` must point
   to the directory that holds `refrains.asd`. If it points to itself
   (`refrains -> refrains`), remove it and recreate it with an absolute
   path, as above.
2. Rebuild Quicklisp's index of local projects, then load again:

   ```lisp
   (ql:register-local-projects)
   (ql:quickload :refrains)
   ```

   `~/quicklisp/local-projects/system-index.txt` must then list
   `refrains/refrains.asd`.
3. In Emacs/SLIME (or Sly), a Lisp already running may keep the previous
   search: evaluate the forms above in its REPL, or restart it
   (`M-x slime-restart-inferior-lisp`).

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

- **Code** (`.lisp` and `.asd` files, except in `doc/`): GNU General Public
  License, version 3 only (GPL-3.0-only), see [LICENSE](LICENSE).
- **Documentation** (`doc/`): Creative Commons Attribution 4.0 International
  (CC BY 4.0), see [doc/LICENSE](doc/LICENSE). This includes every Lisp
  file of `doc/lisp/`, the examples of the documentation (such as
  `refrains-trees.lisp`, which draws the function trees), and the data of
  the examples in `doc/data/` (except `Alice.txt`, in the public domain).
