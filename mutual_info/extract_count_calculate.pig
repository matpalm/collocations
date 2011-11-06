-- pig -f extract_count_calculate.pig -p input=sentences -p output=bigram_mutual_info

-- extract ngrams
define ngrams(S, n) returns NG {
 define ngrams `python ngrams.py $n` ship('ngrams.py');
 $NG = stream $S through ngrams;
}
sentences = load '$input' as (sentence:chararray);
unigrams = ngrams(sentences, 1);
unigrams = foreach unigrams generate $0 as t1;
bigrams = ngrams(sentences, 2);
bigrams = foreach bigrams generate $0 as t1, $1 as t2;

-- frequencies and counts
define calc_frequencies(A, key) returns F {
 grped = group $A by $key;
 $F = foreach grped generate flatten(group), COUNT($A) as freq;
}
define calc_total_count(F) returns C {
 grped = group $F all;
 $C = foreach grped generate SUM($F.freq) as count;
}
unigram_f = calc_frequencies(unigrams, t1);
unigram_f = foreach unigram_f generate group as t1, freq;
unigram_c = calc_total_count(unigram_f);
bigram_f  = calc_frequencies(bigrams, '(t1,t2)');
bigram_f = foreach bigram_f generate $0 as t1, $1 as t2, freq;
bigram_c  = calc_total_count(bigram_f);

-- mutual info

-- only process bigrams with a support of 5000
bigram_f = filter bigram_f by freq>5000;

-- bigram log likelihood
-- log2( p(a,b) / ( p(a) * p(b) ) )
bigram_joined_1 = join bigram_f by t1, unigram_f by t1;
bigram_joined_2 = join bigram_joined_1 by t2, unigram_f by t1;
mutual_info = foreach bigram_joined_2 {
 t1 = bigram_joined_1::bigram_f::t1;
 t2 = bigram_joined_1::bigram_f::t2;
 t1_t2_f = bigram_joined_1::bigram_f::freq;
 t1_f = bigram_joined_1::unigram_f::freq;
 t2_f = unigram_f::freq;

 pxy = (double)t1_t2_f / bigram_c.count;
 px = (double)t1_f / unigram_c.count;
 py = (double)t2_f / unigram_c.count;
 mutual_info = LOG(pxy / (px * py)) / LOG(2);

 generate t1, t2, t1_t2_f, mutual_info as mi;
}

-- sort and store
sorted = order mutual_info by mi desc;
top10k = limit sorted 10000;
store top10k into '$output';


