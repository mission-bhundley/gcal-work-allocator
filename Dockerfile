FROM ruby:3.0.0-alpine

COPY . /code

WORKDIR /code

# For timezone lib
RUN apk add --update tzdata

RUN bundle install --without=development

ENTRYPOINT ["/code/bin/workplanner"]
