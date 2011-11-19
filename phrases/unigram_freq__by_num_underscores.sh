cat $1 \
 | perl -plne's/[\(\)]//g;s/ /\n/g' \
 | sort \
 | uniq -c \
 | ./count_underscores.py \
 | sort -k3 -nr \
 | head -n200
