def test_project_config_that_sets_custom_filetype(
    tmpdir,
    ieditor,
    git_repo_a,
    git_repo_b,
    git_repo_c,
    repo_config_factory,
):
    """
    Confirm that Example 1 from examples.md works as documented.
    """
    # create three different project configs that will set filetype by extension
    code_template = "fun! projectconfig.api2024.filetypeDetect(bufnr, ext, basename, bufname) dict\nif a:ext == 'py'\nreturn '{pyft}'\nendif\nendfun\n"
    cfg1 = code_template.format(cfgname="cfg1", pyft='python1')
    cfg2 = code_template.format(cfgname='cfg2', pyft='python2')
    cfg3 = code_template.format(cfgname='cfg3', pyft='python3')

    repo_config_factory(git_repo_a, 'repo-a', 'Repo A', cfg1)
    repo_config_factory(git_repo_b, 'repo-b', 'Repo B', cfg2)
    repo_config_factory(git_repo_c, 'repo-c', 'Repo C', cfg3)

    pairs = [
        (git_repo_a.path, git_repo_a.pyfile, 'python1'),
        (git_repo_b.path, git_repo_b.pyfile, 'python2'),
        (git_repo_c.path, git_repo_c.pyfile, 'python3'),
        # outside the project .py files have the usual filetype
        (tmpdir, tmpdir / 'some_file.py', 'python'),
    ]

    # assertions

    # Assertion1 - custom filetypes work when opening an initial file for the project
    for cwd, pyfile, expected_filetype in pairs:
        ieditor.launch(cwd, pyfile.relative_to(cwd))
        assert ieditor.get_expr_str('&filetype') == expected_filetype
        ieditor.quitall()

    # Assertion 2 - custom filetypes work when opening existing file
    #
    # Open each repo's .py file in a single vim instance so that all custom
    # extensions are registered.
    ieditor.launch(git_repo_a.path, tmpdir / 'some_python_file.py')
    assert ieditor.get_expr_str('&filetype') == 'python'  # a regular python file
    for _, pyfile, expected_filetype in pairs:
        ieditor.edit(pyfile)
        assert ieditor.get_expr_str('&filetype') == expected_filetype
    ieditor.quitall()
