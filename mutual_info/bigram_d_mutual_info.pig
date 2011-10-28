-- bigram_d_mutual_info.pig
set default_parallel 60;

-- load up frequencies and counts
unigram_f = load 'unigram_d_f' as (t1:chararray, freq:long);
unigram_c = load 'unigram_d_c' as (count:long);
bigram_f = load 'bigram_d_f' as (t1:chararray, t2:chararray, freq:long);
bigram_c = load 'bigram_d_c' as (count:long);

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
positive_mutual_info = filter mutual_info by mi>0;
sorted = order positive_mutual_info by mi desc;
store sorted into 'bigram_d_mutual_info';


