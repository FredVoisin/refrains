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

(def-suite help :in refrains
  :description "Documentation: menu, doc and help.")
(in-suite help)

(test help-and-doc
  (let ((*standard-output* (make-broadcast-stream)))
    ;; help printed every similarity score and returned nil
    (is (member 'graph-span (help 'graph)))
    (is (equal '(entropy) (help :entropy)))
    (is (null (help 'zzzzzz)))
    (is (every #'symbolp (help "distance")))
    ;; doc from another package: 'dist-edit was cl-user::dist-edit (nil)
    (let ((*package* (find-package :cl-user)))
      (is (stringp (doc (intern "DIST-EDIT" :cl-user))))
      (is (stringp (doc "histogram"))))
    (is (null (doc 'not-a-function))))
  ;; help prints the documentations of the functions found, not the scores
  (is (search "ENTROPY:" (with-output-to-string (*standard-output*) (help :entropy)))))

(test menu-lists-all-functions
  ;; 23 exported functions were missing from the menu: (doc) did not list them, help could not find them
  (let (missing)
    (do-external-symbols (s :refrains)
      (unless (member s refrains::*refrains-menu*) (push s missing)))
    (is (null missing)))
  (is (every #'fboundp refrains::*refrains-menu*))
  (is (every #'(lambda (f) (documentation f 'function)) refrains::*refrains-menu*))
  (let ((*standard-output* (make-broadcast-stream)))
    (is (member 'filt-median (help 'median)))))

(test doc-lisp-license
  ;; the Lisp files of doc/lisp/, examples of the documentation, are under CC BY 4.0, like the documentation
  (let ((files (remove "lisp" (uiop:directory-files (asdf:system-relative-pathname :refrains "doc/lisp/"))
                       :key #'pathname-type :test-not #'equal)))
    (is (plusp (length files)))
    (dolist (f files)
      (is (search "SPDX-License-Identifier: CC-BY-4.0" (uiop:read-file-string f))
          "~A has no SPDX-License-Identifier: CC-BY-4.0" (file-namestring f)))))
