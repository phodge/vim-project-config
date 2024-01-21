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

<!-- TODO: PC017: is this noticed required for the hooks to work?
**Important!** You should add vim-project-config to your ~/.vimrc in such a way that it appears in
['runtimepath'](https://neovim.io/doc/user/options.html#'runtimepath') earlier than other plugins
so that it can set buffer-local options before other plugins begin initialisation.
-->


## Initialisation

**~/.vimrc**
<!--TODO: PC022: implement project_config_dirs other than 'Personal' -->

    call vimprojectconfig#initialise({
        \ 'project_config_dirs': {'Personal': $HOME . '/dotfiles/project-configs'},
        \ " Use dbakker/vim-projectroot to identify projects
        \ 'get_project_root': 'projectroot#get',
        \ })


<!--
TODO: PC004: add support for lua
TODO: PC022: implement project_config_dirs other than 'Personal'
**init.lua** (Neovim)

    # TODO: rewrite this as lua
    call vimprojectconfig#initialise{
        project_config_dirs = {Personal = $HOME . '/dotfiles/project-configs'},
        -- Use dbakker/vim-projectroot to identify projects
        get_project_root = 'projectroot#get',
    }
--->


## Usage

1) Open a file from one of your projects.

2) Run `:ProjectConfigEdit`.

This will create a blank project config script for the project, or edit the existing config script
if it already exists.

<!--

TODO: PC017: document what the handlers are

### Vimscript

If you are using vimscript, you should use the following template:


    " project.vim - My cool project
    fun! projectconfig.projectLoad(projectstate)
        " executed once when a buffer for the project is first opened. Store per-project state in
        " a:projectstate
    endfun

    fun! projectconfig.projectUnload(projectstate)
        " executed once when the last buffer for a project is unloaded.
    endfun

    " XXX: I need to do some experimentation to see which autocmd is right for this thing

    fun! projectconfig.projectBufLoad(projectstate, bufnr)
        " executed once when a buffer for a project is created or opened.
    endfun

    " TODO: per-buffer hooks? Or just one hook that enables you to add any of the below autocmds?
    fun! projectconfig.BufEnter(projectstate)
    endfun

    fun! projectconfig.BufNew(projectstate)
    endfun

    fun! projectconfig.BufNewFile(projectstate)
    endfun

    fun! projectconfig.BufReadPre(projectstate)
    endfun

    fun! projectconfig.BufReadPost(projectstate)
    endfun

    fun! projectconfig.BufUnload(projectstate)
    endfun

    fun! projectconfig.BufWritePre(projectstate)
    endfun

    fun! projectconfig.BufWritePost(projectstate)
    endfun

    fun! projectconfig.FileType(projectstate)
    endfun

    fun! projectconfig.Syntax(projectstate)
    endfun


### Lua

TODO: PC004: add support for lua

If you are using Lua, you should use the following template:

    " project.lua - My cool project
    fun! projectconfig.setup(a:projectstate)
        " executed once when a buffer for the project is first opened. Store per-project state in
        " a:projectstate
    endfun

    fun! projectconfig.teardown(a:projectstate)
        " executed once when the last buffer for a project is unloaded.
    endfun

-->


### Automatic Reload

<!-- TODO: PC026: ensure this works for all buffers -->

Each time you save your project config script (or any other buffer under the project config script's
parent folder) with `:w` the relevant hooks will be re-run for each project and all of its open buffers.



### Configuration Options

**get_project_root**

Required. The name of a vim function which can be used to get the project root folder for a buffer.

    " example
    call vimprojectconfig#initialise({
        \ " Use dbakker/vim-projectroot to identify projects
        \ 'get_project_root': 'projectroot#get',
        \ })

**project_config_dirs**

Required; at least one entry must be provided. Specifies the parent folder(s)
where project-configs should be stored. You may wish to have configs for your
personal projects stored separately from work projects.
<!--TODO: PC022: implement project_config_dirs other than 'Personal' -->
**WARNING:** currently only 'Personal' will work.

    " example
    call vimprojectconfig#initialise({
        \ 'project_config_dirs': {
        \     'Personal': $HOME . '/dotfiles/project-configs',
        \     'Work': $HOME . '/.vim/work-projects',
        \ },
        \ })

<!--
TODO: PC004: add these options also:
**init_scripts**

Optional. Defaults to `["project.lua", "project.vim"]`.


**default_init_script**

Optional. If set, must be one of the file names from **init_scripts**. Specifies the name of the
init script to use for new project configs so that you aren't prompted to choose for every project.
-->

<!--
TODO: PC027: document API here?
### Other API Features

`projectconfig#getProjectConfigPath(projectfile)`

    Returns the path for the project config script that would be opened by `:ProjectConfigEdit` for
    the specified buffer, or `v:null` if it does not exist.

`projectconfig#getProjectConfigDir(projectfile)`

    Returns the path for folder containing the project config script that would be opened by
    `:ProjectConfigEdit`, or `v:null` if no project config exists for that project.
-->


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
