{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.dandyrow;
  identity = config.dandyrow.sbxIdentity;

  enabled = osConfig != null && !cfg.isStandalone && (osConfig.sbx.enable or false);
  isWsl = osConfig != null && !cfg.isStandalone && (osConfig.wsl.enable or false);
  hostName =
    if cfg.isStandalone || osConfig == null then
      "standalone"
    else
      (osConfig.networking.hostName or "unknown");

  owner = "dandyrow";
  keyringService = "sbx-github-app";

  mintBackend =
    if identity.github.backend == "file" then
      ''
        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/sbx"
        app_id_file="$config_dir/github-app-id"
        key_file="$config_dir/github-app.pem"
        [ -r "$app_id_file" ] || die "GitHub App ID not found at $app_id_file. Run sbx-github-app-register on this host."
        [ -r "$key_file" ] || die "GitHub App private key not found at $key_file. Run sbx-github-app-register on this host."
        app_id="$(tr -d '[:space:]' < "$app_id_file")"
        key_source="$key_file"
      ''
    else
      ''
        app_id="$(secret-tool lookup service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind app-id)" \
          || die "GitHub App ID not found in GNOME Keyring (service ${identity.github.keyring.service}, host ${identity.hostName}). Run sbx-github-app-register on this host."
        key="$(secret-tool lookup service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind private-key)" \
          || die "GitHub App private key not found in GNOME Keyring (service ${identity.github.keyring.service}, host ${identity.hostName}). Unlock the keyring and run sbx-github-app-register."
        printf '%s' "$key" > "$tmp_dir/github-app.pem"
        key_file="$tmp_dir/github-app.pem"
        key_source="GNOME Keyring (service ${identity.github.keyring.service}, host ${identity.hostName})"
      '';

  storeBackend =
    if identity.github.backend == "file" then
      ''
        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/sbx"
        id_path="$config_dir/github-app-id"
        key_path="$config_dir/github-app.pem"
        if [ "$force" -eq 0 ] && { [ -e "$id_path" ] || [ -e "$key_path" ]; }; then
          die "Credentials already exist at $id_path or $key_path. Re-run with --force to replace them."
        fi
        install -d -m 700 "$config_dir"
        printf '%s\n' "$app_id" > "$id_path"
        printf '%s\n' "$pem" > "$key_path"
        chmod 600 "$id_path" "$key_path"
      ''
    else
      ''
        if [ "$force" -eq 0 ] && secret-tool lookup service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind app-id >/dev/null 2>&1; then
          die "Credentials already exist in GNOME Keyring (service ${identity.github.keyring.service}, host ${identity.hostName}). Re-run with --force to replace them."
        fi
        if [ "$force" -eq 1 ]; then
          secret-tool clear service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind app-id || true
          secret-tool clear service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind private-key || true
        fi
        printf '%s' "$app_id" | secret-tool store --label="sbx GitHub App ID (${identity.hostName})" service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind app-id \
          || die "Could not store the App ID in GNOME Keyring. Unlock the keyring and retry."
        printf '%s' "$pem" | secret-tool store --label="sbx GitHub App key (${identity.hostName})" service ${lib.escapeShellArg identity.github.keyring.service} host ${lib.escapeShellArg identity.hostName} kind private-key \
          || die "Could not store the private key in GNOME Keyring. Unlock the keyring and retry."
      '';

  registerNextSteps =
    if identity.github.backend == "file" then
      ''
        printf '%s\n' \
          "Personal-repo sandboxes on this host use the App token per sandbox:" \
          "  sbx secret set github --sandbox <name> --command 'sbx-github-mint'"
      ''
    else
      ''
        printf '%s\n' \
          "Set the global GitHub secret for this host:" \
          "  sbx secret set github --command 'sbx-github-mint'"
      '';

  mint = pkgs.writeShellApplication {
    name = "sbx-github-mint";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        curl
        jq
        openssl
      ]
      ++ lib.optionals (identity.github.backend == "keyring") [ pkgs.libsecret ];
    text = ''
      die() {
        printf 'sbx-github-mint: %s\n' "$*" >&2
        exit 1
      }

      umask 077
      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' EXIT

      app_id=""
      key_file=""
      key_source=""

      ${mintBackend}

      [ -n "$app_id" ] || die "GitHub App ID is empty. Run sbx-github-app-register on this host."
      case "$app_id" in
        *[!0-9]*)
          die "GitHub App ID is not numeric: $app_id. Run sbx-github-app-register on this host."
          ;;
      esac

      b64url() {
        openssl base64 -A | tr '+/' '-_' | tr -d '='
      }

      now="$(date +%s)"
      iat="$((now - 60))"
      exp="$((now + 600))"
      header="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | b64url)"
      payload="$(jq -cn --argjson iat "$iat" --argjson exp "$exp" --arg iss "$app_id" '{iat: $iat, exp: $exp, iss: $iss}' | b64url)"
      signing_input="$header.$payload"
      printf '%s' "$signing_input" > "$tmp_dir/signing-input"
      openssl dgst -sha256 -sign "$key_file" -out "$tmp_dir/signature" "$tmp_dir/signing-input" \
        || die "Could not sign the App JWT. The private key from $key_source is not a valid RSA key."
      signature="$(b64url < "$tmp_dir/signature")"
      jwt="$signing_input.$signature"

      api() {
        curl --silent --show-error --fail-with-body \
          --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 --retry-connrefused \
          -H "Authorization: Bearer $jwt" \
          -H "Accept: application/vnd.github+json" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          "$@"
      }

      if ! installations="$(api https://api.github.com/app/installations)"; then
        printf '%s\n' "$installations" >&2
        die "Could not list installations for App $app_id. Check network access and that the App still exists."
      fi

      installation_id="$(printf '%s' "$installations" | jq -r 'if type == "array" and length > 0 then .[0].id else empty end')" \
        || die "Could not parse the installation list from GitHub."
      if [ -z "$installation_id" ]; then
        die "App $app_id is not installed. Install it at https://github.com/apps/${identity.github.appName}/installations/new, then retry."
      fi

      if ! response="$(api -X POST "https://api.github.com/app/installations/$installation_id/access_tokens")"; then
        printf '%s\n' "$response" >&2
        die "Could not mint an installation token for installation $installation_id."
      fi

      token="$(printf '%s' "$response" | jq -r '.token // empty')" \
        || die "Could not parse the token response from GitHub."
      [ -n "$token" ] || die "GitHub returned no installation token for installation $installation_id."
      printf '%s\n' "$token"
    '';
  };

  register = pkgs.writeShellApplication {
    name = "sbx-github-app-register";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        curl
        jq
        openssl
        python3
      ]
      ++ lib.optionals (identity.github.backend == "keyring") [ pkgs.libsecret ];
    text = ''
            die() {
              printf 'sbx-github-app-register: %s\n' "$*" >&2
              exit 1
            }

            app_name=${lib.escapeShellArg identity.github.appName}
            owner=${lib.escapeShellArg identity.github.owner}
      default_port=${lib.escapeShellArg "47831"}
      port="$default_port"
            code=""
            force=0

            usage() {
              cat <<'EOF'
      Usage: sbx-github-app-register [OPTIONS]

      Register this host's GitHub App through GitHub's manifest flow and store its
      ID and private key in the host backend. The App permissions match the sandbox
      agent: Contents, Pull requests, Issues, Actions and Commit statuses write,
      Metadata read.

      Options:
        --app-name NAME   App name (default: host-specific dandyrow-agent-*)
        --owner LOGIN     GitHub account that owns the App (default: dandyrow)
        --port PORT       Local callback port (default: 47831)
        --code CODE       Skip the browser callback and convert an existing code
        --force           Replace credentials already present in the backend
        -h, --help        Show this help
      EOF
            }

            while [ "$#" -gt 0 ]; do
              case "$1" in
                --app-name)
                  [ "$#" -ge 2 ] || die "--app-name needs a value"
                  app_name="$2"
                  shift 2
                  ;;
                --owner)
                  [ "$#" -ge 2 ] || die "--owner needs a value"
                  owner="$2"
                  shift 2
                  ;;
                --port)
                  [ "$#" -ge 2 ] || die "--port needs a value"
                  port="$2"
                  shift 2
                  ;;
                --code)
                  [ "$#" -ge 2 ] || die "--code needs a value"
                  code="$2"
                  shift 2
                  ;;
                --force)
                  force=1
                  shift
                  ;;
                -h | --help)
                  usage
                  exit 0
                  ;;
                *)
                  die "Unknown argument: $1"
                  ;;
              esac
            done

            case "$port" in
              "" | *[!0-9]*)
                die "Port must be a number: $port"
                ;;
            esac

            umask 077
            tmp_dir="$(mktemp -d)"
            server_pid=""
            trap 'if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || true; fi; rm -rf "$tmp_dir"' EXIT

            if [ -z "$code" ]; then
              state="$(openssl rand -hex 16)"
              redirect_url="http://localhost:$port/callback"
              manifest="$tmp_dir/manifest.json"
              jq -n \
                --arg name "$app_name" \
                --arg url "https://github.com/$owner" \
                --arg redirect "$redirect_url" \
                '{
                  name: $name,
                  url: $url,
                  redirect_url: $redirect,
                  public: false,
                  default_permissions: {
                    contents: "write",
                    pull_requests: "write",
                    issues: "write",
                    actions: "write",
                    statuses: "write",
                    metadata: "read"
                  },
                  default_events: []
                }' > "$manifest"

              server="$tmp_dir/callback.py"
              cat > "$server" <<'PY'
      import html
      import http.server
      import sys
      import urllib.parse

      port = int(sys.argv[1])
      manifest_path = sys.argv[2]
      state = sys.argv[3]
      out_path = sys.argv[4]
      app_name = sys.argv[5]
      bind_host = sys.argv[6]

      with open(manifest_path, encoding="utf-8") as handle:
          manifest = handle.read()


      class Handler(http.server.BaseHTTPRequestHandler):
          def log_message(self, *_args):
              pass

          def send_text(self, status, body, content_type="text/html; charset=utf-8"):
              data = body.encode("utf-8")
              self.send_response(status)
              self.send_header("Content-Type", content_type)
              self.send_header("Content-Length", str(len(data)))
              self.end_headers()
              self.wfile.write(data)

          def do_GET(self):
              parsed = urllib.parse.urlparse(self.path)
              if parsed.path == "/":
                  body = (
                      "<!doctype html><meta charset=\"utf-8\"><title>Register %s</title>"
                      "<form id=\"f\" action=\"https://github.com/settings/apps/new?state=%s\" method=\"post\">"
                      "<input type=\"hidden\" name=\"manifest\" value=\"%s\">"
                      "<button type=\"submit\">Create GitHub App</button></form>"
                      "<p>If the form does not submit itself, click the button.</p>"
                      "<script>document.getElementById(\"f\").submit()</script>"
                  ) % (html.escape(app_name), html.escape(state, quote=True), html.escape(manifest, quote=True))
                  self.send_text(200, body)
                  return
              if parsed.path == "/manifest.json":
                  self.send_text(200, manifest, "application/json; charset=utf-8")
                  return
              if parsed.path == "/callback":
                  query = urllib.parse.parse_qs(parsed.query)
                  received = query.get("state", [""])[0]
                  received_code = query.get("code", [""])[0]
                  if received != state:
                      self.send_text(400, "<h1>State mismatch</h1><p>Close this tab and rerun the command.</p>")
                      return
                  if not received_code:
                      self.send_text(400, "<h1>Missing code</h1><p>Close this tab and rerun the command.</p>")
                      return
                  with open(out_path, "w", encoding="utf-8") as handle:
                      handle.write(received_code)
                  self.send_text(200, "<h1>GitHub App created</h1><p>Close this tab and return to the terminal.</p>")
                  raise SystemExit(0)
              self.send_text(404, "<h1>Not found</h1>")


      httpd = http.server.HTTPServer((bind_host, port), Handler)
      print("Waiting for the GitHub callback on http://localhost:%d/" % port, file=sys.stderr)
      httpd.serve_forever()
      PY

              python3 "$server" "$port" "$manifest" "$state" "$tmp_dir/code" "$app_name" "${
                if identity.isWsl then "0.0.0.0" else "127.0.0.1"
              }" &
              server_pid=$!
              sleep 0.5
              if ! kill -0 "$server_pid" 2>/dev/null; then
                die "Callback server failed to start on port $port. Pick a free port with --port."
              fi

              printf '\nOpen http://localhost:%s/ in a browser logged in to GitHub as %s.\n' "$port" "$owner" >&2
              printf 'If the browser cannot reach this host, copy the code from the failed callback URL and rerun with --code <code>.\n' >&2

              remaining=600
              while [ "$remaining" -gt 0 ]; do
                if [ -s "$tmp_dir/code" ]; then
                  break
                fi
                if ! kill -0 "$server_pid" 2>/dev/null; then
                  die "Callback server stopped before GitHub returned a code."
                fi
                remaining="$((remaining - 1))"
                sleep 1
              done
              [ -s "$tmp_dir/code" ] || die "Timed out waiting for the GitHub callback. Rerun with --code <code>."

              code="$(cat "$tmp_dir/code")"
              kill "$server_pid" 2>/dev/null || true
              wait "$server_pid" 2>/dev/null || true
              server_pid=""
            fi

            if ! response="$(curl --silent --show-error --fail-with-body \
              --connect-timeout 10 --max-time 30 \
              -X POST \
              -H "Accept: application/vnd.github+json" \
              -H "X-GitHub-Api-Version: 2022-11-28" \
              "https://api.github.com/app-manifests/$code/conversions")"; then
              printf '%s\n' "$response" >&2
              die "Could not convert the manifest code. Codes expire after one hour and can be used once."
            fi

            app_id="$(printf '%s' "$response" | jq -er '.id')" \
              || die "GitHub did not return an App ID. The manifest code may already have been used."
            pem="$(printf '%s' "$response" | jq -er '.pem')" \
              || die "GitHub did not return an App private key. The manifest code may already have been used."
            slug="$(printf '%s' "$response" | jq -er '.slug')" \
              || die "GitHub did not return an App slug."

            ${storeBackend}

            printf '\nRegistered GitHub App %s (id %s).\n' "$slug" "$app_id"
            printf 'Install it at https://github.com/apps/%s/installations/new\n' "$slug"
            ${registerNextSteps}
    '';
  };
