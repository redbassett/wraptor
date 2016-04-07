# wraptor
[![Build Status](https://travis-ci.org/redbassett/wraptor.svg?branch=master)](https://travis-ci.org/redbassett/wraptor) [![Code Climate](https://codeclimate.com/github/redbassett/wraptor/badges/gpa.svg)](https://codeclimate.com/github/redbassett/wraptor)

### Stop being soft on your code. Hard wrap in Atom.
When active, wraptor will automatically hard wrap code with newlines at the editor's preferred line length.

## Grammars:
To enable wraptor on a specific grammar, simply set the `enabled` property to `true` in `config.cson`.

    ".git-commit.text":
      editor:
        preferredLineLength: 72
      wraptor:
        enabled: true

## Wrap on demand:
To manually wrap the current text editor, run the `Wraptor: Wrap Current Buffer` command from the command palette.

## What's next:
- [x] Handle comments
- [ ] Allow manual wrapping of selection
- [ ] Implement better synergy

#### That's a wrap!
