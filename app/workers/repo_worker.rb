class RepoWorker
    include Sidekiq::Worker

    # Kick off the background job to process the webhook's payload
    def perform(repo_params)
        org_name = repo_params["organization"]["login"]
        repo_name = repo_params["repository"]["name"]
        member_id = repo_params["sender"]["login"]

        # Initialize Oktokit client
        client = Octokit::Client.new(:access_token => ENV["GITHUB_ACCESS_TOKEN"])

        # Create new protection on master branch, requiring PR before merging
        client.protect_branch("sa-interview-project/#{repo_name}", "master", {
            :enforce_admins => true, 
            :required_pull_request_reviews => 
                {
                    :dismissal_restrictions => {}, 
                    :dismiss_stale_reviews =>  false, 
                    :require_code_owner_reviews => false
                }   
            })

        # Submit issue on the new repo and notify the repo creator with an @-mention, explaining the protection
        client.create_issue("#{org_name}/#{repo_name}", "Master branch protection has been created for the #{repo_name} repo"
            # Inform the user what the protections are 
         # --> ADD DETAIL   "Hi @#{member_id}! We've enabled protection for this repository's master branch. Here's what this means:")
    end
end