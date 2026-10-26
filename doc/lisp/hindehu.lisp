;;;; hindehu.lisp
;;;;
;;;; Quantifier une fréquence fondamentale (F0) mesurée : un extrait de Hìndèhú, des Aka
;;;; (Centrafrique), voix et mòbéké alternés, enregistré par S. Arom, V. Dehoux,
;;;; S. Fürniss et F. Voisin en 1989.
;;;; La F0 a été mesurée toutes les 10 ms (algorithme YIN, de 60 à 1000 Hz), avec
;;;; l'intensité : doc/data/hindehu-f0.txt, une ligne par trame (temps en s, F0 en Hz ou 0
;;;; si la trame n'est pas voisée, intensité en dB). La F0, telle que détectée, est
;;;; quantifiée par filt-quantize, sur l'ensemble et sur une fenêtre glissante, puis par
;;;; notes, et transcrite en notation ABC et pour LilyPond.
;;;;
;;;; (load "doc/lisp/hindehu.lisp") affiche les résultats et écrit sa figure (svg), sa
;;;; transcription (abc, ly) et, si lilypond est installé, sa partition (svg) dans
;;;; doc/pictures/.
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

;;; 1. La détection : read-text lit chaque ligne comme une liste (temps F0 intensité)

(defparameter *trames*
  (read-text (namestring (merge-pathnames "data/hindehu-f0.txt" *doc*))))

(defun note-midi (f)
  "La fréquence F (Hz) en note MIDI (69 : la 440 Hz), NIL si F est 0 (trame non voisée)."
  (when (plusp f) (+ 69 (* 12 (log (/ f 440) 2)))))

