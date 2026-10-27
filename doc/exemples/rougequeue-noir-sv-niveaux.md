# Le chant du rougequeue noir, des données brutes de Sonic Visualiser à sa transcription

[Exemples](../exemples.md)

F. Voisin, octobre 2026. Script : [lisp/rougequeue-noir-sv-niveaux.lisp](../lisp/rougequeue-noir-sv-niveaux.lisp).

Cet exemple prolonge celui de 2011 ([rougequeue noir](rougequeue-noir.md)) et
son remake de 2026 ([depuis Sonic Visualiser](rougequeue-noir-sv.md)). Dans ces
deux exemples, chaque spectre instantané du sonagramme est un « mot » de deux
symboles, présence ou absence d'énergie, comme dans l'image en noir et blanc
que donnait jp2a, et les mots sont classés selon leur distance d'édition
(`class-sym`). Ici, on lit directement les **données brutes** du sonagramme
exportées de Sonic Visualiser, avec leurs intensités : chaque spectre devient
un vecteur de **six niveaux d'intensité**, et les vecteurs sont classés par les
nuées dynamiques (`class-num`), selon leur distance euclidienne.

On commence par un seul chant, le premier des trois du remake : un extrait de
la plage 12 du CD de André Bossus, [*Les chants d'oiseaux d'Europe occidentale*](https://www.delachauxetniestle.com/livre/les-chants-doiseaux-deurope-occidentale-3/9782603020036),
Delachaux et Niestlé (livre avec CD). L'enregistrement audio n'est pas
distribué : seules les données du sonagramme le sont.

## 1. Les données

[data/rougequeue-noir01.csv](../data/rougequeue-noir01.csv) : 400 spectres
(4,63 s) de 513 bandes, de 0 à 22 050 Hz, un spectre toutes les 11,6 ms. Ce
sont les amplitudes du sonagramme, et non des décibels. L'export depuis Sonic
Visualiser et le format du fichier sont décrits dans le
[remake](rougequeue-noir-sv.md#1-lexport-depuis-sonic-visualiser).

## 2. La méthode

1. **La lecture** : `(read-text fichier :sep ",")` donne une liste par ligne ;
   les nombres de l'en-tête sont les fréquences, et chaque autre ligne, sans le
   temps, est un spectre.
2. **Les bandes** : les 513 bandes sont regroupées par 11, en gardant le
   maximum de chaque groupe : 47 bandes de 474 Hz, proches des 490 Hz de
   l'image de 2011.
3. **Les niveaux** : une bande vaut 0 quand son amplitude est à plus de
   40 dB sous le maximum du sonagramme, puis de 1 à 5 par tranches de 8 dB, le
   niveau 5 atteignant le maximum. Le seuil se rapporte au maximum de chaque
   fichier, non à un enregistrement de référence. Chaque spectre est un vecteur
   de 47 niveaux.
4. **La classification** : les spectres silencieux (tout à 0) forment la
   classe 0 ; les autres sont classés en 11 classes par les nuées dynamiques
   (Diday) de `class-num`, avec la distance euclidienne. Les centres initiaux
   sont les spectres distincts triés par leur énergie (la somme de leurs
   niveaux), pris à intervalles réguliers : le résultat est reproductible, alors
   que des centres tirés au hasard donnent une autre partition à chaque essai.
   Chaque classe est décrite par son centre de gravité, et sa cohésion par la
   distance moyenne de ses spectres à ce centre.

Pourquoi pas `class-sym`, comme en 2011 ? Avec six niveaux, sa distance
d'édition compte un passage de 1 à 2 comme un passage de 1 à 5, et son lien
simple enchaîne les spectres par petites différences : sur
`rougequeue-noir01.csv`, 191 des 204 spectres non silencieux tombent dans une
seule classe, et les 11 autres classes n'ont qu'un à trois spectres. La
distance euclidienne tient compte de l'écart entre les niveaux, et les nuées
dynamiques forment des classes compactes.

Le sonagramme en texte (`x` pour le silence, puis le niveau de 1 à 5) est
écrit dans `pictures/rougequeue-noir01-niveaux.txt` ; voici la bande du chant, de 2,4 à
6,6 kHz, sur les 200 premiers spectres (2,3 s) :

```
 6.2 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 5.7 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1xxxxxxxxxxxxx
 5.2 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx22xxxxxx44x11xxx24111xxxxx22xxxxxxxx3312xxxxxxxxxxxx11xxxxxxxxxxxxxxxxxxxx1xxxxxxxxxxxxxxxxx111xx1xxxxxx11xxxx
 4.7 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxx12xxxxxxxxxxxx232xxxxxxxxxxxxx244xxxxxxxxxxxxxx441xxxxxxxxxxxx34432xxx24332xxx243431xxx14433xxxxxx34232xxxxxxxxx14433xxxxxxxxxxxxxxxxxxx1xxxxxxxxxxxxxxxxx111xx1xxxxxxx1xxxx
 4.3 kHz |xxxxxxxxxxx11xxxxxxxxxxxxxxxx232xxxxxxxxxxx233xxxxxxxxxxxxx1431xxx22231xxxx244211x22222xxx234432xx134431xx124432xxx123343xxxxx23333xxxxxxxxxx2333xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx111xx1xxxxx111xxxx
 3.8 kHz |xxxxxxxxxxxx1xxxxxxxxxxxxxxxxxx2xxxxxxxxxxxx1321x12222xxxxxx14322233433xxxxxx4422233333xxx133332xx124332xx114332xxx113343xxxxx21333xxxxxxxxxxx333xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1xxxxxxxxxxxx1xxxx
 3.3 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1211211xxxxxxxx1211212332xxxxxxx221112332xxxx1232xxxxx222xxxxx2122xxxxx12121xxxx1x2221xxxxxxxxxxx111xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 2.8 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1xxxxxxx1xxxxxxxx1xxxxxxxx21xxxxxxxx121xxxxxxxxxxxx1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 2.4 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 3. Le résultat

La transcription de `rougequeue-noir01.csv`, un caractère par spectre
(11,6 ms), `-` pour le silence et une lettre par classe :

```
-----------aa---------------abcd----------cbbdaeaaeaaa----cbbdfaaedffff----bbdfeaadffff---ghhhid--gjhhia--gjhhhi---cjhhhia----jjihiaa-------abhhha------------------c-----------------ccc-ac-----acc-------------ccccggccccc------cckc-----------kcckgccc-cgkkkgkgcgcaag-cacckkgcgkkkkggceeeeea-----eadddhhjjifea----efajjkheea--eeegjjjdee----bbhhhia----bbhhhfa----abhihiaa-----------------------------------
```

Les notes du chant se lisent comme des suites de classes, et se répètent avec
des variantes. Les trois notes longues du début : `cbbdaeaaeaaa`,
`cbbdfaaedffff`, `bbdfeaadffff`. Les notes brèves qui suivent : `ghhhid`,
`gjhhia`, `gjhhhi`, `cjhhhia`. Le grésillement, après la pause, mêle les
classes `c`, `g` et `k`, plus aiguës. Les dernières notes du chant, `bbhhhia`,
`bbhhhfa`, `abhihiaa`, reprennent la classe `h` des notes brèves du début.

| Classe | Spectres | Distance moyenne au centre | Centre (niveau maximal) |
|---|---|---|---|
| `-` | 196 | | silence |
| `a` | 34 | 1,46 | 3,3-4,3 kHz (1) |
| `b` | 13 | 1,29 | 4,3-5,2 kHz (4) |
| `c` | 36 | 1,19 | 4,3-5,7 kHz (1) |
| `d` | 11 | 1,41 | 3,3-4,7 kHz (3) |
| `e` | 19 | 1,28 | 3,3-4,3 kHz (3) |
| `f` | 13 | 1,03 | 3,3-4,7 kHz (3) |
| `g` | 16 | 1,21 | 3,8-6,2 kHz (2) |
| `h` | 26 | 1,42 | 3,3-5,7 kHz (4) |
| `i` | 10 | 1,32 | 2,8-5,2 kHz (3) |
| `j` | 12 | 1,80 | 3,8-5,7 kHz (4) |
| `k` | 14 | 1,20 | 3,8-6,6 kHz (2) |

Les classes vont de 10 à 36 spectres : aucune n'isole un spectre rare. Elles
se distinguent par leur bande et par leur intensité : `a` et `c` sont les
attaques et les fins de notes, faibles (niveau 1), et `c` aussi le gros du
grésillement ; `b`, `h` et `j`, le cœur
des notes, forts (niveau 4) ; `g` et `k`, plus aigus (jusqu'à 6,2 et 6,6 kHz),
qui l'accompagnent. Le centre d'une classe est une moyenne : ses niveaux arrondis
décrivent un spectre type, qui n'est pas forcément un spectre observé.

## Le code

Le code est la documentation. [lisp/rougequeue-noir-sv-niveaux.lisp](../lisp/rougequeue-noir-sv-niveaux.lisp)
se charge depuis le dossier du dépôt :

```lisp
(load "doc/lisp/rougequeue-noir-sv-niveaux.lisp")
```

<!-- code: doc/lisp/rougequeue-noir-sv-niveaux.lisp -->
```lisp
;;;; rougequeue-noir-sv-niveaux.lisp
;;;;
;;;; Transcrire le chant d'un rougequeue noir à partir des données brutes de son sonagramme,
;;;; exportées de Sonic Visualiser : les spectres instantanés, réduits en bandes, deviennent
;;;; des vecteurs dont chaque coordonnée est un niveau d'intensité (de 0, le silence, à 5),
;;;; classés par les nuées dynamiques de class-num (distance euclidienne). C'est une
;;;; extension de l'exemple de 2011 (doc/exemples/rougequeue-noir.md) et de son remake
;;;; (doc/lisp/rougequeue-noir-sv.lisp), qui classent des mots de 0 et de 1, présence ou
;;;; absence d'énergie, par class-sym.
;;;;
;;;; Les données : doc/data/rougequeue-noir01.csv, exportée de Sonic Visualiser 5.2.1
;;;; (calque du sonagramme, File > Export Annotation Layer) : une ligne d'en-tête (TIME, puis
;;;; la fréquence de chaque bande), puis une ligne par instant, le temps en secondes et
;;;; l'amplitude de chaque bande.
;;;;
;;;; (load "doc/lisp/rougequeue-noir-sv-niveaux.lisp") affiche les résultats et écrit le
;;;; sonagramme en texte (doc/pictures/rougequeue-noir01-niveaux.txt).
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

(defparameter *doc*
  (uiop:pathname-parent-directory-pathname (uiop:pathname-directory-pathname *load-truename*)))

;; les réglages : le nombre de bandes de Sonic Visualiser regroupées en une (11 bandes de
;; 43,07 Hz font 474 Hz, proche des 490 Hz de l'image de 2011), le seuil en dB sous le
;; maximum du sonagramme, le nombre de niveaux d'intensité (le silence compris), et le nombre
;; de classes (le silence compris)
(defparameter *regroupement* 11)
(defparameter *seuil-db* 40)
(defparameter *niveaux* 6)
(defparameter *classes* 12)

;;; 1. La lecture : read-text lit chaque ligne comme une liste. Avec :sep ",", il sépare aux
;;; virgules, et aussi aux blancs : un export séparé par des tabulations se lit de même.

(defun lire-sonagramme (file)
  "Les fréquences des bandes (lues dans l'en-tête) et les spectres (sans le temps) de l'export file."
  (let ((lines (read-text file :sep ",")))
    ;; l'en-tête : TIME 0 Hz 43.0664 Hz ... ; les nombres en sont les fréquences
    (values (remove-if-not #'numberp (first lines))
            (mapcar #'rest (rest lines)))))

;;; 2. Les bandes : le maximum de chaque groupe de *regroupement* bandes

(defun bandes (spectre)
  (loop for tail on spectre by (lambda (l) (nthcdr *regroupement* l))
        collect (reduce #'max (subseq tail 0 (min *regroupement* (length tail))))))

;;; 3. Les mots : le niveau de chaque bande, 0 quand son amplitude est à plus de *seuil-db*
;;; sous le maximum du sonagramme, puis de 1 à *niveaux* - 1 par tranches égales en dB
;;; (8 dB pour 40 dB et 6 niveaux), le dernier niveau atteignant le maximum. Le seuil dépend
;;; du fichier (de son maximum), non d'un enregistrement de référence.

(defun niveau (a maximum)
  (let ((db (if (plusp a) (* 20 (log (/ a maximum) 10)) (- *seuil-db*))))
    (if (<= db (- *seuil-db*))
        0
        (max 1 (ceiling (* (- *niveaux* 1) (/ (+ db *seuil-db*) *seuil-db*)))))))

(defun mots (spectres)
  (let* ((reduits (mapcar #'bandes spectres))
         (maximum (reduce #'max (mapcar (lambda (b) (reduce #'max b)) reduits))))
    (mapcar (lambda (b) (mapcar (lambda (a) (niveau a maximum)) b)) reduits)))

;;; 4. Le sonagramme en texte, comme l'image de 2011 convertie par jp2a : une ligne par
;;; bande, les aigus en haut, une colonne par instant ; x pour le silence, puis le niveau
;;; de 1 à 5

(defun image (mots)
  (with-output-to-string (s)
    (loop for k from (1- (length (first mots))) downto 0
          do (format s "~{~A~}~%" (mapcar (lambda (m) (if (zerop (nth k m)) "x" (nth k m))) mots)))))

;; les bandes présentes d'un mot, en plages de fréquences contiguës, avec le niveau maximal
;; de chaque plage : "3,3-4,3 kHz (4)"
(defun plages (mot largeur)
  (let ((plages nil) debut (haut 0))
    (loop for x in (append mot (list 0)) for k from 0
          do (cond ((plusp x) (unless debut (setf debut k haut 0)) (setf haut (max haut x)))
                   (debut
                    (push (format nil "~,1F-~,1F kHz (~D)" (/ (* debut largeur) 1000) (/ (* k largeur) 1000) haut)
                          plages)
                    (setf debut nil))))
    (or (nreverse plages) (list "silence"))))

;;; 5. La classification : les nuées dynamiques de class-num, sur les spectres qui ne sont pas
;;; silencieux, le silence formant la classe 0. Avec la distance d'édition de class-sym, deux
;;; niveaux voisins (1 et 2) sont aussi différents que deux niveaux éloignés (1 et 5), et le
;;; lien simple enchaîne les spectres par petites différences : presque tous tombent dans une
;;; seule classe. La distance euclidienne tient compte de l'écart entre les niveaux.

;; les centres initiaux : les spectres distincts, triés par leur énergie (la somme de leurs
;; niveaux), pris à intervalles réguliers. Partir de centres donnés rend le résultat
;; reproductible, alors que des centres tirés au hasard donnent une partition à chaque essai.
(defun centres-initiaux (sons k)
  (let ((distincts (sort (remove-duplicates sons :test #'equal) #'< :key (lambda (s) (reduce #'+ s)))))
    (loop for i below k
          collect (nth (floor (* (+ i 1/2) (length distincts)) k) distincts))))

;; le centre de gravité de chaque classe, et la distance moyenne de ses spectres à ce centre
(defun centres (sons classes)
  (loop for c from 0 to (reduce #'max classes)
        collect (let* ((membres (loop for s in sons for k in classes when (= k c) collect s))
                       (centre (mapcar (lambda (x) (/ x (length membres)))
                                       (reduce (lambda (a b) (mapcar #'+ a b)) membres))))
                  (list centre (/ (reduce #'+ (mapcar (lambda (s) (dist-euclidean s centre)) membres))
                                  (length membres))))))

(defun analyse (file)
  (multiple-value-bind (frequences spectres) (lire-sonagramme file)
    (let* ((mots (mots spectres))
           (silence (make-list (length (first mots)) :initial-element 0))
           (sons (remove silence mots :test #'equal))
           (classes-sons (first (class-num sons (centres-initiaux sons (1- *classes*)) :centroids)))
           (largeur (* *regroupement* (- (second frequences) (first frequences)))))
      (let ((classes (let ((c classes-sons))
                       (mapcar (lambda (m) (if (equal m silence) 0 (1+ (pop c)))) mots))))
        (format t "~&~%=== ~A~%" (file-namestring file))
        (format t "~D spectres de ~D bandes (~,2F Hz), en ~D bandes de ~D Hz ; ~D silences, ~D spectres distincts~%"
                (length spectres) (length frequences) (- (second frequences) (first frequences))
                (length silence) (round largeur) (count silence mots :test #'equal)
                (length (remove-duplicates mots :test #'equal)))
        ;; la transcription : - pour le silence, une lettre par classe
        (format t "Transcription :~%~{~A~}~%"
                (mapcar (lambda (c) (if (zerop c) "-" (string-downcase (num>alpha (1- c))))) classes))
        ;; chaque classe : son nombre de spectres, la distance moyenne de ses spectres à son
        ;; centre, et les bandes de son centre (aux niveaux arrondis), en kHz
        (format t "  - : ~3D spectres, silence~%" (count 0 classes))
        (loop for (centre distance) in (centres sons classes-sons)
              for c from 1
              do (format t "~&  ~A : ~3D spectres, distance ~,2F, centre ~{~A~^, ~}~%"
                         (string-downcase (num>alpha (1- c))) (count c classes) distance
                         (plages (mapcar #'round centre) largeur)))
        (let ((texte (merge-pathnames (format nil "pictures/~A-niveaux.txt" (pathname-name file)) *doc*)))
          (with-open-file (o texte :direction :output :if-exists :supersede)
            (write-string (image mots) o))
          (format t "~&Sonagramme en texte : doc/pictures/~A~%" (file-namestring texte)))
        ;; la transcription, pour d'autres exemples (rougequeue-noir-arbres.lisp)
        classes))))

(analyse (merge-pathnames "data/rougequeue-noir01.csv" *doc*))
```
<!-- /code -->

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
