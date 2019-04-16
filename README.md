# Custom Homebrew formulas by Rossum

Install an older version poppler and its [cairo-specific headers](https://gitlab.freedesktop.org/poppler/poppler/merge_requests/252/diffs)
needed by [pdfparser](https://github.com/rossumai/pdfparser).

```
brew tap rossumai/formulas
brew install poppler@0.62.0
brew link poppler@0.62.0
```
