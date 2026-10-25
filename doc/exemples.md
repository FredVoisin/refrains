# refrains : exemples

In English, see: [examples.md](examples.md)

Des exemples d'utilisation de refrains, un par fichier. La documentation de chaque fonction est dans [refrains.fr.md](refrains.fr.md), et la liste des fonctions dans [refrains-fonctions.fr.md](refrains-fonctions.fr.md).

- [Arbres de refrains](exemples/arbres-des-fonctions.md) : les fonctions de refrains reliées par leurs noms et par le vocabulaire de leur documentation, en arbres de recouvrement minimal et en dendrogrammes (en Common Lisp).
- [Arbres de réseaux de neurones](exemples/neuromuse.md) : analyse d'un perceptron multicouche et d'une carte auto-organisatrice de [neuromuse](https://github.com/FredVoisin/neuromuse) étudiés avec refrains : squelette des connexions, ressemblance des neurones, topologie de la carte, et suites de neurones gagnants d'un chant de pinson comparées par distance d'édition (en Common Lisp).
- [Comparer des réseaux de neurones](exemples/neuromuse-comparaison.md) : six perceptrons multicouches et trois cartes auto-organisatrices de [neuromuse](https://github.com/FredVoisin/neuromuse) apprennent la même chose à partir de tirages différents, comparés avant et après l'apprentissage par ce qui ne dépend pas de la numérotation de leurs neurones : géométrie de la couche cachée, rôles des neurones, topologie et segmentation du chant (en Common Lisp).
- [Délinéations : représentation rhizomatique d'un texte](exemples/delineations.md) (F. Voisin, 2013) : l'arbre de recouvrement minimal des mots d'un texte, selon leur distance d'édition (`graph-span`, `graph>dot`).
- [Transcription automatique d'un sonagramme : le rougequeue noir](exemples/rougequeue-noir.md) (F. Voisin, JIM 2011, Saint-Étienne) : transcrire le chant d'un oiseau en classant les spectres instantanés d'un sonagramme lu comme une image (`class-sym`).
- [Analyse contrastive : marques et ressemblance](exemples/analyse-contrastive.md) (F. Voisin, 2010) : traiter comme un seul motif des segments proches en distance d'édition (`mark-list`).
- [Quantification](exemples/quantification.md) (F. Voisin, 2010) : quantifier un flux sur ses propres centres d'attraction (`class-num`).
- [Segmentation d'une fréquence fondamentale (F0)](exemples/frequence-fondamentale.md) (F. Voisin, 2010-2013) : découper une analyse de fréquence fondamentale (F0) en segments, exportés pour Max.
- [Classification, quantification et entropie : *Zoboko*](exemples/zoboko.md) (F. Voisin, 2009) : dans la partie rythmique d'une pièce des Aka de Centrafrique, le seuil d'intensité qui donne la structure la plus cohérente (`class-num`, `entropy`).

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE).
