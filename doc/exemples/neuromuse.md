# Arbres de réseaux de neurones

[Exemples](../exemples.md) · In English: [Trees of neural networks](../examples/neuromuse.md)

L'idée est ici d'appliquer refrains à l'étude de réseaux de neurones tels
que formalisés dans [neuromuse](https://github.com/FredVoisin/neuromuse), bibliothèque Common Lisp
de réseaux de neurones artificiels pour la musique. Ses réseaux sont déjà
des graphes : leur méthode `edges` donne les arcs `(source cible poids)`,
presque de la forme des graphes de refrains `(nœud-a nœud-b distance)`.
Cet exemple explore avec refrains un perceptron multicouche et une carte
auto-organisatrice. Le code est dans
[lisp/neuromuse-graphs.lisp](../lisp/neuromuse-graphs.lisp) ; les résultats
ci-dessous sont ceux de SBCL, avec les tirages aléatoires du script.

## Un perceptron multicouche appris sur le XOR

Un MLP à 2 entrées (I0, I1), 4 neurones cachés (H0 à H3) et une sortie (O0) a
appris le XOR (sorties 0,03, 0,98, 0,98, 0,02). Chaque poids devient une
distance, |poids maximal| / |poids| : 1 pour la connexion la plus forte, une
grande distance pour une connexion faible. Le signe des poids (excitation ou
inhibition) et le sens des arcs sont perdus.

- **Le squelette des connexions fortes** (`graph-span`) : H2–O0 (1,0), I0–H0
  (1,74), I1–H3 (1,77), H0–O0 (1,94), H3–O0 (1,98), H1–O0 (2,03).
- **La chaîne d'influence la plus forte** de I0 vers la sortie (`graph-path`,
  `dist-graph`) : I0, H0, O0, de longueur 3,68.
- **L'élagage** (`graph-degree`), en ne gardant que les connexions d'au moins
  un quart du poids maximal : H1 n'a plus qu'une connexion, il ne relaie plus
  rien et pourrait être supprimé.
- **La ressemblance des neurones cachés** d'après leurs poids d'entrée
  (`dist-euclidean`, `graph-dendrogram` avec le lien de Ward, justifié pour
  ces vecteurs) : H1 et H2 se ressemblent (7,94), puis H0 les rejoint (10,33) ;
  H3 reste à part (14,71).

![Squelette du MLP appris sur le XOR](../pictures/neuromuse-xor.png)

## Une carte auto-organisatrice apprise sur le chant du pinson

La carte de 12 × 12 neurones de l'exemple `pinson_som.lisp` de neuromuse
apprend les spectres (18 bandes de fréquence) de trois chants de pinson.

- **La topologie de la carte.** L'arbre de recouvrement minimal des prototypes
  (les poids de chaque neurone, comparés par `dist-euclidean`) a 143 arêtes,
  dont 120 relient des voisins sur la grille : la carte préserve bien la
  topologie de l'espace des sons.
- **Les suites de neurones gagnants.** Pour chaque trame d'un chant, le neurone
  gagnant donne un symbole : la carte transcrit le chant en suite de symboles,
  que refrains analyse. Une fois les répétitions locales retirées
  (`filt-repeat`), les trois chants donnent des suites de 757, 829 et 795
  gagnants, avec 87, 99 et 92 neurones différents, et une entropie de 5,6 à
  5,7 bits (`entropy`).
- **Les motifs** (`motif-list`) : les plus fréquents du premier chant sont des
  alternances entre deux neurones, (132 4), (11 4), (4 11), (0 132)…, la
  trace des trilles du pinson sur la carte.
- **La comparaison des chants** (`dist-edit` normalisée) : 0,72 à 0,73 entre
  les trois chants.

Le fichier `pinson_som.lisp` de neuromuse envisageait, pour comparer les
chants, « un DTW sur les séquences de gagnants ». La distance d'édition de
refrains joue ce rôle : comme le DTW, elle aligne par programmation dynamique
deux suites de longueurs et de tempos différents, avec un coût du même ordre
(une matrice de n × m cases). Elle compare cependant des symboles : chaque case
ne demande qu'un test d'égalité, là où un DTW sur les trames calculerait une
distance entre deux spectres de 18 bandes, et les différences de tempo sont
traitées par les insertions et les suppressions ; la suppression des
répétitions raccourcit en outre les suites (de 1 249 trames à 757 gagnants pour
le premier chant). En contrepartie, deux neurones voisins sur la carte y sont
aussi différents que deux neurones éloignés, alors qu'un DTW sur les gagnants
pourrait tenir compte de leur distance sur la grille.

