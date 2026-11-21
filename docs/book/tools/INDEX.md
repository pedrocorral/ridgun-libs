# docs/book/tools/ — Tools that refresh and check the book

| Path | What | Read when |
|---|---|---|
| `refresh.py` | Rewrites every chapter from the current sources and tests, builds the chapters listed in `data.py` and updates the `INDEX.md` of each edition. A run on an up-to-date book changes nothing | After a lib, a test or a signature changes |
| `verify.py` | Checks quoted function names, hand-written examples (`ridgunc check`) and shown code against the sources; exit code 1 on any mismatch | Before committing a change to the book |
| `data.py` | What the book shows, independent of the language: chapters, source sections, examples, table rows, corrected names | Adding a chapter, an example or a table row |
| `common.py` | Helpers shared by the two tools: paths, source sections, test functions, signatures | Changing how the tools read the sources |
| `strings/` | The text of the entries of `data.py` in each of the 8 languages | Adding or changing a text |
