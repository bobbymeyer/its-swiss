# Published specimens

A version-stamped specimen that something outside this repository points at —
a blog post, a release note — kept here so it survives a deploy.

Pages replaces the whole site on every deploy, so `.github/workflows/pages.yml`
publishes this directory alongside the specimen it renders for the current
version. A page in here is never regenerated: it is what that version looked
like, which is the only reason to pin to one.

To add a version, check that version out and run `bin/specimen`, then commit
the version-stamped file it writes:

    git checkout v0.6.0
    bin/specimen out && cp out/0.6.0.html published/
