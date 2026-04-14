# antibloat
This repos main goal is to supply gentoo ebuilds (that I acquire from various sources, shout outs) for software which are plagued by bloat like dbus or wayland.

Additionally you might see packages related to virtualization, these are copied 1:1 from the original gentoo repos with the only difference being they are made to be more stealthy with custom patches.

Sometimes you'll also see just generic software that the upstream gentoo repo hasn't updated in a while or I just mess around with. I would submit these to the repos but there are some things I cba to do, see here for example: https://www.gentoo.org/glep/glep-0076.html

To add this repo to your system simply run:
```bash
# eselect repository add antibloat git https://github.com/authorisation/antibloat.git
```
