import os
import re
import subprocess
import time
from functools import partial
from pathlib import Path
from textwrap import dedent

import pytest

TESTS_DIR = Path(__file__).parent


class Editor:
    skipreason: str | None = None

    _p = None
    _cwd = None

    def __init__(self, tmpdir: Path):
        super().__init__()

        self._configs_dir = tmpdir / 'project-configs'

    @classmethod
    def get_pytest_param(class_):
        marks = pytest.mark.skip(class_.skipreason) if class_.skipreason else []
        return pytest.param(class_, marks=marks)

    @property
    def launch_cmd(self):
        raise NotImplementedError(f"{self.__class__.__name__} does not implement .launch_cmd")

    def launch(self, cwd: Path):
        assert self._p is None
        assert self._cwd is None
        self._cwd = cwd

        # where to store configs
        init_call = f'vimprojectconfig#initialise({{"project_config_dirs": {{"Personal": "{self._configs_dir}"}}}})'

        env = {**dict(os.environ), 'VIM_PROJECT_CONFIG_UNIT_TESTING': '1'}
        cmd = self.launch_cmd + ['+call ' + init_call]
        self._p = subprocess.Popen(cmd, cwd=cwd, env=env)

    def cleanup(self):
        try:
            if self._p:
                self._cleanup_subprocess(self._p)
        finally:
            self._p = None
            self._cwd = None

    def _cleanup_subprocess(self, job):
        # see if it is already terminated
        try:
            if job.wait(0) is not None:
                return
        except subprocess.TimeoutExpired:
            pass

        # try terminate() command
        job.terminate()
        if job.wait(1) is None:
            job.kill()

    def edit(self, what: Path):
        raise NotImplementedError(f"{self.__class__.__name__} does not implement .edit()")


class Vim(Editor):
    executable = 'vim'
    skipreason = "Vim not found"


class NeoVim(Editor):
    executable = 'nvim'
    _address = None

    @property
    def launch_cmd(self):
        assert self._address is not None
        return [
            self.executable,
            # don't load a vimrc
            '-u', TESTS_DIR / 'vimrc.vim',
            # become server listening at this address
            '--listen', str(self._address),
        ]

    def launch(self, cwd: Path):
        self._address = cwd / 'neovim.sock'
        assert not self._address.exists()
        super().launch(cwd)

        # give time for the socket to appear
        start = time.time()
        while True:
            time.sleep(0.01)

            if self._address.exists():
                break

            elapsed = time.time() - start
            if elapsed > 2.0:
                raise Exception("socket did not appear in 2s")

    def edit(self, what: Path):
        # send a command to neovim to open a file
        self._remote_command(f'edit {str(what)}')

    def command(self, cmd: str):
        self._remote_command(cmd)

    def command_start(self, cmd: str):
        self._remote_command_start(cmd)

    def _remote_command(self, command):
        assert self._address is not None
        subprocess.run([
            self.executable,
            '--server', str(self._address),
            '--remote-expr', f"execute('{command}')",
        ], check=True)

    def _remote_command_start(self, command):
        assert self._address is not None
        job = subprocess.Popen([
            self.executable,
            '--server', str(self._address),
            '--remote-expr', f"execute('{command}')",
        ])
        return job

    def handle_choice(self, choices, choose, wait):
        choices_data = self._wait_for_data(
            'join(get(g:, "vimprojectconfig#__debug_choices", []), "|")',
            wait=wait,
        )

        if not choices_data:
            raise AssertionError('UI is not in "choose" mode: vimprojectconfig#__debug_choices is empty')

        current_choices = choices_data.split('|')

        for nr, pattern in enumerate(choices):
            assert pattern in current_choices[nr], f"UI Choice {nr+1} did not contain text {pattern!r}"

        self._send_chars(str(choose))

    def handle_prompt(self, expected, suggested, answer, wait):
        current_prompt = self._wait_for_data(
            'get(g:, "vimprojectconfig#__debug_prompt_label", "")',
            wait=wait,
        )
        if not current_prompt:
            raise AssertionError('UI is not in "prompt" mode: vimprojectconfig#__debug_prompt_label is empty')

        if expected not in current_prompt:
            # TODO: PC028: test this code path
            raise AssertionError(f'UI prompt {current_prompt!r} does not contain {expected!r}')

        current_default = self._get_expr('g:vimprojectconfig#__debug_prompt_default')
        if current_default != suggested:
            # TODO: PC028: test this code path
            raise AssertionError(f'UI prompt defaults to {current_default!r} instead of {suggested!r}')

        if answer:
            self._send_chars('<C-U>' + answer)
        self._send_chars('<CR>')

    def assert_buf_name(self, pattern, wait):
        self._wait_for(partial(self._assert_buf_name, pattern), wait, f'bufname matches {pattern!r}')

    def _assert_buf_name(self, pattern):
        current_buffer = self._get_expr('expand("%:p")')
        assert re.search(pattern, current_buffer), f"bufname {current_buffer!r} did not match {pattern!r}"

    def _wait_for(self, callable, wait, condition):
        if wait:
            attempts_remaining = 20
        else:
            return callable()

        while attempts_remaining:
            attempts_remaining -= 1

            # verify we are in a choice mode
            try:
                return callable()
            except AssertionError:
                if attempts_remaining > 0:
                    time.sleep(0.05)
                    continue

                raise

        raise AssertionError("Timed out waiting for: " + condition)

    def _wait_for_data(self, expr, wait):
        attempts_remaining = 20 if wait else 1

        data = ''

        while not len(data):
            attempts_remaining -= 1

            # verify we are in a choice mode
            data = self._get_expr(expr)

            if not len(data):
                if attempts_remaining > 0:
                    time.sleep(0.05)
                    continue

                return None

        return data

    def _get_expr(self, expr):
        assert self._address is not None
        return subprocess.run(
            [self.executable, '--server', str(self._address), '--remote-expr', expr],
            check=True,
            stdout=subprocess.PIPE,
        ).stdout.decode('utf-8')

    def _send_chars(self, chars):
        assert len(chars) >= 1
        assert self._address is not None
        return subprocess.run(
            [self.executable, '--server', str(self._address), '--remote-send', chars],
            check=True,
        )

    def get_buf_contents(self):
        return self._get_expr('join(getline(0, "$"), "\\n")')

    def get_buf_name(self):
        return self._get_expr('bufname()')

    def get_bool_option(self, name):
        val = self._get_expr('&' + name)
        if val == '1':
            return True
        if val == '0':
            return False

        raise Exception(f"Unexpected value {val!r}")

    def get_expr_str(self, expr):
        return self._get_expr(expr)

    def append_lines(self, lines):
        if isinstance(lines, str):
            lines = dedent(lines).strip().splitlines()

        # TODO: PC028: this is not very efficient compared to msgpack apis
        for line in lines:
            safe = line.replace("'", "''")
            self._get_expr(f"append(line('$'), ['{safe}'])")




@pytest.fixture(params=[
    Vim.get_pytest_param(),
    NeoVim.get_pytest_param(),
])
def editor(request, tmpdir):
    """A fixture that provides Vim and NeoVim as separate params."""
    class_ = request.param
    instance = class_(tmpdir)
    try:
        yield instance
    finally:
        instance.cleanup()


@pytest.fixture
def ieditor(tmpdir):
    instance = NeoVim(tmpdir)
    try:
        yield instance
    finally:
        instance.cleanup()
