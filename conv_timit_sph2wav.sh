#!/bin/bash

dir_timit=/DB/TIMIT-CD01
cmd="/kaldi/tools/sph2pipe_v2.5/sph2pipe -f wav" 

find $dir_timit -name "*WAV" -print -exec $cmd {} {}.dec \;
