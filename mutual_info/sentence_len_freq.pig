 -- sentence_len_freq.pig
 s = load 'sentences_single_char_filtered' as (sentence:chararray);
 define num_tokens `python num_tokens.py` ship('num_tokens.py');
 sentence_lens = stream s through num_tokens as (len:int);
 grped = group sentence_lens by len;
 len_freq = foreach grped generate group as len, COUNT(sentence_lens) as len_freq;
 o = order len_freq by len;
 store o into 'sentence_len_freq';

