-- pig -f downsample.pig -p input=sentences -p output=sentences_0.1
s = load '$input'; # 55e6
s2 = sample s 0.1;
store s2 into '$output'; # 5e6
