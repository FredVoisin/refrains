;;;; rougequeue-noir-sv-niveaux.lisp
;;;;
;;;; Transcrire le chant d'un rougequeue noir à partir des données brutes de son sonagramme,
;;;; exportées de Sonic Visualiser : les spectres instantanés, réduits en bandes, deviennent
;;;; des vecteurs dont chaque coordonnée est un niveau d'intensité (de 0, le silence, à 5),
;;;; classés par les nuées dynamiques de class-num (distance euclidienne). C'est une
;;;; extension de l'exemple de 2011 (doc/exemples/rougequeue-noir.md) et de son remake
;;;; (doc/lisp/rougequeue-noir-sv.lisp), qui classent des mots de 0 et de 1, présence ou
;;;; absence d'énergie, par class-sym.
;;;;
;;;; Les données : doc/data/rougequeue-noir01.csv, exportée de Sonic Visualiser 5.2.1
;;;; (calque du sonagramme, File > Export Annotation Layer) : une ligne d'en-tête (TIME, puis
;;;; la fréquence de chaque bande), puis une ligne par instant, le temps en secondes et
;;;; l'amplitude de chaque bande.
;;;;
;;;; (load "doc/lisp/rougequeue-noir-sv-niveaux.lisp") affiche les résultats et écrit le
;;;; sonagramme en texte (doc/pictures/rougequeue-noir01-niveaux.txt).
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

