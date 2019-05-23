class WorkSpace < ApplicationRecord
  has_and_belongs_to_many :polling_stations
  has_many :turnout_observations

  before_validation :create_identifier, on: :create

  def to_param
    self.identifier
  end

  def latest_observations
    polling_stations.map do |ps|
      most_recent_observation = \
        most_recent_observation_for(ps) || UnobservedTurnoutObservation.new

      OpenStruct.new(
        polling_station: ps,
        turnout_observation: most_recent_observation
      )
    end.group_by do |observation_pair|
      observation_pair.polling_station.polling_district
    end.map do |_district_code, observation_pairs|
      PollingDistrict.new(observation_pairs)
    end.sort_by do |district|
      [
        -district.guesstimated_labour_votes_left,
        -district.pre_election_labour_promises
      ]
    end
  end

  private

  def create_identifier
    self.identifier = XKPassword.generate.downcase
  end

  def most_recent_observation_for(polling_station)
    self.turnout_observations
      .where(polling_station: polling_station)
      .order(created_at: :desc)
      .limit(1).first
  end
end
