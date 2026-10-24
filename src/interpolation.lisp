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

;;;; interpolation.lisp
;;;;
;;;; Interpolation of two sequences of symbols (Levenshtein).

(in-package :refrains)

;; s-interpolate.lisp
;; interpolate two lists as sequences of symbols using some levenshtein distance algorithm.
;; Fred Voisin, pour Julien Vincenot, 2013.

(defun levenshtein-matrix (a b test)
  "The matrix d of the edit distances from the prefixes of vector a to those of vector b:
d(i,j) is the distance from the first i elements of a to the first j elements of b."
  (let* ((m (length a))
         (n (length b))
         (d (make-array (list (1+ m) (1+ n)))))
    (dotimes (i (1+ m)) (setf (aref d i 0) i))
    (dotimes (j (1+ n)) (setf (aref d 0 j) j))
    (loop for i from 1 to m
          do (loop for j from 1 to n
                   do (setf (aref d i j)
                            (min (1+ (aref d (1- i) j))
                                 (1+ (aref d i (1- j)))
                                 (+ (aref d (1- i) (1- j))
                                    (if (funcall test (aref a (1- i)) (aref b (1- j))) 0 1))))))
    d))

(defun edit-path (a b test random)
  "The positions (i j) of an alignment of minimal cost from vector a to vector b, from (0 0) to (m n):
at each step, i elements of a have been replaced by j elements of b. For equal costs, the substitution
is preferred, then the deletion, then the insertion; or one of them at random if random is true."
  (let* ((d (levenshtein-matrix a b test))
         (i (length a))
         (j (length b))
         (path (list (list i j))))
    (loop until (and (zerop i) (zerop j))
          do (let* ((here (aref d i j))
                    (moves (remove nil
                                   (list (when (and (plusp i) (plusp j)
                                                    (= here (+ (aref d (1- i) (1- j))
                                                               (if (funcall test (aref a (1- i)) (aref b (1- j))) 0 1))))
                                           (list (1- i) (1- j)))
                                         (when (and (plusp i) (= here (1+ (aref d (1- i) j))))
                                           (list (1- i) j))
                                         (when (and (plusp j) (= here (1+ (aref d i (1- j)))))
                                           (list i (1- j))))))
                    (move (if random (nth (random (length moves)) moves) (car moves))))
               (setf i (first move) j (second move))
               (push move path)))
    path))

(defun s-interpolate (a b &key (test #'equalp) (random nil))
  "The sequences from a to b changing one element at a time (substitution, deletion or insertion) along
an edit path of minimal cost: the first is a, the last is b, and there are as many steps as the edit
distance. Each sequence is the beginning of b followed by the end of a."
  (let* ((va (coerce a 'vector))
         (vb (coerce b 'vector))
         (r (list (coerce a 'list))))
    (loop for (p q) on (edit-path va vb test random)
          while q
          unless (and (= (first q) (1+ (first p))) (= (second q) (1+ (second p)))
                      (funcall test (aref va (first p)) (aref vb (second p))))
            do (push (append (coerce (subseq vb 0 (second q)) 'list)
                             (coerce (subseq va (first q)) 'list))
                     r))
    (nreverse r)))

;(s-interpolate '(a m p h o r a) '(p o u l e t))
