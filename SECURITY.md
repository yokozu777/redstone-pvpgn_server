# Security policy

This stack is a private game server for a LAN. It is not meant to be reachable from the public internet.

## Reporting a vulnerability

Report vulnerabilities through [GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) for this repository. Do not open a public issue for an unfixed vulnerability.

## What to change before anyone else can reach the host

Change `DB_PASSWORD`, `DB_ROOT_PASSWORD`, and `D2GS_PASSWORD` in `.env`. The values shipped in this tree are defaults.

A new database password is stored when `./mysql` is first created. Replacing the password in `.env` does not rewrite an existing data directory.

## Ports

Do not publish these ports beyond the LAN:

- `6112` TCP and UDP (Battle.net)
- `6113` TCP (Diablo II realm)
- `6114` TCP (Diablo II character database)
- `6115` TCP (Diablo 1)
- `6200` TCP (Warcraft III route)
- `4000` TCP (Diablo II game server)

MariaDB listens on the internal Docker network only. The compose file does not publish port `3306`.
