Feature: Security Considerations

  Scenario: Conjur API key should only exist in memory
    Then the environment contains an invalid conjur api key
    Then the rotated conjur api key is valid