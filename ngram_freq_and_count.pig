-- ngram_freq_and_count.pig
define calc_frequencies_and_count(A, key, F, C) returns void {
 grped = group $A by $key;
 ngram_f = foreach grped generate flatten(group), COUNT($A) as freq;
 store ngram_f into '$F';
 grped = group ngram_f all;
 ngram_c = foreach grped generate SUM(ngram_f.freq) as count; 
 store ngram_c into '$C';
}
unigrams = load 'unigrams' as (t1:chararray);
calc_frequencies_and_count(unigrams, t1, unigram_f, unigram_c);
bigrams = load 'bigrams' as (t1:chararray, t2:chararray);
calc_frequencies_and_count(bigrams, '(t1,t2)', bigram_f, bigram_c);
trigrams = load 'trigrams' as (t1:chararray, t2:chararray, t3:chararray);
calc_frequencies_and_count(trigrams, '(t1,t2,t3)', trigram_f, trigram_c);
