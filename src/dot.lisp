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

;;;; dot.lisp
;;;;
;;;; graphs to dot format for drawing (with neato)

;;;; at first, to update morphologie 'draw-tree', which was representing undirected graphs from
;;;; Thanks to neato program, the job is to convert list of (node-A node-B dist) into dot format

(in-package :refrains)

(defun make-name-from-path (path)
  "The name of the file path (without directory and type), for naming the graph."
  (or (and (or (pathnamep path) (stringp path))
           (pathname-name (pathname path)))
      "span-graph"))

(defun dot-id (x)
  "x as a quoted DOT identifier: strings as they are, other objects printed without package prefix."
  (let ((s (if (stringp x) x (let ((*package* (if (symbolp x) (or (symbol-package x) *package*) *package*)))
                                (princ-to-string x)))))
    (with-output-to-string (o)
      (write-char #\" o)
      (loop for c across s
            do (when (member c '(#\" #\\)) (write-char #\\ o))
               (write-char c o))
      (write-char #\" o))))

(defun dot-shape (shape)
  "A Graphviz shape name, case kept (Mrecord, box3d...)."
  (if (stringp shape) shape (string-downcase (string shape))))

(defun 2dot (graph min dis shape1 shape2 out legend &key (name "span-graph") (overlap t) (invert nil))
  ;; invert: white on black instead of black on white (light blue for the edges of length 0)
  (let ((fg (if invert "white" "black"))
        (fg0 (if invert "lightskyblue" "blue"))
        (nid (remove-if #'(lambda (x) (zerop (third x))) graph))
        (ide (remove-if-not #'(lambda (x) (zerop (third x))) graph)))
    (format out "graph ~A {~&" (dot-id (make-name-from-path name)))
    (format out "/* generated with refrains:graph>dot, ~A */~&" (date-string t))
    ;; overlap t (default): nodes may overlap; nil: neato moves them apart (overlap=false),
    ;; a string: the value of the Graphviz overlap attribute ("scale", "prism"...)
    (unless (eq overlap t)
      (format out " graph [overlap=~A, sep=\"+4\"];~&" (dot-id (if overlap overlap "false"))))
    (when invert
      (format out " graph [bgcolor=black];~&"))
    (format out " node [shape=~A, font=Helvetica, fontsize=12, color=~A, fontcolor=~A];~&"
	    (dot-id (dot-shape shape1)) fg fg)
    (format out " edge [font=Helvetica,fontsize=10, color=~A, ~:[~;fontcolor=white, ~]labelfloat=true];~&"
            fg invert)
    (dolist (n nid)
      ;; len: the length itself (it was formatted on 3 characters first: 12.5 gave 13.)
      (format out " ~A -- ~A [w=~A, len=~,6F, label=~A];~&"
              (dot-id (car n)) (dot-id (cadr n)) dis (float (third n))
              (dot-id (if legend (third n) " "))))
    (when ide
      (format out " node [shape=~A, font=Helvetica, fontsize=12, color=~A, fontcolor=~A];~&"
	      (dot-id (dot-shape shape2)) fg0 fg0)
      (format out " edge [font=Helvetica,fontsize=10, color=~A];~&" fg0)
      (dolist (n ide)
        (format out " ~A -- ~A [len=~,6F];~&" (dot-id (car n)) (dot-id (cadr n)) (float min))))
    (format out "}~&")))

(defun graph-min-length (graph k)
  "The length drawn for edges of length 0: the shortest other length times k (k if there is none)."
  (let ((lengths (remove-if #'zerop (mapcar #'third graph))))
    (* (if lengths (reduce #'min lengths) 1) k)))

#-Lispworks
(defun graph2dot (graph dis mode shape out &optional (legend t) (overlap t) (invert nil))
  (let* ((k (if (numberp mode) mode (if mode 1 0.2)))
         (min (graph-min-length graph k))
         shape1 shape2)
    (when (not out) (setf out t))
    (if (not shape) (setf shape1 "ellipse" shape2 "ellipse")
      (if (stringp shape) (setf shape1 shape shape2 shape)
        (setf shape1 (car shape) shape2 (cadr shape))))
    (cond ((or (pathnamep out) (stringp out))
           (let ((file (pathname-name out))
                 (dir (pathname-directory out))
                 (type (pathname-type out)))
             (with-open-file (stream (make-pathname :directory dir
                                                    :name file
                                                    :type "dot")
                                     :direction :output
                                     :if-exists :supersede
                                     :if-does-not-exist :create)
               (2dot graph min dis shape1 shape2 stream legend :name out :overlap overlap :invert invert))
             (when (not (equalp type "dot"))
               ;; the type of the file is the output format of neato (svg, pdf, png, gif...)
               (let ((fmt (string-downcase (or type "png")))
                     (dot (namestring (make-pathname :directory dir :name file :type "dot"))))
                 (handler-case
                     (shell-command (list "neato"
                                          (format nil "-T~A" fmt)
                                          "-o" (namestring (make-pathname :directory dir
                                                                          :name file
                                                                          :type fmt))
                                          dot)
                                    ;; neato's messages to the terminal of the Lisp
                                    ;; (:error-output t is not supported by ECL)
                                    :error-output :interactive)
                   (error (c)
                     (error "graph>dot: the dot file ~A is written, but neato (Graphviz) could not make the ~A file: ~A"
                            dot fmt c)))))))
          (t (2dot graph min dis shape1 shape2 out legend :name out :overlap overlap :invert invert))))
  (format nil "~G" out))

#+Lispworks
(defun graph2dot (graph dis mode shape out &optional (legend t) (overlap t) (invert nil))
  (let* ((k (if (numberp mode) mode (if mode 1 0.2)))
         (min (graph-min-length graph k))
         shape1 shape2
         (neato "/usr/local/bin/neato"))
    (when (not out) (setf out t))
    (if (not shape) (setf shape1 "ellipse" shape2 "ellipse")
      (if (stringp shape) (setf shape1 shape shape2 shape)
        (setf shape1 (car shape) shape2 (cadr shape))))
    (cond ((or (pathnamep out) (stringp out))
           (let* ((file (pathname-name out))
                  (dir (pathname-directory out))
                  (type (pathname-type out))
                  (dot (make-pathname :directory dir
                                      :name file
                                      :type "dot")))
             (with-open-file (stream dot
                                     :direction :output
                                     :if-exists :supersede
                                     :if-does-not-exist :create)
               (2dot graph min dis shape1 shape2 stream legend :name out :overlap overlap :invert invert))
             (when (not (equalp type "dot"))
               (system::run-shell-command
                (list neato (format nil "-T~(~S~)" (if type (safe-read-from-string type) (safe-read-from-string "gif"))))
                :input dot
                :output (namestring (make-pathname :directory dir
                                           :name file
                                           :type (if type type "gif")))
                :wait t 
                :if-input-does-not-exist :error
                :if-output-exists :supersede
                ))))
          (t (2dot graph min dis shape1 shape2 out legend :name out :overlap overlap :invert invert)))
    (format nil "~G" out)))

;(graph2dot '((a b 1) (a c 2) (a d 3) (b k 8) (b j 0)) 0 .1 nil t)
;(graph2dot '((8 10 0) (1 8 1.5) (7 9 0) (7 11 1) (1 4 0) (1 11 1) (2 11 2) (2 6 0) (2 5 0) (2 3 0) (0 2 1)) 0 1 nil t)
;(graph2dot '((8 10 0) (1 8 1.5) (7 9 0) (7 11 1) (1 4 0) (1 11 1) (2 11 2) (2 6 0) (2 5 0) (2 3 0) (0 2 1)) 0 nil nil t)
;(graph2dot '((8 10 0) (1 8 1.5) (7 9 0) (7 11 1) (1 4 0) (1 11 1) (2 11 2) (2 6 0) (2 5 0) (2 3 0) (0 2 1)) 0 nil "ellipse" t)
;(graph2dot '((8 10 0) (1 8 1.5) (7 9 0) (7 11 1) (1 4 0) (1 11 1) (2 11 2) (2 6 0) (2 5 0) (2 3 0) (0 2 1)) 0 .25 "plaintext" t)
;(graph2dot '((8 10 0) (1 8 1.5) (7 9 0) (7 11 1) (1 4 0) (1 11 1) (2 11 2) (2 6 0) (2 5 0) (2 3 0) (0 2 1)) 0 1 '("point" "plaintext") t)
;(graph2dot '((8 10 0) (1 8 1.5) (7 9 0) (7 11 1) (1 4 0) (1 11 1) (2 11 2) (2 6 0) (2 5 0) (2 3 0) (0 2 1)) 0 1 "plaintext" "/Users/fred/g.gif")

(defgeneric graphtodot (graph dis min out &key shape legend)
  (:documentation "Converts a graph (list of edges) into an undirected graph into dot langage to be processed using neato program.
Arguments are:
graph : the graph
dis : amount of distortion allowed for distances fir drawing the graph (from 0.0 for minimum distorsion to 1.0 maximum distorsion)
min : scaling factor for the mininum distance
shape : string or list of strings to define node's shape, using 'neato' definitions
out :
if NIL or T, print out in listener;
if a string, it defines the pathname of the output. Type of file define output.
"))

(defmethod graphtodot  ((graph list) (dis null) (min null) (out t) &key shape legend)
  (graph2dot graph 0 nil shape out legend))

(defmethod graphtodot  ((graph list) (dis number) (min symbol)  (out t) &key shape legend)
  (graph2dot graph dis T shape out legend))

(defmethod graphtodot  ((graph list) (dis number) (min number)  (out t) &key shape legend)
  (graph2dot graph dis min shape out legend))

;;; dendrograms to dot format, drawn by neato at fixed positions (neato -n2)

(defun dendrogram-leaves (dendrogram)
  "The leaves of a dendrogram (distance tree-a tree-b), from the first one to the last one."
  (if (and (consp dendrogram) (realp (first dendrogram)))
      (append (dendrogram-leaves (second dendrogram)) (dendrogram-leaves (third dendrogram)))
      (list dendrogram)))

(defun dendrogram-height (dendrogram)
  (if (and (consp dendrogram) (realp (first dendrogram))) (first dendrogram) 0))

(defun nice-step (max)
  "A step of 1, 2 or 5 times a power of 10, for about four graduations from 0 to max."
  (if (not (plusp max))
      1
      (let* ((raw (/ max 4))
             (mag (expt 10 (floor (log raw 10))))
             (norm (/ raw mag)))
        (* mag (cond ((<= norm 1) 1) ((<= norm 2) 2) ((<= norm 5) 5) (t 10))))))

(defun scale-label (x)
  "x printed without useless zeros: 0.5, 2, 0.25."
  (let ((s (string-right-trim "." (string-right-trim "0" (format nil "~,4F" x)))))
    (if (string= s "") "0" s)))

(defun 2dot-dendrogram (forest out &key (width 700) (step 16) (invert nil) (name "dendrogram"))
  "Writes the dendrograms of forest into the stream out, in dot, with the position of each point:
the leaves on the left, one by line, each fusion at the abscissa of its distance."
  (let* ((fg (if invert "white" "black"))
         (leaves (loop for d in forest append (dendrogram-leaves d)))
         (names (mapcar #'(lambda (x) (if (stringp x) x (princ-to-string x))) leaves))
         (x0 (+ 12 (* 6.6 (reduce #'max (mapcar #'length names) :initial-value 1)))) ; Courier 11
         (scale-step (nice-step (reduce #'max (mapcar #'dendrogram-height forest) :initial-value 0)))
         (end (* scale-step (max 1 (ceiling (reduce #'max (mapcar #'dendrogram-height forest)
                                                    :initial-value 0)
                                            scale-step))))
         (unit (/ width end))
         (row 0)
         (n 0))
    (labels ((x (d) (+ x0 (* unit d)))
             (point (x y)
               (format out " p~D [pos=\"~,1F,~,1F\"];~&" (incf n) x y)
               (format nil "p~D" n))
             (draw (tree)
               ;; the point from which the line goes to the parent, and its ordinate
               (if (and (consp tree) (realp (first tree)))
                   (destructuring-bind (d a b) tree
                     (destructuring-bind ((pa ya) (pb yb)) (list (draw a) (draw b))
                       (let* ((y (/ (+ ya yb) 2))
                              (ca (point (x d) ya))
                              (cb (point (x d) yb))
                              (m (point (x d) y)))
                         (format out " ~A -- ~A;~& ~A -- ~A;~& ~A -- ~A;~& ~A -- ~A;~&"
                                 pa ca pb cb ca m m cb)
                         (list m y))))
                   (let* ((label (nth row names))
                          (y (* step (- (length leaves) 1 row))))
                     (incf row)
                     (format out " l~D [shape=plaintext, label=~A, pos=\"~,1F,~,1F\"];~&"
                             row (dot-id label) (- x0 6 (* 3.3 (length label))) y)
                     (list (point x0 y) y)))))
      (format out "graph ~A {~&" (dot-id (make-name-from-path name)))
      (format out "/* generated with refrains:dendrogram>dot, ~A, to be drawn with neato -n2 */~&"
              (date-string t))
      (format out " graph [splines=false~:[~;, bgcolor=black~]];~&" invert)
      (format out " node [shape=point, width=0, color=~A, fontcolor=~A, fontname=Courier, fontsize=11];~&" fg fg)
      (format out " edge [color=~A];~&" fg)
      (dolist (d forest) (draw d))
      ;; the scale of the distances, under the leaves
      (let ((y (- (* 1.5 step)))
            (ticks nil))
        (loop for k from 0 to (round end scale-step)
              for d = (* k scale-step)
              do (let ((tick (point (x d) y)))
                   (format out " ~A -- ~A;~& s~D [shape=plaintext, label=~A, pos=\"~,1F,~,1F\"];~&"
                           tick (point (x d) (- y 5)) k (dot-id (scale-label d)) (x d) (- y 16))
                   (push tick ticks)))
        (format out " ~{~A~^ -- ~};~&" (nreverse ticks)))
      (format out "}~&"))))

(defun dendrogram2dot (dendrogram out &key (width 700) (step 16) (invert nil))
  (let ((forest (if (and (consp dendrogram) (realp (first dendrogram))) (list dendrogram) dendrogram)))
    (when (not out) (setf out t))
    (cond ((or (pathnamep out) (stringp out))
           (let* ((type (pathname-type out))
                  (dot (namestring (make-pathname :type "dot" :defaults (pathname out)))))
             (with-open-file (stream dot :direction :output :if-exists :supersede :if-does-not-exist :create)
               (2dot-dendrogram forest stream :width width :step step :invert invert :name out))
             (when (not (equalp type "dot"))
               ;; the type of the file is the output format of neato (svg, pdf, png, gif...)
               (let* ((fmt (string-downcase (or type "png")))
                      (image (namestring (make-pathname :type fmt :defaults (pathname out)))))
                 (handler-case
                     #-Lispworks
                     (shell-command (list "neato" "-n2" (format nil "-T~A" fmt) "-o" image dot)
                                    :error-output :interactive)
                     #+Lispworks
                     (shell-command (format nil "/usr/local/bin/neato -n2 -T~A -o ~S ~S" fmt image dot))
                   (error (c)
                     (error "dendrogram>dot: the dot file ~A is written, but neato (Graphviz) could not make the ~A file: ~A"
                            dot fmt c)))))))
          (t (2dot-dendrogram forest out :width width :step step :invert invert)))
    (format nil "~G" out)))
