class RepoWorker
    include Sidekiq::Worker

    # Kick off the background job to process the webhook's payload
    def perform(push_params)
        repo_name = push_params["repository"]["full_name"]
        pusher_id = push_params["pusher"]["name"]
        
        # Configure Heroku client
        heroku = PlatformAPI.connect_oauth(ENV["H_OAUTH_TOKEN"])
        notified_repos = heroku.config_var.info_for_app('repo-protect')["NOTIFIED_REPOS"]

        # If repo name is not Heroku Config, update config var with repo name and create Issue
        if !notified_repos.include?(repo_name)
            # Append new repo name and update the config var
            notified_repos += "," + repo_name
            # Update config var with refreshed list
            heroku.config_var.update('repo_protect', {'NOTIFIED_REPOS' => notified_repos})

            # Initialize Octokit client
            client = Octokit::Client.new(:access_token => ENV["GITHUB_ACCESS_TOKEN"])

            # Create new protection on master branch, requiring PR before merging
            client.protect_branch("#{repo_name}", "master", {
                :enforce_admins => true, 
                :required_pull_request_reviews => 
                    {
                        :dismissal_restrictions => {}, 
                        :dismiss_stale_reviews =>  false, 
                        :require_code_owner_reviews => false,
                        :required_approving_review_count => 1
                    }   
                })

            # Submit issue on the new repo and notify the repo creator with an @-mention, explaining the protection
            client.create_issue("#{repo_name}", "Master branch protection has been created for the this repo",
                <<~HEREDOC
                    Hi @#{pusher_id}! We've enabled protection for this repository's master branch. Here's what this means:

                    * To merge your work into the master branch, you'll need to push a feature branch to this repo and open a PR.
                    * You'll need at least one other person on your team to approve your work. 
                    * Once they've approved, you'll be able to merge into master. 
                    * This restriction also to all users with admin privilege.  
                HEREDOC
    end
end