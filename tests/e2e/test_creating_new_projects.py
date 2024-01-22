from pathlib import Path
from textwrap import dedent


def test_creating_new_git_based_project(ieditor, git_repo_a):
    ieditor.launch(git_repo_a.path)

    # open a file from the git repo
    ieditor.edit(git_repo_a.file1)

    # edit project config
    ieditor.command_start('ProjectConfigEdit')

    # TODO: handle aborting at this point
    ieditor.handle_choice(
        ['new config', 'existing config'],
        choose=1,
        wait=True,
    )

    # will be prompted for a descriptive name, should suggest the parent folder
    # name
    ieditor.handle_prompt(
        'title for the project',
        suggested=git_repo_a.path.name,
        answer='My cool project',
        wait=True,
    )

    ieditor.assert_buf_name('/project.vim$', wait=True)

    assert ieditor.get_buf_contents().startswith('" Project: My cool project')

    # TODO: PC032: confirm that the project config files don't yet exist
    if False:
        assert ieditor.get_bool_option('l:modified')
        cfgpath = Path(ieditor.get_buf_name())
        assert not cfgpath.exists()
        assert not cfgpath.parent.exists()

    # add some project settings such that the README buffer will get a
    # buffer-local variable
    ieditor.append_lines(
        '''
        fun! projectconfig.BufEnter() dict
            let b:test_flag = 'success'
        endfun
        '''
    )
    ieditor.command('w')
    cfgpath = Path(ieditor.get_buf_name())
    assert cfgpath.exists()

    # confirm that the project config file's contents have been applied
    # to the relevant buffers?
    ieditor.command('buf README.md')

    # give time for the autocmds to fire
    import time
    time.sleep(0.1)
    assert ieditor.get_expr_str('b:test_flag') == 'success'


def test_creating_path_based_project():
    # TODO: PC005: implement this test
    # will be prompted for a descriptive name
    # - should suggest the folder name
    pass
