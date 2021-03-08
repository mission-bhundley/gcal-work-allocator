FROM ruby:3.0.0-alpine

COPY . /code

WORKDIR /code

# For timezone lib
RUN apk add --update tzdata

RUN apk add dumb-init

RUN bundle install --without=development

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/code/bin/workplanner"]
