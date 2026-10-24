;;;; This file is part of refrains.
;;;; Copyright (C) 1992-2026 Frederic Voisin
;;;;
;;;; refrains is derived from fv-morphologie
;;;; (https://github.com/FredVoisin/fv-morphologie), itself derived from
;;;; Morphologie (https://github.com/openmusic-project/Morphologie), released
;;;; under GPL-3.0.
;;;;
;;;; This program is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License version 3
;;;; as published by the Free Software Foundation.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;;;
;;;; SPDX-License-Identifier: GPL-3.0-only

;;;; api/help.lisp
;;;;
;;;; Public functions: the menu of the functions, doc and help.

(in-package :refrains)

(defun generic-function-p (self)
  "T if self is a class of <standard-generic-function>."
  (or (eq (class-name
           (class-of self))
          'standard-generic-function)
      (eq (class-name
       (class-of self))
      'compiled-function)))

(defun find-functions (&optional (package (find-package 'refrains)))
  "Give the list of generic functions in <package>."
  (when (symbolp package) (setf package (find-package package)))
  (let
    ((func '()))
    (do-symbols (sym package)
      (when (eq package (symbol-package sym))
        (let ((value (when (fboundp sym) (symbol-function sym))))
          (when (and value
		     (or ;(compiled-function-p value)
			 ;(function-p value)
			 (generic-function-p value)))
            (push sym func)))))
    (sort func #'string-lessp)))

;(print (find-functions))

(defparameter *refrains-menu*
  '(;; 1. transcription
    transcode num>base num>alpha alpha>num list>sym str>sym filt-noise
    filt-median filt-extrema filt-mean filt-lowpass filt-repeat filt-function
    graph-span graph>dendrogram graph-path graph>dot dendrogram>dot graph>matrix
    morph-seq
    ;; 2. classification
    exsample separate graph-part
    motif-group
    mark-structure motif-structure class-num class-sym
    ;; 3. evaluation
    mark-position mark-list motif-position motif-list graph-nodes graph-leaves
    dist-euclidean dist-cityblock dist-hamming dist-edit dist-multi-edit
    dist-structure dist-graph
    histogram entropy self-info inner-dynamic graph-length graph-degree
    ;; 4. reading and writing files
    read-text write-list display-list date-string date+time-string
    ;; documentation
    help doc)
  "The refrains functions, in the order of the documentation (all the exported functions).")


(defun fv-function (name)
  "The refrains symbol named name (a symbol of any package, a keyword or a string), or nil."
  (find-symbol (string-upcase (string name)) :refrains))

(defgeneric doc (&optional fct)
  (:documentation
  "DOC: Prints out the documentation of some refrains function(s).
If no argument, prints out the list of all generic functions.
If argument is a symbol (of any package, or a keyword or a string) or a list of them, prints out documentation
of the corresponding functions; list gives the list of the functions, all prints out all their documentations.
Exemples: 
(doc)
(doc 'dist-edit)"))

(defmethod doc (&optional (fct nil))
  ;; functions found by name in refrains ('dist-edit from cl-user was cl-user::dist-edit)
  (cond
    ((not fct)
     (format t "~%refrains generic functions :")
     (dolist (d *refrains-menu* (format t "~%")) (format t "~% ~(~S~)" d)))
    ((listp fct) (dolist (f fct) (format t "~S~%~%" (documentation (fv-function f) 'function))))
    ((string-equal (string fct) "LIST") *refrains-menu*)
    ((string-equal (string fct) "ALL")
     (dolist (d *refrains-menu* (format t "~%")) (format t "~S~%~%" (documentation d 'function))))
    (t (let ((f (fv-function fct)))
         (and f (documentation f 'function))))))

(defun doc-words (f)
  "The words of the name and of the documentation of the function f, in lower case."
  (mapcar #'string-downcase
          (append (split-string (symbol-name f) "->")
                  (split-string (or (documentation f 'function) "") "(<>) ,;.!:?'\"#*[]{}|=/-"))))

(defun word-similarity (word key)
  "1 if word contains key, else 1 - the normalized edit distance between them (case ignored)."
  (if (search key word :test #'char-equal)
      1
      (- 1 (edit-dist1 (coerce word 'list) (coerce key 'list) :normalized t :test #'char-equal))))

(defgeneric help (&optional keyword threshold)
  (:documentation "HELP: looks for a keyword (a symbol of any package, a keyword or a string) in the names and the
documentation of the refrains functions, prints out the documentation of the functions found, the most
similar first, and returns the list of their names. A word of a name or of a documentation matches if it contains
the keyword, or if its similarity with the keyword (1 - normalized edit distance, case ignored) is at least
<threshold> (0.75 by default, from 0 to 1).
If no argument (keyword), prints out the list of all generic functions."))

(defmethod help (&optional (keyword nil) (threshold .75))
  ;; the keyword was compared with the words of the documentations, but the matches were
  ;; neither filtered (threshold), nor attached to their functions: help printed all the scores
  (if (not keyword)
      (doc)
      (let* ((key (string-downcase (string keyword)))
             (found (loop for f in *refrains-menu*
                          for score = (reduce #'max (mapcar #'(lambda (w) (word-similarity w key)) (doc-words f))
                                              :initial-value 0)
                          when (>= score threshold) collect (cons f score)))
             (sorted (stable-sort found #'> :key #'cdr)))
        (dolist (fs sorted)
          (format t "~&~(~S~)~%~A~%~%" (car fs) (or (documentation (car fs) 'function) "")))
        (mapcar #'car sorted))))

;(help)
;(help 'graph)

;(doc)
;(doc 'list)
;(doc 'all)
;(doc 'dist-edit)

;eof
