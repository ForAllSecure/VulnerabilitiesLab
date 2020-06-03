# Contributing

When contributing to this repository, please first discuss the change
you wish to make via an issue.

Please note that we only include examples that have been responsibly
disclosed.  ForAllSecure follows Google Project Zero's
(disclosure
policy)[https://googleprojectzero.blogspot.com/p/vulnerability-disclosure-faq.html].

## Pull Request Process

 1. Ensure that your example passes `./mayhemit.sh --sanity <project directory>`.
 2. Ensure the `README.md` for your example is detailed.
 3. Ensure you have the rights for any files in the corpus. If you did
    not create them, you should include a note in your README.md of why
    they can be made open source.
 4. Do not use line widths over 80 characters (including newline). If
    you absolutely, positively must for code readability, that is ok.
    But if it's just your preferred editor preference, please realize
    and conform to ours. Tip: use hard newlines in your editor.
 5. Make sure you add the necessary github actions to perform
    CI/CD. We are currently using 1 job per image to parallelize builds.

## Code of Conduct

We follow the code of conduct from
(PurpleBooth)[https://gist.github.com/PurpleBooth/b24679402957c63ec426]. We
ask all contributors to follow it too.
