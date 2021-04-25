# git-tools
Various tools for working with git for stack pull request. Install with `make install`

Generally:

* `git-stack-todo` -- script to process TODO from `git rebase -i` so that all your branches are moved too. It
  creates backup branches in case something goes wrong. If you give it additional arguments (like command how to
  run tests), git rebase will run it before moving branches.
* git stack-clean-backup -- remove all backup branches.
* git stack-foreach -- give it base commit and command, and run your command on all branches between commit and HEAD. I.e. `git stack-foreach master git push --force-with-lease`
* git backup -- used internally by git-stack-todo. Create backup branch.
