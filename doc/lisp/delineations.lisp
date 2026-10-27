;;;; delineations.lisp
;;;;
;;;; Délinéations : représentation rhizomatique d'un texte (F. Voisin, 2013), appliquée à
;;;; Alice's Adventures in Wonderland de Lewis Carroll (doc/data/Alice.txt, domaine public).
;;;; Les mots du texte, réduits à leurs formes distinctes, sont reliés par leur distance
;;;; d'édition : l'arbre de recouvrement minimal de ces distances rapproche les mots qui
;;;; s'écrivent de façon semblable, sans rien savoir de leur sens.
;;;;
;;;; (load "doc/lisp/delineations.lisp") affiche les étapes et dessine les arbres avec neato
;;;; (Graphviz) : doc/pictures/delineations-alice.svg (tout le livre) et
;;;; doc/pictures/delineations-alice-ch1.png (le chapitre I).
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

;;; 1. La lecture : read-text en mode plat (nil) donne la liste des mots du texte, toute la
;;; ponctuation servant de séparateur (:sep t), et les mots de moins de quatre lettres
;;; supprimés (:rem-test). Les mots sont mis en minuscules : « Alice » et « ALICE » sont le
;;; même mot.

(defparameter *mots*
  (mapcar #'string-downcase
          (read-text (merge-pathnames "data/Alice.txt" *doc*)
                     :mode nil :sep t :rem-test (lambda (w) (< (length w) 4)))))

;;; 2. Les mots distincts : les répétitions supprimées, puis les mots qui diffèrent d'au plus
;;; un caractère tenus pour identiques, la distance d'édition servant de test à
;;; remove-duplicates. Le premier mot rencontré dans le texte est gardé (:from-end t).

(defun distincts (mots)
  (remove-duplicates (remove-duplicates mots :test #'string= :from-end t)
                     :test (lambda (a b) (<= (dist-edit a b) 1))
                     :from-end t))

;;; 3. L'arbre : la semi-matrice des distances d'édition entre les mots, dont graph-span
;;; garde l'arbre de recouvrement minimal. :uncom 1 ajoute 1 au coût de la substitution
;;; d'un caractère qui n'est pas commun aux deux mots : il éloigne les mots faits de lettres
;;; différentes, dans l'espoir de rapprocher les mots de même racine. dist-edit numérote les
;;; mots ; les nœuds de l'arbre sont les mots eux-mêmes.

(defun arbre (mots)
  (let ((v (coerce mots 'vector)))
    (mapcar (lambda (e) (list (aref v (first e)) (aref v (second e)) (third e)))
            (graph-span (dist-edit mots nil :uncom 1)))))

;; le chapitre I : les mots du premier « chapter » au suivant
(defun chapitre-1 (mots)
  (let ((debut (position "chapter" mots :test #'string=)))
    (subseq mots debut (position "chapter" mots :test #'string= :start (1+ debut)))))

;;; 4. Le livre entier, puis le chapitre I

(defun delineation (nom mots fichier &rest options)
  (let* ((d (distincts mots))
         (a (arbre d)))
    (format t "~&~%~A : ~D mots, ~D distincts, ~D après la fusion des mots à un caractère près~%"
            nom (length mots) (length (remove-duplicates mots :test #'string=)) (length d))
    (format t "longueurs des arêtes (longueur, nombre) : ~S~%"
            (sort (histogram (mapcar #'third a)) #'< :key #'first))
    (format t "les nœuds de plus haut degré : ~{~{~A (~D)~}~^, ~}~%"
            (mapcar (lambda (x) (list (second x) (first x)))
                    (subseq (stable-sort (mapcar (lambda (n) (list (graph-degree n a) n)) (graph-nodes a))
                                         #'> :key #'first)
                            0 8)))
    (apply #'graph>dot a :out (merge-pathnames fichier *doc*) options)
    (format t "dessin : doc/~A~%" fichier)
    a))

(defparameter *livre*
  (delineation "Le livre" *mots* "pictures/delineations-alice.svg" :shape "plaintext" :legend nil))

(defparameter *chapitre-1*
  (delineation "Le chapitre I" (chapitre-1 *mots*) "pictures/delineations-alice-ch1.png"
               :shape "plaintext" :legend nil :overlap nil))

;;; 5. Un chemin dans l'arbre du livre : de mot en mot, par les ressemblances d'écriture

;; « queen » n'est pas dans l'arbre : à un caractère de « queer », rencontré avant lui dans le
;; texte, il a été fusionné avec lui (comme « hatter » avec « matter », « mouse » avec « house »)
(format t "~&~%De « rabbit » à « queer » (queen) : ~{~A~^ — ~}~%" (graph-path "rabbit" "queer" *livre*))
(format t "De « alice » à « turtle » : ~{~A~^ — ~}~%" (graph-path "alice" "turtle" *livre*))
