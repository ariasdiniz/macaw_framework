# Contributing to Macaw Framework

First off, thank you for considering contributing to Macaw Framework.

## Getting Started

- Submit an issue for your problem or suggestion, assuming one does not already exist.
    - Clearly describe the issue including steps to reproduce when it is a bug.
    - Make sure you fill in the earliest version that you know has the issue.

## Making Changes

- Fork the repository on GitHub.
- Create a topic branch from where you want to base your work. This is usually the main branch.
    - To quickly create a topic branch based on main; `git checkout -b fix/main/my_contribution main`. Please avoid working directly on the `main` branch.
- Make commits of logical units.
- Check for unnecessary whitespace with `git diff --check` before committing.
- Make sure your commit messages are in the proper format.
- Make sure you have added the necessary tests for your changes.
- Run _all_ the tests to assure nothing else was accidentally broken.

## Submitting Changes

- Run RuboCop to ensure your code adheres to our code style conventions. You can do this by running `rubocop` in your terminal.
- Push your changes to a topic branch in your fork of the repository.
- Submit a pull request to the repository in my GitHub account.
- Our automatic CI/CD pipeline will run all tests and lint for 3 different ruby versions before merges.
- I'm constantly reviewing Pull Requests and will provide feedback as soon as possible.

Thanks for contributing!
