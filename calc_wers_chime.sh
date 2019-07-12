#!/bin/bash

if [ $# != 1 ]; then
   echo "Usage: calc_wer_chime.sh <exp_dir>"
   echo "ex) calc_wer_chime.sh <exp/chime3_lstm_fbank>"
   exit 1;
fi

target_dir=$1
exp_dir=exp/$target_dir
n_decode_out_dir=`find $exp_dir -maxdepth 1 -type d | grep "out_dnn" | wc -l` 

if [ $n_decode_out_dir != 1 ]; then
  echo "Too many output directories...$exp_dir"
  ls $exp_dir
  exit 1
fi

decode_dir=`find $exp_dir -maxdepth 1 -type d | grep "out_dnn"` 
echo "taget: $decode_dir"

e_d="et05"
task="real"
dir_kaldi=/workspace/kaldi/egs/chime4/s5_2ch
enhan=blstm-gev
graph_dir=$dir_kaldi/exp/tri3b_tr05_multi_blstm_gev/graph_tgpr_5k
#decode_dir=exp/$1/decode_et05_real_out_dnn1

for a in `find $decode_dir | grep "\/wer_" | awk -F'[/]' '{print $NF}' | sort`; do
  echo -n "$a "
  cat $decode_dir/$a | grep WER | awk '{err+=$4} {wrd+=$6} END{printf("%.2f\n",err/wrd*100)}'
done | sort -n -k 2 | head -n 1 > $decode_dir/best_wer_$enhan

lmw=`cut -f 1 -d" " $decode_dir/best_wer_$enhan | cut -f 2 -d"_"`
echo "-------------------"
printf "best overall et05 WER %s" `cut -f 2 -d" " $decode_dir/best_wer_$enhan`
echo -n "%"
printf " (language model weight = %s)\n" $lmw
echo "-------------------"

    rdir=$decode_dir
    if [ -e $rdir ]; then
	echo $dir
      for a in _BUS _CAF _PED _STR; do
        grep $a $rdir/scoring/test_filt.txt \
          > $rdir/scoring/test_filt_$a.txt
        cat $rdir/scoring/$lmw.tra \
          | $dir_kaldi/utils/int2sym.pl -f 2- $graph_dir/words.txt \
          | sed s:\<UNK\>::g \
          | compute-wer --text --mode=present ark:$rdir/scoring/test_filt_$a.txt ark,p:- \
          1> $rdir/${a}_wer_$lmw 2> /dev/null
      done
      echo -n "${e_d}_${task} WER: `grep WER $rdir/wer_$lmw | cut -f 2 -d" "`% (Average), "
      echo -n "`grep WER $rdir/_BUS_wer_$lmw | cut -f 2 -d" "`% (BUS), "
      echo -n "`grep WER $rdir/_CAF_wer_$lmw | cut -f 2 -d" "`% (CAFE), "
      echo -n "`grep WER $rdir/_PED_wer_$lmw | cut -f 2 -d" "`% (PEDESTRIAN), "
      echo -n "`grep WER $rdir/_STR_wer_$lmw | cut -f 2 -d" "`% (STREET)"
      echo ""
      echo "-------------------"
    fi
echo ""


