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

;;;; io.lisp
;;;;
;;;; to import data from files or export to files

(in-package :refrains)

;;; FILE SYSTEM

;(defconstant whitechars '#(#\Space #\Tab #\Return #\Newline))

(defun file-list (dir &optional extension)
  "attention: extension en  minuscules !"
  (when (not (equalp "/" (elt dir (1- (length dir)))))
    (setf dir (concatenate 'string dir "/")))
  (let ((d (directory (if extension
			  (concatenate 'string (directory-namestring dir) "*."
				       (if (stringp extension) extension (format nil "~(~@S~)" extension)))
			  (concatenate 'string (directory-namestring dir) "*.*")))))
    (mapcar #'namestring d)))

; (print  (file-list "/home/fred/lisp/midi/"))
; (print (file-list "/home/fred/lisp/midi" 'lisp))

(defun file-list-rec (paths &optional files)
  (if (null paths)
      files
    (multiple-value-bind (newfiles newpaths)
	(file-list (pop paths))
      (file-list-rec
       (append newpaths paths)
       (append newfiles files) ))))

; (print (file-list-rec '("/home/fred/lisp/")))

(defun read-text-lines (file)
  "The lines of the text file, as strings."
  ;; read-line until the end of the file: file-position counts bytes, not characters
  (with-open-file (in-stream file
			     :direction :input
                             :element-type 'character)
    (loop for line = (read-line in-stream nil nil)
          while line
          collect line)))

(defun slurp-stream (stream)
  "The whole contents of the character stream, as a string."
;src: www.ymeme.com/slurping-a-file-common-lisp-83.html
;www.emmett.ca/~sabetts/slurp.html
  ;; file-length counts bytes: with multi-byte characters (UTF-8), fewer characters are
  ;; read, and only these are kept
  (let* ((l (file-length stream))
         (seq (make-string l)))
    (subseq seq 0 (read-sequence seq stream :end l))))

(defun slurp-file (file)
  (with-open-file (in file :direction :input)
    (slurp-stream in)))
 
(defun read-txt-file (file &key (mode t) (marks nil) (rem-test nil))
  "Reads the text file: mode t, each line as a list; nil, one flat list of strings; :charcode, the
segments of the file as lists of character codes. marks are the separators, besides blanks (spaces,
tabulations, newlines and other characters of code up to 32): a string, a list of characters or codes,
t for the usual punctuation marks, or, with :charcode, (:ignore c ...) for all the characters which are
not letters or digits, but c ..."
  (if (not file) nil
    (progn
      (when (not rem-test) (setf rem-test #'(lambda (x) (declare (ignore x)) nil)))
      (when (eq 'T marks) (setf marks " ,;:?./@&\"'(!)-_#*+=<>{}[]$`%^"))
      (unless (member mode '(t nil :charcode))
        (error "read-text: unknown mode ~S, use t (lines), nil (flat) or :charcode." mode))
      (if mode
          (case mode
            (:charcode
             (flet ((blankp (c) (<= c 32))
                    (letterp (c) (alphanumericp (code-char c))))
               (remove-if rem-test
                          (split-list-using-marks
                           (string2code (slurp-file file))
                           (cond ((stringp marks)
                                  (let ((codes (string2code marks)))
                                    #'(lambda (c) (or (blankp c) (member c codes)))))
                                 ((and (listp marks) (eql :ignore (car marks)))
                                  (let ((kept (all2char-code (cdr marks))))
                                    #'(lambda (c) (not (or (letterp c) (member c kept))))))
                                 ((listp marks)
                                  (let ((codes (all2char-code marks)))
                                    #'(lambda (c) (or (blankp c) (member c codes)))))
                                 (t (error "read-text: :sep must be a string or a list, not ~S." marks)))))))
	    ;; rem-test on the words of each line too (it was ignored in this mode)
	    (t (mapcar #'(lambda (x) (remove-if rem-test (string2sym (split-string x marks))))
		       (remove-if #'(lambda (x) (zerop (length x)))
				  (read-text-lines file)))))
	  (let ((st (slurp-file file)))
       	;(split-string st marks)
        ;(mapcar #'read-from-string
	    (remove-if rem-test (split-string st marks)) )))))

#|
(read-from-string (code2string (string2code "aiuo")))
(mapcar #'code2string
        (split-list-using-marks
         (subseq
         (string2code
          (slurp-file "~/txt/Deleuze/DR_314-315.txt")
          )
         3680 3706)
         (string2code "\\ ,?!.;:+=\"'(@)\^\&")
         )
        )

(char-code #\) ;195
(code-char 233)
|#

;;----------------
;; OUTPUT

(defun 2flatstring (liste s)
  (if (not liste) s
   (let ((k (pop liste)))
      (if (atom k)
          (2flatstring liste (if (zerop (length s))
                                (if (or (pathnamep k) (stringp k))
                                    (format nil "~G" k)
                                  (format nil "~S" k))
                                (funcall #'concat (list s " " (if (or (pathnamep k) (stringp k))
                                                                  (format nil "~G" k)
                                                                (format nil "~S" k))))))
        (2flatstring (append k liste) s)))))

(defun list-write (liste file mode)
  "Writes a list to a file."
  (with-open-file (out-stream (if file file "liste")
                              :direction :output
                              :element-type 'character
                              :if-exists :supersede
                              :if-does-not-exist :create)
    (case mode
      (:coll (coll-entries liste out-stream))
      (:lisp
       (format out-stream "(~&")
       (dolist (l liste (format out-stream "~&)"))
         (format out-stream "~&~S" l)))
      (t (dolist (l liste (format out-stream "~&"))
           (if (atom l)
               (if (or (pathnamep l) (stringp l))
                   (format out-stream "~&~G" l)
                 (format out-stream "~&~S" l))
             (format out-stream "~&~G" (2flatstring l "")))))))
  (format nil "~&~G" file))


;;; read/write Max/MSP coll format

(defun coll-atom (x)
  "x as a Max coll item: integers as they are, other numbers as decimals, symbols by name in lower
case (Max symbols are case-sensitive), unless the name has lower-case letters (|Ab| stays Ab), and
quoted if they contain spaces, commas or semicolons; strings quoted, as they are."
  (flet ((quoted (str) (with-output-to-string (o)
                         (write-char #\" o)
                         (loop for c across str
                               do (when (member c '(#\" #\\)) (write-char #\\ o))
                                  (write-char c o))
                         (write-char #\" o))))
    (cond ((integerp x) (format nil "~D" x))
          ((realp x) (let ((*read-default-float-format* 'double-float))
                       (format nil "~F" (if (floatp x) x (float x)))))
          ((stringp x) (quoted x))
          ((symbolp x) (let ((name (let ((n (symbol-name x)))
                                     (if (string= n (string-upcase n)) (string-downcase n) n))))
                         (if (find-if #'(lambda (c) (member c '(#\Space #\Tab #\, #\; #\"))) name)
                             (quoted name)
                             name)))
          (t (quoted (princ-to-string x))))))

(defun coll-entries (liste stream)
  "Writes liste to stream as the entries of a Max coll: one line index, data; for each element,
from index 0; an element which is a list is flattened."
  (loop for e in liste
        for i from 0
        do (format stream "~D,~{ ~A~};~%" i
                   (mapcar #'coll-atom (if (listp e) (flat e) (list e))))))

(defun coll-write (liste file)
  "Writes a list to a Max coll file."
  (with-open-file (out-stream (if file file "coll")
                              :direction :output
                              :element-type 'character
                              :if-exists :supersede
                              :if-does-not-exist :create)
    (coll-entries liste out-stream))
  (format nil "~&~G" file))

;;; PLOT : a sequence of events drawn with characters, for the listener or a terminal, or in SVG

(defun plot-number (x)
  "X written without useless decimals: an integer as such, otherwise with at most 3 decimals."
  (if (integerp x)
      (format nil "~D" x)
      (let ((s (string-right-trim "0" (format nil "~,3F" x))))
        (string-right-trim "." s))))

(defun plot-sequence (seq)
  "SEQ as a list of events (time value0 value1 ...): a list of events as it is, or a list of numbers, a flow
of one value, as events (rank number), a NIL being a missing value, kept as NIL to break the line in SVG."
  (if (and seq (every (lambda (x) (or (null x) (realp x))) seq))
      (loop for y in seq for i from 0 collect (when y (list i y)))
      seq))

(defun plot-window (events dimension start duration low high)
  "The events of EVENTS between the time START (the first event by default) and START + DURATION (the
last event by default). Returns the events, their values (nth DIMENSION (cdr event)), the bottom and
the top of the plot (LOW and HIGH, by default the minimum and the maximum of the values), and the times
of the beginning and of the end of the window. The NILs of EVENTS, missing values, are left out."
  (setf events (remove nil events))
  (when (null events)
    (error "seq>plot: there is no event to draw."))
  (dolist (e events)
    (unless (and (consp e) (realp (car e)) (realp (nth dimension (cdr e))))
      (error "seq>plot: ~S is not an event (time value ...) with a number as value ~D." e dimension)))
  (let* ((start (or start (car (first events))))
         (end (if duration (+ start duration) (car (car (last events)))))
         (window (remove-if-not (lambda (e) (<= start (car e) end)) events)))
    (when (null window)
      (error "seq>plot: no event between the times ~S and ~S." start end))
    (dolist (y (list low high))
      (unless (or (null y) (realp y))
        (error "seq>plot: the bound ~S is not a number." y)))
    (let* ((ys (mapcar (lambda (e) (nth dimension (cdr e))) window))
           (lo (or low (reduce #'min ys)))
           (hi (or high (reduce #'max ys))))
      (when (> lo hi)
        (error "seq>plot: the bottom ~S is above the top ~S." lo hi))
      (values window ys lo hi start end))))

(defun plot-chars (events &key (dimension 0) start duration low high (width 72) (height 16) (labels t)
                               (stream *standard-output*))
  "Draws EVENTS, a list of events (time value0 value1 ...) sorted by time, with characters on STREAM:
the time in x, proportionally (empty columns where there is no event), and (nth DIMENSION (cdr event))
in y, between its maximum (above) and its minimum (below), on WIDTH columns and HEIGHT rows. Each
column marks all the events of its time span, so that no extremum is lost. LOW and HIGH zoom in y: the
values outside them are not drawn. With LABELS, the bottom, the top and the times of the window are
written."
  (multiple-value-bind (window ys lo hi start end) (plot-window events dimension start duration low high)
    (let ((span (if (= hi lo) 1 (- hi lo)))
          (time-span (if (= end start) 1 (- end start)))
          (grid (make-array (list height width) :initial-element #\Space)))
      (loop for e in window for y in ys
            when (<= lo y hi)
            do (let ((col (min (1- width) (floor (* width (- (car e) start)) time-span)))
                     (row (round (* (1- height) (/ (- y lo) span)))))
                 (setf (aref grid (- height 1 row) col) #\*)))
      (fresh-line stream)
      (when labels (format stream "~A~%" (plot-number hi)))
      (dotimes (r height)
        (dotimes (c width) (write-char (aref grid r c) stream))
        (terpri stream))
      (when labels
        (format stream "~A~%" (plot-number lo))
        ;; the times of the beginning and of the end of the window, under the plot
        (let ((left (plot-number start)) (right (plot-number end)))
          (format stream "~A~V@A~%" left (max (1+ (length right)) (- width (length left))) right)))
      (values))))

(defun plot-svg (events file &key (dimension 0) start duration low high (width 720) (height 240)
                                  (labels t) (mode :line))
  "Draws EVENTS as plot-chars, in an SVG image of WIDTH x HEIGHT pixels written to FILE (of type svg
when it has no type): with MODE :line, a line joining the events, with :points, a point by event. With
LABELS, the bottom, the top and the times of the window are written. Returns the name of the file."
  (unless (member mode '(:line :points))
    (error "seq>plot: the mode ~S is neither :line nor :points." mode))
  (multiple-value-bind (window ys lo hi start end) (plot-window events dimension start duration low high)
    (declare (ignore ys))
    (let* ((file (if (pathname-type file) (pathname file) (make-pathname :type "svg" :defaults file)))
           (font 12)
           (left (if labels (+ 8 (* 0.6 font (max (length (plot-number hi)) (length (plot-number lo))))) 4))
           (top 4)
           (right (- width 4))
           (bottom (- height (if labels (+ font 8) 4)))
           (span (if (= hi lo) 1 (- hi lo)))
           (time-span (if (= end start) 1 (- end start)))
           (point (lambda (e)
                    (list (+ left (* (- right left) (/ (- (car e) start) time-span)))
                          (- bottom (* (- bottom top) (/ (- (nth dimension (cdr e)) lo) span))))))
           (points (mapcar point window))
           ;; the line is broken at the missing values (NIL) of EVENTS
           (lines (let ((lines nil) (line nil))
                    (dolist (e (append events (list nil)) (nreverse lines))
                      (cond ((null e) (when line (push (nreverse line) lines)) (setf line nil))
                            ((<= start (car e) end) (push (funcall point e) line)))))))
      (with-open-file (svg file :direction :output :if-exists :supersede :if-does-not-exist :create)
        (format svg "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"~D\" height=\"~D\" viewBox=\"0 0 ~D ~D\">~%"
                width height width height)
        (format svg "<!-- generated with refrains:seq>plot, ~A -->~%" (date-string t))
        (format svg "<rect width=\"~D\" height=\"~D\" fill=\"white\"/>~%" width height)
        (format svg "<rect x=\"~,1F\" y=\"~,1F\" width=\"~,1F\" height=\"~,1F\" fill=\"none\" stroke=\"#bbbbbb\"/>~%"
                left top (- right left) (- bottom top))
        ;; what is outside the plot (values outside LOW and HIGH) is not drawn
        (format svg "<clipPath id=\"plot\"><rect x=\"~,1F\" y=\"~,1F\" width=\"~,1F\" height=\"~,1F\"/></clipPath>~%"
                left top (- right left) (- bottom top))
        (ecase mode
          (:line (dolist (line lines)
                   (format svg "<polyline clip-path=\"url(#plot)\" fill=\"none\" stroke=\"black\" stroke-width=\"1\" points=\"~{~{~,1F,~,1F~}~^ ~}\"/>~%"
                           line)))
          (:points (format svg "<g fill=\"black\" clip-path=\"url(#plot)\">~%~{~{<circle cx=\"~,1F\" cy=\"~,1F\" r=\"1.5\"/>~}~%~}</g>~%"
                           points)))
        (when labels
          (format svg "<g font-family=\"monospace\" font-size=\"~D\" fill=\"black\">~%" font)
          ;; the maximum and the minimum on the left, the times of the window under the plot
          (format svg "<text x=\"~,1F\" y=\"~,1F\" text-anchor=\"end\">~A</text>~%" (- left 4) (+ top font -2) (plot-number hi))
          (format svg "<text x=\"~,1F\" y=\"~,1F\" text-anchor=\"end\">~A</text>~%" (- left 4) bottom (plot-number lo))
          (format svg "<text x=\"~,1F\" y=\"~,1F\">~A</text>~%" left (+ bottom font 4) (plot-number start))
          (format svg "<text x=\"~,1F\" y=\"~,1F\" text-anchor=\"end\">~A</text>~%" right (+ bottom font 4) (plot-number end))
          (format svg "</g>~%"))
        (format svg "</svg>~%"))
      (namestring file))))

;;; ABC : a sequence of notes written in the ABC music notation

(defun abc-pitch (midi)
  "The MIDI note MIDI as a letter and an octave mark in ABC (60, middle C, is C), with :sharp or nil."
  (multiple-value-bind (octave class) (floor midi 12)
    (let* ((names #("C" "C" "D" "D" "E" "F" "F" "G" "G" "A" "A" "B"))
           (sharp (member class '(1 3 6 8 10)))
           (octave (- octave 1))      ; 60 is in the octave 4
           (letter (aref names class)))
      (values (if (>= octave 5)
                  (concatenate 'string (string-downcase letter) (make-string (- octave 5) :initial-element #\'))
                  (concatenate 'string letter (make-string (- 4 octave) :initial-element #\,)))
              (and sharp :sharp)))))

(defun abc-notes (seq &key rhythm (unit 1))
  "The notes of SEQ (MIDI notes, lists of MIDI notes for chords, NIL a rest) in ABC: consecutive equal
notes or chords (rounded to the semitone) make one, with a length of their number of positions divided
by UNIT when RHYTHM. The accidentals are written where needed, as they last until the end of the bar
(here, of the tune)."
  (let ((runs nil) (sharps (make-hash-table :test #'equal)))
    (flet ((note (n)
             (multiple-value-bind (name sharp) (abc-pitch n)
               (cond (sharp (setf (gethash name sharps) t)
                            (concatenate 'string "^" name))
                     ((gethash name sharps) (remhash name sharps)
                      (concatenate 'string "=" name))
                     (t name)))))
      (dolist (x seq)
        (unless (or (null x) (realp x) (and (consp x) (every #'realp x)))
          (error "seq>abc: ~S is neither a note (a number), nor a chord (a list of numbers), nor a rest (NIL)." x))
        ;; a chord: its notes rounded, sorted, once each; a chord of one note is that note
        (let ((n (cond ((realp x) (round x))
                       ((consp x) (let ((c (sort (remove-duplicates (mapcar #'round x)) #'<)))
                                    (if (rest c) c (first c)))))))
          (if (and runs (equal n (car (first runs))))
              (incf (cdr (first runs)))
              (push (cons n 1) runs))))
      (loop for (n . count) in (nreverse runs)
            collect (let ((length (if rhythm (max 1 (round count unit)) 1)))
                      (concatenate 'string
                                   (cond ((null n) "z")
                                         ((consp n) (format nil "[~{~A~}]" (mapcar #'note n)))
                                         (t (note n)))
                                   (if (= length 1) "" (princ-to-string length))))))))

(defun abc-text (seq &key title rhythm (unit 1) (per-line 16))
  "SEQ as an ABC tune: header, then the notes, PER-LINE by line."
  (with-output-to-string (s)
    (format s "X:1~%T:~A~%M:none~%L:~A~%K:C~%" (or title "refrains") (if rhythm "1/16" "1/4"))
    (loop for notes on (abc-notes seq :rhythm rhythm :unit unit) by (lambda (l) (nthcdr per-line l))
          do (format s "~{~A~^ ~}~%" (subseq notes 0 (min per-line (length notes)))))))

;;; LILYPOND : a sequence of notes written for LilyPond, to the quarter tone

(defun ly-pitch (midi)
  "The MIDI note MIDI (rounded to the quarter tone) in LilyPond (Dutch names, absolute octaves, 60 being
c'), a quarter tone higher written ih: 74.5 is dih''."
  (let* ((q (/ (round (* 2 midi)) 2))
         (semitone (floor q))
         (quarter (/= q semitone)))
    (multiple-value-bind (octave class) (floor semitone 12)
      (concatenate 'string
                   (aref #("c" "cis" "d" "dis" "e" "f" "fis" "g" "gis" "a" "ais" "b") class)
                   (if quarter "ih" "")
                   (let ((marks (- octave 4)))   ; 48 is c, 60 c'
                     (if (minusp marks)
                         (make-string (- marks) :initial-element #\,)
                         (make-string marks :initial-element #\')))))))

(defun ly-lengths (sixteenths)
  "SIXTEENTHS as a list of LilyPond lengths (1 2 4 8 16), the longest first, to be tied."
  (loop for (value length) in '((16 1) (8 2) (4 4) (2 8) (1 16))
        nconc (loop repeat (floor sixteenths value) collect length)
        do (setf sixteenths (mod sixteenths value))))

(defun ly-notes (seq &key rhythm (unit 1))
  "The notes of SEQ (MIDI notes, lists of MIDI notes for chords, NIL a rest) in LilyPond: consecutive equal
notes or chords (rounded to the quarter tone) make one, of a length of their number of positions divided by
UNIT, in sixteenths, when RHYTHM (else a quarter, the stems hidden)."
  (let ((runs nil))
    (dolist (x seq)
      (unless (or (null x) (realp x) (and (consp x) (every #'realp x)))
        (error "seq>ly: ~S is neither a note (a number), nor a chord (a list of numbers), nor a rest (NIL)." x))
      (let ((n (cond ((realp x) (/ (round (* 2 x)) 2))
                     ((consp x) (let ((c (sort (remove-duplicates (mapcar (lambda (y) (/ (round (* 2 y)) 2)) x)) #'<)))
                                  (if (rest c) c (first c)))))))
        (if (and runs (equal n (car (first runs))))
            (incf (cdr (first runs)))
            (push (cons n 1) runs))))
    (loop for (n . count) in (nreverse runs)
          collect (let ((name (cond ((null n) "r")
                                    ((consp n) (format nil "<~{~A~^ ~}>" (mapcar #'ly-pitch n)))
                                    (t (ly-pitch n))))
                        (lengths (if rhythm (ly-lengths (max 1 (round count unit))) (list 4))))
                    ;; a note longer than one value: tied values; a rest: values one after the other
                    (format nil (if n "~{~A~^~~ ~}" "~{~A~^ ~}")
                            (mapcar (lambda (l) (format nil "~A~D" name l)) lengths))))))

(defun ly-text (seq &key title rhythm (unit 1) (per-line 8))
  "SEQ as a LilyPond score, without meter nor bar (cadenza), an accidental on each note, a possible line
break every PER-LINE notes."
  (with-output-to-string (s)
    (format s "\\version \"2.24.0\"~%\\header { title = \"~A\" tagline = ##f }~%" (or title "refrains"))
    (format s "\\score {~%  {~%    \\cadenzaOn~%~:[    \\omit Stem~%~;~]" rhythm)
    (loop for notes on (ly-notes seq :rhythm rhythm :unit unit) by (lambda (l) (nthcdr per-line l))
          do (format s "    ~{~A~^ ~} \\bar \"\"~%" (subseq notes 0 (min per-line (length notes)))))
    ;; an accidental on each note (there is no bar to end it), and no time signature
    (format s "  }~%  \\layout { \\context { \\Staff \\accidentalStyle forget \\omit TimeSignature } }~%}~%")))

;;; eof
