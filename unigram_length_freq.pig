 register 'pig/piggybank.jar';
 define len org.apache.pig.piggybank.evaluation.string.LENGTH;
 unigrams = load 'unigrams.gz' as (t1:chararray);
 lengths = foreach unigrams generate len(t1) as length;
 grped = group lengths by length;
 freqs = foreach grped generate group as length, COUNT(lengths) as freq;
 store freqs into 'length_freqs';

