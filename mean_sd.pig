-- mean_sd.pig
-- see http://en.wikipedia.org/wiki/Standard_deviation#Rapid_calculation_methods
td = load 'token_distance/bigram_distance' as (t1:chararray, t2:chararray, distance:int);
tds = foreach td generate t1, t2, distance, distance*distance as distance_sqr;
grped = group tds by (t1,t2);
mean_sd = foreach grped {
 n  = COUNT(tds);
 s1 = SUM(tds.distance);
 s2 = SUM(tds.distance_sqr);
 generate group, n as n, s1 as s1, s2 as s2;
}
mean_sd = filter mean_sd by n > 1;
mean_sd = foreach mean_sd {
 mean = (double)s1/n;
 sd_nomin = (double)(n*s2 - s1*s1);
 sd_denom = n * (n-1);
 sd = SQRT( sd_nomin / sd_denom );
 generate flatten(group), n, mean, sd;
}
store mean_sd into 'token_distance/mean_sd';

