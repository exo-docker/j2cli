# j2cli

Jinja2 command line renderer packaged as a Docker image: [`exoplatform/j2cli`](https://hub.docker.com/r/exoplatform/j2cli).

It is used by the [eXo ADT](https://github.com/exoplatform/adt) to generate its configuration files from `*.j2` templates. The environment variables are the template context.

Since `2.0.0` the image is built on [jinjanator](https://github.com/kpfleming/jinjanator) (`jinjanate`), the maintained fork of [j2cli](https://github.com/kolypto/j2cli). The `1.x` tags are the legacy `j2cli 0.3.10` (Python 3.10, Jinja2 3.1.2) and are no longer rebuilt.

Current versions: jinjanator `25.3.1`, Jinja2 `3.1.6`, Python `3.12`.

## Usage

The entrypoint is `jinjanate --quiet` (no version banner on stderr, only the rendered result on stdout).

```bash
cat > hello.j2 <<'TPL'
host={{ DEPLOYMENT_EXT_HOST }}
{% if FEATURE_ENABLED == "true" %}feature is on{% endif %}
{{ MODE | default("SAML", true) }}
TPL

docker run --rm \
  -e DEPLOYMENT_EXT_HOST=acceptance.example.org -e FEATURE_ENABLED=true \
  -v "$PWD":"$PWD":ro \
  exoplatform/j2cli --undefined "$PWD/hello.j2"
```

- Use `--env-file` to give all the variables of a file (a multi-lines value isn't supported by Docker in this file).
- `--undefined` allows undefined variables, which are rendered as empty strings. Without it an undefined variable is an error.
- The template must be mounted in the container (read only is enough). The ADT mounts its directory on the same absolute path as on the host.
- Don't forward the `PATH` of your host with `--env-file`, it would override the one of the container.

Other options of `jinjanate` (data files in `json`/`yaml`/`ini`/`env` format, `--import-env`, ...) are described in the [jinjanator documentation](https://github.com/kpfleming/jinjanator).

### Without Docker

The ADT uses by order of preference `jinjanate`, `j2` and then this image. To use it directly on your host:

```bash
pipx install jinjanator
jinjanate --quiet --undefined template.j2
```

The legacy `j2cli` doesn't work with the recent Python versions (it imports the removed `imp` module).

## Build

```bash
docker build -t exoplatform/j2cli:test .
# use another jinjanator version
docker build --build-arg JINJANATOR_VERSION=25.3.1 -t exoplatform/j2cli:test .
```

## Tests

```bash
tests/smoke.sh exoplatform/j2cli:test
```

The smoke tests check the rendering of environment variables, conditions, filters, undefined variables, blank lines and a clean stderr. They run on each pull request (`.github/workflows/ci.yaml`) and before each publication.

## Publication

The `publish` GitHub workflow builds the multi-architecture image (`linux/amd64`, `linux/arm64`) once the smoke tests are green:

- a push on `master` publishes the `latest` tag
- a push of a tag `X.Y.Z` (for example `2.0.0`) publishes this tag

[Dependabot](.github/dependabot.yml) proposes the updates of the GitHub actions and of the base image every week. To update jinjanator, change `JINJANATOR_VERSION` in the `Dockerfile`.

## License

[AGPL-3.0](LICENSE)
