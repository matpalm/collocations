package phrases;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Map;

public class BigramMutualInfo {
  
  private int unigramCount;
  private int bigramCount;
  private Map<String, Integer> unigramFreqs = new HashMap<String,Integer>();
  private Map<String, Integer> bigramFreqs = new HashMap<String,Integer>();
  
  public static void main(String s[]) throws IOException {
    new BigramMutualInfo().run();
  }
  
  private void run() throws IOException {
    slurpStdin();
    calculateMutualInfo();
  }

  private void slurpStdin() throws IOException {
    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
    String line;
    while ((line = in.readLine()) != null) {
      String[] tokens = line.split(" ");
      String t1 = null;
      for (String t2 : tokens) {
        inc(unigramFreqs, t2);
        unigramCount++;
        if (t1 != null) {
          String bigram = t1+" "+t2;
          inc(bigramFreqs, bigram);
          bigramCount++;
        }
        t1 = t2;        
      }      
    }  
    in.close();
  }

  private void calculateMutualInfo() {
    for(String bigram : bigramFreqs.keySet()) {
      int bigramFreq = bigramFreqs.get(bigram);
      if (bigramFreq==1) // log(1) = 0 so final score always 0
        continue;
      
      String[] t = bigram.split(" ");
      int t1Freq = unigramFreqs.get(t[0]);
      int t2Freq = unigramFreqs.get(t[1]);
      
      double mutualInfo = Math.log(bigramFreq) - Math.log(bigramCount) - 
                          Math.log(t1Freq) - Math.log(t2Freq) + 2*Math.log(unigramCount);
      double freqMutualIinfo = Math.log(bigramFreq) * mutualInfo;
      
      System.out.println(t[0] + "\t" + t[1] + "\t" + bigramFreq + "\t" + mutualInfo + "\t" + freqMutualIinfo);
    }    
  }
  
  private void inc(Map<String,Integer> map, String key) {
    if (map.containsKey(key)) 
      map.put(key, map.get(key) + 1);
    else 
      map.put(key, 1);
  }
  
}
