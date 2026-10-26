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

;;;; graphs.lisp
;;;;
;;;; Trees and graphs: minimum spanning tree, paths, lengths, degrees,
;;;; adjacency matrices, partitions.

(in-package :refrains)

;;; TREES AND GRAPHS
; 1. minimum spanning tree (in french: arbre de longueur minimum ou arbre de recouvrement)
; using Prim's algorithm

(defun spanning-tree (graph &optional verbose)
  "Minimum spanning tree of graph, a list of edges (vertex-a vertex-b distance), by Kruskal's algorithm:
the edges are taken by increasing distance (in their order in graph for equal distances), and kept if
they join two parts not yet joined. Vertices are compared with equal. The result is deterministic;
if graph is not connected, it is a minimum spanning forest (one tree for each connected part)."
  (let ((parent (make-hash-table :test #'equal))
        (tree nil)
        (vertices 0))
    (labels ((root (x)
               (let ((p (gethash x parent x)))
                 (if (equal p x) x (setf (gethash x parent) (root p))))))
      (dolist (e graph)
        (dolist (v (list (first e) (second e)))
          (unless (nth-value 1 (gethash v parent))
            (setf (gethash v parent) v)
            (incf vertices))))
      (dolist (e (stable-sort (copy-list graph) #'< :key #'third))
        (let ((ra (root (first e))) (rb (root (second e))))
          (unless (equal ra rb)
            (setf (gethash ra parent) rb)
            (when verbose (message e))
            (push e tree))))
      (when (and graph (< (length tree) (1- vertices)))
        (message (format nil "graph-span: the graph is not connected: minimum spanning forest of ~D trees."
                         (- vertices (length tree)))))
      (nreverse tree))))

(defun graph-neighbours (graph)
  "Hash table (test equal) of the neighbours of each node of graph, a list of edges
(node-a node-b distance): a list of (neighbour . distance), in the order of the edges."
  (let ((nb (make-hash-table :test #'equal)))
    (dolist (e graph nb)
      (push (cons (second e) (third e)) (gethash (first e) nb))
      (push (cons (first e) (third e)) (gethash (second e) nb)))
    (maphash #'(lambda (k v) (setf (gethash k nb) (nreverse v))) nb)
    nb))

(defun shortest-paths (neighbours start)
  "Dijkstra's algorithm from start: two hash tables (test equal), the distance of each node
reachable from start, and its predecessor on a shortest path. Distances must be positive or 0."
  (let ((dist (make-hash-table :test #'equal))
        (pred (make-hash-table :test #'equal))
        (done (make-hash-table :test #'equal))
        (frontier (list start)))
    (setf (gethash start dist) 0)
    (loop while frontier
          do (let* ((n (let ((best (first frontier)))
                         (dolist (x (rest frontier) best)
                           (when (< (gethash x dist) (gethash best dist)) (setf best x)))))
                    (dn (gethash n dist)))
               (setf frontier (delete n frontier :test #'equal :count 1)
                     (gethash n done) t)
               (dolist (m (gethash n neighbours))
                 (let ((node (car m)) (d (+ dn (cdr m))))
                   (unless (gethash node done)
                     (multiple-value-bind (old found) (gethash node dist)
                       (when (or (not found) (< d old))
                         (unless found (push node frontier))
                         (setf (gethash node dist) d
                               (gethash node pred) n))))))))
    (values dist pred)))

(defun path-to (pred start end)
  "The nodes of the path from start to end, from the predecessors pred (see shortest-paths)."
  (let ((path (list end)))
    (loop until (equal (first path) start)
          do (push (gethash (first path) pred) path))
    path))

(defun find-path (tree start end)
  "The nodes of the shortest path (by distance) from start to end in tree, a list of edges
(node-a node-b distance), or nil if there is no path. Nodes are compared with equal.
In a tree there is only one path; in other graphs, Dijkstra's algorithm gives the shortest."
  (if (equal start end)
      (list start)
      (multiple-value-bind (dist pred) (shortest-paths (graph-neighbours tree) start)
        (when (nth-value 1 (gethash end dist))
          (path-to pred start end)))))

(defun graph-distance (tree start end)
  "The length of the shortest path from start to end in tree, or nil if there is no path."
  (if (equal start end)
      0
      (values (gethash end (shortest-paths (graph-neighbours tree) start)))))

(defun paths-from (start ends neighbours)
  "The shortest paths from start to each of ends reachable from it (one search from start)."
  (multiple-value-bind (dist pred) (shortest-paths neighbours start)
    (loop for e in ends
          when (nth-value 1 (gethash e dist))
            collect (path-to pred start e))))

(defun paths-to-leaves (start tree)
  "The paths from start to each leaf of tree."
  (paths-from start (remove start (leaves tree) :test #'equal) (graph-neighbours tree)))

(defun all-paths (tree)
  "The paths between all the pairs of leaves of tree."
  (let ((nb (graph-neighbours tree)))
    (loop for (l . others) on (leaves tree)
          append (paths-from l others nb))))

;; a tree is a list of list of edges each defined by two vertices, such as: ( (a b) (b c) (b d) (c e)...) 
; any edge can be defined by some properties in the rest of the list of its vertices ;
; for instance: (a b .1 2 z) is an edge between vertices a and b with (.12 z) as properties of the edge.

(defun vertex< (a b)
  "Order for vertices of any type: numbers first (by value), then all others by name."
  (flet ((name (x) (if (or (stringp x) (symbolp x) (characterp x)) (string x) (princ-to-string x))))
    (cond ((and (realp a) (realp b)) (< a b))
          ((realp a) t)
          ((realp b) nil)
          (t (string-lessp (name a) (name b))))))

(defun node-degrees (graph)
  "Hash table (test equal) of the degree of each node of graph, a list of edges (node-a node-b ...):
its number of edges (a loop (a a ...) counts once)."
  (let ((deg (make-hash-table :test #'equal)))
    (dolist (e graph deg)
      (incf (gethash (first e) deg 0))
      (unless (equal (first e) (second e))
        (incf (gethash (second e) deg 0))))))

(defun leaves (graph)
  "The leaves of graph (the nodes of degree 1), sorted as by all-vertices (graph-nodes)."
  (let ((deg (node-degrees graph)))
    (remove-if-not #'(lambda (v) (= 1 (gethash v deg))) (all-vertices graph))))

(defun all-vertices (tree)
  (let ((v (remove-duplicates (apply #'append (mapcar #'(lambda (x) (subseq x 0 2)) tree)) :test #'equal)))
    (sort v #'vertex<)))

(defun min-total-length (tree)
  (apply #'+ (mapcar #'caddr tree)))

;;Strahler number to do

;; graphs - suite

(defun adj-matrix (l-graph)
  "The symmetric adjacency matrix of l-graph, a list of edges (v1 v2 distance), as a list of rows:
rows and columns in the order of all-vertices (graph-nodes), the distance of each edge, 0 elsewhere.
Vertices are compared with equal (eq failed on strings, which are not eq when equal)."
  (let* ((v (all-vertices l-graph))
         (m (make-list (length v))))
    (dotimes (i (length m))
      (setf (nth i m) (make-list (length v) :initial-element 0)))
    (dolist (g l-graph m)
      (let ((i (position (car g) v :test #'equal))
            (j (position (cadr g) v :test #'equal))
            (d (caddr g)))
        (setf (nth j (nth i m)) d
              (nth i (nth j m)) d)))))

(defun part-tree-dist (tree)
  "Split a tree into partitions by cutting all its edges of maximum distance (see part-tree-n)."
  (if (null tree)
      (values nil nil)
      (let ((longest (reduce #'max (mapcar #'third tree))))
        (part-tree-n tree (1+ (count longest tree :key #'third :test #'=))))))

(defgeneric part-graph (graph mode &optional n)
  (:documentation "Does a partition of a graph <graph>, into <n> parts if <n> is given."))

(defmethod part-graph ((graph list) (mode symbol) &optional (n nil))
  (case mode
    ((nil :distance) (if n (part-tree-n graph n) (part-tree-dist graph)))
    (t (error "graph-part: unknown mode ~S, use :distance." mode))))

(defun tree-components (n-nodes edges)
  "Connected components of the graph of nodes 0..n-nodes-1 and edges (i j d):
for each node, the class of its component, numbered from 0 by order of first node."
  (let ((root (make-array n-nodes)))
    (dotimes (i n-nodes) (setf (aref root i) i))
    (labels ((find-root (i)
               (if (= i (aref root i)) i
                   (setf (aref root i) (find-root (aref root i))))))
      (dolist (e edges)
        (let ((a (find-root (first e))) (b (find-root (second e))))
          (unless (= a b) (setf (aref root (max a b)) (min a b)))))
      (let ((roots (loop for i below n-nodes collect (find-root i))))
        (normalize-class roots #'=)))))

(defun part-tree-n (tree n)
  "Split a tree into n partitions by cutting its n-1 longest edges (the first one in the tree if equal).
Returns the edges of each partition (((node)) for a single node) and the nodes of each partition."
  (let* ((nodes (remove-duplicates (append (mapcar #'first tree) (mapcar #'second tree))
                                   :test #'equal :from-end t))
         (cut (subseq (stable-sort (copy-list tree) '> :key #'third)
                      0 (min (max 0 (1- n)) (length tree))))
         (kept (remove-if #'(lambda (e) (member e cut :test #'eq)) tree))
         (comp (tree-components (length nodes)
                                (mapcar #'(lambda (e) (list (position (first e) nodes :test #'equal)
                                                            (position (second e) nodes :test #'equal)))
                                        kept)))
         (parts (loop for c from 0 to (if comp (apply #'max comp) -1)
                      collect (loop for x in nodes for k in comp when (= k c) collect x))))
    (values (mapcar #'(lambda (p)
                        (or (remove-if-not #'(lambda (e) (member (first e) p :test #'equal)) kept)
                            (list p)))
                    parts)
            parts)))

(defun single-linkage (graph)
  "Hierarchical classification by single linkage of the nodes of graph, a list of edges (node-a node-b distance),
for instance a semi-matrix of distances, given by the edges of its minimum spanning tree (Kruskal).
Returns two values: the fusions (distance group-a group-b) of the groups of nodes, by increasing distance,
a group being the list of its nodes; and the dendrogram, where each fusion is (distance tree-a tree-b) and
the leaves are the nodes (if graph is not connected, the list of the dendrograms of its connected parts)."
  (let ((clusters (make-hash-table :test #'equal)) ; node -> (group . tree)
        (fusions nil))
    (dolist (e (spanning-tree graph))
      (let ((ca (gethash (first e) clusters (cons (list (first e)) (first e))))
            (cb (gethash (second e) clusters (cons (list (second e)) (second e)))))
        (push (list (third e) (car ca) (car cb)) fusions)
        (let ((c (cons (append (car ca) (car cb)) (list (third e) (cdr ca) (cdr cb)))))
          (dolist (x (car c)) (setf (gethash x clusters) c)))))
    (let ((roots (remove-duplicates
                  (loop for x in (all-vertices graph)
                        collect (gethash x clusters (cons (list x) x)))
                  :test #'eq :from-end t)))
      (values (nreverse fusions)
              (if (cdr roots) (mapcar #'cdr roots) (cdr (car roots)))))))

(defun agglomerative-clustering (graph linkage)
  "Agglomerative hierarchical classification of the nodes of graph, a complete semi-matrix of distances
((node-a node-b distance) ...), by complete linkage (linkage :complete, the distance of two groups is the
greatest distance of their nodes), average linkage (:average, UPGMA, the mean distance of their nodes) or
Ward's linkage (:ward, the groups whose fusion increases the least the inertia within the groups: the distance
of two groups is the square root of twice this increase, the distance itself for two nodes).
At each step, the two closest groups are merged (the first ones in the order of the nodes for equal distances).
Returns the same two values as single-linkage: the fusions and the dendrogram."
  (let* ((nodes (all-vertices graph))
         (n (length nodes))
         (d (make-array (list n n) :initial-element nil))
         (index (make-hash-table :test #'equal)))
    (loop for x in nodes for i from 0 do (setf (gethash x index) i))
    (dolist (e graph)
      (let ((i (gethash (first e) index)) (j (gethash (second e) index)))
        (unless (or (= i j) (aref d i j))
          (setf (aref d i j) (third e) (aref d j i) (third e)))))
    (dotimes (i n)
      (loop for j from (1+ i) below n
            unless (aref d i j)
              do (error "graph-dendrogram: no distance between ~S and ~S: linkage ~S needs a complete semi-matrix of distances."
                        (nth i nodes) (nth j nodes) linkage)))
    (let ((groups (coerce (mapcar #'list nodes) 'vector))
          (trees (coerce nodes 'vector))
          (sizes (make-array n :initial-element 1))
          (alive (loop for i below n collect i))
          (fusions nil))
      (loop while (cdr alive)
            do (let (bi bj bd)
                 (loop for (i . rest) on alive
                       do (dolist (j rest)
                            (when (or (null bd) (< (aref d i j) bd))
                              (setf bi i bj j bd (aref d i j)))))
                 (push (list bd (aref groups bi) (aref groups bj)) fusions)
                 (dolist (k alive)
                   (unless (or (= k bi) (= k bj))
                     (let ((dk (ecase linkage
                                 (:complete (max (aref d bi k) (aref d bj k)))
                                 (:average (/ (+ (* (aref sizes bi) (aref d bi k))
                                                 (* (aref sizes bj) (aref d bj k)))
                                              (+ (aref sizes bi) (aref sizes bj))))
                                 ;; Lance & Williams' formula for Ward, on the squares of the distances
                                 (:ward (let ((na (aref sizes bi)) (nb (aref sizes bj)) (nk (aref sizes k)))
                                          (sqrt (max 0 (/ (- (+ (* (+ na nk) (expt (aref d bi k) 2))
                                                                (* (+ nb nk) (expt (aref d bj k) 2)))
                                                             (* nk (expt bd 2)))
                                                          (+ na nb nk)))))))))
                       (setf (aref d bi k) dk (aref d k bi) dk))))
                 (setf (aref groups bi) (append (aref groups bi) (aref groups bj))
                       (aref trees bi) (list bd (aref trees bi) (aref trees bj))
                       (aref sizes bi) (+ (aref sizes bi) (aref sizes bj))
                       alive (remove bj alive))))
      (values (nreverse fusions) (when alive (aref trees (car alive)))))))
