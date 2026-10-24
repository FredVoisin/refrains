# Automatic transcription of a sonogram: the black redstart

[Examples](../examples.md) · En français : [Transcription automatique d'un sonagramme : le rougequeue noir](../exemples/rougequeue-noir.md)

F. Voisin, 2011.

*An analysis kept with its data in the [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) repository; its principle is summarized here, to be rewritten as a Common Lisp example.*

An original method by Frédéric Voisin: a sonogram is considered only as an
image (`data/rougequeue_noir.jpg`), in which motifs are looked for. A
sonogram represents the evolution of sound in time: a succession of instants
described by their spectrum, each region darkened according to its
intensity.

1. The image is converted into text with
   [jp2a](http://jp2a.sourceforge.net/) (`data/rougequeue_noir.txt`): `x`
   for white, `.` for black; 45 lines of 300 characters for 5 seconds, i.e.
   490 Hz and 17 ms per character.
2. Each line is split into its symbols (`alpha>num`), and the list of lists
   is rotated, so that each column — the instantaneous spectrum — becomes a
   "word".
3. The symbols are transcoded to `0` and `1` for readability (`transcode`).
4. The words are classified with `class-sym`, the silent words being
   excluded (`:excluded`), so that silences count in the transcription but
   not in the classification. The result is a sequence of 12 classes of
   instantaneous spectra, plus silence.

A second patch decomposes the process: edit distances between the spectral
words (insertion and deletion cost 1.5, to increase the distances due to
transpositions), minimum spanning tree (`graph-span`), drawing (`graph>dot`),
and classification from that tree (`class-sym` with `:mst`). See
[« Dissemblance et espaces compositionnels »](https://fredvoisin.com/articles/185-dissemblance-et-espaces-compositionnels.html)
and [« Arbres de recouvrement minimal de chants d'oiseaux »](https://fredvoisin.com/articles/186-arbres-de-recouvrement-minimal-de-chants-d-oiseaux.html).

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
