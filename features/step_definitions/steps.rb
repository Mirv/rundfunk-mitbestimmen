feature_directory = Pathname.new(__FILE__).join('../..')
def sanitize_amount(amount)
  amount.gsub('€','').to_f
end

def login
  stub_jwt(@user)
  click_on 'Log in'
end

Given(/^I am logged in$/) do
  visit '/'
  @user = create(:user)
  login
end

Given(/^(?:I|we) have (?:these|this) broadcast(?:s)? in (?:my|our) database:$/) do |table|
  table.hashes.each do |row|
    attributes = { title: row['Title'] }
    if row['Medium']
      medium = Medium.all.find{|m| m.name == row['Medium'] } || create(:medium, name_de: row['Medium'], name_en: row['Medium'])
      attributes[:medium] = medium
    end
    if row['Station']
      station = Station.find_by(name: row['Station']) || create(:station, name: row['Station'])
      attributes[:station] = station
    end
    create(:broadcast, attributes)
  end
end

When(/^I visit the landing page$/) do
  visit '/'
  expect(page).to have_css('.ui.main.container')
end

Then(/^I can read:$/) do |string|
  expect(page).to have_text string
end

When(/^I click on "([^"]*)"$/) do |string|
  click_on string
end

Then(/^a new user was created in the database$/) do
  expect(User.count).to eq 1
end

Given(/^I have signed up two months ago/) do
  @email = 'legacy_user@example.org'
  @user = create(:user, email: @email)
end

Then(/^my login was successful$/) do
  wait_for_ajax
  expect(page).to have_text('Log out')
end

When(/^I visit the decision page$/) do
  visit '/decide'
  expect(page).to have_css('.decision-page')
end

