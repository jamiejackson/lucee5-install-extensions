# lucee5-install-extensions

Scripted Installation of Extensions in Lucee 5

## Purpose

Lucee 5 provides an easy way to install extensions (drop a `*.lex` file into the `deploy` directory), but it's completely opaque about the installation progress.
Therefore, unless you're smart about deducing installation completion in your automation, you can easily interrupt the installation without noticing it.

This is especially true in docker builds, where it's easy to build an image with a corrupt extension installation because not enough time was allowed for the installation to complete.

This approach jumps through hoops to keep checking until the extension appears in the Lucee administrator.
