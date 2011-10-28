register 'datafu-0.0.1/dist/datafu-0.0.1.jar';
define percentiles datafu.pig.stats.Quantile('0.9','0.91','0.92','0.93','0.94','0.95','0.96','0.97','0.98','0.99','0.991','0.992','0.993','0.994','0.995','0.996','0.997','0.998','0.999','1.0');
define quantiles(A, key, out) returns void {
 grped_f = group $A by $key;
 freqs = foreach grped_f generate COUNT($A) as freq;
 grped = group freqs all; 
 quantiles = foreach grped {          
  sorted = order freqs by freq;
  generate flatten(percentiles(sorted));
 }
 store quantiles into '$out';
}
unigrams = load 'unigrams.gz' as (t1:chararray);
quantiles(unigrams, t1, unigrams_quantiles);
bigrams = load 'bigrams.gz' as (t1:chararray, t2:chararray);
quantiles(bigrams, '(t1,t2)', bigrams_quantiles);

