@38
Feature: Lead the user through the suggestions
  As a user
  I want to get a suggestion when a pile of decision cards runs out - issue the invoice or draw new cards?
  Because I do not know when it is a good moment to review the invoice

  Background:
    Given we have 10 broadcasts in our database
    And I am logged in
    When I visit the decision page

  Scenario: Tell the user to issue the invoice
    When I click 3 times on 'Support' and 7 times on 'Next'
    Then I see 3 checkmarks and 7 grey dots, labeled with "10/10"
    And I am told to issue the invoice:
    """
    You have already found 3 broadcasts, that you want to pay for. Now
    distribute your budget among these broadcasts.
    """

  Scenario: Tell the user to repeat until he finds enough broadcasts
    When I click 1 times on 'Support' and 9 times on 'Next'
    Then I see 1 checkmarks and 9 grey dots, labeled with "10/10"
    And I am told to continue my search for more broadcasts:
    """
    You have found only 1 broadcast that you want to pay for. Click on More
    suggestions, to find even more relevant broadcasts.
    """