When(/^I decide 'Support' for ([^"]*) and ([^"]*) but 'Next' for ([^"]*)$/) do |title1, title2, title3|
  3.times do
    wait_for_transition('.decision-card')
    expect(page).to have_css('.decision-card.fully-displayed')
    card = find('.decision-card.fully-displayed')
    [title1, title2].each do |title|
      if card.text.include? title
        find('.positive').click
      end
    end
    if card.text.include? title3
      find('.neutral').click
    end
  end
end

Then(/^the list of selectable broadcasts is empty$/) do
  wait_for_ajax
  expect(page).to have_css('.decision-page')
  expect(page).to have_css('.decision-card', count: 1) # the last one
  expect(page).not_to have_css('.decision-card-action.positive')
end

Then(/^the database contains these selections that belong to me:$/) do |table|
  mapping = {'Support' => 'positive', 'Next' => 'neutral'}
  my_selections = @user.selections
  table.hashes.each do |row|
    selection = my_selections.find {|s| s.broadcast.title == row['Title']}
    expect(selection.response).to eq(mapping[row['Answer']])
  end
end

Given(/^I want to give money to each of these broadcasts:$/) do |table|
  table.hashes.each do |row|
    b = create(:broadcast, title: row['Title'])
    create(:selection, user: @user, broadcast: b)
  end
end

When(/^I visit the invoice page$/) do
  visit '/invoice'
end

def check_invoice(ast_table)
  ast_table.hashes.each do |row|
    title = row['Title']
    amount = row['Amount']
    within('.invoice-item', text: /#{title}/) do
      expect(page).to have_text(amount)
    end
  end
end

Then(/^I can see that my budget of .*€ is distributed equally:$/) do |table|
  check_invoice(table)
end

Then(/^also in the database all selections have the same amount of "([^"]*)"$/) do |amount|
  amounts = Selection.pluck(:amount)
  expect(amounts.all? {|a| a == amount.to_f}).to be_truthy
end

Given(/^my invoice looks like this:$/) do |table|
  table.hashes.each do |row|
    title = row['Title']
    amount = sanitize_amount(row['Amount'])
    fixed = !! (row['Fixed'] =~ /yes/i)
    broadcast = create(:broadcast, title: title)
    create(:selection,
           user: @user,
           broadcast: broadcast,
           response: :positive,
           amount: amount.to_f,
           fixed: fixed
          )
  end
end

When(/^I look at my invoice/) do
  visit '/invoice'
end

When(/^I click on the 'X' next to ([^"]*)$/) do |title|
  invoice_table = find('#invoice-table')
  scroll_to(invoice_table)
  invoice_item = find('.invoice-item', text: /#{title}/)
  within(invoice_item) do
    find('.invoice-item-action-remove').click
  end
end

Then(/^my updated invoice looks like this:$/) do |table|
  wait_for_ajax
  check_invoice(table)
end

Then(/^my response to "([^"]*)" is listed in the database as "([^"]*)"$/) do |title, response|
  selection = @user.selections.find {|s| s.broadcast.title == title }
  expect(selection.response).to eq response
end


Given(/^I have many broadcasts in my database, let's say (\d+) broadcasts in total$/) do |number|
  number.to_i.times do
    create(:broadcast)
  end
end

Given(/^I click (\d+) times on 'Support'$/) do |number|
  number.to_i.times do
    wait_for_transition('.decision-card')
    expect(page).to have_css('.decision-card-action.positive')
    find('.decision-card-action.positive').click
  end
end

def change_amount(title, amount)
  invoice_table = find('#invoice-table')
  scroll_to(invoice_table)
  invoice_item = find('.invoice-item', text: /#{title}/)
  within(invoice_item) do
    find('.ember-inline-edit').click
    find('input').set(amount)
    find('.ember-inline-edit-save').click
  end
end

When(/^I change the amount of "([^"]*)" to "([^"]*)" euros$/) do |title, amount|
  change_amount(title, amount)
end

Then(/^the main part of the invoice looks like this:$/) do |table|
  wait_for_ajax
  check_invoice(table)
end

Then(/^I see the remaining budget at the bottom of the invoice:$/) do |table|
  table.hashes.each do |row|
    label = row['Label']
    amount = row['Amount']
    within('.invoice-footer') do
      within('tr', text: /#{label}/) do
        expect(page).to have_text(amount)
      end
    end
  end
end

When(/^I click on the german flag$/) do
  click_on 'Deutsch'
end

Then(/^I(?: can)? see the "([^"]*)" menu item$/) do |label|
  expect(page).to have_css('.button', text: label)
end

Given(/^I see a medium called "([^"]*)"$/) do |medium|
  within('.broadcast-search') do
    find('.ui.dropdown').click
    expect(page).to have_text(medium)
  end
end

When(/^I click on the lock symbol next to "([^"]*)"$/) do |title|
  invoice_table = find('#invoice-table')
  scroll_to(invoice_table)
  invoice_item = find('.invoice-item', text: /#{title}/)
  within(invoice_item) do
    find('.invoice-item-action-fix').click
  end
  wait_for_ajax
end

Given(/^the attribute 'fixed' is "([^"]*)" for my selected broadcast "([^"]*)"$/) do |value, title|
  selection = @user.selections.find {|s| s.broadcast.title ==  title }
  selection.reload
  if value == 'true'
    expect(selection).to be_fixed
  else
    expect(selection).not_to be_fixed
  end
end

When(/^I click on the unlock symbol next to "([^"]*)"$/) do |title|
  invoice_table = find('#invoice-table')
  scroll_to(invoice_table)
  invoice_item = find('.invoice-item', text: /#{title}/)
  within(invoice_item) do
    find('.invoice-item-action-unfix').click
  end
end

Given(/^these users want to pay money for these broadcasts:$/) do |table|
  table.hashes.each do |row|
    broadcast = Broadcast.find_by(title: row['Broadcast'])
    unless broadcast
      broadcast = create(:broadcast, title: row['Broadcast'])
    end
    user = User.find_by(email: row['Email'])
    unless user
      user = create(:user, email: row['Email'])
    end
    create(:selection,
           broadcast: broadcast,
           user: user,
           response: :positive,
           amount: sanitize_amount(row['Amount']))
  end
end

When(/^I visit the public statistics page$/) do
  visit '/statistics'
end

Then(/^I see this summary:$/) do |table|
  table.hashes.each do |row|
    item = find('.statistic-item', text: /#{row['Broadcast']}/)
    within(item) do
      expect(find('.votes')).to have_text(row['Reviews'])
      expect(find('.approval')).to have_text(row['Satisfaction'])
      expect(find('.average')).to have_text(row['Average'])
      expect(find('.total')).to have_text(row['Total'])
    end
  end
end

Given(/^I have (\d+) broadcasts in my database$/) do |number|
  description = 'I am displayed on fully visible decision cards'
  create_list(:broadcast, number.to_i, description: description)
end

Then(/^I see the buttons to click 'Support' or 'Next' only once, respectively$/) do
  expect(page).to have_css('.decision-card-action.positive', count: 1)
  expect(page).to have_css('.decision-card-action.neutral', count: 1)
end

Then(/^only the first card on the stack is displayed$/) do
  expect(page).to have_css('.decision-card .description', count: 1)
  description = find('.decision-card .description')
  expect(description).to have_text 'I am displayed on fully visible decision cards'
  expect(page).to have_css('.decision-card', count: 1) # only one card initially
end

Then(/^all of a sudden, there are more broadcasts again$/) do
  expect(page).to have_css('.decision-card', count: 1)
end

Given(/^there are (\d+) registered users$/) do |number|
  number.to_i.times { create(:user) }
end

Given(/^every user wants to pay (\d+) broadcasts each with €(\d+\.?\d*) each$/) do |number, amount|
  User.find_each do |user|
    number.to_i.times { create(:selection, user: user, amount: amount.to_f) }
  end
end

Then(/^I can see these numbers:$/) do |table|
  row = table.hashes.first
  expect(page).to have_css('.statistics.registered-users', text: row['Registered users'])
  expect(page).to have_css('.statistics.votes', text: row['Reviews'])
  expect(page).to have_css('.statistics.money-assigned', text: row['Money assigned'])
end

Then(/^there is a link that brings me to the statistics page$/) do
  click_on 'Statistics per broadcast'
  expect(page).to have_css('.statistics')
  expect(current_path).to eq '/statistics'
end

When(/^I click 'Next' when I am asked if I want to pay for the broadcast$/) do
  expect(page).to have_css('.decision-card-action.neutral')
  find('.decision-card-action.neutral').click
end

When(/^the decision card has disappeared$/) do
  wait_for_transition('.decision-card')
end

Then(/^I can still click on the 'Back' button$/) do
  expect(page).to have_css('.back.button')
  find('.back.button').click
end

Then(/^click 'I do support!'$/) do
  expect(page).to have_css('.decision-card-action.positive', text: /I do support!/)
  find('.decision-card-action.positive', text: /I do support!/).click
end

Then(/^the grey circle above turns into a green checkmark$/) do
  wait_for_transition('.decision-card')
  expect(page).to have_css('i.green.checkmark', count: 1)
end

Then(/^in the database my response is saved as 'positive'$/) do
  wait_for_ajax
  expect(Selection.count).to eq 1
  expect(Selection.first.response).to eq 'positive'
end

Given(/^I really like a broadcast called "([^"]*)"$/) do |title|
  @favourite_broadcast
end

Given(/^I have reviewed all broadcasts already$/) do
  expect(@user.selections.count).to eq Broadcast.count
end

Given(/^the form to create a new broadcast is there$/) do
  expect(page).to have_css('#broadcast-form')
end

When(/^I enter the title "([^"]*)" with the following description:$/) do |title, description|
  @title, @description = title, description
  fill_in 'title', with: title
  fill_in 'description', with: description
end

Then(/^a new broadcast was stored in the database with the data above$/) do
  broadcast = Broadcast.last
  expect(broadcast.title).to eq @title
  expect(broadcast.description).to eq @description
end

Given(/^there are (\d+) broadcasts in the database$/) do |number|
  number.to_i.times { create(:broadcast) }
end

When(/^I click 'Support' three times in a row$/) do
  3.times do
    expect(page).to have_css('.decision-card-action.positive')
    find('.decision-card-action.positive').click
    wait_for_transition '.decision-card'
  end
end

Then(/^message pops up, telling me I could reload more broadcasts$/) do
  within('.decision-card.reload-or-invoice') do
    expect(page).to have_text 'More suggestions'
  end
end

Then(/^then, the message is replaced with another one, requesting me this:$/) do |string|
  within('#help-message-new-broadcast') do
    expect(page).to have_text string
  end
end

Then(/^I see a form to enter a title and a description$/) do
  expect(page).to have_field('title')
  expect(page).to have_field('description')
end

Given(/^one broadcast with title "([^"]*)"$/) do |title|
  @broadcast = create(:broadcast, title: title)
end

Given(/^do not see the desired broadcast by coincidence$/) do
  Timeout::timeout(5) do
    expect(page).to have_css('.decision-card')
    its_there = find('.decision-card').text.include? @broadcast.title
    while its_there
      page.reset!
      visit '/decide'
      expect(page).to have_css('.decision-card')
      its_there = find('.decision-card').text.include? @broadcast.title
    end
  end
end

When(/^I search for "([^"]*)"$/) do |query|
  fill_in 'search', with: query
  @query = query
  click_on 'submit-search'
end

Then(/^there is exactly one search result$/) do
  expect(page).to have_text("1 result")
end

Then(/^the displayed broadcast has the title:$/) do |title|
  expect(page).to have_css '.decision-card'
  within '.decision-card' do
    expect(page).to have_text title
  end
end

Given(/^(\d+) out of (\d+) users want to pay for a show called "([^"]*)"$/) do |positive, total, title|
  @broadcast = create(:broadcast, title: title)
  create_list(:selection, positive.to_i, broadcast: @broadcast, response: :positive)
  neutral = total.to_i - positive.to_i
  create_list(:selection, neutral, broadcast: @broadcast, response: :neutral)
end

Given(/^the total amount collected for this show is €(\d+\.\d+)$/) do |amount|
  average = (amount.to_f / @broadcast.selections.positive.count.to_f)
  @broadcast.selections.positive.each do |s|
    s.amount = average
    s.save
  end
end

Given(/^(\d+) users of the app never voted on this show$/) do |number|
  create_list(:user, number.to_i)
end

Given(/^I get no search results$/) do
  expect(page).to have_text('no result')
end

Given(/^then the broadcast form pops up, encouraging me to create a new one$/) do
  expect(page).to have_css('#broadcast-form')
end

Given(/^I see the input field filled out with the title I searched for$/) do
  expect(page).to have_css('#title')
  expect(find('#title').value).to eq @query
end

When(/^I just hit "([^"]*)"$/) do |button|
  click_on button
end

Then(/^I get an error message$/) do |string|
  string.split('[...]').each do |part|
    expect(page).to have_css('.error.message', text: part.strip)
  end
end

Then(/^because I'm lazy, I just submit the broadcast's official website$/) do |string|
  fill_in 'description', with: string
  click_on 'Create'
end

Then(/^no broadcast was saved to the database$/) do
  expect(Broadcast.count).to eq 0
end

Given(/^yesterday I deselected a broadcast called "([^"]*)"$/) do |title|
  @broadcast = create(:broadcast, title: title)
  create(:selection, user: @user, broadcast: @broadcast, response: :neutral)
end

Given(/^today I learned that it is actually a broadcast that I really like$/) do
  # just documentation
end

When(/^I visit the broadcasts page$/) do
  visit '/broadcasts'
end

When(/^I click on the unimpressed smiley next to "([^"]*)"$/) do |title|
  expect(page).to have_text(title)
  within('.broadcast', {text: /#{title}/}) do
    find('button.reselect').click
  end
end

Then(/^the smiley turns happy$/) do
  within('.broadcast', {text: /#{@broadcast.title}/}) do
    expect(page).to have_css('button.unselect')
  end
end

Then(/^on my invoice, this broadcast shows up suddenly$/) do
  visit '/invoice'
  expect(page).to have_text(@broadcast.title)
end

Then(/^a label indicates the medium 'Radio' on the decision card$/) do
  expect(page).to have_css('.meta', text: 'Radio')
end

When(/^I want to create a new broadcast$/) do
  visit '/decide'
  expect(page).to have_css('.broadcast-form')
end

When(/^I type in "([^"]*)" and choose "([^"]*)" as medium$/) do |title, medium|
  fill_in 'title', with: title
  find('.selection', text: 'Select medium').click
  find('.item:not(.blank)', text: medium).click
end

When(/^I fill in a description and hit submit$/) do
  fill_in 'description', with: ('a' * 50)
  click_on 'Create'
end

Then(/^I see "([^"]*)"$/) do |string|
  expect(page).to have_text(string)
end

Then(/^a new radio broadcast is created in the database$/) do
  expect(Broadcast.count).to eq 1
  expect(Broadcast.first.medium.name).to eq 'Radio'
end

Then(/^the only (?:thing|broadcast) I see is "([^"]*)"$/) do |string|
  expect(page).to have_text(string)
end

def filter_by_medium(label)
  expect(page).to have_css('.selection', text: /Filter by medium/)
  find('.selection', text: /Filter by medium/).click
  expect(page).to have_css('.item:not(.blank)', text: label)
  find('.item:not(.blank)', text: label).click
end

When(/^I filter by medium "([^"]*)"$/) do |label|
  filter_by_medium(label)
end

Given(/^I reviewed the broadcast "([^"]*)" with this description:$/) do |title, description|
  @broadcast = create(:broadcast, title: title, description: description)
  create(:selection, broadcast: @broadcast, user: @user)
end

When(/^I click the edit button next to the title "([^"]*)"$/) do |title|
  within('tr.broadcast', text: title) do
    find('button.edit').click
  end
  wait_for_transition('.broadcast-form-modal')
