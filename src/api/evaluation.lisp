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

;;;; api/evaluation.lisp
;;;;
;;;; Public functions: evaluation (positions, motifs, distances, information)
;;;; and graph measures.

(in-package :refrains)

(defgeneric mark-position (seq mark &optional test cons)
  (:documentation "MARK-POSITION: returns all positions of marks in seq."))

(defmethod mark-position ((seq t) (mark t) &optional (test #'equalp) (cons t))
  (all-pos seq mark test cons))

(defgeneric mark-list (seq mark &key mark-test seg-test)
  (:documentation "MARK-LIST: returns the list of all segments and their position in <seq> beginning with some marks defined with argument <mark>.
If no argument mark (nil), considers all different symbols in <seq>.
Option :mark-test defines the test function for searching the marks (equalp by default).
Option :seg-test defines the test function for comparing the different segments."))

(defmethod mark-list ((seq t) (mark t) &key (mark-test #'equalp) (seg-test #'equalp))
  (when (and (symbolp mark-test) (not (boundp mark-test)))
    (setf mark-test (eval `(function ,mark-test))))
  (when (and (symbolp seg-test) (not (boundp seg-test)))
    (setf seg-test (eval `(function ,seg-test))))
  (mark-pos seq mark mark-test seg-test))

(defgeneric motif-position (motif seq &key diss l-var sub ins del uncom test)
  (:documentation "MOTIF-POSITION: returns all positions of a <motif> into a sequence <seq>.
Argument :diss is the threshold (from 0 to 1.0) of dissimilarity according to the normalized editing distance under which two different segments are considered to be the same ;
argument :l-var is the threshold for variation in length of the motifs to be compared ;
arguments :sub :ins :del :uncom and :test for tuning the editing distance (see dist-edit)."))

(defmethod motif-position ((motif t) (seq t) &key (diss 0) (l-var 0) (sub 1) (ins 1) (del 1) (uncom 0) (test #'equalp))
  (find-pos-in motif (coerce seq 'vector) 0 diss l-var
               #'(lambda (a b) (edit-dist a b sub ins del uncom t test))))

(defmethod motif-position ((motif string) (seq string) &key (diss 0) (l-var 0) (sub 1) (ins 1) (del 1) (uncom 0) (test #'equalp))
  ;; a string is searched as a list of characters (there was no method for strings)
  (motif-position (coerce motif 'list) (coerce seq 'list) :diss diss :l-var l-var
                  :sub sub :ins ins :del del :uncom uncom :test test))

(defgeneric motif-list (seq out &key diss l-var n sub ins del uncom test)
  (:documentation "MOTIF-LIST: returns the list of all motifs found into <seq> where a motif is any segment repeted at least one time according to editing distance.
Output can be sorted according to the length of segment (:length, or nil) or to their frequency (:freq); another output is an error.
Argument :diss is a threshold (from 0 to 1.0) of dissimilarity according to the normalized editing distance under which two different segments are considered to be the same ;
argument :l-var is the threshold for variation in length of the segments to be compared ;
argument :n is the maximum length of the motifs (lengths 2 to n), or a list (min max) (default: 3 to half the length of <seq>) ;
arguments :sub :ins :del :uncom and :test for tuning the editing distance (see dist-edit)."))

(defmethod motif-list ((seq t) (out t)
		       &key (diss 0) (l-var 0) (n nil)
		       (sub 1) (ins 1) (del 1) (uncom 0) (test #'equalp))
  (when (not out) (setf out :length))
  (unless (member out '(:length :freq))
    (error "motif-list: unknown output ~S, use :length or :freq." out))
  (let* ((diss (or diss 0))
         (l-var (or l-var 0))
         ;; the default distance (nil) gives the same results faster: with diss 0 and positive costs,
         ;; a distance of 0 means identical elements by test; with the default costs, it is the same
         ;; normalized edit distance
         (distance (if (or (and (zerop diss) (plusp sub) (plusp ins) (plusp del) (not (minusp uncom)))
                           (and (= sub ins del 1) (zerop uncom)))
                       nil
                       #'(lambda (a b) (edit-dist a b sub ins del uncom t test)))))
    (sort (whenlooploopwhenwhen seq diss l-var n distance test) '>
          :key (if (eq out :freq)
                   #'(lambda (x) (length (cdr x)))
                   #'(lambda (x) (length (car x)))))))

(defgeneric dist-euclidean (a b)
  (:documentation "DIST-EUCLIDEAN: euclidean distance between points a and b.
Point coordinates are represented by a list of values in any euclidean space with n dimensions (n integer > 0).
The dimensionality of the euclidean space is defined by the list representing <a> and <b>.
 If a is a list of coordinates (lists) and b null,
output is the list of distances for all points to all others ;
 if a or b is a number, consider b or a as list of numbers (1 dim).
If a and b are lists with not same size (i.e points with not same dimensions),
 returns NIL (no distance)."))

(defmethod dist-euclidean ((a t) (b t))
  (refrains::dist-euclid a b))

(defgeneric dist-cityblock (a b)
  (:documentation "DIST-CITYBLOCK: city-block distance between <x> and <y> which represent 'points' into kind of euclidean space.
If <y> is null, <x> may represent a list of points, then the output is the list of city-block distances for all points to all others."))

(defmethod dist-cityblock ((a t) (b t))
  (refrains::city-block a b))

(defgeneric dist-hamming (a b &optional norm test)
  (:documentation "DIST-HAMMING: Hamming distance between list a and list b."))

(defmethod dist-hamming ((a t) (b t) &optional (norm t) (test #'eq))
  (refrains::hamming-dist a b norm test))

;; distances between sets: the order and the repetitions of the elements are ignored

(defgeneric dist-set (a b &key measure test key)
  (:documentation "DIST-SET: distance between the sets a and b, from 0 (the same elements, two empty sets too)
to 1 (no common element). The order and the repetitions of the elements are ignored. :measure (a symbol
of any package, a keyword or a string):
jaccard (or nil, default): Jaccard distance, 1 - |a & b| / |a | b|;
sorensen: Sorensen-Dice distance, 1 - 2 |a & b| / (|a| + |b|), which weighs the common elements more;
mountford: Mountford distance, 1 / (1 + M), with Mountford's index M = 2j / (2|a||b| - (|a| + |b|)j), j = |a & b|.
:test: identity of the elements (equalp by default); :key: the part of the elements compared (identity by default).
If <b> is nil, the distances between all the sets of <a>."))

(defmethod dist-set ((a t) (b t) &key (measure nil) (test #'equalp) (key #'identity))
  ;; measures are recognized by their names: 'sorensen from any package, :sorensen or "sorensen"
  (let* ((name (if measure (string-upcase (string measure)) "JACCARD"))
         (d (cond ((string= name "JACCARD")
                   #'(lambda (x y) (refrains::jaccard-dist x y :test test :key key)))
                  ((string= name "SORENSEN")
                   #'(lambda (x y) (- 1.0 (refrains::sorensen-similarity x y :test test :key key))))
                  ((string= name "MOUNTFORD")
                   #'(lambda (x y) (- 1.0 (refrains::mountford-similarity x y :test test :key key))))
                  (t (error "dist-set: unknown measure ~S, use jaccard, sorensen or mountford." measure)))))
    (if (and a (null b))
        (refrains::semi-matrix d a)
        (funcall d a b))))

(defgeneric dist-jaccard-bin (a b &key test key)
  (:documentation "DIST-JACCARD-BIN: Jaccard distance between the binary vectors (lists of the same length) a and b:
among the positions where a value is present in a or in b, the proportion of those where it is present in only one;
the positions absent from both are not counted. :test: a predicate telling if a value is present (by default,
any value other than nil and 0); :key: the part of the elements tested (identity by default).
If <b> is nil, the distances between all the vectors of <a>."))

(defmethod dist-jaccard-bin ((a t) (b t) &key (test nil) (key #'identity))
  (refrains::binary-jaccard-dist a b :test test :key key))

(defgeneric dist-edit (seq1 seq2 &key sub ins del uncom norm test)
  (:documentation "DIST-EDIT: editing distance from seq1 to seq2.
Keywords arguments are:
:sub : cost for substituting symbols (1 by default)
:ins : cost for inserting symbols (1 by default)
:del : cost for deleting symbols (1 by default)
:uncom : cost for substituting symbols which are not common to both sequences
:norm : result divided by the length of the longer sequence, from 0 to 1 with costs of 1 (T, or NIL by default)
:test : identity function"))

(defmethod dist-edit ((seq1 t) (seq2 t)
		      &key (sub 1) (ins 1) (del 1) (uncom 0) (norm NIL) (test #'equalp))
  (refrains::edit-dist seq1 seq2 sub ins del uncom norm test))

(defgeneric dist-multi-edit (seq1 seq2 wgth &key sub ins del uncom test)
  (:documentation "DIST-MULTI-EDIT: edit distance between seq1 and seq2, whose elements are lists of descriptors (one per dimension),
the distances of the dimensions being weighted by wgth: a number (same weight for all) or a list of weights, one per dimension
(a list too short is completed with its last weight, a list too long is cut). The weights are normalized to sum to 1."))

(defmethod dist-multi-edit ((seq1 t) (seq2 t) (wgth t) &key (sub 1) (ins 1) (del 1) (uncom 0) (test #'equalp))
  (refrains::multi-edit-dist seq1 seq2 wgth :change sub :insert ins :delete del :inex uncom :test test))

(defgeneric dist-structure  (a b &key w-occ w-rep test)
  (:documentation "DIST-STRUCTURE: dissimilarity between the sequences <a> and <b> from the point of view of their structure,
from 0 (same structure) to 1: for each element, its number of occurrences and the position of its first occurrence
are compared with the edit distance. Experimental.
:w-occ, :w-rep: weights of the occurrences and of the repetitions; :test: identity of the elements (equalp by default).
If <b> is nil, the distances between all the sequences of <a>."))

(defmethod dist-structure  ((a t) (b t) &key (w-occ 1.) (w-rep 1.) (test #'equalp))
  (refrains::struct-dist a b w-occ w-rep test))

(defgeneric dist-graph (v1 v2 graph)
  (:documentation "DIST-GRAPH: distance between the nodes <v1> and <v2> of a graph: the length of the shortest path
between them (Dijkstra, see graph-path), 0 from a node to itself, nil if there is no path.
A list of nodes <v2> gives the list of their distances to <v1>, and nil the distances of <v1> to all the nodes,
in the order of graph-nodes."))

(defmethod dist-graph ((v1 t) (v2 t) (graph list))
  ;; the length of the shortest path, nil if there is none (it gave 0)
  (graph-distance graph v1 v2))

(defmethod dist-graph ((v1 t) (v2 list) (graph list))
  (mapcar #'(lambda (x) (dist-graph v1 x graph)) v2))

(defmethod dist-graph ((v1 t) (v2 null) (graph list))
  ;; the distances to all the nodes, in the order of all-vertices (graph-nodes), 0 to v1 itself
  ;; (it gave the number of nodes of the paths to the other nodes)
  (mapcar #'(lambda (x) (dist-graph v1 x graph)) (all-vertices graph)))

(defgeneric histogram (data &key test thes)
  (:documentation "HISTOGRAM: histogram of data, as a list of (element count): sorted by increasing value for numbers,
else by decreasing count (elements of equal count in their order of first appearance). With optional arguments:
test: identity test (equalp by default)
thes: thesaurus or list of symbols to be considered."))

(defmethod histogram ((data t) &key (test #'equalp) (thes nil))
  (refrains::histogramme data :test test :thes thes))

(defgeneric entropy (data &optional mode samples test)
  (:documentation "ENTROPY: entropy of the set or sequence <data>, according to <mode> (a symbol of any package, a keyword or a string):
shannon-2 (or nil, default): Shannon entropy in base 2;
shannon-n: Shannon entropy in base n, the number of distinct elements (from 0 to 1);
shannon-e: Shannon entropy with the natural logarithm;
cond-sh: conditional entropy (experimental).
<samples>: number of consecutive windows of <data>, giving the list of their entropies.
<test>: identity of the elements (equalp by default)."))

(defmethod entropy ((data t) &optional (mode nil) (samples nil) (test #'equalp))
  ;; modes are recognized by their names: 'shannon-2 from any package, :shannon-2 or "shannon-2"
  ;; (they were compared with eq to the symbols of refrains)
  (let* ((name (if mode (string-upcase (string mode)) "SHANNON-2"))
         (r (cond ((string= name "SHANNON-2") (shannon-entropy data 2 samples test))
                  ((string= name "SHANNON-E") (shannon-entropy data (exp 1) samples test))
                  ((string= name "SHANNON-N") (shannon-entropy data nil samples test))
                  ((string= name "COND-SH") (entropie-conditionnelle data nil samples test))
                  (t (error "entropy: unknown mode ~S, use shannon-2, shannon-n, shannon-e or cond-sh." mode)))))
    (if (listp r) (mapcar #'float r) (float r))))

(defgeneric self-info (data elt &optional test)
  (:documentation "SELF-INFO: self-information of the element <elt>: -log2 of its frequency in <data>, nil if the element
is absent or <data> is empty. With <elt> nil, each element with its information, the most informative first
(elements of equal information in their order of first appearance). <test>: identity of the elements (equalp by default)."))

(defmethod self-info ((data t) (elt t) &optional (test #'equalp))
  (refrains::self-information data elt test))

;(defmethod redundancy ((data t))
;  :non-generic t
;  :class morphologie-box
;  (refrains::redondance data))

(defgeneric inner-dynamic (seq &optional test)
  (:documentation "INNER-DYNAMIC: a kind of inner dynamic of the distribution of the symbols (marks) of the sequence <seq>,
 one value for each element, computed by integrating the contrast/mark analysis: novelty of the marks and their echoes
 in the sequence (rewritten from Paolo Aralla's 'energy profile'). Experimental.
<test>: identity of the elements (equalp by default).
Reference: Paolo Aralla, 'Analisi morfologica. Un modello matematico per descrivere la relazione fra struttura morfologica
del messaggio, attivita' mnemonico-percettiva e risposta psichica', Prisma 01, Euresis Edizioni, 2002
(sections 3 'New/Old-Analysis' and 5 'Energy-profile')."))

(defmethod  inner-dynamic ((seq t) &optional (test #'equalp))
  (refrains::mark-dynamic seq test))

(defgeneric graph-length (graph)
  (:documentation "GRAPH-LENGTH: the total length of a graph, the sum of the lengths of its edges; for a minimum spanning tree
(see graph-span), a measure of the diversity of the objects."))

(defmethod graph-length ((graph list))
  (refrains::min-total-length graph))

(defgeneric graph-degree (node graph)
  (:documentation "GRAPH-DEGREE: degree of a node in a graph, the number of its edges (0 if it is not in the graph).
A list of nodes gives the list of their degrees, nil the degrees of all the nodes, in the order of graph-nodes."))

(defmethod graph-degree ((node t) (graph list))
  (tree-degree node graph))

(defmethod graph-degree ((node list) (graph list))
  (mapcar #'(lambda (x) (graph-degree x graph)) node))

(defmethod graph-degree ((node null) (graph list))
  (graph-degree (all-vertices graph) graph))

(defgeneric graph-nodes (graph)
  (:documentation "GRAPH-NODES: list of all nodes of a graph, each node once, sorted."))

(defmethod graph-nodes ((graph list))
  (refrains::all-vertices graph))

(defgeneric graph-leaves (graph)
  (:documentation "GRAPH-LEAVES: returns all extremities (leaves) of a graph, the nodes of degree 1, sorted as by graph-nodes."))

(defmethod graph-leaves ((graph list))
  (refrains::leaves graph))

(defgeneric graph-path (from to graph)
  (:documentation "GRAPH-PATH: returns path(s) from node(s) or leave(s) to one or some other node(s) or leave(s) of a graph; in a graph with cycles, the shortest path by distance."))

(defmethod graph-path ((from number) (to number) (graph list))
  (find-path graph from to))

(defmethod graph-path ((from symbol) (to symbol) (graph list))
  (find-path graph from to))

(defmethod graph-path ((from null) (to null) (graph list))
  (all-paths graph))

(defmethod graph-path ((from t) (to null) (graph list))
  (paths-to-leaves from graph))

;; nil is a symbol: without this method, (graph-path 'a nil graph) would look for a node named nil
(defmethod graph-path ((from symbol) (to null) (graph list))
  (paths-to-leaves from graph))

(defmethod graph-path ((from null) (to t) (graph list))
  (paths-to-leaves to graph))

(defmethod graph-path ((from list) (to null) (graph list))
  (mapcar #'(lambda (v) (paths-to-leaves v graph)) from))

(defmethod graph-path ((from null) (to list) (graph list))
  (mapcar #'(lambda (v) (paths-to-leaves v graph)) to))

(defmethod graph-path ((from list) (to list) (graph list))
  (mapcar #'(lambda (s)
              (remove-duplicates (mapcar #'(lambda (e)
                                             (find-path graph s e)) to)
                                 :test #'equal))  from))

(defmethod graph-path ((from string) (to string) (graph list))
  (find-path graph from to))
