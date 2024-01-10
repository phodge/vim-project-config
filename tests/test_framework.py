from subprocess import run


def test_have_editor(editor):
    run([editor.executable, '+q!'])
