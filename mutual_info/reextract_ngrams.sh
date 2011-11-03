rm -rf {uni,bi,tri}gram{s,_c,_f}
pig -x local -f extract_ngrams.pig
pig -x local -f ngram_freq_and_count.pig