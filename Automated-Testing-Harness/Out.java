//IO Mapping
import java.util.*;

class Out {
   public static void main(String[] args){
      Test testFile = new Test();      int passed = 0;
      int tests = 6;
      HashMap<int[], Integer> mp = new HashMap<int[], Integer>();
      mp.put(new int[]{4, 5, 6, 7},  8);
      mp.put(new int[]{6, 1, 4, 8},  10);
      mp.put(new int[]{0, 0, 1, 3},  0);
      mp.put(new int[]{3, 5, 6, 8},  9);
      mp.put(new int[]{4, 8, 3, 5},  12);
      mp.put(new int[]{9, 6, 33, 666},  1000);

      for(int[] in_case : mp.keySet()){
         if(testFile.double_val(in_case[0], in_case[1], in_case[2], in_case[3]) == mp.get(in_case) ) passed++;
      }

      System.out.println("Out: "+passed+"/"+tests+" passed.");
   }
}
