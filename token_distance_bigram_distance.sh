hadoop mkdir token_distance
hadoop jar ~/contrib/streaming/hadoop-streaming.jar \
 -input sentences -output token_distance/bigram_distance \
 -mapper token_distance.py -file token_distance.py \
 -numReduceTasks 0
