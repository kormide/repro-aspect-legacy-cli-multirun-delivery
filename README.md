# Apsect CLI selective delivery with multirun bug

This repo reproduces a bug when attempting to use a multirun delivery target with selective delivery under Aspect Workflows with the legacy CLI.

The delivery manifest step fails when using selective delivery (`only_on_change: true`) when building a release manifest including a rules_multirun target.

To reproduce, run:

```bash
./build.sh
```

The rules_multirun ruleset uses an older version of rules_python, but when the root module brings in a newer version with a fix for this [issue](https://github.com/bazel-contrib/rules_python/issues/2489), the `bazel outputs` command fails with:

```
skipping invalid runfiles manifest entry: '__init__.py '
skipping invalid runfiles manifest entry: 'rules_multirun+/__init__.py '
skipping invalid runfiles manifest entry: 'rules_multirun+/internal/__init__.py '
skipping invalid runfiles manifest entry: 'rules_multirun+/internal/_multirun.venv/__init__.py '
Error: failed to stat runfiles manifest entry ../../../../rules_python++python+python_3_11_x86_64-unknown-linux-gnu/bin/python3: stat ../../../../rules_python++python+python_3_11_x86_64-unknown-linux-gnu/bin/python3: no such file or directory
```

Since rules_python 2.0.0, each `py_binary` gets a build-time venv whose `bin/python3` is created with `ctx.actions.declare_symlink()`. Bazel writes such an entry to the runfiles manifest as `<runfiles path> <link target>`, where the target is relative to the entry's own directory in the runfiles tree:

`rules_multirun+/internal/_multirun.venv/bin/python3 ../../../../rules_python++python+python_3_11_x86_64-unknown-linux-gnu/bin/python3`
  
[AddRunfilesHash](https://github.com/aspect-build/aspect-cli-legacy/blob/main/pkg/aspect/outputs/hash.go) treats the right-hand side as a file path. For a relative path it tries `<output_base>/external/<path>`, then stats the raw path against the working directory. Neither exists for a symlink target, so it returns the error.

One workaround is to set the flag `common --@rules_python//python/config_settings:venvs_use_declare_symlink=no` (see [docs](https://rules-python.readthedocs.io/en/1.2.0/api/rules_python/python/config_settings/index.html#venvs_use_declare_symlink)). rules_python documents the flag as "only intended to work around" a packaging-rules issue, not as a supported configuration.

