# Beta deployment and matrix

Beta requires all four pre-beta reports and human direction in the conversation.
The human manages and authorizes the process; the approval need not use special
words. Each approval applies only to the explicitly named next action. After
direction, the AI may run that requested deployment, test, or service command.
The AI must pause for fresh approval before each later action and must not
approve for itself.

For a normal package, the AI may run the requested command:

```sh
./scripts/deploy-installers.sh beta.webi.sh <pkg>
```

For classifier or `internal/releases/<pkg>` changes, use the webicached
deployment flow instead.

Use Apple Container on the actual ARM64 architecture when available. Use
`--cap-drop ALL`, no host `$HOME`, SSH or container sockets, host secrets, or
unrelated mounts. Install from `https://beta.webi.sh/<pkg>`, never the local
checkout. Run the command's version output and each credential-free README
happy path.

Matrix:

| Family | Images |
|---|---|
| Debian | 12, 13, Sid |
| Ubuntu | 22.04, 24.04, 26.04 when available |
| Alpine | 3.20, 3.22, 3.24 when available, or edge |

Record image, architecture, command, output, and pass/fail/blocked result. If a
platform fails, identify libc, runtime, architecture, or classification cause.
Unsupported platforms must be classified or documented.