end

When(/^I change the description to:$/) do |string|
  @better_description = string
  fill_in 'description', with: @better_description
end

Then(/^this better description was saved$/) do
  wait_for_ajax
  @broadcast.reload
  expect(@broadcast.description).to eq @better_description
end

def support_some_broadcasts(number)
  create_list(:broadcast, number)
  visit '/decide'
  @responses = number
  @responses.times do
    expect(page).to have_css('.decision-card-action.positive')
    find('.decision-card-action.positive').click
    wait_for_transition('.decision-card')
  end
end

Given(/^the statistics look like this:$/) do |table|
  table.hashes.each do |row|
    n_selections = row['Reviews'].to_i
    approval = row['Approval'].to_f/100.0
    n_positive = approval*n_selections
    average_amount = sanitize_amount(row['Total'])/n_positive
    n_neutral = (1.0 - approval)*n_selections

    station = if row['Station']
                Station.find_by(name: row['Station']) || create(:station, name: row['Station'])
              else
                nil
              end

    broadcast = create(:broadcast, title: row['Broadcast'], station: station)
    create_list(:selection, n_positive.to_i,
                broadcast: broadcast,
                response: :positive,
                amount: average_amount)
    create_list(:selection, n_neutral.to_i,
                broadcast: broadcast,
                response: :neutral)
  end
