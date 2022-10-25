# GitHub Useful commands

---

`.md` file cheatsheet [Source-1](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) ~ [Soruce-2](https://github.com/tchapi/markdown-cheatsheet/blob/master/README.md)

## Github Basic commands everyone should know ☻

- git init ~ to initialize github.
- git clone `[repo path]` ~ to clone your repostiory on your `local` or `live-server`.
- git status ~ to check the status of your repo.
- git branch ~ check on which branch we are on and how many branches we have.
- git add `file or folder path` ~ to add your stuff in your branch.
- git commit -m `your message` ~ useful for knowing what you have added in ur repo.
- git pull ~ get updated stuff from your repo to `local` or `live-server`. -> default branch `main`
  - git pull origin `[branch-name]` ~ if you want to add a specific branch to get pull from it.
- git push ~ deliver your updated work on `github` repo. -> default branch `main`
  - git push origin `[branch-name]` ~ if you want specific branch stuff to upload on github.
- git reset ~ this will reset the state of the current HEAD in easy words, like you have added 1 or 2 files in your branch and you wanna undo it, so use this command.

### _Mostly used in working environment are as follows: ~ top to bottom step by step_

###### Not telling all the scenarios that occurs, _freely ask if needed ☻_

1. git branch ~ _we check are we standing on `main` branch or the one we created._
   - if we are not so first switch to `main` branch -> _`git checkout main`_
2. git pull ~ make sure you are `UpToDate` with your `main` branch.
3. git status ~ see the changes you have made or you are going to do.
4. git checkout -b `[new-branch-name]` ~ this is how we create a new branch we can update `main` branch too but this is a good way if you are working in a professional environment you will see the benefits of it. after creating you will switch to new branch.
5. git add ~ `git add [file or folder path]`
   - eg. git add index.html css/ js/ ... etc.
6. git commit -m "your message..." ~ after adding your files or folders you must add this.
7. git push origin `[new-branch]` ~ this is how you can push your changes of newly created branch on github repo.
   > and then visit your `repository` on browser, and do rest of stuff, that's simple. you can ask if have any query. ☻
   >
   > > you can use GitHub Desktop Version too. but personally I like `terminal` ♥
8. `git config core.fileMode` default is `true` set this to `false`
```php
git config core.fileMode false
```
> By doing this it will ignore all those files that has changed their `chmod` and git will not show them as modified files.
---

## ♦ Dangerous Commands ♦

### To remove folder/directory only from git repository and not from the local try 3 simple commands.

1. git rm -r --cached FolderName
2. git commit -m "Removed folder from repository"
3. git push origin master

---

## Git CheatSheets :

- [Git CheatSheet](https://cult.honeypot.io/reads/git-commands-cheat-sheet-for-all-developers/)

#### Regards, [SaadiDK & taha123618](https://github.com/SaadiDK-003/)
