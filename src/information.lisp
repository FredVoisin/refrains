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

;;;; information.lisp
;;;;
;;;; Statistics and information: histograms, Shannon entropy, conditional
;;;; entropy, self-information.

(in-package :refrains)

;;;
;; stats

(defun histogramme (data &key (test #'equalp) (thes nil))
  "The list of (element count) of data, for the different elements (or those of thes): sorted by
increasing value for numbers, else by decreasing count, elements of equal count in their order of
first appearance (in data, or in thes)."
  (let* ((cl (or thes (remove-duplicates data :test test :from-end t)))
         (histo (mapcar #'(lambda (c) (list c (count-if #'(lambda (x) (funcall test c x)) data)))
                        cl)))
    (if (every #'numberp cl)
        (stable-sort histo #'< :key #'car)
        (stable-sort histo #'> :key #'cadr))))

;;;
;; info theory

(defun e-shannon (data &optional (base nil) (test #'equalp))
  "Returns the shannon entropy value of data.
Shannon entropy value may be between 0 and (log n base)."
  (let* ((cl (remove-duplicates data :test test))
	 (n (length data))
	 (p nil)
	 (b (if (numberp base)
		base (if (eql base 'e)
			 (exp 1)
			 (max 2 (length cl))))))
    (dolist (ci cl (- 0 (reduce #'+ (mapcar #'(lambda (x) (* x (log! x b))) p))))
      (push (/ (length (remove-if-not #'(lambda (x) (funcall test x ci)) data)) n)
            p))))

(defun kind-of-entropie-conditionnelle (data &optional (base 2) (test #'equalp))
  "Kind of conditionnal entropy based on a hack of shannon entropy by me. Experimental."
  (let* ((p nil) (len (length data))
	 ;; the distinct symbols by test, as they are counted (equalp failed with a stricter test)
	 (s (remove-duplicates data :test test))
	 (n (length s))
	 (b (if (numberp base)
		base (if (eql base 'e) (exp 1) (max 2 n))))
	 (r (mapcar (lambda (x) (cons x (mapcar (lambda (y) (list y 0)) s))) s)))
    (dotimes (d (1- (length data))) ;build table of P(a if b)
      (let ((k (assoc (nth d data) r :test test))
	    (l (nth (1+ d) data)))
	(incf (cadr (assoc l (cdr k) :test test)) )))
    (dolist (i r (- 0 (reduce #'+ (mapcar #'(lambda (x) (* x (log! x (* b b)))) p)))) ; sqr log to scale
      (dolist (j (cdr i))
	(push (/ (cadr j) len) p))))) ; P(i)

;(kind-of-entropie-conditionnelle (loop for i from  0 to 1000 collect (random 2)) nil)

(defun distinct-counts (items test)
  "The number of occurrences of each distinct element of items (by test)."
  (let ((distinct nil))
    (dolist (x items (mapcar #'cdr distinct))
      (let ((d (assoc x distinct :test test)))
        (if d (incf (cdr d)) (push (cons x 1) distinct))))))

(defun counts-entropy (counts base)
  "The Shannon entropy, in base base, of the distribution given by the counts."
  (let ((n (reduce #'+ counts)))
    (- (reduce #'+ (mapcar #'(lambda (c) (let ((p (/ c n))) (* p (log p base)))) counts)))))

(defun conditional-entropy (data &optional (base 2) (test #'equalp))
  "The conditional entropy H(x(t+1) | x(t)) of the sequence data: the uncertainty on an element knowing the
previous one, H(pairs) - H(first elements of the pairs), over the pairs of successive elements.
0 when each element determines the next one (a periodic sequence), up to the entropy of the elements
when the successions are random."
  (let ((pairs (loop for tail on (coerce data 'list)
                     while (cdr tail)
                     collect (list (first tail) (second tail)))))
    (if (null pairs)
        0
        (- (counts-entropy (distinct-counts pairs #'(lambda (p q) (and (funcall test (first p) (first q))
                                                                       (funcall test (second p) (second q)))))
                           base)
           (counts-entropy (distinct-counts (mapcar #'first pairs) test) base)))))

(defgeneric self-information (data elt &optional test)
  (:documentation "Amount of information of each element <elt> in data: -log2 of its frequency, nil if
it is absent from data (the information is infinite) or if data is empty.
Element <elt> may be of any kind (symbol, number, string, list...).
If <elt> is null, self-information returns the amount of information for each element in data,
sorted in decreasing order of amount of information in data (equal amounts in the order of first appearance)."))

(defmethod self-information ((data list) (elt t) &optional (test #'equalp))
  (when (not test) (setf test #'equalp))
  (let ((n (count-if #'(lambda (x) (funcall test x elt)) data)))
    (if (zerop n)
        nil
        (- 0 (log (/ n (length data)) 2)))))

(defmethod self-information ((data list) (elt null) &optional (test #'equalp))
  (when (not test) (setf test #'equalp))
  (let ((elts (remove-duplicates data :test test :from-end t)))
    (stable-sort (mapcar #'(lambda (x) (list x (self-information data x test))) elts) '> :key #'second)))