end

When(/^I click on the header "([^"]*)" once$/) do |header|
  find('th', text: header).click
end

Then(/^the table is sorted ascending by column "([^"]*)"$/) do |header|
  expect(page).to have_css('th.sorted.ascending', text: header)
end

Then(/^the table is sorted descending by column "([^"]*)"$/) do |header|
  expect(page).to have_css('th.sorted.descending', text: header)
end

Given(/^there are (\d+) remaining broadcasts$/) do |number|
  expect(page).to have_text("#{number} results")
end

def filter_by_station(label)
  find('.selection', text: 'Filter by station').click
  expect(page).to have_css('.item:not(.blank)', text: label)
  find('.item:not(blank)', text: label).click
end

Then(/^the displayed broadcast is either "([^"]*)" or "([^"]*)"$/) do |option1, option2|
  ok = [option1, option2].any? do |option|
    page.has_css?('.decision-card.fully-displayed', text: /#{option}/)
  end
  expect(ok).to be true
end

Then(/^the only station to choose from is "([^"]*)"$/) do |station|
  find('.selection', text: 'Filter by station').click
  within('.menu.visible') do
    expect(page).to have_css('.item:not(.blank)', text: station)
    expect(page).to have_css('.item:not(.blank)', count: 1)
  end
end

Given(/^we have (\d+) broadcasts in our database$/) do |count|
  create_list(:broadcast, count.to_i)
end

When(/^I click (\d+) times on 'Support' and (\d+) times on 'Next'$/) do |positives, neutrals|
  positives.to_i.times do
    wait_for_transition('.decision-card')
    expect(page).to have_css('.decision-card-action.positive')
    find('.decision-card-action.positive').click
  end

  neutrals.to_i.times do
    wait_for_transition('.decision-card')
    expect(page).to have_css('.decision-card-action.neutral')
    find('.decision-card-action.neutral').click
  end
end

Then(/^I am told to issue the invoice:$/) do |string|
  expect(page).to have_text(string)
end

Then(/^I see (\d+) checkmarks and (\d+) grey dots, labeled with "([^"]*)"$/) do |checkmarks, dots, string|
  expect(page).to have_css('i.green.checkmark.icon', count: checkmarks.to_i)
  expect(page).to have_css('i.grey.circle.icon', count: dots.to_i)
  expect(page).to have_css('.label', text: string)
