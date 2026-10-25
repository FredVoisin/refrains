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

(def-suite io :in refrains
  :description "4. Read and write files.")
(in-suite io)

(test write-list/read-text
  (uiop:with-temporary-file (:pathname file :type "txt")
    (write-list '((a b c) (1 2 3)) (namestring file))
    (is (equal '((a b c) (1 2 3)) (read-text (namestring file))))
    (is (equal '("A" "B" "C" "1" "2" "3") (read-text (namestring file) :mode nil)))))

(test dates
  (is (stringp (date-string)))
  (is (stringp (date-string t)))
  (let ((u (encode-universal-time 5 4 12 15 1 2000)))
    (is (equal "15 Jan 2000" (date-string nil u)))
    ;; date+time-string is date-string with time
    (is (equal "15 Jan 2000 12:04:05" (date-string t u)))))

(test date-string-months
  ;; MONTHS used to be undefined
  (is (search "Jan" (date-string t (encode-universal-time 0 0 12 15 1 2000)))))

(test slurp-file-multibyte
  ;; file-length counts bytes: a UTF-8 file gave one NUL (SBCL) or space (ECL)
  ;; per extra byte at the end of the string
  (uiop:with-temporary-file (:pathname file :type "txt")
    (with-open-file (out file :direction :output :if-exists :supersede :external-format :utf-8)
      (format out "~a~%~a" (coerce (list (code-char 233) #\t (code-char 233)) 'string) "abc"))
    (let ((s (refrains::slurp-file file))
          (lines (refrains::read-text-lines file)))
      (is (equal 2 (length lines)))
      (is (= (length s) (+ (reduce #'+ (mapcar #'length lines)) (1- (length lines)))))
      (is (notany #'(lambda (c) (member (char-code c) '(0))) s))
      (is (char= #\c (char s (1- (length s)))))))
  ;; an empty file
  (uiop:with-temporary-file (:pathname file :type "txt")
    (is (equal "" (refrains::slurp-file file)))
    (is (null (refrains::read-text-lines file)))))

(test read-text-charcode
  (flet ((write-file (file text)
           (with-open-file (out file :direction :output :if-exists :supersede :external-format :utf-8)
             (write-string text out))))
    (uiop:with-temporary-file (:pathname file :type "txt")
      (write-file file (format nil "ab-cd~cef~%gh!ij~%" #\Tab))
      ;; newlines and tabulations separate the segments (they stayed inside them)
      (is (equal '((97 98 45 99 100) (101 102) (103 104 33 105 106))
                 (read-text file :mode :charcode)))
      (is (equal '((97 98) (99 100) (101 102) (103 104) (105 106))
                 (read-text file :mode :charcode :sep "-!")))
      (is (equal (read-text file :mode :charcode :sep "-!")
                 (read-text file :mode :charcode :sep (list #\- #\!))))
      (is (equal '((97 98 45 99 100) (101 102) (103 104) (105 106))
                 (read-text file :mode :charcode :sep (list :ignore #\-))))
      ;; the old modes, and any unknown mode, are errors (:ascii-7b gave the lines)
      (signals error (read-text file :mode :ascii-7b))
      (signals error (read-text file :mode :foo)))
    (uiop:with-temporary-file (:pathname file :type "txt")
      ;; accented letters are letters (they were separators without 8 bits)
      (write-file file (format nil "~a,~%~a~%"
                               (coerce (list (code-char 233) #\t (code-char 233)) 'string)
                               (coerce (list (code-char 231) #\a) 'string)))
      (is (equal '((233 116 233) (231 97)) (read-text file :mode :charcode :sep ",")))
      (is (equal '((233 116 233) (231 97)) (read-text file :mode :charcode :sep (list :ignore)))))))

(test write-list-coll
  ;; :coll wrote the default format, not a Max coll file (coll-write was never called)
  (uiop:with-temporary-file (:pathname file :type "txt")
    (write-list (list '(60 62 64) 72 '(a b c) '(1/3 2.5) '("hello world" x) '((1 2) (3 (4)))
                      '(|Ab| "Cd" |e f|))
                (namestring file) :coll)
    ;; symbols in lower case for Max, unless typed with lower-case letters; strings as they are
    (is (equal '("0, 60 62 64;" "1, 72;" "2, a b c;" "3, 0.33333334 2.5;"
                 "4, \"hello world\" x;" "5, 1 2 3 4;" "6, Ab \"Cd\" \"e f\";")
               (uiop:read-file-lines file))))
  ;; the default mode is unchanged
  (uiop:with-temporary-file (:pathname file :type "txt")
    (write-list '((a b c) (1 2 3)) (namestring file))
    (is (equal '("A B C" "1 2 3") (uiop:read-file-lines file)))))

(test read-text-rem-test-lines
  (uiop:with-temporary-file (:pathname file :type "txt")
    (with-open-file (out file :direction :output :if-exists :supersede)
      (format out "the cat sat~%on a mat~%it is~%"))
    ;; rem-test was ignored in lines mode (the default)
    (is (equal '((the cat sat) (mat) ())
               (read-text file :rem-test #'(lambda (w) (< (length (string w)) 3)))))
    (is (equal '("the" "cat" "sat" "mat")
               (read-text file :mode nil :rem-test #'(lambda (w) (< (length w) 3)))))
    ;; without rem-test, unchanged
    (is (equal '((the cat sat) (on a mat) (it is)) (read-text file)))))

(test read-without-eval
  ;; read-from-string evaluated #. : a word #.(...) of a text file ran its code (read-text, lines mode)
  (let ((ran nil))
    (declare (special ran))
    (setf (symbol-function 'read-without-eval-marker) #'(lambda () (setf ran t) 'injected))
    (uiop:with-temporary-file (:pathname file :type "txt")
      (with-open-file (out file :direction :output :if-exists :supersede)
        (format out "hello #.(refrains/tests::read-without-eval-marker) world~%a ) # (~%3 4.5 abc~%"))
      (let ((r (read-text file)))
        (is (not ran))
        ;; unreadable words are kept as strings
        (is (equal '(hello "#.(refrains/tests::read-without-eval-marker)" world) (first r)))
        (is (equal '(a ")" "#" "(") (second r)))
        (is (equal '(3 4.5 abc) (third r))))))
  (signals reader-error (refrains::safe-read-from-string "#.(+ 1 2)"))
  (is (= 3 (refrains::safe-read-from-string "3"))))

(test seq>plot
  (flet ((plot (seq &rest keys)
           (with-output-to-string (s) (apply #'seq>plot seq :out s keys)))
         (lines (string)
           (uiop:split-string (string-right-trim '(#\Newline) string) :separator '(#\Newline))))
    (let* ((events (loop for i below 10 collect (list i i)))   ; (time value), increasing
           (l (lines (plot events :width 10 :height 5))))
      ;; the maximum, 5 rows, the minimum, the times
      (is (= 8 (length l)))
      (is (string= "9" (first l)))
      (is (string= "0" (seventh l)))
      (is (string= "0        9" (eighth l)))
      (is (= 10 (count #\* (format nil "~{~A~}" (subseq l 1 6)))))
      ;; the first event at the bottom left, the last one at the top right
      (is (char= #\* (char (sixth l) 0)))
      (is (char= #\* (char (second l) 9))))
    ;; the time in x, proportionally: an event at time 0 and one at time 9 on 10 columns
    (let ((l (lines (plot '((0 1) (9 2)) :width 10 :height 2))))
      (is (string= "         *" (second l)))
      (is (string= "*         " (third l))))
    ;; the dimension: (nth dimension (cdr event))
    (is (search "30" (plot '((0 1 10) (1 2 30)) :dimension 1 :width 4 :height 2)))
    ;; the window: from the time 5, during 2
    (is (string= "7" (first (lines (plot (loop for i below 10 collect (list i i))
                                              :start 5 :duration 2 :width 3 :height 3)))))
    ;; the zoom in y: from 2 to 6, the values outside are not drawn
    (let ((l (lines (plot (loop for i below 9 collect (list i i)) :low 2 :high 6 :width 9 :height 5))))
      (is (string= "6" (first l)))
      (is (string= "2" (seventh l)))
      (is (string= "      *  " (second l)))
      (is (string= "  *      " (sixth l)))
      (is (= 5 (count #\* (format nil "~{~A~}" (subseq l 1 6))))))
    ;; one bound only, the other one from the values
    (is (string= "10" (first (lines (plot '((0 1) (1 2)) :high 10 :width 4 :height 2)))))
    (signals error (plot '((0 1) (1 2)) :low 5 :high 3))
    (signals error (plot '((0 1) (1 2)) :low 'a))
    ;; more events than columns: each column marks all its events, the extrema are kept
    (is (search "100" (plot (loop for i below 1000 collect (list i (if (= i 501) 100 0)))
                                :width 10 :height 4)))
    ;; the times of the window stay apart, even on a narrow plot
    (is (string= "0.25 3" (car (last (lines (plot '((1/4 1) (3 2)) :width 4 :height 2))))))
    ;; numbers without useless decimals
    (let ((l (lines (plot '((0 1.25) (1 2.5)) :width 4 :height 2))))
      (is (equal '("2.5" "1.25") (list (first l) (fourth l)))))
    (signals error (plot '((0 a))))
    (signals error (plot '(1 2 3)))
    (signals error (plot '((0 1) (1 2)) :start 5))
    ;; without labels: the plot alone
    (is (equal '("   *" "*   ") (lines (plot '((0 1) (3 2)) :width 4 :height 2 :labels nil))))))

(test seq>plot-svg
  (uiop:with-temporary-file (:pathname tmp :type "svg" :keep nil)
    (let ((events '((0 60) (1 62) (2 64) (3 62) (5 67))))
      ;; a pathname or a string: an SVG file, whose name is returned
      (is (string= (namestring tmp) (seq>plot events :out tmp)))
      (let ((svg (uiop:read-file-string tmp)))
        (is (search "<svg" svg))
        (is (search "width=\"720\" height=\"240\"" svg))
        (is (= 1 (count-substring "<polyline" svg)))
        (is (search ">67</text>" svg))
        (is (search ">60</text>" svg))
        (is (search ">5</text>" svg))
        (is (search "clip-path" svg)))
      ;; zoom in y: the bounds are written
      (seq>plot events :out tmp :low 50 :high 70)
      (let ((svg (uiop:read-file-string tmp)))
        (is (search ">70</text>" svg))
        (is (search ">50</text>" svg)))
      ;; points, size, no labels
      (seq>plot events :out (namestring tmp) :mode :points :width 300 :height 100 :labels nil)
      (let ((svg (uiop:read-file-string tmp)))
        (is (= 5 (count-substring "<circle" svg)))
        (is (search "width=\"300\" height=\"100\"" svg))
        (is (not (search "<text" svg))))
      (signals error (seq>plot events :out tmp :mode :bars))))
  ;; without type, the file is of type svg
  (uiop:with-temporary-file (:pathname tmp :keep nil)
    (let ((name (seq>plot '((0 1) (1 2)) :out (make-pathname :type nil :defaults tmp))))
      (is (equal "svg" (pathname-type name)))
      (ignore-errors (delete-file name)))))

