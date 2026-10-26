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

(def-suite filtering :in refrains
  :description "1. Transcription: preprocessing (filters).")
(in-suite filtering)

(test filters
  (is (equal '(1 1 1 1 1 1 1) (filt-median '(1 9 1 1 1 9 1) 3)))
  (is (equal '(a b c a) (filt-repeat '(a a b b b c a a)))))

(test filt-lowpass-double
  ;; (1- alpha) is alpha - 1, not 1 - alpha: constants were not kept,
  ;; and the last value was missing
  (is (every #'approx= '(5 5 5 5 5) (filt-lowpass '(5 5 5 5 5) 0.5 0.5)))
  (is (every #'approx= '(0 1 2 3 4 5) (filt-lowpass '(0 1 2 3 4 5) 0.3 0.7)))
  (is (every #'approx= '(0 10 10 12.5 8.125) (filt-lowpass '(0 10 0 10 0) 0.5 0.5)))
  (is (= 5 (length (filt-lowpass '(0 10 0 10 0) 0.5 0.5))))
  (is (equal '(3) (filt-lowpass '(3) 0.5 0.5)))
  ;; simple smoothing
  (is (every #'approx= '(0 5 2.5 6.25 3.125) (filt-lowpass '(0 10 0 10 0) 0.5)))
  (is (null (filt-lowpass '() 0.5))))

(test filt-median-centred
  ;; the window looked ahead over w+1 values: steps and ramps were shifted
  (is (equal '(0 0 0 0 10 10 10 10) (filt-median '(0 0 0 0 10 10 10 10) 3)))
  (is (equal '(1 2 3 4 5 6 7 8) (filt-median '(1 2 3 4 5 6 7 8) 3)))
  ;; a peak is removed if narrower than half the window, kept otherwise
  (is (equal '(0 0 9 9 0 0 0) (filt-median '(0 0 9 9 0 0 0) 3)))
  (is (equal '(0 0 0 0 0 0 0 0 0) (filt-median '(0 0 0 9 9 0 0 0 0) 5)))
  ;; the first and last values are repeated at the edges: edge peaks are kept
  (is (equal '(9 0 0 0) (filt-median '(9 0 0 0) 3)))
  (is (equal '(0 0 0 9) (filt-median '(0 0 0 9) 3)))
  ;; odd windows only, so that the result is made of values of seq:
  ;; an even window is enlarged to the next odd size
  (is (equal (filt-median '(1 5 2 8 3) 5) (filt-median '(1 5 2 8 3) 4)))
  (is (equal '(1 2 3 3 3) (filt-median '(1 5 2 8 3) 4)))
  (is (subsetp (filt-median '(1 5 2 8 3 7 4) 4) '(1 5 2 8 3 7 4)))
  ;; same length, short lists filtered too, real window
  (is (equal '(5 5 5 5 5) (filt-median '(5 1 5 5 5) 3)))
  (is (equal '(2 2 3) (filt-median '(2 1 3) 3)))
  (is (equal '(1 1 1 1 1 1 1) (filt-median '(1 9 1 1 1 9 1) 3/7)))
  ;; the window as for all the functions with windows: an integer, or a part of the length in ]0, 1]
  (signals error (filt-median '(1 9 1 1 1 9 1) 3.0))
  (signals error (filt-median '(1 9 1 1 1 9 1) -1))
  (is (equal '(4 2 7) (filt-median '(4 2 7) 1)))
  (is (null (filt-median '() 3))))

(test filt-mean-centred
  ;; the window looked ahead: steps and peaks were moved earlier
  (is (every #'approx= '(0 0 0 10/3 20/3 10 10 10) (filt-mean '(0 0 0 0 10 10 10 10) 3)))
  (is (every #'approx= '(0 0 3 3 3 0 0) (filt-mean '(0 0 0 9 0 0 0) 3)))
  ;; ramps are kept, ends included: the window shrinks symmetrically at the edges
  (is (every #'approx= '(1 2 3 4 5 6 7 8) (filt-mean '(1 2 3 4 5 6 7 8) 3)))
  (is (every #'approx= '(9 3 0 0 0) (filt-mean '(9 0 0 0 0) 3)))
  ;; an even window is enlarged to the next odd size
  (is (equal (filt-mean '(1 5 2 8 3 7) 5) (filt-mean '(1 5 2 8 3 7) 4)))
  ;; block mode: step = wind averages each block
  (is (every #'approx= '(2 2 2 5 5 5 8 8 8) (filt-mean '(1 2 3 4 5 6 7 8 9) 3 3)))
  (is (every #'approx= '(3 3 3 3 3 8 8 8 8 8) (filt-mean '(1 2 3 4 5 6 7 8 9 10) 3 5)))
  ;; a float window too small for the list used to divide by zero
  (is (every #'approx= '(1 2 3 4 5 6) (filt-mean '(1 2 3 4 5 6) 0.01)))
  (is (null (filt-mean '() 3))))

(test window-apply-list-order
  ;; list results were reversed within each window
  (is (equal '(1 2 3 4 5 6) (filt-function '(1 2 3 4 5 6) #'identity 2 2))))

(test filt-function-centred
  (flet ((mx (w) (apply #'max w)))
    ;; the window looked ahead, and the default step was 1 + wind/2
    (is (equal '(0 0 9 9 9 0 0 0) (filt-function '(0 0 0 9 0 0 0 0) #'mx 3)))
    (is (equal (filt-function '(0 0 0 9 0 0 0 0) #'mx 3) (filt-function '(0 0 0 9 0 0 0 0) #'mx 3 1)))
    ;; wind 0 and 1 were forced to 2
    (is (equal '(1 2 3 4) (filt-function '(1 2 3 4) #'mx 1)))
    (is (equal '(1 2 3 4) (filt-function '(1 2 3 4) #'mx 0)))
    ;; a float wind above 0.5 failed, a ratio was ignored, a large step failed
    (is (equal '(1 3 5 7 8 8 8 8) (filt-function '(1 2 3 4 5 6 7 8) #'mx 0.75)))
    (is (equal '(1 3 4 5 6 7 8 8) (filt-function '(1 2 3 4 5 6 7 8) #'mx 1/4)))
    (is (equal '(4 4 4 4 4 8 8 8) (filt-function '(1 2 3 4 5 6 7 8) #'mx 2 5)))
    (signals error (filt-function '(1 2 3 4) #'mx 2.5))
    (signals error (filt-function '(1 2 3 4) #'mx 2 0)))
  ;; overlapping windows returning lists used to lengthen the result
  (is (equal '(1 2 3 4 5 6 7 8) (filt-function '(1 2 3 4 5 6 7 8) #'identity 3)))
  (is (equal '(1 2 3 4 5 6 7 8) (filt-function '(1 2 3 4 5 6 7 8) #'reverse 3 1)))
  (signals error (filt-function '(1 2 3 4 5 6 7 8) (lambda (w) (remove 4 w)) 3 1))
  ;; blocks (step = wind) are replaced by the lists, whatever their length
  (is (equal '(3 2 1 6 5 4 8 7) (filt-function '(1 2 3 4 5 6 7 8) #'reverse 3 3)))
  (is (equal '(1 2 3 5 6 7 8) (filt-function '(1 2 3 4 5 6 7 8) (lambda (w) (remove 4 w)) 4 4)))
  ;; nil is a value, it used to remove the values
  (is (equal '(nil t nil t) (filt-function '(1 2 3 4) (lambda (w) (evenp (car w))) 1))))

(test filt-repeat-fixes
  ;; :linear used to modify the list given (and quoted constants)
  (let ((x (list 0 0 1 2 2 2 3 3 0 0)))
    (is (every #'approx= '(0 0.5 1 2 7/3 8/3 3 1.5 0 0) (filt-repeat x :linear)))
    (is (equal '(0 0 1 2 2 2 3 3 0 0) x)))
  ;; with a tolerance, the ramp used to start from each value instead of the first of the run
  (let ((close (lambda (a b) (< (abs (- a b)) 0.2))))
    (is (every #'approx= '(1 5/3 7/3 3 4 5) (filt-repeat '(1.0 1.1 1.05 3 3.1 5) :linear close)))
    (is (equal '(1.0 3 5) (filt-repeat '(1.0 1.1 1.05 3 3.1 5) :delete close))))
  ;; repeated nils were not removed
  (is (equal '(a b nil c) (filt-repeat '(a a b b nil nil c))))
  (is (equal '(nil a) (filt-repeat '(nil nil a))))
  ;; :interp is :linear; an unknown mode was silently :delete
  (is (equal (filt-repeat '(0 0 1 2 2 3) :linear) (filt-repeat '(0 0 1 2 2 3) :interp)))
  (signals error (filt-repeat '(1 1 2) :foo))
  ;; non-numeric data with :linear: repetitions removed
  (is (equal '(a b) (filt-repeat '(a a b) :linear)))
  (is (equal '(5 5 5) (filt-repeat '(5 5 5) :linear)))
  (is (null (filt-repeat '() :linear))))

(test filt-noise-modes
  (let ((*random-state* (seeded-random-state)))
    ;; :nozero: all zeros used to crash; integer val could leave zeros
    (is (notany #'zerop (filt-noise '(0 0 0))))
    (is (every #'(lambda (x) (< 0 x 0.1)) (filt-noise '(0 0 0))))
    (is (loop repeat 200 never (find-if #'zerop (filt-noise '(0 10) :nozero 1))))
    (is (equal '(5 10) (cdr (filt-noise '(0 5 10)))))
    (signals error (filt-noise '(0 10) :nozero 0))
    ;; :relative was not implemented: noise within val * range
    (is (loop repeat 200
              always (every #'(lambda (x y) (<= (abs (- y x)) 20.0001))
                            '(100 200 0 50) (filt-noise '(100 200 0 50) :relative 0.1))))
    (is (every #'approx= '(5 5 5) (filt-noise '(5 5 5) :relative 0.1)))
    ;; :swap keeps the elements
    (is (equal '(1 2 3 4 5 6 7 8) (sort (filt-noise '(1 2 3 4 5 6 7 8) :swap 0.5) #'<)))
    ;; unknown modes used to return the list silently; empty lists crashed
    (signals error (filt-noise '(1 2 3) :foo))
    (is (null (filt-noise '())))
    (let ((l (list 0 1 2)))
      (filt-noise l :relative 0.5)
      (is (equal '(0 1 2) l)))))

(test filt-noise-function-mode
  ;; mode may be a function (x l) applied to each element x, l being the whole list
  (is (equal '(10 20 30) (filt-noise '(1 2 3) (lambda (x l) (declare (ignore l)) (* x 10)))))
  (is (equal '(3 3 3) (filt-noise '(a b c) (lambda (x l) (declare (ignore x)) (length l)))))
  (is (equal '(1/6 2/6 3/6) (filt-noise '(1 2 3) (lambda (x l) (/ x (reduce #'+ l))))))
  ;; replace each element by a random element of the list
  (let ((*random-state* (seeded-random-state)))
    (is (loop repeat 50
              always (subsetp (filt-noise '(a b c d)
                                          (lambda (x l) (declare (ignore x)) (nth (random (length l)) l)))
                              '(a b c d)))))
  (is (null (filt-noise '() (lambda (x l) (declare (ignore l)) x))))
  ;; the function gets a copy of the list: seq is not modified
  (let ((s (list 3 1 2)))
    (filt-noise s (lambda (x l) (setf (first l) 0) x))
    (is (equal '(3 1 2) s)))
  (signals error (filt-noise '(1 2) 'reverse)))

(test filt-extrema
  ;; the window was not centred, and the last values repeated an extremum already passed
  (is (equal '(5 5 8 8 8 9 9 9 4 4) (filt-extrema '(1 5 2 8 3 3 9 1 0 4) 3)))
  (is (equal '(1 1 2 2 3 3 1 0 0 0) (filt-extrema '(1 5 2 8 3 3 9 1 0 4) 3 :min)))
  ;; an even window is enlarged to the next odd size
  (is (equal (filt-extrema '(1 5 2 8 3) 3) (filt-extrema '(1 5 2 8 3) 2)))
  ;; opening removes the narrow peaks, closing fills the narrow hollows
  (is (equal '(0 0 0 0 0 5 5 5 0 0) (filt-extrema '(0 0 9 0 0 5 5 5 0 0) 3 :open)))
  (is (equal '(5 5 5 5 5 1 1 1 5 5) (filt-extrema '(5 5 0 5 5 1 1 1 5 5) 3 :close)))
  (is (equal '(1 2 3) (filt-extrema '(1 2 3) 1)))
  (is (null (filt-extrema '() 3)))
  (signals error (filt-extrema '(1 2 3) 3 :median))
  (is (equal (filt-extrema '(1 5 2 8 3 3 9 1 0 4) 3) (filt-extrema '(1 5 2 8 3 3 9 1 0 4) 0.3)))
  (signals error (filt-extrema '(1 2 3) 1.5)))

(test filt-quantize
  (let ((s '(0 1 2 10 11 12 20 21 22)))
    ;; without window: class-num, each value replaced by the centre of its class
    (is (equal '(1.0 1.0 1.0 11.0 11.0 11.0 21.0 21.0 21.0) (filt-quantize s 3)))
    (is (equal '(0 0 0 1 1 1 2 2 2) (filt-quantize s 3 :out :classes)))
    ;; the same as class-num :sort t
    (is (equal (first (class-num s 3 :1d-centroids :sort t)) (filt-quantize s 3 :out :classes)))
    ;; NIL: a missing value, kept
    (is (equal '(0.5 0.5 nil 10.5 10.5) (filt-quantize '(0 1 nil 10 11) 2))))
  ;; by the turns (:minmax): each extremum counts once, the brief peak (60) has its level;
  ;; by the time spent (:1d-centroids), it is absorbed
  (let* ((up (loop for i from 0 to 50 collect i))
         (down (reverse up))
         (peak (append (loop for i from 51 to 60 collect i) (loop for i from 59 downto 51 collect i)))
         (s (append up down up peak down up down)))
    (is (< (reduce #'max (filt-quantize s 3)) 50))
    (is (equal '(0.0 50.0 60.0) (sort (remove-duplicates (filt-quantize s 3 :mode :minmax)) #'<))))
  ;; segments: each run between NILs quantized apart, in its own register
  (multiple-value-bind (v classes parts) (filt-quantize '(0 1 10 11 nil 100 101 110 111) 2 :segments t :out :all)
    (is (equal '(0.5 0.5 10.5 10.5 nil 100.5 100.5 110.5 110.5) v))
    (is (equal '(0 0 1 1 nil 0 0 1 1) classes))
    (is (equal '((0 3 (0.5 10.5)) (5 8 (100.5 110.5))) parts)))
  ;; sliding windows: an integer size, or a part of the length; each value in the nearest window
  (let ((s (loop for i below 40 collect (if (< i 20) (mod i 2) (+ 100 (mod i 2))))))
    (is (equal (filt-quantize s 2 :window 20 :step 20) (filt-quantize s 2 :window 1/2 :step 1.0)))
    (is (= 4 (length (remove-duplicates (filt-quantize s 2 :window 20 :step 20))))))
  (multiple-value-bind (v c parts) (filt-quantize (loop for i below 10 collect i) 2 :window 4 :out :all)
    (declare (ignore v c))
    ;; windows of 4 by 2, the last one ending at the end
    (is (equal '((0 3) (2 5) (4 7) (6 9)) (mapcar (lambda (p) (subseq p 0 2)) parts))))
  (signals error (filt-quantize '(0 1 2) 2 :mode :foo))
  (signals error (filt-quantize '(0 1 2) 2 :thres 1))
  (signals error (filt-quantize '(0 a 2) 2))
  (signals error (filt-quantize '(0 1 2) 2 :window -1)))
