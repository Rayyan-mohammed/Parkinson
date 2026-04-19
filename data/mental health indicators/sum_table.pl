#!/usr/bin/perl -w

&sum;

sub sum {
  $outfile2 = "error.txt";
  open OUT2, ">$outfile2" or die "$outfile2\n";
  $outfile = "sum_table.txt";
  open OUT, ">$outfile" or die "$outfile $!\n";
  @files = glob("out/*txt");
  foreach $f (0..$#files){
    $infile = $files[$f];
    open IN, $infile or die "$infile $!\n";
    while (<IN>){
      chomp;
      @F = split;
      if ($. == 1){
        if (!$f){
          print OUT "$_\n";
        }
        next;
      }
      if ($#F != 72){
        print OUT2 "$infile $#F 72 $_\n";
        next;
      }
      print OUT "$_\n";
    }
    close IN;
  }
  close OUT;
  close OUT2;
}


