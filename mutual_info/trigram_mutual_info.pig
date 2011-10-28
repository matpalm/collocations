-- trigram_mutual_info.pig
set default_parallel 60;

-- load up frequencies and counts
unigram_f = load 'unigram_f' as (t1:chararray, freq:long);
unigram_c = load 'unigram_c' as (count:long);
bigram_f = load 'bigram_f' as (t1:chararray, t2:chararray, freq:long);
bigram_c = load 'bigram_c' as (count:long);
trigram_f = load 'trigram_f' as (t1:chararray, t2:chararray, t3:chararray, freq:long);
trigram_c = load 'trigram_c' as (count:long);

-- only consider trigrams with a support > 1000
trigram_f = filter trigram_f by freq > 100;

-- join; like a boss (a boss who doesn't know how to write idiomatic pig joins)
j1 = join trigram_f by t1, unigram_f by t1;
j1 = foreach j1 generate trigram_f::t1 as t1, t2 as t2, t3 as t3, trigram_f::freq as tri_f, unigram_f::freq as t1_f;
j2 = join j1 by t2, unigram_f by t1;
j2 = foreach j2 generate j1::t1 as t1, t2 as t2, t3 as t3, tri_f as tri_f, t1_f as t1_f, unigram_f::freq as t2_f;
j3 = join j2 by t3, unigram_f by t1;
j3 = foreach j3 generate j2::t1 as t1, t2 as t2, t3 as t3, tri_f as tri_f, t1_f as t1_f, t2_f as t2_f, unigram_f::freq as t3_f;
j4 = join j3 by (t1,t2), bigram_f by (t1,t2);
j4 = foreach j4 generate j3::t1 as t1, j3::t2 as t2, j3::t3 as t3, tri_f as tri_f, t1_f as t1_f, t2_f as t2_f, t3_f as t3_f, bigram_f::freq as t1_t2_f;
j5 = join j4 by (t2,t3), bigram_f by (t1,t2);
j5 = foreach j5 generate j4::t1 as t1, j4::t2 as t2, j4::t3 as t3, tri_f as tri_f, t1_f as t1_f, t2_f as t2_f, t3_f as t3_f, t1_t2_f as t1_t2_f, bigram_f::freq as t2_t3_f;

-- mi = log2( p(x,y,z) / (p(x)*p(y)*p(z) + p(x)*p(y,z) + p(x,y)*p(z)) )
mutual_info = foreach j5 {
 px = (double)t1_f / unigram_c.count;
 py = (double)t2_f / unigram_c.count;
 pz = (double)t3_f / unigram_c.count;
 pxy = (double)t1_t2_f / bigram_c.count;
 pyz = (double)t2_t3_f / bigram_c.count;

 dep_pxyz = (double)tri_f / trigram_c.count;

 px_py_pz = px * py * pz;
 px_pyz   = px * pyz;
 pxy_pz   = pxy * pz;
 indep_pxyz = px_py_pz + px_pyz + pxy_pz;
 
 mi = LOG(dep_pxyz / indep_pxyz) / LOG(2);
 
 generate t1,t2,t3, tri_f, mi as mi;
}

-- sort and store
positive_mutual_info = filter mutual_info by mi>0;
sorted = order positive_mutual_info by mi desc;
store sorted into 'trigram_mutual_info';

