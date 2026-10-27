# Délinéations : représentation rhizomatique d'un texte

[Exemples](../exemples.md) · In English: [Delineations: rhizomatic representation of a text](../examples/delineations.md)

F. Voisin, octobre 2026 (2013). Script : [lisp/delineations.lisp](../lisp/delineations.lisp).

*Analyse conservée avec ses données dans le dépôt [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) ; elle est réécrite ici en Common Lisp, et appliquée à* Alice's Adventures in Wonderland *de Lewis Carroll.*

Un texte est réduit à ses mots, et les mots sont reliés selon leur ressemblance
d'écriture : l'arbre de recouvrement minimal de leurs distances d'édition en
donne une représentation *rhizomatique*, où les mots voisins s'écrivent de façon
semblable, sans rien savoir de leur sens ni de leur place dans le texte.

L'arbre d'un extrait de *Différence et répétition* de Gilles Deleuze, calculé
par cette méthode, a été publié dans Frédéric Voisin, « De la brousse dans les
synthés », dans Pascale Criton et Jean-Marc Chouvel (dir.), *Gilles Deleuze : la
pensée-musique*, Paris, CDMC, 2015, p. 231–240 (HAL
[hal-01611947](https://hal.science/hal-01611947v1)).

## La méthode

1. Un texte (ASCII 7 bits) est lu dans une liste de mots avec `read-text`,
   toute la ponctuation servant de séparateur (`:sep`) et les mots de moins
   de quatre lettres étant supprimés (`:rem-test`). Ici, les mots sont aussi mis
   en minuscules : « Alice » et « ALICE » sont le même mot.
2. Les mots répétés sont supprimés ; les mots qui diffèrent d'au plus un
   caractère sont considérés comme identiques, la distance d'édition servant
   de test à `remove-duplicates`. Le premier rencontré dans le texte est gardé.
3. La semi-matrice des distances d'édition entre les mots donne l'arbre de
   recouvrement minimal (`graph-span`). `:uncom` maximise la distance entre
   des mots aux caractères non communs, dans l'espoir de rapprocher les mots
   de même racine (ici `:uncom 1`).
4. `graph>dot` trace l'arbre avec neato.

## Alice au pays des merveilles

Le texte, [data/Alice.txt](../data/Alice.txt) (*The Millennium Fulcrum
Edition 2.9*, domaine public), compte 14 152 mots de quatre lettres ou plus,
2 352 distincts, et 1 754 après la fusion des mots à un caractère près. La
fusion garde le premier mot rencontré : « queen » devient « queer »,
« hatter » « matter », et « mouse » « house ». Le livre entier se calcule en une
dizaine de secondes (la semi-matrice de 1,5 million de distances en 5 s,
l'arbre en moins d'une seconde), et son dessin par neato en sept secondes.

Les arêtes de l'arbre mesurent de 2 à 13 (la distance d'édition, augmentée de
1 pour chaque substitution d'une lettre que l'autre mot n'a pas) ; la plupart
mesurent 4 ou 5. Les nœuds de plus haut degré sont des mots courts et
ordinaires, auxquels beaucoup d'autres ressemblent : *late* (16 voisins),
*going* (14), *nice* (10), *burning*, *hear*, *peeped*, *seen* (9).

L'arbre du livre entier, à agrandir :
[pictures/delineations-alice.svg](../pictures/delineations-alice.svg).

L'arbre du chapitre I (*Down the Rabbit-Hole*, 1 113 mots, 419 distincts) :

![Délinéation du chapitre I d'Alice](../pictures/delineations-alice-ch1.png)

Un chemin dans l'arbre (`graph-path`) passe d'un mot à l'autre par des
ressemblances d'écriture, à la manière d'une chaîne de jeux de mots :

- de *rabbit* à *queer* (*queen*) : rabbit — brain — bring — grin — going —
  king — making — asking — shaking — shining — singing — sitting — strings —
  things — this — sits — suit — quite — quiver — queer ;
- d'*alice* à *turtle* : alice — nice — once — ones — seen — lessen — less —
  else — tells — tales — teases — taste — past — salt — shall — seals — ears —
  hear — hers — there — three — true — turtle.

## Variantes et références

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

## Le code

Le code est la documentation. [lisp/delineations.lisp](../lisp/delineations.lisp)
se charge depuis le dossier du dépôt, et dessine les arbres avec `neato`
([Graphviz](https://graphviz.org/)) :

```lisp
(load "doc/lisp/delineations.lisp")
```

<!-- code: doc/lisp/delineations.lisp -->
```lisp
;;;; delineations.lisp
;;;;
;;;; Délinéations : représentation rhizomatique d'un texte (F. Voisin, 2013), appliquée à
;;;; Alice's Adventures in Wonderland de Lewis Carroll (doc/data/Alice.txt, domaine public).
;;;; Les mots du texte, réduits à leurs formes distinctes, sont reliés par leur distance
;;;; d'édition : l'arbre de recouvrement minimal de ces distances rapproche les mots qui
;;;; s'écrivent de façon semblable, sans rien savoir de leur sens.
;;;;
;;;; (load "doc/lisp/delineations.lisp") affiche les étapes et dessine les arbres avec neato
;;;; (Graphviz) : doc/pictures/delineations-alice.svg (tout le livre) et
;;;; doc/pictures/delineations-alice-ch1.png (le chapitre I).
;;;;
;;;; Copyright (C) 2026 Frédéric Voisin
;;;;
;;;; Ce fichier, exemple de la documentation de refrains, est placé sous licence
;;;; Creative Commons Attribution 4.0 International (CC BY 4.0), comme la
;;;; documentation : voir ../LICENSE ou https://creativecommons.org/licenses/by/4.0/
;;;;
;;;; SPDX-License-Identifier: CC-BY-4.0

(asdf:load-system :refrains)
(in-package :refrains)

(defparameter *doc*
  (uiop:pathname-parent-directory-pathname (uiop:pathname-directory-pathname *load-truename*)))

;;; 1. La lecture : read-text en mode plat (nil) donne la liste des mots du texte, toute la
;;; ponctuation servant de séparateur (:sep t), et les mots de moins de quatre lettres
;;; supprimés (:rem-test). Les mots sont mis en minuscules : « Alice » et « ALICE » sont le
;;; même mot.

(defparameter *mots*
  (mapcar #'string-downcase
          (read-text (merge-pathnames "data/Alice.txt" *doc*)
                     :mode nil :sep t :rem-test (lambda (w) (< (length w) 4)))))

;;; 2. Les mots distincts : les répétitions supprimées, puis les mots qui diffèrent d'au plus
;;; un caractère tenus pour identiques, la distance d'édition servant de test à
;;; remove-duplicates. Le premier mot rencontré dans le texte est gardé (:from-end t).

(defun distincts (mots)
  (remove-duplicates (remove-duplicates mots :test #'string= :from-end t)
                     :test (lambda (a b) (<= (dist-edit a b) 1))
                     :from-end t))

;;; 3. L'arbre : la semi-matrice des distances d'édition entre les mots, dont graph-span
;;; garde l'arbre de recouvrement minimal. :uncom 1 ajoute 1 au coût de la substitution
;;; d'un caractère qui n'est pas commun aux deux mots : il éloigne les mots faits de lettres
;;; différentes, dans l'espoir de rapprocher les mots de même racine. dist-edit numérote les
;;; mots ; les nœuds de l'arbre sont les mots eux-mêmes.

(defun arbre (mots)
  (let ((v (coerce mots 'vector)))
    (mapcar (lambda (e) (list (aref v (first e)) (aref v (second e)) (third e)))
            (graph-span (dist-edit mots nil :uncom 1)))))

;; le chapitre I : les mots du premier « chapter » au suivant
(defun chapitre-1 (mots)
  (let ((debut (position "chapter" mots :test #'string=)))
    (subseq mots debut (position "chapter" mots :test #'string= :start (1+ debut)))))

;;; 4. Le livre entier, puis le chapitre I

(defun delineation (nom mots fichier &rest options)
  (let* ((d (distincts mots))
         (a (arbre d)))
    (format t "~&~%~A : ~D mots, ~D distincts, ~D après la fusion des mots à un caractère près~%"
            nom (length mots) (length (remove-duplicates mots :test #'string=)) (length d))
    (format t "longueurs des arêtes (longueur, nombre) : ~S~%"
            (sort (histogram (mapcar #'third a)) #'< :key #'first))
    (format t "les nœuds de plus haut degré : ~{~{~A (~D)~}~^, ~}~%"
            (mapcar (lambda (x) (list (second x) (first x)))
                    (subseq (stable-sort (mapcar (lambda (n) (list (graph-degree n a) n)) (graph-nodes a))
                                         #'> :key #'first)
                            0 8)))
    (apply #'graph>dot a :out (merge-pathnames fichier *doc*) options)
    (format t "dessin : doc/~A~%" fichier)
    a))

(defparameter *livre*
  (delineation "Le livre" *mots* "pictures/delineations-alice.svg" :shape "plaintext" :legend nil))

(defparameter *chapitre-1*
  (delineation "Le chapitre I" (chapitre-1 *mots*) "pictures/delineations-alice-ch1.png"
               :shape "plaintext" :legend nil :overlap nil))

;;; 5. Un chemin dans l'arbre du livre : de mot en mot, par les ressemblances d'écriture

;; « queen » n'est pas dans l'arbre : à un caractère de « queer », rencontré avant lui dans le
;; texte, il a été fusionné avec lui (comme « hatter » avec « matter », « mouse » avec « house »)
(format t "~&~%De « rabbit » à « queer » (queen) : ~{~A~^ — ~}~%" (graph-path "rabbit" "queer" *livre*))
(format t "De « alice » à « turtle » : ~{~A~^ — ~}~%" (graph-path "alice" "turtle" *livre*))
```
<!-- /code -->

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
