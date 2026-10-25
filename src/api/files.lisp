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

;;;; api/files.lisp
;;;;
;;;; Public functions: import and export (text files, lists, Max coll files),
;;;; and graphs and dendrograms in the DOT format, drawn by neato.

(in-package :refrains)

(defgeneric read-text (file &key mode sep rem-test)
  (:documentation "READ-TEXT: reads text <file> using following <mode> formats (another mode is an error):
 T : each line of file as a list of symbols or numbers
 NIL : flat mode, reads file as a single list of strings
 :charcode : the segments of the file, as lists of character codes.
Additional keyword :sep is a string defining all characters defining a separator, besides blanks
(spaces, tabulations, newlines), or t for the usual punctuation marks; with :charcode, it may also
be a list of characters or codes, or (:ignore c ...) to separate at all the characters which are
not letters or digits (in any alphabet), but c ...
Additional Keyword :rem-test defines a function to remove choosen words."))

(defmethod read-text ((file t)  &key (mode t) (sep nil) (rem-test nil))
  (read-txt-file file :mode mode :marks sep :rem-test rem-test))

; (defmethod read-midi ((file))
; (defmethod read-sdif ((file))

(defgeneric display-list (list &optional recursive)
  (:documentation "DISPLAY-LIST: prints out to the Lisp listener each element of list within a newline with indentation relative to list level."))

(defmethod display-list (list &optional (recursive nil))
  (declare (ignore recursive))
  (list-display list))
  
(defgeneric seq>plot (seq &key out dimension start duration low high width height mode labels)
  (:documentation "SEQ>PLOT: draws the sequence <seq>, with characters to see its shape in the listener or a terminal,
or in an SVG image. <seq> is a list of events sorted by time, each event a list (time value0 value1 ...): the time is
drawn in x, proportionally (empty columns where there is no event), and the value of the dimension :dimension (0 by
default, (nth dimension (cdr event)), a number) in y, between its maximum (above) and its minimum (below). Each column
marks all the events of its time span, so that no extremum is lost.
:out : NIL (by default) or T, draws with characters in the listener; a stream, draws with characters into it; a string
or a pathname, writes an SVG image in this file (of type svg when it has no type) and returns its name.
:start and :duration: the window to draw, from the time :start (the first event by default) during :duration
(until the last event by default); :low and :high: the bottom and the top of the plot, to zoom in y (the minimum
and the maximum of the values by default), the values outside them are not drawn; :width and :height: the size of the plot, in characters (72 and 16 by default)
or in pixels for SVG (720 and 240 by default).
:mode : for SVG, :line (by default) joins the events, :points draws a point by event.
:labels : T (by default) writes the bottom, the top and the times of the beginning and the end of the window;
NIL draws the plot alone."))

(defmethod seq>plot ((seq list) &key out (dimension 0) start duration low high width height (mode :line)
                                     (labels t))
  (if (or (stringp out) (pathnamep out))
      (plot-svg seq out :dimension dimension :start start :duration duration :low low :high high
                        :width (or width 720) :height (or height 240) :mode mode :labels labels)
      (plot-chars seq :dimension dimension :start start :duration duration :low low :high high
                      :width (or width 72) :height (or height 16) :labels labels
                      :stream (if (streamp out) out *standard-output*))))

(defgeneric write-list (list file &optional mode)
  (:documentation "WRITE-LIST: write list to a file using following optional argument <mode> format:
:flat (by default) : each element of list is written in a new line, sub-lists without parentheses (as read by read-text)
:lisp : list is written as a Lisp list
:coll : a Max coll file, one line index, data; for each element, from index 0."))

(defmethod write-list ((list list) (file t) &optional (mode :supersede))
  (list-write list file mode))

(defgeneric graph>dot (graph &key out dis scale shape legend overlap invert)
  (:documentation   "GRAPH>DOT: converts a graph (list of edges) into an undirected graph into dot langage to be processed using neato program.
Arguments:
<graph> : the graph, as a structured list.
Keywords:
 :out : NIL (by default) or T, prints out in the listener; a stream, writes into it; a string or a pathname, the
pathname of the output: a dot file, and, unless its type is dot, the image made by neato in the format of its type
(png without type).
 :dis : amount of distortion allowed for distances fir drawing the graph (from 0.0 for minimum distorsion to 1.0 maximum distorsion)
 :scale : scaling factor for the mininum distance
 :shape : string or list of strings to define node's shape, using 'neato' definitions
 :legend : label the edges with their lengths (t by default)
 :overlap : t (default) lets the nodes overlap; nil makes neato move them apart (useful when the lengths
are short compared with the names of the nodes); a string is the value of the Graphviz overlap attribute (\"scale\", \"prism\"...)
 :invert : t draws white on black instead of black on white (nil by default)
"))

(defmethod graph>dot ((graph t) &key out (dis 1) (scale t) (shape "ellipse") (legend t) (overlap t) (invert nil))
  (refrains::graph2dot graph dis scale shape out legend overlap invert))

(defgeneric dendrogram>dot (dendrogram &key out width step invert)
  (:documentation "DENDROGRAM>DOT: draws a dendrogram, as given by graph-dendrogram (distance tree-a tree-b), or a list of
dendrograms, in dot langage with the position of each point, to be drawn by neato -n2: the leaves on the left, one by
line, and each fusion at the abscissa of its distance, with a scale of the distances under the leaves.
Arguments:
<dendrogram> : the dendrogram, or a list of dendrograms (the second value of graph-dendrogram for a graph not connected).
Keywords:
 :out : NIL (by default) or T, prints out in the listener; a stream, writes into it; a string or a pathname, the
pathname of the output: a dot file, and, unless its type is dot, the image made by neato -n2 in the format of its type
(png without type).
 :width : the width of the scale, in points (700 by default)
 :step : the space between two leaves, in points (16 by default)
 :invert : t draws white on black instead of black on white (nil by default)
"))

(defmethod dendrogram>dot ((dendrogram t) &key out (width 700) (step 16) (invert nil))
  (refrains::dendrogram2dot dendrogram out :width width :step step :invert invert))
