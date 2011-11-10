# take a sample
head -n1000 part-00086 > pass0

# ensure no underscores at start
cat pass0 | perl -plne's/_/-/;' > f; mv f pass0

# extract hiscore bigrams
cat pass0 | ./bigram_mutual_info.py | sort -k5 -nr | cut -f1,2 | head > high_scrored_bigrams.pass0

# replace them in text with a unigram "version"
# ie bigram "the" "cat" becomes "(the_cat)"
cat pass0 | ./resubstitute_bigrams.py high_scrored_bigrams.pass0 > pass1
 
or iteratively

for N in {0..100}; do
 N_1=$(($N+1))
 N="pass${N}"
 N_1="pass${N_1}"
 cat $N | ./bigram_mutual_info.py | sort -k5 -nr | cut -f1,2 | head > high_scrored_bigrams.$N
 echo; echo $N
 cat high_scrored_bigrams.$N
 cat $N | ./resubstitute_bigrams.py high_scrored_bigrams.$N > $N_1
done

# unigram freqs
cat pass1001 | perl -plne's/[\(\)]//g;s/ /\n/g' | sort | uniq -c | sort -nr > unigram_freqs

# sort by number of underscores...

cat unigram_freqs | ./count_underscores.py | sort -k3 -nr | head -n 20 > unigram_freqs__by_num_underscores
2       The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the_The_per_capita_income_for_the 191

where did this come from? there is no case of a sentence with this repeated.. there must be a bug?