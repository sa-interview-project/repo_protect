class ReceiverController < ApplicationController

    def create
        # Since we'll be making outbound requests to the GitHub API, we want to perform this asyncrhonously with Sidekiq 

        RepoWorker.perform_async(repo_params)
    end
    
    private 

    
    # Only grab the necessary payload keys for this service

    def repo_params
        #org_id = params["repository"]["id"]
        #issues_url = params["issues_url"]
        #login_id = ["sender"]["login"]
        
        params.permit(organization: [:login], repository: [:name], sender: [:login])
    end

end
