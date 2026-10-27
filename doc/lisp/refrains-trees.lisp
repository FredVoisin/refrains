;;;; refrains-trees.lisp
;;;;
;;;; Les arbres des fonctions de refrains : les arbres de recouvrement minimal
;;;; des fonctions exportées, d'après leurs noms et d'après le vocabulaire de
;;;; leur documentation, et leurs dendrogrammes, calculés avec refrains.
;;;;
;;;; (load "doc/lisp/refrains-trees.lisp") écrit, dans doc/pictures/,
;;;; refrains-names.dot/.png, refrains-docstrings.dot/.png, refrains-code.dot/.png
;;;; et leurs dendrogrammes, refrains-names-dendrogram.dot/.png,
;;;; refrains-docstrings-dendrogram.dot/.png et refrains-code-dendrogram.dot/.png.
;;;; Les images sont tracées par neato (Graphviz).
;;;;
;;;; Copyright (C) 2026 Frédéric Voisin
;;;;
;;;; Ce fichier, exemple de la documentation de refrains, est placé sous licence
;;;; Creative Commons Attribution 4.0 International (CC BY 4.0), comme la
;;;; documentation : voir ../LICENSE ou https://creativecommons.org/licenses/by/4.0/
;;;;
;;;; SPDX-License-Identifier: CC-BY-4.0

(asdf:load-system :refrains)
(in-package :refrains)

;; le dossier des images : doc/pictures/, à côté du dossier de ce fichier (doc/lisp/)
(defparameter *pictures*
  (merge-pathnames "pictures/" (uiop:pathname-parent-directory-pathname
                                (uiop:pathname-directory-pathname *load-truename*))))

