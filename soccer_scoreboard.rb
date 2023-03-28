require 'tk'
require 'rest-client'
require 'json'

api_key = '46a58db47dc645dfb0fb49632ae43e9f'

leagues_url = 'http://api.football-data.org/v2/competitions'
leagues_response = RestClient.get(leagues_url, { 'X-Auth-Token': api_key })
leagues_data = JSON.parse(leagues_response.body)

teams_url = 'http://api.football-data.org/v2/teams'
teams_response = RestClient.get(teams_url, { 'X-Auth-Token': api_key })
teams_data = JSON.parse(teams_response.body)

teams_by_league = {}
leagues_data['competitions'].each do |league|
  league_teams_url = "http://api.football-data.org/v2/competitions/#{league['id']}/teams"
  league_teams_response = RestClient.get(league_teams_url, { 'X-Auth-Token': api_key })
  league_teams_data = JSON.parse(league_teams_response.body)
  teams_by_league[league['name']] = league_teams_data['teams'].map { |team| team['name'] }
end

root = TkRoot.new { title "Football Scores" }

league_label = TkLabel.new(root) { text "Select a league:" }
league_menu = TkOptionMenubutton.new(root) do
  relief 'raised'
  options teams_by_league.keys.sort
  pack('side' => 'left', 'padx' => '10', 'pady' => '10')
end

team_label = TkLabel.new(root) { text "Select a team:" }
team_menu = TkOptionMenubutton.new(root) do
  relief 'raised'
  options []
  pack('side' => 'left', 'padx' => '10', 'pady' => '10')
end

score_label = TkLabel.new(root) { text "" }
score_label.pack('side' => 'bottom', 'padx' => '10', 'pady' => '10')

league_menu.command { |league|
  teams = teams_by_league[league]
  team_menu.options_clear
  team_menu.options teams.sort
}

team_menu.command { |team|
  scores_url = "#{teams_url}/#{URI.encode_www_form_component(team)}/matches"
  scores_response = RestClient.get(scores_url, { 'X-Auth-Token': api_key })
  scores_data = JSON.parse(scores_response.body)

  scores = []
  scores_data['matches'].each do |match|
    if match['status'] == 'FINISHED'
      scores << "#{match['homeTeam']['name']} #{match['score']['fullTime']['homeTeam']}-#{match['score']['fullTime']['awayTeam']} #{match['awayTeam']['name']}"
    elsif match['status'] == 'SCHEDULED'
      scores << "#{match['homeTeam']['name']} vs #{match['awayTeam']['name']}, #{match['utcDate']}"
    end
  end

  score_label.configure('text', scores.join("\n"))
}

Tk.mainloop
