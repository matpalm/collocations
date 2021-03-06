see <a href="http://matpalm.com/blog/2011/10/22/collocations_1">my blog post</a> for more info

## preprocess

### stanford parser

    cd /mnt
    wget http://nlp.stanford.edu/downloads/stanford-parser-2011-09-14.tgz
    tar zxf stanford-parser-2011-09-14.tgz

### freebase dump

    wget http://download.freebase.com/wex/latest/freebase-wex-2011-09-30-articles.tsv.bz2  # 7/8gb

### freebase just text to articles without newlines or <, >

    bzcat freebase-wex-2011-09-30-articles.tsv.bz2 | cut -f5 | perl -plne's/\\n\\n/ /g' | sed -es/[\<\>]/\ /g > articles

### extract sentences

    java -classpath /mnt/stanford-parser-2011-09-14/stanford-parser.jar edu.stanford.nlp.process.DocumentPreprocessor articles > sentences

### move to hdfs

    hadoop fs -mkdir sentences
    hadoop fs -copyFromLocal sentences sentences/sentences

### filter out long "terms", urls and terms without at least one alpha numeric

    -- clean_sentences.pig
    s = load 'sentences' as (s:chararray);
    define chw `python cut_huge_words.py` ship('cut_huge_words.py');
    s = stream s through chw;
    define fsnc `python filter_single_non_char.py` ship('filter_single_non_char.py');
    s = stream s through fsnc;
    store s into 'sentences.filtered'

note! seems to be the same sentences repeated 2-3 times (???)
wrote a pig job to get rid of them...

<pre>
 -- distinct_sentences.pig
 s = load 'sentences';
 d = distinct s;
 store d into 'sentences.distinct';
</pre>

## extract ngrams

### extract 

<pre>
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
</pre>

### sanity check frequency of unigram lengths..

