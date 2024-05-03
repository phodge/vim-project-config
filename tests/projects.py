import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from textwrap import dedent
from typing import Callable, Iterator

import pytest


@pytest.fixture()
def tmpdir() -> Iterator[Path]:
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture()
def personalconfigsdir(tmpdir) -> Path:
    return tmpdir / 'project-configs'


@pytest.fixture()
def vimrcdir(tmpdir) -> Path:
    return tmpdir / 'my-vim-files'


@dataclass
class GitRepo:
    path: Path
    file1: Path
    file2: Path
    pyfile: Path

    _repo_id: str | None = None

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

    def get_repo_id(self):
        # Note: this needs to replicate the logic from
        # autoload#vimprojectconfig#_utils <SID>getGitProjectId()
        if self._repo_id is None:
            cmd = ['git', '-C', self.path, 'rev-list', '--max-parents=0', 'HEAD']
            sha = subprocess.check_output(cmd, encoding='utf-8').strip()
            assert len(sha)
            self._repo_id = sha
        return self._repo_id


def _git_repo_maker(
    repo_path: Path,
    repo_files: dict[str, str],
    *,
    shortcuts: dict[str, str],
) -> GitRepo:
    repo_path.mkdir()

    # create some files
    file_kwargs: dict[str, Path] = {}
    for basename, contents in repo_files.items():
        filepath = (repo_path / basename)
        filepath.write_text(dedent(contents))
        file_kwargs[f'file{len(file_kwargs) + 1}'] = filepath

    for argname, filename in shortcuts.items():
        file_kwargs[argname] = repo_path / filename

    repo = GitRepo(path=repo_path, **file_kwargs)  # type: ignore

    repo.run_git(['init'])
    repo.run_git(['add'] + list(repo_files.keys()))
    repo.run_git(['commit', '-m', 'initial commit'])

    return repo


@pytest.fixture
def git_repo_a(tmpdir):
    repo_path = tmpdir / 'git-repo-a'

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
    shortcuts = {'pyfile': 'test.py'}

    return _git_repo_maker(repo_path, repo_files, shortcuts=shortcuts)


@pytest.fixture
def git_repo_b(tmpdir):
    repo_path = tmpdir / 'git-repo-b'

    repo_files = {
        "README.md": (
            '''
            # Welcome to git repo B.
            '''
        ),
        "system.py": (
            '''
            import subprocess, sys

            subprocess.run(sys.argv[1], check=True)
            '''
        )
    }
    shortcuts = {'pyfile': 'system.py'}

    return _git_repo_maker(repo_path, repo_files, shortcuts=shortcuts)


@pytest.fixture
def git_repo_c(tmpdir):
    repo_path = tmpdir / 'git-repo-c'

    repo_files = {
        "README.md": (
            '''
            # Welcome to git repo C.
            '''
        ),
        "hello.py": (
            '''
            import sys

            sys.stdout.write("Hello, world!\n")
            '''
        )
    }
    shortcuts = {'pyfile': 'hello.py'}

    return _git_repo_maker(repo_path, repo_files, shortcuts=shortcuts)


@pytest.fixture
def repo_config_factory(personalconfigsdir: Path) -> Callable[..., None]:
    def _factory(repo: GitRepo, slug: str, desc: str, contents: str) -> None:
        projectid = repo.get_repo_id()
        cfgpath = personalconfigsdir / slug
        cfgpath.mkdir(exist_ok=False, parents=True)
        projectvim = cfgpath / 'project.vim'
        with projectvim.open('w') as f:
            f.write(f'" Project: {desc}\n')
            f.write(f'" ProjectID: {projectid}\n')
            f.write('\n')
            f.write(dedent(contents).rstrip())
            f.write('\n')

    return _factory
