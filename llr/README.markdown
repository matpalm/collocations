apply log likelihood ratio

see <a href="">this blog post</a>

requires mahout libs, at least the following dependencies, on pig classpath

<pre>
export PIG_CLASSPATH=/home/mat/dev/collocations/llr/lib/google-collections-1.0-rc2.jar:/home/mat/dev/collocations/llr/lib/mahout-math-0.6-SNAPSHOT.jar
</pre>

also requires unigrams and bigrams from mutual info experiment

at least

<pre>
pig -f extract_ngrams.pig
pig -f ngram_freq_and_count.pig
</pre>

then run llr.pig
<pre>
pig -f llr.pig
</pre>
