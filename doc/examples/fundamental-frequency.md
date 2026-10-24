# Segmentation of a fundamental frequency (F0)

[Examples](../examples.md) · En français : [Segmentation d'une fréquence fondamentale (F0)](../exemples/frequence-fondamentale.md)

F. Voisin, 2010-2013.

*An analysis kept with its data in the [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) repository; its principle is summarized here, to be rewritten as a Common Lisp example.*

Automatic segmentation of an F0 analysis made with Praat, by a minimal time
gap between segments. Only the read and write functions of refrains
are needed; the segments can be exported, for example as Max `coll` files
(`data/babil-chant-3-*.coll`, in [data/](../data/README.md)), from the F0 analysis
[data/babil-chant-3.pitch](../data/babil-chant-3.pitch).

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