end

Then(/^I am told to continue my search for more broadcasts:$/) do |string|
  expect(page).to have_text(string)
end

Then(/^there are no stations to choose from$/) do
  expect(page).not_to have_css('.selections', text: 'Filter by station')
end

Given(/^we have these media:$/) do |table|
  table.hashes.each do |row|
    create(:medium,
           name_en: (row['Medium'] || row['Medium_en']),
           name_de: (row['Medium'] || row['Medium_de']),
          )
  end
end

When(/^I choose "([^"]*)" from the list of available media$/) do |medium|
  find('.selection', text: 'Select medium').click
  find('.item:not(.blank)', text: medium).click
end

Given(/^we have these stations in our database:$/) do |table|
  table.hashes.each do |row|
    medium = Medium.all.find{|m| m.name == row['Medium'] } || create(:medium, name_de: row['Medium'], name_en: row['Medium'])
    create(:station, name: row['Station'], medium: medium)
  end
end

When(/^I choose "([^"]*)" from the list of "([^"]*)" stations$/) do |station, medium|
  filter_by_medium(medium)
  filter_by_station(station)
end

Given(/^there is another broadcast called "([^"]*)"/) do |title|
  broadcast = create(:broadcast, title: title)
end

Then(/^I see "([^"]*)".* but I don't see "([^"]*)"$/) do |see, dontsee|
  expect(page).to have_text(see)
  expect(page).not_to have_text(dontsee)
end

Given(/^I want to create a new broadcast that does not exist yet$/) do
  expect(Broadcast.count).to eq 0
  # if there are no broadcasts, a visit of /decide will open up the broadcast form

  visit '/decide'
  expect(page).to have_css('#broadcast-form')
end

When(/^I enter the following data:$/) do |table|
  row = table.hashes.first
  @title = row['Title']
  @description = row['Description']
  @medium_name = row['Medium']
  @station_name = row['Station']
  fill_in 'title', with: @title
  fill_in 'description', with: @description
  find('.selection', text: 'Select medium').click
  find('.item:not(.blank)', text: @medium_name).click
  expect(page).to have_css('.selection', text: 'Select station')
  find('.selection', text: 'Select station').click
  find('.item:not(.blank)', text: @station_name).click
end

Then(/^the created broadcast has got the exact data from above$/) do
  broadcast = Broadcast.last
  expect(broadcast.title).to eq @title
  expect(broadcast.description).to eq @description
  expect(broadcast.station.name).to eq @station_name
  expect(broadcast.medium.name).to eq @medium_name
end

Given(/^we have these stations:$/) do |table|
  table.hashes.each do |row|
    medium = create(:medium, name_en: row['Medium'], name_de: row['Medium'])
    create(:station, medium: medium, name: row['Station'])
  end
end

When(/^I click on the stations dropdown menu$/) do
  find('.selection', text: 'Filter by station').click
end

Then(/^the stations are ordered like this:$/) do |table|
  within('.filter-stations-field') do
    expect(all('.item:not(.blank)').map(&:text)).to eq(table.rows.flatten)
  end
end

Given(/^we have some more stations:$/) do |table|
  table.hashes.each do |row|
    medium = Medium.all.find{|m| m.name == row['Medium'] } || create(:medium, name_de: row['Medium'], name_en: row['Medium'])
    station = create(:station, name: row['Station'], medium: medium)
    create_list(:broadcast, row['#Broadcasts'].to_i, station: station, medium: medium)
  end
end

Then(/^I see that "([^"]*)" is aired on a "([^"]*)" station called "([^"]*)"$/) do |title, medium, station|
  expect(page).to have_css('.decision-card', count: 1)
  expect(page).to have_css('.decision-card .header', text: title)
  expect(page).to have_css('.decision-card .meta', text: medium)
  expect(page).to have_css('.decision-card .meta', text: station)
