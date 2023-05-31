FROM alpine as builder

ARG VERSION

COPY get.sh get.sh

RUN apk add bash
RUN chmod +x ./get.sh
RUN ./get.sh $VERSION

FROM alpine:3

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="hurlenko" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="filebrowser" \
    org.label-schema.description="Web File Browser which can be used as a middleware or standalone app" \
    org.label-schema.version=$VERSION \
    org.label-schema.url="https://github.com/hurlenko/filebrowser-docker" \
    org.label-schema.license="MIT" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/hurlenko/filebrowser-docker" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vendor="hurlenko" \
    org.label-schema.schema-version="1.0"


COPY --from=builder /usr/local/bin/filebrowser /filebrowser

#RUN /bin/sh -c 'mkdir -p -m 777 /srv/filebrowser/config && mkdir -p -m 777 /srv/filebrowser/data'

EXPOSE 8080
ENTRYPOINT ["/filebrowser"]
CMD ["--root=/srv/filebrowser/data", "--address=0.0.0.0", "--database=/srv/filebrowser/config/filebrowser.db"]
