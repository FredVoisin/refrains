# Les arbres des fonctions de refrains

[Exemples](../exemples.md) · In English: [The function trees of refrains](../examples/function-trees.md)

Frédéric Voisin, 2015. Voir Voisin, Frédéric, « De la brousse dans les
synthés », in P. Criton & J.-M. Chouvel (éd.), *Gilles Deleuze : la
pensée-musique*, Paris, CDMC, 2015, p. 231–240 (HAL
[hal-01611947](https://hal.science/hal-01611947v1)) : l'arbre de
recouvrement minimal des verbes qui nomment les opérations d'analyse
([figure](../pictures/morpho-processes.png)), dont cet exemple applique la
méthode aux fonctions de refrains.

Un exemple complet en Common Lisp, qui n'utilise que des fonctions de
refrains : [pictures/refrains-trees.lisp](../pictures/refrains-trees.lisp)
relie les fonctions de refrains d'après leurs noms (`dist-edit`) et d'après
le vocabulaire de leur documentation (`separate`, `histogram`, distance de
Jaccard), en calcule les arbres de recouvrement minimal (`graph-span`) et
les dendrogrammes (`graph-dendrogram`), et les dessine (`graph>dot`,
`dendrogram>dot`). Les images et la méthode sont présentées dans les
[Arbres des fonctions](../refrains-fonctions.fr.md#arbres-des-fonctions).

```lisp
(load "doc/pictures/refrains-trees.lisp")
```

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
