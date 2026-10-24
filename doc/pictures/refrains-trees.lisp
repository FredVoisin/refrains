;;;; refrains-trees.lisp
;;;;
;;;; Les arbres des fonctions de refrains : les arbres de recouvrement minimal
;;;; des fonctions exportées, d'après leurs noms et d'après le vocabulaire de
;;;; leur documentation, et leurs dendrogrammes, calculés avec refrains.
;;;;
;;;; (load "refrains-trees.lisp") écrit, dans le dossier de ce fichier,
;;;; refrains-names.dot/.png, refrains-docstrings.dot/.png et leurs
;;;; dendrogrammes, refrains-names-dendrogram.dot/.png et
;;;; refrains-docstrings-dendrogram.dot/.png.
;;;; Les images sont tracées par neato (Graphviz).
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

(defparameter *here* (uiop:pathname-directory-pathname *load-truename*))

(defparameter *functions*
  (sort (loop for f being the external-symbols of :refrains collect f) #'string<))

(defparameter *names* (mapcar #'string-downcase *functions*))

(defun semi-matrix (objects distance)
  "La semi-matrice ((nom-a nom-b distance) ...) des fonctions, d'après la distance
entre leurs objets (noms ou vocabulaires), arrondie au centième."
  (loop for (a . others) on objects
        for (name-a . other-names) on *names*
        nconc (loop for b in others
                    for name-b in other-names
                    collect (list name-a name-b
                                  (/ (round (* 100 (funcall distance a b))) 100.0)))))

;;; 1. Par les noms : distance d'édition normalisée entre les noms, lettre à lettre

(defparameter *names-tree*
  (graph-span (semi-matrix *names* (lambda (a b) (dist-edit a b :norm t)))))

;;; 2. Par la documentation : distance de Jaccard entre les vocabulaires

(defparameter *articles* '("a" "an" "the"))

(defun vocabulaire (f)
  "Les mots de la documentation de f, en minuscules, sans le nom de f, les articles,
les nombres et les symboles d'une lettre (a, b, x...)."
  (remove-duplicates
   (remove-if (lambda (word)
                (or (member word *articles* :test #'string=)
                    (= (length word) 1)
                    (every #'digit-char-p word)
                    (string= word (string-downcase f))))
              (separate (string-downcase (documentation f 'function))
                        :marks "()<>[]{},;.:!?'\"=/|*#`&+~"))
   :test #'string=))

(defparameter *vocabulaires* (mapcar #'vocabulaire *functions*))

;; les mots voisins (list et lists ; define, defined et defines...) sont fusionnés en un
;; terme générique, le plus court d'entre eux : leur distance d'édition relative est
;; au plus 0,2, une substitution comptant comme une suppression et une insertion
;; (:sub 2), pour que seules les variantes d'un même mot se rapprochent

(defparameter *mots*
  (sort (remove-duplicates (reduce #'append *vocabulaires*) :test #'string=) #'string<))

(defun mots-voisins (words)
  "Les paires de mots voisins (mot-a mot-b distance)."
  (loop for (a . others) on words
        nconc (loop for b in others
                    ;; la distance relative vaut au moins l'écart des longueurs
                    when (<= (abs (- (length a) (length b))) (* 0.2 (max (length a) (length b))))
                      nconc (let ((d (dist-edit a b :sub 2 :norm t)))
                              (when (<= d 0.2) (list (list a b d)))))))

;; les groupes de mots voisins : les feuilles des dendrogrammes (lien simple) du graphe
;; des mots voisins, qui n'est pas connexe (graph-span le signale) ;
;; dendrogram-leaves : fonction interne de refrains, non exportée
(defparameter *termes-generiques*
  (let ((terms (make-hash-table :test #'equal))
        (forest (nth-value 1 (graph-dendrogram (mots-voisins *mots*)))))
    (dolist (tree (if (realp (first forest)) (list forest) forest) terms)
      (let* ((group (refrains::dendrogram-leaves tree))
             (generic (first (stable-sort (sort (copy-list group) #'string<) #'< :key #'length))))
        (dolist (word group) (setf (gethash word terms) generic))))))

(defun vocabulaire-generique (vocabulaire)
  (remove-duplicates (mapcar (lambda (word) (gethash word *termes-generiques* word)) vocabulaire)
                     :test #'string=))

(defparameter *termes* (mapcar #'vocabulaire-generique *vocabulaires*))

;; les termes présents dans plus de 10 des 52 documentations (list, with...),
;; trop courants pour distinguer les fonctions
(defparameter *termes-courants*
  (loop for (term count) in (histogram (reduce #'append *termes*) :test #'equal)
        when (> count 10) collect term))

(defparameter *docstrings-tree*
  (graph-span
   (semi-matrix (mapcar (lambda (v) (set-difference v *termes-courants* :test #'string=))
                        *termes*)
                ;; jaccard-dist : fonction interne de refrains, non exportée
                (lambda (a b) (refrains::jaccard-dist a b :test #'string=)))))

;;; 3. Les arbres en langage dot, puis en images : graph>dot écrit le fichier .dot
;;; et appelle neato. Les distances, de 0 à 1, sont plus courtes que les noms des
;;; nœuds : avec :overlap nil, neato écarte les nœuds qui se chevaucheraient ;
;;; :invert t trace en blanc sur noir.

(graph>dot *names-tree* (namestring (merge-pathnames "refrains-names.png" *here*))
           :overlap nil :invert t)
(graph>dot *docstrings-tree* (namestring (merge-pathnames "refrains-docstrings.png" *here*))
           :overlap nil :invert t)

;;; 4. Les dendrogrammes de chaque arbre : graph-dendrogram (lien simple) range les
;;; fusions de l'arbre par distance croissante ; dendrogram>dot place les feuilles à
;;; gauche et chaque fusion à l'abscisse de sa distance, et appelle neato -n2.

(dendrogram>dot (nth-value 1 (graph-dendrogram *names-tree*))
                (namestring (merge-pathnames "refrains-names-dendrogram.png" *here*))
                :invert t)
(dendrogram>dot (nth-value 1 (graph-dendrogram *docstrings-tree*))
                (namestring (merge-pathnames "refrains-docstrings-dendrogram.png" *here*))
                :invert t)
