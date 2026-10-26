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

(defun frequencies (data test)
  "The list of (element count) of the distinct elements of data (by test), in their order of first appearance."
  (let ((table nil))
    (map nil #'(lambda (x)
                 (let ((e (assoc x table :test test)))
                   (if e (incf (second e)) (push (list x 1) table))))
         data)
    (nreverse table)))

(defun histogramme (data &key (test #'equalp) (thes nil))
  "The list of (element count) of data, for the different elements (or those of thes): sorted by
increasing value for numbers, else by decreasing count, elements of equal count in their order of
first appearance (in data, or in thes)."
  (let ((histo (if thes
                   (mapcar #'(lambda (c) (list c (count-if #'(lambda (x) (funcall test c x)) data))) thes)
                   (frequencies data test))))
    (if (every #'numberp (mapcar #'first histo))
        (stable-sort histo #'< :key #'car)
        (stable-sort histo #'> :key #'cadr))))

;;;
;; info theory

(defun counts-entropy (counts base &optional (total (reduce #'+ counts)))
  "The Shannon entropy, in base base, of the distribution given by the counts, the probabilities being
the counts divided by total (their sum by default); the counts of 0 are ignored."
  ;; (- 0 x) and not (- x): 0.0 for a single element, not -0.0
  (- 0 (reduce #'+ (mapcar #'(lambda (c) (if (zerop c) 0 (let ((p (/ c total))) (* p (log p base)))))
                           counts))))

(defun successive-pairs (data)
  "The list of the pairs (x y) of successive elements of the sequence data."
  (loop for tail on (coerce data 'list)
        while (cdr tail)
        collect (list (first tail) (second tail))))

(defun pair-test (test)
  "The identity of two pairs: test on their first elements and on their second elements."
  #'(lambda (p q) (and (funcall test (first p) (first q)) (funcall test (second p) (second q)))))

(defun e-shannon (data &optional (base nil) (test #'equalp))
  "The Shannon entropy of data, in base base (nil: the number of distinct elements, at least 2):
from 0 to (log n base) for n distinct elements."
  (let ((counts (mapcar #'second (frequencies data test))))
    (counts-entropy counts (or base (max 2 (length counts))))))

(defun kind-of-entropie-conditionnelle (data &optional (base nil) (test #'equalp))
  "The entropy of the pairs of successive elements of data divided by 2 (a logarithm in base n^2, n the
number of distinct elements, or base^2), the probabilities of the pairs being divided by the length of data
(not by the number of pairs). Experimental: see the mode cond-sh of entropy."
  (let ((b (or base (max 2 (length (frequencies data test))))))
    (counts-entropy (mapcar #'second (frequencies (successive-pairs data) (pair-test test)))
                    (* b b)
                    (length data))))

(defun conditional-entropy (data &optional (base 2) (test #'equalp))
  "The conditional entropy H(x(t+1) | x(t)) of the sequence data: the uncertainty on an element knowing the
previous one, H(pairs) - H(first elements of the pairs), over the pairs of successive elements.
0 when each element determines the next one (a periodic sequence), up to the entropy of the elements
when the successions are random."
  (let ((pairs (successive-pairs data)))
    (if (null pairs)
        0
        (- (counts-entropy (mapcar #'second (frequencies pairs (pair-test test))) base)
           (counts-entropy (mapcar #'second (frequencies (mapcar #'first pairs) test)) base)))))

(defun self-information (data elt &optional (test #'equalp))
  "Amount of information of the element elt in data: -log2 of its frequency, nil if it is absent from data
(the information is infinite) or if data is empty. Element elt may be of any kind (symbol, number,
string, list...). If elt is null, the amount of information of each element of data, sorted in decreasing
order (equal amounts in the order of first appearance)."
  (let ((test (or test #'equalp))
        (n (length data)))
    (flet ((info (count) (- 0 (log (/ count n) 2))))
      (if elt
          (let ((count (count-if #'(lambda (x) (funcall test x elt)) data)))
            (unless (zerop count) (info count)))
          (stable-sort (mapcar #'(lambda (f) (list (first f) (info (second f)))) (frequencies data test))
                       #'> :key #'second)))))
