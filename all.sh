#!/bin/bash
for f in *.iso; do ./mk.sh $f; mv espeakup.iso espeakup.$f; done
