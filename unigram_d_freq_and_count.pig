-- ngram_d_freq_and_count.pig
define calc_frequencies_and_count(A, key, F, C) returns void {
 grped = group $A by $key;
 ngram_f = foreach grped generate flatten(group), COUNT($A) as freq;
 store ngram_f into '$F';
 grped = group ngram_f all;
 ngram_c = foreach grped generate SUM(ngram_f.freq) as count; 
 store ngram_c into '$C';
}
unigrams = load 'unigrams_d' as (t1:chararray);
calc_frequencies_and_count(unigrams, t1, unigram_d_f, unigram_d_c);
bigrams = load 'bigrams_d' as (t1:chararray, t2:chararray);
calc_frequencies_and_count(bigrams, '(t1,t2)', bigram_d_f, bigram_d_c);
