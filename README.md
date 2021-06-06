# What is this? 

This repository contains a basic Rails service which automates master branch protection for newly created repos in the `sa-interview-project` GitHub org. Each time a new repository is created, a new issue will be created which notifies the repository creator with an @-mention - informing them of the master branch protection in place. 

# How do I use this?

The service is up and running on Heroku at the URL https://herokuapp.com/repo-protect. I've configured the GitHub webhook (which sends a payload when a repo is created) to send a JSON blob to this app's `/receive` endpoint. 

If, however, you'd like to manage this service directly ping @apdarr in order to be added as a collaborator on the Heroku app. Once you've been added as a collaborator, here's how to operate the `repo-protect` Heroku app: 

1. Install the Heroku CLI if you haven't already.
2. Be sure you have access to the `repo-protect` app. Ping @apdarr if you'd like to be added.
3. The app has one `worker` and one `web` dyno for operation. The status of these dynos can viewed by typing `heroku ps -a repo-protect` at the command-line. Unless these dynos are restarted they should both be `up` - thereby indicating they're ready to receive webhooks from GitHub. 
4. You can halt these dynos by running `heroku ps:stop -a repo-protect` in case you might want to temporarily pause the Heroku app from receiving requests. 
5. Check out `heroku ps --help` for a few other methods to control the web service's running.

# In more detail, how does it work:

When a user pushes to a GitHub repo, GitHub sends a webhook the app's `/receive` endpoint. In GitHub, you can confirm this destination by naviging to the org's Settings -> Webhooks -> and then viewing the Payload URL. 

With the configuration in `routes.rb`, this request is routed to the `ReceiverController#create` method. Note that there's a private method called `push_params` in `ReceiverController`. This private method acts as a basic Allow List so that only certain param keys are permitted for ingestion. 

With the right params in place, `ReceiverController#create` passes the Hash payload to a background worker running on a Sidekiq worker. Sidekiq requires Redis for operation, so I've attached a Heroku Redis instance to the `repo-protect` Heroku app. 

The `app/workers/repo_worker.rb` file then outlines the remainder of this master branch protection automation. Note that configuring this automation based on push events instead of when an repo is created. In order for master branch protection to exist, there has to be some code or file in the repo. A user might create a repo on GitHub, not upload any files to it, or just delete it after creation. We wouldn't want to send notifications in this case. 

As a result, we depend on push events to determine the first and only first time a user actually pushes code so that we can protect the newly pushed master branch. Once this repo's master branch has been protected, it's flagged in a `NOTIFIED_REPOS` [config var (which is persisted in Heroku)](https://devcenter.heroku.com/articles/config-vars). Future pushes to the same repo don't trigger a new notification as the running service is already aware of their existence. 

To kick off the notification process, this service uses the Octokit gem to interact with the GitHub API, which is authenticated through a GitHub OAuth Token. The worker protects the opened repo's master branch with the `:enforce_admins` and `:required_pull_request_reviews` (which requires at least one PR reviewer) restrictions.

Finally, a new issue is created which pings the user who created the repo. The opened issue quickly outlines the master branch protections in place 

# Who do I contact if I run into issues?

If there are any problems, concerns, or questions with this service, please don't hesitate to open a new Issue in _this_ repository (`repo_protect`) and ping @apdarr explaining your thoughts. 

# Next steps for improvement:

There are a few ways in which this project can be refined. Firstly, it doesn't have tests configured. While this proof-of-concept didn't _necessarily_ require tests, it's a best practice to add them for more robust usage. 

While the app is perfectly performant for its current use case, the project directory contains a fair amount of unnecessary files for its use. The app was created using the Rails API-only option (`rails new app --api`), but still, there are several files that don't need to exist. 

The app relies on checking a Heroku config var for repos that have already been notified. In an org with high-user activity, this service might run into scaling issues. However for most use cases, it should work fine. 

To further refine the automation, a next step for this project is likely to explore either incorporating a `sleep` mechanism that waits for a newly created repo to receive a code push, which would prevent the service from having to ingest all push events. Alternatively, relying on a Heroku config var isn't the most robust option but works fine for this use case. If we want to continue relying on push events, we should use a database for persistence.

I wanted to create a live, running, service and hence chose Heroku for deployment. As a result, there's no real "development" environment here. I'm a fan of `byebug` for debugging, but `byebug` isn't compatible with Heroku (unless there's a workaround of which I'm unaware). A good next step for this project would be to configure something like Ngrok for local development, outlining how to configure it in the README.md, and continuing to use Heroku for production.