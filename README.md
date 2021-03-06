# Redmine PivotalMiner Plugin

Two-Way sync Pivotal Tracker stories/tasks to Redmine. Successor of [Trackmine plugin](https://github.com/capita/redmine_trackmine)

## Features

* Updating story in a Pivotal Tracker automatically creates a correspondent Redmine issue
* Map what to import. All User Stories are selected tags only
* Perform Import existing Pivotal Project Stories
* Pivotal Story tasks are created as related issues in Redmine.
* Updating a story in a Pivotal Tracker updates the Redmine issue attributes (subject, description, status)
* Redmine Issue status change will update Pivotal Story state
* Story points and Estimate hours are two-way synced
* Redmine keeps Pivotal Tracker description separate from Issue description
* Mapping between Pivotal Tracker and Redmine attributes can be configured
* Change priority in Redmine with tags from Pivotal Story and vise versa
* Milestones are maintained between Pivotal and Redmine via Tags
* Map any Redmine Status to any Pivotal State
* Map Redmine Users to Pivotal manual or with email automatcher
* Redmine keeps journal of all changes made via Sync
* Selective Sync(choose what parts of US or Issues to Sync)a

## Compatibility
  - Tested with Redmine 2.3.x - 2.4.x
  - Known to be working with 2.4.x - 3.1.x

## Setup
### Installation
Clone it into under plugins folder:
````
  $ git clone https://github.com/noma4i/pivotal_miner.git
````
Install missing gems:
````
  $ bundle install
````
Run migrations:
````
  $ rake redmine:plugins:migrate
````
### Configuration. Redmine side

#### pivotal_miner.yml

First of all you will need to setup `pivotal_miner.yml` (example included) and place it under `config` folder in Readmine

````
super_user:
  token: PIVOTAL_TRACKER_TOKEN

mappings:
  # tracker name for SubTasks
  tasks: Task
  # status name for task in Redmine in case it was deleted from Pivotal Tracker
  removed_task: Rejected
  # Tag name in Pivotal to change priority
  priority:
     P1: Immediate
     P2: Urgent
     P3: High
     P4: Medium
     P5: Low
  # User stories states map to Redmine issue states and vise versa
  story_states:
    unstarted: Pending
    started: Implementation
    finished: Resolved
    delivered: Resolved
    accepted: Closed
    rejected: Pending
  # Redmine Issue states map to Pivotal Story states
  issue_states:
    Pending: unstarted
    Implementation: started
    Resolved: finished
    Resolved: delivered
    Closed: accepted
    Pending: rejected
    Rejected: rejected
  # Redmine states map to Pivotal SubTasks 'ticks'
  task_states:
    Pending: open
    Implementation: open
    Resolved: closed
    Closed: closed
    Accepted: open
````

#### Create Custom Fields to enable plugin syncs:

##### Issue

- Pivotal Story ID (*type: integer*)
- Pivotal Task ID (*type: integer*)
- Pivotal Project ID (*type: integer*)
- Pivotal Story Description (*type: text*)

##### User
- Pivotal User ID (*type: integer*)

### Configuration. Pivotal Tracker side

Add Web Hook Url pointing to your Redmine app. To do that:

- On your project page choose `Project -> Configure Integrations`
- Find Activity Web Hook section

In `Web Hook Url` put `[redmine_app_url]/pivotal_activity.json` **`API_VERSION: 5`**

Example:

`http://my-company-redmine-site.org/pivotal_activity.json`

## Usage

Navigate to `Administration` panel and open `Pivotal Miner`. You will need to setup what projects to sync and what lablels to take. If you have users to link between Pivotal Tracker and Redmine you can make it manualy or automaticaly if emails are same.

## Author

Copyright (c) 2016 [Alexander Tsirel @noma4i](https://github.com/noma4i)

Copyright (c) 2010 - 2015 **Capita Unternehmensberatung GmbH. See LICENSE for details.**

*kindly sponsored by* [***Texuna Technologies Ltd***](http://texuna.com)

## Contribution Guide

Open Issue or send PR ;)
