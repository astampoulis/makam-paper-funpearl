BEGIN { inmakam = 0;
        outputfile = gensub(/.md$/, ".makam", "g", ARGV[1]);
        stdlibfile = gensub(/[0-9a-z\-]+.md$/, "00-adapted-stdlib.makam", "g", ARGV[1]);
        print "Generating", outputfile; }

/^```makam$/ { inmakam = 1; }
/^```makam-stdlib$/ { inmakam = 2; }
/^```$/ { if (inmakam == 1) { inmakam = 0; print "" >> outputfile; } else if (inmakam == 2) { inmakam = 0; print "" > stdlibfile; }; }

!(/^```$/ || /^```makam$/ || /^```makam-stdlib$/ || \
  /^<\!--/ || /^-->/ || /^\.\.\./ \
 ) { if (inmakam == 1) { print $0 >> outputfile } else if (inmakam == 2) { print $0 >> stdlibfile; } }

END { }
