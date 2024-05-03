from textwrap import dedent

import pytest


@pytest.fixture()
def placeholder_repo_configs(
    git_repo_a,
    git_repo_b,
    git_repo_c,
    repo_config_factory,
) -> None:
    # create three different project configs that will set filetype by extension
    code_template = dedent(
        """
        fun! projectconfig.api2024.filetypeDetect(bufnr, ext, basename, bufname) dict
            if a:ext == 'py'
                return '{pyft}'
            endif
        endfun
        """.lstrip()
    )
    cfg1 = code_template.format(cfgname="cfg1", pyft='python1')
    cfg2 = code_template.format(cfgname='cfg2', pyft='python2')
    cfg3 = code_template.format(cfgname='cfg3', pyft='python3')

    repo_config_factory(git_repo_a, 'repo-a', 'Repo A', cfg1)
    repo_config_factory(git_repo_b, 'repo-b', 'Repo B', cfg2)
    repo_config_factory(git_repo_c, 'repo-c', 'Repo C', cfg3)


@pytest.fixture
def file_pairs(
    tmpdir,
    git_repo_a,
    git_repo_b,
    git_repo_c,
):
    return [
        (git_repo_a.path, git_repo_a.pyfile, 'python1'),
        (git_repo_b.path, git_repo_b.pyfile, 'python2'),
        (git_repo_c.path, git_repo_c.pyfile, 'python3'),
        # outside the project .py files have the usual filetype
        (tmpdir, tmpdir / 'some_file.py', 'python'),
    ]


@pytest.mark.usefixtures("placeholder_repo_configs")
class TestProjectConfigWithCustomFileTypes:
    def test_launching_edit_of_project_file(self, ieditor, file_pairs):
        # custom filetypes work when opening an initial file for the project
        for cwd, pyfile, expected_filetype in file_pairs:
            ieditor.launch(cwd, pyfile.relative_to(cwd))
            assert ieditor.get_expr_str('&filetype') == expected_filetype
            ieditor.quitall()

    def test_split_to_project_file_after_launch(
        self,
        tmpdir,
        ieditor,
        git_repo_a,
        file_pairs,
    ):
        """Custom filetypes work when opening existing file."""
        # Open each repo's .py file in a single vim instance so that all custom
        # extensions are registered.
        ieditor.launch(git_repo_a.path, tmpdir / 'some_python_file.py')
        assert ieditor.get_expr_str('&filetype') == 'python'  # a regular python file
        for _, pyfile, expected_filetype in file_pairs:
            ieditor.edit(pyfile)
            assert ieditor.get_expr_str('&filetype') == expected_filetype
        ieditor.quitall()
