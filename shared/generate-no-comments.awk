BEGIN { inmakam = 0;
        outputfile = gensub(/.md$/, ".makam", "g", ARGV[1]);
        print "Generating", outputfile; }

/^```makam$/ { inmakam = 1 }
/^```$/ { if (inmakam) { inmakam = 0; print "" >> outputfile; } }

!(/^```$/ || /^```makam$/ || \
  /^<\!--/ || /^-->/ || /^\.\.\./ \
 ) { if (inmakam) { print $0 >> outputfile } }

END { }
