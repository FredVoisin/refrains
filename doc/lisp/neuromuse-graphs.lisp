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
(refrains:graph>dot (refrains:graph-span *xor-graph*) (picture "neuromuse-xor.png") :invert t)

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

(refrains:graph>dot *prototypes-tree* (picture "neuromuse-pinson.png")
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
