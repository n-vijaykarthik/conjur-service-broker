Feature: Manage service binding

Scenario: Send a GET request to /v2/catalog

When I get "/v2/catalog""
Then the HTTP response status code is "200"
And the result is not empty
And there is a list of services
And the singular service is named "cyberark-conjur"
And the singular plan is named "community"
