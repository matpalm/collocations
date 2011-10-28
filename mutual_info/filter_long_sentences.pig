 -- filter_long_sentences.pig
 s = load 'sentences_single_char_filtered' as (sentence:chararray);
 define filter_long_sentences `python filter_long_sentences.py` ship('filter_long_sentences.py');
 long_sentences = stream s through filter_long_sentences;
 store long_sentences into 'long_sentences';
