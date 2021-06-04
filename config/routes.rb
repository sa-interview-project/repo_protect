Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # The callback URL, https://herokuapp.repo-protect.com/receive, sends requests to the ReceiverController#create method 
  post 'receive', to: 'receiver#create'

end
