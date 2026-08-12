{ lib }:
{
  home,
  git,
  caCert ? null,
  chownTo ? null,
}:
let
  dir = "${home}/.dotfiles";
  url = "https://github.com/dandyrow/dotfiles.git";
  # Only cert var forwarded into the root install context (for work machines).
  sslPrefix = lib.optionalString (caCert != null) "GIT_SSL_CAINFO=${caCert} ";
  chownLine = lib.optionalString (chownTo != null) ''chown -R ${chownTo} "${dir}"'';
in
''
  if [ ! -d "${dir}" ]; then
    ${sslPrefix}${git} clone \
      ${url} \
      "${dir}"
    ${chownLine}
  fi
''
