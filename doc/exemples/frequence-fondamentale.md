# Segmentation d'une fréquence fondamentale (F0)

[Exemples](../exemples.md) · In English: [Segmentation of a fundamental frequency (F0)](../examples/fundamental-frequency.md)

F. Voisin, 2010-2013.

*Analyse conservée avec ses données dans le dépôt [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) ; son principe est résumé ici, en attendant d'être réécrit sous forme d'exemple Common Lisp.*

Segmentation automatique d'une analyse de F0 réalisée avec Praat, selon un
écart temporel minimal entre segments. Seules les fonctions de lecture et
d'écriture de refrains sont nécessaires ; les segments peuvent être
exportés, par exemple sous forme de fichiers `coll` de Max
(`data/babil-chant-3-*.coll`, dans [data/](../data/README.md)), à partir de l'analyse
de F0 [data/babil-chant-3.pitch](../data/babil-chant-3.pitch).

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