;; les réglages : le nombre de bandes de Sonic Visualiser regroupées en une (11 bandes de
;; 43,07 Hz font 474 Hz, proche des 490 Hz de l'image de 2011), le seuil en dB sous le
;; maximum du sonagramme, le nombre de niveaux d'intensité (le silence compris), et le nombre
;; de classes (le silence compris)
(defparameter *regroupement* 11)
(defparameter *seuil-db* 40)
(defparameter *niveaux* 6)
(defparameter *classes* 12)

;;; 1. La lecture : read-text lit chaque ligne comme une liste. Avec :sep ",", il sépare aux
;;; virgules, et aussi aux blancs : un export séparé par des tabulations se lit de même.

(defun lire-sonagramme (file)
  "Les fréquences des bandes (lues dans l'en-tête) et les spectres (sans le temps) de l'export file."
  (let ((lines (read-text file :sep ",")))
    ;; l'en-tête : TIME 0 Hz 43.0664 Hz ... ; les nombres en sont les fréquences
    (values (remove-if-not #'numberp (first lines))
            (mapcar #'rest (rest lines)))))

;;; 2. Les bandes : le maximum de chaque groupe de *regroupement* bandes

(defun bandes (spectre)
  (loop for tail on spectre by (lambda (l) (nthcdr *regroupement* l))
        collect (reduce #'max (subseq tail 0 (min *regroupement* (length tail))))))

;;; 3. Les mots : le niveau de chaque bande, 0 quand son amplitude est à plus de *seuil-db*
;;; sous le maximum du sonagramme, puis de 1 à *niveaux* - 1 par tranches égales en dB
;;; (8 dB pour 40 dB et 6 niveaux), le dernier niveau atteignant le maximum. Le seuil dépend
;;; du fichier (de son maximum), non d'un enregistrement de référence.

(defun niveau (a maximum)
  (let ((db (if (plusp a) (* 20 (log (/ a maximum) 10)) (- *seuil-db*))))
    (if (<= db (- *seuil-db*))
        0
        (max 1 (ceiling (* (- *niveaux* 1) (/ (+ db *seuil-db*) *seuil-db*)))))))

(defun mots (spectres)
  (let* ((reduits (mapcar #'bandes spectres))
         (maximum (reduce #'max (mapcar (lambda (b) (reduce #'max b)) reduits))))
    (mapcar (lambda (b) (mapcar (lambda (a) (niveau a maximum)) b)) reduits)))

;;; 4. Le sonagramme en texte, comme l'image de 2011 convertie par jp2a : une ligne par
;;; bande, les aigus en haut, une colonne par instant ; x pour le silence, puis le niveau
;;; de 1 à 5

(defun image (mots)
  (with-output-to-string (s)
    (loop for k from (1- (length (first mots))) downto 0
          do (format s "~{~A~}~%" (mapcar (lambda (m) (if (zerop (nth k m)) "x" (nth k m))) mots)))))

;; les bandes présentes d'un mot, en plages de fréquences contiguës, avec le niveau maximal
;; de chaque plage : "3,3-4,3 kHz (4)"
(defun plages (mot largeur)
  (let ((plages nil) debut (haut 0))
    (loop for x in (append mot (list 0)) for k from 0
          do (cond ((plusp x) (unless debut (setf debut k haut 0)) (setf haut (max haut x)))
                   (debut
                    (push (format nil "~,1F-~,1F kHz (~D)" (/ (* debut largeur) 1000) (/ (* k largeur) 1000) haut)
                          plages)
                    (setf debut nil))))
    (or (nreverse plages) (list "silence"))))

;;; 5. La classification : les nuées dynamiques de class-num, sur les spectres qui ne sont pas
;;; silencieux, le silence formant la classe 0. Avec la distance d'édition de class-sym, deux
;;; niveaux voisins (1 et 2) sont aussi différents que deux niveaux éloignés (1 et 5), et le
;;; lien simple enchaîne les spectres par petites différences : presque tous tombent dans une
;;; seule classe. La distance euclidienne tient compte de l'écart entre les niveaux.

;; les centres initiaux : les spectres distincts, triés par leur énergie (la somme de leurs
;; niveaux), pris à intervalles réguliers. Partir de centres donnés rend le résultat
;; reproductible, alors que des centres tirés au hasard donnent une partition à chaque essai.
(defun centres-initiaux (sons k)
  (let ((distincts (sort (remove-duplicates sons :test #'equal) #'< :key (lambda (s) (reduce #'+ s)))))
    (loop for i below k
          collect (nth (floor (* (+ i 1/2) (length distincts)) k) distincts))))

;; le centre de gravité de chaque classe, et la distance moyenne de ses spectres à ce centre
(defun centres (sons classes)
  (loop for c from 0 to (reduce #'max classes)
        collect (let* ((membres (loop for s in sons for k in classes when (= k c) collect s))
                       (centre (mapcar (lambda (x) (/ x (length membres)))
                                       (reduce (lambda (a b) (mapcar #'+ a b)) membres))))
                  (list centre (/ (reduce #'+ (mapcar (lambda (s) (dist-euclidean s centre)) membres))
                                  (length membres))))))

(defun analyse (file)
  (multiple-value-bind (frequences spectres) (lire-sonagramme file)
    (let* ((mots (mots spectres))
           (silence (make-list (length (first mots)) :initial-element 0))
           (sons (remove silence mots :test #'equal))
           (classes-sons (first (class-num sons (centres-initiaux sons (1- *classes*)) :centroids)))
           (largeur (* *regroupement* (- (second frequences) (first frequences)))))
      (let ((classes (let ((c classes-sons))
                       (mapcar (lambda (m) (if (equal m silence) 0 (1+ (pop c)))) mots))))
        (format t "~&~%=== ~A~%" (file-namestring file))
        (format t "~D spectres de ~D bandes (~,2F Hz), en ~D bandes de ~D Hz ; ~D silences, ~D spectres distincts~%"
                (length spectres) (length frequences) (- (second frequences) (first frequences))
                (length silence) (round largeur) (count silence mots :test #'equal)
                (length (remove-duplicates mots :test #'equal)))
        ;; la transcription : - pour le silence, une lettre par classe
        (format t "Transcription :~%~{~A~}~%"
                (mapcar (lambda (c) (if (zerop c) "-" (string-downcase (num>alpha (1- c))))) classes))
        ;; chaque classe : son nombre de spectres, la distance moyenne de ses spectres à son
        ;; centre, et les bandes de son centre (aux niveaux arrondis), en kHz
        (format t "  - : ~3D spectres, silence~%" (count 0 classes))
        (loop for (centre distance) in (centres sons classes-sons)
              for c from 1
              do (format t "~&  ~A : ~3D spectres, distance ~,2F, centre ~{~A~^, ~}~%"
                         (string-downcase (num>alpha (1- c))) (count c classes) distance
                         (plages (mapcar #'round centre) largeur)))
        (let ((texte (merge-pathnames (format nil "pictures/~A-niveaux.txt" (pathname-name file)) *doc*)))
          (with-open-file (o texte :direction :output :if-exists :supersede)
            (write-string (image mots) o))
          (format t "~&Sonagramme en texte : doc/pictures/~A~%" (file-namestring texte)))
        ;; la transcription, pour d'autres exemples (rougequeue-noir-arbres.lisp)
        classes))))

(analyse (merge-pathnames "data/rougequeue-noir01.csv" *doc*))