<pre>
   -- cat unigram_length_freq.pig
   set default_parallel 24;
   register 'pig/piggybank.jar';
   define len org.apache.pig.piggybank.evaluation.string.LENGTH;
   unigrams = load 'unigrams' as (t1:chararray);
   lengths = foreach unigrams generate len(t1) as length;
   grped = group lengths by length;
   freqs = foreach grped generate group as length, COUNT(lengths) as freq;
   store freqs into 'length_freqs';

   $ hfs -cat /user/hadoop/length_freqs/*  |sort -n
   1       180552974
   2       218916294
   3       229329881
   4       171347574
   5       154830964
   6       111346344
   7       104234492
   8       79782236
   9       54408813
   10      36727785
   11      19836470
   12      12233497
   13      6588796
   14      3133951
   15      1394993
   ...
   93      14
   94      18
   95      39
   96      25
   97      14
   98      13
   99      15
   100     25
</pre>

### n-gram quantiles

get datafu

<pre>
wget https://github.com/downloads/linkedin/datafu/datafu-0.0.1.tar.gz
tar zxf datafu-0.0.1.tar.gz
cd datafu-0.0.1
ant
</pre>

extract quantiles

( if i was to redo this i'd use StreamingQuantile to avoid the sort )

<pre>
-- quantiles.pig
set default_parallel 36;
register 'datafu-0.0.1/dist/datafu-0.0.1.jar';
define percentiles datafu.pig.stats.Quantile('0.9','0.91','0.92','0.93','0.94','0.95','0.96','0.97','0.98','0.99','0.991','0.992','0.993','0.994','0.995','0.996','0.997','0.998','0.999','1.0');
define quantiles(A, key, out) returns void {
 grped_f = group $A by $key;
 freqs = foreach grped_f generate COUNT($A) as freq;
 grped = group freqs all; 
 quantiles = foreach grped {          
  sorted = order freqs by freq;
  generate flatten(percentiles(sorted));
 }
 store quantiles into '$out';
}
unigrams = load 'unigrams' as (t1:chararray);
quantiles(unigrams, t1, unigrams_quantiles);
bigrams = load 'bigrams' as (t1:chararray, t2:chararray);
quantiles(bigrams, '(t1,t2)', bigrams_quantiles);
</pre>

result

<pre>
$ hfs -cat unigrams_quantiles/part-r-00000
12.0    14.0    16.0    20.0    25.0    32.0    45.0    69.0    129.0   392.0   465.0   562.0   693.0   882.0   1177.0  1679.0  2574.0  4703.0  12582.0 7.4528781E7
hadoop@ip-10-17-216-123:~$ hfs -cat bigrams_quantiles/part-r-00000
6.0     7.0     8.0     10.0    11.0    14.0    19.0    27.0    43.0    99.0    112.0   129.0   151.0   180.0   222.0   286.0   396.0   621.0   1303.0  1.2184383E7
</pre>

### extract ngram_frequecy and counts

<pre>
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
calc_frequencies_and_count(trigrams, '(t1,t2,t3)', trigram_f, trigram_c)
</pre>

### high frequency ngrams 

<pre>
-- top_ngrams_by_freq.pig
n = load 'unigram_f' as (t1:chararray, freq:long);
s = order n by freq desc;
s = limit s by 10;
store s into 'unigram_top10';
n = load 'bigram_f' as (t1:chararray, t2:chararray, freq:long);
s = order n by freq desc;
s = limit s by 10;
store s into 'bigram_top10';
n = load 'trigram_f' as (t1:chararray, t2:chararray, t3:chararray, freq:long);
s = order n by freq desc;
s = limit s by 10;
store s into 'trigram_top10';
</pre>

result

<pre>
$ hfs -cat /user/hadoop/unigram_top10/*
the  74528781
,    70605655
.    54902186
of   41340440
and  34962970
in   30111358
to   24904598
a    24600822
was  14322281
is   13485661

$ hfs -cat /user/hadoop/bigram_top10/*
of the  12184383
in the  8042527
, and   7223201
, the   4756776
to the  4077474
is a    2913727
and the 2740848
on the  2657395
| |     2615179
for the 2395016

$ hfs -cat /user/hadoop/trigram_top10/*
| | |             805094
, and the 	  767814
one of the 	  617374
-RRB- is a 	  562709
| - | 	 	  516652
as well as 	  504222
the United States 504124
part of the       413992
| align =         352575
-RRB- , and       290050
</pre>

## bigram mutual info

<pre>
-- bigram_mutual_info.pig

-- load up frequencies and counts
unigram_f = load 'unigram_f' as (t1:chararray, freq:long);
unigram_c = load 'unigram_c' as (count:long);
bigram_f = load 'bigram_f' as (t1:chararray, t2:chararray, freq:long);
bigram_c = load 'bigram_c' as (count:long);

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
store sorted into 'bigram_mutual_info';

-- dump top 10k, support 5,000
sorted = order bigram_mi by mi desc;
top_10k_s5k = limit sorted 10000;
store top_10k_s5k into 'bigram_mutual_info__top10k_s5k.gz';

-- dump top 10k, support 50,000
sup = filter bigram_mi by t1_t2_f > 50000;
sorted = order sup by mi desc;
top_10k = limit sorted 10000;
store top_10k into 'bigram_mutual_info__top10k_s50k.gz';

-- dump top 10k, support 250,000
sup = filter bigram_mi by t1_t2_f > 250000;
sorted = order sup by mi desc;
top_10k = limit sorted 10000;
store top_10k into 'bigram_mutual_info__top10k_s250k.gz';
</pre>

result

<pre>
$ hfs -cat /user/hadoop/bigram_mutual_info__top10k_s5k.gz/part-r-00000.gz | gunzip | head
mutual_info             t1      t2        t12_f   bigram_c        t1_f    t2_f    unigram_c
12.397738367262338      Burkina Faso      5417    1331695519      5687    5679    1386868488
12.136124155313361      Rotten  Tomatoes  5695    1331695519      7264    6072    1386868488
12.113289381980444      Kuala   Lumpur    6441    1331695519      7847    6504    1386868488
11.72023878663395       Tel     Aviv      9106    1331695519      11212   9534    1386868488
11.679730019305111      Baton   Rouge     5587    1331695519      6219    10982   1386868488
11.396162983156035      Figure  Skating   5518    1331695519      11164   8023    1386868488
11.391231883436134      Lok     Sabha     7429    1331695519      8908    13604   1386868488
11.169792546284583      Notre   Dame      13516   1331695519      13845   19872   1386868488
11.127412869936919      Buenos  Aires     20595   1331695519      20908   20919   1386868488
11.038927639150135      gastropod mollusk 19335   1331695519      22195   20212   1386868488wordsplitter.py

hadoop@ip-10-17-216-123:~$ hfs -cat /user/hadoop/bigram_mutual_info__top10k_s50k.gz/part-r-00000.gz | gunzip | head
9.752548540247900       Hong    Kong    67506   1331695519      74127   76481   1386868488
9.100741649871587       Los     Angeles 134207  1331695519      158036  136862  1386868488
9.04193275319404        Summer  Olympics 50573   1331695519      92912   93036   1386868488
8.867283927960393       Prime   Minister 64629   1331695519      79612   165235  1386868488
8.834295951388988       median  income  106184  1331695519      116870  191133  1386868488
8.697542938085967       Supreme Court   56347   1331695519      72797   186693  1386868488
8.58353850698748        \       t       110564  1331695519      232890  128335  1386868488
8.534865092105356       square  mile    57875   1331695519      175459  93613   1386868488
8.349655012939401       San     Francisco 83370   1331695519      277709  102536  1386868488
8.314182119206784       Air     Force   92015   1331695519      218205  149230  1386868488

hadoop@ip-10-17-216-123:~$ hfs -cat /user/hadoop/bigram_mutual_info__top10k_s250k.gz/part-r-00000.gz | gunzip | head
7.226096947140881       United  States  719664  1331695519      1005315 752037  1386868488
7.125046765096364       align   =       401440  1331695519      404672  1152961 1386868488
7.004555445216198       New     York    512842  1331695519      1209924 555714  1386868488
5.8550085688353946      did     not     310806  1331695519      545985  2356006 1386868488
5.708106314799068       more    than    273197  1331695519      1346085 972904  1386868488
5.19926746463544        |       align   352579  1331695519      6947135 404672  1386868488
5.176074269794974       can     be      492695  1331695519      1235963 3253103 1386868488
5.158784004550341       have    been    497399  1331695519      2157275 1914404 1386868488
5.051402270277741       has     been    650292  1331695519      3140106 1914404 1386868488
4.813860313764799       =       ``      638122  1331695519      1152961 6488163 1386868488

</pre>

## trigram mutual info

<pre>
-- trigram_mutual_info.pig

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
</pre>

result (support 100)

<pre>
Rychnov	nad	Kněžnou	118	22.424602293608007
DoualaPays	:	CamerounAdresse	102	22.406178326732338
Bajaga		i	Instruktori	118	22.385818095638346
d'activité	:	Principaux	128	22.367493053820052
Feasa		ar	Éirinn		121	22.214224197726296
Séré		de	Rivières	109	22.15457802657505
Tiako		I	Madagasikara	134	22.149050193285223
African-Eurasian	Migratory	Waterbirds	145	22.103210375266972
Kw			`		alaams		110	22.09419756064452
Ponts			et		Chaussées	106	22.084725134502357
</pre>

result (support 1000)

<pre>
Abdu	`	l-Bahá	1011	549844.1721224862
Dravida	Munnetra	Kazhagam	1043	519490.7200429379
Ab	urbe		condita		1059	392353.38202227355
Dar	es		Salaam		1130	280500.2163137233
Kitts	and		Nevis		1095	266394.29635043273
Procter	&		Gamble		1255	256374.4275852869
Antigua	and		Barbuda		1290	245226.03987268283
agnostic		or		atheist	1068	235635.2233948117
Vasco			da		Gama	1401	224613.90052744994
Ku			Klux		Klan	1944	224200.36813564494
</pre>

## graphs

<pre>

sh>
 hfs -cat bigram_mutual_info/* | ./reparse_ngram_mi.py > bigram_mutual_info.tsv
 hfs -cat trigram_mutual_info/* | ./reparse_ngram_mi.py > trigram_mutual_info.tsv

R>
 b = read.delim('bigram_mutual_info.tsv', sep="\t", header=F)
 ggplot(b, aes(log10(V2),V3)) + geom_point(alpha=1/5) + xlab('log bigram freq') + ylab('mutual info') + opts(title="bigram mutual info")
 t = read.delim('trigram_mutual_info.tsv', sep="\t", header=F)
 t = t[t$V2>750,]
 ggplot(t, aes(log10(V2),V3)) + geom_point(alpha=1/5) + xlab('log trigram freq') + ylab('mutual info') + opts(title="trigram mutual info")
</pre>

## pareto front

<pre>
hfs -cat /user/hadoop/trigram_mutual_info/* | ./reparse_ngram_mi.py > trigram_mutual_info.tsv
cat trigram_mutual_info.tsv | ./pareto.py > trigram_mutual_info.pareto.tsv
</pre>

## bigrams at a distance

first filter out bracket tokens (-LRB- and -RRB-) and any word that doesnt have at least one letter

<pre>
hadoop jar ~/contrib/streaming/hadoop-streaming.jar \
 -input sentences_sans_url_long_words -output sentences_single_char_filtered \
 -mapper filter_single_non_char.py -file filter_single_non_char.py \
 -numReduceTasks 0
</pre>

rebuild unigrams & bigrams

<pre>
hadoop jar ~/contrib/streaming/hadoop-streaming.jar \
 -input sentences_single_char_filtered -output unigrams_d \
 -mapper "ngrams.py 1" -file ngrams.py \
 -numReduceTasks 0
hadoop jar ~/contrib/streaming/hadoop-streaming.jar \
 -input sentences_single_char_filtered -output bigrams_d \
 -mapper bigrams_at_a_distance.py -file bigrams_at_a_distance.py \
 -numReduceTasks 0
</pre>

from 55,172,969 sentences to 3,154,200,111 bigrams

re calc _f and _c for unigrams_ and bigrams_d

<pre>
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
</pre>

result

<pre>
unigram_d_f (dus) 95,097,917
unigram_d_c = 1,161,564,928
bigram_d_f (dus) 5,876,653,769
bigram_d_c = 3,154,200,111

$ hfs -cat /user/hadoop/bigram_d_mutual_info/part-r-00000 | head -n 50
expr    expr    20888   17.048076978103953
ifeq    ifeq    6507    16.186081768917436
Burkina Faso    5473    16.145461115766583
Rotten  Tomatoes        5705    15.755724868405853
Kuala   Lumpur  6457    15.723829544745481
SO      Strikeouts      5788    15.564872663796615
Masovian        east-central    8452    15.412136208849287
Earned  SO      5651    15.40456407733207
Wins    Losses  7984    15.239019810631586
Tel     Aviv    9137    15.158101160760133
Baton   Rouge   5599    15.097851626874347
Dungeons        Dragons 5509    14.84334814467409
Trinidad        Tobago  6241    14.770530324750123
Figure  Skating 5528    14.68826766933851
Lok     Sabha   7435    14.679706153380339
background-color        E9E9E9  8490    14.652837972898762
Haleakala       NEAT    5328    14.514309090636834
Kitt    Spacewatch      17854   14.435471379604573
</pre>

## mean / stddev

build token distances

<pre>
hadoop fs -mkdir token_distance
hadoop jar ~/contrib/streaming/hadoop-streaming.jar \
 -input sentences -output token_distance/bigram_distance \
 -mapper token_distance.py -file token_distance.py \
 -numReduceTasks 0
</pre>

55,378,018 sentences -> 20,089,376,334 pairs

calc mean/sd of all pairs

<pre>
-- mean_sd.pig
-- see http://en.wikipedia.org/wiki/Standard_deviation#Rapid_calculation_methods
td = load 'token_distance/bigram_distance' as (t1:chararray, t2:chararray, distance:int);
tds = foreach td generate t1, t2, distance, distance*distance as distance_sqr;
grped = group tds by (t1,t2);

mean_sd = foreach grped {
 n  = COUNT(tds);
 s1 = SUM(tds.distance);
 s2 = SUM(tds.distance_sqr);

 mean = (double)s1/n;

 sd_nomin = (double)(n*s2 - s1*s1);
 sd_denom = n * (n-1);
 sd = SQRT( sd_nomin / sd_denom );

 generate flatten(group), n, mean, sd;
}

store mean_sd into 'token_distance/mean_sd';
</pre>

calculate quantiles of mean / sd values (sanity)

<pre>
-- mean_sd_quantiles.pig 
register /mnt/datafu/dist/datafu-0.0.1.jar
define Quantile datafu.pig.stats.StreamingQuantile('101');
define calc_quantiles(src, field, out) returns void {
 just_field = foreach $src generate $field;
 grped = group just_field all;
 quantiles = foreach grped generate Quantile(just_field);
 store quantiles into '$out';
}
mean_sd = load 'token_distance/mean_sd' as (t1:chararray, t2:chararray, n:int, mean:double, stddev:double);
calc_quantiles(mean_sd, mean, 'token_distance/mean_quantiles');
calc_quantiles(mean_sd, stddev, 'token_distance/stddev_quantiles');
</pre>

hadoop@ip-10-17-57-166:~$ hfs -cat /user/hadoop/token_distance/mean_quantiles/*
(-9.0,-8.0,-7.5,-7.0,-6.5,-6.0,-6.0,-5.5,-5.375,-5.0,-5.0,-4.5,-4.4,-4.0,-4.0,-3.75,-3.5,-3.4,-3.1683168316831685,-3.0,-3.0,-2.7777777777777777,-2.607142857142857,-2.5,-2.4,-2.25,-2.0,-2.0,-2.0,-1.875,-1.6944444444444444,-1.6,-1.5,-1.5,-1.3333333333333333,-1.2352941176470589,-1.0588235294117647,-1.0,-1.0,-1.0,-0.8888888888888888,-0.75,-0.6666666666666666,-0.5157894736842106,-0.5,-0.5,-0.34782608695652173,-0.2702702702702703,-0.16666666666666666,0.0,0.0,0.0,0.02502691065662002,0.2,0.3076923076923077,0.4,0.5,0.5,0.5680933852140078,0.6666666666666666,0.7777777777777778,0.9354838709677419,1.0,1.0,1.0,1.1111111111111112,1.25,1.3333333333333333,1.5,1.5,1.625,1.75,1.9714285714285715,2.0,2.0,2.1,2.3214285714285716,2.48,2.5,2.6666666666666665,2.8620689655172415,3.0,3.0,3.25,3.5,3.5238095238095237,3.8333333333333335,4.0,4.142857142857143,4.5,4.666666666666667,5.0,5.0,5.5,5.666666666666667,6.0,6.333333333333333,6.666666666666667,7.0,7.666666666666667,9.0)

hadoop@ip-10-17-57-166:~$ hfs -cat /user/hadoop/token_distance/stddev_quantiles/*
(0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.5,0.6030226891555273,0.7071067811865476,0.7071067811865476,0.7071067811865476,0.7071067811865476,1.1547005383792515,1.4142135623730951,1.4142135623730951,1.4142135623730951,1.4142135623730951,1.6278820596099706,1.8085096269323728,2.073644135332772,2.1213203435596424,2.1213203435596424,2.1213203435596424,2.23606797749979,2.4257748058625186,2.6076809620810595,2.819996622760558,2.8284271247461903,2.8284271247461903,2.886751345948129,3.03315017762062,3.2145502536643185,3.420526275297414,3.519648784380674,3.5355339059327378,3.5355339059327378,3.669695718539436,3.8172540616821107,4.0,4.08248290463863,4.203173404306164,4.242640687119285,4.242640687119285,4.343246179462463,4.444097208657794,4.541892543729748,4.618802153517006,4.715628712080461,4.793585457511062,4.88535225614967,4.949747468305833,4.949747468305833,4.979959839195493,5.036533199202271,5.118869382571086,5.18613073726338,5.237229365663817,5.297106327329854,5.366563145999495,5.440588203494177,5.504543577809154,5.5506327395643655,5.609515724790034,5.656854249492381,5.656854249492381,5.7016464227295405,5.770615218501403,5.830951894845301,5.894913061275798,5.9717615272398445,6.0332412515993425,6.09831551536455,6.18465843842649,6.25642526870234,6.3508529610858835,6.363961030678928,6.3979848801256,6.494261974735176,6.597558470963162,6.685805860178712,6.8452277432633934,6.990072325170257,7.0710678118654755,7.0710678118654755,7.211102550927978,7.41057802513857,7.637626158259733,7.7781745930520225,7.788880963698615,8.144527815247077,8.48528137423857,8.48528137423857,9.192388155425117,9.192388155425117,9.899494936611665,10.606601717798213,12.727922061357855)


todo:
- mean_sd analysis
- pos tagging and mi on AN and ANN phrases
- pareto front analysis
- likelihood ratios

# embedded pig notes

download and jar xf
 http://hivelocity.dl.sourceforge.net/project/jython/jython/2.5.2/jython_installer-2.5.2.jar

 x = load 'numbers';
 y = filter x by $0>3;

java -cp pig/pig.jar:jython/jython.jar org.apache.pig.Main -x local -g jython test.py

#!/usr/bin/python
from org.apache.pig.scripting import *

def main():
    P = Pig.compile("""
x = load 'numbers';
y = filter x by $0>3;
store y into '$out';
"""
)
    out = 'test.out'
    job = P.bind().runSingle()
    print 'success?', job.isSuccessful()
    print 'result', job.result('out')


if __name__ == '__main__':
    main()


