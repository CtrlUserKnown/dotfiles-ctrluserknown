# dotfiles

Personal configuration files, managed declaratively with [`dots`](https://github.com/CtrlUserKnown/dots).

## Layout

| Directory      | Symlinked to        |
| -------------- | ------------------- |
| `bat/`         | `~/.config/bat`     |
| `fastfetch/`   | `~/.config/fastfetch` |
| `ghostty/`     | `~/.config/ghostty` |
| `herdr/`       | `~/.config/herdr`   |
| `opencode/`    | `~/.config/opencode` |
| `zsh/zsh/`     | `~/.config/zsh`     |
| `zsh/.zshrc`   | `~/.zshrc`          |
| `git/.gitconfig` | `~/.gitconfig`    |

The full mapping lives in [`links.toml`](links.toml).

## Install

Clone into `~/development/dotfiles` (the path the manifest expects):

```sh
git clone <this-repo> ~/development/dotfiles
```

Point `dots` at the manifest and apply it:

```sh
ln -sf ~/development/dotfiles/links.toml ~/.dots/links.toml
dots link apply
```

`dots link apply` creates every symlink, backing up any real file already at a
target before replacing it. Re-run it any time to repair drift.

## Adding a new config

```sh
dots link add ~/development/dotfiles/foo ~/.config/foo
```

This moves the existing file into the repo (if needed), records it in
`links.toml`, and creates the symlink.
