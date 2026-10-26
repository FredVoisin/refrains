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

;;;; api/transcription.lisp
;;;;
;;;; Public functions: transcription (encoding, filters) and graphs
;;;; (spanning tree, dendrogram, paths, matrices).
;;;;
;;;; copyright (c) Frederic Voisin, 1992-2012
;;;; Morphologie tool suite (Library) for Common-Lisp, OpenMusic (Ircam, 1997) and PWGL (Sibelius Academy, 2007).
;;;; First imagined and developped with Herve Riviere at LACITO-CNRS (1992) using Patchwork (Ircam 1991), most of these functions were originaly published with Jacopo Baboni-Schilingi (Ircam, 1997) - most of them are actually largely modified following some new experiences in music analysis, composition and teaching (cf. Voisin 2015, Vincenot). 
;;;; Common-Lisp
;;;; UTF-8


(in-package :refrains)

(defgeneric num>base (num base)
  (:documentation "NUM>BASE: converts an number to its representation in base <base>."))

(defmethod num>base ((num number) (base t))
  (refrains::num-base num base))

(defgeneric list>sym (list)
  (:documentation "LIST>SYM: concatenates the elements of <list> into one element: numbers into a number,
strings into a string, other elements into a symbol."))

(defmethod list>sym ((list t))
  (refrains::concaten list))

(defgeneric graph>matrix (graph)
  (:documentation "GRAPH>MATRIX: the symmetric adjacency matrix of <graph>, a list of edges (node-a node-b distance),
as a list of rows: rows and columns in the order of graph-nodes, the distance of each edge, 0 elsewhere."))

(defmethod graph>matrix ((list t))
  (refrains::adj-matrix list))

(defgeneric filt-function (seq func window &optional step)
  (:documentation "Apply function <func> to sequence <seq> thru a sliding window of length <window> by (optional) step <step> (1 by default).
Window size may be an integer (samples) or a fraction of the length of seq; step size may be an integer (samples) or a fraction of the window.
With step 1 the window is centred on each value; with a larger step it is centred on each block of step values.
A value returned by <func> is repeated for the block; a list replaces the block (step = window), or gives the values of the block's positions."))

(defmethod filt-function ((seq list) (func function) (window real) &optional (step 1))
  (let ((window (if (integerp window) window (max 1 (round (* window (length seq)))))))
    (refrains::window-apply seq func window
                                  (if (integerp step) step (max 1 (round (* step window)))))))

(defun quantize-part (values levels mode thres)
  "The quantization of VALUES (numbers): (classes centres), the classes numbered by increasing centre.
MODE :1d-centroids or :centroids, the dynamic clouds on the values (class-num); a method of exsample,
class-num on the salient points of the values, then each value at the nearest centre (fixed centres)."
  (if (null (rest (remove-duplicates values :test #'=)))
      (list (make-list (length values) :initial-element 0) (list (first values)))
      (if (member mode '(:1d-centroids :centroids))
          (subseq (class-num values levels mode :sort t) 0 2)
          (let* ((points (exsample values mode thres :out :values))
                 (centres (if (rest (remove-duplicates points :test #'=))
                              (second (class-num points levels :1d-centroids :sort t))
                              (list (first points)))))
            (list (mapcar (lambda (x)
                            (position (reduce (lambda (a b) (if (<= (abs (- x a)) (abs (- x b))) a b)) centres)
                                      centres))
                          values)
                  centres)))))

(defun quantize-windows (n window step)
  "The windows (start end) over N positions: of WINDOW positions (all if nil), by STEP, the last one
ending at the last position."
  (if (or (null window) (>= window n))
      (list (list 0 (1- n)))
      (let ((starts (loop for s from 0 to (- n window) by step collect s)))
        (unless (= (car (last starts)) (- n window))
          (setf starts (append starts (list (- n window)))))
        (mapcar (lambda (s) (list s (+ s window -1))) starts))))

(defun quantize (seq levels &key (mode :1d-centroids) thres window (step 1/2) segments)
  "SEQ quantized (see filt-quantize). Returns the quantized values, the classes, and the parts
(start end centres), one by window or segment."
  (let* ((v (coerce seq 'vector))
         (n (length v))
         (values (make-array n :initial-element nil))
         (classes (make-array n :initial-element nil))
         (parts nil)
         (domains ; the segments: the runs of numbers between NILs, or all the positions
           (if segments
               (let ((runs nil) (start nil))
                 (dotimes (i n)
                   (cond ((and (aref v i) (null start)) (setf start i))
                         ((and (null (aref v i)) start) (push (list start (1- i)) runs) (setf start nil))))
                 (when start (push (list start (1- n)) runs))
                 (nreverse runs))
               (when (some #'identity v) (list (list 0 (1- n)))))))
    (dolist (d domains)
      (destructuring-bind (d-start d-end) d
        (let* ((len (1+ (- d-end d-start)))
               (size (cond ((null window) nil)
                           ((integerp window) window)
                           (t (max 1 (round (* window len))))))
               (pace (when size (max 1 (if (integerp step) step (round (* step size))))))
               (windows (mapcar (lambda (w) (mapcar (lambda (x) (+ x d-start)) w))
                                (quantize-windows len size pace)))
               (results (mapcar (lambda (w)
                                  (let ((positions (loop for i from (first w) to (second w)
                                                         when (aref v i) collect i)))
                                    (cons positions
                                          (when positions
                                            (quantize-part (mapcar (lambda (i) (aref v i)) positions)
                                                           levels mode thres)))))
                                windows)))
          (loop for w in windows for r in results
                when (rest r) do (push (list (first w) (second w) (third r)) parts))
          ;; each value is quantized in the window whose centre is the nearest
          (loop for i from d-start to d-end
                when (aref v i)
                  do (let* ((k (position (reduce #'min windows :key (lambda (w) (abs (- i (/ (+ (first w) (second w)) 2)))))
                                         windows :key (lambda (w) (abs (- i (/ (+ (first w) (second w)) 2))))))
                            (r (nth k results))
                            (c (nth (position i (first r)) (second r))))
                       (setf (aref classes i) c
                             (aref values i) (nth c (third r))))))))
    (values (coerce values 'list) (coerce classes 'list) (nreverse parts))))

(defgeneric filt-quantize (seq levels &key mode thres window step segments out)
  (:documentation "FILT-QUANTIZE: quantizes the sequence of numbers <seq> (a NIL being a missing value, kept): each value is replaced by
the centre of its class. <levels> is the number of levels, or the list of their initial centres (see class-num).
:mode : :1d-centroids (by default) or :centroids, the dynamic clouds of class-num on the values, where each value counts (the
time spent); or a method of exsample (:minmax, :minflexmax, :major-extrema, :landmarks, :angles), class-num on the salient
points given by this method, with the threshold :thres (0 by default), then each value at the nearest centre, the centres
being fixed: with :minmax, each turn of the sequence (a minimum or a maximum) counts once, whatever its duration.
:window : NIL (by default), the whole sequence (as class-num); an integer, a sliding window of this number of positions; a
float or a ratio, a part of the length (1/4: a quarter). :step : an integer, a number of positions; a float or a ratio, a part
of the window (1/2 by default). Each value is quantized in the window whose centre is the nearest.
:segments : T, each run of numbers between NILs is quantized apart (the parts of :window are then parts of the run).
:out : :values (by default), the quantized sequence; :classes, the level of each value (numbered by increasing centre in its
window or segment); :all, three values: the quantized sequence, the levels, and the list of (start end centres) of each window
or segment."))

(defmethod filt-quantize ((seq list) levels &key (mode :1d-centroids) thres window (step 1/2) segments (out :values))
  (unless (member mode '(:1d-centroids :centroids :minmax :minflexmax :major-extrema :landmarks :angles))
    (error "filt-quantize: unknown mode ~S, use :1d-centroids, :centroids or a method of exsample." mode))
  (when (and thres (member mode '(:1d-centroids :centroids)))
    (error "filt-quantize: :thres applies only to the methods of exsample."))
  (unless (every (lambda (x) (or (null x) (realp x))) seq)
    (error "filt-quantize: the values must be numbers, or NIL."))
  (unless (or (null window) (and (realp window) (plusp window)))
    (error "filt-quantize: the window must be a positive number, not ~S." window))
  (unless (and (realp step) (plusp step))
    (error "filt-quantize: the step must be a positive number, not ~S." step))
  (multiple-value-bind (values classes parts)
      (refrains::quantize seq levels :mode mode :thres (or thres 0) :window window :step step :segments segments)
    (ecase out
      (:values values)
      (:classes classes)
      (:all (values values classes parts)))))

(defgeneric filt-mean (seq window &optional step)
  (:documentation "Values replaced by their respective  windowed mean values."))

(defmethod filt-mean ((seq list) (window real) &optional (step 1))
  (filt-function seq #'refrains::mean window step))

;(filt-mean '(1 2 1 1 3 4 5 6 0 0 1) 3)


(defgeneric filt-median (seq window)
  (:documentation "FILT-MEDIAN: median filter over a window of <window> values centred on each value of <seq>
(an even window is enlarged to the next odd size, so that the result is made of values of <seq>);
the first and last values are repeated at the edges. The result has the same length as <seq>."))

(defmethod filt-median ((seq t) (window number))
  (refrains::median-filter seq window))

(defgeneric filt-extrema (seq window &optional mode)
  (:documentation "FILT-EXTREMA: maximum (<mode> :max, by default) or minimum (:min) over a window of <window> values
centred on each value of <seq>, the contrary of the median filter: the peaks (or the hollows) are widened.
:open (minimum then maximum) removes the peaks narrower than the window, :close (maximum then minimum) fills
the hollows narrower than the window, keeping the other values in place. An even window is enlarged to the
next odd size; the first and last values are repeated at the edges. The result has the same length as <seq>."))

(defmethod filt-extrema ((seq t) (window number) &optional (mode :max))
  (refrains::extrema-filter seq window mode))

(defgeneric filt-lowpass (seq alpha &optional gamma)
  (:documentation "FILT-LOWPASS: exponential smoothing of <seq>: each value moves by the fraction <alpha> (0 to 1) towards
the input, s(t) = s(t-1) + alpha (x(t) - s(t-1)). With <gamma> (0 to 1), double exponential smoothing (Holt), which also
follows the trend of <seq>. The result has the same length as <seq>."))

(defmethod filt-lowpass ((seq t) (alpha number) &optional (gamma nil))
  (if (not gamma)
      (refrains::exponential-smoothing seq alpha)
    (refrains::double-exponential-smoothing seq alpha gamma)))

(defgeneric filt-repeat (seq &optional mode test)
  (:documentation "FILT-REPEAT: removes the consecutive identical elements of <seq> (<mode> nil or :delete), or, for
numbers, replaces each run of identical values by a ramp towards the next different value (<mode> :linear, or :interp),
keeping the length of <seq>. <test>: identity of the elements (equalp by default)."))

(defmethod filt-repeat ((seq t) &optional (mode nil) (test #'equalp))
  (case mode
    ((nil :delete) (refrains::rem-local-rep seq test))
    ((:linear :interp)
     (if (every #'numberp seq)
         (refrains::nocons= seq test)
         (refrains::rem-local-rep seq test)))
    (t (error "filt-repeat: unknown mode ~S, use nil, :delete or :linear." mode))))

(defgeneric filt-noise (seq &optional mode val)
  (:documentation  "FILT-NOISE: jitters or adds some noise into sequence <seq> using different methods, according to the first optional argument <mode>,
with the amount <val> (0.1 by default), relative to the range (max - min) of <seq>:
 :nozero : replaces each zero value of <seq> with a random value in ]0, val * range[
 :swap : swaps val * length pairs of elements (val integer: the number of swaps)
 :relative : adds to each value a random amount in [-val * range, val * range]
A sequence which is not numerical is swapped.
<mode> may also be a function of two arguments (x l): each element x of <seq> is replaced by its result, l being the whole <seq>; <val> is ignored.
For instance (lambda (x l) (declare (ignore x)) (nth (random (length l)) l)) replaces each element by a random element of <seq>."))

(defmethod filt-noise ((seq t) &optional (mode :nozero) (val 0.1))
  (refrains::fnoise seq mode val))

(defgeneric graph-span (mat-dist &optional verbose)
  (:documentation   "GRAPH-SPAN: minimum spanning tree build on a semi-matrix of distances <mat-dist>."))

(defmethod graph-span ((mat-dist list) &optional (verbose nil))
  (spanning-tree mat-dist verbose))

(defgeneric graph-dendrogram (mat-dist &key linkage)
  (:documentation "GRAPH-DENDROGRAM: dendrogram of the hierarchical classification of the objects of a semi-matrix of
distances or of a graph <mat-dist>, a list of edges (node-a node-b distance). Returns two values: the list of the
successive fusions (distance group-a group-b), by increasing distance, where a group is the list of its nodes;
and the dendrogram, where each fusion is (distance tree-a tree-b) and the leaves are the objects.
:linkage defines the distance of two groups: :single (by default) the smallest distance of their objects,
given by the minimum spanning tree (see graph-span; a graph not connected gives the list of the dendrograms
of its parts); :complete the greatest distance; :average (UPGMA) the mean distance; :ward (Ward's method) the
fusion that increases the least the inertia within the groups, its distance being the square root of twice
this increase (the distance itself for two objects). :complete, :average and :ward need a complete semi-matrix
of distances; :ward supposes euclidean distances."))

(defmethod graph-dendrogram ((mat-dist list) &key (linkage :single))
  (case linkage
    (:single (refrains::single-linkage mat-dist))
    ((:complete :average :ward) (refrains::agglomerative-clustering mat-dist linkage))
    (t (error "graph-dendrogram: unknown linkage ~S, use :single, :complete, :average or :ward." linkage))))

(defgeneric morph-seq (seq1 seq2 &key test random)
  (:documentation "MORPH-SEQ: interpolates the sequence <seq1> to the sequence <seq2> with the minimum of steps,
changing one element at a time (substitution, deletion or insertion) along an edit path of minimal cost (see
dist-edit): the list of the sequences from <seq1> to <seq2>, as many steps as their edit distance. <test>:
identity of the elements (equalp by default). For equal costs, substitution is preferred, then deletion,
then insertion; with :random t, one of them at random. Two strings give strings."))

(defmethod morph-seq ((seq1 list) (seq2 list) &key (test #'equalp) (random nil))
  (refrains::s-interpolate seq1 seq2 :test test :random random))

(defmethod morph-seq ((seq1 string) (seq2 string) &key (test #'equalp) (random nil))
  (mapcar #'(lambda (s) (coerce s 'string))
          (refrains::s-interpolate seq1 seq2 :test test :random random)))
