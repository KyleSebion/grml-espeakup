# About
mk.sh sets up espeakup in a new .iso file (espeakup.iso) based on a given grml .iso file.
mk.sh is the primary file to use.
The others are primarily for testing mk.sh.
You might also be interested in the fork at [https://people.math.wisc.edu/~jheim/GRML/grml2speak](url).

# Instructions
1. Boot grml
2. Download the grml .iso file you want to use
3. Run: `./mk.sh <grml.iso> [espeakup|ltlk]`
4. Use the .iso file it creates (espeakup.iso)[^note1]

[^note1]: Tweaks might be needed depending on your hardware.
