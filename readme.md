# git-diff-exp

## Features

- gitリビジョン間のファイル差分diffをフォルダにエクスポートする
- 各リビジョンの時点をファイルをフォルダにエクスポートする
- diffファイルをもとにGithub pull request風のhtmlファイルをフォルダにエクスポートする

## Requirement

- shell script (and git command)
- nodejs
- diff2html

## Installation

#### git-diff-exp Setup

~~~
$ git clone git@gain-github-poc.dst.ibm.com:eb21246/git-diff-exp.git
$ ./setup.sh
~~~

## Usage

#### gitリビジョン間の差分diff、各リビジョンのファイルを取得する

~~~
$ cd path_to_repos
$ git-diff-exp.sh
~~~

* コマンドリファレンス

~~~

$ git-diff-exp.sh 

    git-diff-exp.sh is a tool for ...

    Usage:
        git-diff-exp.sh [--before <hash string>] [--after <hash string>]
                   [--list <file>] [--name-only]
                   [--version] [--help]

    Options:
        --before, -b        変更前GITリビジョンID
        --after, -a         変更後GITリビジョンID
        --list, -l          取得対象一覧ファイル名
        --name-only, -o     取得対象一覧ファイル生成モード
        --export, -x        HTMLファイル出力先ディレクトリ
        --version, -v       バージョン情報
        --help, -h          コマンドリファレンス


~~~

