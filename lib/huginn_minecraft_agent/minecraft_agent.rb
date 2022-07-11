module Agents
  class MinecraftAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule "every_1h"

    description <<-MD
      The Minecraft Agent creates an event with status change for example.

      I created with [mcsrvstat](https://mcsrvstat.us/) because I'm not able to find how to communicate with a Bedrock server instance.

      `mc_server` is the url of the Minecraft server 

      `player_alert` is used for creating an event if there is a change about the number of players.

      `status_alert` is used for creating an event if there is a change about the status of the server.

      The website cache is 10mn so not needed to decrease scheduling < 30mn.

      Set `expected_update_period_in_days` to the maximum amount of time that you'd expect to pass between Events being created by this Agent.

    MD

    event_description <<-MD
      Events look like this:

          {
            "ip": "XXX.XXX.XXX.XXX",
            "port": 25565,
            "debug": {
              "ping": false,
              "query": true,
              "srv": false,
              "querymismatch": false,
              "ipinsrv": false,
              "cnameinsrv": false,
              "animatedmotd": false,
              "cachetime": 0,
              "apiversion": 2
            },
            "motd": {
              "raw": [
                "Dedicated Server"
              ],
              "clean": [
                "Dedicated Server"
              ],
              "html": [
                "Dedicated Server"
              ]
            },
            "players": {
              "online": 0,
              "max": 20
            },
            "version": "1.19.2",
            "online": true,
            "protocol": 527,
            "map": "XXXXXXXXXXXXX",
            "gamemode": "Survival",
            "serverid": "XXXXXXXXXXXXXXXXXXXX"
          }
    MD

    def default_options
      {
        'mc_server' => '',
        'player_alert' => 'false',
        'status_alert' => 'false',
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'changes_only' => 'true'
      }
    end

    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :mc_server, type: :string
    form_configurable :changes_only, type: :boolean
    form_configurable :debug, type: :boolean
    form_configurable :player_alert, type: :boolean
    form_configurable :status_alert, type: :boolean
    def validate_options

      if options.has_key?('player_alert') && boolify(options['player_alert']).nil?
        errors.add(:base, "if provided, player_alert must be true or false")
      end

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      if options.has_key?('status_alert') && boolify(options['status_alert']).nil?
        errors.add(:base, "if provided, status_alert must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      fetch
    end

    private

    def fetch
      uri = URI.parse("https://api.mcsrvstat.us/bedrock/2/#{interpolated['mc_server']}")
      response = Net::HTTP.get_response(uri)

      log "request  status : #{response.code}"

      payload = JSON.parse(response.body)

      if interpolated['debug'] == 'true'
        log payload
      end
      if interpolated['changes_only'] == 'true'
        if payload.to_s != memory['last_status']
          if "#{memory['last_status']}" == ''
            create_event payload: payload
          else
            last_status = memory['last_status'].gsub("=>", ": ").gsub(": nil,", ": null,")
            last_status = JSON.parse(last_status)
            found = false
            if interpolated['player_alert'] == 'true'
              if payload['players']['online'] != last_status['players']['online']
                found = true
              end
            end
            if interpolated['status_alert'] == 'true'
              if payload['online'] != last_status['online']
                found = true
              end
            end
            if found == true
              if interpolated['debug'] == 'true'
                log "found is #{found}! so event created"
              end
              create_event payload: payload
            end
          end
          memory['last_status'] = payload.to_s
        end
      else
        create_event payload: payload
        if payload.to_s != memory['last_status']
          memory['last_status'] = payload.to_s
        end
      end
    end
  end
end
