class Eduskunta

  class Scraper

    require 'open-uri'
    require 'nokogiri'

    @@PARL_URL = 'http://www.eduskunta.fi'
    
    def initialize(file)
      @file = file
      @noko = Nokogiri::HTML(file.read)
    end

    def as_hash 
      return { 
        :id => our_id,
        :name => name,
        :family_name => family_name,
        :given_names => given_names,
        :identifiers => identifiers,
        :email => email,
        :birth_date => birth_date,
        :image => image,
        :contact_details => contact_details,
        :links => links,
        :memberships => memberships,
      }
    end

    def memberships
      combined = council_of_state + parties
      combined.sort_by { |m| m[:start_date] }.collect { |i| i.reject { |k, v| v.nil? } }
    end


    def name
      return @noko.at('div.subhead h4').text.strip
    end

    def fullname
      return infotable.xpath('tr/th[.="Full name: "]/following-sibling::td').text.gsub(/\s+/, ' ')
    end

    def family_name
      fullname.gsub(/,.*/, '').strip
    end
    
    def given_names 
      fullname.gsub(/.*?,/, '').strip
    end

    def identifiers
      return [{
        :identifier => official_id,
        :scheme => 'eduskunta.fi',
      }]
    end

    def phone 
      return infotable.xpath('tr/th[.="Telephone: "]/following-sibling::td').text
    end

    def contact_details 
      return [
        { 
          :type => "phone",
          :value => phone,
        },
      ]
    end

    def birth_date
      birth = infotable.xpath('tr/th[.="Date and place of birth: "]/following-sibling::td').text
      return _find_date_in(birth)
    end


    def official_id
      french = @noko.at('#edustaja-alku a:nth-child(4)')
      /hnro\=(\d+)/.match(french['href']) and return $1 or raise "No ID in #{french['href']}"
    end

    def our_id
      "popit.eduskunta/person/" + official_id
    end

    #TODO add the other language links too
    def links
      return [ {
        :url => "http://www.eduskunta.fi/triphome/bin/hex5000.sh?hnro=#{official_id}&kieli=en",
        :note => "Eduskunta.fi (en)",
      }]
    end

    def email
      return infotable.css('.emailAddress').text.gsub(/\[at\]/, '@')
    end

    def image
      portrait = @noko.at('img.portrait')
      return @@PARL_URL + portrait['src']
    end

    def council_of_state_raw
      cos_table = @noko.xpath('//h3[.="Member in the Council of State"]/following-sibling::table/tr//ul/li').collect { |li| li.text }
    end

    def council_of_state
      council_of_state_raw.collect { |cs| _cs_membership(cs) }
    end

    def parties_raw
      return @noko.xpath('//table/tr/th[.="Parliamentary groups: "]/following-sibling::td/ul/li').collect { |li| li.text }
    end

    def parties
      parties_raw.collect { |p| _party_membership(p) }
    end

    def infotable
       @infotable ||= @noko.at('table.datatable') or raise "No infotable"
    end

    private

    def _cs_membership (text)
      # Prime Minister (Katainen)  22.06.2011
      # "Minister for Foreign Trade (Lipponen II)  15.04.1999 - 03.01.2002, ",
      /(.*?)\s\([^\)]+\)\s+(\d{2}\.\d{2}\.\d{4})\s+(.*)$/.match(text) or 
        raise "Can't parse Council of State membership from #{text}"
      return {
        :organization_id => "popit.eduskunta/council-of-state",
        :role => $1,
        :start_date => _find_date_in($2),
        :end_date => _find_date_in($3, true),
      }
    end

    def _party_membership (text)
      text.gsub!(/\(.*?\)/, '')  # strip out historic party names
      /^\s*(.*?)\s+(\d{2}\.\d{2}\.\d{4})\s+-(.*)$/.match(text) or 
        raise "Can't parse party membership from #{text}"
      party_id = _find_party_by_name($1) or raise "No such party <#{$1}>"
      return {
        :organization_id => "popit.eduskunta/party/#{party_id}",
        :start_date => _find_date_in($2),
        :end_date => _find_date_in($3, true),
      }
    end
    
    def _find_party_by_name (name)
      parties = {
        'Christian Democratic Parliamentary Group' => 'kd',
        'Finnish Centre Party' => 'kesk',
        'National Coalition Party' => 'kok',
        'Parliamentary group Change 2011' => 'm11',
        'Swedish Parliamentary Group' => 'r',
        'The Finns Party Parliamentary Group' => 'ps',
        'The Social Democratic Parliamentary Group' => 'sd',
        'Left Alliance' => 'vas',
        'Green Parliamentary Group' => 'vihr',
        'Left Faction Parliamentary Group' => 'vr',
        'Parliamentary group Mustajärvi' => 'emus',
        'Parliamentary group Yrttiaho' => 'eyrt',
        'Parliamentary group Virtanen' => 'evir',
      }
      return parties[name]
    end

    def _find_date_in(str, silent=false)
      /(\d{2})\.(\d{2})\.(\d{4})*/.match(str) and return [$3,$2,$1].join("-");
      return nil if silent
      raise "No date in #{str}"
    end

  end
end


