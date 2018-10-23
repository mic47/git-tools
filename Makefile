git-stack-todo: GitStackTodo.hs
	ghc -O2 GitStackTodo.hs -o git-stack-todo

install: git-stack-todo
	cp git-stack-todo ~/.local/bin
	cp git-backup ~/.local/bin
	cp git-stack-clean-backup ~/.local/bin
	cp git-stack-foreach ~/.local/bin

clean:
	rm git-stack-todo *.o *.hi
