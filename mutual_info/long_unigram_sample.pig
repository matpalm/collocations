 register 'pig/piggybank.jar';
 define len org.apache.pig.piggybank.evaluation.string.LENGTH;
 unigrams = load 'unigrams.gz' as (t1:chararray);
 lengths = foreach unigrams generate t1, len(t1) as length;
 s = filter lengths by length > 70;
 store s into 'unigram_sample_len_70_plus';
