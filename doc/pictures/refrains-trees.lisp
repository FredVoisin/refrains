;;;; refrains-trees.lisp
;;;;
;;;; Les arbres des fonctions de refrains : les arbres de recouvrement minimal
;;;; des fonctions exportées, d'après leurs noms et d'après le vocabulaire de
;;;; leur documentation, calculés avec refrains.
;;;;
;;;; (load "refrains-trees.lisp") écrit, dans le dossier de ce fichier,
;;;; refrains-names.dot/.png et refrains-docstrings.dot/.png.
;;;; Les images sont tracées par neato (Graphviz).
;;;;
;;;; This file is part of refrains (GPL-3.0-only).

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

(defun vocabulary (f)
  "Les mots de la documentation de f, en minuscules, sans le nom de f, les nombres
et les mots de moins de trois lettres."
  (remove-duplicates
   (remove-if (lambda (word)
                (or (< (length word) 3)
                    (string= word (string-downcase f))
                    (every #'digit-char-p word)))
              (separate (string-downcase (documentation f 'function))
                        :marks "()<>[]{},;.:!?'\"=/|*#`&+~"))
   :test #'string=))

(defparameter *vocabularies* (mapcar #'vocabulary *functions*))

;; les mots présents dans plus de 10 des 53 documentations (the, list, with...),
;; trop courants pour distinguer les fonctions
(defparameter *common-words*
  (loop for (word count) in (histogram (reduce #'append *vocabularies*) :test #'equal)
        when (> count 10) collect word))

(defparameter *docstrings-tree*
  (graph-span
   (semi-matrix (mapcar (lambda (v) (set-difference v *common-words* :test #'string=))
                        *vocabularies*)
                ;; jaccard-dist : fonction interne de refrains, non exportée
                (lambda (a b) (refrains::jaccard-dist a b :test #'string=)))))

;;; 3. Les arbres en langage dot (graph>dot), puis en images (neato)

(defun draw (tree name)
  (let ((dot (namestring (merge-pathnames (format nil "~A.dot" name) *here*)))
        (png (namestring (merge-pathnames (format nil "~A.png" name) *here*))))
    (graph>dot tree dot)
    ;; les distances, de 0 à 1, sont plus courtes que les noms des nœuds :
    ;; neato écarte les nœuds qui se chevaucheraient
    (uiop:run-program (list "neato" "-Goverlap=false" "-Gsep=+4" "-Tpng" "-o" png dot))
    png))

(draw *names-tree* "refrains-names")
(draw *docstrings-tree* "refrains-docstrings")
