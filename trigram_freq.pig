trigrams = load 'trigrams.gz' as (t1:chararray, t2:chararray, t3:chararray);
trigram_f = group trigrams by (t1,t2,t3);
trigram_f = foreach trigram_f generate flatten(group), COUNT(trigrams) as freq;
ord = order trigram_f by freq desc;
top_2k = limit ord 2000;
store top_2k into 'trigrams.top2k.gz';

