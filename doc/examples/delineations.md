# Delineations: rhizomatic representation of a text

[Examples](../examples.md) · En français : [Délinéations : représentation rhizomatique d'un texte](../exemples/delineations.md)

F. Voisin, 2013.

*An analysis kept with its data in the [fv-morphologie](https://github.com/FredVoisin/fv-morphologie) repository; its principle is summarized here, to be rewritten as a Common Lisp example.*

1. A text (7-bit ASCII) is read into a list of words with `read-text`, all
   punctuation being separators (`:sep`) and words of less than four letters
   being removed (`:rem-test`).
2. Repeated words are removed; words differing by at most one character are
   considered identical, using the edit distance as test of
   `remove-duplicates`.
3. The semi-matrix of the edit distances between the words gives the minimum
   spanning tree (`graph-span`). `:uncom` maximizes the distance between
   words with uncommon characters, hoping to bring words with the same root
   closer.
4. `graph>dot` draws the tree with neato.

Variants: normalized edit distances with a logarithmic scaling of the
distances; the sum of the edit distance and of the distance between the
word frequencies ("the sum of two distances is a distance — is the product of
two distances a distance?"). For large graphs, prefer the svg format.
Computing the spanning tree can take from seconds to hours depending on the
number of elements (about 12 hours for the
[« Délinéations différentielles »](https://fredvoisin.com/articles/220-delineations-differentielles.html), 2013).
Data: [data/Alice.txt](../data/Alice.txt) (Lewis Carroll, public domain), and two protected
texts, kept in the fv-morphologie repository and not covered by the license of
refrains: an excerpt of Gilles Deleuze, *Différence et répétition*
([Difference&Repetition-utf8.txt](https://github.com/FredVoisin/fv-morphologie/blob/master/pwgl-legacy/tutorial/5.%20FV-exemples/data/Difference%26Repetition-utf8.txt)), and a quotation of
Arkady and Boris Strugatsky, *Roadside Picnic*
([Stalker.txt](https://github.com/FredVoisin/fv-morphologie/blob/master/pwgl-legacy/tutorial/5.%20FV-exemples/data/Stalker.txt)).

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](../LICENSE).
