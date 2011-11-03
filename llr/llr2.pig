-- llr.pig

-- convert bigrams to two sets; one for where the term occurs as t1
-- the other for when the term occurs as t2
bigrams = load 'bigrams' as (t1:chararray, t2:chararray);
t1s = foreach bigrams generate t1;
t1s_g = group t1s by t1;
t1s_f = foreach t1s_g generate group as t1, COUNT(t1s) as freq;
t2s = foreach bigrams generate t2;
t2s_g = group t2s by t2;
t2s_f = foreach t2s_g generate group as t2, COUNT(t2s) as freq;

-- load up bigram frequencies and counts
--unigram_f = load 'unigram_f' as (t1:chararray, freq:long);
bigram_f = load 'bigram_f' as (t1:chararray, t2:chararray, freq:long);
bigram_c = load 'bigram_c' as (count:long);

-- join bigrams to unigrams to get freqs
bigram_joined_1 = join bigram_f by t1, t1s_f by t1;
bigram_joined_2 = join bigram_joined_1 by t2, t2s_f by t2;
freqs = foreach bigram_joined_2 {
 generate
  bigram_joined_1::bigram_f::t1 as t1,
  bigram_joined_1::bigram_f::t2 as t2,
  bigram_joined_1::bigram_f::freq as t1_t2_f,
  bigram_joined_1::t1s_f::freq as t1_f,
  t2s_f::freq as t2_f;
}
store freqs into 'freqs2';

-- convert freqs to k_values
k_values = foreach freqs { 
 generate 
  t1 as t1, 
  t2 as t2,
  t1_t2_f as k11, 
  t1_f - t1_t2_f as k12, 
  t2_f - t1_t2_f as k21, 
  bigram_c.count - (t1_f + t2_f - t1_t2_f) as k22;
}
store k_values into 'k_values2';

-- calculate log likelihood from k_values
register 'lib/mahout-math-0.6-SNAPSHOT.jar';
register 'lib/google-collections-1.0-rc2.jar';
define LLR InvokeForString('org.apache.mahout.math.stats.LogLikelihood.logLikelihoodRatio', 'long long long long');
llrs = foreach k_values generate t1 as t1, t2 as t2, LLR(k11,k12,k21,k22) as llr;
o = order llrs by llr desc;
store o into 'llrs2';