in
{
  options.dandyrow.sbxIdentity = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = enabled;
      defaultText = lib.literalExpression "osConfig.sbx.enable or false";
      description = "Whether sbx is enabled for this host.";
    };

    isWsl = lib.mkOption {
      type = lib.types.bool;
      default = isWsl;
      defaultText = lib.literalExpression "osConfig.wsl.enable or false";
      description = "Whether this host runs under WSL.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = hostName;
      description = "NixOS host name used in App names and keyring attributes.";
    };

    gitIdentity = {
      name = lib.mkOption {
        type = lib.types.str;
        default = if identity.isWsl then "Copilot" else "opencode-agent[bot]";
        description = "Git author and committer name for sandboxed agents.";
      };

      email = lib.mkOption {
        type = lib.types.str;
        default =
          if identity.isWsl then
            "198982749+Copilot@users.noreply.github.com"
          else
            "219766164+opencode-agent[bot]@users.noreply.github.com";
        description = "Git author and committer email for sandboxed agents.";
      };
    };

    github = {
      owner = lib.mkOption {
        type = lib.types.str;
        default = owner;
        description = "GitHub account that owns this host's App.";
      };

      appName = lib.mkOption {
        type = lib.types.str;
        default = "dandyrow-agent-${lib.toLower identity.hostName}";
        description = "GitHub App name for this host.";
      };

      backend = lib.mkOption {
        type = lib.types.enum [
          "file"
          "keyring"
        ];
        default = if identity.isWsl then "file" else "keyring";
        description = "Where this host stores the App ID and private key.";
      };

      mintCommand = lib.mkOption {
        type = lib.types.str;
        default = "sbx-github-mint";
        description = "Command that prints a GitHub App installation token to stdout.";
      };

      keyring = {
        service = lib.mkOption {
          type = lib.types.str;
          default = keyringService;
          description = "GNOME Keyring service attribute for App credentials.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = identity.hostName;
          description = "GNOME Keyring host attribute for App credentials.";
        };
      };
    };
  };

  config = lib.mkIf identity.enable {
    home.packages = [
      mint
      register
    ];
  };
}
