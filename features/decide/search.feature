@33
Feature: Search on decision page
  As a user
  I want to search the list of broadcasts by title
  To find my favourite shows

  Background:
    Given I am logged in

  Scenario: Search by title
    Given I have 10 broadcasts in my database
    And one broadcast with title "Search for: keyword"
    And I visit the decision page
    And I see 9 broadcasts to choose from
    When I search for "keyword"
    Then there is exactly one search result
    And the only displayed broadcast has the title:
    """
    Search for: keyword
    """
