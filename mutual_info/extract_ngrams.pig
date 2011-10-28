 -- extract_ngrams.pig
define ngrams(s, n, out) returns void {
 define ngrams `python ngrams.py $n` ship('ngrams.py');
 ngrams = stream $s through ngrams;
 store ngrams into '$out';
}
sentences = load 'sentences' as (sentence:chararray);
ngrams(sentences, 1, 'unigrams');
ngrams(sentences, 2, 'bigrams');
ngrams(sentences, 3, 'trigrams');

