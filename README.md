# awesomerc
Awesome WM configuration

Main features:
* Dynamic labels, persistent across restarts (removal of labels not yet supported, though)
* Shared labels across multiple monitors (adapted from https://github.com/XLegion/sharetags)
* Shared configuration file shared between desktop (home) and laptop (work, running under a vm) computers, with machine dependent sections
* New layout: two pane, inspired by xmonad's (http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Layout-TwoPane.html)
* Jump directly to wiindow number n with Super+n keybinding
* Detection of a connected projector and special rules for directing specific windows (Kodi, netflix) to it
* Uses apw from https://github.com/mokasin/apw

The sharetags/ directory is the place to go if you are interested in the first two points. No real documentation, though, look into the main rc.lua for an usage example.
