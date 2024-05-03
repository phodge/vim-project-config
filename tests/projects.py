import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from textwrap import dedent

import pytest


@pytest.fixture()
def tmpdir():
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@dataclass
class GitRepo:
    path: Path
    file1: Path
    file2: Path

    def run_git(self, args, **kwargs):
        cmd = [
            'git',
            '-c', 'user.email=vimmer@example.com',
            # just specified here to avoid excess output from git init
            '-c', 'init.defaultBranch=main',
        ] + args

        stdout = kwargs.pop('stdout', subprocess.DEVNULL)

        check = kwargs.pop('check', True)

        return subprocess.run(cmd, cwd=self.path, check=check, stdout=stdout, **kwargs)


@pytest.fixture
def git_repo_a(tmpdir):
    repo_path = tmpdir / 'git-repo-a'
    repo_path.mkdir()

    repo_files = {
        "README.md": (
            '''
            # Welcome to git repo A.
            '''
        ),
        "test.py": (
            '''
            import os

            print(os.environ["HOME"])
            '''
        )
    }

    # create some files
    for basename, contents in repo_files.items():
        (repo_path / basename).write_text(dedent(contents))

    repo = GitRepo(
        path=repo_path,
        file1=repo_path / 'README.md',
        file2=repo_path / 'test.py',
    )

    repo.run_git(['init'])
    repo.run_git(['add'] + list(repo_files.keys()))
    repo.run_git(['commit', '-m', 'initial commit'])

    return repo
