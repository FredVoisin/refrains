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

;;;; utils.lisp
;;;;
;;;; General variables, maths, lists, matrices and other utilities.

(in-package :refrains)

(defun safe-read-from-string (string &rest args)
  "read-from-string with *read-eval* nil: the reader macro #. in string (for instance a word of a text file)
signals an error instead of evaluating its code."
  (let ((*read-eval* nil))
    (apply #'read-from-string string args)))

;;; Date & Time

(defparameter *short-months*
  #("Jan" "Feb" "Mar" "Apr" "May" "June" "Jul" "Aug" "Sept" "Oct" "Nov" "Dec"))

(defun date-string (&optional time (u (get-universal-time)))
  "The date of the universal time u (now by default), as a string such as \"22 Oct 2026\";
with time true, the date and time, such as \"22 Oct 2026 14:05:09\"."
  (multiple-value-bind (s m h d mo y) (decode-universal-time u)
    (if time
        (format nil "~A ~A ~A ~A:~2,'0D:~2,'0D" d (svref *short-months* (1- mo)) y h m s)
        (format nil "~A ~A ~A" d (svref *short-months* (1- mo)) y))))
    
;;; FOR WARNINGS ETC.

(defun message (message)
  (format t "~%~S~%" message))

;;; SOME "MATHS"

(defun log! (x b)
  (if (zerop x) 0 (log x b)))

(defun mean (data)
  "The mean of the numbers of data (an error if data is empty)."
  (if data
      (float (/ (apply #'+ data) (length data)))
      (error "mean: no value (the list is empty).")))

(defun test (mode)
  (case mode
    (null 0)
    (:charcode 2)
    (t 1)))

;;;; sept 2009, kind of deleuzian differentiation (sept. 2009)...

(defgeneric a-zero (x &optional quasi-zero)
 (:documentation "Replace all zeros by small value (optional: quasi-zero value).
If x is a graph or tree (a list of lists), change only the third element of each node considered to be a distance."))

(defmethod a-zero ((x number) &optional (quasi-zero .001))
  (if (zerop x) (random quasi-zero) x))

(defmethod a-zero ((x list) &optional (quasi-zero .001))  ;; not to be removed used for tres etc
  (if (not (member nil (mapcar #'listp x)))
      (mapcar #'(lambda (a) (append (butlast a) (a-zero (last a) quasi-zero))) x)
      (mapcar #'(lambda (a) (a-zero a quasi-zero)) x)))

(defun normalize (data)
  "The numbers of data divided by their sum, which is then 1 (an error if the sum is 0)."
  (let ((sum (apply #'+ data)))
    (cond ((null data) nil)
          ((zerop sum) (error "normalize: the sum of ~S is 0." data))
          ((= 1 sum) data)
          (t (mapcar #'(lambda (x) (/ x sum)) data)))))

;;; then, quasi-zero should me renamed schism and be a kind of random number when 0 is a float (epsilon = eteron ?), not integer
;;; ( 0 =? nil) 
;;; in a dynamical - chaotic - dynamic model for emergence 
  

;;; FOR COMPATIBILITIES (OM, PWGL etc)

(defun mat-transpose (liste)
  (assert (apply #'= (mapcar #'length liste)) nil
	  "we usually consider regular matrix. so, this should not happen. Please report this to Kilian Sprotte or Fred Voisin")
  (when liste (apply #'mapcar #'list liste)))

; when list have decreasing size, recursively (used by newold function)
(defun ldlrot (ldl &optional (r (list)))
  (if (caar ldl)
      (ldlrot (mapcar #'cdr ldl) (cons (remove 'nil (mapcar #'car ldl)) r))
      (reverse r)))

(defun flat0 (tree res r)
  "At first in LispMe on my Visor :)"
  (cond ((null tree)
	 (if (null res) r (flat0 (car res) (if (null res) '() (cdr res)) r)))
	((listp tree) (flat0 (car tree) (cons (cdr tree) res) r))
	(t (progn
	     (setf r (cons tree r))
	     (flat0 (if (null res) '() (car res))
		    (if (null res) '() (cdr res))
			r)))))

(defun flat (list)
 (reverse (flat0 list '() '())))

;(flat '(YOU (WALRUS (HURT THE) ONE ((YOU) LOVE))))

(defun dx (seq &key key)
    (let (r (n-1 (pop seq)))
      (loop while seq
	 do (let ((n (pop seq)))
	      (if (not key)
		  (push (- n n-1) r)
		  (progn
		    (push (copy-tree n) r)
		    (eval `(setf (,key (car (quote ,r)))
			   (- (,key (quote ,n))
			      (,key (quote ,n-1)))))))
	      (setf n-1 n)))
      (nreverse r)))

; (dx '(1 2 3 3 5 6 5 3  8 9))
; (dx '((1 2) (3 3) (5 6) (5 3) (8 9)) :key 'cadr)

(defun derivee (seq)
  "The signs of the successive differences of the numbers of seq: 1 when the next value is greater,
-1 when it is smaller, 0 when it is equal (one element less than seq)."
  (loop for (a . rest) on seq
        while rest
        collect (let ((b (car rest)))
                  (cond ((> b a) 1)
                        ((< b a) -1)
                        (t 0)))))

; (derivee '(1 2 3 3 5 6 5 3 8 9)) => (1 1 0 1 1 -1 -1 1 1)

;;; ABOUT LISTS

(defun lmin (liste)
  "The minimum of the numbers of liste (an error if liste is empty)."
  (if liste (reduce #'min liste) (error "lmin: no value (the list is empty).")))

(defun lmax (liste)
  "The maximum of the numbers of liste (an error if liste is empty)."
  (if liste (reduce #'max liste) (error "lmax: no value (the list is empty).")))

(defun split-list-using-marks (liste marks &optional keep)
  "Splits liste at its marks: marks is a list of marks (compared with equalp), a predicate, or a single
mark. The marks are removed, or with keep, each one begins the segment that follows it.
Empty segments are removed."
  (let ((markp (cond ((functionp marks) marks)
                     ((listp marks) #'(lambda (e) (member e marks :test #'equalp)))
                     (t #'(lambda (e) (equalp e marks)))))
        (r nil)
        (segment nil))
    (dolist (e liste)
      (if (funcall markp e)
          (progn (when segment (push (nreverse segment) r))
                 (setf segment (if keep (list e) nil)))
          (push e segment)))
    (when segment (push (nreverse segment) r))
    (nreverse r)))
	
;(split-list-using-marks '(1 2 3 4 1 2 3 1 2 1) '(1 2))
;(split-list-using-marks '(1 2 3 4 1 2 3 1 2 1) #'(lambda (x) (< x 3)))

(defun concat (liste)
  (if (atom liste) liste
      (let ((a (car liste)))
	(cond ((listp a)
	       (apply #'append liste))
	      ((stringp a)
	       (eval `(concatenate 'string .,liste)))
	      (t
	       (safe-read-from-string (concat (mapcar #'(lambda (x) (format nil "~S" x))
						 liste))))))))

(defun randswap (list &optional iter)
  "A copy of list with iter random swaps of two elements: an integer, or a float, a part of the length
of list (half of it by default)."
  (setf iter (cond ((null iter) (floor (length list) 2))
                   ((floatp iter) (floor (* iter (length list))))
                   (t iter)))
  (let ((l (copy-tree list))
        (le (length list)))
    (loop repeat iter
       do (let* ((i (random le))
		 (j (random le))
		 (k (nth i l)))
	    (setf  (nth i l) (nth j l)
		   (nth j l) k)))
    (values l)))

;(randswap '(1 2 3 4 5 6 7 8 9 0) 10)

(defun window-size (window n caller)
  "The length in positions of WINDOW over N positions: an integer, a number of positions (0 or 1: no window);
a ratio or a float between 0 (excluded) and 1, a part of N (at least 1 position); nil stays nil (the whole).
Another value is an error of CALLER."
  (cond ((null window) nil)
        ((and (integerp window) (>= window 0)) window)
        ((and (realp window) (< 0 window) (<= window 1)) (max 1 (round (* window n))))
        (t (error "~A: the window must be an integer (positions) or a part of the length (a ratio or a float in ]0, 1]), not ~S."
                  caller window))))

(defun window-step (step size caller)
  "The step in positions between windows of SIZE positions: a positive integer, a number of positions;
a ratio or a float between 0 (excluded) and 1, a part of the window (1.0: windows end to end).
Another value is an error of CALLER."
  (cond ((and (integerp step) (plusp step)) step)
        ((and (realp step) (< 0 step) (<= step 1)) (max 1 (round (* step size))))
        (t (error "~A: the step must be a positive integer (positions) or a part of the window (a ratio or a float in ]0, 1]), not ~S."
                  caller step))))

(defun window-bounds (n size step)
  "The windows (start end) over N positions: of SIZE positions (all if nil), every STEP positions,
the last one ending at the last position."
  (if (or (null size) (>= size n))
      (list (list 0 (1- n)))
      (let ((starts (loop for s from 0 to (- n size) by step collect s)))
        (unless (= (car (last starts)) (- n size))
          (setf starts (append starts (list (- n size)))))
        (mapcar (lambda (s) (list s (+ s size -1))) starts))))

(defun list-display (tree &optional res (n 0))
  (cond ((null tree) (if res (list-display (car res) (cdr res) (1- n)) (values)))
	((listp tree) (list-display (car tree) (cons (cdr tree) res) (1+ n)))
	(t (progn (format t "~&")
		  (dotimes (i n (format t "~S" tree)) (format t " "))
		  (list-display (car res) (cdr res) (1- n))))))

;(list-display '(YOU (WALRUS (HURT THE) ONE ((YOU) LOVE))))

;;;;;;;;;;;;;;;;
;;; SOME NUMERIC DATA PROCESSING

; fmax fmin: reduce, as apply of min max is bounded by call-arguments-limit
(defun fmax (seq)
  "max value of s (an error if seq is empty)"
  (if seq (reduce #'max seq) (error "fmax: no value (the list is empty).")))

(defun fmin (seq)
  "min value of s (an error if seq is empty)"
  (if seq (reduce #'min seq) (error "fmin: no value (the list is empty).")))

;;; LISTS

(defun -reverse (list r)
  "A special working reverse for dotted lists."
    (if (listp list)
	(-reverse (cdr list) (cons (car list) r))
      (cons list r)))

;(-reverse (cons 1 '(2)) nil) !!crash
;(-reverse (cons 1 2) nil)
;(-reverse '(1 2 . 3) nil)
; > flatten

;;; shell utils

(defun shell-command (command &rest args)
  "Runs COMMAND (a string or a list of program and arguments), see uiop:run-program for ARGS."
  (apply #'uiop:run-program command args))

;(shell-command "ls")
