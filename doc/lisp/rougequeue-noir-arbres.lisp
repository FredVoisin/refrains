;;;; rougequeue-noir-arbres.lisp
;;;;
;;;; Les arbres de recouvrement minimal des transcriptions du chant du rougequeue noir, et
;;;; l'arbre de leurs ressemblances. Cinq transcriptions : celle de 2011
;;;; (doc/exemples/rougequeue-noir.md), celles des trois chants du remake de 2026
;;;; (doc/lisp/rougequeue-noir-sv.lisp), et celle du premier chant en six niveaux
;;;; (doc/lisp/rougequeue-noir-sv-niveaux.lisp).
;;;;
;;;; Chaque transcription est coupée aux silences : chaque note est une suite de lettres
;;;; (une lettre par spectre). Les notes distinctes d'une transcription sont reliées par leur
;;;; distance d'édition normalisée (graph-span) : c'est l'arbre de la transcription. Les
;;;; lettres ne désignent pas les mêmes types de spectres d'une transcription à l'autre
;;;; (chacune est classée seule) : les arbres sont donc comparés par leur forme, qui ne
;;;; dépend pas des lettres, et les distances entre les formes donnent l'arbre résultant.
;;;;
;;;; (load "doc/lisp/rougequeue-noir-arbres.lisp") affiche les transcriptions, leurs arbres
;;;; et les distances entre les arbres, et dessine les arbres avec neato (Graphviz) :
;;;; doc/pictures/rougequeue-noir-arbre-*.png.
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

(defparameter *ici* (uiop:pathname-directory-pathname *load-truename*))
(defparameter *doc-arbres* (uiop:pathname-parent-directory-pathname *ici*))

;;; 1. Les transcriptions : une classe par spectre, 0 pour le silence

;; la transcription de 2011, depuis le texte de jp2a, comme dans rougequeue-noir.md
(defun transcription-2011 ()
  (let ((spectres (read-text (merge-pathnames "data/rougequeue_noir.txt" *doc-arbres*)
                             :mode :charcode :columns t)))
    (class-sym spectres 12 :edit-nn :ins 1.5 :del 1.5
               :excluded (list (make-list 45 :initial-element (char-code #\x))))))

;; une transcription d'un autre exemple : charger son script et appeler son analyse, sans
;; afficher ses résultats. Les deux scripts définissent tous deux analyse : chacun est chargé
;; juste avant de servir.
(defun transcription (script fichier)
  (let ((*standard-output* (make-broadcast-stream)))
    (load (merge-pathnames script *ici*))
    (funcall 'analyse (merge-pathnames fichier *doc-arbres*))))

(defparameter *transcriptions*
  (list (list "2011" (transcription-2011))
        (list "remake-01" (transcription "rougequeue-noir-sv.lisp" "data/rougequeue-noir01.csv"))
        (list "remake-02" (transcription "rougequeue-noir-sv.lisp" "data/rougequeue-noir02.csv"))
        (list "remake-03" (transcription "rougequeue-noir-sv.lisp" "data/rougequeue-noir03.csv"))
        (list "brut-01" (transcription "rougequeue-noir-sv-niveaux.lisp" "data/rougequeue-noir01.csv"))))

(defun lettre (c) (if (zerop c) "-" (string-downcase (num>alpha (1- c)))))

;;; 2. Les notes : les suites de lettres entre deux silences

(defun notes (classes)
  (let ((notes nil) (note nil))
    (dolist (c (append classes (list 0)) (nreverse notes))
      (cond ((plusp c) (push (lettre c) note))
            (note (push (apply #'concatenate 'string (reverse note)) notes)
                  (setf note nil))))))

;;; 3. L'arbre d'une transcription : les notes distinctes, reliées par leur distance
;;; d'édition normalisée (de 0 à 1, quelle que soit la longueur des notes)

(defun arbre (notes)
  (let ((distinctes (remove-duplicates notes :test #'string= :from-end t)))
    ;; dist-edit donne la semi-matrice (i j distance) ; les nœuds de l'arbre sont les notes
    (mapcar (lambda (e) (list (nth (first e) distinctes) (nth (second e) distinctes)
                              (/ (round (* 100 (third e))) 100.0)))
            (graph-span (dist-edit distinctes nil :norm t)))))

;;; 4. La forme d'un arbre, qui ne dépend pas des lettres : les déciles des longueurs de ses
;;; arêtes, et la proportion de ses nœuds de degré 1 (les feuilles), 2, 3 et 4 ou plus

(defun forme (arbre)
  (let* ((longueurs (sort (mapcar #'third arbre) #'<))
         (n (length longueurs))
         (degres (mapcar (lambda (x) (graph-degree x arbre)) (graph-nodes arbre))))
    (append (loop for q from 1 to 9 collect (nth (floor (* q (1- n)) 10) longueurs))
            (loop for d from 1 to 4
                  collect (/ (count-if (lambda (k) (if (= d 4) (>= k 4) (= k d))) degres)
                             (float (length degres)))))))

;;; 5. L'affichage et les dessins

(format t "~&~%1. Les transcriptions (- pour le silence, une lettre par classe)~%")
(loop for (nom classes) in *transcriptions*
      do (format t "~&~%~A (~D spectres)~%~{~A~}~%" nom (length classes) (mapcar #'lettre classes)))

(defparameter *arbres*
  (loop for (nom classes) in *transcriptions*
        collect (list nom (arbre (notes classes)))))

(format t "~&~%2. Les arbres des transcriptions~%")
(loop for (nom a) in *arbres*
      for notes = (notes (second (assoc nom *transcriptions* :test #'string=)))
      do (format t "~&~%~A : ~D notes, ~D distinctes ; longueur ~,2F~%" nom (length notes)
                 (length (graph-nodes a)) (graph-length a))
         (dolist (e a) (format t "~&  ~A — ~A  ~,2F~%" (first e) (second e) (third e)))
         (graph>dot a :out (merge-pathnames (format nil "pictures/rougequeue-noir-arbre-~A.png" nom)
                                             *doc-arbres*)
                      :shape "plaintext" :overlap nil))

(format t "~&~%3. La forme des arbres (déciles des longueurs, puis degrés 1, 2, 3, 4+)~%")
(defparameter *formes* (mapcar (lambda (x) (forme (second x))) *arbres*))
(loop for (nom) in *arbres* for f in *formes*
      do (format t "~&  ~10A ~{~,2F~^ ~}~%" nom f))

(format t "~&~%4. Les distances entre les arbres, et l'arbre résultant~%")
(defparameter *noms* (mapcar #'first *arbres*))
(defparameter *distances*
  (mapcar (lambda (e) (list (nth (first e) *noms*) (nth (second e) *noms*)
                            (/ (round (* 100 (third e))) 100.0)))
          (dist-euclidean *formes* nil)))
(dolist (e *distances*) (format t "~&  ~10A ~10A ~,2F~%" (first e) (second e) (third e)))
(defparameter *arbre-resultant* (graph-span *distances*))
(format t "~&~%Arbre résultant :~%")
(dolist (e *arbre-resultant*) (format t "~&  ~A — ~A  ~,2F~%" (first e) (second e) (third e)))
(graph>dot *arbre-resultant* :out (merge-pathnames "pictures/rougequeue-noir-arbres.png" *doc-arbres*)
                             :overlap nil)
