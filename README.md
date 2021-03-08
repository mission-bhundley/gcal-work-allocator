# Google Calendar Work Planner

Plan "working hours" on your Google Calendar across multiple projects.

It is scoped to a single week view, and uses time slots prior to your working
hours as a backlog / to-do list of project hours.

The idea is to drag hours into times when you actually perform the work, so it
can serve as a meeting blocker and a record of time spent per project.

![Usage](usage.gif)

### Requirements

- Docker

- Credentials for accessing the Google Calendar API

### Setup

1. Go to https://console.developers.google.com/apis/dashboard and enable the
Calendar API. Download the credentials file in JSON format.

1. Save the JSON credentials file you receive after enabling the Google Calendar
API to `config/credentials.json`.

1. Copy the example config to `config/config.yaml` and enter your project
details and calendar settings.

### Usage

On the first run you'll be asked to go to a Google OAuth link and enter the code
presented. Since you won't be verifying the app for public use, you'll be taken to a page where you <span style="color:red">see a warning</span>, but you must
proceed and allow the 2 permissions needed for API use against your account (it's *your* app, so don't worry).

In Chrome, you click **Advanced** > **Proceed to ... (unsafe)**.

```shell
# Insert events
./bin/workplanner_docker allocate

# Clear unused events
./bin/workplanner_docker scrub
```
