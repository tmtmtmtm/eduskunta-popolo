require 'eduskunta-scraper'
require 'test/unit'

class ScraperTest < Test::Unit::TestCase

  def setup
    @sauli = Eduskunta::Scraper.new(File.open('data/MPs/html/1086.html')).as_hash
    @jyrki = Eduskunta::Scraper.new(File.open('data/MPs/html/571.html')).as_hash
    @kimmo = Eduskunta::Scraper.new(File.open('data/MPs/html/261.html')).as_hash
    @musta = Eduskunta::Scraper.new(File.open('data/MPs/html/802.html')).as_hash
    @donner = Eduskunta::Scraper.new(File.open('data/MPs/html/109.html')).as_hash
  end

  def test_find_party
    assert_equal "popit.eduskunta/party/vas", Eduskunta::Party.name_to_id('Left Alliance')
  end

  def test_fail_to_find_party
    assert_nil Eduskunta::Party.name_to_id('No Such Party')
  end

  def test_find_old_party
    assert_equal "popit.eduskunta/party/ps", Eduskunta::Party.name_to_id('True Finns Party')
  end

  def test_id
    assert_equal 'popit.eduskunta/person/1086', @sauli[:id]
  end

  def test_name
    assert_equal 'Sauli Ahvenjärvi', @sauli[:name]
  end

  def test_family_name
    assert_equal 'Ahvenjärvi', @sauli[:family_name]
  end

  def test_given_names
    assert_equal 'Sauli Sakari', @sauli[:given_names]
  end

  def test_identifiers
    identifiers = @sauli[:identifiers].select { |i| i[:scheme] == 'eduskunta.fi' }
    assert_equal '1086', identifiers[0][:identifier]
  end

  def test_email
    assert_equal 'sauli.ahvenjarvi@parliament.fi', @sauli[:email]
  end

  def test_birth_date
    assert_equal '1957-08-18', @sauli[:birth_date]
  end

  def test_image
    assert_equal 'http://www.eduskunta.fi/fakta/edustaja/kuvat/1086.jpg', @sauli[:image]
  end

  def test_contact_details
    phone = @sauli[:contact_details].select { |cd| cd[:type] == 'phone' }
    assert_equal '+358 9 432 3006', phone[0][:value]
  end

  def test_links
    links = @sauli[:links].select { |i| i[:note] == 'Eduskunta.fi (en)' }
    assert_equal 'http://www.eduskunta.fi/triphome/bin/hex5000.sh?hnro=1086&kieli=en', links[0][:url]
  end

  # Split across two sections for Minister and Prime Minster
  def test_pm_council_of_state
    cos = @jyrki[:memberships].select { |m| m[:organization_id] == 'popit.eduskunta/council-of-state' }
    assert_equal 5, cos.count
    assert_equal 'Prime Minister', cos[4][:role]
    assert_equal '2011-06-22', cos[4][:start_date]
    assert_nil   cos[4][:end_date]
  end

  # Split across Minister section only
  def test_valtioneuvosto_only_council_of_state
    cos = @kimmo[:memberships].select { |m| m[:organization_id] == 'popit.eduskunta/council-of-state' }
    assert_equal 5, cos.count
    assert_equal 'popit.eduskunta/council-of-state', cos[0][:organization_id]
    assert_equal 'Minister of Transport', cos[0][:role]
    assert_equal '1999-01-15', cos[0][:start_date]
    assert_equal '1999-04-14', cos[0][:end_date]
  end

  def test_alternate_minister_name
    cos = @kimmo[:memberships].select { |m| m[:organization_id] == 'popit.eduskunta/council-of-state' }
    assert_equal 'Minister of Trade and Industry', cos[1][:role]
  end

  def test_memberships
    assert_equal 1, @sauli[:memberships].count
    assert_equal 6, @jyrki[:memberships].count
    assert_equal 'Prime Minister', @jyrki[:memberships][-1][:role]
  end

  # Only ever in one Party
  def test_party
    parties = @kimmo[:memberships].select { |m| m[:organization_id].start_with? 'popit.eduskunta/party/' }
    assert_equal 1, parties.count 
    assert_equal "popit.eduskunta/party/kok", parties[0][:organization_id]
    assert_equal '1983-03-26', parties[0][:start_date]
    assert_nil   parties[0][:end_date]
      
  end

  # Has changed party
  def test_parties
    parties = @musta[:memberships].select { |m| m[:organization_id].start_with? 'popit.eduskunta/party/' }
    assert_equal 3, parties.count
    assert_equal "popit.eduskunta/party/vas",  parties[0][:organization_id]
    assert_equal "popit.eduskunta/party/emus", parties[1][:organization_id]
    assert_equal "popit.eduskunta/party/vr",   parties[2][:organization_id]
    assert_equal '2003-03-19', parties[0][:start_date]
    assert_equal '2011-06-30', parties[0][:end_date]
    assert_nil   parties[-1][:end_date]
  end

  def test_in_party_multiple_times
    parties = @donner[:memberships].select { |m| m[:organization_id].start_with? 'popit.eduskunta/party/' }
    assert_equal 3, parties.count
    assert_equal ["popit.eduskunta/party/r"], parties.collect { |p| p[:organization_id] }.uniq 
    assert_equal "1987-03-21", parties[0][:start_date]
    assert_equal "1995-03-23", parties[0][:end_date]
    assert_equal "2013-09-05", parties[-1][:start_date]
    assert_nil parties[-1][:end_date]
  end

end

