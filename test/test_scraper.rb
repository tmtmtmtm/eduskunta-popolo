require 'eduskunta-scraper'

require 'test/unit'

class ScraperTest < Test::Unit::TestCase

  @@testfile = 'test/data/1086.html'

  def setup
    @doc = Eduskunta::Scraper.new(File.open(@@testfile));
    @sauli = @doc.as_hash
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

end

