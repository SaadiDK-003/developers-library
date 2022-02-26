# GitHub Useful commands
--------
`.md` file cheatsheet [Source-1](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) ~ [Soruce-2](https://github.com/tchapi/markdown-cheatsheet/blob/master/README.md)

Github Basic commands everyone should know ☻
---
* git init ~ to initialize github.
* git clone `[repo path]` ~ to clone your repostiory on your `local` or `live-server`.
* git status ~ to check the status of your repo.
* git branch ~ check on which branch we are on and how many branches we have.
* git add `file or folder path` ~ to add your stuff in your branch.
* git commit -m `your message` ~ useful for knowing what you have added in ur repo.
* git pull ~ get updated stuff from your repo to `local` or `live-server`. -> default branch `main`
  * git pull origin `[branch-name]` ~  if you want to add a specific branch to get pull from it.
* git push ~ deliver your updated work on `github` repo. -> default branch `main`
  * git push origin `[branch-name]` ~ if you want specific branch stuff to upload on github.

### *Mostly used in working environment are as follows: ~ top to bottom step by step*
###### Not telling all the scenarios that occurs
1. git branch ~ *we check are we standing on `main` branch or the one we created.*
   1. if we are not so first switch to `main` branch -> *`git checkout main`*
2. git git pull ~ make sure you are `UpToDate` with your `main` branch.
3. git status ~ see the changes you have made or you are going to do.
4. 

## ♦ Dangerous Commands ♦
### To remove folder/directory only from git repository and not from the local try 3 simple commands.
1. git rm -r --cached FolderName
2. git commit -m "Removed folder from repository"
3. git push origin master
