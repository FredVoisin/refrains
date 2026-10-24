# The function trees of refrains

[Examples](../examples.md) · En français : [Les arbres des fonctions de refrains](../exemples/arbres-des-fonctions.md)

Frédéric Voisin, 2015. See Voisin, Frédéric, "De la brousse dans les
synthés", in P. Criton & J.-M. Chouvel (eds.), *Gilles Deleuze : la
pensée-musique*, Paris, CDMC, 2015, pp. 231–240 (HAL
[hal-01611947](https://hal.science/hal-01611947v1)): the minimum spanning
tree of the verbs naming the operations of analysis
([figure](../pictures/morpho-processes.png)), whose method this example
applies to the functions of refrains.

A complete example in Common Lisp, which uses only functions of refrains:
[pictures/refrains-trees.lisp](../pictures/refrains-trees.lisp) links the
functions of refrains by their names (`dist-edit`) and by the vocabulary of
their documentation (`separate`, `histogram`, Jaccard distance), computes
their minimum spanning trees (`graph-span`) and dendrograms
(`graph-dendrogram`), and draws them (`graph>dot`, `dendrogram>dot`). The
images and the method are presented in the
[Function trees](../refrains-functions.md#function-trees).

```lisp
(load "doc/pictures/refrains-trees.lisp")
```

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
