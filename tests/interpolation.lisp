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

(def-suite interpolation :in refrains
  :description "1. Transcription: interpolation of sequences (morph-lists).")
(in-suite interpolation)

(test morph-lists
  (let ((r (morph-lists '(a m p h o r a) '(p o u l e t))))
    (is (equal '(a m p h o r a) (first r)))
    (is (equal '(p o u l e t) (car (last r))))
    ;; as many steps as the edit distance
    (is (= (1+ (dist-edit '(a m p h o r a) '(p o u l e t))) (length r))))
  ;; deterministic: the same result at each call
  (is (equal (morph-lists '(a b c d) '(d c b a)) (morph-lists '(a b c d) '(d c b a))))
  ;; identical elements were counted as steps: 4 copies of (a b c)
  (is (equal '((a b c)) (morph-lists '(a b c) '(a b c))))
  (is (equal '((1 2 3) (1 3)) (morph-lists '(1 2 3) '(1 3))))
  (is (equal '((a b c) (b c) (c) nil) (morph-lists '(a b c) '())))
  (is (equal '(nil (a) (a b)) (morph-lists '() '(a b))))
  ;; strings were compared with eql
  (is (equal '(("a" "b") ("a" "c")) (morph-lists (list "a" "b") (list (copy-seq "a") "c"))))
  (is (equal '("chat" "chiat" "chiet" "chien") (morph-lists "chat" "chien")))
  ;; at random, still a path of minimal length
  (let ((*random-state* (seeded-random-state)))
    (is (loop repeat 20
              always (= 8 (length (morph-lists '(a m p h o r a) '(p o u l e t) :random t)))))))
