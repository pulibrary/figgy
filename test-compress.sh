#!/bin/bash
kdu_compress -i $JP2_FILE_PATH -o output.jp2 -rate 2.4,1.48331273,.91673033,.56657224,.35016049,.21641118,.13374944,.08266171\
      -jp2_space sRGB\
      -double_buffering 10\
      -num_threads 1\
      -no_weights\
      Clevels=6\
      Clayers=8\
      Cblk=\{64,64\}\
      Cuse_sop=yes\
      Cuse_eph=yes\
      Corder=RPCL\
      ORGgen_plt=yes\
      ORGtparts=R\
      Stiles=\{1024,1024\}
