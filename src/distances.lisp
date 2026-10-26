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

;;;; distances.lisp
;;;;
;;;; Distances and similarities: euclidean, city-block, Hamming, edit
;;;; distances, Jaccard, Sorensen, Mountford, structures.

(in-package :refrains)

(defun semi-matrix (fn list)
  "The semi-matrix of the distances (fn x y) between all the elements of list, as a list of (i j d(i,j)),
i < j, by increasing i then j: the form of the results of all the distances when their second argument is nil."
  (let ((v (coerce list 'vector))
        (r nil))
    (dotimes (i (length v) (nreverse r))
      (loop for j from (1+ i) below (length v)
            do (push (list i j (funcall fn (aref v i) (aref v j))) r)))))

;;; DISTANCES DISSEMBLANCE ETC

;; 1. Distance euclidienne

(defgeneric dist-euclid (a b &optional key)
  (:documentation "Euclidean distance between points a and b.
Point coordinates are represented by a list of values in any euclidean space.
 if a is a list of coordinates (lists) and b null,
output is the list of distances for all points to all others ;
 if a or b is a number, consider b or a as list of numbers (1 dim).
If a and b are lists with not same size (i.e points with not same dimensions),
 returns NIL (no distance)."))

(defmethod dist-euclid ((a number) (b number) &optional (key #'identity))
  (declare (ignore key))
  (abs (- b a)))

(defmethod dist-euclid ((a list) (b number) &optional (key #'identity))
  ;(assert (not (member 'nil (mapcar #'numberp a))))
  (mapcar #'(lambda (x) (dist-euclid x b key)) a))

(defmethod dist-euclid ((a number) (b list) &optional (key #'identity))
  ;(assert (not (member 'nil (mapcar #'numberp b))))
  (mapcar #'(lambda (x) (dist-euclid a x key)) b))

(defmethod dist-euclid ((a list) (b list) &optional (key #'identity))
  ;(assert (equalp (mapcar #'numberp a) (mapcar #'numberp b)))
  (if key
      (sqrt (loop for i in (funcall key a) for j in (funcall key b) sum (expt (- j i) 2)))
    (sqrt (loop for i in a for j in b sum (expt (- j i) 2)))
    ))

(defmethod dist-euclid ((a list) (b null) &optional (key #'identity))
  (semi-matrix #'(lambda (x y) (dist-euclid x y key)) a))

(defgeneric city-block (a b)
  (:documentation "City-block distance between a and b in euclidean space with n dimensions (with integer n > 0)."))

(defmethod city-block ((a number) (b number))
 (if (> a b) (- a b) (- b a)))

(defmethod city-block ((a list) (b list))
  (assert (= (length a) (length b)))
  (loop for x in a for y in b sum (city-block x y)))

(defmethod city-block ((a list) (b null))
  (assert (same-lengths-p a))
  (semi-matrix #'city-block a))

(defun hamming-distance (v1 v2 &optional (test #'eq))
  "The number of positions where the sequences v1 and v2, of the same length, differ."
  (assert (= (length v1) (length v2)))
  (loop for x in v1 for y in v2 count (not (funcall test x y))))

(defgeneric hamming-dist (v1 v2 &optional norm test)
  (:documentation "Hamming distance."))

(defmethod hamming-dist ((v1 list) (v2 list) &optional (norm t) (test #'eq))
  (let ((d (hamming-distance v1 v2 test)))
    (if norm (float (/ d (length v1))) d)))

(defmethod hamming-dist ((v1 list) (v2 null) &optional (norm t) (test #'eq))
  (semi-matrix #'(lambda (x y) (hamming-dist x y norm test)) v1))

;; 2. 'Editing distance' (Distance d'edition)
;; I have red a paper on genomic analysis on ADN using, as I remember, also used by a unix text commande.
;; Finally, as I understand it now, it's a kind of measure of the work of a Turing Machine:
;; the less it does, the closest it is...
;; (I may write here a Turing machine here to do the same :)

(defun edit-distance (seq1 seq2 &key (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  "The smallest cost of the changes, insertions and deletions that turn the sequence seq1 into seq2.
 change, insert, delete: the cost of each operation;
 inex: the extra cost of an element which does not exist (according to test) in the other sequence (0 by default);
 normalized: the cost divided by the length of the longer sequence, from 0 (the closest) to 1 with costs of 1;
 test: the identity of the elements (equalp by default)."
  (let* ((a (coerce seq1 'vector))
         (b (coerce seq2 'vector))
         (la (length a))
         (lb (length b))
         (inex (or inex 0))
         ;; 1 for an element which does not exist (according to test) in the other sequence,
         ;; computed only when it costs something
         (ex (unless (zerop inex) (map 'vector #'(lambda (x) (if (member x seq2 :test test) 0 1)) a)))
         (ey (unless (zerop inex) (map 'vector #'(lambda (y) (if (member y seq1 :test test) 0 1)) b)))
         (prev (make-array (1+ la)))
         (row (make-array (1+ la))))
    ;; the loops are written once, and compiled twice: without inex (the usual case, faster) and with it
    (macrolet ((fill-matrix (xa yb)
                 ;; xa, yb: the extra cost of the element (1- i) of a and (1- j) of b, left out when 0
                 (setf xa (unless (eql xa 0) (list xa))
                       yb (unless (eql yb 0) (list yb)))
                 `(progn
                    ;; row j of the matrix of costs: (aref row i) for the first i elements of seq1, j of seq2
                    (setf (aref prev 0) 0)
                    (loop for i from 1 to la
                          do (setf (aref prev i) (+ (aref prev (1- i)) delete ,@xa)))
                    (loop for j from 1 to lb
                          do (setf (aref row 0) (+ (aref prev 0) insert ,@yb))
                             (loop for i from 1 to la
                                   do (setf (aref row i)
                                            (min (+ (aref prev (1- i))
                                                    (if (funcall test (aref a (1- i)) (aref b (1- j)))
                                                        0
                                                        (+ change ,@xa ,@yb)))
                                                 (+ (aref prev i) insert ,@yb)
                                                 (+ (aref row (1- i)) delete ,@xa))))
                             (rotatef prev row)))))
      (if ex
          (fill-matrix (* (aref ex (1- i)) inex) (* (aref ey (1- j)) inex))
          (fill-matrix 0 0)))
    (let ((d (aref prev la)))
      (if normalized
          (if (zerop (max la lb)) 0.0 (float (/ d (max la lb))))
          d))))

(defun edit-dist-bounded (a b start lb bound &optional (test #'equalp))
  "The edit distance (costs 1) between the vector a and the lb elements of the vector b from
position start, if it is not more than the integer bound, else nil. The computation stops as
soon as the distance is certainly more than bound: the minimum of a row of the matrix of costs
never decreases in the next rows. With test nil, a and b hold integer codes of their elements,
compared with eql (see element-codes).
Only the cells within bound of the diagonal are computed: any other cell is more than bound, and
counts as bound + 1, which changes no distance within bound (Esko Ukkonen, 'Algorithms for
approximate string matching', Information and Control, 64, 1985, p. 100-118)."
  (declare (simple-vector a b) (fixnum start lb bound) (type (or null function) test))
  (let ((la (length a))
        (out (1+ bound)))   ; the value of the cells outside the band
    (declare (fixnum la out))
    (when (<= (abs (- la lb)) bound)
      (let ((prev (make-array (1+ la) :element-type 'fixnum))
            (row (make-array (1+ la) :element-type 'fixnum)))
        (declare (type (simple-array fixnum (*)) prev row))
        (dotimes (i (1+ la)) (setf (aref prev i) (min i out)))
        ;; the loops are written once, and compiled twice: integer codes compared with eql, or test
        (macrolet ((rows (same)
                     `(loop for j fixnum from 1 to lb
                            do (let ((lo (max 1 (- j bound)))
                                     (hi (min la (+ j bound)))
                                     (m (min j out))
                                     (bj (svref b (+ start j -1))))
                                 (declare (fixnum lo hi m))
                                 (setf (aref row 0) (min j out))
                                 ;; the cell before the band, read by the first cell of the band
                                 (when (> lo 1) (setf (aref row (1- lo)) out))
                                 (loop for i fixnum from lo to hi
                                       do (let ((d (min (+ (aref prev (1- i)) (if ,same 0 1))
                                                        (1+ (aref prev i))
                                                        (1+ (aref row (1- i))))))
                                            (declare (fixnum d))
                                            (setf (aref row i) d)
                                            (when (< d m) (setf m d))))
                                 ;; the cell after the band, read by the next row
                                 (when (< hi la) (setf (aref row (1+ hi)) out))
                                 (when (> m bound) (return-from edit-dist-bounded nil)))
                               (rotatef prev row))))
          (if test
              (rows (funcall test (svref a (1- i)) bj))
              (rows (eql (svref a (1- i)) bj))))
        (let ((d (aref prev la)))
          (when (<= d bound) d))))))

(defun first-close-length (a b start jmin jmax bmax accept test)
  "The first length j, from jmin to jmax, such that (accept j d) is true, d being the edit distance (costs 1)
between the vector a and the j elements of the vector b from position start, when d is not more than bmax;
or nil. All the lengths come from one matrix of costs: the distance for the length j is the last cell of
its row j. Only the band of bmax around the diagonal is computed (see edit-dist-bounded), and the search
stops when the minimum of a row is more than bmax. test as in edit-dist-bounded (nil: integer codes)."
  (declare (simple-vector a b) (fixnum start jmin jmax bmax) (function accept) (type (or null function) test))
  (let* ((la (length a))
         (out (1+ bmax))
         (prev (make-array (1+ la) :element-type 'fixnum))
         (row (make-array (1+ la) :element-type 'fixnum)))
    (declare (fixnum la out) (type (simple-array fixnum (*)) prev row))
    (dotimes (i (1+ la)) (setf (aref prev i) (min i out)))
    (macrolet ((rows (same)
                 `(loop for j fixnum from 1 to jmax
                        do (let ((lo (max 1 (- j bmax)))
                                 (hi (min la (+ j bmax)))
                                 (m (min j out))
                                 (bj (svref b (+ start j -1))))
                             (declare (fixnum lo hi m))
                             (setf (aref row 0) (min j out))
                             (when (> lo 1) (setf (aref row (1- lo)) out))
                             (loop for i fixnum from lo to hi
                                   do (let ((d (min (+ (aref prev (1- i)) (if ,same 0 1))
                                                    (1+ (aref prev i))
                                                    (1+ (aref row (1- i))))))
                                        (declare (fixnum d))
                                        (setf (aref row i) d)
                                        (when (< d m) (setf m d))))
                             (when (< hi la) (setf (aref row (1+ hi)) out))
                             ;; the distance for the length j, when its cell is in the band
                             (when (and (>= j jmin) (<= (abs (- la j)) bmax) (<= (aref row la) bmax)
                                        (funcall accept j (aref row la)))
                               (return-from first-close-length j))
                             (when (> m bmax) (return-from first-close-length nil)))
                           (rotatef prev row))))
      (if test
          (rows (funcall test (svref a (1- i)) bj))
          (rows (eql (svref a (1- i)) bj))))
    nil))

(defun element-codes (test &rest sequences)
  "If test is eq, eql, equal or equalp (an equality, by which a hash table can be built), the sequences
as simple vectors of integer codes, the same code for elements equal by test; otherwise nil."
  (when (member test (list #'eq #'eql #'equal #'equalp 'eq 'eql 'equal 'equalp))
    (let ((codes (make-hash-table :test test)))
      (mapcar #'(lambda (s)
                  (map 'simple-vector
                       #'(lambda (x) (or (gethash x codes)
                                         (setf (gethash x codes) (hash-table-count codes))))
                       s))
              sequences))))

(defgeneric edit-dist (seq1 seq2 &optional change insert delete inex normalized test)
  (:documentation
"Dissemblance measurement between sequences of symbols <seq1> and <seq2>, according to the 'editing distance';
 the dissemblance is nul (zero) when the sequences are the considered to be the same or 'equal'.
 Argument <change> is the cost value when changing a symbol ;
 Argument <insert> is the cost value when inserting a symbol ;
 Argument <delete> is the cost value when deleting a symbol ;
 Argument <inex> is the cost value when changing a symbol in one of the sequence which does not exist in the other ;
 Argument <normalized> to choose (un-)normalized output. If normalized, value 1.0 in ratio to the length of the longest sequence to be compared;
 test: any binary function to compare symbols (default: #'equalp)."))

(defmethod edit-dist ((seq1 list) (seq2 list) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (edit-distance seq1 seq2 :change change :insert insert :delete delete :inex inex
                           :normalized normalized :test test))

(defmethod edit-dist ((seq1 null) (seq2 null) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  ;; two empty sequences: nil is also a symbol, and the method for symbols called itself forever
  (declare (ignore seq1 seq2 change insert delete inex test))
  (if normalized 0.0 0))

(defmethod edit-dist ((seq1 list) (seq2 null) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (declare (ignore seq2))
  (when (not (= (length seq1)
		(length (remove-duplicates (copy-tree seq1) :test #'equalp))))
    (message "gen-dist: warning ! duplicates in input list."))
  (semi-matrix #'(lambda (x y) (edit-dist x y change insert delete inex normalized test)) seq1))

(defmethod edit-dist ((seq1 string) (seq2 string) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (edit-dist (string2code seq1) (string2code seq2) change insert delete inex normalized test))

(defmethod edit-dist ((seq1 symbol) (seq2 symbol) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (edit-dist (alpha>num seq1) (alpha>num seq2) change insert delete inex normalized test))

(defmethod edit-dist ((seq1 symbol) (seq2 number) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (edit-dist (alpha>num seq1) (alpha>num seq2) change insert delete inex normalized test))

(defmethod edit-dist ((seq1 number) (seq2 symbol) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (edit-dist (alpha>num seq1) (alpha>num seq2) change insert delete inex normalized test))

(defmethod edit-dist ((seq1 number) (seq2 number) &optional (change 1) (insert 1) (delete 1) (inex 0) (normalized nil) (test #'equalp))
  (edit-dist (alpha>num seq1) (alpha>num seq2) change insert delete inex normalized test))

(defun dimension-weights (wgth n)
  "The weights of n dimensions, summing to 1, from wgth: a number gives the same weight to all;
a list too short is completed with its last weight, a list too long is cut.
If all the weights are 0, all are 0 (every dimension is ignored)."
  (let ((w (cond ((numberp wgth) (make-list n :initial-element wgth))
                 ((< (length wgth) n)
                  (message (format nil "wgth has ~D weights for ~D dimensions: the last weight is used for the missing ones."
                                   (length wgth) n))
                  (append wgth (make-list (- n (length wgth)) :initial-element (or (car (last wgth)) 1))))
                 ((> (length wgth) n)
                  (message (format nil "wgth has ~D weights for ~D dimensions: the extra weights are ignored."
                                   (length wgth) n))
                  (subseq wgth 0 n))
                 (t wgth))))
    (if (zerop (reduce #'+ w))
        w
        (normalize w))))

(defgeneric multi-edit-dist (seq1 seq2 wgth &key change insert delete inex test)
  (:documentation
 "Considering each element of sequences seq1 and seq2 as an event described into symbolic dimensions,
returns the editing distance between seq1 and seq2 according to the weigthed dimensions defined.
By symbolic dimensions, I consider a structured list of 'arbitrary' symbols describing an event, such as, for instance,
 '(a IV x)."))

(defmethod multi-edit-dist ((seq1 list) (seq2 list) (wgth t)
			    &key (change 1) (insert 1) (delete 1) (inex 0) (test #'equalp))
  ;; the normalized edit distance of each dimension (a column of the lists of descriptors), weighted
  (assert (and (same-lengths-p seq1)
	       (same-lengths-p seq2)
	       (= (length (car seq1)) (length (car seq2)))))
  (let ((r 0)
        (matrix1 (mat-transpose seq1))
        (matrix2 (mat-transpose seq2))
        (wgth (dimension-weights wgth (length (car seq1)))))
    (dotimes (n (length matrix1) r)
      (incf r (* (nth n wgth)
                 (edit-distance (nth n matrix1) (nth n matrix2)
                                :change change :insert insert :delete delete :inex inex
                                :normalized t :test test))))))

(defmethod multi-edit-dist ((seq1 list) (seq2 null) (wgth t)
			    &key (change 1) (insert 1) (delete 1) (inex 0) (test #'equalp))
  (semi-matrix #'(lambda (x y) (multi-edit-dist x y wgth :change change :insert insert :delete delete
                                                          :inex inex :test test))
               seq1))

(defgeneric intersection-card (a b &key key test)
 (:documentation "Cardinal de l'intersection des ensembles a et b, ou de tous les éléments de a si b est vide."))

(defmethod intersection-card ((a list) (b list) &key (key #'identity) (test #'equalp))
  (length (intersection (remove-duplicates a :key key :test test)
                        (remove-duplicates b :key key :test test)
                        :key key :test test)))

(defmethod intersection-card ((a list) (b null) &key (key #'identity) (test #'equalp))
  (let ((x (pop a)))
    (loop until (not a)
          do (setf x (intersection (remove-duplicates x :key key :test test)
                                   (remove-duplicates (pop a) :key key :test test)
                                   :key key :test test)))
    (length x)))

(defgeneric jaccard-dist (a b &key test key)
  (:documentation "Jaccard distance.
If a is null, Jaccard distance of both lists of b ;
if b null, as usual in refrains, matrix of Jaccard distances of lists of a."))

(defmethod jaccard-dist ((a list) (b list) &key (test #'equalp) (key #'identity))
  ;; the union counted with key and test, like the intersection (it used equalp only);
  ;; two empty sets are identical: 0
  (let* ((j (intersection-card a b :test test :key key))
         (o (- (+ (length (remove-duplicates a :key key :test test))
                  (length (remove-duplicates b :key key :test test)))
               j)))
    (if (zerop o) 0.0 (float (/ (- o j) o)))))

(defmethod jaccard-dist ((a list) (b null) &key (test #'equalp) (key #'identity))
  (declare (ignore b))
  (semi-matrix #'(lambda (x y) (jaccard-dist x y :key key :test test)) a))

(defmethod jaccard-dist ((a null) (b list) &key (test #'equalp) (key #'identity))
  (declare (ignore a))
  (let ((n (loop for x in b sum (length x))))
    (if (zerop n) 0.0 (float (/ (intersection-card b nil :key key :test test) n)))))

;(jaccard-dist '((a b c d e f) (a b c 1 2 3) (b x y)) nil)
;(jaccard-dist 'nil '((a b c d e f) (a b c 1 2 3) (b x y)))
;(jaccard-dist '(1 0 1 0 0 0 0) '(1 0 0 1 0 1 1))

(defgeneric binary-jaccard-dist (a b &key key test)
  (:documentation "Jaccard distance between binary vectors: (b + c) / (a + b + c), a the positions present in both,
b and c those present in only one; the positions absent from both are not counted. Present: test true,
by default a value other than nil and 0."))

(defmethod binary-jaccard-dist ((a list) (b list) &key (key #'identity) (test nil))
  (assert (= (length a) (length b)))
  (let ((present (or test #'(lambda (x) (and x (not (eql x 0))))))
        (both 0) (one 0))
    (loop for x in a
          for y in b
          do (let ((px (funcall present (funcall key x)))
                   (py (funcall present (funcall key y))))
               (cond ((and px py) (incf both))
                     ((or px py) (incf one)))))
    ;; nothing present in either: identical, 0
    (if (zerop (+ both one)) 0.0 (float (/ one (+ both one))))))

(defmethod binary-jaccard-dist ((a list) (b null) &key (key #'identity) (test nil))
  (semi-matrix #'(lambda (x y) (binary-jaccard-dist x y :key key :test test)) a))

;(binary-jaccard-dist '(1 0 1 0 0 0 0) '(1 0 0 1 0 1 1))
;(binary-jaccard-dist '((a 1) (b 0) (c 1) (d 0) (e 0) (f 0) (g 0)) '((a 1) (b 0) (c 0) (d 1) (e 0) (f 1) (g 1)) :key #'cadr)
;(binary-jaccard-dist '(1 0 1 0 0 0 0) '(1 0 0 1 0 1 1) :test #'(lambda (x) (= 1 x)))

(defun sorensen-similarity (a b &key (test #'equalp) (key #'identity))
  "Sorensen-Dice similarity, 2 |a & b| / (|a| + |b|): 1 for identical sets (two empty sets too), 0 for disjoint sets."
  (let ((ca (length (remove-duplicates a :key key :test test)))
        (cb (length (remove-duplicates b :key key :test test))))
    (if (zerop (+ ca cb))
        1.0
        (float (/ (* 2 (intersection-card a b :test test :key key))
                  (+ ca cb))))))

(defun mountford-similarity (a b &key (key #'identity) (test #'equalp))
  "Mountford's index M = 2j / (2ab - (a+b)j) (a, b the sizes of the sets, j of their intersection),
normalized to M / (1 + M), from 0 (disjoint sets) to 1 (identical sets, two empty sets too):
M itself is infinite for identical sets."
  (let ((ca (length (remove-duplicates a :key key :test test)))
        (cb (length (remove-duplicates b :key key :test test)))
        (j (intersection-card a b :test test :key key)))
    (cond ((and (zerop ca) (zerop cb)) 1.0)
          ((zerop j) 0.0)
          (t (float (/ (* 2 j) (+ (- (* 2 ca cb) (* (+ ca cb) j)) (* 2 j))))))))

;(mountford-similarity '(1 0 1 0 0 0 0 2 3 4) '(1 0 0 1 0 1 1))

(defgeneric struct-dist (a b &optional w-occ w-rep test)
  (:documentation   "Dissemblance value (0 to 1) between sequences a and b according to their internal structures:
for each element, the number of its occurrences and the position of its first occurrence in its sequence,
compared with the multidimensional edit distance.
w-occ: weigth for 'occurence structure';
w-rep: weigth for 'repetition' structure;
test: identity of the elements (equalp by default)."))

(defmethod struct-dist ((a list) (b list) &optional (w-occ 1) (w-rep 1) (test #'equalp))
  ;; the occurrences and first positions are counted with test, for any kind of element
  ;; (match had methods for symbols and numbers only, and test compared the codes, not the elements)
  (flet ((codes (s)
           ;; the count and the first position of each element, computed once for each element (eql)
           ;; instead of a pass over s for each element
           (let ((known (make-hash-table :test #'eql)))
             (mapcar #'(lambda (x)
                         (or (gethash x known)
                             (setf (gethash x known)
                                   (list (count x s :test test) (position x s :test test)))))
                     s))))
    (multi-edit-dist (codes a) (codes b) (list w-occ w-rep) :inex 0 :test #'eql)))

(defmethod struct-dist ((a list) (b null) &optional (w-occ 1.) (w-rep 1.) (test #'equalp))
  (semi-matrix #'(lambda (x y) (struct-dist x y w-occ w-rep test)) a))
