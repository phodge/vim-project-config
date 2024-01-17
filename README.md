# vim-project-config

A plugin for defining true per-project config without committing to the project repo.

Provides the following advantages over other plugins:

* Provides more powerful mechanisms for idenfiying a project / can recognise the same project when
  it is located in different paths.
* Provides more flexibility in how to store and manage project config scripts.
* "Batteries included" philosophy - more powerful hooks than just a single init script, plus the
  supporting utilities you need to configure a project properly.
* "Ergonomic" - interactive prompts and hot reload make it quick and easy to modify your project
  configs as time goes on.


## Installation

*vim-plug*

    Plug 'phodge/vim-project-config'


## Initialisation

**~/.vimrc**

    call vimprojectconfig#initialise({
        \ 'project_config_dirs': {'Personal': $HOME . '/dotfiles/project-configs'},
        \ " Use dbakker/vim-projectroot to identify projects
        \ 'get_project_root': 'projectroot#get',
        \ })


### Configuration Options

**get_project_root**

Required. The name of a vim function which can be used to get the project root folder for a buffer.

    " example
    call vimprojectconfig#initialise({
        \ " Use dbakker/vim-projectroot to identify projects
        \ 'get_project_root': 'projectroot#get',
        \ })

**project_config_dirs**

Required; at least one entry must be provided. Specifies the parent folder(s) where
project-configs should be stored. You may wish to have configs for your personal projects separate

    " example
    call vimprojectconfig#initialise({
        \ 'project_config_dirs': {
        \     'Personal': $HOME . '/dotfiles/project-configs',
        \     'Work': $HOME . '/.vim/work-projects',
        \ },
        \ })


## Alternative Solutions

[EditorConfig](https://editorconfig.org/)

* requires committing to the repo
* only the most common filetype settings are supported

['exrc'](https://neovim.io/doc/user/options.html#'exrc') or [nvim-config-local](https://github.com/klen/nvim-config-local) or [emersonmx/vim-prj](https://github.com/emersonmx/vim-prj)

* requires committing to the repo
* only provides a single script as the entry point


[natecraddock/workspaces.nvim](https://github.com/natecraddock/workspaces.nvim)

* Oriented around folders (paths), so can't be paired with [vim-projectroot](https://github.com/dbakker/vim-projectroot).
* Hooks must be defined in your `init.lua` or your must build your own solution for making them
  more organised.


[windwp/nvim-projectconfig](https://github.com/windwp/nvim-projectconfig)

* Oriented around folders (paths) instead of projects.


[jandamm/vim-projplugin](https://github.com/jandamm/vim-projplugin)

* This appears to be oriented around folders (or rather, the parent folder name) and requires you
  to open files from the project root only, or use a 3rd-party plugin like vim-rooter to modify each
  buffer's pwd.


## Development

### Running Unit Tests

Unit tests require a recent version of python and the
[poetry](https://python-poetry.org/) package manager. You will also need to
install the minimum supported versions of vim and neovim.

Run these commands to run the whole test suite

    # this should install to a virtual environment
    poetry install --no-root
    poetry run pytest tests

... or to run a single test:

    poetry run pytest tests/test_something.py [ -v --ff -x]