end

Then(/^no other account was created/) do
  expect(User.count).to eq 1
  visit '/'
  expect(find('.registered-users')).to have_text('1')
end

Given(/^there is no user in the database$/) do
  expect(User.count).to eq 0
end

When(/^I sign up$/) do
  @user = build(:user) # don't create
  stub_jwt(@user)
  expect(User.count).to eq 0
  click_on 'Log in'
end

When(/^I log in with my old credentials$/) do
  login
end

Then(/^there is just one result$/) do
  expect(page).to have_text('1 result')
end

Then(/^when I unselect the station$/) do
  within('.filter-stations-field') do
    find('.selection').click
    find('.item.blank').click
  end
end

Then(/^there are (\d+) results$/) do |number|
  expect(page).to have_text("#{number} result")
end

Then(/^when I unselect the medium$/) do
  within('.filter-media-field') do
    find('.selection').click
    find('.item.blank').click
  end
end

When(/^I click the accordion(?: once again)? on "([^"]*)"$/) do |label|
  find('.accordion .title', text: label).click
end

When(/^I visit the visualization page$/) do
  visit '/visualize'
end

Then(/^from the diff in the distribution I can see/) do |block|
  # just documentation
end

When(/^download the chart as SVG$/) do
  expect(page).to have_css('#chart-area')
  # export_button
  find('path.highcharts-button-symbol').click
  find('.highcharts-menu-item', text: 'SVG').click
end

def strip_highcharts_svg(content)
  result = content
  result = result.gsub(/\(#highcharts-[^)]*\)/, '(#highcharts)')
  result = result.gsub(/"highcharts-[^"]*"/, '"highcharts"')
  result
end

Then(/^the downloaded chart is exactly the same like the one in "([^"]*)"$/) do |path|
  expected_content = strip_highcharts_svg(File.read(feature_directory.join(path)))
  actual_content = strip_highcharts_svg(download_content)
  expect(expected_content).to eq actual_content
end
