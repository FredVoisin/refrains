# La documentation de refrains

*In English below.*

La documentation est écrite en français, version de référence, et traduite en
anglais. Pour commencer, lisez [refrains.fr.md](refrains.fr.md).

| Fichier | Contenu |
|---|---|
| [refrains.fr.md](refrains.fr.md) | La documentation : présentation, historique et cadre théorique, installation, menu, et la description de chaque fonction avec des exemples, section par section du menu ; références. |
| [refrains-fonctions.fr.md](refrains-fonctions.fr.md) | La liste des fonctions exportées, section par section du menu, avec leurs arguments et leur docstring ; les conventions de nommage ; les arbres des fonctions. |
| [exemples.md](exemples.md) | La liste des exemples d'utilisation, avec une courte description de chacun. |
| [exemples/](exemples/) | Les exemples, un par fichier. |
| [lisp/](lisp/README.md) | Les exemples écrits en Common Lisp, comme [refrains-trees.lisp](lisp/refrains-trees.lisp), qui calcule et dessine les arbres des fonctions. |
| [pictures/](pictures/) | Les figures de la documentation : l'arbre des opérations (`morpho-processes.png`), et les arbres et dendrogrammes des fonctions (`.png`), avec les fichiers dot dont ils sont tracés, produits par `lisp/refrains-trees.lisp`. |
| [LICENSE](LICENSE) | La licence de la documentation : CC BY 4.0. |

En anglais : [refrains.md](refrains.md), [refrains-functions.md](refrains-functions.md),
[examples.md](examples.md) et [examples/](examples/).

Dans Lisp, `(doc)` liste les fonctions, `(doc 'dist-edit)` affiche la
docstring d'une fonction, et `(help "distance")` cherche un mot dans les noms
et les docstrings.

La documentation, y compris les fichiers Lisp de `lisp/`, est placée sous
licence [Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE) ;
le code de refrains est placé sous licence GPL-3.0-only (voir le
[README](../README.md) du dépôt). Les évolutions sont décrites dans le
[CHANGELOG](../CHANGELOG.md).

---

# The documentation of refrains

The documentation is written in French, the reference version, and
translated into English. To begin, read [refrains.md](refrains.md).

| File | Content |
|---|---|
| [refrains.md](refrains.md) | The documentation: presentation, history and theoretical framework, installation, menu, and the description of each function with examples, section by section of the menu; references. |
| [refrains-functions.md](refrains-functions.md) | The list of the exported functions, section by section of the menu, with their arguments and docstrings; the naming conventions; the function trees. |
| [examples.md](examples.md) | The list of the examples of use, with a short description of each. |
| [examples/](examples/) | The examples, one per file. |
| [lisp/](lisp/README.md) | The examples written in Common Lisp, such as [refrains-trees.lisp](lisp/refrains-trees.lisp), which computes and draws the function trees. |
| [pictures/](pictures/) | The figures of the documentation: the tree of the operations (`morpho-processes.png`), and the trees and dendrograms of the functions (`.png`), with the dot files they are drawn from, made by `lisp/refrains-trees.lisp`. |
| [LICENSE](LICENSE) | The license of the documentation: CC BY 4.0. |

In French (reference): [refrains.fr.md](refrains.fr.md),
[refrains-fonctions.fr.md](refrains-fonctions.fr.md), [exemples.md](exemples.md)
and [exemples/](exemples/).

In Lisp, `(doc)` lists the functions, `(doc 'dist-edit)` prints the
docstring of a function, and `(help "distance")` looks for a word in the
names and docstrings.

The documentation, including the Lisp files of `lisp/`, is licensed under
[Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE); the
code of refrains is licensed under GPL-3.0-only (see the
[README](../README.md) of the repository). The changes are described in the
[CHANGELOG](../CHANGELOG.md).
