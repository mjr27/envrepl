# envrepl

Envsubst replacement. Most used in SPA dynamic configuration.

## Features

* **Static** binary below **`200kb`** 
* Ability to customize macro prefix (when `$` is not supported)
* Does not replace missing environment variables (like `$http_host` in nginx.conf) unless default value is specified

## Usage

```
envrepl -- 

Replaces environment variables in specified files

Usage:
  envrepl [options] COMMAND

Commands:

  batch
  pipe

Options:
  -c, --character=CHARACTER  Variable expanded character (for variables like ${VAR} it should be $) (default: $)
  -p, --prefix=PREFIX        Prefix of environment variables to include. E.g REACT_APP_
  -m, --skip-missing         Do not substitute missing variables without default values.
  -s, --strip-prefix         Strip prefix on replace. If prefix is `REACT_APP_`, then `${VAR}` will be taken from `env.REACT_APP_VAR`
  -v, --verbose              Verbose logging
  -h, --help                 Show this help
```

## Samples

```bash
$ export MY_VAR=Value

$ echo '${MY_VAR}' | ./envrepl
Value

$ echo '${MISSING_VAR}' | ./envrepl
${MISSING_VAR}

$ echo '${MISSING_VAR:defaultValue}' | ./envrepl
defaultValue

$ echo '@{MY_VAR}' | ./envrepl -c @
Value

$ echo '@{VAR}' | ./envrepl -c @
@{VAR}

$ echo '@{VAR}' | ./envrepl -c @ -p "MY_" -s
Value

$ echo '@{VAR2:defaultValue}' | ./envrepl -c @ -p "MY_" -s
defaultValue

$ echo '@{MISSING_VAR:{\}}'  > test.txt
$ cat test.txt
@{MISSING_VAR:{\}}
$ ./envrepl -c @ batch test.txt
$ cat test.txt
{}

```

## Docker usage

`production.env`:
```
REACT_APP_BASE_URL=@{REACT_APP_BASE_URL}
```

`Dockerfile`:
```dockerfile
FROM node AS build
WORKDIR /app/
COPY production.env .env
COPY ./ .
RUN npm install
RUN npm run build

FROM mjr27/envrepl as envrepl

FROM nginxinc/nginx-unprivileged:stable-alpine
COPY --from=envrepl --chown=nginx /envrepl /bin/envrepl
COPY --from=build /app /app
CMD ["sh", "-c", "envrepl -c '@' -p REACT_APP_ batch /app/static/ && nginx -g 'daemon off;' "]
```

## Building

```bash
$ nimble tasks
release        libc release build
static        static release build. Musl if possible

$ nimble static 

```

## Testing

```bash
$ testament all
```

or 

```bash
$ testament c replacer
```
