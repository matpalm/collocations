s = load 'sentences';
define fls `python filter_long_sentences.py`;
s = stream s through fls;
define fsnc `python filter_single_non_char.py`;
s = stream s through fsnc;
store s into 'sentences.cleaned';