# Custom Homebrew formulas by Rossum

Install an older version poppler and its [cairo-specific headers](https://gitlab.freedesktop.org/poppler/poppler/merge_requests/252/diffs)
needed by [pdfparser](https://github.com/rossumai/pdfparser).

```
brew tap rossumai/formulas
brew install poppler@21.07.0
brew link poppler@21.07.0
```

## Development

Create a new formula in `Formula/` directory.
Test installation by:

```
brew install ./Formula/foo.rb
```
