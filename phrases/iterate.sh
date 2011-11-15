N=0
:> high_score_bigrams
cp pass0.orig pass0
while true; do
 NF="pass${N}"
 N_1=$(($N+1))
 NF_1="pass${N_1}"

# cat $NF | ./bigram_mutual_info.py | sort -k5 -nr | cut -f1,2 | head > high_scrored_bigrams.$NF
 cat $NF | java -cp bin phrases.BigramMutualInfo | sort -k5 -nr | cut -f1,2 | head > high_scrored_bigrams.$NF

 echo; echo $NF
 echo >> high_score_bigrams
 echo $NF >> high_score_bigrams 
 cat high_scrored_bigrams.$NF | tee -a high_score_bigrams
 cat $NF | ./resubstitute_bigrams.py high_scrored_bigrams.$NF > $NF_1
 rm high_scrored_bigrams.$NF
 N=$N_1
 if diff $NF $NF_1 >/dev/null; then
  rm $NF
  exit 0
 fi
 rm $NF
done
