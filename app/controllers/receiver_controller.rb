class ReceiverController < ApplicationController

    # This ReceiverController#create endpoint accepts the webhook payload from GitHub
    def create
        # Since we'll be making outbound requests to the GitHub API, we want to perform this asyncrhonously with Sidekiq 
        RepoWorker.perform_async(repo_params)
    end
    
    private 
    
    # Only grab the necessary payload keys for this service
    def repo_params
        params.permit(organization: [:login], repository: [:name], sender: [:login]).to_h # Convert to a Hash for ease-of-use
    end

end
