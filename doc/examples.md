# refrains: examples

The reference version of this document is in French, see: [exemples.md](exemples.md)

Examples of use of refrains, one per file. The documentation of each function is in [refrains.md](refrains.md), and the list of the functions in [refrains-functions.md](refrains-functions.md).

- [Trees of refrains](examples/function-trees.md): the functions of refrains linked by their names and by the vocabulary of their documentation, as minimum spanning trees and dendrograms (in Common Lisp).
- [Trees of neural networks](examples/neuromuse.md): analysis of a multilayer perceptron and of a self-organizing map of [neuromuse](https://github.com/FredVoisin/neuromuse) studied with refrains: skeleton of the connections, resemblance of the neurons, topology of the map, and sequences of winning neurons of a chaffinch song compared by edit distance (in Common Lisp).
- [Comparing neural networks](examples/neuromuse-comparaison.md): six multilayer perceptrons and three self-organizing maps of [neuromuse](https://github.com/FredVoisin/neuromuse) learn the same thing from different draws, compared before and after learning by what does not depend on the numbering of their neurons: geometry of the hidden layer, roles of the neurons, topology and segmentation of the song (in Common Lisp).
- [Delineations: rhizomatic representation of a text](examples/delineations.md) (F. Voisin, 2013): the minimum spanning tree of the words of a text, by their edit distance (`graph-span`, `graph>dot`).
- [Automatic transcription of a sonogram: the black redstart](examples/black-redstart.md) (F. Voisin, JIM 2011, Saint-Étienne): transcribing the song of a bird by classifying the instantaneous spectra of a sonogram read as an image (`class-sym`).
- [Contrastive analysis: marks and resemblance](examples/contrastive-analysis.md) (F. Voisin, 2010): treating as one motif segments close in edit distance (`mark-list`).
- [Quantization](examples/quantization.md) (F. Voisin, 2010): quantizing a flow on its own centres of attraction (`class-num`).
- [Segmentation of a fundamental frequency (F0)](examples/fundamental-frequency.md) (F. Voisin, 2010-2013): cutting an analysis of fundamental frequency (F0) into segments, exported for Max.
- [Classification, quantization and entropy: *Zoboko*](examples/zoboko.md) (F. Voisin, 2009): in the rhythmic part of a piece of the Aka of Central Africa, the threshold of intensity that gives the most coherent structure (`class-num`, `entropy`).

---

This documentation is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](LICENSE).
