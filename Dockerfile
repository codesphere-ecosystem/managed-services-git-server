FROM codeberg.org/forgejo/forgejo:16.0.3-rootless

USER root

ARG USER_UID=1501
ARG USER_GID=1010

# Recreate Forgejo's system account with the IDs required by Codesphere. The
# account name stays "git" because the rootless entrypoint and Forgejo use it.
RUN deluser git \
    && addgroup -S -g "${USER_GID}" git \
    && adduser -S -H -D \
        -h /var/lib/gitea \
        -s /bin/bash \
        -u "${USER_UID}" \
        -G git \
        git \
    && chown -R "${USER_UID}:${USER_GID}" /var/lib/gitea

ENV USER=git \
    FORGEJO____RUN_USER=git

USER 1501:1010
