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

;;;; motifs.lisp
;;;;
;;;; Pattern structure: motifs (repeated subsequences) and groups of adjacent
;;;; elements.

(in-package :refrains)

;;; PATTERN STRUCTURE is old Structure 2 totally rewritten

(defun find-pos-in (motif v start diss l-var distance-fct &optional (test #'equalp))
  "Positions (first last) of motif in the vector v, from position start (see motif-position).
Without distance-fct, the normalized edit distance is used, test being the identity of elements;
with diss 0 too, the windows are compared element by element with test, which gives the same
result without computing distances."
  (let* ((m (coerce motif 'simple-vector))
         (v (coerce v 'simple-vector))
         (l (length m))
         (lseq (length v))
         (l+ (floor (* l l-var)))   ; for length tolerance
         (exact (and (null distance-fct) (zerop diss)))
         ;; integer codes for the edit distance, when test is an equality (see element-codes)
         (codes (unless (or exact distance-fct) (element-codes test m v)))
         ;; with a margin for the rounding of floats
         (rdiss (+ (rational diss) 1/1000000))
         pos)
    (flet ((match-p (i j)
             (if exact
                 (and (= j l)
                      (loop for k below l always (funcall test (aref m k) (aref v (+ i k)))))
                 (if distance-fct
                     (>= diss (funcall distance-fct motif (coerce (subseq v i (+ i j)) 'list)))
                     ;; the normalized edit distance, computed only while it may be <= diss;
                     ;; same decision as before
                     (let* ((maxlen (max l j))
                            (d (if codes
                                   (edit-dist-bounded (first codes) (second codes) i j (floor (* rdiss maxlen)) nil)
                                   (edit-dist-bounded m v i j (floor (* rdiss maxlen)) (coerce test 'function)))))
                       (and d (>= diss (float (/ d maxlen)))))))))
      (if (or exact distance-fct)
          (loop for i from start to (- lseq l+ 1)
                do (loop for j from (max 1 (- l l+)) to (+ l l+)
                         while (<= (+ i j) lseq)
                         when (match-p i j)
                           do (push (list i (+ i j -1)) pos)
                              (return)))
          ;; the normalized edit distance: all the lengths at a position from one matrix of costs, the
          ;; first one within diss as before (there was one computation for each length)
          (let ((jmin (max 1 (- l l+)))
                (accept #'(lambda (j d)
                            (let ((maxlen (max l j)))
                              (and (<= d (floor (* rdiss maxlen))) (>= diss (float (/ d maxlen))))))))
            (loop for i from start to (- lseq l+ 1)
                  do (let ((jmax (min (+ l l+) (- lseq i))))
                       (when (<= jmin jmax)
                         (let ((j (if codes
                                      (first-close-length (first codes) (second codes) i jmin jmax
                                                          (floor (* rdiss (max l jmax))) accept nil)
                                      (first-close-length m v i jmin jmax (floor (* rdiss (max l jmax)))
                                                          accept (coerce test 'function)))))
                           (when j (push (list i (+ i j -1)) pos)))))))))
    (reverse (remove-if #'(lambda (x)
                            (some #'(lambda (a) (subpos-p x a))
                                  (remove x pos :test #'equalp)))
                        pos))))

(defun subseq-p (a b &optional (test #'equalp))
  (let ((la (length a))
        (lb (length b))
        (pos 0)
        x)
    (if (or (not a) (not b)) ; trivial test
	nil
      (if (< la lb)
          (loop for i from 0 to (- lb la)
                until (setf x (funcall test a (subseq b i (+ i la))))
                do (setf pos i)
                finally (incf pos))
        (if (> la lb)
            (loop for i from 0 to (- la lb)
                  until (setf x (funcall test b (subseq a i (+ i lb))))
                  do (setf pos i)
                  finally (incf pos))
          (if (equalp a b)  ; another trivial test
              (setf x t)
            (setf x (funcall test a b))))))
    (values (if x pos x))))

;(subseq-p '(a b c) '(x y a b c z))
;(subseq-p '(a b c) '(x y d a b e c z) #'(lambda (a b) (<= (edit-dist a b 1 1 1 0 T) .34)))
;(subseq-p '(a b c) '(x y d a b e c z) #'(lambda (a b) (<= (edit-dist a b 1 1 1 0 T) .25)))
;(subseq-p '(a b c) '(x y a b z))
;(subseq-p '(a b c) '(x y a c d z) #'(lambda (a b) (<= (- (char-code (elt (format nil "~S" a) 0)) (char-code (elt (format nil "~S" b) 0))) 1)))

(defun whenlooploopwhenwhen (seq &optional (diss 0) (l-var 0) (n nil) (distance-fct nil) (test #'equalp))
  (let ((r (list))
	(n- 2)
	(n+ nil)
	(l (length seq))
	(v (coerce seq 'vector)))
    ;; distance-fct nil: the normalized edit distance (see find-pos-in)
    (when (not n) (setf n (list 3 (floor (/ l 2)))))
    (if (numberp n)
        (setf n+ n)
      (setf n- (car n)
            n+ (cadr n)))
    (loop for i from 0 to (- l (max 2 n-)) 
       do (loop for j from n- to (if n+ (min n+ (- l i)) (- l i))
	     do (let (f searched (candidat (coerce (subseq v i (+ i j)) 'list)))
		  ;; skip a candidate identical to an earlier motif, or which is one of its repetitions
		  (when (not (or (assoc candidat r :test #'equalp)
				 (let ((range (list i (+ i j -1))))
				   (some #'(lambda (x) (member range (cdr x) :test #'equal)) r))))
		    (setf searched t
                          f (find-pos-in candidat v (+ i j) diss l-var distance-fct test)))
		  (when f (push (append (list candidat) (cons (list i (+ i j -1)) f)) r))
                  ;; exact search: a segment not repeated after it cannot be lengthened into a repeated one
                  ;; (each repetition of the longer one would contain one of the shorter one)
                  (when (and searched (null f) (null distance-fct) (zerop diss))
                    (return)))))
    (remove-if #'(lambda (x)
		   (some #'(lambda (a) (l-subpos-p (cdr x) (cdr a)))
			 (remove x r :test #'equalp)))
	       r)))

#|
(print (whenlooploopwhenwhen '(t x a  b c y  t a e  b c k  r t x  a t x  a b c  i y t  a e c  e i b  c k r)
			     0 0 '(3 5)))
(print (whenlooploopwhenwhen '(t x a  b c y  t a e  b c k  r t x  a t x  a b c  i y t  a e c  e i b  c k r)
			     0.25 0.25 '(3 6)))
(print (whenlooploopwhenwhen '(t x a  b c y  t a e  b c k  r t x  a t x  a b c  i y t  a e c  e i b  c k r)
            ;;                 0 1 2  3 4 5  6      9     12     15     18     21     24     27     30
			     0.25 0.25 '(3 8))
(print (whenlooploopwhenwhen '(t x a  b c y  t a e  b c k  r t x  a t x  a b c  i y t  a e c  e i b  c k r)
			      .0 .0 nil)
(print (whenlooploopwhenwhen '(t x a  b c y  t a e  b c k  r t x  a t x  a b c  i y t  a e c  e i b  c k r)
			     0 .4 nil)
|#

;; next function does also an brut-force run on the seqs which may be not well adapted to huge lists
;; for huge lists of symbols, I rather like to do the same but using an random search to be tuned - kind of sondage or windowing -
;; in the list, following more flexible or fuzzy/lazy rules for probabiltistic retrieval - may be use of a dict ?

;; groupadjif1 / 2 a optimiser !

(defun groupadjif1 (data test r)
  "Groups adjacent elts in data if test is verified. Elts are atoms."
  (if (null data)
      (reverse (mapcar #'(lambda (x) (if (listp x) (-reverse x nil) x)) r))
    (let ((x (pop data)))
      (groupadjif1 data test
		   (if r
		       (let* ((c (car r)) (y (if (listp c) (car c) c)))
			 (if (funcall test y x)
			     (if (listp c)
				 (cons (cons x c) (cdr r))
				 (cons (cons x c) (cdr r)))
			     (cons x r)))
		       (cons x r))))))

;(groupadjif1 '(1 2 3 3 4 5 6 6 6 6 7 8 9) #'= nil) ;duscutable cf v if2

(defun groupadjif2 (data test r)
  (if (null data)
      (nreverse r) ;(mapcar #'(lambda (x) (apply #'append x)) r))
     (let ((x (pop data)))
      (groupadjif2 data test
                   (if r
                       (let* ((c (car r)) ); (y (if (listp (car c)) (car c) c)))
                         ;(print (list c x r))
                         (if (funcall test c x) ;y
                             (cons (append c x) (cdr r))
                           (cons x r)))
                     (cons x r))))))

;(groupadjif2 '((0 1) (1 8) (2 1) (3 8) (4 8) (5 8) (9 1) (9 1) (9 2) (1 1)) #'(lambda (x y) (= (cadr x) (cadr y))) nil)

(defgeneric adj-group (seq test &optional key)
  (:documentation "Groups adjacent elts in data according to the function test ('eq by default).
A function key specifies the position or value to be tested for each element of seq with optional argument.
If no key (by default), the test apply to the element itself."))

(defmethod adj-group ((seq list) (test function) &optional (key nil))
  (when (not (functionp test)) (setf test #'equalp)
    (message "adj-group: test is not a function, using test #'equalp"))
  (cond ((not (member nil (mapcar #'atom seq)))
         (if (not key)
             (groupadjif1 seq test nil)
           (groupadjif1 seq #'(lambda (x y) (funcall test (funcall key x) (funcall key y))) nil)))
        ((not (member nil (mapcar #'listp seq)))
         (when (not key) (setf key #'(lambda (x) (remove-duplicates x :test #'equalp)))) ; #'identity))
         (groupadjif2 seq #'(lambda (x y) (funcall test (funcall key x) (funcall key y))) nil))) )

(defmethod adj-group ((seq list) (test t) &optional (key nil))
  (adj-group seq #'equalp key))

;(adj-group '(0 1 2 3 3 3 4 3 2 1 1 1 1 2 1) #'=)
;(adj-group '((0 1) (1 8) (2 1) (3 8) (4 8) (5 8) (9 1) (9 1) (9 2) (1 1)) #'(lambda (x y) (= (cadr x) (cadr y))) )
;(adj-group '((0 1) (1 8) (2 1) (3 8) (4 8) (5 8) (9 1) (9 1) (9 2) (1 1)) #'(lambda (x y) (= x y)) #'cadr)
