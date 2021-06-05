class RepoWorker
    include Sidekiq::Worker

    # Kick off the background job to process the webhook's payload
    def perform(push_params)
        repo_name = push_params["repository"]["full_name"]
        pusher_id = push_params["pusher"]["name"]

        # Initialize Oktokit client
        client = Octokit::Client.new(:access_token => ENV["GITHUB_ACCESS_TOKEN"])

        # Create new protection on master branch, requiring PR before merging
        client.protect_branch("#{repo_name}", "master", {
            :enforce_admins => true, 
            :required_pull_request_reviews => 
                {
                    :dismissal_restrictions => {}, 
                    :dismiss_stale_reviews =>  false, 
                    :require_code_owner_reviews => false
                }   
            })

        # Submit issue on the new repo and notify the repo creator with an @-mention, explaining the protection
        client.create_issue("#{repo_name}", "Master branch protection has been created for the this repo",
            "Hi @#{pusher_id}! We've enabled protection for this repository's master branch. Here's what this means:")
    end
end