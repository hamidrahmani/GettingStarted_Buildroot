# pre commit check
## to be sure the the files are not broken 
to detect and fix risky characters and line-endings in config and script files
- Zero‑width spaces (U+200B, U+200C, U+200D)
- Non‑breaking space (U+00A0)
- Non‑breaking hyphen (U+2011) and other Unicode dashes (U+2010–U+2015)
- Smart quotes, fancy arrows, and HTML entities like &gt;
- Windows line endings (CRLF)
- Any non‑ASCII control characters
### steps
- create scan_suspicious.sh
- create fix_suspicious.sh
- make them executable --> chmod +x ....
- create .githooks/pre-commit
- enable custom hooks --> git config core.hooksPath .githooks
- make it exacutable  --> chmod +x ...

