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

;;;; package.lisp
;;;;
;;;; The OMPW package (PWGL/OpenMusic bindings, see fv-morphologie) is used
;;;; only when it is already loaded, so the system also loads in a plain
;;;; Common Lisp image.

;;;; Lisp tools to analyse sequences of symbols or signs wich represent music,
;;;; for PWGL and OpenMusic (and Lisp).
;;;;
;;;; Frederic Voisin, Paris - Montbeliard, 1994-2010
;;;; rewriting of morphologie for Common-Lisp, OpenMusic and PWGL
;;;;
;;;; Thank's to Jacopo Baboni-Schilingi, Giacomo Platini, Paolo Aralla, Killian Sprotte, Julien Vincenot, Carlo Ciceri...

;;;; TODO
;;;; struct ---> pourcentage de completion !!!!
;;;; adding a som somewhere in classification - with save weigths then analysing weigth (> tutorial) ?
;;;; ...

(defpackage :refrains
  (:use :cl . #.(if (find-package :ompw) '(:ompw) '()))
  (:export
   ;; 1. transcription
   #:transcode #:num>base #:num>alpha #:alpha>num #:list>sym #:str>sym
   #:filt-median #:filt-extrema #:filt-mean #:filt-lowpass
   #:filt-repeat #:filt-noise #:filt-function #:filt-quantize
   #:graph-span #:graph-dendrogram #:graph>matrix
   #:morph-seq
   ;; 2. classification
   #:exsample #:separate
   #:motif-group
   #:mark-structure #:motif-structure #:class-num #:class-sym #:graph-part
   ;; 3. evaluation
   #:mark-position #:mark-list #:motif-position #:motif-list
   #:graph-nodes #:graph-leaves #:graph-degree #:graph-path
   #:dist-euclidean #:dist-cityblock #:dist-hamming #:dist-edit
   #:dist-multi-edit #:dist-structure #:dist-graph
   #:dist-set #:dist-jaccard-bin
   #:histogram #:entropy #:self-info #:inner-dynamic
   #:graph-length
   ;; 4. read/write
   #:read-text #:write-list #:display-list #:seq>plot #:seq>abc #:seq>ly #:graph>dot #:dendrogram>dot
   ;; documentation
   #:help #:doc))
