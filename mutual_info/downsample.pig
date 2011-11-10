-- pig -f downsample.pig -p input=sentences -p output=sentences_0.1 -p sample=0.1
s = load '$input'; 
s2 = sample s $sample;
store s2 into '$output'; 
