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

;;; 3. Les arbres en langage dot, puis en images : graph>dot écrit le fichier .dot
;;; et appelle neato. Les distances, de 0 à 1, sont plus courtes que les noms des
;;; nœuds : avec :overlap nil, neato écarte les nœuds qui se chevaucheraient ;
;;; :invert t trace en blanc sur noir.

(graph>dot *names-tree* (namestring (merge-pathnames "refrains-names.png" *here*))
           :overlap nil :invert t)
(graph>dot *docstrings-tree* (namestring (merge-pathnames "refrains-docstrings.png" *here*))
           :overlap nil :invert t)

;;; 4. Les dendrogrammes de chaque arbre : graph>dendrogram (lien simple) donne
;;; les fusions de l'arbre par distance croissante, sous forme d'arbre imbriqué
;;; (distance gauche droite). refrains ne trace pas encore de dendrogramme :
;;; dendrogram>dot place les feuilles à gauche, une par ligne, et chaque fusion
;;; à l'abscisse de sa distance ; neato -n2 trace le dot à ces positions.

(defun dendrogram-leaves (dendrogram)
  (if (atom dendrogram)
      (list dendrogram)
      (append (dendrogram-leaves (second dendrogram)) (dendrogram-leaves (third dendrogram)))))

(defun dendrogram>dot (dendrogram file &key (unit 700) (step 16))
  "Écrit le dendrogramme dans file, en langage dot, avec la position de chaque point :
une distance d est à l'abscisse x0 + d * unit, les feuilles sont espacées de step points."
  (let* ((names (dendrogram-leaves dendrogram))
         (x0 (+ 12 (* 6.6 (reduce #'max (mapcar #'length names))))) ; Courier 11 : 6,6 points par lettre
         (n 0))
    (with-open-file (out file :direction :output :if-exists :supersede)
      (labels ((x (d) (+ x0 (* unit d)))
               (point (x y)
                 (format out " p~D [pos=\"~,1F,~,1F\"];~%" (incf n) x y)
                 (format nil "p~D" n))
               (draw (tree)
                 ;; le point d'où part le trait vers le parent, et son ordonnée
                 (if (atom tree)
                     (let ((y (* step (- (length names) 1 (position tree names :test #'equal)))))
                       (format out " ~S [shape=plaintext, label=~S, pos=\"~,1F,~,1F\"];~%"
                               tree tree (- x0 6 (* 3.3 (length tree))) y)
                       (list (point x0 y) y))
                     (destructuring-bind (d a b) tree
                       (destructuring-bind ((pa ya) (pb yb)) (list (draw a) (draw b))
                         (let* ((y (/ (+ ya yb) 2))
                                (ca (point (x d) ya))
                                (cb (point (x d) yb))
                                (m (point (x d) y)))
                           (format out " ~A -- ~A;~% ~A -- ~A;~% ~A -- ~A;~% ~A -- ~A;~%"
                                   pa ca pb cb ca m m cb)
                           (list m y)))))))
        (format out "graph dendrogram {~%")
        (format out " graph [bgcolor=black, splines=false];~%")
        (format out " node [shape=point, width=0, color=white, fontcolor=white, fontname=Courier, fontsize=11];~%")
        (format out " edge [color=white];~%")
        (draw dendrogram)
        ;; l'échelle des distances, sous les feuilles
        (let ((y (- (* 1.5 step))))
          (loop for d in '(0 0.25 0.5 0.75 1)
                for (tick label) = (list (point (x d) y) (point (x d) (- y 5)))
                do (format out " ~A -- ~A;~% t~A [shape=plaintext, label=\"~A\", pos=\"~,1F,~,1F\"];~%"
                           tick label n d (x d) (- y 16))
                collect tick into ticks
                finally (format out " ~{~A~^ -- ~};~%" ticks)))
        (format out "}~%")))
    file))

(defun draw-dendrogram (tree name)
  (let ((dot (namestring (merge-pathnames (format nil "~A.dot" name) *here*)))
        (png (namestring (merge-pathnames (format nil "~A.png" name) *here*))))
    (dendrogram>dot (nth-value 1 (graph>dendrogram tree)) dot)
    (uiop:run-program (list "neato" "-n2" "-Tpng" "-o" png dot))
    png))

(draw-dendrogram *names-tree* "refrains-names-dendrogram")
(draw-dendrogram *docstrings-tree* "refrains-docstrings-dendrogram")
