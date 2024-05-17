from pathlib import Path
from subprocess import run


def test_get_git_project_id(ieditor, git_repo_a):
    real_repo_id = git_repo_a.get_repo_id()

    ieditor.launch(cwd=Path("/tmp"))
    plugin_repo_id = ieditor.get_expr_str(f"vimprojectconfig#_utils#_getGitProjectId('{git_repo_a.path}')")

    assert real_repo_id == plugin_repo_id


def test_get_git_project_id_multiple_first_commits(ieditor, git_repo_a, git_repo_b):
    # git repo A adds B as an origin, then creates a merge commit between the
    # two

    # move repo B's files sideways so there is no merge conflict
    git_repo_b.run_git(['mv', 'README.md', 'README_b.md'])
    git_repo_b.run_git(['commit', '-m', 'move files to prevent conflict'])

    # merge the two histories to create a repo with multiple ids
    git_repo_a.run_git(['remote', 'add', '-f', 'repo_b', git_repo_b.path])
    git_repo_a.run_git(['merge', '--allow-unrelated-histories', 'repo_b/main', '-m', 'cool_merge_bro'])

    real_repo_id = git_repo_a.get_repo_id()

    ieditor.launch(cwd=Path("/tmp"))
    plugin_repo_id = ieditor.get_expr_str(f"vimprojectconfig#_utils#_getGitProjectId('{git_repo_a.path}')")

    assert real_repo_id == plugin_repo_id
