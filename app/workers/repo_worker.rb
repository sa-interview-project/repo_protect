class RepoWorker
    include Sidekiq::Worker

    # Kick off the background job to process payload
    def perform(repo_params)
        org_name = repo_params["organization"]["login"]
        repo_name = repo_params["repository"]["name"]
        member_id = repo_params["sender"]["login"]

        # Initialize Oktokit client
        client = Oktokit::Client.new(:access_token => ENV["GITHUB_ACCESS_TOKEN"])

        # Create new protection on master branch, requiring PR before merging

        client.protect_branch("sa-interview-project/first-test", "master", {
            :enforce_admins => true, :required_pull_request_reviews => 
                {
                    :dismissal_restrictions => {}, 
                    :dismiss_stale_reviews =>  false, 
                    :require_code_owner_reviews => false
                }   
            })

        # Submit issue on the new repo and notify the repo creator with an @-mention, explaining the protection
        client.create_issue("#{org_name}/#{repo_name}", "Master branch protections for this repo"
             "Hi @#{member_id}! This repository has a few protections in place.")
    end
end