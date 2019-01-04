FROM golang:latest AS golang

WORKDIR /go/src/github.com/bitly/oauth2_proxy
COPY . .
RUN rm -rf _dist bin oauth2_proxy
RUN go get -u github.com/golang/dep/cmd/dep && dep ensure
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o oauth2_proxy .

FROM alpine:latest
RUN apk add --update ca-certificates openssl
COPY --from=golang /go/src/github.com/bitly/oauth2_proxy/oauth2_proxy /

EXPOSE 8080 4180
ENTRYPOINT ["/oauth2_proxy"]
