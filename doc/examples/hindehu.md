# Quantizing an F0: *Hìndèhú*

[Examples](../examples.md) · En français : [Quantifier une F0 : *Hìndèhú*](../exemples/hindehu.md)

F. Voisin, 2026 (recording: S. Arom, V. Dehoux, S. Fürniss and F. Voisin, Central African Republic, 1989).

This example shows how to quantize raw data of pitch detection (F0), in order
to interpret them and transcribe them as a score.

It is a short extract (12 s) of *Hìndèhú* of the Aka of the Central African
Republic, where the voice alternates with the *mòbéké*, an instrument made of
two whistles cut from bamboo. The fundamental frequency (F0) and the
intensity of the recording were detected every 10 ms, with the YIN algorithm
(de Cheveigné and Kawahara, 2002), between 60 and 1000 Hz:
[data/hindehu-f0.txt](../data/hindehu-f0.txt), where each line gives the time
(in s), the F0 (in Hz, or 0 when the frame is not voiced) and the intensity
(in dB). The extract itself (filtered) is the file
[data/hindehu.mp3](../data/hindehu.mp3).

We quantize the F0 with the functions of refrains:
- on its own centres of attraction with `filt-quantize` (see
  [1.2](../refrains.md#12-filter)),
- on the whole and on a sliding window, then by notes with `class-num` and
  `histogram`,
- and we transcribe the quantized data with LilyPond (`seq>ly`), to the
  quarter tone, and in the ABC notation (`seq>abc`).

The code and its output are in French.

## 1. Overview of the data

The data are first read with the function `read-text`. Each frequency is
converted into a MIDI note, 69 + 12 log₂(f / 440), `nil` in the frames that
are not voiced; `seq>plot` draws a list of numbers as a flow of one value,
each frame at its rank:

```lisp
(defparameter *trames* (read-text "doc/data/hindehu-f0.txt"))   ; (temps F0 intensité)
(defparameter *notes* (mapcar (lambda (trame) (note-midi (second trame))) *trames*))

(seq>plot *notes* :height 14)
```
```
74.783
 **  **  *** *** **  ***  *****   **  *** *   **  **  **  *** *** **  **
*     **          ***   **    *****        ****        **    **    **** 
      **          *         **                                   **     
            **  **  **                           **  **  ** *           
******  ** *** * *   * *   *       **** ***    *   **        *  *      *
               *       *                           *                    
                                                                        
                 *                      *         *   *   *     * *     
           *        *                                                   
                *            *                  *                 *     
                                           *                            
        *                                                               
                                                                        
                                        *                               
38.24
4                                                                   1192
```

1203 frames, 1006 of them voiced. The notes make clear plateaus between 62
and 75, with a few isolated values much lower (down to 38). The intensity,
`(seq>plot (mapcar #'third *trames*) :height 8)`, shows notes separated by
troughs:

```
-8.9
                             *                                  **      
**  **  **       ***        **       *  **       *   *  **      ** * *  
*** ******* *** ******* ***********  ********************** *********** 
*** ******* *********** ******** **********  * * * ******** ** ****  ** 
***  * ****  * * *   ** ** *  *  * *   * *   * *** * *  ** **  *     * *
*  *    *  **  *    *  *   **      *   *       *   **   *  **  **      *
   **   *  **  **   *  **  **      **  **      **   *      **  **      *
*              **      **               *       *               *      *
-64.7
0                                                                   1202
```

## 2. The low values

`class-num` into 2 levels, with `:1d-centroids`, cuts at the largest gap
between the sorted values: it separates 25 low values from all the others,
which begin at 62. They are not changed; we only look at where they fall,
and with which intensity:

```lisp
(defparameter *registre*            ; la plus basse valeur de la classe haute
  (let* ((valeurs (remove nil *notes*))
         (classes (first (class-num valeurs 2 :1d-centroids :sort t))))
    (reduce #'min (loop for v in valeurs for c in classes when (= c 1) collect v))))
```
```
25 valeurs sous 62.0 (position, note, intensité) :
137 42.9 -48.8 |
192 51.3 -52.8 |
193 51.2 -54.7 |
268 50.3 -61.6 |
269 50.3 -61.0 |
270 50.3 -61.4 |
271 50.5 -61.6 |
294 55.5 -38.9 |
342 52.1 -54.5 |
496 50.6 -31.8 |
497 50.6 -31.7 |
666 38.2 -57.3 |
668 55.2 -59.6 |
714 46.7 -30.0 |
796 50.3 -56.8 |
797 50.3 -57.2 |
831 55.1 -39.0 |
832 55.6 -38.2 |
897 55.5 -34.9 |
963 55.3 -37.0 |
964 55.6 -33.3 |
1063 55.1 -54.0 |
1064 55.1 -55.7 |
1097 50.6 -31.1 |
1098 55.9 -30.5
```

They last one to four frames (10 to 40 ms) and all fall at the edge of a
note: at its end, weak (from -48 to -62 dB), when the note dies away, or at
the passage from one note to the next, louder (from -30 to -39 dB). They are
not held notes, rather transitions, where the detection sometimes locks onto
a subharmonic (55.5 is an octave below 67.5, 50.3 below 62.3).

## 3. Quantize

`filt-quantize` replaces each value by the centre of its class, by the time
spent (`:1d-centroids`, the dynamic clouds on all the frames) or by the turns
(`:mode :minmax`, `class-num` on the minima and maxima only, each turn
counting once, then each value at the nearest centre):

```lisp
(dolist (n '(5 6 7 8 9 10))
  (let ((duree (filt-quantize *notes* n))
        (retournements (filt-quantize *notes* n :mode :minmax)))
    ...))
```
```
 5 niveaux : par le temps passé 38.2 42.9 46.7 52.8 71.1 (erreur 3.16)
    par les retournements 38.2 42.9 46.7 53.1 70.9 (erreur 3.22)
 6 niveaux : par le temps passé 38.2 42.9 46.7 52.8 64.8 73.1 (erreur 1.51)
    par les retournements 38.2 42.9 46.7 53.1 64.1 73.1 (erreur 1.50)
 7 niveaux : par le temps passé 38.2 42.9 46.7 50.7 55.4 64.8 73.1 (erreur 1.46)
    par les retournements 38.2 42.9 46.7 50.9 55.3 64.1 73.1 (erreur 1.46)
 8 niveaux : par le temps passé 38.2 42.9 46.7 50.6 52.1 55.4 64.8 73.1 (erreur 1.46)
    par les retournements 38.2 42.9 46.7 50.9 55.3 63.1 67.7 73.3 (erreur 1.24)
 9 niveaux : par le temps passé 38.2 42.9 46.7 50.4 51.2 52.1 55.4 64.8 73.1 (erreur 1.46)
    par les retournements 38.2 42.9 46.7 50.6 52.1 55.3 63.1 67.7 73.3 (erreur 1.24)
10 niveaux : par le temps passé 38.2 42.9 46.7 50.4 51.2 52.1 55.4 64.8 71.3 74.4 (erreur 0.58)
    par les retournements 38.2 42.9 46.7 50.4 51.2 52.1 55.3 63.1 67.7 73.3 (erreur 1.24)
```

`:1d-centroids` starts from the largest gaps between the sorted values:
those that isolate the low values. With 5 levels, four go to these 25
frames, and only one (71.1) to all the notes; 10 levels are needed for the
notes to spread again, on 64.8, 71.3 and 74.4 (mean error of 0.58 semitone).
By the turns, the spread stays worse: a few isolated frames are enough to
take levels, because each turn counts, however brief.

On a sliding window of a quarter of the extract (`:window 1/4`, by steps of
half a window), with 10 levels:

```lisp
(filt-quantize *notes* 10 :window 1/4 :out :all)   ; la troisième valeur : (début fin centres)
```
```
fenêtre    0- 300 : 42.9 50.4 51.2 55.5 63.7 65.6 66.9 71.0 72.9 74.4
fenêtre  150- 450 : 50.4 51.2 52.1 55.5 62.6 64.3 65.2 66.8 71.4 74.4
fenêtre  300- 600 : 50.6 52.1 62.4 63.4 65.0 66.5 69.6 71.5 73.2 74.4
fenêtre  450- 750 : 38.2 46.7 50.6 55.2 62.7 64.0 69.4 71.5 73.4 74.4
fenêtre  600- 900 : 38.2 46.7 50.3 55.2 55.6 62.8 64.0 66.7 71.5 74.4
fenêtre  750-1050 : 50.3 55.4 62.3 63.1 64.1 65.3 66.6 71.7 73.0 74.4
fenêtre  900-1200 : 50.6 55.4 62.3 64.1 65.3 66.4 69.5 71.7 73.3 74.4
fenêtre  902-1202 : 50.6 55.4 62.3 64.1 65.3 66.4 69.5 71.7 73.3 74.4
```

The high levels, 74.4 and about 71.5, are the same everywhere: those of the
long notes. The others vary from one window to the other, with the low
values and the transitions each one contains.

## 4. By notes

Quantized frame by frame, the brief notes weigh little, and the weak
detections (the breath, the attacks, the endings) take levels. So we turn to
the notes: the very short minima (see [2](#2-the-low-values)) are ignored,
becoming `nil` without changing their octave; each run of voiced frames
between two silences is a note, of median pitch; the weak runs, below
-45 dB on average, are left out; then `class-num` classifies the notes, each
counting once, whatever its duration:

```lisp
(defparameter *notes-jouees*        ; (début fin hauteur intensité)
  (loop for (debut fin) in (suites *sans-minima*)
        for intensite = (moyenne (subseq *intensites* debut (1+ fin)))
        when (>= intensite *seuil*)
          collect (list debut fin (mediane (subseq *sans-minima* debut (1+ fin))) intensite)))

(defparameter *niveaux*
  (second (class-num (mapcar #'third *notes-jouees*) 5 :1d-centroids :sort t)))
```
```
23 notes ; 5 niveaux (nombre de notes, durée moyenne en ms) :
  64.60 : 2 notes, 195 ms
  66.62 : 4 notes, 152 ms
  69.50 : 2 notes, 155 ms
  71.65 : 6 notes, 713 ms
  74.29 : 9 notes, 441 ms
```

Five notes: two low and short (64.6 and 66.6), a short one a little below
the two high ones (69.5), and two high and long (71.6 and 74.3). The weak
runs left out (13, from 10 to 40 ms, from -48 to -62 dB) are clearly apart
from the notes (from -17 to -34 dB); only one is in between, at -42.5 dB (a
note of 60 ms at 1008), kept by the threshold.

`histogram` confirms it, without rounding the pitches: with a grid of
centres every quarter tone (`:thes`) and a test of tolerance of an eighth of
a tone (`:test`), it counts the frames around each centre:

```lisp
(histogram (remove nil *sans-minima*)
           :thes (loop for c from 62 to 75 by 1/2 collect c)
           :test (lambda (c x) (< (abs (- c x)) 1/4)))
```
```
au quart de ton : ((62 9) (125/2 25) (63 21) (127/2 12) (64 47) (129/2 25)
                   (65 3) (131/2 5) (66 21) (133/2 26) (67 38) (135/2 4) (68 0)
                   (137/2 0) (69 5) (139/2 26) (70 2) (141/2 15) (71 49)
                   (143/2 143) (72 58) (145/2 8) (73 8) (147/2 4) (74 68)
                   (149/2 358) (75 1))
```

The clearest peaks are between two tempered semitones: 74.5 (358 frames),
71.5 (143), 69.5 (26), then 66.5–67 and 64. The scale is not tempered: its
measured intervals, of 2.0, 2.9, 2.15 and 2.65 semitones, are roughly those
of a pentatonic scale without semitones (2, 3, 2, 3), placed about a quarter
tone above the tempered one at A 440.

The transcription then gives each frame (but the very short minima) the
nearest of the five levels, to the quarter tone, the centres staying fixed.
A voiced run may thus hold several notes linked without silence, that its
median alone hid. The segments shorter than 50 ms (5 frames), glides between
two notes or weak detections, become rests:

```lisp
(defparameter *transcription*
  (let* ((par-trame (mapcar (lambda (v) (when v (quart-de-ton (niveau v)))) *sans-minima*))
         (transcription (copy-list par-trame)))
    (dolist (s (segments par-trame) transcription)      ; (début fin niveau)
      (when (< (1+ (- (second s) (first s))) *duree-minimale*)
        (loop for i from (first s) to (second s) do (setf (nth i transcription) nil))))))
```
```
41 notes (début, durée en ms, niveau au quart de ton) :
   8  160 64.5
  24  280 74.5
  76  160 64.5
  92  150 74.5
 110  220 71.5
 144  160 64.5
 160  300 74.5
 213  140 66.5
 230  280 74.5
 280  130 66.5
 296  150 74.5
 311   50 69.5
 316  260 71.5
 345  160 66.5
 364  240 74.5
 414  190 71.5
 433  290 74.5
 482  140 69.5
 498  160 74.5
 514  520 71.5
 566  280 74.5
 617  200 64.5
 637  270 74.5
 681  190 64.5
 700  140 74.5
 715  500 71.5
 765  300 74.5
 816  150 66.5
 833  240 74.5
 881  150 66.5
 898  170 74.5
 915  280 71.5
 946  160 66.5
 965  310 74.5
1008   60 64.5
1015  190 71.5
1034  280 74.5
1080  170 69.5
1099  150 74.5
1114  490 71.5
1163  290 74.5
```

A figure comes back again and again: a brief low note (64.5, 66.5 or 69.5,
from 130 to 200 ms), then a leap to 74.5 (from 150 to 300 ms), often followed
by a longer 71.5 (up to 520 ms) and a return to 74.5.

![The detected notes (white), their quantization frame by frame into 10 levels (orange) and the transcription, at the nearest of the five levels, to the quarter tone (blue)](../pictures/hindehu.svg)

## 5. The transcription

Each note lasts its number of frames divided by 5, in sixteenths (a
sixteenth for 50 ms), the silences becoming rests. The five levels fall about
a quarter tone above the tempered semitones (at A 440): 64.5, 66.5, 69.5,
71.5 and 74.5. The two transcriptions that follow show the difference between
a notation to the quarter tone and a notation to the semitone.

**For LilyPond**, at the measured pitches: `seq>ly` rounds to the quarter
tone, and writes a quarter tone higher `ih` (74.5 is `dih''`, a D a quarter
tone higher); it makes the score if `lilypond` is installed:

```lisp
(seq>ly *transcription* :title "Hìndèhú" :rhythm t :unit 5 :out "doc/pictures/hindehu-partition.svg")
```

```lilypond
\version "2.24.0"
\header { title = "Hìndèhú" tagline = ##f }
\score {
  {
    \cadenzaOn
    r8 eih'8~ eih'16 dih''4~ dih''8 r4 r16 eih'8~ eih'16 dih''8~ dih''16 r16 bih'4 \bar ""
    r8 eih'8~ eih'16 dih''4~ dih''8 r4 r16 fisih'8~ fisih'16 r16 dih''4~ dih''8 r4 \bar ""
    fisih'8~ fisih'16 r16 dih''8~ dih''16 aih'16 bih'4~ bih'16 r16 fisih'8~ fisih'16 r16 \bar ""
    dih''4~ dih''16 r4 r16 bih'4 dih''4~ dih''8 r4 aih'8~ aih'16 r16 dih''8~ dih''16 \bar ""
    bih'2~ bih'8 dih''4~ dih''8 r4 r16 eih'4 dih''4~ dih''16 r8 r16 eih'4 dih''8~ dih''16 \bar ""
    r16 bih'2~ bih'8 dih''4~ dih''8 r4 fisih'8~ fisih'16 r16 dih''4~ dih''16 r4 r16 \bar ""
    fisih'8~ fisih'16 r16 dih''8~ dih''16 bih'4~ bih'8 r16 fisih'8~ fisih'16 r16 dih''4~ dih''8 \bar ""
    r8 eih'16 r16 bih'4 dih''4~ dih''8 r4 aih'8~ aih'16 r16 \bar ""
    dih''8~ dih''16 bih'2~ bih'8 dih''4~ dih''8 r8 \bar ""
  }
  \layout { \context { \Staff \accidentalStyle forget \omit TimeSignature } }
}
```

![The transcription of the extract of Hìndèhú, at the measured pitches, to the quarter tone](../pictures/hindehu-partition.svg)

**In ABC**, to the semitone: `seq>abc` rounds to the tempered semitone, which
would cut this scale between two semitones. The melody is therefore lowered
by a quarter tone: each note then falls on a semitone, E, F♯, A, B and D, and
the title says so:

```lisp
(defparameter *plus-bas* (mapcar (lambda (n) (when n (- n 1/2))) *transcription*))
(seq>abc *plus-bas* :title "Hìndèhú (un quart de ton plus bas)" :rhythm t :unit 5)
```

```abc
X:1
T:Hìndèhú (un quart de ton plus bas)
M:none
L:1/16
K:C
z2 E3 d6 z5 E3 d3 z B4 z2 E3 d6 z5 ^F3 z d6 z4
^F3 z d3 A B5 z ^F3 z d5 z5 B4 d6 z4 A3 z d3
B10 d6 z5 E4 d5 z3 E4 d3 z B10 d6 z4 ^F3 z d5 z5
^F3 z d3 B6 z ^F3 z d6 z2 E z B4 d6 z4 A3 z
d3 B10 d6 z2
```

([pictures/hindehu.abc](../pictures/hindehu.abc),
[pictures/hindehu-partition.ly](../pictures/hindehu-partition.ly))

## The code

The code is the documentation (its comments are in French).
[lisp/hindehu.lisp](../lisp/hindehu.lisp) is loaded from the directory of the
repository, prints the results and writes its figure (SVG), its
transcription (ABC, LilyPond) and, if `lilypond` is installed, its score
(SVG) in `doc/pictures/`:

```lisp
(load "doc/lisp/hindehu.lisp")
```

<!-- code: doc/lisp/hindehu.lisp -->
```lisp
;;;; hindehu.lisp
;;;;
;;;; Quantifier une fréquence fondamentale (F0) mesurée : un extrait de Hìndèhú, des Aka
;;;; (Centrafrique), voix et mòbéké alternés, enregistré par S. Arom, V. Dehoux,
;;;; S. Fürniss et F. Voisin en 1989.
;;;; La F0 a été mesurée toutes les 10 ms (algorithme YIN, de 60 à 1000 Hz), avec
;;;; l'intensité : doc/data/hindehu-f0.txt, une ligne par trame (temps en s, F0 en Hz ou 0
;;;; si la trame n'est pas voisée, intensité en dB). La F0, telle que détectée, est
;;;; quantifiée par filt-quantize, sur l'ensemble et sur une fenêtre glissante, puis par
;;;; notes, et transcrite en notation ABC et pour LilyPond.
;;;;
;;;; (load "doc/lisp/hindehu.lisp") affiche les résultats et écrit sa figure (svg), sa
;;;; transcription (abc, ly) et, si lilypond est installé, sa partition (svg) dans
;;;; doc/pictures/.
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

;;; 1. La détection : read-text lit chaque ligne comme une liste (temps F0 intensité)

(defparameter *trames*
  (read-text (namestring (merge-pathnames "data/hindehu-f0.txt" *doc*))))

(defun note-midi (f)
  "La fréquence F (Hz) en note MIDI (69 : la 440 Hz), NIL si F est 0 (trame non voisée)."
  (when (plusp f) (+ 69 (* 12 (log (/ f 440) 2)))))

;; les notes, une par trame de 10 ms, NIL dans les trames non voisées
(defparameter *notes* (mapcar (lambda (trame) (note-midi (second trame))) *trames*))
(defparameter *intensites* (mapcar #'third *trames*))

(format t "~&~D trames de 10 ms, ~D voisées ; notes MIDI de ~,1F à ~,1F~%"
        (length *notes*) (count-if #'identity *notes*)
        (reduce #'min (remove nil *notes*)) (reduce #'max (remove nil *notes*)))

;;; 2. Regarder : les notes, puis l'intensité

(seq>plot *notes* :height 14)
(seq>plot *intensites* :height 8)

;;; 3. Les valeurs basses : class-num en 2 niveaux coupe au plus grand écart entre les
;;; valeurs triées, qui sépare quelques valeurs basses de toutes les autres. Elles ne sont pas
;;; modifiées : on regarde seulement où elles tombent, combien de trames elles durent et avec
;;; quelle intensité

(defparameter *registre*
  ;; la plus basse valeur de la classe haute
  (let* ((valeurs (remove nil *notes*))
         (classes (first (class-num valeurs 2 :1d-centroids :sort t))))
    (reduce #'min (loop for v in valeurs for c in classes when (= c 1) collect v))))

(format t "~&~D valeurs sous ~,1F (position, note, intensité) :~%"
        (count-if (lambda (v) (and v (< v *registre*))) *notes*) *registre*)
(loop for v in *notes* for db in *intensites* for i from 0
      when (and v (< v *registre*))
        do (format t "~4D ~4,1F ~5,1F | " i v db))

;;; 4. Quantifier : par le temps passé (:1d-centroids) et par les retournements (:minmax),
;;; de 5 à 10 niveaux

(defun erreur (notes quantifiees)
  "L'écart moyen, en demi-tons, entre les notes et leur version quantifiée (NIL exclus)."
  (let ((ecarts (loop for a in notes for b in quantifiees when a collect (abs (- a b)))))
    (/ (reduce #'+ ecarts) (length ecarts))))

(defun niveaux (quantifiees)
  (sort (remove-duplicates (remove nil quantifiees) :test #'=) #'<))

(dolist (n '(5 6 7 8 9 10))
  (let ((duree (filt-quantize *notes* n))
        (retournements (filt-quantize *notes* n :mode :minmax)))
    (format t "~&~2D niveaux : par le temps passé ~{~,1F~^ ~} (erreur ~,2F)~%    par les retournements ~{~,1F~^ ~} (erreur ~,2F)~%"
            n (niveaux duree) (erreur *notes* duree)
            (niveaux retournements) (erreur *notes* retournements))))

;; sur une fenêtre glissante d'un quart (pas d'une demi-fenêtre) : les niveaux de chaque fenêtre
(multiple-value-bind (quantifiees classes fenetres) (filt-quantize *notes* 10 :window 1/4 :out :all)
  (declare (ignore quantifiees classes))
  (dolist (f fenetres)
    (format t "~&fenêtre ~4D-~4D : ~{~,1F~^ ~}~%" (first f) (second f) (third f))))

;;; 5. Par notes : quantifiées trame par trame, les notes brèves pèsent peu, et les détections
;;; faibles (la respiration, les attaques) prennent des niveaux. On passe donc aux notes :
;;; les minima très courts sont ignorés (NIL), chaque suite de trames voisées entre deux
;;; silences est une note, de hauteur médiane ; les suites faibles sont écartées ; puis
;;; class-num classe les notes, chacune comptant une fois, quelle que soit sa durée

(defparameter *sans-minima*
  (mapcar (lambda (v) (when (and v (>= v *registre*)) v)) *notes*))

(defun suites (valeurs)
  "Les suites (début fin) de VALEURS entre deux NIL."
  (let ((suites nil) (debut nil))
    (loop for v in (append valeurs (list nil)) for i from 0
          do (cond ((and v (null debut)) (setf debut i))
                   ((and (null v) debut) (push (list debut (1- i)) suites) (setf debut nil))))
    (nreverse suites)))

(defun mediane (valeurs)
  (nth (floor (length valeurs) 2) (sort (copy-list valeurs) #'<)))

(defun moyenne (valeurs) (/ (reduce #'+ valeurs) (length valeurs)))

;; les suites faibles (sous -45 dB en moyenne) sont la respiration, une attaque, une
;; extinction ; les autres sont les notes : (début fin hauteur intensité)
(defparameter *seuil* -45)

(defparameter *notes-jouees*
  (loop for (debut fin) in (suites *sans-minima*)
        for intensite = (moyenne (subseq *intensites* debut (1+ fin)))
        when (>= intensite *seuil*)
          collect (list debut fin (mediane (subseq *sans-minima* debut (1+ fin))) intensite)))

;; les cinq niveaux : class-num sur les hauteurs des notes
(defparameter *niveaux*
  (second (class-num (mapcar #'third *notes-jouees*) 5 :1d-centroids :sort t)))

(defun niveau (hauteur)
  "Le niveau le plus proche de HAUTEUR."
  (reduce (lambda (a b) (if (< (abs (- hauteur a)) (abs (- hauteur b))) a b)) *niveaux*))

(format t "~&~D notes ; 5 niveaux (nombre de notes, durée moyenne en ms) :~%" (length *notes-jouees*))
(dolist (n *niveaux*)
  (let ((durees (loop for (debut fin hauteur) in *notes-jouees*
                      when (= (niveau hauteur) n) collect (* 10 (1+ (- fin debut))))))
    (format t "  ~,2F : ~D notes, ~D ms~%" n (length durees) (round (moyenne durees)))))

;; la grille au quart de ton : histogram compte les trames autour de chaque centre (:thes), à
;; moins d'un huitième de ton (:test), sans arrondir les hauteurs
(defun quart-de-ton (x) (/ (round (* 2 x)) 2))

(format t "~&au quart de ton : ~S~%"
        (histogram (remove nil *sans-minima*)
                   :thes (loop for c from 62 to 75 by 1/2 collect c)
                   :test (lambda (c x) (< (abs (- c x)) 1/4))))

;; la transcription : chaque trame (hors minima très courts) prend le plus proche des cinq
;; niveaux, au quart de ton, centres fixes ; une suite voisée peut ainsi contenir plusieurs
;; notes enchaînées. Les segments de moins de 50 ms (5 trames) sont des glissements entre
;; deux notes ou des détections faibles : ils deviennent des silences

(defparameter *duree-minimale* 5)

(defun segments (valeurs)
  "Les suites (début fin valeur) de VALEURS égales consécutives, hors NIL."
  (let ((segments nil) (debut nil))
    (loop for v in (append valeurs (list nil)) for i from 0
          do (cond ((and v (null debut)) (setf debut i))
                   ((and debut (not (eql v (nth debut valeurs))))
                    (push (list debut (1- i) (nth debut valeurs)) segments)
                    (setf debut (when v i)))))
    (nreverse segments)))

(defparameter *transcription*
  (let* ((par-trame (mapcar (lambda (v) (when v (quart-de-ton (niveau v)))) *sans-minima*))
         (transcription (copy-list par-trame)))
    (dolist (s (segments par-trame) transcription)
      (when (< (1+ (- (second s) (first s))) *duree-minimale*)
        (loop for i from (first s) to (second s) do (setf (nth i transcription) nil))))))

(format t "~&~D notes (début, durée en ms, niveau au quart de ton) :~%~{~{~4D ~4D ~,1F~}~%~}"
        (length (segments *transcription*))
        (mapcar (lambda (s) (list (first s) (* 10 (1+ (- (second s) (first s)))) (float (third s))))
                (segments *transcription*)))

;;; 6. La transcription, avec le rythme : chaque note dure son nombre de trames divisé par 5, en
;;; doubles croches (une double croche pour 50 ms). Pour LilyPond, aux hauteurs mesurées, au
;;; quart de ton (ih : un quart de ton plus haut), avec la partition (svg) si lilypond est
;;; installé. En ABC, qui ne note que des demi-tons : la mélodie est descendue d'un quart de
;;; ton, pour que chaque note tombe sur un demi-ton tempéré (mi, fa#, la, si, ré), et le titre
;;; le précise

(format t "~&~A" (seq>ly *transcription* :title "Hìndèhú" :rhythm t :unit 5))
(handler-case (seq>ly *transcription* :title "Hìndèhú" :rhythm t :unit 5
                                      :out (merge-pathnames "pictures/hindehu-partition.svg" *doc*))
  (error (c) (format t "~&~A~%" c)))

(defparameter *plus-bas* (mapcar (lambda (n) (when n (- n 1/2))) *transcription*))
(defparameter *titre* "Hìndèhú (un quart de ton plus bas)")

(format t "~&~A" (seq>abc *plus-bas* :title *titre* :rhythm t :unit 5))
(seq>abc *plus-bas* :title *titre* :rhythm t :unit 5 :out (merge-pathnames "pictures/hindehu.abc" *doc*))

;;; 7. Une figure : les notes détectées (en blanc), leur quantification trame par trame en 10
;;; niveaux (en orange) et la transcription, au plus proche des cinq niveaux (en bleu)

(defun svg-polylines (stream valeurs largeur hauteur bas haut couleur epaisseur)
  "Trace les VALEURS, une par trame, chacune à son rang ; la ligne est coupée aux NIL."
  (let ((n (length valeurs)) (ligne nil))
    (flet ((tracer ()
             (when ligne
               (format stream "<polyline fill=\"none\" stroke=\"~A\" stroke-width=\"~A\" points=\"~{~{~,1F,~,1F~}~^ ~}\"/>~%"
                       couleur epaisseur (nreverse ligne))
               (setf ligne nil))))
      (loop for v in valeurs for i from 0
            do (if v
                   (push (list (* largeur (/ i (1- n))) (- hauteur (* hauteur (/ (- v bas) (- haut bas))))) ligne)
                   (tracer)))
      (tracer))))

(defun paliers (valeurs)
  "Les VALEURS, la première de chaque nouveau palier remplacée par NIL : tracées par
svg-polylines, les paliers restent horizontaux, sans les traits qui les relient."
  (loop for precedente = nil then v
        for v in valeurs
        collect (unless (and precedente v (/= precedente v)) v)))

(with-open-file (svg (merge-pathnames "pictures/hindehu.svg" *doc*)
                     :direction :output :if-exists :supersede)
  (let ((largeur 1000) (hauteur 300)
        (bas (reduce #'min (remove nil *notes*))) (haut (reduce #'max (remove nil *notes*))))
    (format svg "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"~D\" height=\"~D\" viewBox=\"-10 -10 ~D ~D\">~%"
            (+ largeur 20) (+ hauteur 20) (+ largeur 20) (+ hauteur 20))
    (format svg "<rect x=\"-10\" y=\"-10\" width=\"~D\" height=\"~D\" fill=\"black\"/>~%" (+ largeur 20) (+ hauteur 20))
    (svg-polylines svg *notes* largeur hauteur bas haut "white" 1)
    ;; les paliers, sans les traits qui les relient
    (svg-polylines svg (paliers (filt-quantize *notes* 10)) largeur hauteur bas haut "orange" 2)
    (svg-polylines svg (paliers *transcription*) largeur hauteur bas haut "#4fc3f7" 3)
    (format svg "</svg>~%")))
```
<!-- /code -->

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
