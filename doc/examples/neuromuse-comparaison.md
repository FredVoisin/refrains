# Comparing neural networks

[Examples](../examples.md) · En français : [Comparer des réseaux de neurones](../exemples/neuromuse-comparaison.md)

Several networks of [neuromuse](https://github.com/FredVoisin/neuromuse)
learn the same thing from different random draws: do they learn in the same
way? This example compares them with refrains, before and after learning,
after [Trees of neural networks](neuromuse.md). The code is in
[lisp/neuromuse-comparaison.lisp](../lisp/neuromuse-comparaison.lisp); the
results below are those of SBCL, with the draws of the script.

Two networks trained from different draws do not number their neurons the
same way: the hidden neurons of a multilayer perceptron can be permuted
without changing what it computes, and two self-organizing maps place the
same sounds in different places. Comparing them weight by weight, or neuron
by neuron, would make no sense. They are compared by what does not depend on
this numbering.

## Six multilayer perceptrons trained on XOR

Six MLPs (2 inputs, 4 hidden neurons, 1 output) start from six different
draws; all of them learn XOR (outputs 0.02, 0.98, 0.98, 0.01 to 0.02).

**The geometry of the hidden layer.** For each network, the four inputs of
XOR give four activation vectors of the hidden layer; their six distances
(`dist-euclidean`) describe how the network separates the inputs, whatever
the order of its neurons. The distances between these geometries, for the
six networks before and after learning, give a dendrogram
(`graph-dendrogram`, average linkage; `dendrogram>dot`):

![Dendrogram of the six MLPs before and after learning XOR](../pictures/neuromuse-comparaison.png)

The initial networks and the trained networks form two clearly separated
groups (2.29). The trained networks are much more alike than the initial
ones: 1, 2 and 6 are almost identical (0.01 to 0.04), network 4 is the most
different (0.33). Starting from different draws, they converge towards a same
way of separating the inputs.

**The role of the hidden neurons.** The profile of a hidden neuron is its
activation for each of the four inputs, (0,0), (1,0), (0,1) and (1,1): 1 if it
is clearly active (above 0.8), 0 if it is off (below 0.2), `-` if it is
undecided. `histogram` counts these profiles over the six networks:

- before learning, the 24 neurons are undecided, `(- - - -)`;
- after learning, three roles come back in each of the six networks: the
  detector of (0,1), `(- 0 1 0)`, the detector of (1,0), `(- 1 0 0)`, and a
  neuron off for the three other inputs, `(- 0 0 0)`; the fourth neuron
  mostly detects the input I1, `(- 0 1 1)`, in three networks.

For the input (0,0), all the neurons are at 0.5, trained or not: the MLPs of
neuromuse have no bias, and the logistic function of a null sum is 0.5. The
neuron that is off suggests that three hidden neurons would be enough.

## Three self-organizing maps trained on the song of the chaffinch

Three maps of 12 × 12 neurons (the one of the example `pinson_som.lisp` of
neuromuse) start from three different draws and learn the three songs of the
chaffinch. They are compared on the first song, before and after learning.

| Map | Topology (out of 143 edges) | Winning neurons | Entropy (bits) |
|---|---|---|---|
| 1 | 5 → 122 | 54 → 88 | 4.73 → 5.57 |
| 2 | 4 → 122 | 61 → 95 | 4.84 → 5.65 |
| 3 | 1 → 115 | 53 → 88 | 4.44 → 5.54 |

- **The topology**: the number of edges of the minimum spanning tree of the
  prototypes (`graph-span`) that link neighbours on the grid. Before
  learning, the prototypes are drawn at random and the tree ignores the grid;
  after, the three maps preserve the topology of the space of the sounds, to
  about the same degree.
- **The use of the map**: the three trained maps use more neurons for the
  same song, with a higher entropy (`entropy`): they describe it more finely.
- **The segmentation of the song.** The sequences of winners of two maps
  cannot be compared symbol by symbol, since their neurons are numbered
  differently (`dist-edit` gives 0.92 to 0.96 between the trained maps), and
  `dist-structure`, which compares the structure of repetitions of two
  sequences independently of the symbols, does not tell them apart either on
  sequences this long (0.90 to 0.93). So the instants where each map changes
  its winner are compared: for each frame, 1 if the winner changes, 0
  otherwise. The normalized Hamming distance (`dist-hamming`) between these
  segmentations is 0.15 to 0.18 between the trained maps, 0.28 to 0.36
  between the initial maps, and 0.49 between two independent segmentations
  changing as often. The three trained maps cut the song at the same
  instants: they learnt the same articulation of it, even if they name its
  sounds differently.

## The code

The code is the documentation (its comments are in French).
[lisp/neuromuse-comparaison.lisp](../lisp/neuromuse-comparaison.lisp) needs
the systems neuromuse and refrains; it is loaded from the directory of the
repository, prints the results and writes its image in `doc/pictures/`:

```lisp
(load "doc/lisp/neuromuse-comparaison.lisp")
```

<!-- code: doc/lisp/neuromuse-comparaison.lisp -->
```lisp
;;;; neuromuse-comparaison.lisp
;;;;
;;;; Comparer avec refrains plusieurs réseaux de neurones de neuromuse qui
;;;; apprennent la même chose, à partir de tirages initiaux différents :
;;;; 1. six perceptrons multicouches (MLP) appris sur le XOR : la géométrie de leur
;;;;    couche cachée et le rôle de leurs neurones, avant et après l'apprentissage ;
;;;; 2. trois cartes auto-organisatrices (SOM) apprises sur le chant du pinson : leur
;;;;    topologie, leur usage de la carte et leur segmentation du chant, avant et
;;;;    après l'apprentissage.
;;;;
;;;; Deux réseaux appris à partir de tirages différents ne numérotent pas leurs
;;;; neurones de la même façon : les neurones cachés d'un MLP peuvent être permutés
;;;; sans rien changer, et deux cartes placent les mêmes sons en des endroits
;;;; différents. On les compare donc par ce qui ne dépend pas de cette numérotation.
;;;;
;;;; Demande les systèmes neuromuse (https://github.com/FredVoisin/neuromuse) et
;;;; refrains, trouvables par ASDF. (load "doc/lisp/neuromuse-comparaison.lisp")
;;;; affiche les résultats et écrit, dans doc/pictures/,
;;;; neuromuse-comparaison.dot/.png. L'apprentissage des trois cartes prend environ
;;;; une minute et demie.
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

;; chaque réseau part d'un tirage aléatoire différent, mais reproductible
(defun tirage (n)
  (setf *random-state* #+sbcl (sb-ext:seed-random-state n) #-sbcl (make-random-state t)))

;;; 1. Six MLP appris sur le XOR : 2 entrées, 4 neurones cachés, 1 sortie

(defparameter *xor-entrees* '((0 0) (1 0) (0 1) (1 1)))
(defparameter *xor-sorties* '((0) (1) (1) (0)))

(defun profil (net)
  "Les activations des neurones cachés de NET (les poids d'un MLP) pour chacune des
quatre entrées du XOR : quatre vecteurs, un par entrée."
  (mapcar (lambda (entree) (logistic (matrix-vector (first net) entree))) *xor-entrees*))

(defun geometrie (net)
  "Les six distances entre les quatre entrées du XOR dans l'espace de la couche cachée
de NET : la façon dont le réseau sépare les entrées, qui ne dépend pas de l'ordre de
ses neurones cachés."
  (mapcar #'third (refrains:dist-euclidean (profil net) nil)))

;; les états de chaque réseau, avant et après l'apprentissage : (nom poids)
(defparameter *etats*
  (loop for k from 1 to 6
        append (progn
                 (tirage k)
                 (let ((mlp (make-instance 'mlp :name 'xor :in-size 2 :hidden-size '(4) :out-size 1
                                                :last-error 1000 :net (init-mlp-net 2 1 4))))
                   (setf (learn-fact mlp) .5 (verbose mlp) nil)
                   (let ((initial (copy-tree (net mlp))))
                     (loop repeat 20000
                           do (loop for entree in *xor-entrees* for sortie in *xor-sorties*
                                    do (setf (input mlp) entree (goal mlp) sortie) (learn mlp)))
                     (format t "~&réseau ~D : ~{~,2F~^ ~}~%" k
                             (loop for entree in *xor-entrees*
                                   collect (progn (setf (input mlp) entree) (car (run-mlp mlp)))))
                     (list (list (format nil "initial-~D" k) initial)
                           (list (format nil "appris-~D" k) (copy-tree (net mlp)))))))))

;; la semi-matrice des distances entre les douze états, d'après leur géométrie, puis
;; leur dendrogramme (lien moyen)
(defparameter *distances-etats*
  (loop for (a . autres) on *etats*
        nconc (loop for b in autres
                    collect (list (first a) (first b)
                                  (refrains:dist-euclidean (geometrie (second a)) (geometrie (second b)))))))

(defparameter *dendrogramme-etats*
  (nth-value 1 (refrains:graph-dendrogram *distances-etats* :linkage :average)))

(format t "~&dendrogramme des réseaux : ~S~%" *dendrogramme-etats*)
(refrains:dendrogram>dot *dendrogramme-etats* (picture "neuromuse-comparaison.png") :invert t)

;; le rôle de chaque neurone caché : son profil d'activation sur les quatre entrées,
;; 1 s'il est franchement actif (plus de 0,8), 0 s'il est éteint (moins de 0,2), - s'il
;; est indécis ; les rôles sont comptés sur les six réseaux avec histogram
(defun role (net neurone)
  (mapcar (lambda (activations)
            (let ((a (nth neurone activations)))
              (cond ((> a 0.8) 1) ((< a 0.2) 0) (t '-))))
          (profil net)))

(dolist (etat '("initial" "appris"))
  (format t "~&rôles des neurones cachés, réseaux ~A : ~S~%" etat
          (refrains:histogram
           (loop for (nom net) in *etats*
                 when (search etat nom)
                   append (loop for neurone below 4 collect (role net neurone)))
           :test #'equal)))

;;; 2. Trois cartes apprises sur le chant du pinson : 12 x 12 neurones, 18 bandes

(let ((*standard-output* (make-broadcast-stream))
      (examples (asdf:system-relative-pathname :neuromuse "examples/")))
  (load (merge-pathnames "pinson_vecteurs.lisp" examples))
  (load (merge-pathnames "pinson_som.lisp" examples)))

(defun topologie (som)
  "Le nombre d'arêtes de l'arbre de recouvrement minimal des prototypes de SOM qui
relient des voisins sur la grille."
  (let ((grille (grid-neighbour-pairs som))
        (arbre (refrains:graph-span
                (refrains:dist-euclidean
                 (mapcar (lambda (neurone) (mapcar #'third (edges neurone))) (net som)) nil))))
    (count-if (lambda (e) (member (list (min (first e) (second e)) (max (first e) (second e)))
                                  grille :test #'equal))
              arbre)))

(defun gagnants (som chant)
  "La suite des neurones gagnants de SOM pour CHANT, sans les répétitions locales."
  (refrains:filt-repeat (winner-sequence chant som)))

(defun frontieres (som chant)
  "Pour chaque trame de CHANT après la première, 1 si le neurone gagnant change, 0 sinon :
la segmentation du chant par SOM, qui ne dépend pas de la numérotation de ses neurones."
  (let ((suite (winner-sequence chant som)))
    (mapcar (lambda (a b) (if (= a b) 0 1)) suite (cdr suite))))

(defun etat-carte (som chant)
  (let ((suite (gagnants som chant)))
    (list :topologie (topologie som) :neurones (length (remove-duplicates suite))
          :entropie (refrains:entropy suite) :frontieres (frontieres som chant) :suite suite)))

;; chaque carte : (état initial, état appris), pour le premier chant
(defparameter *cartes*
  (loop for k from 1 to 3
        collect (progn
                  (tirage (+ 20 k))
                  (let ((som (make-instance 'som :name 'carte :size 144 :input 18))
                        (chant (first *pinson-chants*)))
                    (setf (learn-fact som) .4 (radius som) 3 (temp som) 0.0 (net-temp som) 0.05)
                    (let ((initial (etat-carte som chant)))
                      (train-pinson-som :epochs 10 :net som)
                      (list initial (etat-carte som chant)))))))

(loop for (initial appris) in *cartes* for k from 1
      do (format t "~&carte ~D : topologie ~D -> ~D (sur 143), neurones ~D -> ~D, entropie ~,2F -> ~,2F~%"
                 k (getf initial :topologie) (getf appris :topologie)
                 (getf initial :neurones) (getf appris :neurones)
                 (getf initial :entropie) (getf appris :entropie)))

;; les suites de gagnants de deux cartes apprises ne se comparent pas symbole à symbole
;; (leurs neurones sont numérotés différemment), et dist-structure, qui compare leurs
;; structures de répétitions indépendamment des symboles, ne les distingue pas sur des
;; suites aussi longues
(flet ((paires (f)
         (loop for (a . autres) on *cartes*
               nconc (loop for b in autres
                           collect (funcall f (getf (second a) :suite) (getf (second b) :suite))))))
  (format t "~&cartes apprises, dist-edit : ~{~,2F~^ ~} ; dist-structure : ~{~,2F~^ ~}~%"
          (paires (lambda (a b) (refrains:dist-edit a b :norm t)))
          (paires #'refrains:dist-structure)))

;; les cartes découpent-elles le chant aux mêmes instants ? distance de Hamming
;; normalisée entre leurs frontières, deux à deux, avant et après l'apprentissage
(dolist (etat '(first second))
  (format t "~&segmentations des cartes (~A) : ~{~,2F~^ ~}~%"
          (if (eq etat 'first) "initiales" "apprises")
          (loop for (a . autres) on *cartes*
                nconc (loop for b in autres
                            collect (refrains:dist-hamming (getf (funcall etat a) :frontieres)
                                                           (getf (funcall etat b) :frontieres))))))

;; la distance attendue entre deux segmentations indépendantes, de même taux de
;; changement p : 2 p (1 - p)
(let* ((f (getf (second (first *cartes*)) :frontieres))
       (p (/ (count 1 f) (float (length f)))))
  (format t "~&deux segmentations indépendantes : ~,2F~%" (* 2 p (- 1 p))))
```
<!-- /code -->

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
