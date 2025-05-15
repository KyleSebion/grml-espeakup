#!/bin/bash
for f in *.iso; do for t in espeakup ltlk; do ./mk.sh "$f" "$t"; mv espeakup.iso "$t.$f"; done; done
