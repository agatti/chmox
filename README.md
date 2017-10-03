Chmox - a CHM file viewer for macOS
===

This is the repository for an unofficial, updated fork of Chmox.  The original code has been left alone for a few
years now and as such, code stopped building and basically was more or less useless on modern versions of macOS.

This fork aims to bring the code up to modern standards, allowing its usage on recent versions of macOS.

The original code was taken from https://chmox.sourceforge.net/, and it is used in accordance to the original licence,
LGPL 2.1.  The new code still retains the same licence, and its text is available from the LICENSE.TXT file inside the
repository.

## Updates made since version 0.4&beta; (unreleased):

### Version 0.5

- Chmox has a new home now.
- Code now builds again.
- Minimum version requirement has been bumped up to macOS 10.10.
- Migrated code to modern Objective-C syntax and ARC.
- Removed potentially stale translations.
- Removed TOC drawer in favour of an in-window list.
- Removed MacPAD code.
- Cleaned up code.
- Added back/forward/print toolbar buttons.
- Added TouchBar support.

## Further developments

- (Re-)Inclusion of Chmox in the Homebrew/MacPorts package distributions.
- Search functionality.
- Bookmarks and favourites.
