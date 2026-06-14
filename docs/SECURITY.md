# Security & AI safety

Notes on the security posture of this setup, and a roadmap for the rest. These
machines are used in secure environments, so the bar is "professional, not
paranoid."

## In place today
- **SSH hardening** — `ssh/config`: strong ciphers only, keep-alives, `AddKeysToAgent`,
  `HashKnownHosts`. Host-specific details stay in gitignored `~/.ssh/config.local`.
- **Secret scanning** — `trufflehog` + `gitleaks` installed; `just secrets` scans a
  repo. (No global git hook — it would clobber Husky in Node projects; add a
  per-repo `pre-commit` instead.)
- **No secrets in git** — identity/secrets live in gitignored `*.local`
  (`~/.gitconfig.local`, `~/.ssh/config.local`, `~/.localrc`); history audited clean.
- **Claude read-deny** — `claude/settings.json` `permissions.deny` blocks Claude from
  reading `.env`, `~/.ssh`, `~/.aws`, `~/.gnupg`, `*.key`/`*.pem`, `*.local`,
  `secrets/`, `.npmrc`, gh tokens.

## AI secret safety — two distinct risks
1. **Agent holds real credentials** → could leak them via prompt injection.
2. **Sensitive content** in code/context is sent to the model provider.

### Credential brokering — agent-vault (recommended, not yet deployed)
[agent-vault](https://github.com/Infisical/agent-vault) (Infisical, MIT, ~1.7k★)
addresses risk #1: the agent uses dummy placeholders (`__anthropic_api_key__`) and
a self-hosted HTTPS proxy swaps in real credentials only at the outbound API call,
so the agent never holds a real secret.
- **Deploy self-hosted** (Docker on a server you control) — it's a TLS-intercepting
  MITM proxy, so only run an instance you control. It's in *preview* — pin a version.
- **Client wiring** (small): agents route via `HTTPS_PROXY`; set `AGENT_VAULT_ADDR`,
  `AGENT_VAULT_VAULT`, and `AGENT_VAULT_TOKEN` (the token is secret → `~/.localrc`).
- Status: **documented for later** — revisit when ready to deploy.

### Content redaction (risk #2 — optional)
If sensitive *data* (not just creds) might be sent: `claude-code-redact` (local
redaction proxy) or `noirdoc` (Claude PreToolUse hook) or Microsoft Presidio.
The deny-rules above already cover the common cases.

### Runtime secret injection (have the tool today)
Use **1Password CLI** (`op run -- <cmd>` / `op inject` with `op://` references)
to feed secrets at runtime instead of `.env` files on disk — nothing for an agent
or tool to read.

## Roadmap / not yet done
- **Commit signing** via 1Password SSH agent (`gpg.format = ssh`) — YubiKey-free,
  Secure-Enclave-backed. (Deferred.)
- Per-repo `pre-commit` with gitleaks for projects that handle real secrets.
- Deploy agent-vault on a server when ready.
