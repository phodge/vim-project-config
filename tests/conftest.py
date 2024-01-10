import pytest


class Editor:
    skipreason = None

    @classmethod
    @property
    def pytest_param(class_):
        marks = pytest.mark.skip(class_.skipreason) if class_.skipreason else []
        return pytest.param(class_, marks=marks)


class Vim(Editor):
    executable = 'vim'
    skipreason = "NeoVim not found"


class NeoVim(Editor):
    executable = 'nvim'


@pytest.fixture(params=[
    Vim.pytest_param,
    NeoVim.pytest_param,
])
def editor(request):
    return request.param
