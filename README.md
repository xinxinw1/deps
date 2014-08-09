# Git Dependency Manager

I wanted a simple program that would fetch javascript dependencies from other repos without having to use more complicated package managers like npm and bower, so I wrote this bash script to do that.

## How to use

Let's say your directory structure looks like this:
(The `master:` labels are git branches)

```
codes/
  tools/
    master:tools.js
  prec-math/
    master:prec-math.js
  cmpl-math/
    master:cmpl-math.js
    gh-pages:index.html
```

You want to get `tools.js`, `prec-math.js`, and `cmpl-math.js` from the master branches of their repos into a `lib` directory in the gh-pages branch of `cmpl-math`.

To do that, you create a file named `deps` in the gh-pages branch of `cmpl-math`:

```
# This file is a dependency definition
# See https://github.com/xinxinw1/deps for more details
master:cmpl-math.js lib
tools master:tools.js lib
prec-math master:prec-math.js lib
```

The lines starting with `# text text` are comments. Each line with two items separated by a space means "in the original repo, copy <first item> to directory <second item>". Each line with three items means "in repo <first item>, copy <second item> to directory <third item> in the original repo".

Now, if you've installed the `deps.bash` script to a directory in your `$PATH`, and run `git config --global alias.deps '!deps.bash'`, you can now run `git deps` and it will automatically copy the files from the correct branches of tools, prec-math, and cmpl-math to the lib folder of cmpl-math.
