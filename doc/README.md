# Documentation de refrains

*In English below.*

La documentation est principalement écrite en français et traduite en anglais.
Pour commencer, voir : [refrains.fr.md](refrains.fr.md).

| Fichier | Contenu |
|---|---|
| [refrains.fr.md](refrains.fr.md) | La documentation générale : présentation, historique et cadre théorique, installation, menu, et la description de chaque fonction avec des exemples, section par section du menu ; références. |
| [refrains-fonctions.fr.md](refrains-fonctions.fr.md) | La liste des fonctions exportées, section par section du menu, avec leurs arguments et leur docstring, les conventions de nommage, les arbres des fonctions. |
| [exemples.md](exemples.md) | Liste d'exemples d'utilisation, avec une courte description de chacun. |
| [exemples/](exemples/) | Dossier des exemples, un par fichier. |
| [lisp/](lisp/README.md) | Exemples en Common Lisp documenté, comme pour [refrains-trees.lisp](lisp/refrains-trees.lisp). |
| [data/](data/README.md) | Les données des exemples : mesures, sonagramme, analyses de F0 et un texte du domaine public. |
| [pictures/](pictures/) | Figures de la documentation : l'arbre des opérations (`morpho-processes.png`), et les arbres et dendrogrammes des fonctions (`.png`), avec les fichiers dot dont ils sont tracés, produits par `lisp/refrains-trees.lisp`. |
| [LICENSE](LICENSE) | La licence de la documentation : CC BY 4.0. |

Dans Lisp, `(doc)` liste les fonctions, `(doc 'dist-edit)` affiche la
docstring d'une fonction, et `(help "distance")` cherche un mot dans les noms
et les docstrings.

La documentation, y compris les fichiers Lisp de `lisp/` et les données de
`data/` (sauf un texte du domaine public), est placée sous
licence [Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE) ;
le code de refrains est placé sous licence GPL-3.0-only (voir le
[README](../README.md) du dépôt). Les évolutions sont décrites dans le
[CHANGELOG](../CHANGELOG.md).

En anglais : [refrains.md](refrains.md), [refrains-functions.md](refrains-functions.md),
[examples.md](examples.md) et [examples/](examples/).

---

# The documentation of refrains

The documentation is mainly written in French, the reference version, and
translated into English. To begin, read [refrains.md](refrains.md).

| File | Content |
|---|---|
| [refrains.md](refrains.md) | The documentation: presentation, history and theoretical framework, installation, menu, and the description of each function with examples, section by section of the menu; references. |
| [refrains-functions.md](refrains-functions.md) | The list of the exported functions, section by section of the menu, with their arguments and docstrings; the naming conventions; the function trees. |
| [examples.md](examples.md) | The list of the examples of use, with a short description of each. |
| [examples/](examples/) | The examples, one per file. |
| [lisp/](lisp/README.md) | The examples written in Common Lisp, such as [refrains-trees.lisp](lisp/refrains-trees.lisp), which computes and draws the function trees. |
| [data/](data/README.md) | The data of the examples: measures, sonogram, F0 analyses and a public-domain text. |
| [pictures/](pictures/) | The figures of the documentation: the tree of the operations (`morpho-processes.png`), and the trees and dendrograms of the functions (`.png`), with the dot files they are drawn from, made by `lisp/refrains-trees.lisp`. |
| [LICENSE](LICENSE) | The license of the documentation: CC BY 4.0. |

In French (reference): [refrains.fr.md](refrains.fr.md),
[refrains-fonctions.fr.md](refrains-fonctions.fr.md), [exemples.md](exemples.md)
and [exemples/](exemples/).

In Lisp, `(doc)` lists the functions, `(doc 'dist-edit)` prints the
docstring of a function, and `(help "distance")` looks for a word in the
names and docstrings.

The documentation, including the Lisp files of `lisp/` and the data of
`data/` (except a public-domain text), is licensed under
[Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE); the
code of refrains is licensed under GPL-3.0-only (see the
[README](../README.md) of the repository). The changes are described in the
[CHANGELOG](../CHANGELOG.md).
