-- top_ngrams_by_freq.pig
n = load 'unigram_f' as (t1:chararray, freq:long);
s = order n by freq desc;
s = limit s 10;
store s into 'unigram_top10';
n = load 'bigram_f' as (t1:chararray, t2:chararray, freq:long);
s = order n by freq desc;
s = limit s 10;
store s into 'bigram_top10';
n = load 'trigram_f' as (t1:chararray, t2:chararray, t3:chararray, freq:long);
s = order n by freq desc;
s = limit s 10;
store s into 'trigram_top10';