(defparameter *functions*
  (sort (loop for f being the external-symbols of :refrains collect f) #'string<))

(defparameter *names* (mapcar #'string-downcase *functions*))

(defun matrice-des-fonctions (objects distance)
  "La semi-matrice ((nom-a nom-b distance) ...) des fonctions, d'après la distance
entre leurs objets (noms ou vocabulaires), arrondie au centième."
  (loop for (a . others) on objects
        for (name-a . other-names) on *names*
        nconc (loop for b in others
                    for name-b in other-names
                    collect (list name-a name-b
                                  (/ (round (* 100 (funcall distance a b))) 100.0)))))

;;; 1. Par les noms : distance d'édition normalisée entre les noms, lettre à lettre

(defparameter *names-tree*
  (graph-span (matrice-des-fonctions *names* (lambda (a b) (dist-edit a b :norm t)))))

;;; 2. Par la documentation : distance de Jaccard entre les vocabulaires

;; les mots grammaticaux de l'anglais des docstrings, qui ne disent rien du rôle des fonctions
(defparameter *mots-grammaticaux*
  '(;; articles et déterminants
    "a" "an" "the" "this" "that" "these" "those" "each" "every" "all" "any" "some" "no"
    "other" "another" "such" "both" "either" "neither"
    ;; pronoms
    "it" "its" "they" "them" "their" "theirs" "which" "who" "whom" "whose" "what" "there"
    ;; auxiliaires et verbes modaux
    "is" "are" "was" "were" "be" "been" "being" "am" "has" "have" "had" "do" "does" "did"
    "can" "could" "may" "might" "must" "shall" "should" "will" "would"
    ;; conjonctions
    "and" "or" "but" "nor" "so" "yet" "if" "then" "else" "than" "as" "because" "while"
    "when" "where" "whether" "not"
    ;; prépositions
    "of" "to" "in" "on" "at" "by" "for" "with" "from" "into" "onto" "over" "under" "between"
    "among" "through" "during" "before" "after" "about" "against" "without" "within" "along"
    "across" "per" "via" "up" "down" "out" "off"
    ;; adverbes
    "also" "only" "just" "very" "too" "more" "most" "less" "least"))

(defun vocabulaire (f)
  "Les mots de la documentation de f, en minuscules, sans le nom de f, les mots grammaticaux,
les nombres et les symboles d'une lettre (a, b, x...)."
  (remove-duplicates
   (remove-if (lambda (word)
                (or (member word *mots-grammaticaux* :test #'string=)
                    (= (length word) 1)
                    (every #'digit-char-p word)
                    (string= word (string-downcase f))))
              (separate (string-downcase (documentation f 'function))
                        :marks "()<>[]{},;.:!?'\"=/|*#`&+~"))
   :test #'string=))

(defparameter *vocabulaires* (mapcar #'vocabulaire *functions*))

;; les mots voisins (list et lists ; define, defined et defines...) sont fusionnés en un
;; terme générique, le plus court d'entre eux : leur distance d'édition relative est
;; au plus 0,2, une substitution comptant comme une suppression et une insertion
;; (:sub 2), pour que seules les variantes d'un même mot se rapprochent

(defparameter *mots*
  (sort (remove-duplicates (reduce #'append *vocabulaires*) :test #'string=) #'string<))

(defun mots-voisins (words)
  "Les paires de mots voisins (mot-a mot-b distance)."
  (loop for (a . others) on words
        nconc (loop for b in others
                    ;; la distance relative vaut au moins l'écart des longueurs
                    when (<= (abs (- (length a) (length b))) (* 0.2 (max (length a) (length b))))
                      nconc (let ((d (dist-edit a b :sub 2 :norm t)))
                              (when (<= d 0.2) (list (list a b d)))))))

;; les groupes de mots voisins : les feuilles des dendrogrammes (lien simple) du graphe
;; des mots voisins, qui n'est pas connexe (graph-span le signale) ;
;; dendrogram-leaves : fonction interne de refrains, non exportée
(defparameter *termes-generiques*
  (let ((terms (make-hash-table :test #'equal))
        (forest (nth-value 1 (graph-dendrogram (mots-voisins *mots*)))))
    (dolist (tree (if (realp (first forest)) (list forest) forest) terms)
      (let* ((group (refrains::dendrogram-leaves tree))
             (generic (first (stable-sort (sort (copy-list group) #'string<) #'< :key #'length))))
        (dolist (word group) (setf (gethash word terms) generic))))))

(defun vocabulaire-generique (vocabulaire)
  (remove-duplicates (mapcar (lambda (word) (gethash word *termes-generiques* word)) vocabulaire)
                     :test #'string=))

;; les mots du style des docstrings, qui reviennent dans toutes les fonctions qui ont des
;; options, sans dire ce qu'elles font : retirés après la fusion des variantes (define,
;; defined et defines ont pour terme générique define)
(defparameter *mots-de-documentation*
  '("argument" "keyword" "optional" "option" "default" "nil" "equalp"
    "return" "returns" "returned" "define" "give" "according" "use" "using" "mode"))

(defparameter *termes*
  (mapcar (lambda (v) (set-difference (vocabulaire-generique v) *mots-de-documentation*
                                      :test #'string=))
          *vocabulaires*))

(defparameter *docstrings-tree*
  (graph-span
   (matrice-des-fonctions *termes*
                ;; jaccard-dist : fonction interne de refrains, non exportée
                (lambda (a b) (refrains::jaccard-dist a b :test #'string=)))))

;;; 3. Les arbres en langage dot, puis en images : graph>dot écrit le fichier .dot
;;; et appelle neato. Les distances, de 0 à 1, sont plus courtes que les noms des
;;; nœuds : avec :overlap nil, neato écarte les nœuds qui se chevaucheraient ;
;;; :invert t trace en blanc sur noir.

(graph>dot *names-tree* :out (namestring (merge-pathnames "refrains-names.png" *pictures*))
           :overlap nil :invert t)
(graph>dot *docstrings-tree* :out (namestring (merge-pathnames "refrains-docstrings.png" *pictures*))
           :overlap nil :invert t)

;;; 4. Les dendrogrammes de chaque arbre : graph-dendrogram (lien simple) range les
;;; fusions de l'arbre par distance croissante ; dendrogram>dot place les feuilles à
;;; gauche et chaque fusion à l'abscisse de sa distance, et appelle neato -n2.

(dendrogram>dot (nth-value 1 (graph-dendrogram *names-tree*))
                :out (namestring (merge-pathnames "refrains-names-dendrogram.png" *pictures*))
                :invert t)
(dendrogram>dot (nth-value 1 (graph-dendrogram *docstrings-tree*))
                :out (namestring (merge-pathnames "refrains-docstrings-dendrogram.png" *pictures*))
                :invert t)

;;; 5. Par le code : pour chaque fonction, l'expression complète de ce qu'elle fait, sa
;;; définition et celles de toutes les fonctions de refrains qu'elle appelle, de proche en
;;; proche, réduite aux noms des fonctions de refrains et aux noms de leurs arguments et
;;; options ; distance de Jaccard entre ces ensembles de noms.

;; le dossier des sources : src/, à côté de doc/ (doc/pictures/ remonté de deux niveaux)
(defparameter *sources*
  (merge-pathnames "src/" (uiop:pathname-parent-directory-pathname
                           (uiop:pathname-parent-directory-pathname *pictures*))))

;; les définitions de refrains : le nom de chaque fonction, générique ou non, et ses formes
;; (defun, defgeneric et toutes ses méthodes), lues avec le lecteur Lisp
(defparameter *definitions*
  (let ((definitions (make-hash-table)))
    (dolist (file (append (directory (merge-pathnames "*.lisp" *sources*))
                          (directory (merge-pathnames "api/*.lisp" *sources*)))
                  definitions)
      (with-open-file (s file)
        (let ((*package* (find-package :refrains)))
          (loop for form = (read s nil s) until (eq form s)
                when (and (consp form) (member (first form) '(defun defmacro defgeneric defmethod)))
                  do (push form (gethash (second form) definitions))))))))

(defun arguments (form)
  "Les noms des arguments et options de la définition form : sa liste d'arguments sans les
mots &optional, &key..., ni les valeurs par défaut ni les classes des méthodes."
  (loop for x in (third form)
        unless (member x lambda-list-keywords)
          collect (if (consp x) (if (consp (first x)) (second (first x)) (first x)) x)))

(defun appels (form)
  "Les fonctions de refrains appelées dans le corps de la définition form : les symboles en position
de fonction, (f ...), ou désignés par #'f ; une variable du même nom qu'une fonction (test, list...)
n'est pas un appel."
  (let ((calls nil))
    (labels ((call (x) (when (and (symbolp x) (gethash x *definitions*)) (pushnew x calls)))
             (walk (x)
               (when (consp x)
                 (if (and (eq (first x) 'function) (consp (cdr x)))
                     ;; #'f désigne f ; #'(lambda ...) : les appels de son corps
                     (if (consp (second x)) (walk (second x)) (call (second x)))
                     (progn (call (first x))
                            (loop for y on x
                                  do (walk (car y))
                                  while (consp (cdr y))))))))
      (mapc #'walk (cdddr form)))
    calls))

(defun expression-complete (f)
  "Les fonctions de l'expression complète de f : f et toutes les fonctions de refrains qu'elle
appelle, de proche en proche, chacune une fois."
  (let ((seen nil))
    (labels ((visit (g)
               (unless (member g seen)
                 (push g seen)
                 (dolist (form (gethash g *definitions*))
                   (mapc #'visit (appels form))))))
      (visit f))
    seen))

(defun noms-du-code (f)
  "L'expression complète de f réduite à ses noms : les fonctions de refrains et les arguments
et options de leurs définitions, en minuscules."
  (let ((functions (expression-complete f)))
    (remove-duplicates
     (mapcar #'string-downcase
             (append functions
                     (loop for g in functions
                           append (loop for form in (gethash g *definitions*)
                                        append (arguments form)))))
     :test #'string=)))

(defparameter *noms-du-code* (mapcar #'noms-du-code *functions*))

(defparameter *code-tree*
  (graph-span
   (matrice-des-fonctions *noms-du-code*
                          (lambda (a b) (refrains::jaccard-dist a b :test #'string=)))))

(graph>dot *code-tree* :out (namestring (merge-pathnames "refrains-code.png" *pictures*))
           :overlap nil :invert t)
(dendrogram>dot (nth-value 1 (graph-dendrogram *code-tree*))
                :out (namestring (merge-pathnames "refrains-code-dendrogram.png" *pictures*))
                :invert t)
