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

(def-suite dot :in refrains
  :description "Graphs drawn in the DOT format (neato).")
(in-suite dot)

(test graph>dot-stream
  (let ((dot (with-output-to-string (s) (graph>dot '((a b 1) (b c 0)) s))))
    (is (search "graph \"span-graph\" {" dot))
    (is (search "\"A\" -- \"B\"" dot))
    (is (search "\"B\" -- \"C\"" dot))))

(test graph>dot-dis-argument
  ;; used to refer to an undefined variable DISTORSION
  (finishes (with-output-to-string (s) (graph>dot '((a b 1)) s :dis 0.5))))

(test graph-name-from-path
  ;; a path without "/" crashed, and blanks cut the name
  (is (equal "out" (refrains::make-name-from-path "out.dot")))
  (is (equal "out" (refrains::make-name-from-path "out")))
  (is (equal "my graph" (refrains::make-name-from-path "my graph.dot")))
  (is (equal "c" (refrains::make-name-from-path "a.b/c.dot")))
  (is (equal "y" (refrains::make-name-from-path #p"/x/y.png")))
  (is (equal "span-graph" (refrains::make-name-from-path t))))

(test graph>dot-output
  (flet ((dot (graph &rest keys)
           (with-output-to-string (s) (apply #'graph>dot graph s keys))))
    ;; len was formatted on 3 characters first: 12.5 gave 13., 0.123456 gave .12
    (let ((d (dot '((a b 12.5) (b c 0.123456) (c d 1/3)))))
      (is (search "len=12.500000" d))
      (is (search "len=0.123456" d))
      (is (search "len=0.333333" d))
      ;; labels are quoted (1/3 unquoted is not valid DOT)
      (is (search "label=\"1/3\"" d)))
    ;; the case of the shape is kept (Mrecord gave mrecord)
    (is (search "shape=\"Mrecord\"" (dot '((a b 1)) :shape "Mrecord")))
    ;; no package prefix for the names of the nodes
    (let ((*package* (find-package :cl-user)))
      (is (search "\"A\" -- \"B\"" (dot (list (list 'refrains/tests::a 'refrains/tests::b 1))))))
    ;; quotes in names are escaped
    (is (search "\"q\\\"t\"" (dot '(("z" "q\"t" 2)))))
    ;; only edges of length 0, or no edge, used to fail
    (is (search "\"A\" -- \"B\" [len=1.000000]" (dot '((a b 0) (b c 0)))))
    (is (search "graph \"span-graph\" {" (dot '())))
    ;; overlap: nothing by default, overlap=false with nil, a Graphviz value with a string
    (is (not (search "overlap" (dot '((a b 1))))))
    (is (search "graph [overlap=\"false\", sep=\"+4\"];" (dot '((a b 1)) :overlap nil)))
    (is (search "overlap=\"scale\"" (dot '((a b 1)) :overlap "scale")))
    ;; invert: black on white by default, white on black with t
    (let ((d (dot '((a b 1)))))
      (is (search "color=black, fontcolor=black" d))
      (is (not (search "bgcolor" d))))
    (let ((d (dot '((a b 1) (b c 0)) :invert t)))
      (is (search "graph [bgcolor=black];" d))
      (is (search "color=white, fontcolor=white" d))
      (is (search "color=white, fontcolor=white, labelfloat=true" d))
      (is (search "color=lightskyblue" d)))))

(test graph>dot-neato
  ;; draws a graph with neato, if Graphviz is installed (else the test is skipped)
  (if (ignore-errors (uiop:run-program '("neato" "-V") :output nil :error-output nil) t)
      (uiop:with-temporary-file (:pathname tmp :type "svg" :keep nil)
        (let* ((svg (namestring tmp))
               (dot (namestring (make-pathname :type "dot" :defaults tmp))))
          ;; 1/3 as an unquoted label was a syntax error for Graphviz: no image was made
          (graph>dot '((a b 1) (a c 2.5) (b d 0) (c e 1/3)) svg :shape "Mrecord")
          (is (probe-file svg))
          (is (search "<svg" (uiop:read-file-string svg)))
          (ignore-errors (delete-file dot))))
      (skip "neato (Graphviz) is not installed")))

(test dendrogram>dot-output
  (flet ((dot (dendrogram &rest keys)
           (with-output-to-string (s) (apply #'dendrogram>dot dendrogram s keys))))
    (let ((d (dot '(3 (1 x y) (2 (1 a b) c)))))
      (is (search "graph \"dendrogram\" {" d))
      ;; the leaves, in the order of the dendrogram, from the top
      (is (< (search "label=\"X\"" d) (search "label=\"Y\"" d) (search "label=\"A\"" d)
             (search "label=\"C\"" d)))
      ;; every point has a position, for neato -n2
      (is (search "pos=" d))
      ;; the scale: 0 to 3 by 1
      (is (search "label=\"3\"" d))
      (is (not (search "bgcolor" d))))
    (is (search "bgcolor=black" (dot '(1 a b) :invert t)))
    ;; a list of dendrograms (graph not connected), strings as leaves
    (let ((d (dot '((1 "x" "y") (2 "c" "d")))))
      (is (search "label=\"x\"" d))
      (is (search "label=\"d\"" d)))
    ;; with graph-dendrogram
    (is (search "label=\"E\""
                (dot (nth-value 1 (graph-dendrogram '((a b 1) (a c 4) (b c 2) (c d 5) (d e 1)))))))))

(test dendrogram>dot-neato
  ;; draws a dendrogram with neato -n2, if Graphviz is installed (else the test is skipped)
  (if (ignore-errors (uiop:run-program '("neato" "-V") :output nil :error-output nil) t)
      (uiop:with-temporary-file (:pathname tmp :type "svg" :keep nil)
        (let* ((svg (namestring tmp))
               (dot (namestring (make-pathname :type "dot" :defaults tmp))))
          (dendrogram>dot '(0.5 (0.25 a b) c) svg)
          (is (search "<svg" (uiop:read-file-string svg)))
          (ignore-errors (delete-file dot))))
      (skip "neato (Graphviz) is not installed")))

