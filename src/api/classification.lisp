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

;;;; api/classification.lisp
;;;;
;;;; Public functions: differentiation (signatures, sampling, marks, motifs,
;;;; classification) and graph partition.

(in-package :refrains)

(defgeneric exsample (seq method thres &key diff duration out)
  (:documentation "EXSAMPLE: samples a sequence of numerical values <seq> according to its signature, its salient points with some threshold <thres> for variation in intensity.
The argument <thres> may be nil or 0 (no threshold for variations in intensity), or an absolute amplitude (in the unit of the values of <seq>, not negative): variations smaller than <thres> are ignored.
Argument <method> defines the algorithm to compute the signature:
:minflexmax (default, or nil), returns minima, maxima and inflexions (plateaus, negligible variations): the minima and maxima of :minmax, and an inflexion where a plateau
 which is not an extremum begins and where it ends (a plateau is a stretch of at least :duration positions where the sequence varies by less than thres);
:minmax, minima and maxima only: the important extrema of :major-extrema, with |a - b|;
:major-extrema, important extrema (Fink & Gandhi, Conference on Systems, Man and Cybernetics, 2007):
 a minimum (maximum) such that the sequence rises (falls) by at least thres on both sides;
:landmarks, first-order landmarks smoothed by MDPP(D, P) (Perng, Parker & Leung, Conference on Information
 and Knowledge Management, 1999): pairs of close landmarks whose difference is below thres are removed;
:angles, the angular points: the positions where the slope on the left and the slope on the right differ by at least
 thres (by more than 0 if thres is 0), whatever their signs (thres is then a difference of slopes).
Keyword :diff, with :major-extrema and :landmarks, the difference between two values: :absolute (|a - b|, default),
:relative (2 |a - b| / (|a| + |b|), as in Perng et al.) or a function (a b).
Keyword :duration, a number of positions: with :minflexmax, the minimal duration of a plateau (nil, 0, 1 and 2 mean 2);
with :landmarks, D (only landmarks closer than D positions may be removed; nil: no limit).
A keyword not used by the method is an error.
Keyword :out defines the output: :values (default, or nil), :positions, :all (position value) or :resampled
(the straight lines between the points, at every position), all with the first and last values of <seq>;
or :signature, the points (position type value), type -1 for a minimum, 1 for a maximum and 0 for an inflexion
(with :angles, -1 where the slope increases and 1 where it decreases), without the first and last values."))

(defmethod exsample ((seq list) (method symbol) (thres t) &key (diff nil) (duration nil) (out nil))
  ;; nil: the defaults (thres nil: no threshold, as 0)
  (signature seq (or method :minflexmax) (or thres 0) :diff diff :duration duration :out (or out :values)))

(defgeneric separate (seq &key marks keep)
  (:documentation "SEPARATE: separates <seq> at its marks, and returns the list of its segments.
A string is separated at the characters of the string :marks and at blanks.
A list is separated at the elements of the list :marks (compared with equalp), at a single mark, or where the predicate :marks is true.
Keyword :keep, nil (default) to remove the marks, or t to keep them: each mark begins the segment that follows it (blanks are always removed).
Empty segments are removed."))

(defmethod separate ((seq list) &key (marks nil) (keep nil))
  (split-list-using-marks seq marks keep))

(defmethod separate ((seq string) &key (marks " ") (keep nil))
  (split-string seq marks keep))

(defgeneric mark-structure  (seq out &key diss rem-loc-dup test)
  (:documentation "MARK-STRUCTURE: returns the possible structures of <seq> given by its marks: each mark opens segments,
and the repetitions of these segments give a structure. The structures are sorted by length.
Argument <out> defines the form of the result (another value is an error):
:struct (or nil) lists all possible structures according to different marks of <seq>
:pos each structure is consed to the list of positions for each segment followed by the list of the segments themselves
:raw each structure is consed to the list of the different segments, each followed by all its positions in <seq>.
Option :diss defines the dissemblance threshold to consider different segment as the same.
Option :test (equalp by default) defines the identity of elements: of the marks, of the elements of the segments
compared by the edit distance, and of the consecutive elements removed by :rem-loc-dup.
Option :rem-loc-dup (t by default) removes the local repetitions inside each segment; positions refer to <seq>."))

(defmethod mark-structure  ((seq t) (out t) &key (diss 0) (rem-loc-dup t) (test #'equalp))
  (when (not out) (setf out :struct))
  (mark-strct seq out diss rem-loc-dup test))

(defgeneric motif-structure (seq &key lengths test diss l-var criteria distance)
  (:documentation "MOTIF-STRUCTURE: structure of <seq> in terms of its repeated motifs, as a list of two elements:
the positions where motifs begin, each followed by the numbers of the motifs beginning there, then the motifs.
A motif is a segment repeated at least once, later and without overlapping.
:lengths the lengths of the motifs searched: (min max), or a maximum k for lengths 2 to k (default: 3 to half the length of <seq>);
:test the identity of elements (equalp by default);
:diss the tolerance, the maximum normalized edit distance (0 to 1) between a motif and its repetitions (0 by default: exact repetitions);
:l-var the length variation of the repetitions, a fraction of the length of the motif (0 by default; used with a tolerance);
:criteria :length (default) or :freq, to keep the longest or the most frequent of the motifs contained in one another;
:distance a function (a b) giving the distance between two segments (lists), instead of the edit distance; :diss is then in its unit."))

(defmethod motif-structure ((seq t) &key (lengths nil) (test #'equalp) (diss 0) (l-var 0) (criteria :length) (distance nil))
  (unless (member criteria '(:length :freq))
    (error "motif-structure: :criteria must be :length or :freq, not ~S." criteria))
  (unless (or (null lengths) (and (integerp lengths) (plusp lengths))
              (and (listp lengths) (= 2 (length lengths)) (every #'integerp lengths)
                   (<= 1 (first lengths) (second lengths))))
    (error "motif-structure: :lengths must be (min max) or a maximum length, not ~S." lengths))
  ;; the motifs found, each with its positions, then the motifs kept: the longest (:length) or the
  ;; most frequent (:freq) of the motifs contained in one another with the same number of repetitions
  (let* ((x (whenlooploopwhenwhen seq diss l-var lengths distance test))
         (same #'(lambda (a b) (and (subseq-p (car a) (car b)) (= (length (cdr a)) (length (cdr b))))))
         (ptrns (if (eq criteria :freq)
                    (remove-duplicates (sort x '> :key #'(lambda (x) (length (cdr x)))) :from-end nil :test same)
                    (remove-duplicates (sort x '> :key #'(lambda (x) (length (car x)))) :from-end t :test same)))
         (pos (sort (remove-duplicates (apply #'append (mapcar #'(lambda (x) (mapcar #'car (cdr x))) ptrns))) '<))
         (ptrn-list nil)
         (st nil))
    (mapcar #'(lambda (x) (setf (cdr x) (mapcar #'car (cdr x)))) ptrns)
    (dotimes (k (length ptrns))
      (push (list (car (nth k ptrns)) k) ptrn-list))
    (dolist (p pos)
      (push (apply #'append (list (list p)
                                  (mapcar #'(lambda (x) (cadr (assoc (car x) ptrn-list :test #'equalp)))
                                          (remove-if-not #'(lambda (x) (member p (cdr x))) ptrns))))
            st))
    (list (reverse st) (mapcar #'car (sort ptrn-list '< :key #'cadr)))))

(defgeneric motif-group (seq test &optional key)
  (:documentation "MOTIF-GROUP: assembles consecutive elements or motifs of <seq> for which the comparison <test> (by default: equalp) is successful.
Optional argument <key> defines a function to be applyed to each consecutive element or motif to be compared."))

(defmethod motif-group ((seq t) (test function) &optional (key nil))
  (adj-group seq test key))

(defgeneric class-num (data classes mode  &key iter dist sort)
  (:documentation "CLASS-NUM: classifies the points <data> into <classes> classes, in a space of n dimensions (n integer > 0):
each point is a number (one dimension) or the list of its coordinates.
Argument <classes> is the number of classes, or the list of their initial centres (numbers, or lists of coordinates),
approximate ones being possible: the dynamic clouds start from them (equal centres count once), whatever <mode>,
without :iter (deterministic).
Argument <mode> defines the algorithm used for partitioning the points:
:centroids, dynamic clouds algorithm (in French: nuees dynamiques, after Diday), from random initial centres;
:1d-centroids, the same algorithm on numbers (one dimension), from initial centres taken between the largest
differences of the sorted data (deterministic).
Keyword argument :iter to set the number of runs of the algorithm (with :centroids);
:dist to set the distance or metric to be used (by default: euclidean distance);
:sort, with numbers, t to number the classes by increasing centre (class 0 the lowest), nil (default) by order of
first appearance in <data>."))

(defmethod class-num ((data t) (classes t) (mode symbol) &key (iter nil) (dist nil) (sort nil))
  (when (and sort (or iter (notevery #'realp data)))
    (error "class-num: :sort needs numbers as data, and no :iter."))
  ;; without :sort, all the values (with an integer :iter, the partition and its frequency)
  (if sort
      (refrains::sort-classes (class-num-unsorted data classes mode iter dist))
      (class-num-unsorted data classes mode iter dist)))

(defun class-num-unsorted (data classes mode iter dist)
  "class-num, the classes numbered by order of first appearance in data."
  ;; modes recognized by name (:centroids, 'centroids from any package); an unknown mode was nil
  (let ((name (if mode (string-upcase (string mode)) "CENTROIDS")))
    (unless (member name '("CENTROIDS" "1D-CENTROIDS") :test #'string=)
      (error "class-num: unknown mode ~S, use :centroids (or nil) or :1d-centroids." mode))
    (cond ((listp classes)
           ;; initial centres, the same equal ones once: the dynamic clouds from them
           (when iter
             (error "class-num: :iter does not apply when the initial centres are given."))
           (when (and dist (string= name "1D-CENTROIDS"))
             (error "class-num: :dist does not apply to :1d-centroids when the initial centres are given."))
           (refrains::centres-class data (remove-duplicates classes :test #'equalp :from-end t) dist))
          ((not (integerp classes))
           (error "class-num: classes must be a number of classes or a list of initial centres, not ~S." classes))
          ((string= name "CENTROIDS")
           (setf classes (max 2 classes))   ; at least 2 classes
           (let ((numbers (every #'numberp data)))
             (unless (or numbers
                         (and (every #'listp data)
                              (or (null data) (apply #'= (mapcar #'length data)))))
               (error "class-num: the points of data must all be numbers, or lists of the same number of coordinates."))
             (if (and numbers data (null iter))
                 ;; the centres of numbers are numbers (they were (x 0), the points used internally)
                 (let ((r (refrains::n-class data classes iter dist)))
                   (list (first r) (mapcar #'car (second r)) (third r)))
                 ;; all the values (with an integer iter: the partition and its frequency)
                 (refrains::n-class data classes iter dist))))
          (t
           (refrains::1d-class data (max 2 classes) (if dist dist #'identity))))))

(defgeneric class-sym (data classes mode &key sub ins del uncom excluded mst)
  (:documentation "CLASS-SYM: classify a set of segments or sequences into different classes according to their editing distance to each other and
by partitioning the resulting spanning tree (see graph-part).
The output is a list of numbers (from zero) as instances of the different classes retrieved.
<mode> (a symbol of any package, a keyword or a string): edit-nn (or nil), the absolute edit distance;
edit-norm, the edit distance relative to the length of the longer sequence.
Keyword arguments :sub :ins :del :uncom for tuning editing distance (see dist-edit).
The argument :excluded is a list of elements of data excluded from classification ;
in the output, the numbering of the different instances begins by numbering these elements first (from zero), 
in the order defined with the argument :excluded."))

(defmethod class-sym ((data t) (classes integer) (mode t)
		      &key (sub 1) (ins 1) (del 1) (uncom .5) (excluded nil) (mst nil))
  ;; modes are recognized by their names: 'edit-norm from any package, :edit-norm or "edit-norm"
  ;; (with :excluded, :edit-norm was ignored and nil gave nil; an unknown mode gave nil)
  (let* ((name (if mode (string-upcase (string mode)) "EDIT-NN"))
         (norm (cond ((string= name "EDIT-NN") nil)
                     ((string= name "EDIT-NORM") t)
                     (t (error "class-sym: unknown mode ~S, use :edit-nn or :edit-norm." mode)))))
    (refrains::s-class data (max 2 classes) norm sub ins del uncom mst excluded)))

;; 2.5 CONCATENATION

;(defmethod concaten ((list nil))
;  :non-generic t
;  :class morphologie-box
;  (refrains::concaten list))

;(defmethod adj-group ((seq nil) (test #'eq) &optional (key nil))
;  :non-generic t
;  :class morphologie-box
;  (refrains::adj-group seq test key))

(defgeneric graph-part (graph &optional mode n)
  (:documentation  "GRAPH-PART: partition a graph according to edges which have maximum length.
Without <n>, all the edges of maximum length are cut ; with <n>, the n-1 longest edges are cut, giving n parts."))

(defmethod graph-part ((graph list) &optional (mode :distance) (n nil))
  (part-graph graph mode n))
