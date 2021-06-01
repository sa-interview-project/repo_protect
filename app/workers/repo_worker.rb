class RepoWorker
    include Sidekiq::Worker
    
    # Kick off the background job to process payload and protect the master branch
    def perform
        puts repo_params 
    end
end