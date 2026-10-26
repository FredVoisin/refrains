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

(def-suite information :in refrains
  :description "3. Evaluation: information.")
(in-suite information)

(test histogram
  (is (equal '((a 3) (b 2) (c 1)) (histogram '(a b a c a b)))))

(test entropy
  ;; entropy prints its mode to standard output
  (let ((*standard-output* (make-broadcast-stream)))
    (is (approx= 0.0 (entropy '(a a a a))))
    (is (approx= 1.0 (entropy '(a b a b))))
    (is (approx= 2.0 (entropy '(a b c d))))))

(test self-info
  (is (approx= 1.0 (self-info '(a b a c) 'a))))

(test histogram-test-and-order
  ;; the default test was eq: equal strings or lists were not counted together
  (is (equal '(("a" 2) ("b" 1)) (histogram '("a" "b" "a"))))
  (is (equal '(((1 2) 2) ((3) 1)) (histogram '((1 2) (3) (1 2)))))
  (is (equal '(("The" 2) ("cat" 1)) (histogram '("The" "cat" "the"))))
  (is (equal '(("The" 1) ("cat" 1) ("the" 1)) (histogram '("The" "cat" "the") :test #'equal)))
  ;; equal counts in the order of first appearance (it was arbitrary)
  (is (equal '((b 2) (a 2) (c 1)) (histogram '(b a c a b))))
  (is (equal '((c 1) (b 1) (a 1)) (histogram '(c b a))))
  (is (equal '((b 1) (a 1) (c 0)) (histogram '(a b) :thes '(c b a))))
  ;; numbers by increasing value
  (is (equal '((1 2) (2 1) (3 3)) (histogram '(3 1 2 1 3 3))))
  (is (null (histogram '()))))

(test entropy-modes
  ;; modes were compared with eq to the symbols of refrains: from another package,
  ;; 'shannon-2 or :shannon-2 printed "unknown mode" and returned nil
  (let ((*package* (find-package :cl-user)))
    (is (approx= 2 (entropy '(a b c d) :mode (intern "SHANNON-2" :cl-user)))))
  (is (approx= 2 (entropy '(a b c d) :mode :shannon-2)))
  (is (approx= 0.9463947 (entropy '(a b a c) :mode "shannon-n")))
  (is (approx= (log 2) (entropy '(a b) :mode :shannon-e)))
  (is (approx= 0.5141604 (entropy '(a b a b a b) :mode :cond-sh)))
  ;; windows: the same for all the modes (cond-sh took a number of windows as their length)
  (let ((d (loop for i below 100 collect (mod (* i i) 7))))
    (is (= 4 (length (entropy d :window 1/4))))
    (is (= 4 (length (entropy d :mode :cond-sh :window 1/4))))
    (is (= 4 (length (entropy d :mode :cond-sh :window 25))))
    (is (approx= (entropy (subseq d 25 50) :mode :cond-sh) (second (entropy d :mode :cond-sh :window 1/4)))))
  ;; sliding windows: a step smaller than the window
  (is (equal '(1.0 1.0 1.0 1.0 0.0 0.0 0.0) (entropy '(a b a b a a a a) :window 2 :step 1)))
  (let ((e (entropy '(a b a b a a a a) :window 4 :step 1/2)))   ; abab abaa aaaa
    (is (= 3 (length e)))
    (is (every #'approx= '(1.0 0.8112781 0.0) e)))
  (signals error (entropy '(a b c) :window 3.0))
  (signals error (entropy '(a b c) :window 2 :step 0))
  ;; cond-sh with a test stricter than equalp: the distinct symbols were taken with equalp, an error
  (is (approx= 0.72877127 (entropy '(1 1.0 2 1 2) :mode :cond-sh :test #'equalp)))
  (is (realp (entropy '(1 1.0 2 1 2) :mode :cond-sh :test #'eql)))
  (is (realp (entropy '("a" "A" "b") :mode :cond-sh :test #'equal)))
  ;; the default mode printed a message at each call
  (is (equal "" (with-output-to-string (*standard-output*) (entropy '(a b a b)))))
  ;; an unknown mode printed a message and returned nil
  (signals error (entropy '(a b c) :mode :foo))
  ;; always floats (0 and lists mixing 0 and 0.0)
  (is (eql 0.0 (entropy '() :mode :shannon-2)))
  (is (every #'floatp (entropy '(a b) :window 1/5)))
  (is (equal '(1.0 1.0 0.0 0.0) (entropy '(a b a b a a a a) :window 1/4))))

(test entropy-conditional
  ;; H(x(t+1) | x(t)): 0 when each element determines the next one
  (is (approx= 0 (entropy '(a b a b a b) :mode :conditional)))
  (is (approx= 0 (entropy (loop repeat 20 append '(a b c)) :mode :conditional)))
  ;; (a a b b): H(pairs aa ab bb) - H(a a b) = log2 3 - 0.918
  (is (approx= 2/3 (entropy '(a a b b) :mode :conditional)))
  (is (approx= 0 (entropy '() :mode :conditional)))
  (is (approx= 0 (entropy '(a) :mode :conditional)))
  ;; random successions: near the entropy of the elements
  (let ((*random-state* (seeded-random-state 5)))
    (let ((d (loop repeat 4000 collect (if (zerop (random 2)) 'a 'b))))
      (is (< 0.98 (entropy d :mode :conditional) 1.0))))
  (is (= 2 (length (entropy '(a b a b a a a a) :mode :conditional :window 1/2)))))

(test self-info-any-element
  ;; an absent element, or empty data, divided by zero: nil (the information is infinite)
  (is (null (self-info '(a b c) 'z)))
  (is (null (self-info '() 'a)))
  (is (null (self-info '() nil)))
  ;; strings, decimal numbers and lists had no applicable method
  (is (approx= (- (log 2/3 2)) (self-info '("x" "y" "x") "x")))
  (is (approx= 1 (self-info '(1.5 2.5 1.5 3.5) 1.5)))
  (is (approx= (- (log 2/3 2)) (self-info '((1 2) (3) (1 2)) '(1 2))))
  ;; nil: every element, with test, equal amounts in the order of first appearance
  (is (equal '((b 2.0) (c 2.0) (a 1.0)) (self-info '(a b a c) nil)))
  (is (equal '("The" "the" "cat") (mapcar #'first (self-info '("The" "the" "cat") nil #'equal))))
  (is (approx= 0 (self-info '(a a a) 'a))))
