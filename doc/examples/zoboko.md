# Classification, quantization and entropy: *Zoboko*

[Examples](../examples.md) · En français : [Classification, quantification et entropie : *Zoboko*](../exemples/zoboko.md)

Frédéric Voisin, 2009. See
[« À propos de la polyrythmie du *Zoboko* des Aka »](https://fredvoisin.com/articles/105-a-propos-de-la-polyrythmie-du-zoboko-des-aka.html)
(fredvoisin.com, 6 June 2009, in French).

*An analysis kept with its data in the [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) repository; its principle is summarized here, to be rewritten as a Common Lisp example.*

Automatic transcription of a passage from the rhythmic part of *Zoboko*, a
polyrhythmic instrumental piece from the repertoire of the Aka of Central
Africa. This part, called *diketo*, is played by two machetes struck
together. The intensities of the recording (dB) were measured with
[Praat](https://www.praat.org) into a two-column text file (time,
amplitude): `data/diketo-db.txt`. The recordings were made at Mongumba
(Central African Republic) on 5 March 1990 by Simha Arom, Vincent Dehoux,
Susanne Fürniss, Gilles Léothaud and Frédéric Voisin; the *diketo* part was
recorded separately, by *re-recording*.

For each intensity threshold, from the minimum (18 dB) to the maximum
(46 dB) by steps of 1 dB:

1. keep the amplitudes above the threshold, with their dates;
2. compute the time between successive peaks;
3. classify these time intervals into three classes (`class-num`);
4. compute the entropy of the classification (`entropy`).

The most coherent structure is assumed to be found where the entropy is
lowest (negentropy): at 39 dB (entropy 0.8), the null values corresponding to
empty results being discarded.

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
