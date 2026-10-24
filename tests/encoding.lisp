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

(def-suite encoding :in refrains
  :description "1. Transcription: encoding.")
(in-suite encoding)

(test transcode
  (is (equal '(x b z x) (transcode '(a b c a) '((a x) (c z)))))
  (is (equal '() (transcode '() '((a x))))))

(test alpha>num
  (is (equal '(65 66 67) (alpha>num 'abc)))
  (is (equal '(97 98 99) (alpha>num "abc")))
  (is (= 72 (alpha>num "C" :midi)))
  (is (= 72 (alpha>num 'c :midi))))

(test num>alpha
  (is (equal '(a b ab) (num>alpha '(0 1 27)))))

(test num>base
  (is (= 1010 (num>base 10 2)))
  (is (eq 'ff (num>base 255 16))))

(test concaten
  (is (eq 'abc (concaten '(a b c))))
  (is (string= "abcd" (concaten '("ab" "cd"))))
  (is (eq 'x (concaten 'x)))
  (is (= 123 (list>sym '(1 2 3)))))

(test str>sym
  (is (equal '(a b c) (str>sym "a b c")))
  (is (equal '((a b) (c)) (str>sym '("a b" "c")))))

(test no-self-recursive-wrappers
  ;; used to loop forever
  (signals error (num>alpha 2.5))
  (signals error (alpha>num #\a)))

(test alphanump-list
  ;; the list method returned a list of booleans, always true
  (is-true (refrains::alphanump '(#\a #\B #\1)))
  (is-false (refrains::alphanump '(#\! #\?)))
  (is-true (refrains::alphanump '(#\! #\a) '(#\!))))

(test split-string-always-a-list
  ;; a string without marks used to be returned as is, not as a list
  (is (equal '("hello") (split-string "hello" ",")))
  (is (null (split-string "" ",")))
  (is (null (split-string "  " ",")))
  (is (equal '("a,b" "c") (split-string "a,b c" nil)))
  (is (equal '("12" "345" "6789") (split-string "12   345-6789" "- ")))
  ;; read-text: each line is a list, even of one word (as documented)
  (uiop:with-temporary-file (:pathname file :type "txt")
    (with-open-file (out file :direction :output :if-exists :supersede)
      (format out "1~%2 3~%~%4~%"))
    (is (equal '((1) (2 3) (4)) (read-text (namestring file))))
    (is (equal '("1" "2" "3" "4") (read-text (namestring file) :mode nil))))
  (uiop:with-temporary-file (:pathname file :type "txt")
    (with-open-file (out file :direction :output :if-exists :supersede)
      (format out "single"))
    (is (equal '("single") (read-text (namestring file) :mode nil)))))
