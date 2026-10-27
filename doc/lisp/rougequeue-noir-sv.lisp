;;;; rougequeue-noir-sv.lisp
;;;;
;;;; Transcrire le chant d'un rougequeue noir à partir de son sonagramme exporté de Sonic
;;;; Visualiser : les spectres instantanés, réduits en bandes, deviennent des mots de 0 et
;;;; de 1 (présence ou absence d'énergie au-dessus d'un seuil), classés par class-sym.
;;;; C'est un remake de l'exemple de 2011 (doc/exemples/rougequeue-noir.md), à partir des
;;;; données du sonagramme et non de son image : les mots de 0 et de 1 simulent ce que
;;;; donnerait jp2a de l'image exportée de Sonic Visualiser (voir 3.), pour se remettre dans
;;;; les conditions de 2011.
;;;;
;;;; Les données : doc/data/rougequeue-noir*.csv, exportées de Sonic Visualiser 5.2.1
;;;; (calque du sonagramme, File > Export Annotation Layer) : une ligne d'en-tête (TIME, puis
;;;; la fréquence de chaque bande), puis une ligne par instant, le temps en secondes et
;;;; l'amplitude de chaque bande. Chaque fichier trouvé est analysé : un fichier ajouté
;;;; (une autre variante du chant) l'est aussi.
;;;;
;;;; (load "doc/lisp/rougequeue-noir-sv.lisp") affiche les résultats et écrit, pour chaque
;;;; fichier, son sonagramme en texte (doc/pictures/rougequeue-noir*.txt).
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
;; maximum du sonagramme, et le nombre de classes
(defparameter *regroupement* 11)
(defparameter *seuil-db* 40)
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

;;; 3. Les mots : 1 quand l'amplitude d'une bande est à moins de *seuil-db* du maximum du
;;; sonagramme, 0 sinon. Le seuil dépend du fichier (de son maximum), non d'un enregistrement
;;; de référence.
;;;
;;; C'est une simulation de jp2a. En 2011, le sonagramme était une image, que jp2a
;;; convertissait en texte en seuillant sa luminosité : chaque point devenait noir (.) ou
;;; blanc (x), et le seuil dépendait du réglage d'affichage du sonagramme. On pourrait faire
;;; de même avec l'image exportée de Sonic Visualiser (en SVG, avec ses tuiles PNG), mais ses
;;; couleurs et son bruit de fond rendent le seuil difficile à régler. On seuille donc
;;; directement les amplitudes, à 40 dB sous le maximum : la donnée est la même que celle
;;; de 2011, présence ou absence d'énergie, sans passer par l'image.
;;;
;;; Le seuil est écrit ici, car refrains n'a pas de fonction de seuil fixe : filt-quantize à
;;; 2 niveaux trouve son seuil dans les données (par les nuées dynamiques), et il est loin de
;;; 40 dB. Sur rougequeue-noir01.csv, il est vers -72 dB sur les amplitudes en dB (le bruit de
;;; fond compte alors comme de l'énergie), et vers -19 dB sur les amplitudes (seules les
;;; notes les plus fortes restent).

(defun mots (spectres)
  (let* ((reduits (mapcar #'bandes spectres))
         (maximum (reduce #'max (mapcar (lambda (b) (reduce #'max b)) reduits)))
         (seuil (* maximum (expt 10 (/ (- *seuil-db*) 20)))))
    (mapcar (lambda (b) (mapcar (lambda (a) (if (> a seuil) 1 0)) b)) reduits)))

;;; 4. Le sonagramme en texte, comme l'image de 2011 convertie par jp2a : une ligne par
;;; bande, les aigus en haut, une colonne par instant ; x pour le silence, . pour l'énergie

(defun image (mots)
  (with-output-to-string (s)
    (loop for k from (1- (length (first mots))) downto 0
          do (format s "~{~A~}~%" (mapcar (lambda (m) (if (= 1 (nth k m)) "." "x")) mots)))))

;; les bandes présentes d'un mot, en plages de fréquences contiguës : "3,3-4,3 kHz"
(defun plages (mot largeur)
  (let ((plages nil) debut)
    (loop for x in (append mot (list 0)) for k from 0
          do (cond ((and (= x 1) (null debut)) (setf debut k))
                   ((and (= x 0) debut)
                    (push (format nil "~,1F-~,1F kHz" (/ (* debut largeur) 1000) (/ (* k largeur) 1000)) plages)
                    (setf debut nil))))
    (or (nreverse plages) (list "silence"))))

;;; 5. La classification : class-sym, avec les coûts du patch de 2011 (insertion et
;;; suppression 1,5), le silence exclu (la classe 0), et la médiane de chaque classe

(defun analyse (file)
  (multiple-value-bind (frequences spectres) (lire-sonagramme file)
    (let* ((mots (mots spectres))
           (silence (make-list (length (first mots)) :initial-element 0))
           (largeur (* *regroupement* (- (second frequences) (first frequences)))))
      (multiple-value-bind (classes medianes)
          (class-sym mots *classes* :edit-nn :ins 1.5 :del 1.5 :excluded (list silence) :medians t)
        (format t "~&~%=== ~A~%" (file-namestring file))
        (format t "~D spectres de ~D bandes (~,2F Hz), en ~D bandes de ~D Hz ; ~D silences, ~D spectres distincts~%"
                (length spectres) (length frequences) (- (second frequences) (first frequences))
                (length silence) (round largeur) (count silence mots :test #'equal)
                (length (remove-duplicates mots :test #'equal)))
        ;; la transcription : - pour le silence, une lettre par classe
        (format t "Transcription :~%~{~A~}~%"
                (mapcar (lambda (c) (if (zerop c) "-" (string-downcase (num>alpha (1- c))))) classes))
        ;; chaque classe : son nombre de spectres, la cohésion (LSI moyen à la médiane) et les
        ;; bandes de sa médiane, en kHz
        (loop for (mediane lsi) in medianes
              for c from 0
              do (format t "~&  ~A : ~3D spectres, LSI ~,2F, médiane ~{~A~^, ~}~%"
                         (if (zerop c) "-" (string-downcase (num>alpha (1- c))))
                         (count c classes) lsi (plages mediane largeur)))
        (let ((texte (merge-pathnames (format nil "pictures/~A.txt" (pathname-name file)) *doc*)))
          (with-open-file (o texte :direction :output :if-exists :supersede)
            (write-string (image mots) o))
          (format t "~&Sonagramme en texte : doc/pictures/~A~%" (file-namestring texte)))))))

(dolist (file (sort (directory (merge-pathnames "data/rougequeue-noir*.csv" *doc*)) #'string<
                    :key #'namestring))
  (analyse file))
