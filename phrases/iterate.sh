for N in {0..1000}; do
 N_1=$(($N+1))
 N="pass${N}"
 N_1="pass${N_1}"
 cat $N | ./bigram_mutual_info.py | sort -k5 -nr | cut -f1,2 | head > high_scrored_bigrams.$N
 echo; echo $N
 cat high_scrored_bigrams.$N
 cat $N | ./resubstitute_bigrams.py high_scrored_bigrams.$N > $N_1
 #rm $N
done