;; les notes, une par trame de 10 ms, NIL dans les trames non voisées
(defparameter *notes* (mapcar (lambda (trame) (note-midi (second trame))) *trames*))
(defparameter *intensites* (mapcar #'third *trames*))

(format t "~&~D trames de 10 ms, ~D voisées ; notes MIDI de ~,1F à ~,1F~%"
        (length *notes*) (count-if #'identity *notes*)
        (reduce #'min (remove nil *notes*)) (reduce #'max (remove nil *notes*)))

;;; 2. Regarder : les notes, puis l'intensité

(seq>plot *notes* :height 14)
(seq>plot *intensites* :height 8)

;;; 3. Les valeurs basses : class-num en 2 niveaux coupe au plus grand écart entre les
;;; valeurs triées, qui sépare quelques valeurs basses de toutes les autres. Elles ne sont pas
;;; modifiées : on regarde seulement où elles tombent, combien de trames elles durent et avec
;;; quelle intensité

(defparameter *registre*
  ;; la plus basse valeur de la classe haute
  (let* ((valeurs (remove nil *notes*))
         (classes (first (class-num valeurs 2 :1d-centroids :sort t))))
    (reduce #'min (loop for v in valeurs for c in classes when (= c 1) collect v))))

(format t "~&~D valeurs sous ~,1F (position, note, intensité) :~%"
        (count-if (lambda (v) (and v (< v *registre*))) *notes*) *registre*)
(loop for v in *notes* for db in *intensites* for i from 0
      when (and v (< v *registre*))
        do (format t "~4D ~4,1F ~5,1F | " i v db))

;;; 4. Quantifier : par le temps passé (:1d-centroids) et par les retournements (:minmax),
;;; de 5 à 10 niveaux

(defun erreur (notes quantifiees)
  "L'écart moyen, en demi-tons, entre les notes et leur version quantifiée (NIL exclus)."
  (let ((ecarts (loop for a in notes for b in quantifiees when a collect (abs (- a b)))))
    (/ (reduce #'+ ecarts) (length ecarts))))

(defun niveaux (quantifiees)
  (sort (remove-duplicates (remove nil quantifiees) :test #'=) #'<))

(dolist (n '(5 6 7 8 9 10))
  (let ((duree (filt-quantize *notes* n))
        (retournements (filt-quantize *notes* n :mode :minmax)))
    (format t "~&~2D niveaux : par le temps passé ~{~,1F~^ ~} (erreur ~,2F)~%    par les retournements ~{~,1F~^ ~} (erreur ~,2F)~%"
            n (niveaux duree) (erreur *notes* duree)
            (niveaux retournements) (erreur *notes* retournements))))

;; sur une fenêtre glissante d'un quart (pas d'une demi-fenêtre) : les niveaux de chaque fenêtre
(multiple-value-bind (quantifiees classes fenetres) (filt-quantize *notes* 10 :window 1/4 :out :all)
  (declare (ignore quantifiees classes))
  (dolist (f fenetres)
    (format t "~&fenêtre ~4D-~4D : ~{~,1F~^ ~}~%" (first f) (second f) (third f))))

;;; 5. Par notes : quantifiées trame par trame, les notes brèves pèsent peu, et les détections
;;; faibles (la respiration, les attaques) prennent des niveaux. On passe donc aux notes :
;;; les minima très courts sont ignorés (NIL), chaque suite de trames voisées entre deux
;;; silences est une note, de hauteur médiane ; les suites faibles sont écartées ; puis
;;; class-num classe les notes, chacune comptant une fois, quelle que soit sa durée

(defparameter *sans-minima*
  (mapcar (lambda (v) (when (and v (>= v *registre*)) v)) *notes*))

(defun suites (valeurs)
  "Les suites (début fin) de VALEURS entre deux NIL."
  (let ((suites nil) (debut nil))
    (loop for v in (append valeurs (list nil)) for i from 0
          do (cond ((and v (null debut)) (setf debut i))
                   ((and (null v) debut) (push (list debut (1- i)) suites) (setf debut nil))))
    (nreverse suites)))

(defun mediane (valeurs)
  (nth (floor (length valeurs) 2) (sort (copy-list valeurs) #'<)))

(defun moyenne (valeurs) (/ (reduce #'+ valeurs) (length valeurs)))

;; les suites faibles (sous -45 dB en moyenne) sont la respiration, une attaque, une
;; extinction ; les autres sont les notes : (début fin hauteur intensité)
(defparameter *seuil* -45)

(defparameter *notes-jouees*
  (loop for (debut fin) in (suites *sans-minima*)
        for intensite = (moyenne (subseq *intensites* debut (1+ fin)))
        when (>= intensite *seuil*)
          collect (list debut fin (mediane (subseq *sans-minima* debut (1+ fin))) intensite)))

;; les cinq niveaux : class-num sur les hauteurs des notes
(defparameter *niveaux*
  (second (class-num (mapcar #'third *notes-jouees*) 5 :1d-centroids :sort t)))

(defun niveau (hauteur)
  "Le niveau le plus proche de HAUTEUR."
  (reduce (lambda (a b) (if (< (abs (- hauteur a)) (abs (- hauteur b))) a b)) *niveaux*))

(format t "~&~D notes ; 5 niveaux (nombre de notes, durée moyenne en ms) :~%" (length *notes-jouees*))
(dolist (n *niveaux*)
  (let ((durees (loop for (debut fin hauteur) in *notes-jouees*
                      when (= (niveau hauteur) n) collect (* 10 (1+ (- fin debut))))))
    (format t "  ~,2F : ~D notes, ~D ms~%" n (length durees) (round (moyenne durees)))))

;; la grille au quart de ton : histogram compte les trames autour de chaque centre (:thes), à
;; moins d'un huitième de ton (:test), sans arrondir les hauteurs
(defun quart-de-ton (x) (/ (round (* 2 x)) 2))

(format t "~&au quart de ton : ~S~%"
        (histogram (remove nil *sans-minima*)
                   :thes (loop for c from 62 to 75 by 1/2 collect c)
                   :test (lambda (c x) (< (abs (- c x)) 1/4))))

;; la transcription : chaque trame (hors minima très courts) prend le plus proche des cinq
;; niveaux, au quart de ton, centres fixes ; une suite voisée peut ainsi contenir plusieurs
;; notes enchaînées. Les segments de moins de 50 ms (5 trames) sont des glissements entre
;; deux notes ou des détections faibles : ils deviennent des silences

(defparameter *duree-minimale* 5)

(defun segments (valeurs)
  "Les suites (début fin valeur) de VALEURS égales consécutives, hors NIL."
  (let ((segments nil) (debut nil))
    (loop for v in (append valeurs (list nil)) for i from 0
          do (cond ((and v (null debut)) (setf debut i))
                   ((and debut (not (eql v (nth debut valeurs))))
                    (push (list debut (1- i) (nth debut valeurs)) segments)
                    (setf debut (when v i)))))
    (nreverse segments)))

(defparameter *transcription*
  (let* ((par-trame (mapcar (lambda (v) (when v (quart-de-ton (niveau v)))) *sans-minima*))
         (transcription (copy-list par-trame)))
    (dolist (s (segments par-trame) transcription)
      (when (< (1+ (- (second s) (first s))) *duree-minimale*)
        (loop for i from (first s) to (second s) do (setf (nth i transcription) nil))))))

(format t "~&~D notes (début, durée en ms, niveau au quart de ton) :~%~{~{~4D ~4D ~,1F~}~%~}"
        (length (segments *transcription*))
        (mapcar (lambda (s) (list (first s) (* 10 (1+ (- (second s) (first s)))) (float (third s))))
                (segments *transcription*)))

;;; 6. La transcription, avec le rythme : chaque note dure son nombre de trames divisé par 5, en
;;; doubles croches (une double croche pour 50 ms). Pour LilyPond, aux hauteurs mesurées, au
;;; quart de ton (ih : un quart de ton plus haut), avec la partition (svg) si lilypond est
;;; installé. En ABC, qui ne note que des demi-tons : la mélodie est descendue d'un quart de
;;; ton, pour que chaque note tombe sur un demi-ton tempéré (mi, fa#, la, si, ré), et le titre
;;; le précise

(format t "~&~A" (seq>ly *transcription* :title "Hìndèhú" :rhythm t :unit 5))
(handler-case (seq>ly *transcription* :title "Hìndèhú" :rhythm t :unit 5
                                      :out (merge-pathnames "pictures/hindehu-partition.svg" *doc*))
  (error (c) (format t "~&~A~%" c)))

(defparameter *plus-bas* (mapcar (lambda (n) (when n (- n 1/2))) *transcription*))
(defparameter *titre* "Hìndèhú (un quart de ton plus bas)")

(format t "~&~A" (seq>abc *plus-bas* :title *titre* :rhythm t :unit 5))
(seq>abc *plus-bas* :title *titre* :rhythm t :unit 5 :out (merge-pathnames "pictures/hindehu.abc" *doc*))

;;; 7. Une figure : les notes détectées (en blanc), leur quantification trame par trame en 10
;;; niveaux (en orange) et la transcription, au plus proche des cinq niveaux (en bleu)

(defun svg-polylines (stream valeurs largeur hauteur bas haut couleur epaisseur)
  "Trace les VALEURS, une par trame, chacune à son rang ; la ligne est coupée aux NIL."
  (let ((n (length valeurs)) (ligne nil))
    (flet ((tracer ()
             (when ligne
               (format stream "<polyline fill=\"none\" stroke=\"~A\" stroke-width=\"~A\" points=\"~{~{~,1F,~,1F~}~^ ~}\"/>~%"
                       couleur epaisseur (nreverse ligne))
               (setf ligne nil))))
      (loop for v in valeurs for i from 0
            do (if v
                   (push (list (* largeur (/ i (1- n))) (- hauteur (* hauteur (/ (- v bas) (- haut bas))))) ligne)
                   (tracer)))
      (tracer))))

(defun paliers (valeurs)
  "Les VALEURS, la première de chaque nouveau palier remplacée par NIL : tracées par
svg-polylines, les paliers restent horizontaux, sans les traits qui les relient."
  (loop for precedente = nil then v
        for v in valeurs
        collect (unless (and precedente v (/= precedente v)) v)))

(with-open-file (svg (merge-pathnames "pictures/hindehu.svg" *doc*)
                     :direction :output :if-exists :supersede)
  (let ((largeur 1000) (hauteur 300)
        (bas (reduce #'min (remove nil *notes*))) (haut (reduce #'max (remove nil *notes*))))
    (format svg "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"~D\" height=\"~D\" viewBox=\"-10 -10 ~D ~D\">~%"
            (+ largeur 20) (+ hauteur 20) (+ largeur 20) (+ hauteur 20))
    (format svg "<rect x=\"-10\" y=\"-10\" width=\"~D\" height=\"~D\" fill=\"black\"/>~%" (+ largeur 20) (+ hauteur 20))
    (svg-polylines svg *notes* largeur hauteur bas haut "white" 1)
    ;; les paliers, sans les traits qui les relient
    (svg-polylines svg (paliers (filt-quantize *notes* 10)) largeur hauteur bas haut "orange" 2)
    (svg-polylines svg (paliers *transcription*) largeur hauteur bas haut "#4fc3f7" 3)
    (format svg "</svg>~%")))
