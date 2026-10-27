# Transcription automatique d'un sonagramme : le rougequeue noir

[Exemples](../exemples.md) · In English: [Automatic transcription of a sonogram: the black redstart](../examples/black-redstart.md)

F. Voisin, 2011. Présenté aux Journées d'informatique musicale (JIM 2011),
à Saint-Étienne : Voisin, Frédéric, « Dissemblance et espaces
compositionnels », *Actes des Journées d'Informatique Musicale (JIM 2011)*,
Saint-Étienne, 2011, p. 191–197 (HAL
[hal-01612263](https://hal.science/hal-01612263v1)).

*Analyse conservée avec ses données dans le dépôt [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) ; son principe est résumé ici, et réécrit en Common Lisp à la fin de la page.*

Méthode originale de Frédéric Voisin : un sonagramme est considéré uniquement
comme une image ([data/rougequeue_noir.jpg](../data/rougequeue_noir.jpg) ; sonagramme
réalisé par Frédéric Voisin à partir d'un enregistrement de
André Bossus, [*Les chants d'oiseaux d'Europe occidentale*](https://www.delachauxetniestle.com/livre/les-chants-doiseaux-deurope-occidentale-3/9782603020036), Delachaux et Niestlé (livre avec CD)), dans laquelle on cherche des
motifs. Un sonagramme représente l'évolution du son dans le temps : une
succession d'instants décrits par leur spectre, chaque région étant plus ou
moins sombre selon son intensité.

1. L'image est convertie en texte avec
   [jp2a](http://jp2a.sourceforge.net/) ([data/rougequeue_noir.txt](../data/rougequeue_noir.txt)) : `x`
   pour le blanc, `.` pour le noir ; 45 lignes de 300 caractères pour
   5 secondes, soit 490 Hz et 17 ms par caractère.
2. Chaque ligne est découpée en ses symboles (`alpha>num`), et la liste de
   listes est pivotée, si bien que chaque colonne — le spectre instantané —
   devient un « mot ».
3. Les symboles sont transcodés en `0` et `1` pour la lisibilité
   (`transcode`).
4. Les mots sont classés avec `class-sym`, les mots silencieux étant exclus
   (`:excluded`), si bien que les silences comptent dans la transcription mais
   pas dans la classification. Le résultat est une suite de 12 classes de
   spectres instantanés, plus le silence.

Un second patch décompose le procédé : distances d'édition entre les mots
spectraux (coût d'insertion et de suppression de 1.5, pour augmenter les
distances dues aux transpositions), arbre de recouvrement minimal
(`graph-span`), tracé (`graph>dot`), et classification à partir de cet arbre
(`class-sym` avec `:mst`). Voir
[« Dissemblance et espaces compositionnels »](https://fredvoisin.com/articles/185-dissemblance-et-espaces-compositionnels.html)
et [« Arbres de recouvrement minimal de chants d'oiseaux »](https://fredvoisin.com/articles/186-arbres-de-recouvrement-minimal-de-chants-d-oiseaux.html).


## En Common Lisp

Le texte de l'image ([data/rougequeue_noir.txt](../data/rougequeue_noir.txt))
se lit avec `read-text` : en mode `:charcode`, chaque ligne devient la liste
des codes de ses caractères, et `:columns t` en donne les colonnes, les
spectres instantanés (300 « mots » de 45 codes, `x` et `.`). Les colonnes
blanches sont les silences, exclus de la classification :

```lisp
(let* ((spectres (read-text "doc/data/rougequeue_noir.txt" :mode :charcode :columns t))
       (silence (make-list 45 :initial-element (char-code #\x))))
  (class-sym spectres 12 :edit-nn :ins 1.5 :del 1.5 :excluded (list silence)))
;=> (0 0 ... 0 1 2 0 0 0 0 0 0 0 1 1 1 0 1 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 ...)
```

Le silence est la classe 0, et les classes de spectres suivent. Avec
`:medians t`, `class-sym` donne aussi le spectre typique de chaque classe (sa
chaîne médiane) et la cohésion de la classe.

La même démarche vaut pour un sonagramme importé de Sonic Visualiser ou
d'Audacity : voir *Importer un sonagramme*, à `read-text`, dans la
[documentation](../refrains.fr.md#read-text-file-key-mode-sep-rem-test-columns).

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
