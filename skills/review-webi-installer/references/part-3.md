# Part 3 — upstream project review

Start with the repeatable evidence collector:

```sh
sh skills/review-webi-installer/scripts/part3-checks.sh <owner/repo> [history-depth]
```

It performs a shallow upstream checkout (depth 100 by default; pass a larger
value when older history matters) and summarizes relevant files,
suspicious behavior patterns, dependencies, workflows, and the latest release.
Use the checkout for focused reading; the script does not replace human review.

Inspect the upstream README, source, build files, workflows, installers,
license, release history, and dependency declarations. Compare PR author,
upstream owner, release author, package name, and linked organization.

Search for credential, token, SSH key, browser-data, and environment
collection; persistence; profile changes; hidden services; unexpected network
uploads; obfuscation; dynamic code execution; subprocess and privilege use;
filesystem behavior; and container behavior.

Separate the installed launcher from code it later downloads or executes.
Record package feeds, plugins, native assets, transitive depth, floating
updates, and publisher/update trust boundaries. Prefer exact-version examples
where floating updates can replace code.

Do not spend time checking signatures unless integrity changes the install path.
Document intentional code execution and custom-feed trust boundaries as
warnings, not as malicious behavior.

Always record the current upstream release version. Write evidence with file or
URL references. Use the `read` tool on the report path to display the
complete Markdown contents; do not reconstruct it from memory. The assistant
response MUST include that complete report text and a short summary with
**Blockers**,
**Warnings**, **Passes**, and **Recommendation**. Do not give only the
recommendation. Then show the report:

```sh
sh skills/review-webi-installer/scripts/review.sh show 3 <part-3-report> --confirm
```
