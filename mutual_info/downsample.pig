-- pig -f downsample.pig -p input=sentences -p output=sentences_0.1
s = load '$input'; 
s2 = sample s 0.1;
store s2 into '$output'; 
