# Classification, quantification et entropie : *Zoboko*

[Exemples](../exemples.md) · In English: [Classification, quantization and entropy: *Zoboko*](../examples/zoboko.md)

F. Voisin, 2009. Voir
[« À propos de la polyrythmie du *Zoboko* des Aka »](https://fredvoisin.com/articles/105-a-propos-de-la-polyrythmie-du-zoboko-des-aka.html)
(fredvoisin.com, 6 juin 2009).

*Analyse conservée avec ses données dans le dépôt [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) ; son principe est résumé ici, en attendant d'être réécrit sous forme d'exemple Common Lisp.*

Transcription automatique d'un passage de la partie rythmique du *Zoboko*,
pièce instrumentale polyrythmique du répertoire des Aka de Centrafrique.
Cette partie, appelée *diketo*, est jouée avec deux machettes entrechoquées.
Les intensités de l'enregistrement (dB) ont été mesurées avec
[Praat](https://www.praat.org) dans un fichier texte à deux colonnes (temps,
amplitude) : [data/diketo-db.txt](../data/diketo-db.txt). Les enregistrements ont été réalisés à
Mongumba (République centrafricaine) le 5 mars 1990 par Simha Arom, Vincent
Dehoux, Susanne Fürniss, Gilles Léothaud et Frédéric Voisin ; la partie du
*diketo* a été enregistrée séparément, en *re-recording*.

Pour chaque seuil d'intensité, du minimum (18 dB) au maximum (46 dB), par pas
de 1 dB :

1. garder les amplitudes supérieures au seuil, avec leurs dates ;
2. calculer le temps entre pics successifs ;
3. classer ces intervalles de temps en trois classes (`class-num`) ;
4. calculer l'entropie de la classification (`entropy`).

La structure la plus cohérente est supposée se trouver là où l'entropie est
la plus basse (néguentropie) : à 39 dB (entropie 0.8), les valeurs nulles
correspondant à des résultats vides étant écartées.

---

Cette documentation est placée sous licence
[Creative Commons Attribution 4.0 International (CC BY 4.0)](../LICENSE).
