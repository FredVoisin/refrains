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

(in-package :refrains/tests)

(def-suite distances :in refrains
  :description "3. Evaluation: distances and similarities.")
(in-suite distances)

(test dist-euclidean
  (is (approx= 5.0 (dist-euclidean '(0 0) '(3 4))))
  (is (approx= 0.0 (dist-euclidean '(1 2) '(1 2)))))

(test dist-cityblock
  (is (= 7 (dist-cityblock '(0 0) '(3 4)))))

(test dist-hamming
  (is (approx= 0.5 (dist-hamming '(a b c d) '(a x c y))))
  (is (= 2 (dist-hamming '(a b c d) '(a x c y) nil))))

(test dist-edit
  (is (= 0 (dist-edit '(a b c) '(a b c))))
  (is (= 3 (dist-edit '(a b c) '(x y z))))
  (is (= 3 (dist-edit '(k i t t e n) '(s i t t i n g))))
  (is (= 3 (dist-edit "kitten" "sitting")))
  (is (approx= 0.5 (dist-edit '(a b c d) '(a b) :norm t))))

(test dist-edit-symmetry
  (is (= (dist-edit '(a b c d e) '(b c x))
         (dist-edit '(b c x) '(a b c d e)))))

(test dist-multi-edit
  (is (approx= 0.25 (dist-multi-edit '((a 1) (b 2)) '((a 1) (c 2)) 1))))

(test dist-structure
  (is (approx= 0.0 (dist-structure '(a b a b) '(a b a b)))))

(test dist-graph
  (is (= 4 (dist-graph 'a 'd '((a b 1) (b c 2) (c d 1))))))

(test dist-euclid-number-list
  ;; used to map over the number instead of the list
  (is (equal '(1 4 2) (dist-euclid 1 '(2 5 -1))))
  (is (equal '(1 4 2) (dist-euclid '(2 5 -1) 1))))

(test dist-multi-edit-keywords
  ;; positional arguments used to be passed as keywords
  (finishes (dist-multi-edit '((a 1) (b 2)) '((a 1) (c 2)) 1 :sub 2)))

(test dist-multi-edit-weights
  (let ((a '((a 1 x) (b 2 y)))
        (b '((a 1 x) (c 2 z)))
        (*standard-output* (make-broadcast-stream)))
    ;; fewer events than dimensions, or fewer weights than dimensions, used to crash
    (is (approx= 1/3 (dist-multi-edit a b 1)))
    (is (approx= 1/3 (dist-multi-edit a b '(1 1))))
    (is (approx= 1/3 (dist-multi-edit a b '(1))))
    ;; more weights than dimensions used to scale the distance down
    (is (approx= 1/3 (dist-multi-edit a b '(1 1 1 1))))
    (is (approx= 1/6 (dist-multi-edit '((a 1) (b 2) (c 3)) '((a 1) (c 2) (c 3)) 1)))
    ;; a list of weights was not accepted
    (is (approx= 0.375 (dist-multi-edit a b '(2 1 1))))
    (is (approx= 0.375 (dist-multi-edit a b '(2 1))))
    (is (approx= 0.5 (dist-multi-edit a b '(1 0 0))))
    ;; all weights 0: all dimensions ignored (used to divide by zero)
    (is (approx= 0 (dist-multi-edit a b '(0 0 0))))
    (finishes (dist-multi-edit a b '(1 1) :uncom 0.5))
    ;; pairwise distances
    (is (approx= 1/3 (third (first (refrains::multi-edit-dist (list a b) nil 1)))))))

(test edit-dist-rewrite
  ;; edit-dist2: whether an element exists in the other sequence is decided by test (it was eql)
  (is (= 2 (refrains::edit-dist2 '(1.0 2) '(2 1) :inex 1)))
  (is (= 4 (refrains::edit-dist2 '(1.0 2) '(2 1) :inex 1 :test #'eql)))
  ;; usual values
  (is (= 1 (refrains::edit-dist1 '(a b c) '(a b d))))
  (is (= 3 (refrains::edit-dist1 '() '(a b c))))
  (is (approx= 1/3 (refrains::edit-dist1 '(a b c) '(a b d) :normalized t)))
  ;; two empty sequences, normalized, divided by zero
  (is (approx= 0 (refrains::edit-dist1 '() '() :normalized t)))
  (is (approx= 0 (refrains::edit-dist2 '() '() :inex 1 :normalized t))))

(test similarity-measures-no-division-by-zero
  ;; Jaccard: two empty sets are identical (division by zero)
  (is (approx= 0 (refrains::jaccard-dist '() '())))
  (is (approx= 0.5 (refrains::jaccard-dist '(a b c) '(b c d))))
  ;; the union is counted with key (it used equalp only: 0.5)
  (is (approx= 0 (refrains::jaccard-dist '((x 1)) '((x 2)) :key #'car)))
  (is (approx= 0 (refrains::jaccard-dist nil '(() ()))))
  ;; binary Jaccard: nothing present, or one value only (division by zero, nil)
  (is (approx= 0 (refrains::binary-jaccard-dist '(0 0 0) '(0 0 0) :test #'(lambda (x) (= x 1)))))
  (is (approx= 0 (refrains::binary-jaccard-dist '(1 1 1) '(1 1 1))))
  (is (approx= 0.8 (refrains::binary-jaccard-dist '(1 0 1 0 0 0 0) '(1 0 0 1 0 1 1))))
  (signals error (refrains::binary-jaccard-dist '(1 2 3) '(1 2 3)))
  ;; Sorensen: two empty sets are identical
  (is (approx= 1 (refrains::sorensen-similarity '() '())))
  (is (approx= 2/3 (refrains::sorensen-similarity '(a b c) '(b c d))))
  ;; Mountford, normalized to M / (1 + M): it divided by zero for identical sets
  (is (approx= 1 (refrains::mountford-similarity '(a b) '(a b))))
  (is (approx= 1 (refrains::mountford-similarity '() '())))
  (is (approx= 0 (refrains::mountford-similarity '(a) '(b))))
  (is (approx= 0 (refrains::mountford-similarity '() '(a b))))
  (is (approx= 2/3 (refrains::mountford-similarity '(a b c) '(a b))))
  (is (approx= 0.2 (refrains::mountford-similarity '(a b c d) '(c d e f)))))

(test dist-structure-any-element
  ;; strings, lists, and symbols mixed with numbers had no applicable method
  (is (approx= 0 (dist-structure '("a" "b" "a") '("x" "y" "x"))))
  (is (approx= 0 (dist-structure '((1 2) (3) (1 2)) '(x y x))))
  (is (approx= 0 (dist-structure '(a 1 a) '(x y x))))
  ;; :test is the identity of the elements (it compared the structure codes)
  (is (approx= 0 (dist-structure '("a" "A" "b") '(x x y))))
  (is (approx= 0.5 (dist-structure '("a" "A" "b") '(x x y) :test #'string=)))
  ;; the documented examples
  (is (approx= 0 (dist-structure '(a b a c a d a e a f g h) '(1 2 1 3 1 4 1 5 1 6 7 8))))
  (is (approx= 1/3 (dist-structure '(a b a c a d a e a f g h) '(a a a a a b c d e f g h))))
  (is (approx= 0.875 (dist-structure '(a b a c a d a e a f g h) '(x x x x y y y x x y y y)))))