![Arbre de recouvrement minimal des prototypes de la carte apprise sur le chant du pinson](../pictures/neuromuse-pinson.png)

Voir aussi [Comparer des réseaux de neurones](neuromuse-comparaison.md) :
plusieurs réseaux qui apprennent la même chose, comparés avant et après
l'apprentissage.

## Le code

Le code est la documentation.
[lisp/neuromuse-graphs.lisp](../lisp/neuromuse-graphs.lisp) demande les
systèmes neuromuse et refrains ; il se charge depuis le dossier du dépôt, affiche
les résultats et écrit ses images dans `doc/pictures/` :

```lisp
(load "doc/lisp/neuromuse-graphs.lisp")
```

<!-- code: doc/lisp/neuromuse-graphs.lisp -->
```lisp
;;;; neuromuse-graphs.lisp
;;;;
;;;; Les réseaux de neurones de neuromuse étudiés comme des graphes avec refrains :
;;;; 1. un perceptron multicouche (MLP) appris sur le XOR : squelette des connexions,
;;;;    chemin le plus fort, élagage, ressemblance des neurones cachés ;
;;;; 2. une carte auto-organisatrice (SOM) apprise sur le chant du pinson : topologie
;;;;    de la carte, et suites de neurones gagnants analysées comme des suites de
;;;;    symboles (distance d'édition, entropie, motifs).
;;;;
;;;; Demande les systèmes neuromuse (https://github.com/FredVoisin/neuromuse) et
;;;; refrains, trouvables par ASDF. (load "doc/lisp/neuromuse-graphs.lisp") affiche
;;;; les résultats et écrit, dans doc/pictures/, neuromuse-xor.dot/.png et
;;;; neuromuse-pinson.dot/.png. L'apprentissage de la SOM prend environ 20 secondes.
;;;;
;;;; Copyright (C) 2026 Frédéric Voisin
;;;;
;;;; Ce fichier, exemple de la documentation de refrains, est placé sous licence
;;;; Creative Commons Attribution 4.0 International (CC BY 4.0), comme la
;;;; documentation : voir ../LICENSE ou https://creativecommons.org/licenses/by/4.0/
;;;;
;;;; SPDX-License-Identifier: CC-BY-4.0

(asdf:load-system :neuromuse)
(asdf:load-system :refrains)
(in-package :neuromuse)

;; le dossier des images : doc/pictures/, à côté du dossier de ce fichier (doc/lisp/)
(defparameter *pictures*
  (merge-pathnames "pictures/" (uiop:pathname-parent-directory-pathname
                                (uiop:pathname-directory-pathname *load-truename*))))

(defun picture (name) (namestring (merge-pathnames name *pictures*)))

;; des tirages aléatoires reproductibles (poids initiaux, ordre de présentation)
(setf *random-state* #+sbcl (sb-ext:seed-random-state 7) #-sbcl (make-random-state t))

;;; 1. Un MLP appris sur le XOR : 2 entrées, 4 neurones cachés, 1 sortie

(make-mlp xor 2 1 4)

(let ((inputs '((0 0) (1 0) (0 1) (1 1)))
      (goals '((0) (1) (1) (0))))
  (setf (learn-fact xor) .5 (verbose xor) nil)
  (loop repeat 20000
        do (loop for i in inputs for g in goals
                 do (setf (input xor) i (goal xor) g) (learn xor)))
  (format t "~&XOR : ~{~,2F~^ ~}~%"
          (loop for i in inputs
                collect (progn (setf (input xor) i) (run-mlp xor) (car (output xor))))))

;; EDGES (neuromuse) donne les arcs (source cible poids), les noeuds étant notés
;; (couche indice). Pour refrains, les noeuds sont nommés I0, H2, O0... (une liste
;; serait prise pour une liste de noeuds par graph-degree ou graph-path), et chaque
;; poids devient une distance : |poids maximal| / |poids|, 1 pour la connexion la plus
;; forte. Le signe du poids (excitation ou inhibition) et le sens des arcs sont perdus.

(defun node-name (node)
  (format nil "~A~D" (case (first node) (0 "I") (1 "H") (t "O")) (second node)))

(defparameter *weights*
  (mapcar (lambda (e) (list (node-name (first e)) (node-name (second e)) (third e)))
          (edges xor)))

(defparameter *w-max* (reduce #'max *weights* :key (lambda (e) (abs (third e)))))

(defparameter *xor-graph*
  (mapcar (lambda (e)
            (list (first e) (second e)
                  (/ (round (* 100 (/ *w-max* (max 1e-6 (abs (third e)))))) 100.0)))
          *weights*))

;; le squelette des connexions fortes : l'arbre de recouvrement minimal
(format t "~&squelette : ~S~%" (refrains:graph-span *xor-graph*))

;; la chaîne d'influence la plus forte d'une entrée vers la sortie
(format t "~&de I0 à O0 : ~S, longueur ~S~%"
        (refrains:graph-path "I0" "O0" *xor-graph*)
        (refrains:dist-graph "I0" "O0" *xor-graph*))

;; élagage : on ne garde que les connexions d'au moins un quart du poids maximal ;
;; un neurone qui n'a plus qu'une connexion ne relaie plus rien
(let ((strong (remove-if (lambda (e) (> (third e) 4)) *xor-graph*)))
  (format t "~&après élagage : ~{~{~A ~D~}~^, ~}~%"
          (mapcar #'list (refrains:graph-nodes strong) (refrains:graph-degree nil strong))))

;; la ressemblance des neurones cachés, d'après leurs poids d'entrée (des vecteurs
;; euclidiens : le lien de Ward y est justifié)
(format t "~&neurones cachés (Ward) : ~S~%"
        (nth-value 1 (refrains:graph-dendrogram
                      (refrains:dist-euclidean (first (net xor)) nil) :linkage :ward)))

;; le dessin du squelette (le graphe complet, avec ses connexions presque nulles et
;; donc très longues, serait illisible)
(refrains:graph>dot (refrains:graph-span *xor-graph*) :out (picture "neuromuse-xor.png") :invert t)

;;; 2. Une SOM apprise sur le chant du pinson : 12 x 12 neurones, 18 bandes de fréquence

(let ((*standard-output* (make-broadcast-stream))
      (examples (asdf:system-relative-pathname :neuromuse "examples/")))
  (load (merge-pathnames "pinson_vecteurs.lisp" examples))
  (load (merge-pathnames "pinson_som.lisp" examples)))

(train-pinson-som :epochs 10)

;; la topologie : l'arbre de recouvrement minimal des prototypes (les poids de chaque
;; neurone), comparé à la grille ; plus ses arêtes relient des voisins de la grille,
;; mieux la carte préserve la topologie de l'espace des sons
(defparameter *prototypes*
  (mapcar (lambda (neuron) (mapcar #'third (edges neuron))) (net pinson-som)))

(defparameter *prototypes-tree*
  (refrains:graph-span (refrains:dist-euclidean *prototypes* nil)))

(let ((grid (grid-neighbour-pairs pinson-som)))
  (format t "~&arbre des prototypes : ~D arêtes, dont ~D entre voisins de la grille~%"
          (length *prototypes-tree*)
          (count-if (lambda (e) (member (list (min (first e) (second e)) (max (first e) (second e)))
                                        grid :test #'equal))
                    *prototypes-tree*)))

(refrains:graph>dot *prototypes-tree* :out (picture "neuromuse-pinson.png")
                    :overlap nil :invert t :legend nil)

;; les suites de neurones gagnants de chaque chant, sans les répétitions locales :
;; la SOM transcrit le son en suites de symboles, que refrains compare et analyse
(defparameter *winners*
  (mapcar (lambda (chant) (refrains:filt-repeat (winner-sequence chant))) *pinson-chants*))

(format t "~&gagnants : ~{~D~^, ~} ; début du chant 1 : ~S~%"
        (mapcar #'length *winners*) (subseq (first *winners*) 0 20))

;; la distance d'édition compare des suites de longueurs et de tempos différents :
;; c'est le DTW sur les suites de gagnants qu'envisageait pinson_som.lisp
(format t "~&distances d'édition normalisées : 1-2 ~,2F, 1-3 ~,2F, 2-3 ~,2F~%"
        (refrains:dist-edit (first *winners*) (second *winners*) :norm t)
        (refrains:dist-edit (first *winners*) (third *winners*) :norm t)
        (refrains:dist-edit (second *winners*) (third *winners*) :norm t))

(format t "~&entropie (bits) : ~{~,2F~^, ~} ; neurones gagnants : ~{~D~^, ~}~%"
        (mapcar #'refrains:entropy *winners*)
        (mapcar (lambda (s) (length (remove-duplicates s))) *winners*))

;; les motifs les plus fréquents du premier chant, de 2 à 4 gagnants
(format t "~&motifs du chant 1 : ~{~S~^ ~}~%"
        (mapcar #'first (subseq (refrains:motif-list (first *winners*) :freq :n '(2 4)) 0 6)))
```
<!-- /code -->

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
