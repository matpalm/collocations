-- mean_sd_quantiles.pig
register /mnt/datafu/dist/datafu-0.0.1.jar
define Quantile datafu.pig.stats.StreamingQuantile('101');
define calc_quantiles(src, field, out) returns void {
 just_field = foreach $src generate $field;
 grped = group just_field all;
 quantiles = foreach grped generate Quantile(just_field);
 store quantiles into '$out';
}
mean_sd = load 'token_distance/mean_sd' as (t1:chararray, t2:chararray, n:int, mean:double, stddev:double);
calc_quantiles(mean_sd, mean, 'token_distance/mean_quantiles');
calc_quantiles(mean_sd, stddev, 'token_distance/stddev_quantiles');

