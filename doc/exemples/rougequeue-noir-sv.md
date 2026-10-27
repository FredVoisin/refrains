# Le chant du rougequeue noir, du sonagramme de Sonic Visualiser à sa transcription

[Exemples](../exemples.md)

F. Voisin, octobre 2026. Script : [lisp/rougequeue-noir-sv.lisp](../lisp/rougequeue-noir-sv.lisp).

Cet exemple est un remake de celui de 2011 ([rougequeue noir](rougequeue-noir.md)) :
les spectres instantanés d'un sonagramme deviennent des « mots », classés selon
leur distance d'édition (`class-sym`), et la suite de leurs classes est une
transcription du chant. En 2011, le sonagramme était une image, convertie en
texte par jp2a. Ici, on refait l'exemple directement depuis Sonic Visualiser : on
part de ses **données**, et on les ramène à ce que donnait jp2a, une image en
noir et blanc du sonagramme. Les sonagrammes sont ceux de trois extraits de la plage 12 du CD de
André Bossus, [*Les chants d'oiseaux d'Europe occidentale*](https://www.delachauxetniestle.com/livre/les-chants-doiseaux-deurope-occidentale-3/9782603020036), Delachaux et Niestlé (livre avec CD), d'où vient aussi l'enregistrement de 2011 ; ce ne sont pas
nécessairement les mêmes passages, et les classes ne se comparent pas une à
une avec celles de 2011. Les enregistrements audio ne sont pas distribués :
seules les données des sonagrammes le sont.

## 1. L'export depuis Sonic Visualiser

Le sonagramme est calculé et affiché par [Sonic Visualiser](https://www.sonicvisualiser.org/)
(version 5.2.1). Pour exporter ses données, il faut que le calque du sonagramme
soit le calque courant, puis *File > Export Annotation Layer*. L'export des
données d'un sonagramme existe depuis la version 4.1 de Sonic Visualiser.

Les options choisies dans la fenêtre d'export, et ce qu'elles donnent :

- **Column separator : Comma ','** : les valeurs sont séparées par des
  virgules, d'où l'extension `.csv`. Un autre séparateur (tabulation) donnerait
  le même résultat : `read-text` sépare aux virgules et aux blancs.
- **Include a header row before the data rows** : une ligne d'en-tête, `TIME`
  puis la fréquence de chaque bande (`0 Hz`, `43.0664 Hz`… `22050 Hz`). Le
  script y lit les fréquences.
- **Include a timestamp column before the data columns** : chaque ligne
  commence par le temps de l'instant, que le script retire.
- **Write times in seconds** : le temps en secondes (`0.011609977`…), et non en
  numéros d'échantillons.
- **Export only the height of the visible view** : seules les bandes affichées
  sont exportées. Ici, la vue montrait toute la hauteur : les fichiers ont les
  513 bandes, de 0 à 22 050 Hz. Avec une vue limitée à la bande du chant, ils
  seraient plus petits, et le script resterait le même.

Les valeurs exportées sont les **amplitudes** du sonagramme (multipliées par le
facteur d'échelle du calque), et non des décibels ; la normalisation et le gain
d'affichage ne s'y appliquent pas.

## 2. Les données

| Fichier | Spectres | Durée | Bandes |
|---|---|---|---|
| [data/rougequeue-noir01.csv](../data/rougequeue-noir01.csv) | 400 | 4,63 s | 513, de 0 à 22 050 Hz |
| [data/rougequeue-noir02.csv](../data/rougequeue-noir02.csv) | 404 | 4,68 s | 513, de 0 à 22 050 Hz |
| [data/rougequeue-noir03.csv](../data/rougequeue-noir03.csv) | 353 | 4,09 s | 513, de 0 à 22 050 Hz |

D'après les fichiers, le son est échantillonné à 44,1 kHz et le sonagramme
calculé par une transformée de Fourier de 1024 points (513 bandes de
43,07 Hz), un spectre toutes les 512 échantillons (11,6 ms). Chaque ligne est
`temps,amplitude de la bande 1,…,amplitude de la bande 513` :

```
TIME,0 Hz,43.0664 Hz,86.1328 Hz,129.199 Hz,...
0.000000000,1.13231e-05,1.00114e-05,7.18355e-06,3.99856e-06,...
0.011609977,2.28298e-05,1.21638e-05,2.71673e-06,5.92524e-06,...
```

Le script analyse chaque fichier `data/rougequeue-noir*.csv` : une autre
variante du chant, exportée de la même façon, est analysée en l'ajoutant au
dossier.

## 3. La méthode

1. **La lecture** : `(read-text fichier :sep ",")` donne une liste par ligne ;
   les nombres de l'en-tête sont les fréquences, et chaque autre ligne, sans le
   temps, est un spectre.
2. **Les bandes** : les 513 bandes sont regroupées par 11, en gardant le
   maximum de chaque groupe : 47 bandes de 474 Hz, proches des 490 Hz de
   l'image de 2011, et des mots assez courts pour la distance d'édition.
3. **Les mots** : on part du résultat de jp2a, le sonagramme en noir et blanc :
   à chaque instant, chaque bande est noire (1, de l'énergie) ou blanche (0, le
   silence). Chaque spectre est ainsi un mot de 47 symboles, 0 ou 1. Le script
   simule ce résultat à partir des données de Sonic Visualiser : la simulation
   est expliquée dans le code.
4. **La classification** : `class-sym` en 12 classes, avec les coûts du patch
   de 2011 (insertion et suppression 1,5), les spectres silencieux (tout à 0)
   exclus, qui forment la classe 0. Avec `:medians t`, chaque classe a sa
   chaîne médiane (son spectre type) et sa cohésion (le LSI moyen de ses
   spectres à la médiane).

Le sonagramme en texte, comme l'image de 2011 (`x` pour le silence, `.` pour
l'énergie), est écrit dans `pictures/rougequeue-noir01.txt` ; voici la bande du
chant, de 2,4 à 6,6 kHz, sur les 200 premiers spectres (2,3 s) :

```
 6.2 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 5.7 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxx
 5.2 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx..xxxxxx..x..xxx.....xxxxx..xxxxxxxx....xxxxxxxxxxxx..xxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxx...xx.xxxxxx..xxxx
 4.7 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxx..xxxxxxxxxxxx...xxxxxxxxxxxxx...xxxxxxxxxxxxxx...xxxxxxxxxxxx.....xxx.....xxx......xxx.....xxxxxx.....xxxxxxxxx.....xxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxx...xx.xxxxxxx.xxxx
 4.3 kHz |xxxxxxxxxxx..xxxxxxxxxxxxxxxx...xxxxxxxxxxx...xxxxxxxxxxxxx....xxx.....xxxx......x.....xxx......xx......xx......xxx......xxxxx.....xxxxxxxxxx....xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx...xx.xxxxx...xxxx
 3.8 kHz |xxxxxxxxxxxx.xxxxxxxxxxxxxxxxxx.xxxxxxxxxxxx....x.....xxxxxx...........xxxxxx..........xxx......xx......xx......xxx......xxxxx.....xxxxxxxxxxx...xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxx.xxxx
 3.3 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.......xxxxxxxx..........xxxxxxx.........xxxx....xxxxx...xxxxx....xxxxx.....xxxx.x....xxxxxxxxxxx...xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 2.8 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxx.xxxxxxxx.xxxxxxxx..xxxxxxxx...xxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 2.4 kHz |xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 4. Le résultat

La transcription de `rougequeue-noir01.csv`, un caractère par spectre
(11,6 ms), `-` pour le silence et une lettre par classe :

```
-----------ab---------------aaab----------aacbdddddddd----aaceedddeeeee----aaceeedeeeee---afgggb--aagfhb--aafffg---cafgged----faffgdd-------aaafgd------------------a-----------------aaa-aa-----aaa-------------aaaaaaaaaaa------aaaa-----------aaaaaaaa-aaaaaaaaaaaaaa-aaaaaaaaaaaaaaaaeddddd-----ddeggaaaagedd----ddiajafdad--dddakkafad----afaaaed----alafged----aaffcgdd-----------------------------------
```

Les phrases du chant se répètent, avec des variantes : `aaceedddeeeee`, puis
`aaceeedeeeee` ; `afgggb`, `aagfhb`, `aafffg`.

| Classe | Spectres | LSI | Médiane |
|---|---|---|---|
| `-` | 196 | 1,00 | silence |
| `a` | 100 | 0,96 | 3,8-5,7 kHz |
| `b` | 5 | 1,00 | 3,8-4,7 kHz |
| `c` | 5 | 1,00 | 3,8-5,2 kHz |
| `d` | 37 | 0,98 | 3,3-4,3 kHz |
| `e` | 21 | 1,00 | 3,3-4,7 kHz |
| `f` | 16 | 1,00 | 3,3-5,7 kHz |
| `g` | 14 | 1,00 | 3,3-5,2 kHz |
| `h` | 1 | 1,00 | 2,8-5,7 kHz |
| `i` | 1 | 1,00 | 2,8-3,3 kHz, 3,8-4,3 kHz, 5,7-6,2 kHz |
| `j` | 1 | 1,00 | 4,3-6,2 kHz, 15,2-16,1 kHz |
| `k` | 2 | 0,99 | 2,8-3,3 kHz, 4,3-5,7 kHz, 6,2-6,6 kHz, 15,2-16,1 kHz |
| `l` | 1 | 1,00 | 2,8-3,3 kHz, 3,8-5,2 kHz |

Les classes les plus nombreuses ont pour médianes des bandes contiguës entre
3,3 et 5,7 kHz : `a` (3,8 à 5,7 kHz, 100 spectres), `d` (3,3 à 4,3 kHz),
`e`, `f`, `g`. Les classes d'un ou deux spectres ajoutent des bandes plus
graves (2,8 kHz) ou plus aiguës (15 à 16 kHz) : la coupure des plus longues
arêtes de l'arbre (lien simple) isole ces spectres rares, ce qui laisse moins
de classes pour les variantes fréquentes.

Les deux autres chants, `rougequeue-noir02.csv` et `rougequeue-noir03.csv`,
retrouvent les mêmes types de spectres. Chaque fichier est classé seul : ses
lettres sont numérotées dans l'ordre d'apparition, et une même lettre ne
désigne pas le même type d'un chant à l'autre. Ce sont les médianes qui se
comparent :

| Type (médiane) | 01 | 02 | 03 |
|---|---|---|---|
| 3,8-5,7 kHz | `a`, 100 spectres | `a`, 113 | |
| 3,3-4,3 kHz | `d`, 37 | `b`, 24 | `c`, 60 |
| 3,3-5,2 kHz | `g`, 14 | `c`, 22 | |
| 3,3-5,7 kHz | `f`, 16 | | `f`, 29 |
| 3,8-6,6 kHz | | | `g`, 44 |

Le type de 3,3 à 4,3 kHz est le seul présent, et nombreux, dans les trois
chants. Le troisième chant a un type plus large, de 3,8 à 6,6 kHz, surtout
dans sa deuxième partie (`gggg…`), et la classe `a` de 01 et de 02 y est
partagée entre `a` (4,3-4,7 kHz) et `g`. Chaque chant a aussi six ou sept
classes d'un seul spectre, propres à lui. Comparer les médianes par leur LSI
mesurerait ce qui se retrouve d'un chant à l'autre (c'est la méthode 3 de
Garland et al., *Behaviour* 149, 2012).

## Le code

Le code est la documentation. [lisp/rougequeue-noir-sv.lisp](../lisp/rougequeue-noir-sv.lisp)
se charge depuis le dossier du dépôt :

```lisp
(load "doc/lisp/rougequeue-noir-sv.lisp")
```

<!-- code: doc/lisp/rougequeue-noir-sv.lisp -->
```lisp
;;;; rougequeue-noir-sv.lisp
;;;;
;;;; Transcrire le chant d'un rougequeue noir à partir de son sonagramme exporté de Sonic
;;;; Visualiser : les spectres instantanés, réduits en bandes, deviennent des mots de 0 et
;;;; de 1 (présence ou absence d'énergie au-dessus d'un seuil), classés par class-sym.
;;;; C'est un remake de l'exemple de 2011 (doc/exemples/rougequeue-noir.md), à partir des
;;;; données du sonagramme et non de son image : les mots de 0 et de 1 simulent ce que
;;;; donnerait jp2a de l'image exportée de Sonic Visualiser (voir 3.), pour se remettre dans
;;;; les conditions de 2011.
;;;;
;;;; Les données : doc/data/rougequeue-noir*.csv, exportées de Sonic Visualiser 5.2.1
;;;; (calque du sonagramme, File > Export Annotation Layer) : une ligne d'en-tête (TIME, puis
;;;; la fréquence de chaque bande), puis une ligne par instant, le temps en secondes et
;;;; l'amplitude de chaque bande. Chaque fichier trouvé est analysé : un fichier ajouté
;;;; (une autre variante du chant) l'est aussi.
;;;;
;;;; (load "doc/lisp/rougequeue-noir-sv.lisp") affiche les résultats et écrit, pour chaque
;;;; fichier, son sonagramme en texte (doc/pictures/rougequeue-noir*.txt).
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
;; maximum du sonagramme, et le nombre de classes
(defparameter *regroupement* 11)
(defparameter *seuil-db* 40)
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

;;; 3. Les mots : 1 quand l'amplitude d'une bande est à moins de *seuil-db* du maximum du
;;; sonagramme, 0 sinon. Le seuil dépend du fichier (de son maximum), non d'un enregistrement
;;; de référence.
;;;
;;; C'est une simulation de jp2a. En 2011, le sonagramme était une image, que jp2a
;;; convertissait en texte en seuillant sa luminosité : chaque point devenait noir (.) ou
;;; blanc (x), et le seuil dépendait du réglage d'affichage du sonagramme. On pourrait faire
;;; de même avec l'image exportée de Sonic Visualiser (en SVG, avec ses tuiles PNG), mais ses
;;; couleurs et son bruit de fond rendent le seuil difficile à régler. On seuille donc
;;; directement les amplitudes, à 40 dB sous le maximum : la donnée est la même que celle
;;; de 2011, présence ou absence d'énergie, sans passer par l'image.
;;;
;;; Le seuil est écrit ici, car refrains n'a pas de fonction de seuil fixe : filt-quantize à
;;; 2 niveaux trouve son seuil dans les données (par les nuées dynamiques), et il est loin de
;;; 40 dB. Sur rougequeue-noir01.csv, il est vers -72 dB sur les amplitudes en dB (le bruit de
;;; fond compte alors comme de l'énergie), et vers -19 dB sur les amplitudes (seules les
;;; notes les plus fortes restent).

(defun mots (spectres)
  (let* ((reduits (mapcar #'bandes spectres))
         (maximum (reduce #'max (mapcar (lambda (b) (reduce #'max b)) reduits)))
         (seuil (* maximum (expt 10 (/ (- *seuil-db*) 20)))))
    (mapcar (lambda (b) (mapcar (lambda (a) (if (> a seuil) 1 0)) b)) reduits)))

;;; 4. Le sonagramme en texte, comme l'image de 2011 convertie par jp2a : une ligne par
;;; bande, les aigus en haut, une colonne par instant ; x pour le silence, . pour l'énergie

(defun image (mots)
  (with-output-to-string (s)
    (loop for k from (1- (length (first mots))) downto 0
          do (format s "~{~A~}~%" (mapcar (lambda (m) (if (= 1 (nth k m)) "." "x")) mots)))))

;; les bandes présentes d'un mot, en plages de fréquences contiguës : "3,3-4,3 kHz"
(defun plages (mot largeur)
  (let ((plages nil) debut)
    (loop for x in (append mot (list 0)) for k from 0
          do (cond ((and (= x 1) (null debut)) (setf debut k))
                   ((and (= x 0) debut)
                    (push (format nil "~,1F-~,1F kHz" (/ (* debut largeur) 1000) (/ (* k largeur) 1000)) plages)
                    (setf debut nil))))
    (or (nreverse plages) (list "silence"))))

;;; 5. La classification : class-sym, avec les coûts du patch de 2011 (insertion et
;;; suppression 1,5), le silence exclu (la classe 0), et la médiane de chaque classe

(defun analyse (file)
  (multiple-value-bind (frequences spectres) (lire-sonagramme file)
    (let* ((mots (mots spectres))
           (silence (make-list (length (first mots)) :initial-element 0))
           (largeur (* *regroupement* (- (second frequences) (first frequences)))))
      (multiple-value-bind (classes medianes)
          (class-sym mots *classes* :edit-nn :ins 1.5 :del 1.5 :excluded (list silence) :medians t)
        (format t "~&~%=== ~A~%" (file-namestring file))
        (format t "~D spectres de ~D bandes (~,2F Hz), en ~D bandes de ~D Hz ; ~D silences, ~D spectres distincts~%"
                (length spectres) (length frequences) (- (second frequences) (first frequences))
                (length silence) (round largeur) (count silence mots :test #'equal)
                (length (remove-duplicates mots :test #'equal)))
        ;; la transcription : - pour le silence, une lettre par classe
        (format t "Transcription :~%~{~A~}~%"
                (mapcar (lambda (c) (if (zerop c) "-" (string-downcase (num>alpha (1- c))))) classes))
        ;; chaque classe : son nombre de spectres, la cohésion (LSI moyen à la médiane) et les
        ;; bandes de sa médiane, en kHz
        (loop for (mediane lsi) in medianes
              for c from 0
              do (format t "~&  ~A : ~3D spectres, LSI ~,2F, médiane ~{~A~^, ~}~%"
                         (if (zerop c) "-" (string-downcase (num>alpha (1- c))))
                         (count c classes) lsi (plages mediane largeur)))
        (let ((texte (merge-pathnames (format nil "pictures/~A.txt" (pathname-name file)) *doc*)))
          (with-open-file (o texte :direction :output :if-exists :supersede)
            (write-string (image mots) o))
          (format t "~&Sonagramme en texte : doc/pictures/~A~%" (file-namestring texte)))
        ;; la transcription, pour d'autres exemples (rougequeue-noir-arbres.lisp)
        classes))))

(dolist (file (sort (directory (merge-pathnames "data/rougequeue-noir*.csv" *doc*)) #'string<
                    :key #'namestring))
  (analyse file))
```
<!-- /code -->

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
