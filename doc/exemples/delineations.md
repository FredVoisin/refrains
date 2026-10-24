# Délinéations : représentation rhizomatique d'un texte

[Exemples](../exemples.md) · In English: [Delineations: rhizomatic representation of a text](../examples/delineations.md)

F. Voisin, 2013.

*Analyse conservée avec ses données dans le dépôt [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) ; son principe est résumé ici, en attendant d'être réécrit sous forme d'exemple Common Lisp.*

1. Un texte (ASCII 7 bits) est lu dans une liste de mots avec `read-text`,
   toute la ponctuation servant de séparateur (`:sep`) et les mots de moins
   de quatre lettres étant supprimés (`:rem-test`).
2. Les mots répétés sont supprimés ; les mots qui diffèrent d'au plus un
   caractère sont considérés comme identiques, la distance d'édition servant
   de test à `remove-duplicates`.
3. La semi-matrice des distances d'édition entre les mots donne l'arbre de
   recouvrement minimal (`graph-span`). `:uncom` maximise la distance entre
   des mots aux caractères non communs, dans l'espoir de rapprocher les mots
   de même racine.
4. `graph>dot` trace l'arbre avec neato.

Variantes : distances d'édition normalisées, avec une mise à l'échelle
logarithmique des distances ; somme de la distance d'édition et de la
distance entre les fréquences des mots (« la somme de deux distances est une
distance — le produit de deux distances est-il une distance ? »). Pour les
grands graphes, préférez le format svg. Le calcul de l'arbre de recouvrement
peut prendre de quelques secondes à plusieurs heures selon le nombre
d'éléments (environ 12 heures pour les
[« Délinéations différentielles »](https://fredvoisin.com/articles/220-delineations-differentielles.html), 2013).
Données : [data/Alice.txt](../data/Alice.txt) (Lewis Carroll, domaine public), et deux textes
protégés, conservés dans le dépôt fv-morphologie et non couverts par la licence de
refrains : un extrait de Gilles Deleuze, *Différence et répétition*
([Difference&Repetition-utf8.txt](https://github.com/FredVoisin/fv-morphologie/blob/master/pwgl-legacy/tutorial/5.%20FV-exemples/data/Difference%26Repetition-utf8.txt)), et une citation
d'Arcadi et Boris Strougatski, *Pique-nique au bord du chemin*
([Stalker.txt](https://github.com/FredVoisin/fv-morphologie/blob/master/pwgl-legacy/tutorial/5.%20FV-exemples/data/Stalker.txt)).

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
