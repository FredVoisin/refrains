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

;;;; refrains tests
;;;; FiveAM is used here only for testing the code.
;;;; Run with (asdf:test-system :refrains)

(defpackage :refrains/tests
  (:use :cl :fiveam)
  (:import-from :refrains
                ;; encodage
                #:transcode #:alpha>num #:num>alpha #:num>base #:concaten #:list>sym
                #:str>sym #:separate #:split-string #:morph-seq
                #:filt-median #:filt-extrema #:filt-repeat #:filt-lowpass #:filt-mean #:filt-function #:filt-quantize #:filt-noise #:exsample
                ;; distances
                #:dist-euclid #:dist-euclidean #:dist-cityblock #:dist-hamming
                #:dist-edit #:dist-multi-edit #:dist-structure #:dist-graph
                ;; information
                #:histogram #:entropy #:self-info #:inner-dynamic
                ;; classification
                #:mark-position #:mark-list #:mark-structure #:motif-structure
                #:motif-position #:motif-list #:motif-group #:class-num #:class-sym
                ;; graphs
                #:graph-span #:graph-dendrogram #:graph-path #:graph-length #:graph-degree #:graph-nodes
                #:graph-leaves #:graph>dot #:graph-part #:dendrogram>dot
                ;; io
                #:read-text #:write-list #:seq>plot #:seq>abc #:date-string
                #:help #:doc))

(in-package :refrains/tests)

(def-suite refrains
  :description "All refrains tests.")

(defun seeded-random-state (&optional (seed 42))
  "A random state seeded with SEED, where the implementation allows it,
so that the tests of the random algorithms are reproducible."
  #+sbcl (sb-ext:seed-random-state seed)
  #+ecl (make-random-state seed)
  #-(or sbcl ecl) (make-random-state t))

(defun count-substring (part string)
  "The number of occurrences of PART in STRING."
  (loop with start = 0 for i = (search part string :start2 start)
        while i count t do (setf start (1+ i))))

(defun approx= (a b &optional (epsilon 1e-6))
  (< (abs (- a b)) epsilon))
