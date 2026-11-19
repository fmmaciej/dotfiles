# Yazi

## Configuration

- `YAZI_CONFIG_HOME` points at `.config/yazi`.
- Unless set by the user, `YAZI_FILE_ONE` resolves to Scoop Git's
  `usr/bin/file.exe`. It is not a global command shim.
- The native opener syntax targets Yazi 26.9+.

## Usage

- `y` opens Yazi and leaves PowerShell in its final directory.
- Text files open in Vim.
- Images, video and audio open in the Windows-associated application.
- Standard navigation and previews do not require fzf or zoxide.

## Optional features

- The built-in fuzzy jump (`z`) requires fzf; the zoxide jump (`Z`) requires
  zoxide. Installing skim does not supply these dependencies.
- Bootstrap installs ffmpeg, 7zip, jq and poppler for video, archive, JSON and PDF
  previews, plus ripgrep for text search.
- Image-preview passthrough inside psmux still needs native Windows verification.

[Yazi configuration](https://yazi-rs.github.io/docs/configuration/yazi/)
